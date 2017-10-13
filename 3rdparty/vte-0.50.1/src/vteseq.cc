/*
 * Copyright (C) 2001-2004 Red Hat, Inc.
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
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "config.h"

#include <search.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#ifdef HAVE_SYS_SYSLIMITS_H
#include <sys/syslimits.h>
#endif

#include <glib.h>

#include <vte/vte.h>
#include "vteinternal.hh"
#include "vtegtk.hh"
#include "caps.h"
#include "debug.h"

#define BEL "\007"
#define ST _VTE_CAP_ST

/* FUNCTIONS WE USE */

static void
display_control_sequence(const char *name, GValueArray *params)
{
#ifdef VTE_DEBUG
	guint i;
	long l;
	const char *s;
	const gunichar *w;
	GValue *value;
	g_printerr("%s(", name);
	if (params != NULL) {
		for (i = 0; i < params->n_values; i++) {
			value = g_value_array_get_nth(params, i);
			if (i > 0) {
				g_printerr(", ");
			}
			if (G_VALUE_HOLDS_LONG(value)) {
				l = g_value_get_long(value);
				g_printerr("LONG(%ld)", l);
			} else
			if (G_VALUE_HOLDS_STRING(value)) {
				s = g_value_get_string(value);
				g_printerr("STRING(\"%s\")", s);
			} else
			if (G_VALUE_HOLDS_POINTER(value)) {
				w = (const gunichar *)g_value_get_pointer(value);
				g_printerr("WSTRING(\"%ls\")", (const wchar_t*) w);
			}
		}
	}
	g_printerr(")\n");
#endif
}


/* A couple are duplicated from vte.c, to keep them static... */

/* Check how long a string of unichars is.  Slow version. */
static gssize
vte_unichar_strlen(gunichar *c)
{
	int i;
	for (i = 0; c[i] != 0; i++) ;
	return i;
}

/* Convert a wide character string to a multibyte string */
char*
VteTerminalPrivate::ucs4_to_utf8(guchar const* in)
{
	gchar *out = NULL;
	guchar *buf = NULL, *bufptr = NULL;
	gsize inlen, outlen;
	VteConv conv;

	conv = _vte_conv_open ("UTF-8", VTE_CONV_GUNICHAR_TYPE);

	if (conv != VTE_INVALID_CONV) {
		inlen = vte_unichar_strlen ((gunichar *) in) * sizeof (gunichar);
		outlen = (inlen * VTE_UTF8_BPC) + 1;

		_vte_byte_array_set_minimum_size (m_conv_buffer, outlen);
		buf = bufptr = m_conv_buffer->data;

		if (_vte_conv (conv, &in, &inlen, &buf, &outlen) == (size_t) -1) {
			_vte_debug_print (VTE_DEBUG_IO,
					  "Error converting %ld string bytes (%s), skipping.\n",
					  (long) _vte_byte_array_length (m_outgoing),
					  g_strerror (errno));
			bufptr = NULL;
		} else {
			out = g_strndup ((gchar *) bufptr, buf - bufptr);
		}
	}

	_vte_conv_close (conv);

	return out;
}

/* Emit a "bell" signal. */
void
VteTerminalPrivate::emit_bell()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `bell'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_BELL], 0);
}


/* Emit a "deiconify-window" signal. */
void
VteTerminalPrivate::emit_deiconify_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `deiconify-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_DEICONIFY_WINDOW], 0);
}

/* Emit a "iconify-window" signal. */
void
VteTerminalPrivate::emit_iconify_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `iconify-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_ICONIFY_WINDOW], 0);
}

/* Emit a "raise-window" signal. */
void
VteTerminalPrivate::emit_raise_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `raise-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_RAISE_WINDOW], 0);
}

/* Emit a "lower-window" signal. */
void
VteTerminalPrivate::emit_lower_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `lower-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_LOWER_WINDOW], 0);
}

/* Emit a "maximize-window" signal. */
void
VteTerminalPrivate::emit_maximize_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `maximize-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_MAXIMIZE_WINDOW], 0);
}

/* Emit a "refresh-window" signal. */
void
VteTerminalPrivate::emit_refresh_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `refresh-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_REFRESH_WINDOW], 0);
}

/* Emit a "restore-window" signal. */
void
VteTerminalPrivate::emit_restore_window()
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `restore-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_RESTORE_WINDOW], 0);
}

/* Emit a "move-window" signal.  (Pixels.) */
void
VteTerminalPrivate::emit_move_window(guint x,
                                     guint y)
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `move-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_MOVE_WINDOW], 0, x, y);
}

/* Emit a "resize-window" signal.  (Grid size.) */
void
VteTerminalPrivate::emit_resize_window(guint columns,
                                       guint rows)
{
        _vte_debug_print(VTE_DEBUG_SIGNALS, "Emitting `resize-window'.\n");
        g_signal_emit(m_terminal, signals[SIGNAL_RESIZE_WINDOW], 0, columns, rows);
}


/* Some common functions */

/* In Xterm, upon printing a character in the last column the cursor doesn't
 * advance.  It's special cased that printing the following letter will first
 * wrap to the next row.
 *
 * As a rule of thumb, escape sequences that move the cursor (e.g. cursor up)
 * or immediately update the visible contents (e.g. clear in line) disable
 * this special mode, whereas escape sequences with no immediate visible
 * effect (e.g. color change) leave this special mode on.  There are
 * exceptions of course (e.g. scroll up).
 *
 * In VTE, a different technical approach is used.  The cursor is advanced to
 * the invisible column on the right, but it's set back to the visible
 * rightmost column whenever necessary (that is, before handling any of the
 * sequences that disable the special cased mode in xterm).  (Bug 731155.)
 */
void
VteTerminalPrivate::ensure_cursor_is_onscreen()
{
        if (G_UNLIKELY (m_screen->cursor.col >= m_column_count))
                m_screen->cursor.col = m_column_count - 1;
}

void
VteTerminalPrivate::seq_home_cursor()
{
        set_cursor_coords(0, 0);
}

/* Clear the entire screen. */
void
VteTerminalPrivate::seq_clear_screen()
{
        auto row = m_screen->cursor.row - m_screen->insert_delta;
        auto initial = _vte_ring_next(m_screen->row_data);
	/* Add a new screen's worth of rows. */
        for (auto i = 0; i < m_row_count; i++)
                ring_append(true);
	/* Move the cursor and insertion delta to the first line in the
	 * newly-cleared area and scroll if need be. */
        m_screen->insert_delta = initial;
        m_screen->cursor.row = row + m_screen->insert_delta;
        adjust_adjustments();
	/* Redraw everything. */
        invalidate_all();
	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Clear the current line. */
void
VteTerminalPrivate::seq_clear_current_line()
{
	VteRowData *rowdata;

	/* If the cursor is actually on the screen, clear data in the row
	 * which corresponds to the cursor. */
        if (_vte_ring_next(m_screen->row_data) > m_screen->cursor.row) {
		/* Get the data for the row which the cursor points to. */
                rowdata = _vte_ring_index_writable(m_screen->row_data, m_screen->cursor.row);
		g_assert(rowdata != NULL);
		/* Remove it. */
		_vte_row_data_shrink (rowdata, 0);
		/* Add enough cells to the end of the line to fill out the row. */
                _vte_row_data_fill (rowdata, &m_fill_defaults, m_column_count);
		rowdata->attr.soft_wrapped = 0;
		/* Repaint this row. */
		invalidate_cells(0, m_column_count,
                                 m_screen->cursor.row, 1);
	}

	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Clear above the current line. */
void
VteTerminalPrivate::seq_clear_above_current()
{
	/* If the cursor is actually on the screen, clear data in the row
	 * which corresponds to the cursor. */
        for (auto i = m_screen->insert_delta; i < m_screen->cursor.row; i++) {
                if (_vte_ring_next(m_screen->row_data) > i) {
			/* Get the data for the row we're erasing. */
                        auto rowdata = _vte_ring_index_writable(m_screen->row_data, i);
			g_assert(rowdata != NULL);
			/* Remove it. */
			_vte_row_data_shrink (rowdata, 0);
			/* Add new cells until we fill the row. */
                        _vte_row_data_fill (rowdata, &m_fill_defaults, m_column_count);
			rowdata->attr.soft_wrapped = 0;
			/* Repaint the row. */
			invalidate_cells(0, m_column_count, i, 1);
		}
	}
	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Scroll the text, but don't move the cursor.  Negative = up, positive = down. */
void
VteTerminalPrivate::seq_scroll_text(vte::grid::row_t scroll_amount)
{
        vte::grid::row_t start, end;
        if (m_scrolling_restricted) {
                start = m_screen->insert_delta + m_scrolling_region.start;
                end = m_screen->insert_delta + m_scrolling_region.end;
	} else {
                start = m_screen->insert_delta;
                end = start + m_row_count - 1;
	}

        while (_vte_ring_next(m_screen->row_data) <= end)
                ring_append(false);

	if (scroll_amount > 0) {
		for (auto i = 0; i < scroll_amount; i++) {
                        ring_remove(end);
                        ring_insert(start, true);
		}
	} else {
		for (auto i = 0; i < -scroll_amount; i++) {
                        ring_remove(start);
                        ring_insert(end, true);
		}
	}

	/* Update the display. */
        scroll_region(start, end - start + 1, scroll_amount);

	/* Adjust the scrollbars if necessary. */
        adjust_adjustments();

	/* We've modified the display.  Make a note of it. */
        m_text_inserted_flag = TRUE;
        m_text_deleted_flag = TRUE;
}

/* Restore cursor. */
static void
vte_sequence_handler_restore_cursor (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_restore_cursor();
}

void
VteTerminalPrivate::seq_restore_cursor()
{
        restore_cursor(m_screen);
        ensure_cursor_is_onscreen();
}

/* Save cursor. */
static void
vte_sequence_handler_save_cursor (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_save_cursor();
}

void
VteTerminalPrivate::seq_save_cursor()
{
        save_cursor(m_screen);
}

/* Switch to normal screen. */
static void
vte_sequence_handler_normal_screen (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_normal_screen();
}

void
VteTerminalPrivate::seq_normal_screen()
{
        seq_switch_screen(&m_normal_screen);
}

void
VteTerminalPrivate::seq_switch_screen(VteScreen *new_screen)
{
        /* if (new_screen == m_screen) return; ? */

        /* The two screens use different hyperlink pools, so carrying on the idx
         * wouldn't make sense and could lead to crashes.
         * Ideally we'd carry the target URI itself, but I'm just lazy.
         * Also, run a GC before we switch away from that screen. */
        m_hyperlink_hover_idx = _vte_ring_get_hyperlink_at_position(m_screen->row_data, -1, -1, true, NULL);
        g_assert (m_hyperlink_hover_idx == 0);
        m_hyperlink_hover_uri = NULL;
        emit_hyperlink_hover_uri_changed(NULL);  /* FIXME only emit if really changed */
        m_defaults.attr.hyperlink_idx = _vte_ring_get_hyperlink_idx(m_screen->row_data, NULL);
        g_assert (m_defaults.attr.hyperlink_idx == 0);

        /* cursor.row includes insert_delta, adjust accordingly */
        auto cr = m_screen->cursor.row - m_screen->insert_delta;
        m_screen = new_screen;
        m_screen->cursor.row = cr + m_screen->insert_delta;

        /* Make sure the ring is large enough */
        ensure_row();
}

/* Switch to alternate screen. */
static void
vte_sequence_handler_alternate_screen (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_alternate_screen();
}

void
VteTerminalPrivate::seq_alternate_screen()
{
        seq_switch_screen(&m_alternate_screen);
}

/* Switch to normal screen and restore cursor (in this order). */
static void
vte_sequence_handler_normal_screen_and_restore_cursor (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_normal_screen_and_restore_cursor();
}

void
VteTerminalPrivate::seq_normal_screen_and_restore_cursor()
{
        seq_normal_screen();
        seq_restore_cursor();
}

/* Save cursor and switch to alternate screen (in this order). */
static void
vte_sequence_handler_save_cursor_and_alternate_screen (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_save_cursor_and_alternate_screen();
}

void
VteTerminalPrivate::seq_save_cursor_and_alternate_screen()
{
        seq_save_cursor();
        seq_alternate_screen();
}

/* Set icon/window titles. */
void
VteTerminalPrivate::seq_set_title_internal(GValueArray *params,
                                           bool change_icon_title,
                                           bool change_window_title)
{
	GValue *value;
	char *title = NULL;

        if (change_icon_title == FALSE && change_window_title == FALSE)
		return;

	/* Get the string parameter's value. */
	value = g_value_array_get_nth(params, 0);
	if (value) {
		if (G_VALUE_HOLDS_LONG(value)) {
			/* Convert the long to a string. */
			title = g_strdup_printf("%ld", g_value_get_long(value));
		} else
		if (G_VALUE_HOLDS_STRING(value)) {
			/* Copy the string into the buffer. */
			title = g_value_dup_string(value);
		} else
		if (G_VALUE_HOLDS_POINTER(value)) {
                        title = ucs4_to_utf8((const guchar *)g_value_get_pointer (value));
		}
		if (title != NULL) {
			char *p, *validated;
			const char *end;

			/* Validate the text. */
			g_utf8_validate(title, strlen(title), &end);
			validated = g_strndup(title, end - title);

			/* No control characters allowed. */
			for (p = validated; *p != '\0'; p++) {
				if ((*p & 0x1f) == *p) {
					*p = ' ';
				}
			}

			/* Emit the signal */
                        if (change_window_title) {
                                g_free(m_window_title_changed);
                                m_window_title_changed = g_strdup(validated);
			}

                        if (change_icon_title) {
                                g_free(m_icon_title_changed);
                                m_icon_title_changed = g_strdup(validated);
			}

			g_free (validated);
			g_free(title);
		}
	}
}

/* Toggle a terminal mode. */
void
VteTerminalPrivate::seq_set_mode_internal(long setting,
                                          bool value)
{
	switch (setting) {
	case 2:		/* keyboard action mode (?) */
		break;
	case 4:		/* insert/overtype mode */
                m_insert_mode = value;
		break;
	case 12:	/* send/receive mode (local echo) */
                m_sendrecv_mode = value;
		break;
	case 20:	/* automatic newline / normal linefeed mode */
                m_linefeed_mode = value;
		break;
	default:
		break;
	}
}


/*
 * Sequence handling boilerplate
 */

/* Typedef the handle type */
typedef void (*VteTerminalSequenceHandler) (VteTerminalPrivate *that, GValueArray *params);

/* Prototype all handlers... */
#define VTE_SEQUENCE_HANDLER(name) \
	static void name (VteTerminalPrivate *that, GValueArray *params);
#include "vteseq-list.h"
#undef VTE_SEQUENCE_HANDLER


/* Call another function a given number of times, or once. */
static void
vte_sequence_handler_multiple_limited(VteTerminalPrivate *that,
                                      GValueArray *params,
                                      VteTerminalSequenceHandler handler,
                                      glong max)
{
	long val = 1;
	int i;
	GValue *value;

	if ((params != NULL) && (params->n_values > 0)) {
		value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			val = g_value_get_long(value);
			val = CLAMP(val, 1, max);	/* FIXME: vttest. */
		}
	}
	for (i = 0; i < val; i++)
		handler (that, NULL);
}

static void
vte_sequence_handler_multiple_r(VteTerminalPrivate *that,
                                GValueArray *params,
                                VteTerminalSequenceHandler handler)
{
        vte_sequence_handler_multiple_limited(that, params, handler,
                                              that->m_column_count - that->m_screen->cursor.col);
}

static void
vte_reset_mouse_smooth_scroll_delta(VteTerminalPrivate *that,
                                    GValueArray *params)
{
        that->set_mouse_smooth_scroll_delta(0.);
}

void
VteTerminalPrivate::set_mouse_smooth_scroll_delta(double value)
{
	m_mouse_smooth_scroll_delta = value;
}

static void
vte_set_focus_tracking_mode(VteTerminalPrivate *that,
                            GValueArray *params)
{
        /* We immediately send the terminal a focus event, since otherwise
         * it has no way to know the current status.
         */
        that->feed_focus_event_initial();
}

struct decset_t {
        gint16 setting;
        /* offset in VteTerminalPrivate (> 0) or VteScreen (< 0) */
        gint16 boffset;
        gint16 ioffset;
        gint16 poffset;
        gint16 fvalue;
        gint16 tvalue;
        VteTerminalSequenceHandler reset, set;
};

static int
decset_cmp(const void *va,
           const void *vb)
{
        const struct decset_t *a = (const struct decset_t *)va;
        const struct decset_t *b = (const struct decset_t *)vb;

        return a->setting < b->setting ? -1 : a->setting > b->setting;
}

/* Manipulate certain terminal attributes. */
static void
vte_sequence_handler_decset_internal(VteTerminalPrivate *that,
				     int setting,
				     gboolean restore,
				     gboolean save,
				     gboolean set)
{
	static const struct decset_t settings[] = {
#define PRIV_OFFSET(member) (G_STRUCT_OFFSET(VteTerminalPrivate, member))
#define SCREEN_OFFSET(member) (-G_STRUCT_OFFSET(VteScreen, member))
		/* 1: Application/normal cursor keys. */
		{1, 0, PRIV_OFFSET(m_cursor_mode), 0,
		 VTE_KEYMODE_NORMAL,
		 VTE_KEYMODE_APPLICATION,
		 NULL, NULL,},
		/* 2: disallowed, we don't do VT52. */
		{2, 0, 0, 0, 0, 0, NULL, NULL,},
                /* 3: DECCOLM set/reset to and from 132/80 columns */
                {3, 0, 0, 0,
                 FALSE,
                 TRUE,
                 NULL, NULL,},
		/* 5: Reverse video. */
                {5, PRIV_OFFSET(m_reverse_mode), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 6: Origin mode: when enabled, cursor positioning is
		 * relative to the scrolling region. */
                {6, PRIV_OFFSET(m_origin_mode), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 7: Wraparound mode. */
                {7, PRIV_OFFSET(m_autowrap), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 8: disallowed, keyboard repeat is set by user. */
		{8, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 9: Send-coords-on-click. */
		{9, 0, PRIV_OFFSET(m_mouse_tracking_mode), 0,
		 0,
		 MOUSE_TRACKING_SEND_XY_ON_CLICK,
		 vte_reset_mouse_smooth_scroll_delta,
		 vte_reset_mouse_smooth_scroll_delta,},
		/* 12: disallowed, cursor blinks is set by user. */
		{12, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 18: print form feed. */
		/* 19: set print extent to full screen. */
		/* 25: Cursor visible. */
		{25, PRIV_OFFSET(m_cursor_visible), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 30/rxvt: disallowed, scrollbar visibility is set by user. */
		{30, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 35/rxvt: disallowed, fonts set by user. */
		{35, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 38: enter Tektronix mode. */
                /* 40: Enable DECCOLM mode. */
                {40, PRIV_OFFSET(m_deccolm_mode), 0, 0,
                 FALSE,
                 TRUE,
                 NULL, NULL,},
		/* 41: more(1) fix. */
		/* 42: Enable NLS replacements. */
		/* 44: Margin bell. */
		{44, PRIV_OFFSET(m_margin_bell), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 47: Alternate screen. */
                {47, 0, 0, 0,
                 0,
                 0,
                 vte_sequence_handler_normal_screen,
                 vte_sequence_handler_alternate_screen,},
		/* 66: Keypad mode. */
		{66, PRIV_OFFSET(m_keypad_mode), 0, 0,
		 VTE_KEYMODE_NORMAL,
		 VTE_KEYMODE_APPLICATION,
		 NULL, NULL,},
		/* 67: disallowed, backspace key policy is set by user. */
		{67, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 1000: Send-coords-on-button. */
		{1000, 0, PRIV_OFFSET(m_mouse_tracking_mode), 0,
		 0,
		 MOUSE_TRACKING_SEND_XY_ON_BUTTON,
		 vte_reset_mouse_smooth_scroll_delta,
		 vte_reset_mouse_smooth_scroll_delta,},
		/* 1001: Hilite tracking. */
		{1001, 0, PRIV_OFFSET(m_mouse_tracking_mode), 0,
		 (0),
		 (MOUSE_TRACKING_HILITE_TRACKING),
		 vte_reset_mouse_smooth_scroll_delta,
		 vte_reset_mouse_smooth_scroll_delta,},
		/* 1002: Cell motion tracking. */
		{1002, 0, PRIV_OFFSET(m_mouse_tracking_mode), 0,
		 (0),
		 (MOUSE_TRACKING_CELL_MOTION_TRACKING),
		 vte_reset_mouse_smooth_scroll_delta,
		 vte_reset_mouse_smooth_scroll_delta,},
		/* 1003: All motion tracking. */
		{1003, 0, PRIV_OFFSET(m_mouse_tracking_mode), 0,
		 (0),
		 (MOUSE_TRACKING_ALL_MOTION_TRACKING),
		 vte_reset_mouse_smooth_scroll_delta,
		 vte_reset_mouse_smooth_scroll_delta,},
		/* 1004: Focus tracking. */
		{1004, PRIV_OFFSET(m_focus_tracking_mode), 0, 0,
		 FALSE,
		 TRUE,
                 NULL,
                 vte_set_focus_tracking_mode,},
		/* 1006: Extended mouse coordinates. */
		{1006, PRIV_OFFSET(m_mouse_xterm_extension), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 1007: Alternate screen scroll. */
		{1007, PRIV_OFFSET(m_alternate_screen_scroll), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 1010/rxvt: disallowed, scroll-on-output is set by user. */
		{1010, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 1011/rxvt: disallowed, scroll-on-keypress is set by user. */
		{1011, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 1015/urxvt: Extended mouse coordinates. */
		{1015, PRIV_OFFSET(m_mouse_urxvt_extension), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 1035: disallowed, don't know what to do with it. */
		{1035, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 1036: Meta-sends-escape. */
		{1036, PRIV_OFFSET(m_meta_sends_escape), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
		/* 1037: disallowed, delete key policy is set by user. */
		{1037, 0, 0, 0, 0, 0, NULL, NULL,},
		/* 1047: Use alternate screen buffer. */
                {1047, 0, 0, 0,
                 0,
                 0,
                 vte_sequence_handler_normal_screen,
                 vte_sequence_handler_alternate_screen,},
		/* 1048: Save/restore cursor position. */
		{1048, 0, 0, 0,
		 0,
		 0,
                 vte_sequence_handler_restore_cursor,
                 vte_sequence_handler_save_cursor,},
		/* 1049: Use alternate screen buffer, saving the cursor
		 * position. */
                {1049, 0, 0, 0,
                 0,
                 0,
                 vte_sequence_handler_normal_screen_and_restore_cursor,
                 vte_sequence_handler_save_cursor_and_alternate_screen,},
		/* 2004: Bracketed paste mode. */
		{2004, PRIV_OFFSET(m_bracketed_paste_mode), 0, 0,
		 FALSE,
		 TRUE,
		 NULL, NULL,},
#undef PRIV_OFFSET
#undef SCREEN_OFFSET
	};
        struct decset_t key;
        struct decset_t *found;

	/* Handle the setting. */
        key.setting = setting;
        found = (struct decset_t *)bsearch(&key, settings, G_N_ELEMENTS(settings), sizeof(settings[0]), decset_cmp);
        if (!found) {
		_vte_debug_print (VTE_DEBUG_MISC,
				  "DECSET/DECRESET mode %d not recognized, ignoring.\n",
				  setting);
                return;
	}

        key = *found;
        do {
                gboolean *bvalue = NULL;
                gint *ivalue = NULL;
                gpointer *pvalue = NULL, pfvalue = NULL, ptvalue = NULL;
                gpointer p;

		/* Handle settings we want to ignore. */
		if ((key.fvalue == key.tvalue) &&
		    (key.set == NULL) &&
		    (key.reset == NULL)) {
			break;
		}

#define STRUCT_MEMBER_P(type,total_offset) \
                (type) (total_offset >= 0 ? G_STRUCT_MEMBER_P(that, total_offset) : G_STRUCT_MEMBER_P(that->m_screen, -total_offset))

                if (key.boffset) {
                        bvalue = STRUCT_MEMBER_P(gboolean*, key.boffset);
                } else if (key.ioffset) {
                        ivalue = STRUCT_MEMBER_P(int*, key.ioffset);
                } else if (key.poffset) {
                        pvalue = STRUCT_MEMBER_P(gpointer*, key.poffset);
                        pfvalue = STRUCT_MEMBER_P(gpointer, key.fvalue);
                        ptvalue = STRUCT_MEMBER_P(gpointer, key.tvalue);
                }
#undef STRUCT_MEMBER_P

		/* Read the old setting. */
		if (restore) {
			p = g_hash_table_lookup(that->m_dec_saved,
						GINT_TO_POINTER(setting));
			set = (p != NULL);
			_vte_debug_print(VTE_DEBUG_PARSE,
					"Setting %d was %s.\n",
					setting, set ? "set" : "unset");
		}
		/* Save the current setting. */
		if (save) {
			if (bvalue) {
				set = *(bvalue) != FALSE;
			} else
			if (ivalue) {
                                set = *(ivalue) == (int)key.tvalue;
			} else
			if (pvalue) {
				set = *(pvalue) == ptvalue;
			}
			_vte_debug_print(VTE_DEBUG_PARSE,
					"Setting %d is %s, saving.\n",
					setting, set ? "set" : "unset");
			g_hash_table_insert(that->m_dec_saved,
					    GINT_TO_POINTER(setting),
					    GINT_TO_POINTER(set));
		}
		/* Change the current setting to match the new/saved value. */
		if (!save) {
			_vte_debug_print(VTE_DEBUG_PARSE,
					"Setting %d to %s.\n",
					setting, set ? "set" : "unset");
			if (key.set && set) {
				key.set (that, NULL);
			}
			if (bvalue) {
				*(bvalue) = set;
			} else
			if (ivalue) {
                                *(ivalue) = set ? (int)key.tvalue : (int)key.fvalue;
			} else
			if (pvalue) {
                                *(pvalue) = set ? ptvalue : pfvalue;
			}
			if (key.reset && !set) {
				key.reset (that, NULL);
			}
		}
	} while (0);

        that->seq_decset_internal_post(setting, set);
}

void
VteTerminalPrivate::seq_decset_internal_post(long setting,
                                             bool set)
{
	/* Do whatever's necessary when the setting changes. */
	switch (setting) {
	case 1:
		_vte_debug_print(VTE_DEBUG_KEYBOARD, set ?
				"Entering application cursor mode.\n" :
				"Leaving application cursor mode.\n");
		break;
	case 3:
                /* 3: DECCOLM set/reset to 132/80 columns mode, clear screen and cursor home */
                if (m_deccolm_mode) {
                        emit_resize_window(set ? 132 : 80,
                                           m_row_count);
                        seq_clear_screen();
                        seq_home_cursor();
                }
		break;
	case 5:
		/* Repaint everything in reverse mode. */
                invalidate_all();
		break;
	case 6:
		/* Reposition the cursor in its new home position. */
                seq_home_cursor();
		break;
	case 47:
	case 1047:
	case 1049:
                /* Clear the alternate screen if we're switching to it */
		if (set) {
			seq_clear_screen();
		}
		/* Reset scrollbars and repaint everything. */
		gtk_adjustment_set_value(m_vadjustment,
					 m_screen->scroll_delta);
		set_scrollback_lines(m_scrollback_lines);
                queue_contents_changed();
                invalidate_all();
		break;
	case 9:
	case 1000:
	case 1001:
	case 1002:
	case 1003:
                /* Mouse pointer might change. */
                apply_mouse_cursor();
		break;
	case 66:
		_vte_debug_print(VTE_DEBUG_KEYBOARD, set ?
				"Entering application keypad mode.\n" :
				"Leaving application keypad mode.\n");
		break;
	default:
		break;
	}
}

/* THE HANDLERS */

/* Do nothing. */
static void
vte_sequence_handler_nop (VteTerminalPrivate *that, GValueArray *params)
{
}

void
VteTerminalPrivate::set_character_replacements(unsigned slot,
                                               VteCharacterReplacement replacement)
{
        g_assert(slot < G_N_ELEMENTS(m_character_replacements));
        m_character_replacements[slot] = replacement;
}

/* G0 character set is a pass-thru (no mapping). */
static void
vte_sequence_handler_designate_g0_plain (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacements(0, VTE_CHARACTER_REPLACEMENT_NONE);
}

/* G0 character set is DEC Special Character and Line Drawing Set. */
static void
vte_sequence_handler_designate_g0_line_drawing (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacements(0, VTE_CHARACTER_REPLACEMENT_LINE_DRAWING);
}

/* G0 character set is British (# is converted to £). */
static void
vte_sequence_handler_designate_g0_british (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacements(0, VTE_CHARACTER_REPLACEMENT_BRITISH);
}

/* G1 character set is a pass-thru (no mapping). */
static void
vte_sequence_handler_designate_g1_plain (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacements(1, VTE_CHARACTER_REPLACEMENT_NONE);
}

/* G1 character set is DEC Special Character and Line Drawing Set. */
static void
vte_sequence_handler_designate_g1_line_drawing (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacements(1, VTE_CHARACTER_REPLACEMENT_LINE_DRAWING);
}

/* G1 character set is British (# is converted to £). */
static void
vte_sequence_handler_designate_g1_british (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacements(1, VTE_CHARACTER_REPLACEMENT_BRITISH);
}

void
VteTerminalPrivate::set_character_replacement(unsigned slot)
{
        g_assert(slot < G_N_ELEMENTS(m_character_replacements));
        m_character_replacement = &m_character_replacements[slot];
}

/* SI (shift in): switch to G0 character set. */
static void
vte_sequence_handler_shift_in (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacement(0);
}

/* SO (shift out): switch to G1 character set. */
static void
vte_sequence_handler_shift_out (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_character_replacement(1);
}

/* Beep. */
static void
vte_sequence_handler_bell (VteTerminalPrivate *that, GValueArray *params)
{
	that->beep();
        that->emit_bell();
}

/* Backtab. */
static void
vte_sequence_handler_cursor_back_tab (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_cursor_back_tab();
}

void
VteTerminalPrivate::seq_cursor_back_tab()
{
	/* Calculate which column is the previous tab stop. */
        auto newcol = m_screen->cursor.col;

	if (m_tabstops) {
		/* Find the next tabstop. */
		while (newcol > 0) {
			newcol--;
                        if (get_tabstop(newcol % m_column_count)) {
				break;
			}
		}
	}

	/* Warp the cursor. */
	_vte_debug_print(VTE_DEBUG_PARSE,
			"Moving cursor to column %ld.\n", (long)newcol);
        set_cursor_column(newcol);
}

/* Clear from the cursor position (inclusive!) to the beginning of the line. */
void
VteTerminalPrivate::seq_cb()
{
        ensure_cursor_is_onscreen();

	/* Get the data for the row which the cursor points to. */
	auto rowdata = ensure_row();
        /* Clean up Tab/CJK fragments. */
        cleanup_fragments(0, m_screen->cursor.col + 1);
	/* Clear the data up to the current column with the default
	 * attributes.  If there is no such character cell, we need
	 * to add one. */
        vte::grid::column_t i;
        for (i = 0; i <= m_screen->cursor.col; i++) {
                if (i < (glong) _vte_row_data_length (rowdata)) {
			/* Muck with the cell in this location. */
                        auto pcell = _vte_row_data_get_writable(rowdata, i);
                        *pcell = m_color_defaults;
		} else {
			/* Add new cells until we have one here. */
                        _vte_row_data_append (rowdata, &m_color_defaults);
		}
	}
	/* Repaint this row. */
        invalidate_cells(0, m_screen->cursor.col+1,
                         m_screen->cursor.row, 1);

	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Clear to the right of the cursor and below the current line. */
void
VteTerminalPrivate::seq_cd()
{
        ensure_cursor_is_onscreen();

	/* If the cursor is actually on the screen, clear the rest of the
	 * row the cursor is on and all of the rows below the cursor. */
        VteRowData *rowdata;
        auto i = m_screen->cursor.row;
	if (i < _vte_ring_next(m_screen->row_data)) {
		/* Get the data for the row we're clipping. */
                rowdata = _vte_ring_index_writable(m_screen->row_data, i);
                /* Clean up Tab/CJK fragments. */
                if ((glong) _vte_row_data_length(rowdata) > m_screen->cursor.col)
                        cleanup_fragments(m_screen->cursor.col, _vte_row_data_length(rowdata));
		/* Clear everything to the right of the cursor. */
		if (rowdata)
                        _vte_row_data_shrink(rowdata, m_screen->cursor.col);
	}
	/* Now for the rest of the lines. */
        for (i = m_screen->cursor.row + 1;
	     i < _vte_ring_next(m_screen->row_data);
	     i++) {
		/* Get the data for the row we're removing. */
		rowdata = _vte_ring_index_writable(m_screen->row_data, i);
		/* Remove it. */
		if (rowdata)
			_vte_row_data_shrink (rowdata, 0);
	}
	/* Now fill the cleared areas. */
        for (i = m_screen->cursor.row;
	     i < m_screen->insert_delta + m_row_count;
	     i++) {
		/* Retrieve the row's data, creating it if necessary. */
		if (_vte_ring_contains(m_screen->row_data, i)) {
			rowdata = _vte_ring_index_writable (m_screen->row_data, i);
			g_assert(rowdata != NULL);
		} else {
			rowdata = ring_append(false);
		}
		/* Pad out the row. */
                if (m_fill_defaults.attr.back != VTE_DEFAULT_BG) {
                        _vte_row_data_fill(rowdata, &m_fill_defaults, m_column_count);
		}
		rowdata->attr.soft_wrapped = 0;
		/* Repaint this row. */
		invalidate_cells(0, m_column_count,
                                 i, 1);
	}

	/* We've modified the display.  Make a note of it. */
	m_text_deleted_flag = TRUE;
}

/* Clear from the cursor position to the end of the line. */
void
VteTerminalPrivate::seq_ce()
{
	/* If we were to strictly emulate xterm, we'd ensure the cursor is onscreen.
	 * But due to https://bugzilla.gnome.org/show_bug.cgi?id=740789 we intentionally
	 * deviate and do instead what konsole does. This way emitting a \e[K doesn't
	 * influence the text flow, and serves as a perfect workaround against a new line
	 * getting painted with the active background color (except for a possible flicker).
	 */
	/* ensure_cursor_is_onscreen(); */

	/* Get the data for the row which the cursor points to. */
        auto rowdata = ensure_row();
	g_assert(rowdata != NULL);
        if ((glong) _vte_row_data_length(rowdata) > m_screen->cursor.col) {
                /* Clean up Tab/CJK fragments. */
                cleanup_fragments(m_screen->cursor.col, _vte_row_data_length(rowdata));
                /* Remove the data at the end of the array until the current column
                 * is the end of the array. */
                _vte_row_data_shrink(rowdata, m_screen->cursor.col);
		/* We've modified the display.  Make a note of it. */
		m_text_deleted_flag = TRUE;
	}
        if (m_fill_defaults.attr.back != VTE_DEFAULT_BG) {
		/* Add enough cells to fill out the row. */
                _vte_row_data_fill(rowdata, &m_fill_defaults, m_column_count);
	}
	rowdata->attr.soft_wrapped = 0;
	/* Repaint this row. */
	invalidate_cells(m_screen->cursor.col, m_column_count - m_screen->cursor.col,
                         m_screen->cursor.row, 1);
}

/* Move the cursor to the given column (horizontal position), 1-based. */
static void
vte_sequence_handler_cursor_character_absolute (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
	long val;

        val = 0;
	if ((params != NULL) && (params->n_values > 0)) {
		value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
                        val = g_value_get_long(value) - 1;
		}
	}

        that->set_cursor_column(val);
}

/*
 * VteTerminalPrivate::set_cursor_column:
 * @col: the column. 0-based from 0 to m_column_count - 1
 *
 * Sets the cursor column to @col, clamped to the range 0..m_column_count-1.
 */
void
VteTerminalPrivate::set_cursor_column(vte::grid::column_t col)
{
        m_screen->cursor.col = CLAMP(col, 0, m_column_count - 1);
}

/*
 * VteTerminalPrivate::set_cursor_row:
 * @row: the row. 0-based and relative to the scrolling region
 *
 * Sets the cursor row to @row. @row is relative to the scrolling region
 * (0 if restricted scrolling is off).
 */
void
VteTerminalPrivate::set_cursor_row(vte::grid::row_t row)
{
        vte::grid::row_t start_row, end_row;
        if (m_origin_mode &&
            m_scrolling_restricted) {
                start_row = m_scrolling_region.start;
                end_row = m_scrolling_region.end;
        } else {
                start_row = 0;
                end_row = m_row_count - 1;
        }
        row += start_row;
        row = CLAMP(row, start_row, end_row);

        m_screen->cursor.row = row + m_screen->insert_delta;
}

/*
 * VteTerminalPrivate::get_cursor_row:
 *
 * Returns: the relative cursor row, 0-based and relative to the scrolling region
 * if set (regardless of origin mode).
 */
vte::grid::row_t
VteTerminalPrivate::get_cursor_row() const
{
        auto row = m_screen->cursor.row - m_screen->insert_delta;
        /* Note that we do NOT check m_origin_mode here! */
        if (m_scrolling_restricted) {
                row -= m_scrolling_region.start;
        }
        return row;
}

vte::grid::column_t
VteTerminalPrivate::get_cursor_column() const
{
        return m_screen->cursor.col;
}

/*
 * VteTerminalPrivate::set_cursor_coords:
 * @row: the row. 0-based and relative to the scrolling region
 * @col: the column. 0-based from 0 to m_column_count - 1
 *
 * Sets the cursor row to @row. @row is relative to the scrolling region
 * (0 if restricted scrolling is off).
 *
 * Sets the cursor column to @col, clamped to the range 0..m_column_count-1.
 */
void
VteTerminalPrivate::set_cursor_coords(vte::grid::row_t row,
                                      vte::grid::column_t column)
{
        set_cursor_column(column);
        set_cursor_row(row);
}

/* Move the cursor to the given position, 1-based. */
static void
vte_sequence_handler_cursor_position (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *row, *col;

	/* We need at least two parameters. */
        vte::grid::row_t rowval = 0;
        vte::grid::column_t colval = 0;
	rowval = colval = 0;
	if (params != NULL && params->n_values >= 1) {
		/* The first is the row, the second is the column. */
		row = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(row)) {
                        rowval = g_value_get_long(row) - 1;
		}
		if (params->n_values >= 2) {
			col = g_value_array_get_nth(params, 1);
			if (G_VALUE_HOLDS_LONG(col)) {
                                colval = g_value_get_long(col) - 1;
			}
		}
	}

        that->set_cursor_coords(rowval, colval);
}

/* Carriage return. */
static void
vte_sequence_handler_carriage_return (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_cursor_column(0);
}

void
VteTerminalPrivate::reset_scrolling_region()
{
        m_scrolling_restricted = FALSE;
        seq_home_cursor();
}

/* Restrict scrolling and updates to a subset of the visible lines. */
static void
vte_sequence_handler_set_scrolling_region (VteTerminalPrivate *that, GValueArray *params)
{
	long start=-1, end=-1;
	GValue *value;

	/* We require two parameters.  Anything less is a reset. */
	if ((params == NULL) || (params->n_values < 2)) {
                that->reset_scrolling_region();
		return;
	}
	/* Extract the two values. */
	value = g_value_array_get_nth(params, 0);
	if (G_VALUE_HOLDS_LONG(value)) {
                start = g_value_get_long(value) - 1;
	}
	value = g_value_array_get_nth(params, 1);
	if (G_VALUE_HOLDS_LONG(value)) {
                end = g_value_get_long(value) - 1;
	}

        that->set_scrolling_region(start, end);
}

void
VteTerminalPrivate::set_scrolling_region(vte::grid::row_t start /* relative */,
                                         vte::grid::row_t end /* relative */)
{
        /* A (1-based) value of 0 means default. */
        if (start == -1) {
		start = 0;
	}
        if (end == -1) {
                end = m_row_count - 1;
        }
        /* Bail out on garbage, require at least 2 rows, as per xterm. */
        if (start < 0 || start >= m_row_count - 1 || end < start + 1) {
                return;
        }
        if (end >= m_row_count) {
                end = m_row_count - 1;
	}

	/* Set the right values. */
        m_scrolling_region.start = start;
        m_scrolling_region.end = end;
        m_scrolling_restricted = TRUE;
        if (m_scrolling_region.start == 0 &&
            m_scrolling_region.end == m_row_count - 1) {
		/* Special case -- run wild, run free. */
                m_scrolling_restricted = FALSE;
	} else {
		/* Maybe extend the ring -- bug 710483 */
                while (_vte_ring_next(m_screen->row_data) < m_screen->insert_delta + m_row_count)
                        _vte_ring_insert(m_screen->row_data, _vte_ring_next(m_screen->row_data));
	}

        seq_home_cursor();
}

/* Move the cursor to the beginning of the Nth next line, no scrolling. */
static void
vte_sequence_handler_cursor_next_line (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_cursor_column(0);
        vte_sequence_handler_cursor_down (that, params);
}

/* Move the cursor to the beginning of the Nth previous line, no scrolling. */
static void
vte_sequence_handler_cursor_preceding_line (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_cursor_column(0);
        vte_sequence_handler_cursor_up (that, params);
}

/* Move the cursor to the given row (vertical position), 1-based. */
static void
vte_sequence_handler_line_position_absolute (VteTerminalPrivate *that, GValueArray *params)
{
        long val = 0;
	if ((params != NULL) && (params->n_values > 0)) {
		GValue* value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
                        val = g_value_get_long(value) - 1;
		}
	}

        // FIXMEchpe shouldn't we ensure_cursor_is_onscreen AFTER setting the new cursor row?
        that->ensure_cursor_is_onscreen();
        that->set_cursor_row(val);
}

/* Delete a character at the current cursor position. */
static void
_vte_sequence_handler_dc (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_dc();
}

void
VteTerminalPrivate::seq_dc()
{
	VteRowData *rowdata;
	long col;

        ensure_cursor_is_onscreen();

        if (_vte_ring_next(m_screen->row_data) > m_screen->cursor.row) {
		long len;
		/* Get the data for the row which the cursor points to. */
                rowdata = _vte_ring_index_writable(m_screen->row_data, m_screen->cursor.row);
		g_assert(rowdata != NULL);
                col = m_screen->cursor.col;
		len = _vte_row_data_length (rowdata);
		/* Remove the column. */
		if (col < len) {
                        /* Clean up Tab/CJK fragments. */
                        cleanup_fragments(col, col + 1);
			_vte_row_data_remove (rowdata, col);
                        if (m_fill_defaults.attr.back != VTE_DEFAULT_BG) {
                                _vte_row_data_fill(rowdata, &m_fill_defaults, m_column_count);
                                len = m_column_count;
			}
                        rowdata->attr.soft_wrapped = 0;
			/* Repaint this row. */
                        invalidate_cells(col, len - col,
                                         m_screen->cursor.row, 1);
		}
	}

	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Delete N characters at the current cursor position. */
static void
vte_sequence_handler_delete_characters (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_multiple_r(that, params, _vte_sequence_handler_dc);
}

/* Cursor down N lines, no scrolling. */
static void
vte_sequence_handler_cursor_down (VteTerminalPrivate *that, GValueArray *params)
{
        long val = 1;
        if (params != NULL && params->n_values >= 1) {
                GValue* value = g_value_array_get_nth(params, 0);
                if (G_VALUE_HOLDS_LONG(value)) {
                        val = g_value_get_long(value);
                }
        }

        that->seq_cursor_down(val);
}

void
VteTerminalPrivate::seq_cursor_down(vte::grid::row_t rows)
{
        rows = CLAMP(rows, 1, m_row_count);

        // FIXMEchpe why not do this afterwards?
        ensure_cursor_is_onscreen();

        vte::grid::row_t end;
        // FIXMEchpe why not check m_origin_mode here?
        if (m_scrolling_restricted) {
                end = m_screen->insert_delta + m_scrolling_region.end;
	} else {
                end = m_screen->insert_delta + m_row_count - 1;
	}

        m_screen->cursor.row = MIN(m_screen->cursor.row + rows, end);
}

/* Erase characters starting at the cursor position (overwriting N with
 * spaces, but not moving the cursor). */
static void
vte_sequence_handler_erase_characters (VteTerminalPrivate *that, GValueArray *params)
{
	/* If we got a parameter, use it. */
	long count = 1;
	if ((params != NULL) && (params->n_values > 0)) {
                GValue* value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			count = g_value_get_long(value);
		}
	}

        that->seq_erase_characters(count);
}

void
VteTerminalPrivate::seq_erase_characters(long count)
{
        // FIXMEchpe clamp @count to 0..m_column_count? or at least something sane like MAXSHORT?

	VteCell *cell;
	long col, i;

        ensure_cursor_is_onscreen();

	/* Clear out the given number of characters. */
	auto rowdata = ensure_row();
        if (_vte_ring_next(m_screen->row_data) > m_screen->cursor.row) {
		g_assert(rowdata != NULL);
                /* Clean up Tab/CJK fragments. */
                cleanup_fragments(m_screen->cursor.col, m_screen->cursor.col + count);
		/* Write over the characters.  (If there aren't enough, we'll
		 * need to create them.) */
		for (i = 0; i < count; i++) {
                        col = m_screen->cursor.col + i;
			if (col >= 0) {
				if (col < (glong) _vte_row_data_length (rowdata)) {
					/* Replace this cell with the current
					 * defaults. */
					cell = _vte_row_data_get_writable (rowdata, col);
                                        *cell = m_color_defaults;
				} else {
					/* Add new cells until we have one here. */
                                        _vte_row_data_fill (rowdata, &m_color_defaults, col + 1);
				}
			}
		}
		/* Repaint this row. */
                invalidate_cells(m_screen->cursor.col, count,
                                 m_screen->cursor.row, 1);
	}

	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Form-feed / next-page. */
static void
vte_sequence_handler_form_feed (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_line_feed (that, params);
}

/* Insert a blank character. */
static void
_vte_sequence_handler_insert_character (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_insert_blank_character();
}

void
VteTerminalPrivate::seq_insert_blank_character()
{
        ensure_cursor_is_onscreen();

        auto save = m_screen->cursor;
        insert_char(' ', true, true);
        m_screen->cursor = save;
}

/* Insert N blank characters. */
/* TODOegmont: Insert them in a single run, so that we call cleanup_fragments only once. */
static void
vte_sequence_handler_insert_blank_characters (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_multiple_r(that, params, _vte_sequence_handler_insert_character);
}

/* Repeat the last graphic character once. */
static void
vte_sequence_handler_repeat_internal (VteTerminalPrivate *that, GValueArray *params)
{
        if (that->m_last_graphic_character != 0)
                that->insert_char (that->m_last_graphic_character, false, true);
}

/* REP: Repeat the last graphic character n times. */
static void
vte_sequence_handler_repeat (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_multiple_limited (that,
                                               params,
                                               vte_sequence_handler_repeat_internal,
                                               65535);
}

/* Cursor down 1 line, with scrolling. */
static void
vte_sequence_handler_index (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_line_feed (that, params);
}

/* Cursor left. */
static void
vte_sequence_handler_backspace (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_backspace();
}

void
VteTerminalPrivate::seq_backspace()
{
        ensure_cursor_is_onscreen();

        if (m_screen->cursor.col > 0) {
		/* There's room to move left, so do so. */
                m_screen->cursor.col--;
	}
}

/* Cursor left N columns. */
static void
vte_sequence_handler_cursor_backward (VteTerminalPrivate *that, GValueArray *params)
{
        GValue *value;
        long val;

        val = 1;
        if (params != NULL && params->n_values >= 1) {
                value = g_value_array_get_nth(params, 0);
                if (G_VALUE_HOLDS_LONG(value)) {
                        val = g_value_get_long(value);
                }
        }

        that->seq_cursor_backward(val);
}

void
VteTerminalPrivate::seq_cursor_backward(vte::grid::column_t columns)
{
        ensure_cursor_is_onscreen();

        auto col = get_cursor_column();
        columns = CLAMP(columns, 1, col);
        set_cursor_column(col - columns);
}

/* Cursor right N columns. */
static void
vte_sequence_handler_cursor_forward (VteTerminalPrivate *that, GValueArray *params)
{
        long val = 1;
        if (params != NULL && params->n_values >= 1) {
                GValue* value = g_value_array_get_nth(params, 0);
                if (G_VALUE_HOLDS_LONG(value)) {
                        val = g_value_get_long(value);
                }
        }

        that->seq_cursor_forward(val);
}

void
VteTerminalPrivate::seq_cursor_forward(vte::grid::column_t columns)
{
        columns = CLAMP(columns, 1, m_column_count);

        ensure_cursor_is_onscreen();

        /* The cursor can be further to the right, don't move in that case. */
        auto col = get_cursor_column();
        if (col < m_column_count) {
		/* There's room to move right. */
                set_cursor_column(col + columns);
	}
}

/* Move the cursor to the beginning of the next line, scrolling if necessary. */
static void
vte_sequence_handler_next_line (VteTerminalPrivate *that, GValueArray *params)
{
        that->set_cursor_column(0);
        that->cursor_down(true);
}

/* No-op. */
static void
vte_sequence_handler_linux_console_cursor_attributes (VteTerminalPrivate *that, GValueArray *params)
{
}

/* Scroll the text down N lines, but don't move the cursor. */
static void
vte_sequence_handler_scroll_down (VteTerminalPrivate *that, GValueArray *params)
{
	long val = 1;
	GValue *value;

        /* No ensure_cursor_is_onscreen() here as per xterm */

	if ((params != NULL) && (params->n_values > 0)) {
		value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			val = g_value_get_long(value);
			val = MAX(val, 1);
		}
	}

	that->seq_scroll_text(val);
}

/* Internal helper for changing color in the palette */
static void
vte_sequence_handler_change_color_internal (VteTerminalPrivate *that, GValueArray *params,
					    const char *terminator)
{
	if (params != NULL && params->n_values > 0) {
                GValue* value = g_value_array_get_nth (params, 0);

                char *str = NULL;
		if (G_VALUE_HOLDS_STRING (value))
			str = g_value_dup_string (value);
		else if (G_VALUE_HOLDS_POINTER (value))
			str = that->ucs4_to_utf8((const guchar *)g_value_get_pointer (value));

		if (! str)
			return;

                that->seq_change_color_internal(str, terminator);
                g_free(str);
        }
}

void
VteTerminalPrivate::seq_change_color_internal(char const* str,
                                              char const* terminator)
{
        {
                vte::color::rgb color;
                guint idx, i;

		char **pairs = g_strsplit (str, ";", 0);
		if (! pairs)
			return;

		for (i = 0; pairs[i] && pairs[i + 1]; i += 2) {
			idx = strtoul (pairs[i], (char **) NULL, 10);

			if (idx >= VTE_DEFAULT_FG)
				continue;

			if (color.parse(pairs[i + 1])) {
                                set_color(idx, VTE_COLOR_SOURCE_ESCAPE, color);
			} else if (strcmp (pairs[i + 1], "?") == 0) {
				gchar buf[128];
				auto c = get_color(idx);
				g_assert(c != NULL);
				g_snprintf (buf, sizeof (buf),
					    _VTE_CAP_OSC "4;%u;rgb:%04x/%04x/%04x%s",
					    idx, c->red, c->green, c->blue, terminator);
				feed_child(buf, -1);
			}
		}

		g_strfreev (pairs);

		/* emit the refresh as the palette has changed and previous
		 * renders need to be updated. */
		emit_refresh_window();
        }
}

/* Change color in the palette, BEL terminated */
static void
vte_sequence_handler_change_color_bel (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_color_internal (that, params, BEL);
}

/* Change color in the palette, ST terminated */
static void
vte_sequence_handler_change_color_st (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_color_internal (that, params, ST);
}

/* Reset color in the palette */
static void
vte_sequence_handler_reset_color (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
        guint i;
	long idx;

	if (params != NULL && params->n_values > 0) {
		for (i = 0; i < params->n_values; i++) {
			value = g_value_array_get_nth (params, i);

			if (!G_VALUE_HOLDS_LONG (value))
				continue;
			idx = g_value_get_long (value);
			if (idx < 0 || idx >= VTE_DEFAULT_FG)
				continue;

			that->reset_color(idx, VTE_COLOR_SOURCE_ESCAPE);
		}
	} else {
		for (idx = 0; idx < VTE_DEFAULT_FG; idx++) {
			that->reset_color(idx, VTE_COLOR_SOURCE_ESCAPE);
		}
	}
}

/* Scroll the text up N lines, but don't move the cursor. */
static void
vte_sequence_handler_scroll_up (VteTerminalPrivate *that, GValueArray *params)
{
	long val = 1;
	GValue *value;

        /* No ensure_cursor_is_onscreen() here as per xterm */

	if ((params != NULL) && (params->n_values > 0)) {
		value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			val = g_value_get_long(value);
			val = MAX(val, 1);
		}
	}

	that->seq_scroll_text(-val);
}

/* Cursor down 1 line, with scrolling. */
static void
vte_sequence_handler_line_feed (VteTerminalPrivate *that, GValueArray *params)
{
        that->ensure_cursor_is_onscreen();

        that->cursor_down(true);
}

/* Cursor up 1 line, with scrolling. */
static void
vte_sequence_handler_reverse_index (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_reverse_index();
}

void
VteTerminalPrivate::seq_reverse_index()
{
        ensure_cursor_is_onscreen();

        vte::grid::row_t start, end;
        if (m_scrolling_restricted) {
                start = m_scrolling_region.start + m_screen->insert_delta;
                end = m_scrolling_region.end + m_screen->insert_delta;
	} else {
                start = m_screen->insert_delta;
                end = start + m_row_count - 1;
	}

        if (m_screen->cursor.row == start) {
		/* If we're at the top of the scrolling region, add a
		 * line at the top to scroll the bottom off. */
		ring_remove(end);
		ring_insert(start, true);
		/* Update the display. */
		scroll_region(start, end - start + 1, 1);
                invalidate_cells(0, m_column_count,
                                 start, 2);
	} else {
		/* Otherwise, just move the cursor up. */
                m_screen->cursor.row--;
	}
	/* Adjust the scrollbars if necessary. */
        adjust_adjustments();
	/* We modified the display, so make a note of it. */
        m_text_modified_flag = TRUE;
}

/* Set tab stop in the current column. */
static void
vte_sequence_handler_tab_set (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_tab_set();
}

void
VteTerminalPrivate::seq_tab_set()
{
	if (m_tabstops == NULL) {
		m_tabstops = g_hash_table_new(NULL, NULL);
	}
	set_tabstop(m_screen->cursor.col);
}

/* Tab. */
static void
vte_sequence_handler_tab (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_tab();
}

void
VteTerminalPrivate::seq_tab()
{
	long old_len;
        vte::grid::column_t newcol, col;

	/* Calculate which column is the next tab stop. */
        newcol = col = m_screen->cursor.col;

	g_assert (col >= 0);

	if (m_tabstops != NULL) {
		/* Find the next tabstop. */
		for (newcol++; newcol < VTE_TAB_MAX; newcol++) {
			if (get_tabstop(newcol)) {
				break;
			}
		}
	}

	/* If we have no tab stops or went past the end of the line, stop
	 * at the right-most column. */
	if (newcol >= m_column_count) {
		newcol = m_column_count - 1;
	}

	/* but make sure we don't move cursor back (bug #340631) */
	if (col < newcol) {
		VteRowData *rowdata = ensure_row();

		/* Smart tab handling: bug 353610
		 *
		 * If we currently don't have any cells in the space this
		 * tab creates, we try to make the tab character copyable,
		 * by appending a single tab char with lots of fragment
		 * cells following it.
		 *
		 * Otherwise, just append empty cells that will show up
		 * as a space each.
		 */

		old_len = _vte_row_data_length (rowdata);
                _vte_row_data_fill (rowdata, &basic_cell, newcol);

		/* Insert smart tab if there's nothing in the line after
		 * us, not even empty cells (with non-default background
		 * color for example).
		 *
		 * Notable bugs here: 545924, 597242, 764330 */
		if (col >= old_len && newcol - col <= VTE_TAB_WIDTH_MAX) {
			glong i;
			VteCell *cell = _vte_row_data_get_writable (rowdata, col);
			VteCell tab = *cell;
			tab.attr.columns = newcol - col;
			tab.c = '\t';
			/* Save tab char */
			*cell = tab;
			/* And adjust the fragments */
			for (i = col + 1; i < newcol; i++) {
				cell = _vte_row_data_get_writable (rowdata, i);
				cell->c = '\t';
				cell->attr.columns = 1;
				cell->attr.fragment = 1;
			}
		}

		invalidate_cells(m_screen->cursor.col, newcol - m_screen->cursor.col,
                                 m_screen->cursor.row, 1);
                m_screen->cursor.col = newcol;
	}
}

static void
vte_sequence_handler_cursor_forward_tabulation (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_multiple_r(that, params, vte_sequence_handler_tab);
}

/* Clear tabs selectively. */
static void
vte_sequence_handler_tab_clear (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
	long param = 0;

	if ((params != NULL) && (params->n_values > 0)) {
		value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			param = g_value_get_long(value);
		}
	}

        that->seq_tab_clear(param);
}

void
VteTerminalPrivate::seq_tab_clear(long param)
{
	if (param == 0) {
		clear_tabstop(m_screen->cursor.col);
	} else if (param == 3) {
		if (m_tabstops != nullptr) {
			g_hash_table_destroy(m_tabstops);
			m_tabstops = nullptr;
		}
	}
}

/* Cursor up N lines, no scrolling. */
static void
vte_sequence_handler_cursor_up (VteTerminalPrivate *that, GValueArray *params)
{
        long val = 1;
        if (params != NULL && params->n_values >= 1) {
                GValue* value = g_value_array_get_nth(params, 0);
                if (G_VALUE_HOLDS_LONG(value)) {
                        val = g_value_get_long(value);
                }
        }

        that->seq_cursor_up(val);
}

void
VteTerminalPrivate::seq_cursor_up(vte::grid::row_t rows)
{
        rows = CLAMP(rows, 1, m_row_count);

        //FIXMEchpe why not do this afterward?
        ensure_cursor_is_onscreen();

        vte::grid::row_t start;
        //FIXMEchpe why not check m_origin_mode here?
        if (m_scrolling_restricted) {
                start = m_screen->insert_delta + m_scrolling_region.start;
	} else {
		start = m_screen->insert_delta;
	}

        m_screen->cursor.row = MAX(m_screen->cursor.row - rows, start);
}

/* Vertical tab. */
static void
vte_sequence_handler_vertical_tab (VteTerminalPrivate *that, GValueArray *params)
{
        vte_sequence_handler_line_feed (that, params);
}

/* Parse parameters of SGR 38 or 48, starting at @index within @params.
 * Returns the color index, or -1 on error.
 * Increments @index to point to the last consumed parameter (not beyond). */
static gint32
vte_sequence_parse_sgr_38_48_parameters (GValueArray *params, unsigned int *index)
{
	if (*index < params->n_values) {
		GValue *value0, *value1, *value2, *value3;
		long param0, param1, param2, param3;
		value0 = g_value_array_get_nth(params, *index);
		if (G_UNLIKELY (!G_VALUE_HOLDS_LONG(value0)))
			return -1;
		param0 = g_value_get_long(value0);
		switch (param0) {
		case 2:
			if (G_UNLIKELY (*index + 3 >= params->n_values))
				return -1;
			value1 = g_value_array_get_nth(params, *index + 1);
			value2 = g_value_array_get_nth(params, *index + 2);
			value3 = g_value_array_get_nth(params, *index + 3);
			if (G_UNLIKELY (!(G_VALUE_HOLDS_LONG(value1) && G_VALUE_HOLDS_LONG(value2) && G_VALUE_HOLDS_LONG(value3))))
				return -1;
			param1 = g_value_get_long(value1);
			param2 = g_value_get_long(value2);
			param3 = g_value_get_long(value3);
			if (G_UNLIKELY (param1 < 0 || param1 >= 256 || param2 < 0 || param2 >= 256 || param3 < 0 || param3 >= 256))
				return -1;
			*index += 3;
			return VTE_RGB_COLOR | (param1 << 16) | (param2 << 8) | param3;
		case 5:
			if (G_UNLIKELY (*index + 1 >= params->n_values))
				return -1;
			value1 = g_value_array_get_nth(params, *index + 1);
			if (G_UNLIKELY (!G_VALUE_HOLDS_LONG(value1)))
				return -1;
			param1 = g_value_get_long(value1);
			if (G_UNLIKELY (param1 < 0 || param1 >= 256))
				return -1;
			*index += 1;
			return param1;
		}
	}
	return -1;
}

/* Handle ANSI color setting and related stuffs (SGR).
 * @params contains the values split at semicolons, with sub arrays splitting at colons
 * wherever colons were encountered. */
static void
vte_sequence_handler_character_attributes (VteTerminalPrivate *that, GValueArray *params)
{
	unsigned int i;
	GValue *value;
	long param;
	/* The default parameter is zero. */
	param = 0;
	/* Step through each numeric parameter. */
	for (i = 0; (params != NULL) && (i < params->n_values); i++) {
		value = g_value_array_get_nth(params, i);
		/* If this parameter is a GValueArray, it can be a fully colon separated 38 or 48
		 * (see below for details). */
		if (G_UNLIKELY (G_VALUE_HOLDS_BOXED(value))) {
			GValueArray *subvalues = (GValueArray *)g_value_get_boxed(value);
			GValue *value0;
			long param0;
			gint32 color;
			unsigned int index = 1;

			value0 = g_value_array_get_nth(subvalues, 0);
			if (G_UNLIKELY (!G_VALUE_HOLDS_LONG(value0)))
				continue;
			param0 = g_value_get_long(value0);
			if (G_UNLIKELY (param0 != 38 && param0 != 48))
				continue;
			color = vte_sequence_parse_sgr_38_48_parameters(subvalues, &index);
			/* Bail out on additional colon-separated values. */
			if (G_UNLIKELY (index != subvalues->n_values - 1))
				continue;
			if (G_LIKELY (color != -1)) {
				if (param0 == 38) {
                                        that->m_defaults.attr.fore = color;
				} else {
                                        that->m_defaults.attr.back = color;
				}
			}
			continue;
		}
		/* If this parameter is not a GValueArray and not a number either, skip it. */
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		param = g_value_get_long(value);
		switch (param) {
		case 0:
                        that->reset_default_attributes(false);
			break;
		case 1:
                        that->m_defaults.attr.bold = 1;
			break;
		case 2:
                        that->m_defaults.attr.dim = 1;
			break;
		case 3:
                        that->m_defaults.attr.italic = 1;
			break;
		case 4:
                        that->m_defaults.attr.underline = 1;
			break;
		case 5:
                        that->m_defaults.attr.blink = 1;
			break;
		case 7:
                        that->m_defaults.attr.reverse = 1;
			break;
		case 8:
                        that->m_defaults.attr.invisible = 1;
			break;
		case 9:
                        that->m_defaults.attr.strikethrough = 1;
			break;
		case 21: /* Error in old versions of linux console. */
		case 22: /* ECMA 48. */
                        that->m_defaults.attr.bold = 0;
                        that->m_defaults.attr.dim = 0;
			break;
		case 23:
                        that->m_defaults.attr.italic = 0;
			break;
		case 24:
                        that->m_defaults.attr.underline = 0;
			break;
		case 25:
                        that->m_defaults.attr.blink = 0;
			break;
		case 27:
                        that->m_defaults.attr.reverse = 0;
			break;
		case 28:
                        that->m_defaults.attr.invisible = 0;
			break;
		case 29:
                        that->m_defaults.attr.strikethrough = 0;
			break;
		case 30:
		case 31:
		case 32:
		case 33:
		case 34:
		case 35:
		case 36:
		case 37:
                        that->m_defaults.attr.fore = VTE_LEGACY_COLORS_OFFSET + param - 30;
			break;
		case 38:
		case 48:
		{
			/* The format looks like:
			 * - 256 color indexed palette:
			 *   - ^[[38;5;INDEXm
			 *   - ^[[38;5:INDEXm
			 *   - ^[[38:5:INDEXm
			 * - true colors:
			 *   - ^[[38;2;RED;GREEN;BLUEm
			 *   - ^[[38;2:RED:GREEN:BLUEm
			 *   - ^[[38:2:RED:GREEN:BLUEm
			 * See bug 685759 for details.
			 * The fully colon versions were handled above separately. The code is reached
			 * if the first separator is a semicolon. */
			if ((i + 1) < params->n_values) {
				gint32 color;
				GValue *value1 = g_value_array_get_nth(params, ++i);
				if (G_VALUE_HOLDS_LONG(value1)) {
					/* Only semicolons as separators. */
					color = vte_sequence_parse_sgr_38_48_parameters(params, &i);
				} else if (G_VALUE_HOLDS_BOXED(value1)) {
					/* The first separator was a semicolon, the rest are colons. */
					GValueArray *subvalues = (GValueArray *)g_value_get_boxed(value1);
					unsigned int index = 0;
					color = vte_sequence_parse_sgr_38_48_parameters(subvalues, &index);
					/* Bail out on additional colon-separated values. */
					if (G_UNLIKELY (index != subvalues->n_values - 1))
						break;
				} else {
					break;
				}
				if (G_LIKELY (color != -1)) {
					if (param == 38) {
                                                that->m_defaults.attr.fore = color;
					} else {
                                                that->m_defaults.attr.back = color;
					}
				}
			}
			break;
		}
		case 39:
			/* default foreground */
                        that->m_defaults.attr.fore = VTE_DEFAULT_FG;
			break;
		case 40:
		case 41:
		case 42:
		case 43:
		case 44:
		case 45:
		case 46:
		case 47:
                        that->m_defaults.attr.back = VTE_LEGACY_COLORS_OFFSET + param - 40;
			break;
	     /* case 48: was handled above at 38 to avoid code duplication */
		case 49:
			/* default background */
                        that->m_defaults.attr.back = VTE_DEFAULT_BG;
			break;
		case 90:
		case 91:
		case 92:
		case 93:
		case 94:
		case 95:
		case 96:
		case 97:
                        that->m_defaults.attr.fore = VTE_LEGACY_COLORS_OFFSET + param - 90 + VTE_COLOR_BRIGHT_OFFSET;
			break;
		case 100:
		case 101:
		case 102:
		case 103:
		case 104:
		case 105:
		case 106:
		case 107:
                        that->m_defaults.attr.back = VTE_LEGACY_COLORS_OFFSET + param - 100 + VTE_COLOR_BRIGHT_OFFSET;
			break;
		}
	}
	/* If we had no parameters, default to the defaults. */
	if (i == 0) {
                that->reset_default_attributes(false);
	}
	/* Save the new colors. */
        that->m_color_defaults.attr.fore = that->m_defaults.attr.fore;
        that->m_color_defaults.attr.back = that->m_defaults.attr.back;
        that->m_fill_defaults.attr.fore = that->m_defaults.attr.fore;
        that->m_fill_defaults.attr.back = that->m_defaults.attr.back;
}

/* Move the cursor to the given column in the top row, 1-based. */
static void
vte_sequence_handler_cursor_position_top_row (VteTerminalPrivate *that, GValueArray *params)
{
        GValue value = {0};

        g_value_init (&value, G_TYPE_LONG);
        g_value_set_long (&value, 1);

        g_value_array_insert (params, 0, &value);

        vte_sequence_handler_cursor_position(that, params);
}

/* Request terminal attributes. */
static void
vte_sequence_handler_request_terminal_parameters (VteTerminalPrivate *that, GValueArray *params)
{
	that->feed_child("\e[?x", -1);
}

/* Request terminal attributes. */
static void
vte_sequence_handler_return_terminal_status (VteTerminalPrivate *that, GValueArray *params)
{
	that->feed_child("", 0);
}

/* Send primary device attributes. */
static void
vte_sequence_handler_send_primary_device_attributes (VteTerminalPrivate *that, GValueArray *params)
{
	/* Claim to be a VT220 with only national character set support. */
        that->feed_child("\e[?62;c", -1);
}

/* Send terminal ID. */
static void
vte_sequence_handler_return_terminal_id (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_send_primary_device_attributes (that, params);
}

/* Send secondary device attributes. */
static void
vte_sequence_handler_send_secondary_device_attributes (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_send_secondary_device_attributes();
}

void
VteTerminalPrivate::seq_send_secondary_device_attributes()
{
	char **version;
	char buf[128];
	long ver = 0, i;
	/* Claim to be a VT220, more or less.  The '>' in the response appears
	 * to be undocumented. */
	version = g_strsplit(VERSION, ".", 0);
	if (version != NULL) {
		for (i = 0; version[i] != NULL; i++) {
			ver = ver * 100;
			ver += atol(version[i]);
		}
		g_strfreev(version);
	}
	g_snprintf(buf, sizeof (buf), _VTE_CAP_ESC "[>1;%ld;0c", ver);
	feed_child(buf, -1);
}

/* Set one or the other. */
static void
vte_sequence_handler_set_icon_title (VteTerminalPrivate *that, GValueArray *params)
{
	that->seq_set_title_internal(params, true, false);
}

static void
vte_sequence_handler_set_window_title (VteTerminalPrivate *that, GValueArray *params)
{
	that->seq_set_title_internal(params, false, true);
}

/* Set both the window and icon titles to the same string. */
static void
vte_sequence_handler_set_icon_and_window_title (VteTerminalPrivate *that, GValueArray *params)
{
	that->seq_set_title_internal(params, true, true);
}

static void
vte_sequence_handler_set_current_directory_uri (VteTerminalPrivate *that, GValueArray *params)
{
        GValue *value;
        char *uri, *filename;

        uri = NULL;
        if (params != NULL && params->n_values > 0) {
                value = g_value_array_get_nth(params, 0);

                if (G_VALUE_HOLDS_POINTER(value)) {
                        uri = that->ucs4_to_utf8((const guchar *)g_value_get_pointer (value));
                } else if (G_VALUE_HOLDS_STRING(value)) {
                        /* Copy the string into the buffer. */
                        uri = g_value_dup_string(value);
                }
        }

        /* Validate URI */
        if (uri && uri[0]) {
                filename = g_filename_from_uri (uri, NULL, NULL);
                if (filename == NULL) {
                        /* invalid URI */
                        g_free (uri);
                        uri = NULL;
                } else {
                        g_free (filename);
                }
        }

        that->set_current_directory_uri_changed(uri);
}

void
VteTerminalPrivate::set_current_directory_uri_changed(char* uri /* adopted */)
{
        g_free(m_current_directory_uri_changed);
        m_current_directory_uri_changed = uri;
}

static void
vte_sequence_handler_set_current_file_uri (VteTerminalPrivate *that, GValueArray *params)
{
        GValue *value;
        char *uri, *filename;

        uri = NULL;
        if (params != NULL && params->n_values > 0) {
                value = g_value_array_get_nth(params, 0);

                if (G_VALUE_HOLDS_POINTER(value)) {
                        uri = that->ucs4_to_utf8((const guchar *)g_value_get_pointer (value));
                } else if (G_VALUE_HOLDS_STRING(value)) {
                        /* Copy the string into the buffer. */
                        uri = g_value_dup_string(value);
                }
        }

        /* Validate URI */
        if (uri && uri[0]) {
                filename = g_filename_from_uri (uri, NULL, NULL);
                if (filename == NULL) {
                        /* invalid URI */
                        g_free (uri);
                        uri = NULL;
                } else {
                        g_free (filename);
                }
        }

        that->set_current_file_uri_changed(uri);
}

void
VteTerminalPrivate::set_current_file_uri_changed(char* uri /* adopted */)
{
        g_free(m_current_file_uri_changed);
        m_current_file_uri_changed = uri;
}

/* Handle OSC 8 hyperlinks.
 * See bug 779734 and https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda. */
static void
vte_sequence_handler_set_current_hyperlink (VteTerminalPrivate *that, GValueArray *params)
{
        GValue *value;
        char *hyperlink_params;
        char *uri;

        hyperlink_params = NULL;
        uri = NULL;
        if (params != NULL && params->n_values > 1) {
                value = g_value_array_get_nth(params, 0);

                if (G_VALUE_HOLDS_POINTER(value)) {
                        hyperlink_params = that->ucs4_to_utf8((const guchar *)g_value_get_pointer (value));
                } else if (G_VALUE_HOLDS_STRING(value)) {
                        /* Copy the string into the buffer. */
                        hyperlink_params = g_value_dup_string(value);
                }

                value = g_value_array_get_nth(params, 1);

                if (G_VALUE_HOLDS_POINTER(value)) {
                        uri = that->ucs4_to_utf8((const guchar *)g_value_get_pointer (value));
                } else if (G_VALUE_HOLDS_STRING(value)) {
                        /* Copy the string into the buffer. */
                        uri = g_value_dup_string(value);
                }
        }

        that->set_current_hyperlink(hyperlink_params, uri);
}

void
VteTerminalPrivate::set_current_hyperlink(char *hyperlink_params /* adopted */, char* uri /* adopted */)
{
        guint idx;
        char *id = NULL;
        char idbuf[24];

        if (!m_allow_hyperlink)
                return;

        /* Get the "id" parameter */
        if (hyperlink_params) {
                if (strncmp(hyperlink_params, "id=", 3) == 0) {
                        id = hyperlink_params + 3;
                } else {
                        id = strstr(hyperlink_params, ":id=");
                        if (id)
                                id += 4;
                }
        }
        if (id) {
                *strchrnul(id, ':') = '\0';
        }
        _vte_debug_print (VTE_DEBUG_HYPERLINK,
                          "OSC 8: id=\"%s\" uri=\"%s\"\n",
                          id, uri);

        if (uri && strlen(uri) > VTE_HYPERLINK_URI_LENGTH_MAX) {
                _vte_debug_print (VTE_DEBUG_HYPERLINK,
                                  "Overlong URI ignored: \"%s\"\n",
                                  uri);
                uri[0] = '\0';
        }

        if (id && strlen(id) > VTE_HYPERLINK_ID_LENGTH_MAX) {
                _vte_debug_print (VTE_DEBUG_HYPERLINK,
                                  "Overlong \"id\" ignored: \"%s\"\n",
                                  id);
                id[0] = '\0';
        }

        if (uri && uri[0]) {
                /* The hyperlink, as we carry around and store in the streams, is "id;uri" */
                char *hyperlink;

                if (!id || !id[0]) {
                        /* Automatically generate a unique ID string. The colon makes sure
                         * it cannot conflict with an explicitly specified one. */
                        sprintf(idbuf, ":%ld", m_hyperlink_auto_id++);
                        id = idbuf;
                        _vte_debug_print (VTE_DEBUG_HYPERLINK,
                                          "Autogenerated id=\"%s\"\n",
                                          id);
                }
                hyperlink = g_strdup_printf("%s;%s", id, uri);
                idx = _vte_ring_get_hyperlink_idx(m_screen->row_data, hyperlink);
                g_free (hyperlink);
        } else {
                /* idx = 0; also remove the previous current_idx so that it can be GC'd now. */
                idx = _vte_ring_get_hyperlink_idx(m_screen->row_data, NULL);
        }

        m_defaults.attr.hyperlink_idx = idx;

        g_free(hyperlink_params);
        g_free(uri);
}

/* Restrict the scrolling region. */
static void
vte_sequence_handler_set_scrolling_region_from_start (VteTerminalPrivate *that, GValueArray *params)
{
	GValue value = {0};

	g_value_init (&value, G_TYPE_LONG);
        g_value_set_long (&value, 0);  /* A missing value is treated as 0 */

	g_value_array_insert (params, 0, &value);

        vte_sequence_handler_set_scrolling_region (that, params);
}

static void
vte_sequence_handler_set_scrolling_region_to_end (VteTerminalPrivate *that, GValueArray *params)
{
	GValue value = {0};

	g_value_init (&value, G_TYPE_LONG);
        g_value_set_long (&value, 0);  /* A missing value is treated as 0 */

	g_value_array_insert (params, 1, &value);

        vte_sequence_handler_set_scrolling_region (that, params);
}

void
VteTerminalPrivate::set_keypad_mode(VteKeymode mode)
{
        m_keypad_mode = mode;
}

/* Set the application or normal keypad. */
static void
vte_sequence_handler_application_keypad (VteTerminalPrivate *that, GValueArray *params)
{
	_vte_debug_print(VTE_DEBUG_KEYBOARD,
			"Entering application keypad mode.\n");
	that->set_keypad_mode(VTE_KEYMODE_APPLICATION);
}

static void
vte_sequence_handler_normal_keypad (VteTerminalPrivate *that, GValueArray *params)
{
	_vte_debug_print(VTE_DEBUG_KEYBOARD,
			"Leaving application keypad mode.\n");
	that->set_keypad_mode(VTE_KEYMODE_NORMAL);
}

/* Same as cursor_character_absolute, not widely supported. */
static void
vte_sequence_handler_character_position_absolute (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_cursor_character_absolute (that, params);
}

/* Set certain terminal attributes. */
static void
vte_sequence_handler_set_mode (VteTerminalPrivate *that, GValueArray *params)
{
	guint i;
	long setting;
	GValue *value;
	if ((params == NULL) || (params->n_values == 0)) {
		return;
	}
	for (i = 0; i < params->n_values; i++) {
		value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		setting = g_value_get_long(value);
		that->seq_set_mode_internal(setting, true);
	}
}

/* Unset certain terminal attributes. */
static void
vte_sequence_handler_reset_mode (VteTerminalPrivate *that, GValueArray *params)
{
	guint i;
	long setting;
	GValue *value;
	if ((params == NULL) || (params->n_values == 0)) {
		return;
	}
	for (i = 0; i < params->n_values; i++) {
		value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		setting = g_value_get_long(value);
		that->seq_set_mode_internal(setting, false);
	}
}

/* Set certain terminal attributes. */
static void
vte_sequence_handler_decset (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
	long setting;
	guint i;
	if ((params == NULL) || (params->n_values == 0)) {
		return;
	}
	for (i = 0; i < params->n_values; i++) {
		value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		setting = g_value_get_long(value);
		vte_sequence_handler_decset_internal(that, setting, FALSE, FALSE, TRUE);
	}
}

/* Unset certain terminal attributes. */
static void
vte_sequence_handler_decreset (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
	long setting;
	guint i;
	if ((params == NULL) || (params->n_values == 0)) {
		return;
	}
	for (i = 0; i < params->n_values; i++) {
		value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		setting = g_value_get_long(value);
		vte_sequence_handler_decset_internal(that, setting, FALSE, FALSE, FALSE);
	}
}

/* Erase certain lines in the display. */
static void
vte_sequence_handler_erase_in_display (VteTerminalPrivate *that, GValueArray *params)
{
	/* The default parameter is 0. */
	long param = 0;
        /* Pull out the first parameter. */
	for (guint i = 0; (params != NULL) && (i < params->n_values); i++) {
                GValue* value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		param = g_value_get_long(value);
                break;
	}

        that->seq_erase_in_display(param);
}

void
VteTerminalPrivate::seq_erase_in_display(long param)
{
	/* Clear the right area. */
	switch (param) {
	case 0:
		/* Clear below the current line. */
                seq_cd();
		break;
	case 1:
		/* Clear above the current line. */
                seq_clear_above_current();
		/* Clear everything to the left of the cursor, too. */
		/* FIXME: vttest. */
                seq_cb();
		break;
	case 2:
		/* Clear the entire screen. */
                seq_clear_screen();
		break;
        case 3:
                /* Drop the scrollback. */
                drop_scrollback();
                break;
	default:
		break;
	}
	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Erase certain parts of the current line in the display. */
static void
vte_sequence_handler_erase_in_line (VteTerminalPrivate *that, GValueArray *params)
{
	/* The default parameter is 0. */
	long param = 0;
        /* Pull out the first parameter. */
	for (guint i = 0; (params != NULL) && (i < params->n_values); i++) {
                GValue* value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		param = g_value_get_long(value);
                break;
	}

        that->seq_erase_in_line(param);
}

void
VteTerminalPrivate::seq_erase_in_line(long param)
{
	/* Clear the right area. */
	switch (param) {
	case 0:
		/* Clear to end of the line. */
                seq_ce();
		break;
	case 1:
		/* Clear to start of the line. */
                seq_cb();
		break;
	case 2:
		/* Clear the entire line. */
                seq_clear_current_line();
		break;
	default:
		break;
	}
	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Perform a full-bore reset. */
static void
vte_sequence_handler_full_reset (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset(true, true);
}

/* Insert a certain number of lines below the current cursor. */
static void
vte_sequence_handler_insert_lines (VteTerminalPrivate *that, GValueArray *params)
{
	/* The default is one. */
	long param = 1;
	/* Extract any parameters. */
	if ((params != NULL) && (params->n_values > 0)) {
		GValue* value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			param = g_value_get_long(value);
		}
	}

        that->seq_insert_lines(param);
}

void
VteTerminalPrivate::seq_insert_lines(vte::grid::row_t param)
{
        vte::grid::row_t end, i;

	/* Find the region we're messing with. */
        auto row = m_screen->cursor.row;
        if (m_scrolling_restricted) {
                end = m_screen->insert_delta + m_scrolling_region.end;
	} else {
                end = m_screen->insert_delta + m_row_count - 1;
	}

	/* Only allow to insert as many lines as there are between this row
         * and the end of the scrolling region. See bug #676090.
         */
        auto limit = end - row + 1;
        param = MIN (param, limit);

	for (i = 0; i < param; i++) {
		/* Clear a line off the end of the region and add one to the
		 * top of the region. */
                ring_remove(end);
                ring_insert(row, true);
	}
        m_screen->cursor.col = 0;
	/* Update the display. */
        scroll_region(row, end - row + 1, param);
	/* Adjust the scrollbars if necessary. */
        adjust_adjustments();
	/* We've modified the display.  Make a note of it. */
        m_text_inserted_flag = TRUE;
}

/* Delete certain lines from the scrolling region. */
static void
vte_sequence_handler_delete_lines (VteTerminalPrivate *that, GValueArray *params)
{
	/* The default is one. */
	long param = 1;
	/* Extract any parameters. */
	if ((params != NULL) && (params->n_values > 0)) {
		GValue* value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			param = g_value_get_long(value);
		}
	}

        that->seq_delete_lines(param);
}

void
VteTerminalPrivate::seq_delete_lines(vte::grid::row_t param)
{
        vte::grid::row_t end, i;

	/* Find the region we're messing with. */
        auto row = m_screen->cursor.row;
        if (m_scrolling_restricted) {
                end = m_screen->insert_delta + m_scrolling_region.end;
	} else {
                end = m_screen->insert_delta + m_row_count - 1;
	}

        /* Only allow to delete as many lines as there are between this row
         * and the end of the scrolling region. See bug #676090.
         */
        auto limit = end - row + 1;
        param = MIN (param, limit);

	/* Clear them from below the current cursor. */
	for (i = 0; i < param; i++) {
		/* Insert a line at the end of the region and remove one from
		 * the top of the region. */
                ring_remove(row);
                ring_insert(end, true);
	}
        m_screen->cursor.col = 0;
	/* Update the display. */
        scroll_region(row, end - row + 1, -param);
	/* Adjust the scrollbars if necessary. */
        adjust_adjustments();
	/* We've modified the display.  Make a note of it. */
        m_text_deleted_flag = TRUE;
}

/* Device status reports. The possible reports are the cursor position and
 * whether or not we're okay. */
static void
vte_sequence_handler_device_status_report (VteTerminalPrivate *that, GValueArray *params)
{
	if ((params != NULL) && (params->n_values > 0)) {
		GValue* value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			auto param = g_value_get_long(value);
                        that->seq_device_status_report(param);
                }
        }
}

void
VteTerminalPrivate::seq_device_status_report(long param)
{
        switch (param) {
			case 5:
				/* Send a thumbs-up sequence. */
				feed_child(_VTE_CAP_CSI "0n", -1);
				break;
			case 6:
				/* Send the cursor position. */
                                vte::grid::row_t rowval, origin, rowmax;
                                if (m_origin_mode &&
                                    m_scrolling_restricted) {
                                        origin = m_scrolling_region.start;
                                        rowmax = m_scrolling_region.end;
                                } else {
                                        origin = 0;
                                        rowmax = m_row_count - 1;
                                }
                                // FIXMEchpe this looks wrong. shouldn't this first clamp to origin,rowmax and *then* subtract origin?
                                rowval = m_screen->cursor.row - m_screen->insert_delta - origin;
                                rowval = CLAMP(rowval, 0, rowmax);
                                char buf[128];
                                g_snprintf(buf, sizeof(buf),
					   _VTE_CAP_CSI "%ld;%ldR",
                                           rowval + 1,
                                           CLAMP(m_screen->cursor.col + 1, 1, m_column_count));
				feed_child(buf, -1);
				break;
			default:
				break;
        }
}

/* DEC-style device status reports. */
static void
vte_sequence_handler_dec_device_status_report (VteTerminalPrivate *that, GValueArray *params)
{
	if ((params != NULL) && (params->n_values > 0)) {
		GValue* value = g_value_array_get_nth(params, 0);
		if (G_VALUE_HOLDS_LONG(value)) {
			auto param = g_value_get_long(value);
                        that->seq_dec_device_status_report(param);
                }
        }
}

void
VteTerminalPrivate::seq_dec_device_status_report(long param)
{
			switch (param) {
			case 6:
				/* Send the cursor position. */
                                vte::grid::row_t rowval, origin, rowmax;
                                if (m_origin_mode &&
                                    m_scrolling_restricted) {
                                        origin = m_scrolling_region.start;
                                        rowmax = m_scrolling_region.end;
                                } else {
                                        origin = 0;
                                        rowmax = m_row_count - 1;
                                }
                                // FIXMEchpe this looks wrong. shouldn't this first clamp to origin,rowmax and *then* subtract origin?
                                rowval = m_screen->cursor.row - m_screen->insert_delta - origin;
                                rowval = CLAMP(rowval, 0, rowmax);
                                char buf[128];
				g_snprintf(buf, sizeof(buf),
					   _VTE_CAP_CSI "?%ld;%ldR",
                                           rowval + 1,
                                           CLAMP(m_screen->cursor.col + 1, 1, m_column_count));
				feed_child(buf, -1);
				break;
			case 15:
				/* Send printer status -- 10 = ready,
				 * 11 = not ready.  We don't print. */
				feed_child(_VTE_CAP_CSI "?11n", -1);
				break;
			case 25:
				/* Send UDK status -- 20 = locked,
				 * 21 = not locked.  I don't even know what
				 * that means, but punt anyway. */
				feed_child(_VTE_CAP_CSI "?20n", -1);
				break;
			case 26:
				/* Send keyboard status.  50 = no locator. */
				feed_child(_VTE_CAP_CSI "?50n", -1);
				break;
			default:
				break;
			}
}

/* Restore a certain terminal attribute. */
static void
vte_sequence_handler_restore_mode (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
	long setting;
	guint i;
	if ((params == NULL) || (params->n_values == 0)) {
		return;
	}
	for (i = 0; i < params->n_values; i++) {
		value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		setting = g_value_get_long(value);
		vte_sequence_handler_decset_internal(that, setting, TRUE, FALSE, FALSE);
	}
}

/* Save a certain terminal attribute. */
static void
vte_sequence_handler_save_mode (VteTerminalPrivate *that, GValueArray *params)
{
	GValue *value;
	long setting;
	guint i;
	if ((params == NULL) || (params->n_values == 0)) {
		return;
	}
	for (i = 0; i < params->n_values; i++) {
		value = g_value_array_get_nth(params, i);
		if (!G_VALUE_HOLDS_LONG(value)) {
			continue;
		}
		setting = g_value_get_long(value);
		vte_sequence_handler_decset_internal(that, setting, FALSE, TRUE, FALSE);
	}
}

/* Perform a screen alignment test -- fill all visible cells with the
 * letter "E". */
static void
vte_sequence_handler_screen_alignment_test (VteTerminalPrivate *that, GValueArray *params)
{
        that->seq_screen_alignment_test();
}

void
VteTerminalPrivate::seq_screen_alignment_test()
{
	for (auto row = m_screen->insert_delta;
	     row < m_screen->insert_delta + m_row_count;
	     row++) {
		/* Find this row. */
                while (_vte_ring_next(m_screen->row_data) <= row)
                        ring_append(false);
                adjust_adjustments();
                auto rowdata = _vte_ring_index_writable (m_screen->row_data, row);
		g_assert(rowdata != NULL);
		/* Clear this row. */
		_vte_row_data_shrink (rowdata, 0);

                emit_text_deleted();
		/* Fill this row. */
                VteCell cell;
		cell.c = 'E';
		cell.attr = basic_cell.attr;
		cell.attr.columns = 1;
                _vte_row_data_fill(rowdata, &cell, m_column_count);
                emit_text_inserted();
	}
        invalidate_all();

	/* We modified the display, so make a note of it for completeness. */
        m_text_modified_flag = TRUE;
}

/* DECSCUSR set cursor style */
static void
vte_sequence_handler_set_cursor_style (VteTerminalPrivate *that, GValueArray *params)
{
        long style;

        if ((params == NULL) || (params->n_values > 1)) {
                return;
        }

        if (params->n_values == 0) {
                /* no parameters means default (according to vt100.net) */
                style = VTE_CURSOR_STYLE_TERMINAL_DEFAULT;
        } else {
                GValue *value = g_value_array_get_nth(params, 0);

                if (!G_VALUE_HOLDS_LONG(value)) {
                        return;
                }
                style = g_value_get_long(value);
                if (style < 0 || style > 6) {
                        return;
                }
        }

        that->set_cursor_style((VteCursorStyle)style);
}

/* Perform a soft reset. */
static void
vte_sequence_handler_soft_reset (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset(false, false);
}

/* Window manipulation control sequences.  Most of these are considered
 * bad ideas, but they're implemented as signals which the application
 * is free to ignore, so they're harmless.  Handle at most one action,
 * see bug 741402. */
static void
vte_sequence_handler_window_manipulation (VteTerminalPrivate *that, GValueArray *params)
{
        if (params == NULL || params->n_values == 0) {
                return;
        }
        GValue* value = g_value_array_get_nth(params, 0);
        if (!G_VALUE_HOLDS_LONG(value)) {
                return;
        }
        auto param = g_value_get_long(value);

        long arg1, arg2;
        arg1 = arg2 = -1;
        if (params->n_values > 1) {
                value = g_value_array_get_nth(params, 1);
                if (G_VALUE_HOLDS_LONG(value)) {
                        arg1 = g_value_get_long(value);
                }
        }
        if (params->n_values > 2) {
                value = g_value_array_get_nth(params, 2);
                if (G_VALUE_HOLDS_LONG(value)) {
                        arg2 = g_value_get_long(value);
                }
        }

        that->seq_window_manipulation(param, arg1, arg2);
}

void
VteTerminalPrivate::seq_window_manipulation(long param,
                                            long arg1,
                                            long arg2)
{
	GdkScreen *gscreen;
	char buf[128];
	int width, height;

        switch (param) {
        case 1:
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Deiconifying window.\n");
                emit_deiconify_window();
                break;
        case 2:
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Iconifying window.\n");
                emit_iconify_window();
                break;
        case 3:
                if ((arg1 != -1) && (arg2 != -1)) {
                        _vte_debug_print(VTE_DEBUG_PARSE,
                                         "Moving window to "
                                         "%ld,%ld.\n", arg1, arg2);
                        emit_move_window(arg1, arg2);
                }
                break;
        case 4:
                if ((arg1 != -1) && (arg2 != -1)) {
                        _vte_debug_print(VTE_DEBUG_PARSE,
                                         "Resizing window "
                                         "(to %ldx%ld pixels, grid size %ldx%ld).\n",
                                         arg2, arg1,
                                         arg2 / m_char_width,
                                         arg1 / m_char_height);
                        emit_resize_window(arg2 / m_char_width,
                                           arg1 / m_char_height);
                }
                break;
        case 5:
                _vte_debug_print(VTE_DEBUG_PARSE, "Raising window.\n");
                emit_raise_window();
                break;
        case 6:
                _vte_debug_print(VTE_DEBUG_PARSE, "Lowering window.\n");
                emit_lower_window();
                break;
        case 7:
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Refreshing window.\n");
                invalidate_all();
                emit_refresh_window();
                break;
        case 8:
                if ((arg1 != -1) && (arg2 != -1)) {
                        _vte_debug_print(VTE_DEBUG_PARSE,
                                         "Resizing window "
                                         "(to %ld columns, %ld rows).\n",
                                         arg2, arg1);
                        emit_resize_window(arg2, arg1);
                }
                break;
        case 9:
                switch (arg1) {
                case 0:
                        _vte_debug_print(VTE_DEBUG_PARSE,
                                         "Restoring window.\n");
                        emit_restore_window();
                        break;
                case 1:
                        _vte_debug_print(VTE_DEBUG_PARSE,
                                         "Maximizing window.\n");
                        emit_maximize_window();
                        break;
                default:
                        break;
                }
                break;
        case 11:
                /* If we're unmapped, then we're iconified. */
                g_snprintf(buf, sizeof(buf),
                           _VTE_CAP_CSI "%dt",
                           1 + !gtk_widget_get_mapped(m_widget));
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting window state %s.\n",
                                 gtk_widget_get_mapped(m_widget) ?
                                 "non-iconified" : "iconified");
                feed_child(buf, -1);
                break;
        case 13:
                /* Send window location, in pixels. */
                gdk_window_get_origin(gtk_widget_get_window(m_widget),
                                      &width, &height);
                g_snprintf(buf, sizeof(buf),
                           _VTE_CAP_CSI "3;%d;%dt",
                           width + m_padding.left,
                           height + m_padding.top);
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting window location"
                                 "(%d++,%d++).\n",
                                 width, height);
                feed_child(buf, -1);
                break;
        case 14:
                /* Send window size, in pixels. */
                g_snprintf(buf, sizeof(buf),
                           _VTE_CAP_CSI "4;%d;%dt",
                           (int)(m_row_count * m_char_height),
                           (int)(m_column_count * m_char_width));
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting window size "
                                 "(%dx%d)\n",
                                 (int)(m_row_count * m_char_height),
                                 (int)(m_column_count * m_char_width));

                feed_child(buf, -1);
                break;
        case 18:
                /* Send widget size, in cells. */
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting widget size.\n");
                g_snprintf(buf, sizeof(buf),
                           _VTE_CAP_CSI "8;%ld;%ldt",
                           m_row_count,
                           m_column_count);
                feed_child(buf, -1);
                break;
        case 19:
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting screen size.\n");
                gscreen = gtk_widget_get_screen(m_widget);
                height = gdk_screen_get_height(gscreen);
                width = gdk_screen_get_width(gscreen);
                g_snprintf(buf, sizeof(buf),
                           _VTE_CAP_CSI "9;%ld;%ldt",
                           height / m_char_height,
                           width / m_char_width);
                feed_child(buf, -1);
                break;
        case 20:
                /* Report a static icon title, since the real
                   icon title should NEVER be reported, as it
                   creates a security vulnerability.  See
                   http://marc.info/?l=bugtraq&m=104612710031920&w=2
                   and CVE-2003-0070. */
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting fake icon title.\n");
                /* never use m_icon_title here! */
                g_snprintf (buf, sizeof (buf),
                            _VTE_CAP_OSC "LTerminal" _VTE_CAP_ST);
                feed_child(buf, -1);
                break;
        case 21:
                /* Report a static window title, since the real
                   window title should NEVER be reported, as it
                   creates a security vulnerability.  See
                   http://marc.info/?l=bugtraq&m=104612710031920&w=2
                   and CVE-2003-0070. */
                _vte_debug_print(VTE_DEBUG_PARSE,
                                 "Reporting fake window title.\n");
                /* never use m_window_title here! */
                g_snprintf (buf, sizeof (buf),
                            _VTE_CAP_OSC "lTerminal" _VTE_CAP_ST);
                feed_child(buf, -1);
                break;
        default:
                if (param >= 24) {
                        _vte_debug_print(VTE_DEBUG_PARSE,
                                         "Resizing to %ld rows.\n",
                                         param);
                        /* Resize to the specified number of
                         * rows. */
                        emit_resize_window(m_column_count,
                                           param);
                }
                break;
        }
}

/* Internal helper for setting/querying special colors */
static void
vte_sequence_handler_change_special_color_internal (VteTerminalPrivate *that, GValueArray *params,
						    int index, int index_fallback, int osc,
						    const char *terminator)
{
	if (params != NULL && params->n_values > 0) {
		GValue* value = g_value_array_get_nth (params, 0);

                char *name = nullptr;
		if (G_VALUE_HOLDS_STRING (value))
			name = g_value_dup_string (value);
		else if (G_VALUE_HOLDS_POINTER (value))
			name = that->ucs4_to_utf8((const guchar *)g_value_get_pointer (value));

		if (! name)
			return;

                that->seq_change_special_color_internal(name, index, index_fallback, osc, terminator);
                g_free(name);
        }
}

void
VteTerminalPrivate::seq_change_special_color_internal(char const* name,
                                                      int index,
                                                      int index_fallback,
                                                      int osc,
                                                      char const *terminator)
{
	vte::color::rgb color;

		if (color.parse(name))
			set_color(index, VTE_COLOR_SOURCE_ESCAPE, color);
		else if (strcmp (name, "?") == 0) {
			gchar buf[128];
			auto c = get_color(index);
			if (c == NULL && index_fallback != -1)
				c = get_color(index_fallback);
			g_assert(c != NULL);
			g_snprintf (buf, sizeof (buf),
				    _VTE_CAP_OSC "%d;rgb:%04x/%04x/%04x%s",
				    osc, c->red, c->green, c->blue, terminator);
			feed_child(buf, -1);
		}
}

/* Change the default foreground cursor, BEL terminated */
static void
vte_sequence_handler_change_foreground_color_bel (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_DEFAULT_FG, -1, 10, BEL);
}

/* Change the default foreground cursor, ST terminated */
static void
vte_sequence_handler_change_foreground_color_st (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_DEFAULT_FG, -1, 10, ST);
}

/* Reset the default foreground color */
static void
vte_sequence_handler_reset_foreground_color (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset_color(VTE_DEFAULT_FG, VTE_COLOR_SOURCE_ESCAPE);
}

/* Change the default background cursor, BEL terminated */
static void
vte_sequence_handler_change_background_color_bel (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_DEFAULT_BG, -1, 11, BEL);
}

/* Change the default background cursor, ST terminated */
static void
vte_sequence_handler_change_background_color_st (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_DEFAULT_BG, -1, 11, ST);
}

/* Reset the default background color */
static void
vte_sequence_handler_reset_background_color (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset_color(VTE_DEFAULT_BG, VTE_COLOR_SOURCE_ESCAPE);
}

/* Change the color of the cursor background, BEL terminated */
static void
vte_sequence_handler_change_cursor_background_color_bel (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_CURSOR_BG, VTE_DEFAULT_FG, 12, BEL);
}

/* Change the color of the cursor background, ST terminated */
static void
vte_sequence_handler_change_cursor_background_color_st (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_CURSOR_BG, VTE_DEFAULT_FG, 12, ST);
}

/* Reset the color of the cursor */
static void
vte_sequence_handler_reset_cursor_background_color (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset_color(VTE_CURSOR_BG, VTE_COLOR_SOURCE_ESCAPE);
}

/* Change the highlight background color, BEL terminated */
static void
vte_sequence_handler_change_highlight_background_color_bel (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_HIGHLIGHT_BG, VTE_DEFAULT_FG, 17, BEL);
}

/* Change the highlight background color, ST terminated */
static void
vte_sequence_handler_change_highlight_background_color_st (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_HIGHLIGHT_BG, VTE_DEFAULT_FG, 17, ST);
}

/* Reset the highlight background color */
static void
vte_sequence_handler_reset_highlight_background_color (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset_color(VTE_HIGHLIGHT_BG, VTE_COLOR_SOURCE_ESCAPE);
}

/* Change the highlight foreground color, BEL terminated */
static void
vte_sequence_handler_change_highlight_foreground_color_bel (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_HIGHLIGHT_FG, VTE_DEFAULT_BG, 19, BEL);
}

/* Change the highlight foreground color, ST terminated */
static void
vte_sequence_handler_change_highlight_foreground_color_st (VteTerminalPrivate *that, GValueArray *params)
{
	vte_sequence_handler_change_special_color_internal (that, params,
							    VTE_HIGHLIGHT_FG, VTE_DEFAULT_BG, 19, ST);
}

/* Reset the highlight foreground color */
static void
vte_sequence_handler_reset_highlight_foreground_color (VteTerminalPrivate *that, GValueArray *params)
{
	that->reset_color(VTE_HIGHLIGHT_FG, VTE_COLOR_SOURCE_ESCAPE);
}

/* URXVT generic OSC 777 */

static void
vte_sequence_handler_urxvt_777(VteTerminalPrivate *that, GValueArray *params)
{
        /* Accept but ignore this for compatibility with downstream-patched vte (bug #711059)*/
}

/* iterm2 OSC 133 & 1337 */

static void
vte_sequence_handler_iterm2_133(VteTerminalPrivate *that, GValueArray *params)
{
        /* Accept but ignore this for compatibility when sshing to an osx host
         * where the iterm2 integration is loaded even when not actually using
         * iterm2.
         */
}

static void
vte_sequence_handler_iterm2_1337(VteTerminalPrivate *that, GValueArray *params)
{
        /* Accept but ignore this for compatibility when sshing to an osx host
         * where the iterm2 integration is loaded even when not actually using
         * iterm2.
         */
}

/* Lookup tables */

#define VTE_SEQUENCE_HANDLER(name) name
#include "vteseq-n.cc"
#undef VTE_SEQUENCE_HANDLER

static VteTerminalSequenceHandler
_vte_sequence_get_handler (const char *name)
{
	size_t len = strlen(name);

	if (G_UNLIKELY (len < 2)) {
		return NULL;
	} else {
		auto seqhandler = vteseq_n_hash::lookup (name, len);
		return seqhandler ? seqhandler->handler : NULL;
	}
}


/* Handle a terminal control sequence and its parameters. */
void
VteTerminalPrivate::handle_sequence(char const* str,
                                    GValueArray *params)
{
	VteTerminalSequenceHandler handler;

	_VTE_DEBUG_IF(VTE_DEBUG_PARSE)
		display_control_sequence(str, params);

	/* Find the handler for this control sequence. */
	handler = _vte_sequence_get_handler (str);

	if (handler != NULL) {
		/* Let the handler handle it. */
		handler(this, params);
	} else {
		_vte_debug_print (VTE_DEBUG_MISC,
				  "No handler for control sequence `%s' defined.\n",
				  str);
	}
}
