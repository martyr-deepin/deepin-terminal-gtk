/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2018 Deepin, Inc.
 *               2011 ~ 2018 Wang Yong
 *
 * Author:     Wang Yong <wangyong@deepin.com>
 * Maintainer: Wang Yong <wangyong@deepin.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using Widgets;

namespace Widgets {
    public class PreferenceSlidebar : Gtk.Grid {
        public PreferenceSlideItem advanced_key_segment;
        public PreferenceSlideItem advanced_segment;
        public PreferenceSlideItem basic_segment;
        public PreferenceSlideItem cursor_segment;
        public PreferenceSlideItem focus_segment_item;
        public PreferenceSlideItem hotkey_segment;
        public PreferenceSlideItem scroll_segment;
        public PreferenceSlideItem terminal_key_segment;
        public PreferenceSlideItem theme_segment;
        public PreferenceSlideItem window_segment;
        public PreferenceSlideItem workspace_key_segment;
        public int height = 30;
        public int segment_spacing = 20;
        public int width = Constant.PREFERENCE_SLIDEBAR_WIDTH;

        public signal void click_item(string name);

        public PreferenceSlidebar() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            set_size_request(width, -1);

            var spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            spacing_box.set_size_request(-1, Constant.TITLEBAR_HEIGHT);
            this.attach(spacing_box, 0, 0, width, height);

            basic_segment = new PreferenceSlideItem(this, _("Basic"), "basic", true);
            this.attach_next_to(basic_segment, spacing_box, Gtk.PositionType.BOTTOM, width, height);

            theme_segment = new PreferenceSlideItem(this, _("Interface"), "theme", false);
            this.attach_next_to(theme_segment, basic_segment, Gtk.PositionType.BOTTOM, width, height);

            var theme_spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            theme_spacing_box.set_size_request(-1, segment_spacing);
            this.attach_next_to(theme_spacing_box, theme_segment, Gtk.PositionType.BOTTOM, width, height);

            hotkey_segment = new PreferenceSlideItem(this, _("Shortcuts"), "hotkey", true);
            this.attach_next_to(hotkey_segment, theme_spacing_box, Gtk.PositionType.BOTTOM, width, height);

            terminal_key_segment = new PreferenceSlideItem(this, _("Terminal"), "terminal_key", false);
            this.attach_next_to(terminal_key_segment, hotkey_segment, Gtk.PositionType.BOTTOM, width, height);

            workspace_key_segment = new PreferenceSlideItem(this, _("Workspace"), "workspace_key", false);
            this.attach_next_to(workspace_key_segment, terminal_key_segment, Gtk.PositionType.BOTTOM, width, height);

            advanced_key_segment = new PreferenceSlideItem(this, _("Advanced"), "advanced_key", false);
            this.attach_next_to(advanced_key_segment, workspace_key_segment, Gtk.PositionType.BOTTOM, width, height);

            var advanced_key_spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            advanced_key_spacing_box.set_size_request(-1, segment_spacing);
            this.attach_next_to(advanced_key_spacing_box, advanced_key_segment, Gtk.PositionType.BOTTOM, width, height);

            advanced_segment = new PreferenceSlideItem(this, _("Advanced"), "advanced", true);
            this.attach_next_to(advanced_segment, advanced_key_spacing_box, Gtk.PositionType.BOTTOM, width, height);

            cursor_segment = new PreferenceSlideItem(this, _("Cursor"), "cursor", false);
            this.attach_next_to(cursor_segment, advanced_segment, Gtk.PositionType.BOTTOM, width, height);

            scroll_segment = new PreferenceSlideItem(this, _("Scroll"), "scroll", false);
            this.attach_next_to(scroll_segment, cursor_segment, Gtk.PositionType.BOTTOM, width, height);

            window_segment = new PreferenceSlideItem(this, _("Window"), "window", false);
            this.attach_next_to(window_segment, scroll_segment, Gtk.PositionType.BOTTOM, width, height);

            var window_spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_spacing_box.set_size_request(-1, segment_spacing);
            this.attach_next_to(window_spacing_box, window_segment, Gtk.PositionType.BOTTOM, width, height);

            add_focus_handler(basic_segment);
            add_focus_handler(theme_segment);
            add_focus_handler(hotkey_segment);
            add_focus_handler(terminal_key_segment);
            add_focus_handler(workspace_key_segment);
            add_focus_handler(advanced_key_segment);
            add_focus_handler(advanced_segment);
            add_focus_handler(cursor_segment);
            add_focus_handler(scroll_segment);
            add_focus_handler(window_segment);
            focus_item(basic_segment);

            draw.connect(on_draw);

            show_all();
        }

        public void focus_item(PreferenceSlideItem item) {
            if (focus_segment_item != null) {
                focus_segment_item.is_selected = false;
                focus_segment_item.queue_draw();
            }

            focus_segment_item = item;
            focus_segment_item.is_selected = true;
            queue_draw();
        }

        public void add_focus_handler(PreferenceSlideItem item) {
            item.button_press_event.connect((w, e) => {
                    focus_item(item);

                    return false;
                });
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            cr.set_source_rgba(0, 0, 0, 0.1);
            Draw.draw_rectangle(cr, alloc.width - 1, 0, 1, alloc.height);

            return false;
        }
    }

    public class PreferenceSlideItem : Gtk.EventBox {
        public string item_name;
        public bool item_active;
        public bool is_first_segment;

        public int first_segment_margin = 30;
        public int second_segment_margin = 40;

        public int first_segment_size = 12;
        public int second_segment_size = 10;

        public Gdk.RGBA first_segment_text_color;
        public Gdk.RGBA second_segment_text_color;
        public Gdk.RGBA highlight_text_color;

        public bool is_selected = false;

        public int width = Constant.PREFERENCE_SLIDEBAR_WIDTH;
        public int height = 30;

        public PreferenceSlideItem(PreferenceSlidebar bar, string display_name, string name, bool is_first) {
            set_visible_window(false);

            item_name = display_name;
            is_first_segment = is_first;

            first_segment_text_color = Utils.hex_to_rgba("#00162C");
            second_segment_text_color = Utils.hex_to_rgba("#303030");
            highlight_text_color = Utils.hex_to_rgba("#2ca7f8");

            set_size_request(width, height);

            button_press_event.connect((w, e) => {
                    bar.click_item(name);

                    return false;
                });

            draw.connect(on_draw);
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);

            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rectangle(cr, 0, 0, rect.width - 1, rect.height, true);

            if (is_selected) {
                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 0.20);
                Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);

                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 0.10);
                Draw.draw_rectangle(cr, 0, 0, rect.width, 1, true);

                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 0.10);
                Draw.draw_rectangle(cr, 0, rect.height - 1, rect.width, 1, true);

                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 1);
                Draw.draw_rectangle(cr, rect.width - 3, 0, 3, rect.height, true);
            }

            if (is_first_segment) {
                if (is_selected) {
                    Utils.set_context_color(cr, highlight_text_color);
                } else {
                    Utils.set_context_color(cr, first_segment_text_color);
                }
                Draw.draw_text(cr, "<b>" + item_name + "</b>", first_segment_margin, 0, rect.width - first_segment_margin, rect.height, first_segment_size);
            } else {
                if (is_selected) {
                    Utils.set_context_color(cr, highlight_text_color);
                } else {
                    Utils.set_context_color(cr, second_segment_text_color);
                }
                Draw.draw_text(cr, item_name, second_segment_margin, 0, rect.width - second_segment_margin, rect.height, second_segment_size);
            }

            return true;
        }
    }
}
