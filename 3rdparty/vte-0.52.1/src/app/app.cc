/*
 * Copyright © 2001,2002 Red Hat, Inc.
 * Copyright © 2014, 2017 Christian Persch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>
#include <locale.h>
#include <unistd.h>
#include <sys/types.h>

#include <glib.h>
#include <glib/gprintf.h>
#include <glib/gi18n.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gtk/gtk.h>
#include <cairo/cairo-gobject.h>
#include <vte/vte.h>
#include "vtepcre2.h"

#include <algorithm>

/* options */

class Options {
public:
        gboolean allow_window_ops{false};
        gboolean audible_bell{false};
        gboolean console{false};
        gboolean debug{false};
        gboolean icon_title{false};
        gboolean keep{false};
        gboolean no_argb_visual{false};
        gboolean no_bold{false};
        gboolean no_bold_is_bright{false};
        gboolean no_builtin_dingus{false};
        gboolean no_context_menu{false};
        gboolean no_double_buffer{false};
        gboolean no_geometry_hints{false};
        gboolean no_hyperlink{false};
        gboolean no_rewrap{false};
        gboolean no_shell{false};
        gboolean object_notifications{false};
        gboolean reverse{false};
        gboolean test_mode{false};
        gboolean use_gregex{false};
        gboolean version{false};
        gboolean whole_window_transparent{false};
        bool bg_color_set{false};
        bool fg_color_set{false};
        bool cursor_bg_color_set{false};
        bool cursor_fg_color_set{false};
        bool hl_bg_color_set{false};
        bool hl_fg_color_set{false};
        cairo_extend_t background_extend{CAIRO_EXTEND_NONE};
        char* command{nullptr};
        char* encoding{nullptr};
        char* font_string{nullptr};
        char* geometry{nullptr};
        char* output_filename{nullptr};
        char* word_char_exceptions{nullptr};
        char* working_directory{nullptr};
        char** dingus{nullptr};
        char** exec_argv{nullptr};
        char** environment{nullptr};
        GdkPixbuf* background_pixbuf{nullptr};
        GdkRGBA bg_color{1.0, 1.0, 1.0, 1.0};
        GdkRGBA fg_color{0.0, 0.0, 0.0, 1.0};
        GdkRGBA cursor_bg_color{};
        GdkRGBA cursor_fg_color{};
        GdkRGBA hl_bg_color{};
        GdkRGBA hl_fg_color{};
        int cjk_ambiguous_width{1};
        int extra_margin{-1};
        int scrollback_lines{-1 /* infinite */};
        int transparency_percent{-1};
        int verbosity{0};
        double cell_height_scale{1.0};
        double cell_width_scale{1.0};
        VteCursorBlinkMode cursor_blink_mode{VTE_CURSOR_BLINK_SYSTEM};
        VteCursorShape cursor_shape{VTE_CURSOR_SHAPE_BLOCK};
        VteTextBlinkMode text_blink_mode{VTE_TEXT_BLINK_ALWAYS};

        ~Options() {
                g_clear_object(&background_pixbuf);
                g_free(command);
                g_free(encoding);
                g_free(font_string);
                g_free(geometry);
                g_free(output_filename);
                g_free(word_char_exceptions);
                g_free(working_directory);
                g_strfreev(dingus);
                g_strfreev(exec_argv);
                g_strfreev(environment);
        }

private:

        bool parse_enum(GType type,
                        char const* str,
                        int& value,
                        GError** error)
        {
                GEnumClass* enum_klass = reinterpret_cast<GEnumClass*>(g_type_class_ref(type));
                GEnumValue* enum_value = g_enum_get_value_by_nick(enum_klass, str);

                if (enum_value == nullptr) {
                        g_type_class_unref(enum_klass);
                        g_set_error(error, G_OPTION_ERROR, G_OPTION_ERROR_BAD_VALUE,
                                    "Failed to parse enum value \"%s\" as type \"%s\"",
                                    str, g_quark_to_string(g_type_qname(type)));
                        return false;
                }

                value = enum_value->value;
                g_type_class_unref(enum_klass);
                return true;
        }

        bool parse_width_enum(char const* str,
                              int& value,
                              GError** error)
        {
                int v = 1;
                if (str == nullptr || g_str_equal(str, "narrow"))
                        v = 1;
                else if (g_str_equal(str, "wide"))
                        v = 2;
                else {
                        g_set_error(error, G_OPTION_ERROR, G_OPTION_ERROR_BAD_VALUE,
                                    "Failed to parse \"%s\" as width (allowed values are \"narrow\" or \"wide\")", str);
                        return false;
                }

                value = v;
                return true;
        }

        bool parse_color(char const* str,
                         GdkRGBA* value,
                         bool* value_set,
                         GError** error)
        {
                GdkRGBA color;
                if (!gdk_rgba_parse(&color, str)) {
                        g_set_error(error, G_OPTION_ERROR, G_OPTION_ERROR_BAD_VALUE,
                                    "Failed to parse \"%s\" as color", str);
                        *value_set = false;
                        return false;
                }

                *value = color;
                *value_set = true;
                return true;
        }

        bool parse_geometry(char const* str,
                            GError** error)
        {
                g_free(geometry);
                geometry = g_strdup(str);
                return true;
        }

        static gboolean
        parse_background_image(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                g_clear_object(&that->background_pixbuf);
                that->background_pixbuf = gdk_pixbuf_new_from_file(value, error);
                return that->background_pixbuf != nullptr;
        }

        static gboolean
        parse_background_extend(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                int v;
                auto rv = that->parse_enum(CAIRO_GOBJECT_TYPE_EXTEND, value, v, error);
                if (rv)
                        that->background_extend = cairo_extend_t(v);
                return rv;
        }

        static gboolean
        parse_cjk_width(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                return that->parse_width_enum(value, that->cjk_ambiguous_width, error);
        };

        static gboolean
        parse_cursor_blink(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                int v;
                auto rv = that->parse_enum(VTE_TYPE_CURSOR_BLINK_MODE, value, v, error);
                if (rv)
                        that->cursor_blink_mode = VteCursorBlinkMode(v);
                return rv;
        }

        static gboolean
        parse_cursor_shape(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                int v;
                auto rv = that->parse_enum(VTE_TYPE_CURSOR_SHAPE, value, v, error);
                if (rv)
                        that->cursor_shape = VteCursorShape(v);
                return rv;
        }

        static gboolean
        parse_bg_color(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                bool set;
                return that->parse_color(value, &that->bg_color, &set, error);
        }

        static gboolean
        parse_fg_color(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                bool set;
                return that->parse_color(value, &that->fg_color, &set, error);
        }

        static gboolean
        parse_cursor_bg_color(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                return that->parse_color(value, &that->cursor_bg_color, &that->cursor_bg_color_set, error);
        }

        static gboolean
        parse_cursor_fg_color(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                return that->parse_color(value, &that->cursor_fg_color, &that->cursor_fg_color_set, error);
        }

        static gboolean
        parse_hl_bg_color(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                return that->parse_color(value, &that->hl_bg_color, &that->hl_bg_color_set, error);
        }

        static gboolean
        parse_hl_fg_color(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                return that->parse_color(value, &that->hl_fg_color, &that->hl_fg_color_set, error);
        }

        static gboolean
        parse_text_blink(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                int v;
                auto rv = that->parse_enum(VTE_TYPE_TEXT_BLINK_MODE, value, v, error);
                if (rv)
                        that->text_blink_mode = VteTextBlinkMode(v);
                return rv;
        }

        static gboolean
        parse_verbosity(char const* option, char const* value, void* data, GError** error)
        {
                Options* that = static_cast<Options*>(data);
                that->verbosity++;
                return true;
        }

public:

        double get_alpha() const
        {
                return double(100 - CLAMP(transparency_percent, 0, 100)) / 100.0;
        }

        GdkRGBA get_color_bg() const
        {
                double alpha;
                if (background_pixbuf != nullptr)
                        alpha = 0.0;
                else if (whole_window_transparent)
                        alpha = 1.0;
                else
                        alpha = get_alpha();

                GdkRGBA color{bg_color};
                color.alpha = alpha;
                return color;
        }

        GdkRGBA get_color_fg() const
        {
                return fg_color;
        }

        bool parse_argv(int argc,
                        char* argv[],
                        GError** error)
        {
                bool dummy_bool;
                char* dummy_string = nullptr;
                GOptionEntry const entries[] = {
                        { "allow-window-ops", 0, 0, G_OPTION_ARG_NONE, &allow_window_ops,
                          "Allow window operations (resize, move, raise/lower, (de)iconify)", nullptr },
                        { "audible-bell", 'a', 0, G_OPTION_ARG_NONE, &audible_bell,
                          "Use audible terminal bell", nullptr },
                        { "background-color", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_bg_color,
                          "Set default background color", nullptr },
                        { "background-image", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_background_image,
                          "Set background image from file", "FILE" },
                        { "background-extend", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_background_extend,
                          "Set background image extend", "EXTEND" },
                        { "blink", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_text_blink,
                          "Text blink mode (never|focused|unfocused|always)", "MODE" },
                        { "cell-height-scale", 0, 0, G_OPTION_ARG_DOUBLE, &cell_height_scale,
                          "Add extra line spacing", "1.0..2.0" },
                        { "cell-width-scale", 0, 0, G_OPTION_ARG_DOUBLE, &cell_width_scale,
                          "Add extra letter spacing", "1.0..2.0" },
                        { "cjk-width", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_cjk_width,
                          "Specify the cjk ambiguous width to use for UTF-8 encoding", "NARROW|WIDE" },
                        { "cursor-blink", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_cursor_blink,
                          "Cursor blink mode (system|on|off)", "MODE" },
                        { "cursor-background-color", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_cursor_bg_color,
                          "Enable a colored cursor background", nullptr },
                        { "cursor-foreground-color", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_cursor_fg_color,
                          "Enable a colored cursor foreground", nullptr },
                        { "cursor-shape", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_cursor_shape,
                          "Set cursor shape (block|underline|ibeam)", nullptr },
                        { "dingu", 'D', 0, G_OPTION_ARG_STRING_ARRAY, &dingus,
                          "Add regex highlight", nullptr },
                        { "debug", 'd', 0,G_OPTION_ARG_NONE, &debug,
                          "Enable various debugging checks", nullptr },
                        { "encoding", 0, 0, G_OPTION_ARG_STRING, &encoding,
                          "Specify the terminal encoding to use", nullptr },
                        { "env", 0, 0, G_OPTION_ARG_FILENAME_ARRAY, &environment,
                          "Add environment variable to the child\'s environment", "VAR=VALUE" },
                        { "extra-margin", 0, 0, G_OPTION_ARG_INT, &extra_margin,
                          "Add extra margin around the terminal widget", "MARGIN" },
                        { "font", 'f', 0, G_OPTION_ARG_STRING, &font_string,
                          "Specify a font to use", nullptr },
                        { "foreground-color", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_fg_color,
                          "Set default foreground color", nullptr },
                        { "gregex", 0, 0, G_OPTION_ARG_NONE, &use_gregex,
                          "Use GRegex instead of PCRE2", nullptr },
                        { "geometry", 'g', 0, G_OPTION_ARG_STRING, &geometry,
                          "Set the size (in characters) and position", "GEOMETRY" },
                        { "highlight-background-color", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_hl_bg_color,
                          "Enable distinct highlight background color for selection", nullptr },
                        { "highlight-foreground-color", 0, 0, G_OPTION_ARG_CALLBACK, (void*)parse_hl_fg_color,
                          "Enable distinct highlight foreground color for selection", nullptr },
                        { "icon-title", 'i', 0, G_OPTION_ARG_NONE, &icon_title,
                          "Enable the setting of the icon title", nullptr },
                        { "keep", 'k', 0, G_OPTION_ARG_NONE, &keep,
                          "Live on after the command exits", nullptr },
                        { "no-argb-visual", 0, 0, G_OPTION_ARG_NONE, &no_argb_visual,
                          "Don't use an ARGB visual", nullptr },
                        { "no-bold", 0, 0, G_OPTION_ARG_NONE, &no_bold,
                          "Disable bold", nullptr },
                        { "no-bold-is-bright", 'B', 0, G_OPTION_ARG_NONE, &no_bold_is_bright,
                          "Bold does not brightens colors", nullptr },
                        { "no-builtin-dingus", 0, 0, G_OPTION_ARG_NONE, &no_builtin_dingus,
                          "Highlight URLs inside the terminal", nullptr },
                        { "no-context-menu", 0, 0, G_OPTION_ARG_NONE, &no_context_menu,
                          "Disable context menu", nullptr },
                        { "no-double-buffer", '2', 0, G_OPTION_ARG_NONE, &no_double_buffer,
                          "Disable double-buffering", nullptr },
                        { "no-geometry-hints", 'G', 0, G_OPTION_ARG_NONE, &no_geometry_hints,
                          "Allow the terminal to be resized to any dimension, not constrained to fit to an integer multiple of characters", nullptr },
                        { "no-hyperlink", 'H', 0, G_OPTION_ARG_NONE, &no_hyperlink,
                          "Disable hyperlinks", nullptr },
                        { "no-rewrap", 'R', 0, G_OPTION_ARG_NONE, &no_rewrap,
                          "Disable rewrapping on resize", nullptr },
                        { "no-shell", 'S', 0, G_OPTION_ARG_NONE, &no_shell,
                          "Disable spawning a shell inside the terminal", nullptr },
                        { "object-notifications", 'N', 0, G_OPTION_ARG_NONE, &object_notifications,
                          "Print VteTerminal object notifications", nullptr },
                        { "output-file", 0, 0, G_OPTION_ARG_FILENAME, &output_filename,
                          "Save terminal contents to file at exit", nullptr },
                        { "reverse", 0, 0, G_OPTION_ARG_NONE, &reverse,
                          "Reverse foreground/background colors", nullptr },
                        { "scrollback-lines", 'n', 0, G_OPTION_ARG_INT, &scrollback_lines,
                          "Specify the number of scrollback-lines (-1 for infinite)", nullptr },
                        { "transparent", 'T', 0, G_OPTION_ARG_INT, &transparency_percent,
                          "Enable the use of a transparent background", "0..100" },
                        { "verbose", 'v', G_OPTION_FLAG_NO_ARG, G_OPTION_ARG_CALLBACK,
                          (void*)parse_verbosity,
                          "Enable verbose debug output", nullptr },
                        { "version", 0, 0, G_OPTION_ARG_NONE, &version,
                          "Show version", nullptr },
                        { "whole-window-transparent", 0, 0, G_OPTION_ARG_NONE, &whole_window_transparent,
                          "Make the whole window transparent", NULL },
                        { "word-char-exceptions", 0, 0, G_OPTION_ARG_STRING, &word_char_exceptions,
                          "Specify the word char exceptions", "CHARS" },
                        { "working-directory", 'w', 0, G_OPTION_ARG_FILENAME, &working_directory,
                          "Specify the initial working directory of the terminal", nullptr },

                        /* Options for compatibility with the old vteapp test application */
                        { "border-width", 0, G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_INT, &extra_margin,
                          nullptr, nullptr },
                        { "command", 'c', G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_FILENAME, &command,
                          nullptr, nullptr },
                        { "console", 'C', G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_NONE, &console,
                          nullptr, nullptr },
                        { "double-buffer", '2', G_OPTION_FLAG_REVERSE | G_OPTION_FLAG_HIDDEN,
                          G_OPTION_ARG_NONE, &no_double_buffer, nullptr, nullptr },
                        { "pty-flags", 0, G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_STRING, &dummy_string,
                          nullptr, nullptr },
                        { "scrollbar-policy", 'P', G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_STRING,
                          &dummy_string, nullptr, nullptr },
                        { "scrolled-window", 'W', G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_NONE,
                          &dummy_bool, nullptr, nullptr },
                        { "shell", 'S', G_OPTION_FLAG_REVERSE | G_OPTION_FLAG_HIDDEN,
                          G_OPTION_ARG_NONE, &no_shell, nullptr, nullptr },
#ifdef VTE_DEBUG
                        { "test-mode", 0, 0, G_OPTION_ARG_NONE, &test_mode,
                          "Enable test mode", nullptr },
#endif
                        { nullptr }
                };

                /* Look for '--' */
                for (int i = 0; i < argc; i++) {
                        if (!g_str_equal(argv[i], "--"))
                                continue;

                        i++; /* skip it */
                        exec_argv = g_new(char*, argc - i + 1);
                        int j;
                        for (j = 0; i < argc; i++, j++)
                                exec_argv[j] = g_strdup(argv[i]);
                        exec_argv[j] = nullptr;
                        break;
                }

                auto context = g_option_context_new("[-- COMMAND …] — VTE test application");
                g_option_context_set_help_enabled(context, true);
                g_option_context_set_translation_domain(context, GETTEXT_PACKAGE);

                auto group = g_option_group_new(nullptr, nullptr, nullptr, this, nullptr);
                g_option_group_set_translation_domain(group, GETTEXT_PACKAGE);
                g_option_group_add_entries(group, entries);
                g_option_context_set_main_group(context, group);

                g_option_context_add_group(context, gtk_get_option_group(true));

                bool rv = g_option_context_parse(context, &argc, &argv, error);

                g_option_context_free(context);
                g_free(dummy_string);

                if (reverse)
                        std::swap(fg_color, bg_color);

                return rv;
        }
};

Options options{}; /* global */

/* debug output */

static void G_GNUC_PRINTF(2, 3)
verbose_fprintf(FILE* fp,
                char const* format,
                ...)
{
        if (options.verbosity == 0)
                return;

        va_list args;
        va_start(args, format);
        g_vfprintf(fp, format, args);
        va_end(args);
}

#define verbose_print(...) verbose_fprintf(stdout, __VA_ARGS__)
#define verbose_printerr(...) verbose_fprintf(stderr, __VA_ARGS__)

/* regex */

static GRegex*
compile_gregex(char const* pattern,
               bool caseless,
               GError** error)
{
        GRegexCompileFlags flags = GRegexCompileFlags(G_REGEX_OPTIMIZE |
                                                      G_REGEX_MULTILINE |
                                                      caseless ? G_REGEX_CASELESS : 0);

        return g_regex_new(pattern, flags, GRegexMatchFlags(0), error);
}

static void
jit_regex(VteRegex* regex,
          char const* pattern)
{
        GError *err = nullptr;
        if (!vte_regex_jit(regex, PCRE2_JIT_COMPLETE, &err) ||
            !vte_regex_jit(regex, PCRE2_JIT_PARTIAL_SOFT, &err)) {
                if (!g_error_matches(err, VTE_REGEX_ERROR, -45 /* PCRE2_ERROR_JIT_BADOPTION: JIT not supported */))
                        verbose_printerr("JITing regex \"%s\" failed: %s\n", pattern, err->message);
                g_error_free(err);
        }
}

static VteRegex*
compile_regex_for_search(char const* pattern,
                         bool caseless,
                         GError** error)
{
        uint32_t flags = PCRE2_UTF | PCRE2_NO_UTF_CHECK | PCRE2_MULTILINE;
        if (caseless)
                flags |= PCRE2_CASELESS;

        auto regex = vte_regex_new_for_search(pattern, strlen(pattern), flags, error);
        if (regex != nullptr)
                jit_regex(regex, pattern);

        return regex;
}

static VteRegex*
compile_regex_for_match(char const* pattern,
                        bool caseless,
                        GError** error)
{
        uint32_t flags = PCRE2_UTF | PCRE2_NO_UTF_CHECK | PCRE2_MULTILINE;
        if (caseless)
                flags |= PCRE2_CASELESS;

        auto regex = vte_regex_new_for_match(pattern, strlen(pattern), flags, error);
        if (regex != nullptr)
                jit_regex(regex, pattern);

        return regex;
}

/* search popover */

#define VTEAPP_TYPE_SEARCH_POPOVER         (vteapp_search_popover_get_type())
#define VTEAPP_SEARCH_POPOVER(o)           (G_TYPE_CHECK_INSTANCE_CAST((o), VTEAPP_TYPE_SEARCH_POPOVER, VteappSearchPopover))
#define VTEAPP_SEARCH_POPOVER_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), VTEAPP_TYPE_SEARCH_POPOVER, VteappSearchPopoverClass))
#define VTEAPP_IS_SEARCH_POPOVER(o)        (G_TYPE_CHECK_INSTANCE_TYPE((o), VTEAPP_TYPE_SEARCH_POPOVER))
#define VTEAPP_IS_SEARCH_POPOVER_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE((k), VTEAPP_TYPE_SEARCH_POPOVER))
#define VTEAPP_SEARCH_POPOVER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), VTEAPP_TYPE_SEARCH_POPOVER, VteappSearchPopoverClass))

typedef struct _VteappSearchPopover        VteappSearchPopover;
typedef struct _VteappSearchPopoverClass   VteappSearchPopoverClass;

struct _VteappSearchPopover {
        GtkPopover parent;

        /* from GtkWidget template */
        GtkWidget* search_entry;
        GtkWidget* search_prev_button;
        GtkWidget* search_next_button;
        GtkWidget* close_button;
        GtkToggleButton* match_case_checkbutton;
        GtkToggleButton* entire_word_checkbutton;
        GtkToggleButton* regex_checkbutton;
        GtkToggleButton* wrap_around_checkbutton;
        GtkWidget* reveal_button;
        GtkWidget* revealer;
        /* end */

        VteTerminal *terminal;
        bool regex_caseless;
        bool has_regex;
        char* regex_pattern;
};

struct _VteappSearchPopoverClass {
        GtkPopoverClass parent;
};

static GType vteapp_search_popover_get_type(void);

enum {
        SEARCH_POPOVER_PROP0,
        SEARCH_POPOVER_PROP_TERMINAL,
        SEARCH_POPOVER_N_PROPS
};

static GParamSpec* search_popover_pspecs[SEARCH_POPOVER_N_PROPS];

static void
vteapp_search_popover_update_sensitivity(VteappSearchPopover* popover)
{
        bool can_search = popover->has_regex;

        gtk_widget_set_sensitive(popover->search_next_button, can_search);
        gtk_widget_set_sensitive(popover->search_prev_button, can_search);
}

static void
vteapp_search_popover_update_regex(VteappSearchPopover* popover)
{
        char const* search_text = gtk_entry_get_text(GTK_ENTRY(popover->search_entry));
        bool caseless = gtk_toggle_button_get_active(popover->match_case_checkbutton) == FALSE;

        char* pattern;
        if (gtk_toggle_button_get_active(popover->regex_checkbutton))
                pattern = g_strdup(search_text);
        else
                pattern = g_regex_escape_string(search_text, -1);

        if (gtk_toggle_button_get_active(popover->regex_checkbutton)) {
                char* tmp = g_strdup_printf("\\b%s\\b", pattern);
                g_free(pattern);
                pattern = tmp;
        }

        if (caseless == popover->regex_caseless &&
            g_strcmp0(pattern, popover->regex_pattern) == 0)
                return;

        popover->regex_caseless = caseless;
        g_free(popover->regex_pattern);
        popover->regex_pattern = nullptr;

        if (search_text[0] != '\0') {
                GError* error = nullptr;

                if (options.use_gregex) {
                        auto regex = compile_gregex(pattern, caseless, &error);
                        vte_terminal_search_set_gregex(popover->terminal, regex, GRegexMatchFlags(0));
                        if (regex != nullptr)
                                g_regex_unref(regex);
                } else {
                        auto regex = compile_regex_for_search(pattern, caseless, &error);
                        vte_terminal_search_set_regex(popover->terminal, regex, 0);
                        if (regex != nullptr)
                                vte_regex_unref(regex);
                }

                if (error == nullptr) {
                        popover->has_regex = true;
                        popover->regex_pattern = pattern; /* adopt */
                        pattern = nullptr; /* adopted */
                        gtk_widget_set_tooltip_text(popover->search_entry, nullptr);
                } else {
                        popover->has_regex = false;
                        gtk_widget_set_tooltip_text(popover->search_entry, error->message);
                        g_error_free(error);
                }
        }

        g_free(pattern);

        vteapp_search_popover_update_sensitivity(popover);
}

static void
vteapp_search_popover_wrap_around_toggled(GtkToggleButton* button,
                                          VteappSearchPopover* popover)
{
        vte_terminal_search_set_wrap_around(popover->terminal, gtk_toggle_button_get_active(button));
}

static void
vteapp_search_popover_search_forward(VteappSearchPopover* popover)
{
        if (!popover->has_regex)
                return;
        vte_terminal_search_find_next(popover->terminal);
}

static void
vteapp_search_popover_search_backward(VteappSearchPopover* popover)
{
        if (!popover->has_regex)
                return;
        vte_terminal_search_find_previous(popover->terminal);
}

G_DEFINE_TYPE(VteappSearchPopover, vteapp_search_popover, GTK_TYPE_POPOVER)

static void
vteapp_search_popover_init(VteappSearchPopover* popover)
{
        gtk_widget_init_template(GTK_WIDGET(popover));

        popover->regex_caseless = false;
        popover->has_regex = false;
        popover->regex_pattern = nullptr;

        g_signal_connect_swapped(popover->close_button, "clicked", G_CALLBACK(gtk_widget_hide), popover);

        g_object_bind_property(popover->reveal_button, "active",
                               popover->revealer, "reveal-child",
                               GBindingFlags(G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE));

#if GTK_CHECK_VERSION(3, 16, 0)
        g_signal_connect_swapped(popover->search_entry, "next-match", G_CALLBACK(vteapp_search_popover_search_forward), popover);
        g_signal_connect_swapped(popover->search_entry, "previous-match", G_CALLBACK(vteapp_search_popover_search_backward), popover);
#endif
        g_signal_connect_swapped(popover->search_entry, "search-changed", G_CALLBACK(vteapp_search_popover_update_regex), popover);

        g_signal_connect_swapped(popover->search_next_button,"clicked", G_CALLBACK(vteapp_search_popover_search_forward), popover);
        g_signal_connect_swapped(popover->search_prev_button,"clicked", G_CALLBACK(vteapp_search_popover_search_backward), popover);

        g_signal_connect_swapped(popover->match_case_checkbutton,"toggled", G_CALLBACK(vteapp_search_popover_update_regex), popover);
        g_signal_connect_swapped(popover->entire_word_checkbutton,"toggled", G_CALLBACK(vteapp_search_popover_update_regex), popover);
        g_signal_connect_swapped(popover->regex_checkbutton,"toggled", G_CALLBACK(vteapp_search_popover_update_regex), popover);
        g_signal_connect_swapped(popover->match_case_checkbutton, "toggled", G_CALLBACK(vteapp_search_popover_update_regex), popover);

        g_signal_connect(popover->wrap_around_checkbutton, "toggled", G_CALLBACK(vteapp_search_popover_wrap_around_toggled), popover);

        vteapp_search_popover_update_sensitivity(popover);
}

static void
vteapp_search_popover_finalize(GObject *object)
{
        VteappSearchPopover* popover = VTEAPP_SEARCH_POPOVER(object);

        g_free(popover->regex_pattern);

        G_OBJECT_CLASS(vteapp_search_popover_parent_class)->finalize(object);
}

static void
vteapp_search_popover_set_property(GObject* object,
                                   guint prop_id,
                                   const GValue* value,
                                   GParamSpec* pspec)
{
        VteappSearchPopover* popover = VTEAPP_SEARCH_POPOVER(object);

        switch (prop_id) {
        case SEARCH_POPOVER_PROP_TERMINAL:
                popover->terminal = reinterpret_cast<VteTerminal*>(g_value_get_object(value));
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
                break;
        }
}

static void
vteapp_search_popover_class_init(VteappSearchPopoverClass* klass)
{
        GObjectClass* gobject_class = G_OBJECT_CLASS(klass);
        gobject_class->finalize = vteapp_search_popover_finalize;
        gobject_class->set_property = vteapp_search_popover_set_property;

        search_popover_pspecs[SEARCH_POPOVER_PROP_TERMINAL] =
                g_param_spec_object("terminal", nullptr, nullptr,
                                    VTE_TYPE_TERMINAL,
                                    GParamFlags(G_PARAM_WRITABLE | G_PARAM_STATIC_STRINGS | G_PARAM_CONSTRUCT_ONLY));

        g_object_class_install_properties(gobject_class, G_N_ELEMENTS(search_popover_pspecs), search_popover_pspecs);

        GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
        gtk_widget_class_set_template_from_resource(widget_class, "/org/gnome/vte/app/ui/search-popover.ui");
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, search_entry);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, search_prev_button);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, search_next_button);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, reveal_button);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, close_button);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, revealer);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, match_case_checkbutton);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, entire_word_checkbutton);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, regex_checkbutton);
        gtk_widget_class_bind_template_child(widget_class, VteappSearchPopover, wrap_around_checkbutton);
}

static GtkWidget*
vteapp_search_popover_new(VteTerminal* terminal,
                          GtkWidget* relative_to)
{
        return reinterpret_cast<GtkWidget*>(g_object_new(VTEAPP_TYPE_SEARCH_POPOVER,
                                                         "terminal", terminal,
                                                         "relative-to", relative_to,
                                                         nullptr));
}

/* terminal */

#define VTEAPP_TYPE_TERMINAL         (vteapp_terminal_get_type())
#define VTEAPP_TERMINAL(o)           (G_TYPE_CHECK_INSTANCE_CAST((o), VTEAPP_TYPE_TERMINAL, VteappTerminal))
#define VTEAPP_TERMINAL_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), VTEAPP_TYPE_TERMINAL, VteappTerminalClass))
#define VTEAPP_IS_TERMINAL(o)        (G_TYPE_CHECK_INSTANCE_TYPE((o), VTEAPP_TYPE_TERMINAL))
#define VTEAPP_IS_TERMINAL_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE((k), VTEAPP_TYPE_TERMINAL))
#define VTEAPP_TERMINAL_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), VTEAPP_TYPE_TERMINAL, VteappTerminalClass))

typedef struct _VteappTerminal       VteappTerminal;
typedef struct _VteappTerminalClass  VteappTerminalClass;

struct _VteappTerminal {
        VteTerminal parent;

        cairo_pattern_t* background_pattern;
};

struct _VteappTerminalClass {
        VteTerminalClass parent;
};

static GType vteapp_terminal_get_type(void);

G_DEFINE_TYPE(VteappTerminal, vteapp_terminal, VTE_TYPE_TERMINAL)

static void
vteapp_terminal_realize(GtkWidget* widget)
{
        GTK_WIDGET_CLASS(vteapp_terminal_parent_class)->realize(widget);

        VteappTerminal* terminal = VTEAPP_TERMINAL(widget);
        if (options.background_pixbuf != nullptr) {
                auto surface = gdk_cairo_surface_create_from_pixbuf(options.background_pixbuf,
                                                                    0 /* take scale from window */,
                                                                    gtk_widget_get_window(widget));
                terminal->background_pattern = cairo_pattern_create_for_surface(surface);
                cairo_surface_destroy(surface);

                cairo_pattern_set_extend(terminal->background_pattern, options.background_extend);
        }
}

static void
vteapp_terminal_unrealize(GtkWidget* widget)
{
        VteappTerminal* terminal = VTEAPP_TERMINAL(widget);
        if (terminal->background_pattern != nullptr) {
                cairo_pattern_destroy(terminal->background_pattern);
                terminal->background_pattern = nullptr;
        }

        GTK_WIDGET_CLASS(vteapp_terminal_parent_class)->unrealize(widget);
}

static gboolean
vteapp_terminal_draw(GtkWidget* widget,
                     cairo_t* cr)
{
        VteappTerminal* terminal = VTEAPP_TERMINAL(widget);
        if (terminal->background_pattern != nullptr) {
                cairo_push_group(cr);

                /* Draw background colour */
                cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
                cairo_rectangle(cr, 0.0, 0.0,
                                gtk_widget_get_allocated_width(widget),
                                gtk_widget_get_allocated_height(widget));
                auto bg = options.get_color_bg();
                cairo_set_source_rgba(cr, bg.red, bg.green, bg.blue, 1.0);
                cairo_paint(cr);

                /* Draw background image */
                cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
                cairo_set_source(cr, terminal->background_pattern);
                cairo_paint(cr);

                cairo_pop_group_to_source(cr);
                cairo_paint_with_alpha(cr, options.get_alpha());

        }

        return GTK_WIDGET_CLASS(vteapp_terminal_parent_class)->draw(widget, cr);
}

static void
vteapp_terminal_class_init(VteappTerminalClass *klass)
{
        GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);
        widget_class->realize = vteapp_terminal_realize;
        widget_class->unrealize = vteapp_terminal_unrealize;
        widget_class->draw = vteapp_terminal_draw;
}

static void
vteapp_terminal_init(VteappTerminal *terminal)
{
        terminal->background_pattern = nullptr;

        if (options.background_pixbuf != nullptr)
                vte_terminal_set_clear_background(VTE_TERMINAL(terminal), false);
}

static GtkWidget *
vteapp_terminal_new(void)
{
        return reinterpret_cast<GtkWidget*>(g_object_new(VTEAPP_TYPE_TERMINAL, nullptr));
}

/* terminal window */

#define VTEAPP_TYPE_WINDOW         (vteapp_window_get_type())
#define VTEAPP_WINDOW(o)           (G_TYPE_CHECK_INSTANCE_CAST((o), VTEAPP_TYPE_WINDOW, VteappWindow))
#define VTEAPP_WINDOW_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), VTEAPP_TYPE_WINDOW, VteappWindowClass))
#define VTEAPP_IS_WINDOW(o)        (G_TYPE_CHECK_INSTANCE_TYPE((o), VTEAPP_TYPE_WINDOW))
#define VTEAPP_IS_WINDOW_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE((k), VTEAPP_TYPE_WINDOW))
#define VTEAPP_WINDOW_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), VTEAPP_TYPE_WINDOW, VteappWindowClass))

typedef struct _VteappWindow       VteappWindow;
typedef struct _VteappWindowClass  VteappWindowClass;

struct _VteappWindow {
        GtkApplicationWindow parent;

        /* from GtkWidget template */
        GtkWidget* window_box;
        GtkScrollbar* scrollbar;
        /* GtkBox* notifications_box; */
        GtkWidget* readonly_emblem;
        /* GtkButton* copy_button; */
        /* GtkButton* paste_button; */
        GtkToggleButton* find_button;
        GtkMenuButton* gear_button;
        /* end */

        VteTerminal* terminal;
        GtkClipboard* clipboard;
        GPid child_pid;
        GtkWidget* search_popover;

        /* used for updating the geometry hints */
        int cached_cell_width{0};
        int cached_cell_height{0};
        int cached_chrome_width{0};
        int cached_chrome_height{0};
        int cached_csd_width{0};
        int cached_csd_height{0};
};

struct _VteappWindowClass {
        GtkApplicationWindowClass parent;
};

static GType vteapp_window_get_type(void);

static char const* const builtin_dingus[] = {
        "(((gopher|news|telnet|nntp|file|http|ftp|https)://)|(www|ftp)[-A-Za-z0-9]*\\.)[-A-Za-z0-9\\.]+(:[0-9]*)?",
        "(((gopher|news|telnet|nntp|file|http|ftp|https)://)|(www|ftp)[-A-Za-z0-9]*\\.)[-A-Za-z0-9\\.]+(:[0-9]*)?/[-A-Za-z0-9_\\$\\.\\+\\!\\*\\(\\),;:@&=\\?/~\\#\\%]*[^]'\\.}>\\) ,\\\"]",
        nullptr,
};

/* Just some arbitrary minimum values */
#define MIN_COLUMNS (16)
#define MIN_ROWS    (2)

static void
vteapp_window_add_dingus(VteappWindow* window,
                         char const* const* dingus)
{
        for (auto i = 0; dingus[i] != nullptr; i++) {
                int tag = -1;
                GError* error = nullptr;
                if (options.use_gregex) {
                        auto regex = compile_gregex(dingus[i], true, &error);
                        if (regex) {
                                tag = vte_terminal_match_add_gregex(window->terminal, regex,
                                                                    GRegexMatchFlags(0));
                                g_regex_unref(regex);
                        }
                } else {
                        auto regex = compile_regex_for_match(dingus[i], true, &error);
                        if (regex) {
                                tag = vte_terminal_match_add_regex(window->terminal, regex, 0);
                                vte_regex_unref(regex);
                        }
                }

                if (error != nullptr) {
                        verbose_printerr("Failed to compile regex \"%s\": %s\n", dingus[i], error->message);
                        g_error_free(error);
                }

                if (tag != -1)
                        vte_terminal_match_set_cursor_name(window->terminal, tag, "pointer");
        }
}

static void
vteapp_window_update_geometry(VteappWindow* window)
{
        GtkWidget* window_widget = GTK_WIDGET(window);
        GtkWidget* terminal_widget = GTK_WIDGET(window->terminal);

        int columns = vte_terminal_get_column_count(window->terminal);
        int rows = vte_terminal_get_row_count(window->terminal);
        int cell_width = vte_terminal_get_char_width(window->terminal);
        int cell_height = vte_terminal_get_char_height(window->terminal);

        /* Calculate the chrome size as difference between the content's
         * natural size requisition and the terminal grid's size.
         * This includes the terminal's padding in the chrome.
         */
        GtkRequisition contents_req;
        gtk_widget_get_preferred_size(window->window_box, nullptr, &contents_req);
        int chrome_width = contents_req.width - cell_width * columns;
        int chrome_height = contents_req.height - cell_height * rows;
        g_assert_cmpint(chrome_width, >=, 0);
        g_assert_cmpint(chrome_height, >=, 0);

        int csd_width = 0;
        int csd_height = 0;
        if (gtk_widget_get_realized(terminal_widget)) {
                /* Calculate the CSD size as difference between the toplevel's
                 * and content's allocation.
                 */
                GtkAllocation toplevel, contents;
                gtk_widget_get_allocation(window_widget, &toplevel);
                gtk_widget_get_allocation(window->window_box, &contents);

                csd_width = toplevel.width - contents.width;
                csd_height = toplevel.height - contents.height;
                g_assert_cmpint(csd_width, >=, 0);
                g_assert_cmpint(csd_height, >=, 0);

                /* Only actually set the geometry hints once the window is realized,
                 * since only then we know the CSD size. Only set the geometry when
                 * anything has changed.
                 */
                if (!options.no_geometry_hints &&
                    (cell_height != window->cached_cell_height ||
                     cell_width != window->cached_cell_width ||
                     chrome_width != window->cached_chrome_width ||
                     chrome_height != window->cached_chrome_height ||
                     csd_width != window->cached_csd_width ||
                     csd_width != window->cached_csd_height)) {
                        GdkGeometry geometry;

                        geometry.base_width = csd_width + chrome_width;
                        geometry.base_height = csd_height + chrome_height;
                        geometry.width_inc = cell_width;
                        geometry.height_inc = cell_height;
                        geometry.min_width = geometry.base_width + cell_width * MIN_COLUMNS;
                        geometry.min_height = geometry.base_height + cell_height * MIN_ROWS;

                        gtk_window_set_geometry_hints(GTK_WINDOW(window),
#if GTK_CHECK_VERSION (3, 19, 5)
                                                      nullptr,
#else
                                                      terminal_widget,
#endif
                                                      &geometry,
                                                      GdkWindowHints(GDK_HINT_RESIZE_INC |
                                                                     GDK_HINT_MIN_SIZE |
                                                                     GDK_HINT_BASE_SIZE));

                        verbose_print("Updating geometry hints base %dx%d inc %dx%d min %dx%d\n",
                                      geometry.base_width, geometry.base_height,
                                      geometry.width_inc, geometry.height_inc,
                                      geometry.min_width, geometry.min_height);
                }
        }

        window->cached_csd_width = csd_width;
        window->cached_csd_height = csd_height;
        window->cached_cell_width = cell_width;
        window->cached_cell_height = cell_height;
        window->cached_chrome_width = chrome_width;
        window->cached_chrome_height = chrome_height;

        verbose_print("Cached grid %dx%d cell-size %dx%d chrome %dx%d csd %dx%d\n",
                      columns, rows,
                      window->cached_cell_width, window->cached_cell_height,
                      window->cached_chrome_width, window->cached_chrome_height,
                      window->cached_csd_width, window->cached_csd_height);
}

static void
vteapp_window_resize(VteappWindow* window)
{
        /* Don't do this for maximised or tiled windows. */
        auto win = gtk_widget_get_window(GTK_WIDGET(window));
        if (win != nullptr &&
            (gdk_window_get_state(win) & (GDK_WINDOW_STATE_MAXIMIZED | GDK_WINDOW_STATE_TILED)) != 0)
                return;

        /* First, update the geometry hints, so that the cached_* members are up-to-date */
        vteapp_window_update_geometry(window);

        /* Calculate the window's pixel size corresponding to the terminal's grid size */
        int columns = vte_terminal_get_column_count(window->terminal);
        int rows = vte_terminal_get_row_count(window->terminal);
        int pixel_width = window->cached_chrome_width + window->cached_cell_width * columns;
        int pixel_height = window->cached_chrome_height + window->cached_cell_height * rows;

        verbose_print("VteappWindow resize grid %dx%d pixel %dx%d\n",
                      columns, rows, pixel_width, pixel_height);

        gtk_window_resize(GTK_WINDOW(window), pixel_width, pixel_height);
}

static void
vteapp_window_parse_geometry(VteappWindow* window)
{
        /* First update the geometry hints, so that gtk_window_parse_geometry()
         * knows the char width/height and base size increments.
         */
        vteapp_window_update_geometry(window);

        if (options.geometry != nullptr) {
                auto rv = gtk_window_parse_geometry(GTK_WINDOW(window), options.geometry);

                if (!rv)
                        verbose_printerr("Failed to parse geometry spec \"%s\"\n", options.geometry);
                else if (!options.no_geometry_hints) {
                        /* After parse_geometry(), we can get the default size in
                         * width/height increments, i.e. in grid size.
                         */
                        int columns, rows;
                        gtk_window_get_default_size(GTK_WINDOW(window), &columns, &rows);
                        vte_terminal_set_size(window->terminal, columns, rows);
                        gtk_window_resize_to_geometry(GTK_WINDOW(window), columns, rows);
                } else {
                        /* Approximate the grid width from the passed pixel size. */
                        int width, height;
                        gtk_window_get_default_size(GTK_WINDOW(window), &width, &height);
                        width -= window->cached_csd_width + window->cached_chrome_width;
                        height -= window->cached_csd_height + window->cached_chrome_height;
                        int columns = width / window->cached_cell_width;
                        int rows = height / window->cached_cell_height;
                        vte_terminal_set_size(window->terminal,
                                              MAX(columns, MIN_COLUMNS),
                                              MAX(rows, MIN_ROWS));
                }
        } else {
                /* In GTK+ 3.0, the default size of a window comes from its minimum
                 * size not its natural size, so we need to set the right default size
                 * explicitly */
                if (!options.no_geometry_hints) {
                        /* Grid based */
                        gtk_window_set_default_geometry(GTK_WINDOW(window),
                                                        vte_terminal_get_column_count(window->terminal),
                                                        vte_terminal_get_row_count(window->terminal));
                } else {
                        /* Pixel based */
                        vteapp_window_resize(window);
                }
        }
}

static void
vteapp_window_adjust_font_size(VteappWindow* window,
                               double factor)
{
        vte_terminal_set_font_scale(window->terminal,
                                    vte_terminal_get_font_scale(window->terminal) * factor);

        vteapp_window_resize(window);
}

static void
window_spawn_cb(VteTerminal* terminal,
                GPid child_pid,
                GError* error,
                void* data)
{
        if (terminal == nullptr) /* terminal destroyed while spawning */
                return;

        VteappWindow* window = VTEAPP_WINDOW(data);
        window->child_pid = child_pid;

        if (child_pid != -1)
                verbose_printerr("Spawning succeded, PID=%ld\n", (long)child_pid);

        if (error != nullptr) {
                verbose_printerr("Spawning failed: %s\n", error->message);

                if (!options.keep)
                        gtk_widget_destroy(GTK_WIDGET(window));
        }
}

static bool
vteapp_window_launch_argv(VteappWindow* window,
                          char** argv,
                          GError** error)
{
        vte_terminal_spawn_async(window->terminal,
                                 VTE_PTY_DEFAULT,
                                 options.working_directory,
                                 argv,
                                 options.environment,
                                 G_SPAWN_SEARCH_PATH_FROM_ENVP,
                                 nullptr, nullptr, nullptr, /* child setup, data and destroy */
                                 30 * 1000 /* 30s timeout */,
                                 nullptr /* cancellable */,
                                 window_spawn_cb, window);
        return true;
}

static bool
vteapp_window_launch_commandline(VteappWindow* window,
                                 char* commandline,
                                 GError** error)
{
        int argc;
        char** argv;
        if (!g_shell_parse_argv(commandline, &argc, &argv, error))
            return false;

        bool rv = vteapp_window_launch_argv(window, argv, error);

        g_strfreev(argv);
        return rv;
}

static bool
vteapp_window_launch_shell(VteappWindow* window,
                           GError** error)
{
        char* shell = vte_get_user_shell();
        if (shell == nullptr || shell[0] == '\0') {
                g_free(shell);
                shell = g_strdup(g_getenv("SHELL"));
        }
        if (shell == nullptr || shell[0] == '\0') {
                g_free(shell);
                shell = g_strdup("/bin/sh");
        }

        char* argv[2] = { shell, nullptr };

        bool rv = vteapp_window_launch_argv(window, argv, error);

        g_free(shell);
        return rv;
}

static bool
vteapp_window_fork(VteappWindow* window,
                   GError** error)
{
        auto pty = vte_pty_new_sync(VTE_PTY_DEFAULT, nullptr, error);
        if (pty == nullptr)
                return false;

        auto pid = fork();
        switch (pid) {
        case -1: /* error */
                g_set_error(error, G_IO_ERROR, G_IO_ERROR_FAILED, "Error forking: %m");
                return false;

        case 0: /* child */ {
                vte_pty_child_setup(pty);

                for (auto i = 0; ; i++) {
                        switch (i % 3) {
                        case 0:
                        case 1:
                                g_print("%d\n", i);
                                break;
                        case 2:
                                g_printerr("%d\n", i);
                                break;
                        }
                        g_usleep(G_USEC_PER_SEC);
                }
        }
        default: /* parent */
                vte_terminal_set_pty(window->terminal, pty);
                vte_terminal_watch_child(window->terminal, pid);
                verbose_print("Child PID is %d (mine is %d).\n", (int)pid, (int)getpid());
                break;
        }

        g_object_unref(pty);
        return true;
}

static void
vteapp_window_launch(VteappWindow* window)
{
        bool rv;
        GError* err = nullptr;

        if (options.exec_argv != nullptr)
                rv = vteapp_window_launch_argv(window, options.exec_argv, &err);
        else if (options.command != nullptr)
                rv = vteapp_window_launch_commandline(window, options.command, &err);
        else if (!options.no_shell)
                rv = vteapp_window_launch_shell(window, &err);
        else
                rv = vteapp_window_fork(window, &err);

        if (!rv) {
                verbose_printerr("Error launching: %s\n", err->message);
                g_error_free(err);
        }
}

static void
window_update_copy_sensitivity(VteappWindow* window)
{
        auto action = g_action_map_lookup_action(G_ACTION_MAP(window), "copy");
        g_simple_action_set_enabled(G_SIMPLE_ACTION(action),
                                    vte_terminal_get_has_selection(window->terminal));
}

static void
window_update_paste_sensitivity(VteappWindow* window)
{
        GdkAtom* targets;
        int n_targets;

        bool can_paste = false;
        if (gtk_clipboard_wait_for_targets(window->clipboard, &targets, &n_targets)) {
                can_paste = gtk_targets_include_text(targets, n_targets);
                g_free(targets);
        }

        auto action = g_action_map_lookup_action(G_ACTION_MAP(window), "copy");
        g_simple_action_set_enabled(G_SIMPLE_ACTION(action), can_paste);
}

/* Callbacks */

static void
window_action_copy_cb(GSimpleAction* action,
                      GVariant* parameter,
                      void* data)
{
        VteappWindow* window = VTEAPP_WINDOW(data);
        char const* str = g_variant_get_string(parameter, nullptr);

        vte_terminal_copy_clipboard_format(window->terminal,
                                           g_str_equal(str, "html") ? VTE_FORMAT_HTML : VTE_FORMAT_TEXT);

}

static void
window_action_copy_match_cb(GSimpleAction* action,
                            GVariant* parameter,
                            void* data)
{
        VteappWindow* window = VTEAPP_WINDOW(data);
        gsize len;
        char const* str = g_variant_get_string(parameter, &len);
        gtk_clipboard_set_text(window->clipboard, str, len);
}

static void
window_action_paste_cb(GSimpleAction* action,
                       GVariant* parameter,
                       void* data)
{
        VteappWindow* window = VTEAPP_WINDOW(data);
        vte_terminal_paste_clipboard(window->terminal);
}

static void
window_action_reset_cb(GSimpleAction* action,
                       GVariant* parameter,
                       void* data)
{
        VteappWindow* window = VTEAPP_WINDOW(data);
        bool clear;
        GdkModifierType modifiers;

        if (parameter != nullptr)
                clear = g_variant_get_boolean(parameter);
        else if (gtk_get_current_event_state(&modifiers))
                clear = (modifiers & GDK_CONTROL_MASK) != 0;
        else
                clear = false;

        vte_terminal_reset(window->terminal, true, clear);
}

static void
window_action_find_cb(GSimpleAction* action,
                      GVariant* parameter,
                      void* data)
{
        VteappWindow* window = VTEAPP_WINDOW(data);
        gtk_toggle_button_set_active(window->find_button, true);
}

static bool
vteapp_window_show_context_menu(VteappWindow* window,
                                guint button,
                                guint32 timestamp,
                                GdkEvent* event)
{
        if (options.no_context_menu)
                return false;

        auto menu = g_menu_new();
        g_menu_append(menu, "_Copy", "win.copy::text");
        g_menu_append(menu, "Copy As _HTML", "win.copy::html");

        if (event != nullptr) {
                auto hyperlink = vte_terminal_hyperlink_check_event(window->terminal, event);
                if (hyperlink != nullptr) {
                        verbose_print("Hyperlink: %s\n", hyperlink);
                        GVariant* target = g_variant_new_string(hyperlink);
                        auto item = g_menu_item_new("Copy _Hyperlink", nullptr);
                        g_menu_item_set_action_and_target_value(item, "win.copy-match", target);
                        g_menu_append_item(menu, item);
                        g_object_unref(item);
                }

                auto match = vte_terminal_match_check_event(window->terminal, event, nullptr);
                if (match != nullptr) {
                        verbose_print("Match: %s\n", match);
                        GVariant* target = g_variant_new_string(match);
                        auto item = g_menu_item_new("Copy _Match", nullptr);
                        g_menu_item_set_action_and_target_value(item, "win.copy-match", target);
                        g_menu_append_item(menu, item);
                        g_object_unref(item);
                }

                /* Test extra match API */
                char* extra_match = nullptr;
                if (options.use_gregex) {
                        auto regex = compile_gregex("\\d+", false, nullptr);
                        vte_terminal_event_check_gregex_simple(window->terminal, event,
                                                               &regex, 1,
                                                               GRegexMatchFlags(0),
                                                               &extra_match);
                        g_regex_unref(regex);
                } else {
                        auto regex = compile_regex_for_match("\\d+", false, nullptr);
                        vte_terminal_event_check_regex_simple(window->terminal, event,
                                                              &regex, 1, 0,
                                                              &extra_match);
                        vte_regex_unref(regex);
                }

                if (extra_match != nullptr) {
                        verbose_print("\\d+ match: %s\n", extra_match);
                        g_free(extra_match);
                }
        }

        g_menu_append(menu, "_Paste", "win.paste");

        auto popup = gtk_menu_new_from_model(G_MENU_MODEL(menu));
        gtk_menu_attach_to_widget(GTK_MENU(popup), GTK_WIDGET(window->terminal), nullptr);
        gtk_menu_popup(GTK_MENU(popup), nullptr, nullptr, nullptr, nullptr, button, timestamp);
        if (button == 0)
                gtk_menu_shell_select_first(GTK_MENU_SHELL(popup), true);

        return true;
}

static gboolean
window_popup_menu_cb(GtkWidget* widget,
                     VteappWindow* window)
{
        return vteapp_window_show_context_menu(window, 0, gtk_get_current_event_time(), nullptr);
}

static gboolean
window_button_press_cb(GtkWidget* widget,
                       GdkEventButton* event,
                       VteappWindow* window)
{
        if (event->button != GDK_BUTTON_SECONDARY)
                return false;

        return vteapp_window_show_context_menu(window, event->button, event->time,
                                               reinterpret_cast<GdkEvent*>(event));
}

static void
window_cell_size_changed_cb(VteTerminal* term,
                            guint width,
                            guint height,
                            VteappWindow* window)
{
        vteapp_window_update_geometry(window);
}

static void
window_child_exited_cb(VteTerminal* term,
                       int status,
                       VteappWindow* window)
{
        verbose_printerr("Child exited with status %x\n", status);

        if (options.output_filename != nullptr) {
                auto file = g_file_new_for_commandline_arg(options.output_filename);

                GError* err = nullptr;
                auto stream = g_file_replace(file, nullptr, false, G_FILE_CREATE_NONE, nullptr, &err);
                g_object_unref(file);
                if (stream != nullptr) {
                        vte_terminal_write_contents_sync(window->terminal,
                                                         G_OUTPUT_STREAM(stream),
                                                         VTE_WRITE_DEFAULT,
                                                         nullptr, &err);
                        g_object_unref(stream);
                }

                if (err != nullptr) {
                        verbose_printerr("Failed to write output to \"%s\": %s\n",
                                         options.output_filename, err->message);
                        g_error_free(err);
                }
        }

        window->child_pid = -1;

        if (options.keep)
                return;

        gtk_widget_destroy(GTK_WIDGET(window));
}

static void
window_clipboard_owner_change_cb(GtkClipboard* clipboard,
                                 GdkEvent* event,
                                 VteappWindow* window)
{
        window_update_paste_sensitivity(window);
}

static void
window_decrease_font_size_cb(VteTerminal* terminal,
                             VteappWindow* window)
{
        vteapp_window_adjust_font_size(window, 1.0 / 1.2);
}

static void
window_increase_font_size_cb(VteTerminal* terminal,
                             VteappWindow* window)
{
        vteapp_window_adjust_font_size(window, 1.2);
}

static void
window_deiconify_window_cb(VteTerminal* terminal,
                           VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;

        gtk_window_deiconify(GTK_WINDOW(window));
}

static void
window_iconify_window_cb(VteTerminal* terminal,
                         VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;

        gtk_window_iconify(GTK_WINDOW(window));
}

static void
window_icon_title_changed_cb(VteTerminal* terminal,
                         VteappWindow* window)
{
        if (!options.icon_title)
                return;

        gdk_window_set_icon_name(gtk_widget_get_window(GTK_WIDGET(window)),
                                 vte_terminal_get_icon_title(window->terminal));
}

static void
window_window_title_changed_cb(VteTerminal* terminal,
                               VteappWindow* window)
{
        gtk_window_set_title(GTK_WINDOW(window),
                             vte_terminal_get_window_title(window->terminal));
}

static void
window_lower_window_cb(VteTerminal* terminal,
                       VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;
        if (!gtk_widget_get_realized(GTK_WIDGET(window)))
                return;

        gdk_window_lower(gtk_widget_get_window(GTK_WIDGET(window)));
}

static void
window_raise_window_cb(VteTerminal* terminal,
                       VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;
        if (!gtk_widget_get_realized(GTK_WIDGET(window)))
                return;

        gdk_window_raise(gtk_widget_get_window(GTK_WIDGET(window)));
}

static void
window_maximize_window_cb(VteTerminal* terminal,
                          VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;

        gtk_window_maximize(GTK_WINDOW(window));
}

static void
window_restore_window_cb(VteTerminal* terminal,
                         VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;

        gtk_window_unmaximize(GTK_WINDOW(window));
}

static void
window_move_window_cb(VteTerminal* terminal,
                      guint x,
                      guint y,
                      VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;

        gtk_window_move(GTK_WINDOW(window), x, y);
}

static void
window_notify_cb(GObject* object,
                 GParamSpec* pspec,
                 VteappWindow* window)
{
        if (pspec->owner_type != VTE_TYPE_TERMINAL)
                return;

        GValue value G_VALUE_INIT;
        g_object_get_property(object, pspec->name, &value);
        auto str = g_strdup_value_contents(&value);
        g_value_unset(&value);

        verbose_print("NOTIFY property \"%s\" value %s\n", pspec->name, str);
        g_free(str);
}

static void
window_refresh_window_cb(VteTerminal* terminal,
                         VteappWindow* window)
{
        gtk_widget_queue_draw(GTK_WIDGET(window));
}

static void
window_resize_window_cb(VteTerminal* terminal,
                        guint columns,
                        guint rows,
                        VteappWindow* window)
{
        if (!options.allow_window_ops)
                return;
        if (columns < MIN_COLUMNS || rows < MIN_ROWS)
                return;

        vte_terminal_set_size(window->terminal, columns, rows);
        vteapp_window_resize(window);
}

static void
window_selection_changed_cb(VteTerminal* terminal,
                            VteappWindow* window)
{
        window_update_copy_sensitivity(window);
}

static void
window_input_enabled_state_cb(GAction* action,
                              GParamSpec* pspec,
                              VteappWindow* window)
{
        gtk_widget_set_visible(window->readonly_emblem,
                               !g_variant_get_boolean(g_action_get_state(action)));
}

static void
window_search_popover_closed_cb(GtkPopover* popover,
                                VteappWindow* window)
{
        if (gtk_toggle_button_get_active(window->find_button))
                gtk_toggle_button_set_active(window->find_button, false);
}

static void
window_find_button_toggled_cb(GtkToggleButton* button,
                              VteappWindow* window)
{
        auto active = gtk_toggle_button_get_active(button);

        if (gtk_widget_get_visible(GTK_WIDGET(window->search_popover)) != active)
                gtk_widget_set_visible(GTK_WIDGET(window->search_popover), active);
}

G_DEFINE_TYPE(VteappWindow, vteapp_window, GTK_TYPE_APPLICATION_WINDOW)

static void
vteapp_window_init(VteappWindow* window)
{
        gtk_widget_init_template(GTK_WIDGET(window));

        window->child_pid = -1;
}

static void
vteapp_window_constructed(GObject *object)
{
        VteappWindow* window = VTEAPP_WINDOW(object);

        G_OBJECT_CLASS(vteapp_window_parent_class)->constructed(object);

        gtk_window_set_title(GTK_WINDOW(window), "Terminal");

        /* Create terminal and connect scrollbar */
        window->terminal = reinterpret_cast<VteTerminal*>(vteapp_terminal_new());

        auto margin = options.extra_margin;
        if (margin >= 0) {
                gtk_widget_set_margin_start(GTK_WIDGET(window->terminal), margin);
                gtk_widget_set_margin_end(GTK_WIDGET(window->terminal), margin);
                gtk_widget_set_margin_top(GTK_WIDGET(window->terminal), margin);
                gtk_widget_set_margin_bottom(GTK_WIDGET(window->terminal), margin);
        }

        gtk_range_set_adjustment(GTK_RANGE(window->scrollbar),
                                 gtk_scrollable_get_vadjustment(GTK_SCROLLABLE(window->terminal)));

        /* Create actions */
        GActionEntry const entries[] = {
                { "copy",        window_action_copy_cb,       "s", nullptr, nullptr },
                { "copy-match",  window_action_copy_match_cb, "s", nullptr, nullptr },
                { "paste",       window_action_paste_cb,  nullptr, nullptr, nullptr },
                { "reset",       window_action_reset_cb,      "b", nullptr, nullptr },
                { "find",        window_action_find_cb,   nullptr, nullptr, nullptr },
        };

        GActionMap* map = G_ACTION_MAP(window);
        g_action_map_add_action_entries(map, entries, G_N_ELEMENTS(entries), window);

        /* Property actions */
        auto action = g_property_action_new("input-enabled", window->terminal, "input-enabled");
        g_action_map_add_action(map, G_ACTION(action));
        g_object_unref(action);
        g_signal_connect(action, "notify::state", G_CALLBACK(window_input_enabled_state_cb), window);

        /* Find */
        window->search_popover = vteapp_search_popover_new(window->terminal,
                                                           GTK_WIDGET(window->find_button));
        g_signal_connect(window->search_popover, "closed",
                         G_CALLBACK(window_search_popover_closed_cb), window);
        g_signal_connect(window->find_button, "toggled",
                         G_CALLBACK(window_find_button_toggled_cb), window);

        /* Clipboard */
        window->clipboard = gtk_widget_get_clipboard(GTK_WIDGET(window), GDK_SELECTION_CLIPBOARD);
        g_signal_connect(window->clipboard, "owner-change", G_CALLBACK(window_clipboard_owner_change_cb), window);

        /* Set ARGB visual */
        if (options.transparency_percent >= 0) {
                if (!options.no_argb_visual) {
                        auto screen = gtk_widget_get_screen(GTK_WIDGET(window));
                        auto visual = gdk_screen_get_rgba_visual(screen);
                        if (visual != nullptr)
                                gtk_widget_set_visual(GTK_WIDGET(window), visual);
       }

                /* Without this transparency doesn't work; see bug #729884. */
                gtk_widget_set_app_paintable(GTK_WIDGET(window), true);
        }

        /* Signals */
        g_signal_connect(window->terminal, "popup-menu", G_CALLBACK(window_popup_menu_cb), window);
        g_signal_connect(window->terminal, "button-press-event", G_CALLBACK(window_button_press_cb), window);
        g_signal_connect(window->terminal, "char-size-changed", G_CALLBACK(window_cell_size_changed_cb), window);
        g_signal_connect(window->terminal, "child-exited", G_CALLBACK(window_child_exited_cb), window);
        g_signal_connect(window->terminal, "decrease-font-size", G_CALLBACK(window_decrease_font_size_cb), window);
        g_signal_connect(window->terminal, "deiconify-window", G_CALLBACK(window_deiconify_window_cb), window);
        g_signal_connect(window->terminal, "icon-title-changed", G_CALLBACK(window_icon_title_changed_cb), window);
        g_signal_connect(window->terminal, "iconify-window", G_CALLBACK(window_iconify_window_cb), window);
        g_signal_connect(window->terminal, "increase-font-size", G_CALLBACK(window_increase_font_size_cb), window);
        g_signal_connect(window->terminal, "lower-window", G_CALLBACK(window_lower_window_cb), window);
        g_signal_connect(window->terminal, "maximize-window", G_CALLBACK(window_maximize_window_cb), window);
        g_signal_connect(window->terminal, "move-window", G_CALLBACK(window_move_window_cb), window);
        g_signal_connect(window->terminal, "raise-window", G_CALLBACK(window_raise_window_cb), window);
        g_signal_connect(window->terminal, "refresh-window", G_CALLBACK(window_refresh_window_cb), window);
        g_signal_connect(window->terminal, "resize-window", G_CALLBACK(window_resize_window_cb), window);
        g_signal_connect(window->terminal, "restore-window", G_CALLBACK(window_restore_window_cb), window);
        g_signal_connect(window->terminal, "selection-changed", G_CALLBACK(window_selection_changed_cb), window);
        g_signal_connect(window->terminal, "window-title-changed", G_CALLBACK(window_window_title_changed_cb), window);
        if (options.object_notifications)
                g_signal_connect(window->terminal, "notify", G_CALLBACK(window_notify_cb), window);

        /* Settings */
        if (options.no_double_buffer)
                gtk_widget_set_double_buffered(GTK_WIDGET(window->terminal), false);

        if (options.encoding != nullptr) {
                GError* err = nullptr;
                if (!vte_terminal_set_encoding(window->terminal, options.encoding, &err)) {
                        verbose_printerr("Failed to set encoding: %s\n", err->message);
                        g_error_free(err);
                }
        }

        if (options.word_char_exceptions != nullptr)
                vte_terminal_set_word_char_exceptions(window->terminal, options.word_char_exceptions);

        vte_terminal_set_allow_hyperlink(window->terminal, !options.no_hyperlink);
        vte_terminal_set_audible_bell(window->terminal, options.audible_bell);
        vte_terminal_set_allow_bold(window->terminal, !options.no_bold);
        vte_terminal_set_bold_is_bright(window->terminal, !options.no_bold_is_bright);
        vte_terminal_set_cell_height_scale(window->terminal, options.cell_height_scale);
        vte_terminal_set_cell_width_scale(window->terminal, options.cell_width_scale);
        vte_terminal_set_cjk_ambiguous_width(window->terminal, options.cjk_ambiguous_width);
        vte_terminal_set_cursor_blink_mode(window->terminal, options.cursor_blink_mode);
        vte_terminal_set_cursor_shape(window->terminal, options.cursor_shape);
        vte_terminal_set_mouse_autohide(window->terminal, true);
        vte_terminal_set_rewrap_on_resize(window->terminal, !options.no_rewrap);
        vte_terminal_set_scroll_on_output(window->terminal, false);
        vte_terminal_set_scroll_on_keystroke(window->terminal, true);
        vte_terminal_set_scrollback_lines(window->terminal, options.scrollback_lines);
        vte_terminal_set_text_blink_mode(window->terminal, options.text_blink_mode);

        /* Style */
        if (options.font_string != nullptr) {
                auto desc = pango_font_description_from_string(options.font_string);
                vte_terminal_set_font(window->terminal, desc);
                pango_font_description_free(desc);
        }

        auto fg = options.get_color_fg();
        auto bg = options.get_color_bg();
        vte_terminal_set_colors(window->terminal, &fg, &bg, nullptr, 0);
        if (options.cursor_bg_color_set)
                vte_terminal_set_color_cursor(window->terminal, &options.cursor_bg_color);
        if (options.cursor_fg_color_set)
                vte_terminal_set_color_cursor_foreground(window->terminal, &options.cursor_fg_color);
        if (options.hl_bg_color_set)
                vte_terminal_set_color_highlight(window->terminal, &options.hl_bg_color);
        if (options.hl_fg_color_set)
                vte_terminal_set_color_highlight_foreground(window->terminal, &options.hl_fg_color);

        if (options.whole_window_transparent)
                gtk_widget_set_opacity (GTK_WIDGET (window), options.get_alpha());

        /* Dingus */
        if (!options.no_builtin_dingus)
                vteapp_window_add_dingus(window, builtin_dingus);
        if (options.dingus != nullptr)
                vteapp_window_add_dingus(window, options.dingus);

        /* Done! */
        gtk_box_pack_start(GTK_BOX(window->window_box), GTK_WIDGET(window->terminal),
                           true, true, 0);
        gtk_widget_show(GTK_WIDGET(window->terminal));

        window_update_paste_sensitivity(window);
        window_update_copy_sensitivity(window);

        gtk_widget_grab_focus(GTK_WIDGET(window->terminal));

        /* Sanity check */
        g_assert(!gtk_widget_get_realized(GTK_WIDGET(window)));
}

static void
vteapp_window_dispose(GObject *object)
{
        VteappWindow* window = VTEAPP_WINDOW(object);

        if (window->clipboard != nullptr) {
                g_signal_handlers_disconnect_by_func(window->clipboard,
                                                     (void*)window_clipboard_owner_change_cb,
                                                     window);
                window->clipboard = nullptr;
        }

        if (window->search_popover != nullptr) {
                gtk_widget_destroy(window->search_popover);
                window->search_popover = nullptr;
        }

        G_OBJECT_CLASS(vteapp_window_parent_class)->dispose(object);
}

static void
vteapp_window_realize(GtkWidget* widget)
{
        GTK_WIDGET_CLASS(vteapp_window_parent_class)->realize(widget);

        /* Now we can know the CSD size, and thus apply the geometry. */
        VteappWindow* window = VTEAPP_WINDOW(widget);
        verbose_print("VteappWindow::realize\n");
        vteapp_window_resize(window);
}

static void
vteapp_window_show(GtkWidget* widget)
{
        GTK_WIDGET_CLASS(vteapp_window_parent_class)->show(widget);

        /* Re-apply the geometry. */
        VteappWindow* window = VTEAPP_WINDOW(widget);
        verbose_print("VteappWindow::show\n");
        vteapp_window_resize(window);
}

static void
vteapp_window_style_updated(GtkWidget* widget)
{
        GTK_WIDGET_CLASS(vteapp_window_parent_class)->style_updated(widget);

        /* Re-apply the geometry. */
        VteappWindow* window = VTEAPP_WINDOW(widget);
        verbose_print("VteappWindow::style-update\n");
        vteapp_window_resize(window);
}

static void
vteapp_window_class_init(VteappWindowClass* klass)
{
        GObjectClass* gobject_class = G_OBJECT_CLASS(klass);
        gobject_class->constructed  = vteapp_window_constructed;
        gobject_class->dispose  = vteapp_window_dispose;

        GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
        widget_class->realize = vteapp_window_realize;
        widget_class->show = vteapp_window_show;
        widget_class->style_updated = vteapp_window_style_updated;

        gtk_widget_class_set_template_from_resource(widget_class, "/org/gnome/vte/app/ui/window.ui");

        gtk_widget_class_bind_template_child(widget_class, VteappWindow, window_box);
        gtk_widget_class_bind_template_child(widget_class, VteappWindow, scrollbar);
        /* gtk_widget_class_bind_template_child(widget_class, VteappWindow, notification_box); */
        gtk_widget_class_bind_template_child(widget_class, VteappWindow, readonly_emblem);
        /* gtk_widget_class_bind_template_child(widget_class, VteappWindow, copy_button); */
        /* gtk_widget_class_bind_template_child(widget_class, VteappWindow, paste_button); */
        gtk_widget_class_bind_template_child(widget_class, VteappWindow, find_button);
        gtk_widget_class_bind_template_child(widget_class, VteappWindow, gear_button);
}

static VteappWindow*
vteapp_window_new(GApplication* app)
{
        return reinterpret_cast<VteappWindow*>(g_object_new(VTEAPP_TYPE_WINDOW,
                                                            "application", app,
                                                            nullptr));
}

/* application */

#define VTEAPP_TYPE_APPLICATION         (vteapp_application_get_type())
#define VTEAPP_APPLICATION(o)           (G_TYPE_CHECK_INSTANCE_CAST((o), VTEAPP_TYPE_APPLICATION, VteappApplication))
#define VTEAPP_APPLICATION_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), VTEAPP_TYPE_APPLICATION, VteappApplicationClass))
#define VTEAPP_IS_APPLICATION(o)        (G_TYPE_CHECK_INSTANCE_TYPE((o), VTEAPP_TYPE_APPLICATION))
#define VTEAPP_IS_APPLICATION_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE((k), VTEAPP_TYPE_APPLICATION))
#define VTEAPP_APPLICATION_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), VTEAPP_TYPE_APPLICATION, VteappApplicationClass))

typedef struct _VteappApplication       VteappApplication;
typedef struct _VteappApplicationClass  VteappApplicationClass;

struct _VteappApplication {
        GtkApplication parent;
};

struct _VteappApplicationClass {
        GtkApplicationClass parent;
};

static GType vteapp_application_get_type(void);

static void
app_action_new_cb(GSimpleAction* action,
                  GVariant* parameter,
                  void* data)
{
        GApplication* application = G_APPLICATION(data);
        auto window = vteapp_window_new(application);
        vteapp_window_parse_geometry(window);
        gtk_window_present(GTK_WINDOW(window));
        vteapp_window_launch(window);
}

static void
app_action_close_cb(GSimpleAction* action,
                    GVariant* parameter,
                    void* data)
{
        GtkApplication* application = GTK_APPLICATION(data);
        auto window = gtk_application_get_active_window(application);
        if (window != nullptr)
                gtk_widget_destroy(GTK_WIDGET(window));
}

G_DEFINE_TYPE(VteappApplication, vteapp_application, GTK_TYPE_APPLICATION)

static void
vteapp_application_init(VteappApplication* application)
{
        g_object_set(gtk_settings_get_default(),
                     "gtk-enable-mnemonics", FALSE,
                     "gtk-enable-accels", FALSE,
                     /* Make gtk+ CSD not steal F10 from the terminal */
                     "gtk-menu-bar-accel", nullptr,
                     nullptr);
}

static void
vteapp_application_startup(GApplication* application)
{
        /* Create actions */
        GActionEntry const entries[] = {
                { "new",   app_action_new_cb,   nullptr, nullptr, nullptr },
                { "close", app_action_close_cb, nullptr, nullptr, nullptr },
        };

        GActionMap* map = G_ACTION_MAP(application);
        g_action_map_add_action_entries(map, entries, G_N_ELEMENTS(entries), application);

        g_application_set_resource_base_path (application, "/org/gnome/vte/app");

        G_APPLICATION_CLASS(vteapp_application_parent_class)->startup(application);
}

static void
vteapp_application_activate(GApplication* application)
{
        auto action = g_action_map_lookup_action(G_ACTION_MAP(application), "new");
        g_action_activate(action, nullptr);
}

static void
vteapp_application_class_init(VteappApplicationClass* klass)
{
        GApplicationClass* application_class = G_APPLICATION_CLASS(klass);
        application_class->startup = vteapp_application_startup;
        application_class->activate = vteapp_application_activate;
}

static GApplication*
vteapp_application_new(void)
{
        return reinterpret_cast<GApplication*>(g_object_new(VTEAPP_TYPE_APPLICATION,
                                                            "application-id", "org.gnome.Vte.Application",
                                                            "flags", guint(G_APPLICATION_NON_UNIQUE),
                                                            nullptr));
}

/* main */

int
main(int argc,
     char *argv[])
{
        setlocale(LC_ALL, "");

	bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR);
#ifdef HAVE_DECL_BIND_TEXTDOMAIN_CODESET
	bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
#endif

        /* Not interested in silly debug spew, bug #749195 */
        if (g_getenv("G_ENABLE_DIAGNOSTIC") == nullptr)
                g_setenv("G_ENABLE_DIAGNOSTIC", "0", true);

       g_set_prgname("Terminal");
       g_set_application_name("Terminal");

       GError* error = nullptr;
       if (!options.parse_argv(argc, argv, &error)) {
               g_printerr("Error parsing arguments: %s\n", error->message);
               g_error_free(error);
               return EXIT_FAILURE;
       }

        if (g_getenv("VTE_CJK_WIDTH") != nullptr)
                verbose_printerr("VTE_CJK_WIDTH is not supported anymore, use --cjk-width instead\n");

       if (options.version) {
               g_print("VTE Application %s\n", VERSION);
               return EXIT_SUCCESS;
       }

       if (options.debug)
               gdk_window_set_debug_updates(true);
#ifdef VTE_DEBUG
       if (options.test_mode) {
               g_setenv("VTE_TEST", "1", true);
               options.allow_window_ops = true;
       } else {
               g_unsetenv("VTE_TEST");
       }
#endif

       auto app = vteapp_application_new();
       auto rv = g_application_run(app, 0, nullptr);
       g_object_unref(app);

       return rv;
}
