/*
 * Copyright (C) 2001-2004,2009,2010 Red Hat, Inc.
 * Copyright © 2008, 2009, 2010, 2015 Christian Persch
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * SECTION: vte-terminal
 * @short_description: A terminal widget implementation
 *
 * A VteTerminal is a terminal emulator implemented as a GTK3 widget.
 *
 * Note that altough #VteTerminal implements the #GtkScrollable interface,
 * you should not place a #VteTerminal inside a #GtkScrolledWindow
 * container, since they are incompatible. Instead, pack the terminal in
 * a horizontal #GtkBox together with a #GtkScrollbar which uses the
 * #GtkAdjustment returned from gtk_scrollable_get_vadjustment().
 */

#include "config.h"

#include <new> /* placement new */

#include <pwd.h>

#ifdef HAVE_LOCALE_H
#include <locale.h>
#endif

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <gtk/gtk.h>
#include "vte/vteenums.h"
#include "vte/vtepty.h"
#include "vte/vteterminal.h"
#include "vte/vtetypebuiltins.h"

#include "debug.h"
#include "marshal.h"
#include "reaper.hh"
#include "vtedefines.hh"
#include "vteinternal.hh"
#include "vteaccess.h"

#include "vtegtk.hh"
#include "vteregexinternal.hh"

#if !GLIB_CHECK_VERSION(2, 42, 0)
#define G_PARAM_EXPLICIT_NOTIFY 0
#endif

#define I_(string) (g_intern_static_string(string))

#define VTE_TERMINAL_CSS_NAME "vte-terminal"

struct _VteTerminalClassPrivate {
        GtkStyleProvider *style_provider;
};

#ifdef VTE_DEBUG
G_DEFINE_TYPE_WITH_CODE(VteTerminal, vte_terminal, GTK_TYPE_WIDGET,
                        G_ADD_PRIVATE(VteTerminal)
                        g_type_add_class_private (g_define_type_id, sizeof (VteTerminalClassPrivate));
                        G_IMPLEMENT_INTERFACE(GTK_TYPE_SCROLLABLE, NULL)
                        if (_vte_debug_on(VTE_DEBUG_LIFECYCLE)) {
                                g_printerr("vte_terminal_get_type()\n");
                        })
#else
G_DEFINE_TYPE_WITH_CODE(VteTerminal, vte_terminal, GTK_TYPE_WIDGET,
                        G_ADD_PRIVATE(VteTerminal)
                        g_type_add_class_private (g_define_type_id, sizeof (VteTerminalClassPrivate));
                        G_IMPLEMENT_INTERFACE(GTK_TYPE_SCROLLABLE, NULL))
#endif

#define IMPL(t) (reinterpret_cast<VteTerminalPrivate*>(vte_terminal_get_instance_private(t)))

guint signals[LAST_SIGNAL];
GParamSpec *pspecs[LAST_PROP];
GTimer *process_timer;
bool g_test_mode = false;

static bool
valid_color(GdkRGBA const* color)
{
        return color->red >= 0. && color->red <= 1. &&
               color->green >= 0. && color->green <= 1. &&
               color->blue >= 0. && color->blue <= 1. &&
               color->alpha >= 0. && color->alpha <= 1.;
}

VteTerminalPrivate *_vte_terminal_get_impl(VteTerminal *terminal)
{
        return IMPL(terminal);
}

static void
vte_terminal_set_hadjustment(VteTerminal *terminal,
                             GtkAdjustment *adjustment)
{
        g_return_if_fail(adjustment == nullptr || GTK_IS_ADJUSTMENT(adjustment));
        IMPL(terminal)->widget_set_hadjustment(adjustment);
}

static void
vte_terminal_set_vadjustment(VteTerminal *terminal,
                             GtkAdjustment *adjustment)
{
        g_return_if_fail(adjustment == nullptr || GTK_IS_ADJUSTMENT(adjustment));
        IMPL(terminal)->widget_set_vadjustment(adjustment);
}

static void
vte_terminal_set_hscroll_policy(VteTerminal *terminal,
                                GtkScrollablePolicy policy)
{
        IMPL(terminal)->m_hscroll_policy = policy;
        gtk_widget_queue_resize_no_redraw (GTK_WIDGET (terminal));
}


static void
vte_terminal_set_vscroll_policy(VteTerminal *terminal,
                                GtkScrollablePolicy policy)
{
        IMPL(terminal)->m_vscroll_policy = policy;
        gtk_widget_queue_resize_no_redraw (GTK_WIDGET (terminal));
}

static void
vte_terminal_real_copy_clipboard(VteTerminal *terminal)
{
	IMPL(terminal)->widget_copy(VTE_SELECTION_CLIPBOARD, VTE_FORMAT_TEXT);
}

static void
vte_terminal_real_paste_clipboard(VteTerminal *terminal)
{
	IMPL(terminal)->widget_paste(GDK_SELECTION_CLIPBOARD);
}

static void
vte_terminal_style_updated (GtkWidget *widget)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);

        GTK_WIDGET_CLASS (vte_terminal_parent_class)->style_updated (widget);

        IMPL(terminal)->widget_style_updated();
}

static gboolean
vte_terminal_key_press(GtkWidget *widget, GdkEventKey *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);

        /* We do NOT want chain up to GtkWidget::key-press-event, since that would
         * cause GtkWidget's keybindings to be handled and consumed. However we'll
         * have to handle the one sane binding (Shift-F10 or MenuKey, to pop up the
         * context menu) ourself, so for now we simply skip the offending keybinding
         * in class_init.
         */

	/* First, check if GtkWidget's behavior already does something with
	 * this key. */
	if (GTK_WIDGET_CLASS(vte_terminal_parent_class)->key_press_event) {
		if ((GTK_WIDGET_CLASS(vte_terminal_parent_class))->key_press_event(widget,
                                                                                   event)) {
			return TRUE;
		}
	}

        return IMPL(terminal)->widget_key_press(event);
}

static gboolean
vte_terminal_key_release(GtkWidget *widget, GdkEventKey *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        return IMPL(terminal)->widget_key_release(event);
}

static gboolean
vte_terminal_motion_notify(GtkWidget *widget, GdkEventMotion *event)
{
        VteTerminal *terminal = VTE_TERMINAL(widget);
        return IMPL(terminal)->widget_motion_notify(event);
}

static gboolean
vte_terminal_button_press(GtkWidget *widget, GdkEventButton *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        return IMPL(terminal)->widget_button_press(event);
}

static gboolean
vte_terminal_button_release(GtkWidget *widget, GdkEventButton *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        return IMPL(terminal)->widget_button_release(event);
}

static gboolean
vte_terminal_scroll(GtkWidget *widget, GdkEventScroll *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_scroll(event);
        return TRUE;
}

static gboolean
vte_terminal_focus_in(GtkWidget *widget, GdkEventFocus *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_focus_in(event);
        return FALSE;
}

static gboolean
vte_terminal_focus_out(GtkWidget *widget, GdkEventFocus *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_focus_out(event);
        return FALSE;
}

static gboolean
vte_terminal_enter(GtkWidget *widget, GdkEventCrossing *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        gboolean ret = FALSE;

	if (GTK_WIDGET_CLASS (vte_terminal_parent_class)->enter_notify_event) {
		ret = GTK_WIDGET_CLASS (vte_terminal_parent_class)->enter_notify_event (widget, event);
	}

        IMPL(terminal)->widget_enter(event);

        return ret;
}

static gboolean
vte_terminal_leave(GtkWidget *widget, GdkEventCrossing *event)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
	gboolean ret = FALSE;

	if (GTK_WIDGET_CLASS (vte_terminal_parent_class)->leave_notify_event) {
		ret = GTK_WIDGET_CLASS (vte_terminal_parent_class)->leave_notify_event (widget, event);
	}

        IMPL(terminal)->widget_leave(event);

        return ret;
}

static void
vte_terminal_get_preferred_width(GtkWidget *widget,
				 int       *minimum_width,
				 int       *natural_width)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_get_preferred_width(minimum_width, natural_width);
}

static void
vte_terminal_get_preferred_height(GtkWidget *widget,
				  int       *minimum_height,
				  int       *natural_height)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_get_preferred_height(minimum_height, natural_height);
}

static void
vte_terminal_size_allocate(GtkWidget *widget, GtkAllocation *allocation)
{
	VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_size_allocate(allocation);
}

static gboolean
vte_terminal_draw(GtkWidget *widget,
                  cairo_t *cr)
{
        VteTerminal *terminal = VTE_TERMINAL (widget);
        IMPL(terminal)->widget_draw(cr);
        return FALSE;
}

static void
vte_terminal_realize(GtkWidget *widget)
{
        GTK_WIDGET_CLASS(vte_terminal_parent_class)->realize(widget);

        VteTerminal *terminal= VTE_TERMINAL(widget);
        IMPL(terminal)->widget_realize();
}

static void
vte_terminal_unrealize(GtkWidget *widget)
{
        VteTerminal *terminal = VTE_TERMINAL (widget);
        IMPL(terminal)->widget_unrealize();

        GTK_WIDGET_CLASS(vte_terminal_parent_class)->unrealize(widget);
}

static void
vte_terminal_map(GtkWidget *widget)
{
        _vte_debug_print(VTE_DEBUG_LIFECYCLE, "vte_terminal_map()\n");

        VteTerminal *terminal = VTE_TERMINAL(widget);
        GTK_WIDGET_CLASS(vte_terminal_parent_class)->map(widget);

        IMPL(terminal)->widget_map();
}

static void
vte_terminal_unmap(GtkWidget *widget)
{
        _vte_debug_print(VTE_DEBUG_LIFECYCLE, "vte_terminal_unmap()\n");

        VteTerminal *terminal = VTE_TERMINAL(widget);
        IMPL(terminal)->widget_unmap();

        GTK_WIDGET_CLASS(vte_terminal_parent_class)->unmap(widget);
}

static void
vte_terminal_screen_changed (GtkWidget *widget,
                             GdkScreen *previous_screen)
{
        VteTerminal *terminal = VTE_TERMINAL (widget);

        if (GTK_WIDGET_CLASS (vte_terminal_parent_class)->screen_changed) {
                GTK_WIDGET_CLASS (vte_terminal_parent_class)->screen_changed (widget, previous_screen);
        }

        IMPL(terminal)->widget_screen_changed(previous_screen);
}

static void
vte_terminal_constructed (GObject *object)
{
        VteTerminal *terminal = VTE_TERMINAL (object);

        G_OBJECT_CLASS (vte_terminal_parent_class)->constructed (object);

        IMPL(terminal)->widget_constructed();
}

static void
vte_terminal_init(VteTerminal *terminal)
{
        void *place;
	GtkStyleContext *context;

	_vte_debug_print(VTE_DEBUG_LIFECYCLE, "vte_terminal_init()\n");

        context = gtk_widget_get_style_context(&terminal->widget);
        gtk_style_context_add_provider (context,
                                        VTE_TERMINAL_GET_CLASS (terminal)->priv->style_provider,
                                        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

	/* Initialize private data. NOTE: place is zeroed */
	place = vte_terminal_get_instance_private(terminal);
        new (place) VteTerminalPrivate(terminal);

        gtk_widget_set_has_window(&terminal->widget, FALSE);
}

static void
vte_terminal_finalize(GObject *object)
{
    	VteTerminal *terminal = VTE_TERMINAL (object);

        IMPL(terminal)->~VteTerminalPrivate();

	/* Call the inherited finalize() method. */
	G_OBJECT_CLASS(vte_terminal_parent_class)->finalize(object);
}

static void
vte_terminal_get_property (GObject *object,
                           guint prop_id,
                           GValue *value,
                           GParamSpec *pspec)
{
        VteTerminal *terminal = VTE_TERMINAL (object);
        auto impl = IMPL(terminal);

	switch (prop_id)
                {
                case PROP_HADJUSTMENT:
                        g_value_set_object (value, impl->m_hadjustment);
                        break;
                case PROP_VADJUSTMENT:
                        g_value_set_object (value, impl->m_vadjustment);
                        break;
                case PROP_HSCROLL_POLICY:
                        g_value_set_enum (value, impl->m_hscroll_policy);
                        break;
                case PROP_VSCROLL_POLICY:
                        g_value_set_enum (value, impl->m_vscroll_policy);
                        break;
                case PROP_ALLOW_BOLD:
                        g_value_set_boolean (value, vte_terminal_get_allow_bold (terminal));
                        break;
                case PROP_ALLOW_HYPERLINK:
                        g_value_set_boolean (value, vte_terminal_get_allow_hyperlink (terminal));
                        break;
                case PROP_AUDIBLE_BELL:
                        g_value_set_boolean (value, vte_terminal_get_audible_bell (terminal));
                        break;
                case PROP_BACKSPACE_BINDING:
                        g_value_set_enum (value, impl->m_backspace_binding);
                        break;
                case PROP_BOLD_IS_BRIGHT:
                        g_value_set_boolean (value, vte_terminal_get_bold_is_bright (terminal));
                        break;
                case PROP_CELL_HEIGHT_SCALE:
                        g_value_set_double (value, vte_terminal_get_cell_height_scale (terminal));
                        break;
                case PROP_CELL_WIDTH_SCALE:
                        g_value_set_double (value, vte_terminal_get_cell_width_scale (terminal));
                        break;
                case PROP_CJK_AMBIGUOUS_WIDTH:
                        g_value_set_int (value, vte_terminal_get_cjk_ambiguous_width (terminal));
                        break;
                case PROP_CURSOR_BLINK_MODE:
                        g_value_set_enum (value, vte_terminal_get_cursor_blink_mode (terminal));
                        break;
                case PROP_CURRENT_DIRECTORY_URI:
                        g_value_set_string (value, vte_terminal_get_current_directory_uri (terminal));
                        break;
                case PROP_CURRENT_FILE_URI:
                        g_value_set_string (value, vte_terminal_get_current_file_uri (terminal));
                        break;
                case PROP_CURSOR_SHAPE:
                        g_value_set_enum (value, vte_terminal_get_cursor_shape (terminal));
                        break;
                case PROP_DELETE_BINDING:
                        g_value_set_enum (value, impl->m_delete_binding);
                        break;
                case PROP_ENCODING:
                        g_value_set_string (value, vte_terminal_get_encoding (terminal));
                        break;
                case PROP_FONT_DESC:
                        g_value_set_boxed (value, vte_terminal_get_font (terminal));
                        break;
                case PROP_FONT_SCALE:
                        g_value_set_double (value, vte_terminal_get_font_scale (terminal));
                        break;
                case PROP_HYPERLINK_HOVER_URI:
                        g_value_set_string (value, impl->m_hyperlink_hover_uri);
                        break;
                case PROP_ICON_TITLE:
                        g_value_set_string (value, vte_terminal_get_icon_title (terminal));
                        break;
                case PROP_INPUT_ENABLED:
                        g_value_set_boolean (value, vte_terminal_get_input_enabled (terminal));
                        break;
                case PROP_MOUSE_POINTER_AUTOHIDE:
                        g_value_set_boolean (value, vte_terminal_get_mouse_autohide (terminal));
                        break;
                case PROP_PTY:
                        g_value_set_object (value, vte_terminal_get_pty(terminal));
                        break;
                case PROP_REWRAP_ON_RESIZE:
                        g_value_set_boolean (value, vte_terminal_get_rewrap_on_resize (terminal));
                        break;
                case PROP_SCROLLBACK_LINES:
                        g_value_set_uint (value, vte_terminal_get_scrollback_lines(terminal));
                        break;
                case PROP_SCROLL_ON_KEYSTROKE:
                        g_value_set_boolean (value, vte_terminal_get_scroll_on_keystroke(terminal));
                        break;
                case PROP_SCROLL_ON_OUTPUT:
                        g_value_set_boolean (value, vte_terminal_get_scroll_on_output(terminal));
                        break;
                case PROP_TEXT_BLINK_MODE:
                        g_value_set_enum (value, vte_terminal_get_text_blink_mode (terminal));
                        break;
                case PROP_WINDOW_TITLE:
                        g_value_set_string (value, vte_terminal_get_window_title (terminal));
                        break;
                case PROP_WORD_CHAR_EXCEPTIONS:
                        g_value_set_string (value, vte_terminal_get_word_char_exceptions (terminal));
                        break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			return;
                }
}

static void
vte_terminal_set_property (GObject *object,
                           guint prop_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
        VteTerminal *terminal = VTE_TERMINAL (object);

	switch (prop_id)
                {
                case PROP_HADJUSTMENT:
                        vte_terminal_set_hadjustment (terminal, (GtkAdjustment *)g_value_get_object (value));
                        break;
                case PROP_VADJUSTMENT:
                        vte_terminal_set_vadjustment (terminal, (GtkAdjustment *)g_value_get_object (value));
                        break;
                case PROP_HSCROLL_POLICY:
                        vte_terminal_set_hscroll_policy(terminal, (GtkScrollablePolicy)g_value_get_enum(value));
                        break;
                case PROP_VSCROLL_POLICY:
                        vte_terminal_set_vscroll_policy(terminal, (GtkScrollablePolicy)g_value_get_enum(value));
                        break;
                case PROP_ALLOW_BOLD:
                        vte_terminal_set_allow_bold (terminal, g_value_get_boolean (value));
                        break;
                case PROP_ALLOW_HYPERLINK:
                        vte_terminal_set_allow_hyperlink (terminal, g_value_get_boolean (value));
                        break;
                case PROP_AUDIBLE_BELL:
                        vte_terminal_set_audible_bell (terminal, g_value_get_boolean (value));
                        break;
                case PROP_BACKSPACE_BINDING:
                        vte_terminal_set_backspace_binding (terminal, (VteEraseBinding)g_value_get_enum (value));
                        break;
                case PROP_BOLD_IS_BRIGHT:
                        vte_terminal_set_bold_is_bright (terminal, g_value_get_boolean (value));
                        break;
                case PROP_CELL_HEIGHT_SCALE:
                        vte_terminal_set_cell_height_scale (terminal, g_value_get_double (value));
                        break;
                case PROP_CELL_WIDTH_SCALE:
                        vte_terminal_set_cell_width_scale (terminal, g_value_get_double (value));
                        break;
                case PROP_CJK_AMBIGUOUS_WIDTH:
                        vte_terminal_set_cjk_ambiguous_width (terminal, g_value_get_int (value));
                        break;
                case PROP_CURSOR_BLINK_MODE:
                        vte_terminal_set_cursor_blink_mode (terminal, (VteCursorBlinkMode)g_value_get_enum (value));
                        break;
                case PROP_CURSOR_SHAPE:
                        vte_terminal_set_cursor_shape (terminal, (VteCursorShape)g_value_get_enum (value));
                        break;
                case PROP_DELETE_BINDING:
                        vte_terminal_set_delete_binding (terminal, (VteEraseBinding)g_value_get_enum (value));
                        break;
                case PROP_ENCODING:
                        vte_terminal_set_encoding (terminal, g_value_get_string (value), NULL);
                        break;
                case PROP_FONT_DESC:
                        vte_terminal_set_font (terminal, (PangoFontDescription *)g_value_get_boxed (value));
                        break;
                case PROP_FONT_SCALE:
                        vte_terminal_set_font_scale (terminal, g_value_get_double (value));
                        break;
                case PROP_INPUT_ENABLED:
                        vte_terminal_set_input_enabled (terminal, g_value_get_boolean (value));
                        break;
                case PROP_MOUSE_POINTER_AUTOHIDE:
                        vte_terminal_set_mouse_autohide (terminal, g_value_get_boolean (value));
                        break;
                case PROP_PTY:
                        vte_terminal_set_pty (terminal, (VtePty *)g_value_get_object (value));
                        break;
                case PROP_REWRAP_ON_RESIZE:
                        vte_terminal_set_rewrap_on_resize (terminal, g_value_get_boolean (value));
                        break;
                case PROP_SCROLLBACK_LINES:
                        vte_terminal_set_scrollback_lines (terminal, g_value_get_uint (value));
                        break;
                case PROP_SCROLL_ON_KEYSTROKE:
                        vte_terminal_set_scroll_on_keystroke(terminal, g_value_get_boolean (value));
                        break;
                case PROP_SCROLL_ON_OUTPUT:
                        vte_terminal_set_scroll_on_output (terminal, g_value_get_boolean (value));
                        break;
                case PROP_TEXT_BLINK_MODE:
                        vte_terminal_set_text_blink_mode (terminal, (VteTextBlinkMode)g_value_get_enum (value));
                        break;
                case PROP_WORD_CHAR_EXCEPTIONS:
                        vte_terminal_set_word_char_exceptions (terminal, g_value_get_string (value));
                        break;

                        /* Not writable */
                case PROP_CURRENT_DIRECTORY_URI:
                case PROP_CURRENT_FILE_URI:
                case PROP_HYPERLINK_HOVER_URI:
                case PROP_ICON_TITLE:
                case PROP_WINDOW_TITLE:
                        g_assert_not_reached ();
                        break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			return;
                }
}

static void
vte_terminal_class_init(VteTerminalClass *klass)
{
	GObjectClass *gobject_class;
	GtkWidgetClass *widget_class;
	GtkBindingSet  *binding_set;

#ifdef VTE_DEBUG
	{
                _vte_debug_init();
		_vte_debug_print(VTE_DEBUG_LIFECYCLE,
                                 "vte_terminal_class_init()\n");
		/* print out the legend */
		_vte_debug_print(VTE_DEBUG_WORK,
                                 "Debugging work flow (top input to bottom output):\n"
                                 "  .  _vte_terminal_process_incoming\n"
                                 "  <  start process_timeout\n"
                                 "  {[ start update_timeout  [ => rate limited\n"
                                 "  T  start of terminal in update_timeout\n"
                                 "  (  start _vte_terminal_process_incoming\n"
                                 "  ?  _vte_invalidate_cells (call)\n"
                                 "  !  _vte_invalidate_cells (dirty)\n"
                                 "  *  _vte_invalidate_all\n"
                                 "  )  end _vte_terminal_process_incoming\n"
                                 "  =  vte_terminal_paint\n"
                                 "  ]} end update_timeout\n"
                                 "  >  end process_timeout\n");

                char const* test_env = g_getenv("VTE_TEST");
                if (test_env != nullptr) {
                        g_test_mode = g_str_equal(test_env, "1");
                        g_unsetenv("VTE_TEST");
                }
	}
#endif

	_VTE_DEBUG_IF (VTE_DEBUG_UPDATES) gdk_window_set_debug_updates(TRUE);

	bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR);
#ifdef HAVE_DECL_BIND_TEXTDOMAIN_CODESET
	bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
#endif

	gobject_class = G_OBJECT_CLASS(klass);
	widget_class = GTK_WIDGET_CLASS(klass);

	/* Override some of the default handlers. */
        gobject_class->constructed = vte_terminal_constructed;
	gobject_class->finalize = vte_terminal_finalize;
        gobject_class->get_property = vte_terminal_get_property;
        gobject_class->set_property = vte_terminal_set_property;
	widget_class->realize = vte_terminal_realize;
	widget_class->unrealize = vte_terminal_unrealize;
        widget_class->map = vte_terminal_map;
        widget_class->unmap = vte_terminal_unmap;
	widget_class->scroll_event = vte_terminal_scroll;
        widget_class->draw = vte_terminal_draw;
	widget_class->key_press_event = vte_terminal_key_press;
	widget_class->key_release_event = vte_terminal_key_release;
	widget_class->button_press_event = vte_terminal_button_press;
	widget_class->button_release_event = vte_terminal_button_release;
	widget_class->motion_notify_event = vte_terminal_motion_notify;
	widget_class->enter_notify_event = vte_terminal_enter;
	widget_class->leave_notify_event = vte_terminal_leave;
	widget_class->focus_in_event = vte_terminal_focus_in;
	widget_class->focus_out_event = vte_terminal_focus_out;
	widget_class->style_updated = vte_terminal_style_updated;
	widget_class->get_preferred_width = vte_terminal_get_preferred_width;
	widget_class->get_preferred_height = vte_terminal_get_preferred_height;
	widget_class->size_allocate = vte_terminal_size_allocate;
        widget_class->screen_changed = vte_terminal_screen_changed;

#if GTK_CHECK_VERSION(3, 19, 5)
        gtk_widget_class_set_css_name(widget_class, VTE_TERMINAL_CSS_NAME);
#else
        /* Bug #763538 */
        if (gtk_check_version(3, 19, 5) == nullptr)
                g_printerr("VTE needs to be recompiled against a newer gtk+ version.\n");
#endif

	/* Initialize default handlers. */
	klass->eof = NULL;
	klass->child_exited = NULL;
	klass->encoding_changed = NULL;
	klass->char_size_changed = NULL;
	klass->window_title_changed = NULL;
	klass->icon_title_changed = NULL;
	klass->selection_changed = NULL;
	klass->contents_changed = NULL;
	klass->cursor_moved = NULL;
	klass->commit = NULL;

	klass->deiconify_window = NULL;
	klass->iconify_window = NULL;
	klass->raise_window = NULL;
	klass->lower_window = NULL;
	klass->refresh_window = NULL;
	klass->restore_window = NULL;
	klass->maximize_window = NULL;
	klass->resize_window = NULL;
	klass->move_window = NULL;

	klass->increase_font_size = NULL;
	klass->decrease_font_size = NULL;

	klass->text_modified = NULL;
	klass->text_inserted = NULL;
	klass->text_deleted = NULL;
	klass->text_scrolled = NULL;

	klass->copy_clipboard = vte_terminal_real_copy_clipboard;
	klass->paste_clipboard = vte_terminal_real_paste_clipboard;

        klass->bell = NULL;

        /* GtkScrollable interface properties */
        g_object_class_override_property (gobject_class, PROP_HADJUSTMENT, "hadjustment");
        g_object_class_override_property (gobject_class, PROP_VADJUSTMENT, "vadjustment");
        g_object_class_override_property (gobject_class, PROP_HSCROLL_POLICY, "hscroll-policy");
        g_object_class_override_property (gobject_class, PROP_VSCROLL_POLICY, "vscroll-policy");

	/* Register some signals of our own. */

        /**
         * VteTerminal::eof:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the terminal receives an end-of-file from a child which
         * is running in the terminal.  This signal is frequently (but not
         * always) emitted with a #VteTerminal::child-exited signal.
         */
        signals[SIGNAL_EOF] =
                g_signal_new(I_("eof"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, eof),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::child-exited:
         * @vteterminal: the object which received the signal
         * @status: the child's exit status
         *
         * This signal is emitted when the terminal detects that a child
         * watched using vte_terminal_watch_child() has exited.
         */
        signals[SIGNAL_CHILD_EXITED] =
                g_signal_new(I_("child-exited"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, child_exited),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__INT,
                             G_TYPE_NONE,
                             1, G_TYPE_INT);

        /**
         * VteTerminal::window-title-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the terminal's %window_title field is modified.
         */
        signals[SIGNAL_WINDOW_TITLE_CHANGED] =
                g_signal_new(I_("window-title-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, window_title_changed),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::icon-title-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the terminal's %icon_title field is modified.
         */
        signals[SIGNAL_ICON_TITLE_CHANGED] =
                g_signal_new(I_("icon-title-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, icon_title_changed),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::current-directory-uri-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the current directory URI is modified.
         */
        signals[SIGNAL_CURRENT_DIRECTORY_URI_CHANGED] =
                g_signal_new(I_("current-directory-uri-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             0,
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::current-file-uri-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the current file URI is modified.
         */
        signals[SIGNAL_CURRENT_FILE_URI_CHANGED] =
                g_signal_new(I_("current-file-uri-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             0,
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::hyperlink-hover-uri-changed:
         * @vteterminal: the object which received the signal
         * @uri: the nonempty target URI under the mouse, or NULL
         * @bbox: the bounding box of the hyperlink anchor text, or NULL
         *
         * Emitted when the hovered hyperlink changes.
         *
         * @uri and @bbox are owned by VTE, must not be modified, and might
         * change after the signal handlers returns.
         *
         * The signal is not re-emitted when the bounding box changes for the
         * same hyperlink. This might change in a future VTE version without notice.
         *
         * Since: 0.50
         */
        signals[SIGNAL_HYPERLINK_HOVER_URI_CHANGED] =
                g_signal_new(I_("hyperlink-hover-uri-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             0,
                             NULL,
                             NULL,
                             _vte_marshal_VOID__STRING_BOXED,
                             G_TYPE_NONE,
                             2, G_TYPE_STRING, GDK_TYPE_RECTANGLE | G_SIGNAL_TYPE_STATIC_SCOPE);

        /**
         * VteTerminal::encoding-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted whenever the terminal's current encoding has changed, either
         * as a result of receiving a control sequence which toggled between the
         * local and UTF-8 encodings, or at the parent application's request.
         */
        signals[SIGNAL_ENCODING_CHANGED] =
                g_signal_new(I_("encoding-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, encoding_changed),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::commit:
         * @vteterminal: the object which received the signal
         * @text: a string of text
         * @size: the length of that string of text
         *
         * Emitted whenever the terminal receives input from the user and
         * prepares to send it to the child process.  The signal is emitted even
         * when there is no child process.
         */
        signals[SIGNAL_COMMIT] =
                g_signal_new(I_("commit"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, commit),
                             NULL,
                             NULL,
                             _vte_marshal_VOID__STRING_UINT,
                             G_TYPE_NONE, 2, G_TYPE_STRING, G_TYPE_UINT);

        /**
         * VteTerminal::char-size-changed:
         * @vteterminal: the object which received the signal
         * @width: the new character cell width
         * @height: the new character cell height
         *
         * Emitted whenever the cell size changes, e.g. due to a change in
         * font, font-scale or cell-width/height-scale.
         *
         * Note that this signal should rather be called "cell-size-changed".
         */
        signals[SIGNAL_CHAR_SIZE_CHANGED] =
                g_signal_new(I_("char-size-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, char_size_changed),
                             NULL,
                             NULL,
                             _vte_marshal_VOID__UINT_UINT,
                             G_TYPE_NONE, 2, G_TYPE_UINT, G_TYPE_UINT);

        /**
         * VteTerminal::selection-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted whenever the contents of terminal's selection changes.
         */
        signals[SIGNAL_SELECTION_CHANGED] =
                g_signal_new (I_("selection-changed"),
                              G_OBJECT_CLASS_TYPE(klass),
                              G_SIGNAL_RUN_LAST,
                              G_STRUCT_OFFSET(VteTerminalClass, selection_changed),
                              NULL,
                              NULL,
                              g_cclosure_marshal_VOID__VOID,
                              G_TYPE_NONE, 0);

        /**
         * VteTerminal::contents-changed:
         * @vteterminal: the object which received the signal
         *
         * Emitted whenever the visible appearance of the terminal has changed.
         * Used primarily by #VteTerminalAccessible.
         */
        signals[SIGNAL_CONTENTS_CHANGED] =
                g_signal_new(I_("contents-changed"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, contents_changed),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::cursor-moved:
         * @vteterminal: the object which received the signal
         *
         * Emitted whenever the cursor moves to a new character cell.  Used
         * primarily by #VteTerminalAccessible.
         */
        signals[SIGNAL_CURSOR_MOVED] =
                g_signal_new(I_("cursor-moved"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, cursor_moved),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::deiconify-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_DEICONIFY_WINDOW] =
                g_signal_new(I_("deiconify-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, deiconify_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::iconify-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_ICONIFY_WINDOW] =
                g_signal_new(I_("iconify-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, iconify_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::raise-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_RAISE_WINDOW] =
                g_signal_new(I_("raise-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, raise_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::lower-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_LOWER_WINDOW] =
                g_signal_new(I_("lower-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, lower_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::refresh-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_REFRESH_WINDOW] =
                g_signal_new(I_("refresh-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, refresh_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::restore-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_RESTORE_WINDOW] =
                g_signal_new(I_("restore-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, restore_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::maximize-window:
         * @vteterminal: the object which received the signal
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_MAXIMIZE_WINDOW] =
                g_signal_new(I_("maximize-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, maximize_window),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::resize-window:
         * @vteterminal: the object which received the signal
         * @width: the desired number of columns
         * @height: the desired number of rows
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_RESIZE_WINDOW] =
                g_signal_new(I_("resize-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, resize_window),
                             NULL,
                             NULL,
                             _vte_marshal_VOID__UINT_UINT,
                             G_TYPE_NONE, 2, G_TYPE_UINT, G_TYPE_UINT);

        /**
         * VteTerminal::move-window:
         * @vteterminal: the object which received the signal
         * @x: the terminal's desired location, X coordinate
         * @y: the terminal's desired location, Y coordinate
         *
         * Emitted at the child application's request.
         */
        signals[SIGNAL_MOVE_WINDOW] =
                g_signal_new(I_("move-window"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, move_window),
                             NULL,
                             NULL,
                             _vte_marshal_VOID__UINT_UINT,
                             G_TYPE_NONE, 2, G_TYPE_UINT, G_TYPE_UINT);

        /**
         * VteTerminal::increase-font-size:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the user hits the '+' key while holding the Control key.
         */
        signals[SIGNAL_INCREASE_FONT_SIZE] =
                g_signal_new(I_("increase-font-size"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, increase_font_size),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::decrease-font-size:
         * @vteterminal: the object which received the signal
         *
         * Emitted when the user hits the '-' key while holding the Control key.
         */
        signals[SIGNAL_DECREASE_FONT_SIZE] =
                g_signal_new(I_("decrease-font-size"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, decrease_font_size),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::text-modified:
         * @vteterminal: the object which received the signal
         *
         * An internal signal used for communication between the terminal and
         * its accessibility peer. May not be emitted under certain
         * circumstances.
         */
        signals[SIGNAL_TEXT_MODIFIED] =
                g_signal_new(I_("text-modified"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, text_modified),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::text-inserted:
         * @vteterminal: the object which received the signal
         *
         * An internal signal used for communication between the terminal and
         * its accessibility peer. May not be emitted under certain
         * circumstances.
         */
        signals[SIGNAL_TEXT_INSERTED] =
                g_signal_new(I_("text-inserted"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, text_inserted),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::text-deleted:
         * @vteterminal: the object which received the signal
         *
         * An internal signal used for communication between the terminal and
         * its accessibility peer. May not be emitted under certain
         * circumstances.
         */
        signals[SIGNAL_TEXT_DELETED] =
                g_signal_new(I_("text-deleted"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, text_deleted),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal::text-scrolled:
         * @vteterminal: the object which received the signal
         * @delta: the number of lines scrolled
         *
         * An internal signal used for communication between the terminal and
         * its accessibility peer. May not be emitted under certain
         * circumstances.
         */
        signals[SIGNAL_TEXT_SCROLLED] =
                g_signal_new(I_("text-scrolled"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, text_scrolled),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__INT,
                             G_TYPE_NONE, 1, G_TYPE_INT);

        /**
         * VteTerminal::copy-clipboard:
         * @vteterminal: the object which received the signal
         *
         * Emitted whenever vte_terminal_copy_clipboard() is called.
         */
	signals[SIGNAL_COPY_CLIPBOARD] =
                g_signal_new(I_("copy-clipboard"),
			     G_OBJECT_CLASS_TYPE(klass),
			     (GSignalFlags)(G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION),
			     G_STRUCT_OFFSET(VteTerminalClass, copy_clipboard),
			     NULL,
			     NULL,
                             g_cclosure_marshal_VOID__VOID,
			     G_TYPE_NONE, 0);

        /**
         * VteTerminal::paste-clipboard:
         * @vteterminal: the object which received the signal
         *
         * Emitted whenever vte_terminal_paste_clipboard() is called.
         */
	signals[SIGNAL_PASTE_CLIPBOARD] =
                g_signal_new(I_("paste-clipboard"),
			     G_OBJECT_CLASS_TYPE(klass),
			     (GSignalFlags)(G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION),
			     G_STRUCT_OFFSET(VteTerminalClass, paste_clipboard),
			     NULL,
			     NULL,
                             g_cclosure_marshal_VOID__VOID,
			     G_TYPE_NONE, 0);

        /**
         * VteTerminal::bell:
         * @vteterminal: the object which received the signal
         *
         * This signal is emitted when the a child sends a bell request to the
         * terminal.
         */
        signals[SIGNAL_BELL] =
                g_signal_new(I_("bell"),
                             G_OBJECT_CLASS_TYPE(klass),
                             G_SIGNAL_RUN_LAST,
                             G_STRUCT_OFFSET(VteTerminalClass, bell),
                             NULL,
                             NULL,
                             g_cclosure_marshal_VOID__VOID,
                             G_TYPE_NONE, 0);

        /**
         * VteTerminal:allow-bold:
         *
         * Controls whether or not the terminal will attempt to draw bold text.
         * This may happen either by using a bold font variant, or by
         * repainting text with a different offset.
         */
        pspecs[PROP_ALLOW_BOLD] =
                g_param_spec_boolean ("allow-bold", NULL, NULL,
                                      TRUE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:allow-hyperlink:
         *
         * Controls whether or not hyperlinks (OSC 8 escape sequence) are recognized and displayed.
         *
         * Since: 0.50
         */
        pspecs[PROP_ALLOW_HYPERLINK] =
                g_param_spec_boolean ("allow-hyperlink", NULL, NULL,
                                      FALSE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:audible-bell:
         *
         * Controls whether or not the terminal will beep when the child outputs the
         * "bl" sequence.
         */
        pspecs[PROP_AUDIBLE_BELL] =
                g_param_spec_boolean ("audible-bell", NULL, NULL,
                                      TRUE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:backspace-binding:
         *
         * Controls what string or control sequence the terminal sends to its child
         * when the user presses the backspace key.
         */
        pspecs[PROP_BACKSPACE_BINDING] =
                g_param_spec_enum ("backspace-binding", NULL, NULL,
                                   VTE_TYPE_ERASE_BINDING,
                                   VTE_ERASE_AUTO,
                                   (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:bold-is-bright:
         *
         * Whether the SGR 1 attribute also switches to the bright counterpart
         * of the first 8 palette colors, in addition to making them bold (legacy behavior)
         * or if SGR 1 only enables bold and leaves the color intact.
         *
         * Since: 0.52
         */
        pspecs[PROP_BOLD_IS_BRIGHT] =
                g_param_spec_boolean ("bold-is-bright", NULL, NULL,
                                      TRUE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:cell-height-scale:
         *
         * Scale factor for the cell height, to increase line spacing. (The font's height is not affected.)
         *
         * Since: 0.52
         */
        pspecs[PROP_CELL_HEIGHT_SCALE] =
                g_param_spec_double ("cell-height-scale", NULL, NULL,
                                     VTE_CELL_SCALE_MIN,
                                     VTE_CELL_SCALE_MAX,
                                     1.,
                                     (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:cell-width-scale:
         *
         * Scale factor for the cell width, to increase letter spacing. (The font's width is not affected.)
         *
         * Since: 0.52
         */
        pspecs[PROP_CELL_WIDTH_SCALE] =
                g_param_spec_double ("cell-width-scale", NULL, NULL,
                                     VTE_CELL_SCALE_MIN,
                                     VTE_CELL_SCALE_MAX,
                                     1.,
                                     (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:cjk-ambiguous-width:
         *
         * This setting controls whether ambiguous-width characters are narrow or wide
         * when using the UTF-8 encoding (vte_terminal_set_encoding()). In all other encodings,
         * the width of ambiguous-width characters is fixed.
         *
         * This setting only takes effect the next time the terminal is reset, either
         * via escape sequence or with vte_terminal_reset().
         */
        pspecs[PROP_CJK_AMBIGUOUS_WIDTH] =
                g_param_spec_int ("cjk-ambiguous-width", NULL, NULL,
                                  1, 2, VTE_DEFAULT_UTF8_AMBIGUOUS_WIDTH,
                                  (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:cursor-blink-mode:
         *
         * Sets whether or not the cursor will blink. Using %VTE_CURSOR_BLINK_SYSTEM
         * will use the #GtkSettings::gtk-cursor-blink setting.
         */
        pspecs[PROP_CURSOR_BLINK_MODE] =
                g_param_spec_enum ("cursor-blink-mode", NULL, NULL,
                                   VTE_TYPE_CURSOR_BLINK_MODE,
                                   VTE_CURSOR_BLINK_SYSTEM,
                                   (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:cursor-shape:
         *
         * Controls the shape of the cursor.
         */
        pspecs[PROP_CURSOR_SHAPE] =
                g_param_spec_enum ("cursor-shape", NULL, NULL,
                                   VTE_TYPE_CURSOR_SHAPE,
                                   VTE_CURSOR_SHAPE_BLOCK,
                                   (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:delete-binding:
         *
         * Controls what string or control sequence the terminal sends to its child
         * when the user presses the delete key.
         */
        pspecs[PROP_DELETE_BINDING] =
                g_param_spec_enum ("delete-binding", NULL, NULL,
                                   VTE_TYPE_ERASE_BINDING,
                                   VTE_ERASE_AUTO,
                                   (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:font-scale:
         *
         * The terminal's font scale.
         */
        pspecs[PROP_FONT_SCALE] =
                g_param_spec_double ("font-scale", NULL, NULL,
                                     VTE_FONT_SCALE_MIN,
                                     VTE_FONT_SCALE_MAX,
                                     1.,
                                     (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:encoding:
         *
         * Controls the encoding the terminal will expect data from the child to
         * be encoded with.  For certain terminal types, applications executing in the
         * terminal can change the encoding.  The default is defined by the
         * application's locale settings.
         */
        pspecs[PROP_ENCODING] =
                g_param_spec_string ("encoding", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:font-desc:
         *
         * Specifies the font used for rendering all text displayed by the terminal,
         * overriding any fonts set using gtk_widget_modify_font().  The terminal
         * will immediately attempt to load the desired font, retrieve its
         * metrics, and attempt to resize itself to keep the same number of rows
         * and columns.
         */
        pspecs[PROP_FONT_DESC] =
                g_param_spec_boxed ("font-desc", NULL, NULL,
                                    PANGO_TYPE_FONT_DESCRIPTION,
                                    (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:icon-title:
         *
         * The terminal's so-called icon title, or %NULL if no icon title has been set.
         */
        pspecs[PROP_ICON_TITLE] =
                g_param_spec_string ("icon-title", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:input-enabled:
         *
         * Controls whether the terminal allows user input. When user input is disabled,
         * key press and mouse button press and motion events are not sent to the
         * terminal's child.
         */
        pspecs[PROP_INPUT_ENABLED] =
                g_param_spec_boolean ("input-enabled", NULL, NULL,
                                      TRUE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:pointer-autohide:
         *
         * Controls the value of the terminal's mouse autohide setting.  When autohiding
         * is enabled, the mouse cursor will be hidden when the user presses a key and
         * shown when the user moves the mouse.
         */
        pspecs[PROP_MOUSE_POINTER_AUTOHIDE] =
                g_param_spec_boolean ("pointer-autohide", NULL, NULL,
                                      FALSE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:pty:
         *
         * The PTY object for the terminal.
         */
        pspecs[PROP_PTY] =
                g_param_spec_object ("pty", NULL, NULL,
                                     VTE_TYPE_PTY,
                                     (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:rewrap-on-resize:
         *
         * Controls whether or not the terminal will rewrap its contents, including
         * the scrollback buffer, whenever the terminal's width changes.
         */
        pspecs[PROP_REWRAP_ON_RESIZE] =
                g_param_spec_boolean ("rewrap-on-resize", NULL, NULL,
                                      TRUE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:scrollback-lines:
         *
         * The length of the scrollback buffer used by the terminal.  The size of
         * the scrollback buffer will be set to the larger of this value and the number
         * of visible rows the widget can display, so 0 can safely be used to disable
         * scrollback.  Note that this setting only affects the normal screen buffer.
         * For terminal types which have an alternate screen buffer, no scrollback is
         * allowed on the alternate screen buffer.
         */
        pspecs[PROP_SCROLLBACK_LINES] =
                g_param_spec_uint ("scrollback-lines", NULL, NULL,
                                   0, G_MAXUINT,
                                   VTE_SCROLLBACK_INIT,
                                   (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:scroll-on-keystroke:
         *
         * Controls whether or not the terminal will forcibly scroll to the bottom of
         * the viewable history when the user presses a key.  Modifier keys do not
         * trigger this behavior.
         */
        pspecs[PROP_SCROLL_ON_KEYSTROKE] =
                g_param_spec_boolean ("scroll-on-keystroke", NULL, NULL,
                                      FALSE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:scroll-on-output:
         *
         * Controls whether or not the terminal will forcibly scroll to the bottom of
         * the viewable history when the new data is received from the child.
         */
        pspecs[PROP_SCROLL_ON_OUTPUT] =
                g_param_spec_boolean ("scroll-on-output", NULL, NULL,
                                      TRUE,
                                      (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:text-blink-mode:
         *
         * Controls whether or not the terminal will allow blinking text.
         *
         * Since: 0.52
         */
        pspecs[PROP_TEXT_BLINK_MODE] =
                g_param_spec_enum ("text-blink-mode", NULL, NULL,
                                   VTE_TYPE_TEXT_BLINK_MODE,
                                   VTE_TEXT_BLINK_ALWAYS,
                                   (GParamFlags) (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:window-title:
         *
         * The terminal's title.
         */
        pspecs[PROP_WINDOW_TITLE] =
                g_param_spec_string ("window-title", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:current-directory-uri:
         *
         * The current directory URI, or %NULL if unset.
         */
        pspecs[PROP_CURRENT_DIRECTORY_URI] =
                g_param_spec_string ("current-directory-uri", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:current-file-uri:
         *
         * The current file URI, or %NULL if unset.
         */
        pspecs[PROP_CURRENT_FILE_URI] =
                g_param_spec_string ("current-file-uri", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:hyperlink-hover-uri:
         *
         * The currently hovered hyperlink URI, or %NULL if unset.
         *
         * Since: 0.50
         */
        pspecs[PROP_HYPERLINK_HOVER_URI] =
                g_param_spec_string ("hyperlink-hover-uri", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        /**
         * VteTerminal:word-char-exceptions:
         *
         * The set of characters which will be considered parts of a word
         * when doing word-wise selection, in addition to the default which only
         * considers alphanumeric characters part of a word.
         *
         * If %NULL, a built-in set is used.
         *
         * Since: 0.40
         */
        pspecs[PROP_WORD_CHAR_EXCEPTIONS] =
                g_param_spec_string ("word-char-exceptions", NULL, NULL,
                                     NULL,
                                     (GParamFlags) (G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY));

        g_object_class_install_properties(gobject_class, LAST_PROP, pspecs);

	/* Disable GtkWidget's keybindings except for Shift-F10 and MenuKey
         * which pop up the context menu.
         */
	binding_set = gtk_binding_set_by_class(vte_terminal_parent_class);
	gtk_binding_entry_skip(binding_set, GDK_KEY_F1, GDK_CONTROL_MASK);
	gtk_binding_entry_skip(binding_set, GDK_KEY_F1, GDK_SHIFT_MASK);
	gtk_binding_entry_skip(binding_set, GDK_KEY_KP_F1, GDK_CONTROL_MASK);
	gtk_binding_entry_skip(binding_set, GDK_KEY_KP_F1, GDK_SHIFT_MASK);

        process_timer = g_timer_new();

        klass->priv = G_TYPE_CLASS_GET_PRIVATE (klass, VTE_TYPE_TERMINAL, VteTerminalClassPrivate);

        klass->priv->style_provider = GTK_STYLE_PROVIDER (gtk_css_provider_new ());
        gtk_css_provider_load_from_data (GTK_CSS_PROVIDER (klass->priv->style_provider),
                                         "VteTerminal, " VTE_TERMINAL_CSS_NAME " {\n"
                                         "padding: 1px 1px 1px 1px;\n"
                                         "background-color: @theme_base_color;\n"
                                         "color: @theme_fg_color;\n"
                                         "}\n",
                                         -1, NULL);

        /* a11y */
        gtk_widget_class_set_accessible_type(widget_class, VTE_TYPE_TERMINAL_ACCESSIBLE);
}

/* public API */

/**
 * vte_get_features:
 *
 * Gets a list of features vte was compiled with.
 *
 * Returns: (transfer none): a string with features
 *
 * Since: 0.40
 */
const char *
vte_get_features (void)
{
        return
#ifdef WITH_GNUTLS
                "+GNUTLS"
#else
                "-GNUTLS"
#endif
                ;
}

/**
 * vte_get_major_version:
 *
 * Returns the major version of the VTE library at runtime.
 * Contrast this with %VTE_MAJOR_VERSION which represents
 * the version of the VTE library that the code was compiled
 * with.
 *
 * Returns: the major version
 *
 * Since: 0.40
 */
guint
vte_get_major_version (void)
{
        return VTE_MAJOR_VERSION;
}

/**
 * vte_get_minor_version:
 *
 * Returns the minor version of the VTE library at runtime.
 * Contrast this with %VTE_MINOR_VERSION which represents
 * the version of the VTE library that the code was compiled
 * with.
 *
 * Returns: the minor version
 *
 * Since: 0.40
 */
guint
vte_get_minor_version (void)
{
        return VTE_MINOR_VERSION;
}

/**
 * vte_get_micro_version:
 *
 * Returns the micro version of the VTE library at runtime.
 * Contrast this with %VTE_MICRO_VERSION which represents
 * the version of the VTE library that the code was compiled
 * with.
 *
 * Returns: the micro version
 *
 * Since: 0.40
 */
guint
vte_get_micro_version (void)
{
        return VTE_MICRO_VERSION;
}

/**
 * vte_get_user_shell:
 *
 * Gets the user's shell, or %NULL. In the latter case, the
 * system default (usually "/bin/sh") should be used.
 *
 * Returns: (transfer full) (type filename): a newly allocated string with the
 *   user's shell, or %NULL
 */
char *
vte_get_user_shell (void)
{
	struct passwd *pwd;

	pwd = getpwuid(getuid());
        if (pwd && pwd->pw_shell)
                return g_strdup (pwd->pw_shell);

        return NULL;
}

/* VteTerminal public API */

/**
 * vte_terminal_new:
 *
 * Creates a new terminal widget.
 *
 * Returns: (transfer none) (type Vte.Terminal): a new #VteTerminal object
 */
GtkWidget *
vte_terminal_new(void)
{
	return (GtkWidget *)g_object_new(VTE_TYPE_TERMINAL, nullptr);
}

/**
 * vte_terminal_copy_clipboard:
 * @terminal: a #VteTerminal
 *
 * Places the selected text in the terminal in the #GDK_SELECTION_CLIPBOARD
 * selection.
 *
 * Deprecated: 0.50: Use vte_terminal_copy_clipboard_format() with %VTE_FORMAT_TEXT
 *   instead.
 */
void
vte_terminal_copy_clipboard(VteTerminal *terminal)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        IMPL(terminal)->emit_copy_clipboard();
}


/**
 * vte_terminal_copy_clipboard_format:
 * @terminal: a #VteTerminal
 * @format: a #VteFormat
 *
 * Places the selected text in the terminal in the #GDK_SELECTION_CLIPBOARD
 * selection in the form specified by @format.
 *
 * For all formats, the selection data (see #GtkSelectionData) will include the
 * text targets (see gtk_target_list_add_text_targets() and
 * gtk_selection_data_targets_includes_text()). For %VTE_FORMAT_HTML,
 * the selection will also include the "text/html" target, which when requested,
 * returns the HTML data in UTF-16 with a U+FEFF BYTE ORDER MARK character at
 * the start.
 *
 * Since: 0.50
 */
void
vte_terminal_copy_clipboard_format(VteTerminal *terminal,
                                   VteFormat format)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(format == VTE_FORMAT_TEXT || format == VTE_FORMAT_HTML);

        IMPL(terminal)->widget_copy(VTE_SELECTION_CLIPBOARD, format);
}

/**
 * vte_terminal_copy_primary:
 * @terminal: a #VteTerminal
 *
 * Places the selected text in the terminal in the #GDK_SELECTION_PRIMARY
 * selection.
 */
void
vte_terminal_copy_primary(VteTerminal *terminal)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
	_vte_debug_print(VTE_DEBUG_SELECTION, "Copying to PRIMARY.\n");
	IMPL(terminal)->widget_copy(VTE_SELECTION_PRIMARY, VTE_FORMAT_TEXT);
}

/**
 * vte_terminal_paste_clipboard:
 * @terminal: a #VteTerminal
 *
 * Sends the contents of the #GDK_SELECTION_CLIPBOARD selection to the
 * terminal's child.  If necessary, the data is converted from UTF-8 to the
 * terminal's current encoding. It's called on paste menu item, or when
 * user presses Shift+Insert.
 */
void
vte_terminal_paste_clipboard(VteTerminal *terminal)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        IMPL(terminal)->emit_paste_clipboard();
}

/**
 * vte_terminal_paste_primary:
 * @terminal: a #VteTerminal
 *
 * Sends the contents of the #GDK_SELECTION_PRIMARY selection to the terminal's
 * child.  If necessary, the data is converted from UTF-8 to the terminal's
 * current encoding.  The terminal will call also paste the
 * #GDK_SELECTION_PRIMARY selection when the user clicks with the the second
 * mouse button.
 */
void
vte_terminal_paste_primary(VteTerminal *terminal)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
	_vte_debug_print(VTE_DEBUG_SELECTION, "Pasting PRIMARY.\n");
	IMPL(terminal)->widget_paste(GDK_SELECTION_PRIMARY);
}

/**
 * vte_terminal_match_add_gregex:
 * @terminal: a #VteTerminal
 * @gregex: a #GRegex
 * @gflags: the #GRegexMatchFlags to use when matching the regex
 *
 * Adds the regular expression @regex to the list of matching expressions.  When the
 * user moves the mouse cursor over a section of displayed text which matches
 * this expression, the text will be highlighted.
 *
 * Returns: an integer associated with this expression, or -1 if @gregex could not be
 *   transformed into a #VteRegex or @gflags were incompatible
 *
 * Deprecated: 0.46: Use vte_terminal_match_add_regex() or vte_terminal_match_add_regex_full() instead.
 */
int
vte_terminal_match_add_gregex(VteTerminal *terminal,
                              GRegex *gregex,
                              GRegexMatchFlags gflags)
{
        g_return_val_if_fail(gregex != NULL, -1);

        auto regex = _vte_regex_new_gregex(VteRegexPurpose::match, gregex);
        if (regex == NULL)
                return -1;

        auto rv = vte_terminal_match_add_regex(terminal, regex,
                                               _vte_regex_translate_gregex_match_flags(gflags));
        vte_regex_unref(regex);
        return rv;
}

/**
 * vte_terminal_match_add_regex:
 * @terminal: a #VteTerminal
 * @regex: (transfer none): a #VteRegex
 * @flags: PCRE2 match flags, or 0
 *
 * Adds the regular expression @regex to the list of matching expressions.  When the
 * user moves the mouse cursor over a section of displayed text which matches
 * this expression, the text will be highlighted.
 *
 * Returns: an integer associated with this expression
 *
 * Since: 0.46
 */
int
vte_terminal_match_add_regex(VteTerminal *terminal,
                             VteRegex    *regex,
                             guint32      flags)
{
	struct vte_match_regex new_regex_match;

	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), -1);
	g_return_val_if_fail(regex != NULL, -1);
        g_return_val_if_fail(_vte_regex_has_purpose(regex, VteRegexPurpose::match), -1);
        g_warn_if_fail(_vte_regex_get_compile_flags(regex) & PCRE2_MULTILINE);

        auto impl = IMPL(terminal);

        new_regex_match.regex.regex = vte_regex_ref(regex);
        new_regex_match.regex.match_flags = flags;
        new_regex_match.cursor_mode = VTE_REGEX_CURSOR_GDKCURSORTYPE;
        new_regex_match.cursor.cursor_type = VTE_DEFAULT_CURSOR;

        return impl->regex_match_add(&new_regex_match);
}

/**
 * vte_terminal_match_check:
 * @terminal: a #VteTerminal
 * @column: the text column
 * @row: the text row
 * @tag: (out) (allow-none): a location to store the tag, or %NULL
 *
 * Checks if the text in and around the specified position matches any of the
 * regular expressions previously set using vte_terminal_match_add().  If a
 * match exists, the text string is returned and if @tag is not %NULL, the number
 * associated with the matched regular expression will be stored in @tag.
 *
 * If more than one regular expression has been set with
 * vte_terminal_match_add(), then expressions are checked in the order in
 * which they were added.
 *
 * Returns: (transfer full): a newly allocated string which matches one of the previously
 *   set regular expressions
 *
 * Deprecated: 0.46: Use vte_terminal_match_check_event() instead.
 */
char *
vte_terminal_match_check(VteTerminal *terminal,
                         long column,
                         long row,
			 int *tag)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
        return IMPL(terminal)->regex_match_check(column, row, tag);
}


/**
 * vte_terminal_match_check_event:
 * @terminal: a #VteTerminal
 * @event: a #GdkEvent
 * @tag: (out) (allow-none): a location to store the tag, or %NULL
 *
 * Checks if the text in and around the position of the event matches any of the
 * regular expressions previously set using vte_terminal_match_add().  If a
 * match exists, the text string is returned and if @tag is not %NULL, the number
 * associated with the matched regular expression will be stored in @tag.
 *
 * If more than one regular expression has been set with
 * vte_terminal_match_add(), then expressions are checked in the order in
 * which they were added.
 *
 * Returns: (transfer full): a newly allocated string which matches one of the previously
 *   set regular expressions
 */
char *
vte_terminal_match_check_event(VteTerminal *terminal,
                               GdkEvent *event,
                               int *tag)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        return IMPL(terminal)->regex_match_check(event, tag);
}

/**
 * vte_terminal_hyperlink_check_event:
 * @terminal: a #VteTerminal
 * @event: a #GdkEvent
 *
 * Returns a nonempty string: the target of the explicit hyperlink (printed using the OSC 8
 * escape sequence) at the position of the event, or %NULL.
 *
 * Proper use of the escape sequence should result in URI-encoded URIs with a proper scheme
 * like "http://", "https://", "file://", "mailto:" etc. This is, however, not enforced by VTE.
 * The caller must tolerate the returned string potentially not being a valid URI.
 *
 * Returns: (transfer full): a newly allocated string containing the target of the hyperlink
 *
 * Since: 0.50
 */
char *
vte_terminal_hyperlink_check_event(VteTerminal *terminal,
                                   GdkEvent *event)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        return IMPL(terminal)->hyperlink_check(event);
}

/**
 * vte_terminal_event_check_regex_simple:
 * @terminal: a #VteTerminal
 * @event: a #GdkEvent
 * @regexes: (array length=n_regexes): an array of #VteRegex
 * @n_regexes: number of items in @regexes
 * @match_flags: PCRE2 match flags, or 0
 * @matches: (out caller-allocates) (array length=n_regexes): a location to store the matches
 *
 * Checks each regex in @regexes if the text in and around the position of
 * the event matches the regular expressions.  If a match exists, the matched
 * text is stored in @matches at the position of the regex in @regexes; otherwise
 * %NULL is stored there.
 *
 * Returns: %TRUE iff any of the regexes produced a match
 *
 * Since: 0.46
 */
gboolean
vte_terminal_event_check_regex_simple(VteTerminal *terminal,
                                      GdkEvent *event,
                                      VteRegex **regexes,
                                      gsize n_regexes,
                                      guint32 match_flags,
                                      char **matches)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        g_return_val_if_fail(event != NULL, FALSE);
        g_return_val_if_fail(regexes != NULL || n_regexes == 0, FALSE);
        for (gsize i = 0; i < n_regexes; i++) {
                g_return_val_if_fail(_vte_regex_has_purpose(regexes[i], VteRegexPurpose::match), -1);
                g_warn_if_fail(_vte_regex_get_compile_flags(regexes[i]) & PCRE2_MULTILINE);
        }
        g_return_val_if_fail(matches != NULL, FALSE);

        return IMPL(terminal)->regex_match_check_extra(event, regexes, n_regexes, match_flags, matches);
}

/**
 * vte_terminal_event_check_gregex_simple:
 * @terminal: a #VteTerminal
 * @event: a #GdkEvent
 * @regexes: (array length=n_regexes): an array of #GRegex
 * @n_regexes: number of items in @regexes
 * @match_flags: the #GRegexMatchFlags to use when matching the regexes
 * @matches: (out caller-allocates) (array length=n_regexes): a location to store the matches
 *
 * This function does nothing.
 *
 * Returns: %FALSE
 *
 * Since: 0.44
 * Deprecated: 0.46: Use vte_terminal_event_check_regex_simple() instead.
 */
gboolean
vte_terminal_event_check_gregex_simple(VteTerminal *terminal,
                                       GdkEvent *event,
                                       GRegex **regexes,
                                       gsize n_regexes,
                                       GRegexMatchFlags match_flags,
                                       char **matches)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        g_return_val_if_fail(event != NULL, FALSE);
        g_return_val_if_fail(regexes != NULL || n_regexes == 0, FALSE);
        g_return_val_if_fail(matches != NULL, FALSE);

        return FALSE;
}

/**
 * vte_terminal_match_set_cursor:
 * @terminal: a #VteTerminal
 * @tag: the tag of the regex which should use the specified cursor
 * @cursor: (allow-none): the #GdkCursor which the terminal should use when the pattern is
 *   highlighted, or %NULL to use the standard cursor
 *
 * Sets which cursor the terminal will use if the pointer is over the pattern
 * specified by @tag.  The terminal keeps a reference to @cursor.
 *
 * Deprecated: 0.40: Use vte_terminal_match_set_cursor_type() or vte_terminal_match_set_cursor_named() instead.
 */
void
vte_terminal_match_set_cursor(VteTerminal *terminal,
                              int tag,
                              GdkCursor *cursor)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        IMPL(terminal)->regex_match_set_cursor(tag, cursor);
}

/**
 * vte_terminal_match_set_cursor_type:
 * @terminal: a #VteTerminal
 * @tag: the tag of the regex which should use the specified cursor
 * @cursor_type: a #GdkCursorType
 *
 * Sets which cursor the terminal will use if the pointer is over the pattern
 * specified by @tag.
 */
void
vte_terminal_match_set_cursor_type(VteTerminal *terminal,
				   int tag,
                                   GdkCursorType cursor_type)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        IMPL(terminal)->regex_match_set_cursor(tag, cursor_type);
}

/**
 * vte_terminal_match_set_cursor_name:
 * @terminal: a #VteTerminal
 * @tag: the tag of the regex which should use the specified cursor
 * @cursor_name: the name of the cursor
 *
 * Sets which cursor the terminal will use if the pointer is over the pattern
 * specified by @tag.
 */
void
vte_terminal_match_set_cursor_name(VteTerminal *terminal,
				   int tag,
                                   const char *cursor_name)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        IMPL(terminal)->regex_match_set_cursor(tag, cursor_name);
}


/**
 * vte_terminal_match_remove:
 * @terminal: a #VteTerminal
 * @tag: the tag of the regex to remove
 *
 * Removes the regular expression which is associated with the given @tag from
 * the list of expressions which the terminal will highlight when the user
 * moves the mouse cursor over matching text.
 */
void
vte_terminal_match_remove(VteTerminal *terminal, int tag)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(tag != -1);
        IMPL(terminal)->regex_match_remove(tag);
}

/**
 * vte_terminal_match_remove_all:
 * @terminal: a #VteTerminal
 *
 * Clears the list of regular expressions the terminal uses to highlight text
 * when the user moves the mouse cursor.
 */
void
vte_terminal_match_remove_all(VteTerminal *terminal)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        IMPL(terminal)->regex_match_remove_all();
}

/**
 * vte_terminal_search_find_previous:
 * @terminal: a #VteTerminal
 *
 * Searches the previous string matching the search regex set with
 * vte_terminal_search_set_regex().
 *
 * Returns: %TRUE if a match was found
 */
gboolean
vte_terminal_search_find_previous (VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->search_find(true);
}

/**
 * vte_terminal_search_find_next:
 * @terminal: a #VteTerminal
 *
 * Searches the next string matching the search regex set with
 * vte_terminal_search_set_regex().
 *
 * Returns: %TRUE if a match was found
 */
gboolean
vte_terminal_search_find_next (VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->search_find(false);
}

/**
 * vte_terminal_search_set_regex:
 * @terminal: a #VteTerminal
 * @regex: (allow-none): a #VteRegex, or %NULL
 * @flags: PCRE2 match flags, or 0
 *
 * Sets the regex to search for. Unsets the search regex when passed %NULL.
 *
 * Since: 0.46
 */
void
vte_terminal_search_set_regex (VteTerminal *terminal,
                               VteRegex    *regex,
                               guint32      flags)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(regex == nullptr || _vte_regex_has_purpose(regex, VteRegexPurpose::search));
        g_warn_if_fail(regex == nullptr || _vte_regex_get_compile_flags(regex) & PCRE2_MULTILINE);

        IMPL(terminal)->search_set_regex(regex, flags);
}

/**
 * vte_terminal_search_get_regex:
 * @terminal: a #VteTerminal
 *
 * Returns: (transfer none): the search #VteRegex regex set in @terminal, or %NULL
 *
 * Since: 0.46
 */
VteRegex *
vte_terminal_search_get_regex(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);

        auto impl = IMPL(terminal);
        return impl->m_search_regex.regex;
}

/**
 * vte_terminal_search_set_gregex:
 * @terminal: a #VteTerminal
 * @gregex: (allow-none): a #GRegex, or %NULL
 * @gflags: flags from #GRegexMatchFlags
 *
 * Sets the #GRegex regex to search for. Unsets the search regex when passed %NULL.
 *
 * Deprecated: 0.46: use vte_terminal_search_set_regex() instead.
 */
void
vte_terminal_search_set_gregex (VteTerminal *terminal,
				GRegex      *gregex,
                                GRegexMatchFlags gflags)
{
        VteRegex *regex = nullptr;
        if (gregex)
                regex = _vte_regex_new_gregex(VteRegexPurpose::search, gregex);

        vte_terminal_search_set_regex(terminal, regex,
                                      _vte_regex_translate_gregex_match_flags(gflags));

        if (regex)
                vte_regex_unref(regex);
}

/**
 * vte_terminal_search_get_gregex:
 * @terminal: a #VteTerminal
 *
 * Returns: (transfer none): %NULL
 *
 * Deprecated: 0.46: use vte_terminal_search_get_regex() instead.
 */
GRegex *
vte_terminal_search_get_gregex (VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);

        return NULL;
}

/**
 * vte_terminal_search_set_wrap_around:
 * @terminal: a #VteTerminal
 * @wrap_around: whether search should wrap
 *
 * Sets whether search should wrap around to the beginning of the
 * terminal content when reaching its end.
 */
void
vte_terminal_search_set_wrap_around (VteTerminal *terminal,
				     gboolean     wrap_around)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        IMPL(terminal)->search_set_wrap_around(wrap_around != FALSE);
}

/**
 * vte_terminal_search_get_wrap_around:
 * @terminal: a #VteTerminal
 *
 * Returns: whether searching will wrap around
 */
gboolean
vte_terminal_search_get_wrap_around (VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);

	return IMPL(terminal)->m_search_wrap_around;
}


/**
 * vte_terminal_select_all:
 * @terminal: a #VteTerminal
 *
 * Selects all text within the terminal (including the scrollback buffer).
 */
void
vte_terminal_select_all (VteTerminal *terminal)
{
	g_return_if_fail (VTE_IS_TERMINAL (terminal));

        IMPL(terminal)->select_all();
}

/**
 * vte_terminal_unselect_all:
 * @terminal: a #VteTerminal
 *
 * Clears the current selection.
 */
void
vte_terminal_unselect_all(VteTerminal *terminal)
{
	g_return_if_fail (VTE_IS_TERMINAL (terminal));

        IMPL(terminal)->deselect_all();
}

/**
 * vte_terminal_get_cursor_position:
 * @terminal: a #VteTerminal
 * @column: (out) (allow-none): a location to store the column, or %NULL
 * @row: (out) (allow-none): a location to store the row, or %NULL
 *
 * Reads the location of the insertion cursor and returns it.  The row
 * coordinate is absolute.
 */
void
vte_terminal_get_cursor_position(VteTerminal *terminal,
				 long *column,
                                 long *row)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        auto impl = IMPL(terminal);
	if (column) {
                *column = impl->m_screen->cursor.col;
	}
	if (row) {
                *row = impl->m_screen->cursor.row;
	}
}

/**
 * vte_terminal_pty_new_sync:
 * @terminal: a #VteTerminal
 * @flags: flags from #VtePtyFlags
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Creates a new #VtePty, and sets the emulation property
 * from #VteTerminal:emulation.
 *
 * See vte_pty_new() for more information.
 *
 * Returns: (transfer full): a new #VtePty
 */
VtePty *
vte_terminal_pty_new_sync(VteTerminal *terminal,
                          VtePtyFlags flags,
                          GCancellable *cancellable,
                          GError **error)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);

        VtePty *pty = vte_pty_new_sync(flags, cancellable, error);
        if (pty == NULL)
                return NULL;

        return pty;
}

/**
 * vte_terminal_watch_child:
 * @terminal: a #VteTerminal
 * @child_pid: a #GPid
 *
 * Watches @child_pid. When the process exists, the #VteTerminal::child-exited
 * signal will be called with the child's exit status.
 *
 * Prior to calling this function, a #VtePty must have been set in @terminal
 * using vte_terminal_set_pty().
 * When the child exits, the terminal's #VtePty will be set to %NULL.
 *
 * Note: g_child_watch_add() or g_child_watch_add_full() must not have
 * been called for @child_pid, nor a #GSource for it been created with
 * g_child_watch_source_new().
 *
 * Note: when using the g_spawn_async() family of functions,
 * the %G_SPAWN_DO_NOT_REAP_CHILD flag MUST have been passed.
 */
void
vte_terminal_watch_child (VteTerminal *terminal,
                          GPid child_pid)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(child_pid != -1);

        auto impl = IMPL(terminal);
        g_return_if_fail(impl->m_pty != NULL);

        impl->watch_child(child_pid);
}

/**
 * vte_terminal_spawn_sync:
 * @terminal: a #VteTerminal
 * @pty_flags: flags from #VtePtyFlags
 * @working_directory: (allow-none): the name of a directory the command should start
 *   in, or %NULL to use the current working directory
 * @argv: (array zero-terminated=1) (element-type filename): child's argument vector
 * @envv: (allow-none) (array zero-terminated=1) (element-type filename): a list of environment
 *   variables to be added to the environment before starting the process, or %NULL
 * @spawn_flags: flags from #GSpawnFlags
 * @child_setup: (allow-none) (scope call): an extra child setup function to run in the child just before exec(), or %NULL
 * @child_setup_data: user data for @child_setup
 * @child_pid: (out) (allow-none) (transfer full): a location to store the child PID, or %NULL
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Starts the specified command under a newly-allocated controlling
 * pseudo-terminal.  The @argv and @envv lists should be %NULL-terminated.
 * The "TERM" environment variable is automatically set to a default value,
 * but can be overridden from @envv.
 * @pty_flags controls logging the session to the specified system log files.
 *
 * Note that %G_SPAWN_DO_NOT_REAP_CHILD will always be added to @spawn_flags.
 *
 * Note that all open file descriptors will be closed in the child. If you want
 * to keep some file descriptor open for use in the child process, you need to
 * use a child setup function that unsets the FD_CLOEXEC flag on that file
 * descriptor.
 *
 * See vte_pty_new(), g_spawn_async() and vte_terminal_watch_child() for more information.
 *
 * Beginning with 0.52, sets PWD to @working_directory in order to preserve symlink components.
 * The caller should also make sure that symlinks were preserved while constructing the value of @working_directory,
 * e.g. by using vte_terminal_get_current_directory_uri(), g_get_current_dir() or get_current_dir_name().
 *
 * Returns: %TRUE on success, or %FALSE on error with @error filled in
 *
 * Deprecated: 0.48: Use vte_terminal_spawn_async() instead.
 */
gboolean
vte_terminal_spawn_sync(VteTerminal *terminal,
                        VtePtyFlags pty_flags,
                        const char *working_directory,
                        char **argv,
                        char **envv,
                        GSpawnFlags spawn_flags_,
                        GSpawnChildSetupFunc child_setup,
                        gpointer child_setup_data,
                        GPid *child_pid /* out */,
                        GCancellable *cancellable,
                        GError **error)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        g_return_val_if_fail(argv != NULL, FALSE);
        g_return_val_if_fail(child_setup_data == NULL || child_setup, FALSE);
        g_return_val_if_fail(error == NULL || *error == NULL, FALSE);

        return IMPL(terminal)->spawn_sync(pty_flags,
                                         working_directory,
                                         argv,
                                         envv,
                                         spawn_flags_,
                                         child_setup,
                                         child_setup_data,
                                         child_pid,
                                         cancellable,
                                         error);
}

typedef struct {
        GWeakRef wref;
        VteTerminalSpawnAsyncCallback callback;
        gpointer user_data;
} SpawnAsyncCallbackData;

static gpointer
spawn_async_callback_data_new(VteTerminal *terminal,
                     VteTerminalSpawnAsyncCallback callback,
                     gpointer user_data)
{
        SpawnAsyncCallbackData *data = g_new0 (SpawnAsyncCallbackData, 1);

        g_weak_ref_init(&data->wref, terminal);
        data->callback = callback;
        data->user_data = user_data;

        return data;
}

static void
spawn_async_callback_data_free (SpawnAsyncCallbackData *data)
{
        g_weak_ref_clear(&data->wref);
        g_free(data);
}

static void
spawn_async_cb (GObject *source,
                GAsyncResult *result,
                gpointer user_data)
{
        SpawnAsyncCallbackData *data = reinterpret_cast<SpawnAsyncCallbackData*>(user_data);
        VtePty *pty = VTE_PTY(source);

        GPid pid = -1;
        GError *error = nullptr;
        vte_pty_spawn_finish(pty, result, &pid, &error);

        /* Now get a ref to the terminal */
        VteTerminal* terminal = (VteTerminal*)g_weak_ref_get(&data->wref);

        /* Automatically watch the child */
        if (terminal != nullptr) {
                if (pid != -1)
                        vte_terminal_watch_child(terminal, pid);
                else
                        vte_terminal_set_pty(terminal, nullptr);
        } else {
                if (pid != -1) {
                        vte_reaper_add_child(pid);
                }
        }

        if (data->callback)
                data->callback(terminal, pid, error, data->user_data);

        if (terminal == nullptr) {
                /* If the terminal was destroyed, we need to abort the child process, if any */
                if (pid != -1) {
#ifdef HAVE_GETPGID
                        pid_t pgrp;
                        pgrp = getpgid(pid);
                        if (pgrp != -1) {
                                kill(-pgrp, SIGHUP);
                        }
#endif
                        kill(pid, SIGHUP);
                }
        }

        if (error)
                g_error_free(error);

        spawn_async_callback_data_free(data);

        if (terminal != nullptr)
                g_object_unref(terminal);
}


/**
 * VteTerminalSpawnAsyncCallback:
 * @terminal: the #VteTerminal
 * @pid: a #GPid
 * @error: a #GError, or %NULL
 * @user_data: user data that was passed to vte_terminal_spawn_async
 *
 * Callback for vte_terminal_spawn_async().
 *
 * On success, @pid contains the PID of the spawned process, and @error
 * is %NULL.
 * On failure, @pid is -1 and @error contains the error information.
 *
 * Since: 0.48
 */

/**
 * vte_terminal_spawn_async:
 * @terminal: a #VteTerminal
 * @pty_flags: flags from #VtePtyFlags
 * @working_directory: (allow-none): the name of a directory the command should start
 *   in, or %NULL to use the current working directory
 * @argv: (array zero-terminated=1) (element-type filename): child's argument vector
 * @envv: (allow-none) (array zero-terminated=1) (element-type filename): a list of environment
 *   variables to be added to the environment before starting the process, or %NULL
 * @spawn_flags_: flags from #GSpawnFlags
 * @child_setup: (allow-none) (scope async): an extra child setup function to run in the child just before exec(), or %NULL
 * @child_setup_data: (closure child_setup): user data for @child_setup, or %NULL
 * @child_setup_data_destroy: (destroy child_setup_data): a #GDestroyNotify for @child_setup_data, or %NULL
 * @timeout: a timeout value in ms, or -1 to wait indefinitely
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @callback: a #VteTerminalSpawnAsyncCallback, or %NULL
 * @user_data: user data for @callback, or %NULL
 *
 * A convenience function that wraps creating the #VtePty and spawning
 * the child process on it. See vte_pty_new_sync(), vte_pty_spawn_async(),
 * and vte_pty_spawn_finish() for more information.
 *
 * When the operation is finished successfully, @callback will be called
 * with the child #GPid, and a %NULL #GError. The child PID will already be
 * watched via vte_terminal_watch_child().
 *
 * When the operation fails, @callback will be called with a -1 #GPid,
 * and a non-%NULL #GError containing the error information.
 *
 * Note that if @terminal has been destroyed before the operation is called,
 * @callback will be called with a %NULL @terminal; you must not do anything
 * in the callback besides freeing any resources associated with @user_data,
 * but taking care not to access the now-destroyed #VteTerminal. Note that
 * in this case, if spawning was successful, the child process will be aborted
 * automatically.
 *
 * Beginning with 0.52, sets PWD to @working_directory in order to preserve symlink components.
 * The caller should also make sure that symlinks were preserved while constructing the value of @working_directory,
 * e.g. by using vte_terminal_get_current_directory_uri(), g_get_current_dir() or get_current_dir_name().
 *
 * Since: 0.48
 */
void
vte_terminal_spawn_async(VteTerminal *terminal,
                         VtePtyFlags pty_flags,
                         const char *working_directory,
                         char **argv,
                         char **envv,
                         GSpawnFlags spawn_flags_,
                         GSpawnChildSetupFunc child_setup,
                         gpointer child_setup_data,
                         GDestroyNotify child_setup_data_destroy,
                         int timeout,
                         GCancellable *cancellable,
                         VteTerminalSpawnAsyncCallback callback,
                         gpointer user_data)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(argv != nullptr);
        g_return_if_fail(!child_setup_data || child_setup);
        g_return_if_fail(!child_setup_data_destroy || child_setup_data);
        g_return_if_fail(cancellable == nullptr || G_IS_CANCELLABLE (cancellable));

        GError *error = NULL;
        VtePty* pty = vte_terminal_pty_new_sync(terminal, pty_flags, cancellable, &error);
        if (pty == nullptr) {
                if (child_setup_data_destroy)
                        child_setup_data_destroy(child_setup_data);

                callback(terminal, -1, error, user_data);

                g_error_free(error);
                return;
        }

        vte_terminal_set_pty(terminal, pty);

        guint spawn_flags = (guint)spawn_flags_;

        /* We do NOT support this flag. If you want to have some FD open in the child
         * process, simply use a child setup function that unsets the CLOEXEC flag
         * on that FD.
         */
        spawn_flags &= ~G_SPAWN_LEAVE_DESCRIPTORS_OPEN;

        vte_pty_spawn_async(pty,
                            working_directory,
                            argv,
                            envv,
                            GSpawnFlags(spawn_flags),
                            child_setup, child_setup_data, child_setup_data_destroy,
                            timeout, cancellable,
                            spawn_async_cb,
                            spawn_async_callback_data_new(terminal, callback, user_data));
        g_object_unref(pty);
}

/**
 * vte_terminal_feed:
 * @terminal: a #VteTerminal
 * @data: (array length=length) (element-type guint8) (allow-none): a string in the terminal's current encoding
 * @length: the length of the string, or -1 to use the full length or a nul-terminated string
 *
 * Interprets @data as if it were data received from a child process.  This
 * can either be used to drive the terminal without a child process, or just
 * to mess with your users.
 */
void
vte_terminal_feed(VteTerminal *terminal,
                  const char *data,
                  gssize length)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(length == 0 || data != NULL);

        IMPL(terminal)->feed(data, length);
}

/**
 * vte_terminal_feed_child:
 * @terminal: a #VteTerminal
 * @text: (array length=length) (element-type gchar) (allow-none): data to send to the child
 * @length: length of @text in bytes, or -1 if @text is NUL-terminated
 *
 * Sends a block of UTF-8 text to the child as if it were entered by the user
 * at the keyboard.
 */
void
vte_terminal_feed_child(VteTerminal *terminal,
                        const char *text,
                        gssize length)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(length == 0 || text != NULL);

        IMPL(terminal)->feed_child(text, length);
}

/**
 * vte_terminal_feed_child_binary:
 * @terminal: a #VteTerminal
 * @data: (array length=length) (element-type guint8) (allow-none): data to send to the child
 * @length: length of @data
 *
 * Sends a block of binary data to the child.
 */
void
vte_terminal_feed_child_binary(VteTerminal *terminal,
                               const guint8 *data,
                               gsize length)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(length == 0 || data != NULL);

        IMPL(terminal)->feed_child_binary(data, length);
}

/**
 * VteSelectionFunc:
 * @terminal: terminal in which the cell is.
 * @column: column in which the cell is.
 * @row: row in which the cell is.
 * @data: (closure): user data.
 *
 * Specifies the type of a selection function used to check whether
 * a cell has to be selected or not.
 *
 * Returns: %TRUE if cell has to be selected; %FALSE if otherwise.
 */

static void
warn_if_callback(VteSelectionFunc func)
{
        if (!func)
                return;

#ifndef VTE_DEBUG
        static gboolean warned = FALSE;
        if (warned)
                return;
        warned = TRUE;
#endif
        g_warning ("VteSelectionFunc callback ignored.\n");
}

/**
 * vte_terminal_get_text:
 * @terminal: a #VteTerminal
 * @is_selected: (scope call) (allow-none): a #VteSelectionFunc callback
 * @user_data: (closure): user data to be passed to the callback
 * @attributes: (out caller-allocates) (transfer full) (array) (element-type Vte.CharAttributes): location for storing text attributes
 *
 * Extracts a view of the visible part of the terminal.  If @is_selected is not
 * %NULL, characters will only be read if @is_selected returns %TRUE after being
 * passed the column and row, respectively.  A #VteCharAttributes structure
 * is added to @attributes for each byte added to the returned string detailing
 * the character's position, colors, and other characteristics.
 *
 * Returns: (transfer full): a newly allocated text string, or %NULL.
 */
char *
vte_terminal_get_text(VteTerminal *terminal,
		      VteSelectionFunc is_selected,
		      gpointer user_data,
		      GArray *attributes)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
        warn_if_callback(is_selected);
        auto text = IMPL(terminal)->get_text_displayed(true /* wrap */,
                                                       false /* include trailing whitespace */,
                                                       attributes);
        if (text == nullptr)
                return nullptr;
        return (char*)g_string_free(text, FALSE);
}

/**
 * vte_terminal_get_text_include_trailing_spaces:
 * @terminal: a #VteTerminal
 * @is_selected: (scope call) (allow-none): a #VteSelectionFunc callback
 * @user_data: (closure): user data to be passed to the callback
 * @attributes: (out caller-allocates) (transfer full) (array) (element-type Vte.CharAttributes): location for storing text attributes
 *
 * Extracts a view of the visible part of the terminal.  If @is_selected is not
 * %NULL, characters will only be read if @is_selected returns %TRUE after being
 * passed the column and row, respectively.  A #VteCharAttributes structure
 * is added to @attributes for each byte added to the returned string detailing
 * the character's position, colors, and other characteristics. This function
 * differs from vte_terminal_get_text() in that trailing spaces at the end of
 * lines are included.
 *
 * Returns: (transfer full): a newly allocated text string, or %NULL.
 */
char *
vte_terminal_get_text_include_trailing_spaces(VteTerminal *terminal,
					      VteSelectionFunc is_selected,
					      gpointer user_data,
					      GArray *attributes)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
        warn_if_callback(is_selected);
        auto text = IMPL(terminal)->get_text_displayed(true /* wrap */,
                                                       true /* include trailing whitespace */,
                                                       attributes);
        if (text == nullptr)
                return nullptr;
        return (char*)g_string_free(text, FALSE);
}

/**
 * vte_terminal_get_text_range:
 * @terminal: a #VteTerminal
 * @start_row: first row to search for data
 * @start_col: first column to search for data
 * @end_row: last row to search for data
 * @end_col: last column to search for data
 * @is_selected: (scope call) (allow-none): a #VteSelectionFunc callback
 * @user_data: (closure): user data to be passed to the callback
 * @attributes: (out caller-allocates) (transfer full) (array) (element-type Vte.CharAttributes): location for storing text attributes
 *
 * Extracts a view of the visible part of the terminal.  If @is_selected is not
 * %NULL, characters will only be read if @is_selected returns %TRUE after being
 * passed the column and row, respectively.  A #VteCharAttributes structure
 * is added to @attributes for each byte added to the returned string detailing
 * the character's position, colors, and other characteristics.  The
 * entire scrollback buffer is scanned, so it is possible to read the entire
 * contents of the buffer using this function.
 *
 * Returns: (transfer full): a newly allocated text string, or %NULL.
 */
char *
vte_terminal_get_text_range(VteTerminal *terminal,
			    long start_row,
                            long start_col,
			    long end_row,
                            long end_col,
			    VteSelectionFunc is_selected,
			    gpointer user_data,
			    GArray *attributes)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
        warn_if_callback(is_selected);
        auto text = IMPL(terminal)->get_text(start_row, start_col,
                                             end_row, end_col,
                                             false /* block */,
                                             true /* wrap */,
                                             true /* include trailing whitespace */,
                                             attributes);
        if (text == nullptr)
                return nullptr;
        return (char*)g_string_free(text, FALSE);
}

/**
 * vte_terminal_reset:
 * @terminal: a #VteTerminal
 * @clear_tabstops: whether to reset tabstops
 * @clear_history: whether to empty the terminal's scrollback buffer
 *
 * Resets as much of the terminal's internal state as possible, discarding any
 * unprocessed input data, resetting character attributes, cursor state,
 * national character set state, status line, terminal modes (insert/delete),
 * selection state, and encoding.
 *
 */
void
vte_terminal_reset(VteTerminal *terminal,
                   gboolean clear_tabstops,
                   gboolean clear_history)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        IMPL(terminal)->reset(clear_tabstops, clear_history, true);
}

/**
 * vte_terminal_set_size:
 * @terminal: a #VteTerminal
 * @columns: the desired number of columns
 * @rows: the desired number of rows
 *
 * Attempts to change the terminal's size in terms of rows and columns.  If
 * the attempt succeeds, the widget will resize itself to the proper size.
 */
void
vte_terminal_set_size(VteTerminal *terminal,
                      long columns,
                      long rows)
{
        g_return_if_fail(columns >= 1);
        g_return_if_fail(rows >= 1);

        IMPL(terminal)->set_size(columns, rows);
}

/**
 * vte_terminal_get_text_blink_mode:
 * @terminal: a #VteTerminal
 *
 * Checks whether or not the terminal will allow blinking text.
 *
 * Returns: the blinking setting
 *
 * Since: 0.52
 */
VteTextBlinkMode
vte_terminal_get_text_blink_mode(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), VTE_TEXT_BLINK_ALWAYS);
        return IMPL(terminal)->m_text_blink_mode;
}

/**
 * vte_terminal_set_text_blink_mode:
 * @terminal: a #VteTerminal
 * @text_blink_mode: the #VteTextBlinkMode to use
 *
 * Controls whether or not the terminal will allow blinking text.
 *
 * Since: 0.52
 */
void
vte_terminal_set_text_blink_mode(VteTerminal *terminal,
                                     VteTextBlinkMode text_blink_mode)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_text_blink_mode(text_blink_mode))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_TEXT_BLINK_MODE]);
}

/**
 * vte_terminal_get_allow_bold:
 * @terminal: a #VteTerminal
 *
 * Checks whether or not the terminal will attempt to draw bold text,
 * either by using a bold font variant or by repainting text with a different
 * offset.
 *
 * Returns: %TRUE if bolding is enabled, %FALSE if not
 */
gboolean
vte_terminal_get_allow_bold(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->m_allow_bold;
}

/**
 * vte_terminal_set_allow_bold:
 * @terminal: a #VteTerminal
 * @allow_bold: %TRUE if the terminal should attempt to draw bold text
 *
 * Controls whether or not the terminal will attempt to draw bold text,
 * either by using a bold font variant or by repainting text with a different
 * offset.
 */
void
vte_terminal_set_allow_bold(VteTerminal *terminal,
                            gboolean allow_bold)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_allow_bold(allow_bold != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_ALLOW_BOLD]);
}

/**
 * vte_terminal_get_allow_hyperlink:
 * @terminal: a #VteTerminal
 *
 * Checks whether or not hyperlinks (OSC 8 escape sequence) are allowed.
 *
 * Returns: %TRUE if hyperlinks are enabled, %FALSE if not
 *
 * Since: 0.50
 */
gboolean
vte_terminal_get_allow_hyperlink(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        return IMPL(terminal)->m_allow_hyperlink;
}

/**
 * vte_terminal_set_allow_hyperlink:
 * @terminal: a #VteTerminal
 * @allow_hyperlink: %TRUE if the terminal should allow hyperlinks
 *
 * Controls whether or not hyperlinks (OSC 8 escape sequence) are allowed.
 *
 * Since: 0.50
 */
void
vte_terminal_set_allow_hyperlink(VteTerminal *terminal,
                                 gboolean allow_hyperlink)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_allow_hyperlink(allow_hyperlink != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_ALLOW_HYPERLINK]);
}

/**
 * vte_terminal_get_audible_bell:
 * @terminal: a #VteTerminal
 *
 * Checks whether or not the terminal will beep when the child outputs the
 * "bl" sequence.
 *
 * Returns: %TRUE if audible bell is enabled, %FALSE if not
 */
gboolean
vte_terminal_get_audible_bell(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->m_audible_bell;
}

/**
 * vte_terminal_set_audible_bell:
 * @terminal: a #VteTerminal
 * @is_audible: %TRUE if the terminal should beep
 *
 * Controls whether or not the terminal will beep when the child outputs the
 * "bl" sequence.
 */
void
vte_terminal_set_audible_bell(VteTerminal *terminal,
                              gboolean is_audible)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_audible_bell(is_audible != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_AUDIBLE_BELL]);
}

/**
 * vte_terminal_set_backspace_binding:
 * @terminal: a #VteTerminal
 * @binding: a #VteEraseBinding for the backspace key
 *
 * Modifies the terminal's backspace key binding, which controls what
 * string or control sequence the terminal sends to its child when the user
 * presses the backspace key.
 */
void
vte_terminal_set_backspace_binding(VteTerminal *terminal,
                                   VteEraseBinding binding)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(binding >= VTE_ERASE_AUTO && binding <= VTE_ERASE_TTY);

        if (IMPL(terminal)->set_backspace_binding(binding))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_BACKSPACE_BINDING]);
}

/**
 * vte_terminal_get_bold_is_bright:
 * @terminal: a #VteTerminal
 *
 * Checks whether the SGR 1 attribute also switches to the bright counterpart
 * of the first 8 palette colors, in addition to making them bold (legacy behavior)
 * or if SGR 1 only enables bold and leaves the color intact.
 *
 * Returns: %TRUE if bold also enables bright, %FALSE if not
 *
 * Since: 0.52
 */
gboolean
vte_terminal_get_bold_is_bright(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->m_bold_is_bright;
}
/**
 * vte_terminal_set_bold_is_bright:
 * @terminal: a #VteTerminal
 * @bold_is_bright: %TRUE if bold should also enable bright
 *
 * Sets whether the SGR 1 attribute also switches to the bright counterpart
 * of the first 8 palette colors, in addition to making them bold (legacy behavior)
 * or if SGR 1 only enables bold and leaves the color intact.
 *
 * Since: 0.52
 */
void
vte_terminal_set_bold_is_bright(VteTerminal *terminal,
                                gboolean bold_is_bright)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_bold_is_bright(bold_is_bright != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_BOLD_IS_BRIGHT]);
}

/**
 * vte_terminal_get_char_height:
 * @terminal: a #VteTerminal
 *
 * Returns: the height of a character cell
 *
 * Note that this method should rather be called vte_terminal_get_cell_height,
 * because the return value takes cell-height-scale into account.
 */
glong
vte_terminal_get_char_height(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), -1);
	return IMPL(terminal)->get_cell_height();
}

/**
 * vte_terminal_get_char_width:
 * @terminal: a #VteTerminal
 *
 * Returns: the width of a character cell
 *
 * Note that this method should rather be called vte_terminal_get_cell_width,
 * because the return value takes cell-width-scale into account.
 */
glong
vte_terminal_get_char_width(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), -1);
	return IMPL(terminal)->get_cell_width();
}

/**
 * vte_terminal_get_cjk_ambiguous_width:
 * @terminal: a #VteTerminal
 *
 * Returns whether ambiguous-width characters are narrow or wide when using
 * the UTF-8 encoding (vte_terminal_set_encoding()).
 *
 * Returns: 1 if ambiguous-width characters are narrow, or 2 if they are wide
 */
int
vte_terminal_get_cjk_ambiguous_width(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), 1);
        return IMPL(terminal)->m_utf8_ambiguous_width;
}

/**
 * vte_terminal_set_cjk_ambiguous_width:
 * @terminal: a #VteTerminal
 * @width: either 1 (narrow) or 2 (wide)
 *
 * This setting controls whether ambiguous-width characters are narrow or wide
 * when using the UTF-8 encoding (vte_terminal_set_encoding()). In all other encodings,
 * the width of ambiguous-width characters is fixed.
 */
void
vte_terminal_set_cjk_ambiguous_width(VteTerminal *terminal, int width)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(width == 1 || width == 2);

        if (IMPL(terminal)->set_cjk_ambiguous_width(width))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_CJK_AMBIGUOUS_WIDTH]);
}

/**
 * vte_terminal_set_color_background:
 * @terminal: a #VteTerminal
 * @background: the new background color
 *
 * Sets the background color for text which does not have a specific background
 * color assigned.  Only has effect when no background image is set and when
 * the terminal is not transparent.
 */
void
vte_terminal_set_color_background(VteTerminal *terminal,
                                  const GdkRGBA *background)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(background != NULL);
        g_return_if_fail(valid_color(background));

        auto impl = IMPL(terminal);
        impl->set_color_background(vte::color::rgb(background));
        impl->set_background_alpha(background->alpha);
}

/**
 * vte_terminal_set_color_bold:
 * @terminal: a #VteTerminal
 * @bold: (allow-none): the new bold color or %NULL
 *
 * Sets the color used to draw bold text in the default foreground color.
 * If @bold is %NULL then the default color is used.
 */
void
vte_terminal_set_color_bold(VteTerminal *terminal,
                            const GdkRGBA *bold)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(bold == nullptr || valid_color(bold));

        auto impl = IMPL(terminal);
        if (bold)
                impl->set_color_bold(vte::color::rgb(bold));
        else
                impl->reset_color_bold();
}

/**
 * vte_terminal_set_color_cursor:
 * @terminal: a #VteTerminal
 * @cursor_background: (allow-none): the new color to use for the text cursor, or %NULL
 *
 * Sets the background color for text which is under the cursor.  If %NULL, text
 * under the cursor will be drawn with foreground and background colors
 * reversed.
 */
void
vte_terminal_set_color_cursor(VteTerminal *terminal,
                              const GdkRGBA *cursor_background)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(cursor_background == nullptr || valid_color(cursor_background));

        auto impl = IMPL(terminal);
        if (cursor_background)
                impl->set_color_cursor_background(vte::color::rgb(cursor_background));
        else
                impl->reset_color_cursor_background();
}

/**
 * vte_terminal_set_color_cursor_foreground:
 * @terminal: a #VteTerminal
 * @cursor_foreground: (allow-none): the new color to use for the text cursor, or %NULL
 *
 * Sets the foreground color for text which is under the cursor.  If %NULL, text
 * under the cursor will be drawn with foreground and background colors
 * reversed.
 *
 * Since: 0.44
 */
void
vte_terminal_set_color_cursor_foreground(VteTerminal *terminal,
                                         const GdkRGBA *cursor_foreground)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(cursor_foreground == nullptr || valid_color(cursor_foreground));

        auto impl = IMPL(terminal);
        if (cursor_foreground)
                impl->set_color_cursor_foreground(vte::color::rgb(cursor_foreground));
        else
                impl->reset_color_cursor_foreground();
}

/**
 * vte_terminal_set_color_foreground:
 * @terminal: a #VteTerminal
 * @foreground: the new foreground color
 *
 * Sets the foreground color used to draw normal text.
 */
void
vte_terminal_set_color_foreground(VteTerminal *terminal,
                                  const GdkRGBA *foreground)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(foreground != nullptr);
        g_return_if_fail(valid_color(foreground));

        IMPL(terminal)->set_color_foreground(vte::color::rgb(foreground));
}

/**
 * vte_terminal_set_color_highlight:
 * @terminal: a #VteTerminal
 * @highlight_background: (allow-none): the new color to use for highlighted text, or %NULL
 *
 * Sets the background color for text which is highlighted.  If %NULL,
 * it is unset.  If neither highlight background nor highlight foreground are set,
 * highlighted text (which is usually highlighted because it is selected) will
 * be drawn with foreground and background colors reversed.
 */
void
vte_terminal_set_color_highlight(VteTerminal *terminal,
                                 const GdkRGBA *highlight_background)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(highlight_background == nullptr || valid_color(highlight_background));

        auto impl = IMPL(terminal);
        if (highlight_background)
                impl->set_color_highlight_background(vte::color::rgb(highlight_background));
        else
                impl->reset_color_highlight_background();
}

/**
 * vte_terminal_set_color_highlight_foreground:
 * @terminal: a #VteTerminal
 * @highlight_foreground: (allow-none): the new color to use for highlighted text, or %NULL
 *
 * Sets the foreground color for text which is highlighted.  If %NULL,
 * it is unset.  If neither highlight background nor highlight foreground are set,
 * highlighted text (which is usually highlighted because it is selected) will
 * be drawn with foreground and background colors reversed.
 */
void
vte_terminal_set_color_highlight_foreground(VteTerminal *terminal,
                                            const GdkRGBA *highlight_foreground)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(highlight_foreground == nullptr || valid_color(highlight_foreground));

        auto impl = IMPL(terminal);
        if (highlight_foreground)
                impl->set_color_highlight_foreground(vte::color::rgb(highlight_foreground));
        else
                impl->reset_color_highlight_foreground();
}

/**
 * vte_terminal_set_colors:
 * @terminal: a #VteTerminal
 * @foreground: (allow-none): the new foreground color, or %NULL
 * @background: (allow-none): the new background color, or %NULL
 * @palette: (array length=palette_size zero-terminated=0) (element-type Gdk.RGBA) (allow-none): the color palette
 * @palette_size: the number of entries in @palette
 *
 * @palette specifies the new values for the 256 palette colors: 8 standard colors,
 * their 8 bright counterparts, 6x6x6 color cube, and 24 grayscale colors.
 * Omitted entries will default to a hardcoded value.
 *
 * @palette_size must be 0, 8, 16, 232 or 256.
 *
 * If @foreground is %NULL and @palette_size is greater than 0, the new foreground
 * color is taken from @palette[7].  If @background is %NULL and @palette_size is
 * greater than 0, the new background color is taken from @palette[0].
 */
void
vte_terminal_set_colors(VteTerminal *terminal,
                        const GdkRGBA *foreground,
                        const GdkRGBA *background,
                        const GdkRGBA *palette,
                        gsize palette_size)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
	g_return_if_fail((palette_size == 0) ||
			 (palette_size == 8) ||
			 (palette_size == 16) ||
			 (palette_size == 232) ||
			 (palette_size == 256));
        g_return_if_fail(foreground == nullptr || valid_color(foreground));
        g_return_if_fail(background == nullptr || valid_color(background));
        for (gsize i = 0; i < palette_size; ++i)
                g_return_if_fail(valid_color(&palette[i]));

        vte::color::rgb fg;
        if (foreground)
                fg = vte::color::rgb(foreground);
        vte::color::rgb bg;
        if (background)
                bg = vte::color::rgb(background);

        vte::color::rgb* pal = nullptr;
        if (palette_size) {
                pal = g_new0(vte::color::rgb, palette_size);
                for (gsize i = 0; i < palette_size; ++i)
                        pal[i] = vte::color::rgb(palette[i]);
        }

        auto impl = IMPL(terminal);
        impl->set_colors(foreground ? &fg : nullptr,
                         background ? &bg : nullptr,
                         pal, palette_size);
        impl->set_background_alpha(background ? background->alpha : 1.0);
        g_free(pal);
}

/**
 * vte_terminal_set_default_colors:
 * @terminal: a #VteTerminal
 *
 * Reset the terminal palette to reasonable compiled-in default color.
 */
void
vte_terminal_set_default_colors(VteTerminal *terminal)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        IMPL(terminal)->set_colors_default();
}

/**
 * vte_terminal_get_column_count:
 * @terminal: a #VteTerminal
 *
 * Returns: the number of columns
 */
glong
vte_terminal_get_column_count(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), -1);
	return IMPL(terminal)->m_column_count;
}

/**
 * vte_terminal_get_current_directory_uri:
 * @terminal: a #VteTerminal
 *
 * Returns: (transfer none): the URI of the current directory of the
 *   process running in the terminal, or %NULL
 */
const char *
vte_terminal_get_current_directory_uri(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
        return IMPL(terminal)->m_current_directory_uri;
}

/**
 * vte_terminal_get_current_file_uri:
 * @terminal: a #VteTerminal
 *
 * Returns: (transfer none): the URI of the current file the
 *   process running in the terminal is operating on, or %NULL if
 *   not set
 */
const char *
vte_terminal_get_current_file_uri(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
        return IMPL(terminal)->m_current_file_uri;
}

/**
 * vte_terminal_get_cursor_blink_mode:
 * @terminal: a #VteTerminal
 *
 * Returns the currently set cursor blink mode.
 *
 * Return value: cursor blink mode.
 */
VteCursorBlinkMode
vte_terminal_get_cursor_blink_mode(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), VTE_CURSOR_BLINK_SYSTEM);

        return IMPL(terminal)->m_cursor_blink_mode;
}

/**
 * vte_terminal_set_cursor_blink_mode:
 * @terminal: a #VteTerminal
 * @mode: the #VteCursorBlinkMode to use
 *
 * Sets whether or not the cursor will blink. Using %VTE_CURSOR_BLINK_SYSTEM
 * will use the #GtkSettings::gtk-cursor-blink setting.
 */
void
vte_terminal_set_cursor_blink_mode(VteTerminal *terminal,
                                   VteCursorBlinkMode mode)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(mode >= VTE_CURSOR_BLINK_SYSTEM && mode <= VTE_CURSOR_BLINK_OFF);

        if (IMPL(terminal)->set_cursor_blink_mode(mode))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_CURSOR_BLINK_MODE]);
}

/**
 * vte_terminal_get_cursor_shape:
 * @terminal: a #VteTerminal
 *
 * Returns the currently set cursor shape.
 *
 * Return value: cursor shape.
 */
VteCursorShape
vte_terminal_get_cursor_shape(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), VTE_CURSOR_SHAPE_BLOCK);

        return IMPL(terminal)->m_cursor_shape;
}

/**
 * vte_terminal_set_cursor_shape:
 * @terminal: a #VteTerminal
 * @shape: the #VteCursorShape to use
 *
 * Sets the shape of the cursor drawn.
 */
void
vte_terminal_set_cursor_shape(VteTerminal *terminal, VteCursorShape shape)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(shape >= VTE_CURSOR_SHAPE_BLOCK && shape <= VTE_CURSOR_SHAPE_UNDERLINE);

        if (IMPL(terminal)->set_cursor_shape(shape))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_CURSOR_SHAPE]);
}

/**
 * vte_terminal_set_delete_binding:
 * @terminal: a #VteTerminal
 * @binding: a #VteEraseBinding for the delete key
 *
 * Modifies the terminal's delete key binding, which controls what
 * string or control sequence the terminal sends to its child when the user
 * presses the delete key.
 */
void
vte_terminal_set_delete_binding(VteTerminal *terminal,
                                VteEraseBinding binding)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(binding >= VTE_ERASE_AUTO && binding <= VTE_ERASE_TTY);

        if (IMPL(terminal)->set_delete_binding(binding))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_DELETE_BINDING]);
}

/**
 * vte_terminal_get_encoding:
 * @terminal: a #VteTerminal
 *
 * Determines the name of the encoding in which the terminal expects data to be
 * encoded.
 *
 * Returns: (transfer none): the current encoding for the terminal
 */
const char *
vte_terminal_get_encoding(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);
	return IMPL(terminal)->m_encoding;
}

/**
 * vte_terminal_set_encoding:
 * @terminal: a #VteTerminal
 * @codeset: (allow-none): a valid #GIConv target, or %NULL to use UTF-8
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Changes the encoding the terminal will expect data from the child to
 * be encoded with.  For certain terminal types, applications executing in the
 * terminal can change the encoding. If @codeset is %NULL, it uses "UTF-8".
 *
 * Returns: %TRUE if the encoding could be changed to the specified one,
 *  or %FALSE with @error set to %G_CONVERT_ERROR_NO_CONVERSION.
 */
gboolean
vte_terminal_set_encoding(VteTerminal *terminal,
                          const char *codeset,
                          GError **error)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        g_return_val_if_fail(error == NULL || *error == NULL, FALSE);

        GObject *object = G_OBJECT(terminal);
        g_object_freeze_notify(object);

        bool rv = IMPL(terminal)->set_encoding(codeset);
        if (rv)
                g_object_notify_by_pspec(object, pspecs[PROP_ENCODING]);
        else
                g_set_error(error, G_CONVERT_ERROR, G_CONVERT_ERROR_NO_CONVERSION,
                            _("Unable to convert characters from %s to %s."),
                            "UTF-8", codeset);

        g_object_thaw_notify(object);
        return rv;
}

/**
 * vte_terminal_get_font:
 * @terminal: a #VteTerminal
 *
 * Queries the terminal for information about the fonts which will be
 * used to draw text in the terminal.  The actual font takes the font scale
 * into account, this is not reflected in the return value, the unscaled
 * font is returned.
 *
 * Returns: (transfer none): a #PangoFontDescription describing the font the
 * terminal uses to render text at the default font scale of 1.0.
 */
const PangoFontDescription *
vte_terminal_get_font(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);

        return IMPL(terminal)->m_unscaled_font_desc;
}

/**
 * vte_terminal_set_font:
 * @terminal: a #VteTerminal
 * @font_desc: (allow-none): a #PangoFontDescription for the desired font, or %NULL
 *
 * Sets the font used for rendering all text displayed by the terminal,
 * overriding any fonts set using gtk_widget_modify_font().  The terminal
 * will immediately attempt to load the desired font, retrieve its
 * metrics, and attempt to resize itself to keep the same number of rows
 * and columns.  The font scale is applied to the specified font.
 */
void
vte_terminal_set_font(VteTerminal *terminal,
                      const PangoFontDescription *font_desc)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_font_desc(font_desc))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_FONT_DESC]);
}

/**
 * vte_terminal_get_font_scale:
 * @terminal: a #VteTerminal
 *
 * Returns: the terminal's font scale
 */
gdouble
vte_terminal_get_font_scale(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), 1.);

        return IMPL(terminal)->m_font_scale;
}

/**
 * vte_terminal_set_font_scale:
 * @terminal: a #VteTerminal
 * @scale: the font scale
 *
 * Sets the terminal's font scale to @scale.
 */
void
vte_terminal_set_font_scale(VteTerminal *terminal,
                            double scale)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        scale = CLAMP(scale, VTE_FONT_SCALE_MIN, VTE_FONT_SCALE_MAX);
        if (IMPL(terminal)->set_font_scale(scale))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_FONT_SCALE]);
}

/**
 * vte_terminal_get_cell_height_scale:
 * @terminal: a #VteTerminal
 *
 * Returns: the terminal's cell height scale
 *
 * Since: 0.52
 */
double
vte_terminal_get_cell_height_scale(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), 1.);

        return IMPL(terminal)->m_cell_height_scale;
}

/**
 * vte_terminal_set_cell_height_scale:
 * @terminal: a #VteTerminal
 * @scale: the cell height scale
 *
 * Sets the terminal's cell height scale to @scale.
 *
 * This can be used to increase the line spacing. (The font's height is not affected.)
 * Valid values go from 1.0 (default) to 2.0 ("double spacing").
 *
 * Since: 0.52
 */
void
vte_terminal_set_cell_height_scale(VteTerminal *terminal,
                                   double scale)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        scale = CLAMP(scale, VTE_CELL_SCALE_MIN, VTE_CELL_SCALE_MAX);
        if (IMPL(terminal)->set_cell_height_scale(scale))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_CELL_HEIGHT_SCALE]);
}

/**
 * vte_terminal_get_cell_width_scale:
 * @terminal: a #VteTerminal
 *
 * Returns: the terminal's cell width scale
 *
 * Since: 0.52
 */
double
vte_terminal_get_cell_width_scale(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), 1.);

        return IMPL(terminal)->m_cell_width_scale;
}

/**
 * vte_terminal_set_cell_width_scale:
 * @terminal: a #VteTerminal
 * @scale: the cell width scale
 *
 * Sets the terminal's cell width scale to @scale.
 *
 * This can be used to increase the letter spacing. (The font's width is not affected.)
 * Valid values go from 1.0 (default) to 2.0.
 *
 * Since: 0.52
 */
void
vte_terminal_set_cell_width_scale(VteTerminal *terminal,
                                  double scale)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        scale = CLAMP(scale, VTE_CELL_SCALE_MIN, VTE_CELL_SCALE_MAX);
        if (IMPL(terminal)->set_cell_width_scale(scale))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_CELL_WIDTH_SCALE]);
}

/* Just some arbitrary minimum values */
#define MIN_COLUMNS (16)
#define MIN_ROWS    (2)

/**
 * vte_terminal_get_geometry_hints:
 * @terminal: a #VteTerminal
 * @hints: (out caller-allocates): a #GdkGeometry to fill in
 * @min_rows: the minimum number of rows to request
 * @min_columns: the minimum number of columns to request
 *
 * Fills in some @hints from @terminal's geometry. The hints
 * filled are those covered by the %GDK_HINT_RESIZE_INC,
 * %GDK_HINT_MIN_SIZE and %GDK_HINT_BASE_SIZE flags.
 *
 * See gtk_window_set_geometry_hints() for more information.
 *
 * @terminal must be realized (see gtk_widget_get_realized()).
 *
 * Deprecated: 0.52
 */
void
vte_terminal_get_geometry_hints(VteTerminal *terminal,
                                GdkGeometry *hints,
                                int min_rows,
                                int min_columns)
{
        GtkWidget *widget;
        GtkBorder padding;

        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(hints != NULL);
        widget = &terminal->widget;
        g_return_if_fail(gtk_widget_get_realized(widget));

        auto impl = IMPL(terminal);

        auto context = gtk_widget_get_style_context(widget);
        gtk_style_context_get_padding(context, gtk_style_context_get_state(context),
                                      &padding);

        hints->base_width  = padding.left + padding.right;
        hints->base_height = padding.top  + padding.bottom;
        hints->width_inc   = impl->m_cell_width;
        hints->height_inc  = impl->m_cell_height;
        hints->min_width   = hints->base_width  + hints->width_inc  * min_columns;
        hints->min_height  = hints->base_height + hints->height_inc * min_rows;

	_vte_debug_print(VTE_DEBUG_WIDGET_SIZE,
                         "[Terminal %p] Geometry cell       width %ld height %ld\n"
                         "                       base       width %d height %d\n"
                         "                       increments width %d height %d\n"
                         "                       minimum    width %d height %d\n",
                         terminal,
                         impl->m_cell_width, impl->m_cell_height,
                         hints->base_width, hints->base_height,
                         hints->width_inc, hints->height_inc,
                         hints->min_width, hints->min_height);
}

/**
 * vte_terminal_set_geometry_hints_for_window:
 * @terminal: a #VteTerminal
 * @window: a #GtkWindow
 *
 * Sets @terminal as @window's geometry widget. See
 * gtk_window_set_geometry_hints() for more information.
 *
 * @terminal must be realized (see gtk_widget_get_realized()).
 *
 * Deprecated: 0.52
 */
void
vte_terminal_set_geometry_hints_for_window(VteTerminal *terminal,
                                           GtkWindow *window)
{
        GdkGeometry hints;

        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(gtk_widget_get_realized(&terminal->widget));

        vte_terminal_get_geometry_hints(terminal, &hints, MIN_ROWS, MIN_COLUMNS);
        gtk_window_set_geometry_hints(window,
#if GTK_CHECK_VERSION (3, 19, 5)
                                      NULL,
#else
                                      &terminal->widget,
#endif
                                      &hints,
                                      (GdkWindowHints)(GDK_HINT_RESIZE_INC |
                                                       GDK_HINT_MIN_SIZE |
                                                       GDK_HINT_BASE_SIZE));
}

/**
 * vte_terminal_get_has_selection:
 * @terminal: a #VteTerminal
 *
 * Checks if the terminal currently contains selected text.  Note that this
 * is different from determining if the terminal is the owner of any
 * #GtkClipboard items.
 *
 * Returns: %TRUE if part of the text in the terminal is selected.
 */
gboolean
vte_terminal_get_has_selection(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->m_has_selection;
}

/**
 * vte_terminal_get_icon_title:
 * @terminal: a #VteTerminal
 *
 * Returns: (transfer none): the icon title
 */
const char *
vte_terminal_get_icon_title(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), "");
	return IMPL(terminal)->m_icon_title;
}

/**
 * vte_terminal_get_input_enabled:
 * @terminal: a #VteTerminal
 *
 * Returns whether the terminal allow user input.
 */
gboolean
vte_terminal_get_input_enabled (VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);

        return IMPL(terminal)->m_input_enabled;
}

/**
 * vte_terminal_set_input_enabled:
 * @terminal: a #VteTerminal
 * @enabled: whether to enable user input
 *
 * Enables or disables user input. When user input is disabled,
 * the terminal's child will not receive any key press, or mouse button
 * press or motion events sent to it.
 */
void
vte_terminal_set_input_enabled (VteTerminal *terminal,
                                gboolean enabled)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_input_enabled(enabled != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_INPUT_ENABLED]);
}

/**
 * vte_terminal_get_mouse_autohide:
 * @terminal: a #VteTerminal
 *
 * Determines the value of the terminal's mouse autohide setting.  When
 * autohiding is enabled, the mouse cursor will be hidden when the user presses
 * a key and shown when the user moves the mouse.  This setting can be changed
 * using vte_terminal_set_mouse_autohide().
 *
 * Returns: %TRUE if autohiding is enabled, %FALSE if not
 */
gboolean
vte_terminal_get_mouse_autohide(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->m_mouse_autohide;
}

/**
 * vte_terminal_set_mouse_autohide:
 * @terminal: a #VteTerminal
 * @setting: whether the mouse pointer should autohide
 *
 * Changes the value of the terminal's mouse autohide setting.  When autohiding
 * is enabled, the mouse cursor will be hidden when the user presses a key and
 * shown when the user moves the mouse.  This setting can be read using
 * vte_terminal_get_mouse_autohide().
 */
void
vte_terminal_set_mouse_autohide(VteTerminal *terminal, gboolean setting)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_mouse_autohide(setting != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_MOUSE_POINTER_AUTOHIDE]);
}

/**
 * vte_terminal_set_pty:
 * @terminal: a #VteTerminal
 * @pty: (allow-none): a #VtePty, or %NULL
 *
 * Sets @pty as the PTY to use in @terminal.
 * Use %NULL to unset the PTY.
 */
void
vte_terminal_set_pty(VteTerminal *terminal,
                     VtePty *pty)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(pty == NULL || VTE_IS_PTY(pty));

        GObject *object = G_OBJECT(terminal);
        g_object_freeze_notify(object);

        if (IMPL(terminal)->set_pty(pty))
                g_object_notify_by_pspec(object, pspecs[PROP_PTY]);

        g_object_thaw_notify(object);
}

/**
 * vte_terminal_get_pty:
 * @terminal: a #VteTerminal
 *
 * Returns the #VtePty of @terminal.
 *
 * Returns: (transfer none): a #VtePty, or %NULL
 */
VtePty *
vte_terminal_get_pty(VteTerminal *terminal)
{
        g_return_val_if_fail (VTE_IS_TERMINAL (terminal), NULL);

        return IMPL(terminal)->m_pty;
}

/**
 * vte_terminal_get_rewrap_on_resize:
 * @terminal: a #VteTerminal
 *
 * Checks whether or not the terminal will rewrap its contents upon resize.
 *
 * Returns: %TRUE if rewrapping is enabled, %FALSE if not
 */
gboolean
vte_terminal_get_rewrap_on_resize(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
	return IMPL(terminal)->m_rewrap_on_resize;
}

/**
 * vte_terminal_set_rewrap_on_resize:
 * @terminal: a #VteTerminal
 * @rewrap: %TRUE if the terminal should rewrap on resize
 *
 * Controls whether or not the terminal will rewrap its contents, including
 * the scrollback history, whenever the terminal's width changes.
 */
void
vte_terminal_set_rewrap_on_resize(VteTerminal *terminal,
                                  gboolean rewrap)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_rewrap_on_resize(rewrap != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_REWRAP_ON_RESIZE]);
}

/**
 * vte_terminal_get_row_count:
 * @terminal: a #VteTerminal
 *
 *
 * Returns: the number of rows
 */
glong
vte_terminal_get_row_count(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), -1);
	return IMPL(terminal)->m_row_count;
}

/**
 * vte_terminal_set_scrollback_lines:
 * @terminal: a #VteTerminal
 * @lines: the length of the history buffer
 *
 * Sets the length of the scrollback buffer used by the terminal.  The size of
 * the scrollback buffer will be set to the larger of this value and the number
 * of visible rows the widget can display, so 0 can safely be used to disable
 * scrollback.
 *
 * A negative value means "infinite scrollback".
 *
 * Note that this setting only affects the normal screen buffer.
 * No scrollback is allowed on the alternate screen buffer.
 */
void
vte_terminal_set_scrollback_lines(VteTerminal *terminal, glong lines)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));
        g_return_if_fail(lines >= -1);

        GObject *object = G_OBJECT(terminal);
        g_object_freeze_notify(object);

        if (IMPL(terminal)->set_scrollback_lines(lines))
                g_object_notify_by_pspec(object, pspecs[PROP_SCROLLBACK_LINES]);

        g_object_thaw_notify(object);
}

/**
 * vte_terminal_get_scrollback_lines:
 * @terminal: a #VteTerminal
 *
 * Returns: length of the scrollback buffer used by the terminal.
 * A negative value means "infinite scrollback".
 *
 * Since: 0.52
 */
glong
vte_terminal_get_scrollback_lines(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), 0);
        return IMPL(terminal)->m_scrollback_lines;
}

/**
 * vte_terminal_set_scroll_on_keystroke:
 * @terminal: a #VteTerminal
 * @scroll: whether the terminal should scroll on keystrokes
 *
 * Controls whether or not the terminal will forcibly scroll to the bottom of
 * the viewable history when the user presses a key.  Modifier keys do not
 * trigger this behavior.
 */
void
vte_terminal_set_scroll_on_keystroke(VteTerminal *terminal,
                                     gboolean scroll)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_scroll_on_keystroke(scroll != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_SCROLL_ON_OUTPUT]);
}

/**
 * vte_terminal_get_scroll_on_keystroke:
 * @terminal: a #VteTerminal
 *
 * Returns: whether or not the terminal will forcibly scroll to the bottom of
 * the viewable history when the user presses a key.  Modifier keys do not
 * trigger this behavior.
 *
 * Since: 0.52
 */
gboolean
vte_terminal_get_scroll_on_keystroke(VteTerminal *terminal)
{
    g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
    return IMPL(terminal)->m_scroll_on_keystroke;
}

/**
 * vte_terminal_set_scroll_on_output:
 * @terminal: a #VteTerminal
 * @scroll: whether the terminal should scroll on output
 *
 * Controls whether or not the terminal will forcibly scroll to the bottom of
 * the viewable history when the new data is received from the child.
 */
void
vte_terminal_set_scroll_on_output(VteTerminal *terminal,
                                  gboolean scroll)
{
	g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_scroll_on_output(scroll != FALSE))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_SCROLL_ON_OUTPUT]);
}

/**
 * vte_terminal_get_scroll_on_output:
 * @terminal: a #VteTerminal
 *
 * Returns: whether or not the terminal will forcibly scroll to the bottom of
 * the viewable history when the new data is received from the child.
 *
 * Since: 0.52
 */
gboolean
vte_terminal_get_scroll_on_output(VteTerminal *terminal)
{
    g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
    return IMPL(terminal)->m_scroll_on_output;
}

/**
 * vte_terminal_get_window_title:
 * @terminal: a #VteTerminal
 *
 * Returns: (transfer none): the window title
 */
const char *
vte_terminal_get_window_title(VteTerminal *terminal)
{
	g_return_val_if_fail(VTE_IS_TERMINAL(terminal), "");
	return IMPL(terminal)->m_window_title;
}

/**
 * vte_terminal_get_word_char_exceptions:
 * @terminal: a #VteTerminal
 *
 * Returns the set of characters which will be considered parts of a word
 * when doing word-wise selection, in addition to the default which only
 * considers alphanumeric characters part of a word.
 *
 * If %NULL, a built-in set is used.
 *
 * Returns: (transfer none): a string, or %NULL
 *
 * Since: 0.40
 */
const char *
vte_terminal_get_word_char_exceptions(VteTerminal *terminal)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), NULL);

        return IMPL(terminal)->m_word_char_exceptions_string;
}

/**
 * vte_terminal_set_word_char_exceptions:
 * @terminal: a #VteTerminal
 * @exceptions: a string of ASCII punctuation characters, or %NULL
 *
 * With this function you can provide a set of characters which will
 * be considered parts of a word when doing word-wise selection, in
 * addition to the default which only considers alphanumeric characters
 * part of a word.
 *
 * The characters in @exceptions must be non-alphanumeric, each character
 * must occur only once, and if @exceptions contains the character
 * U+002D HYPHEN-MINUS, it must be at the start of the string.
 *
 * Use %NULL to reset the set of exception characters to the default.
 *
 * Since: 0.40
 */
void
vte_terminal_set_word_char_exceptions(VteTerminal *terminal,
                                      const char *exceptions)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        if (IMPL(terminal)->set_word_char_exceptions(exceptions))
                g_object_notify_by_pspec(G_OBJECT(terminal), pspecs[PROP_WORD_CHAR_EXCEPTIONS]);
}

/**
 * vte_terminal_write_contents_sync:
 * @terminal: a #VteTerminal
 * @stream: a #GOutputStream to write to
 * @flags: a set of #VteWriteFlags
 * @cancellable: (allow-none): a #GCancellable object, or %NULL
 * @error: (allow-none): a #GError location to store the error occuring, or %NULL
 *
 * Write contents of the current contents of @terminal (including any
 * scrollback history) to @stream according to @flags.
 *
 * If @cancellable is not %NULL, then the operation can be cancelled by triggering
 * the cancellable object from another thread. If the operation was cancelled,
 * the error %G_IO_ERROR_CANCELLED will be returned in @error.
 *
 * This is a synchronous operation and will make the widget (and input
 * processing) during the write operation, which may take a long time
 * depending on scrollback history and @stream availability for writing.
 *
 * Returns: %TRUE on success, %FALSE if there was an error
 */
gboolean
vte_terminal_write_contents_sync (VteTerminal *terminal,
                                  GOutputStream *stream,
                                  VteWriteFlags flags,
                                  GCancellable *cancellable,
                                  GError **error)
{
        g_return_val_if_fail(VTE_IS_TERMINAL(terminal), FALSE);
        g_return_val_if_fail(G_IS_OUTPUT_STREAM(stream), FALSE);

        return IMPL(terminal)->write_contents_sync(stream, flags, cancellable, error);
}

/**
 * vte_terminal_set_clear_background:
 * @terminal: a #VteTerminal
 * @setting:
 *
 * Sets whether to paint the background with the background colour.
 * The default is %TRUE.
 *
 * This function is rarely useful. One use for it is to add a background
 * image to the terminal.
 *
 * Since: 0.52
 */
void
vte_terminal_set_clear_background(VteTerminal* terminal,
                                  gboolean setting)
{
        g_return_if_fail(VTE_IS_TERMINAL(terminal));

        IMPL(terminal)->set_clear_background(setting != FALSE);
}
