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
    public class SearchPanel : Gtk.HBox {
        public Entry search_entry;
        public Gtk.Box clear_button_box;
        public ImageButton clear_button;
        public ImageButton search_next_button;
        public ImageButton search_previous_button;
        public Term terminal;
        public Widgets.ImageButton search_image;
        public int button_margin = 4;
        public int margin_horizontal = 10;
        public string search_text;

        public signal void quit_search();

        public SearchPanel(Widgets.ConfigWindow config_window, Term term, string init_search_text) {
            terminal = term;
            search_text = init_search_text;

            search_image = new ImageButton("search", true);
            search_entry = new Widgets.Entry();
            clear_button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            clear_button = new ImageButton("search_clear", true);
            search_next_button = new ImageButton("search_next", true);
            search_previous_button = new ImageButton("search_previous", true);

            search_entry.set_text(init_search_text);

            pack_start(search_image, false, false, 0);
            pack_start(search_entry, true, true, 0);
            pack_start(clear_button_box, false, false, 0);
            pack_start(search_previous_button, false, false, 0);
            pack_start(search_next_button, false, false, 0);

            search_image.set_valign(Gtk.Align.CENTER);
            search_entry.set_valign(Gtk.Align.CENTER);
            search_next_button.set_valign(Gtk.Align.CENTER);
            search_previous_button.set_valign(Gtk.Align.CENTER);
            clear_button_box.set_valign(Gtk.Align.CENTER);

            search_image.margin_start = margin_horizontal;
            clear_button_box.margin_end = margin_horizontal;
            search_previous_button.margin_end = margin_horizontal;
            search_entry.margin_end = button_margin;
            search_next_button.margin_end = button_margin;

            set_size_request(Constant.SEARCH_PANEL_WIDTH, Constant.TITLEBAR_HEIGHT);
            set_valign(Gtk.Align.START);
            set_halign(Gtk.Align.END);

            adjust_css_with_theme(config_window);
            realize.connect((w) => {
                    ((Widgets.ConfigWindow) this.get_toplevel()).config.update.connect((w) => {
                            adjust_css_with_theme(config_window);
                        });
                });

            search_entry.key_press_event.connect((w, e) => {
                    string keyname = Keymap.get_keyevent_name(e);

                    if (keyname == "Esc") {
                        quit_search();
                    } else if (keyname == "Enter") {
                        update_search_text();
                    }

                    return false;
                });
            search_entry.get_buffer().deleted_text.connect((buffer, p, nc) => {
                    string entry_text = search_entry.get_text().strip();
                    if (entry_text == "") {
                        hide_clear_button();
                    }

                    update_search_text();
                });
            search_entry.get_buffer().inserted_text.connect((buffer, p, c, nc) => {
                    string entry_text = search_entry.get_text().strip();
                    if (entry_text != "") {
                        show_clear_button();
                    }
                    update_search_text();
                });
            clear_button.button_press_event.connect((w, e) => {
                    search_entry.set_text("");
                    update_search_text();

                    return false;
                });
            search_entry.activate.connect((w) => {
                    if (search_text != "") {
                        terminal.term.search_find_next();
                    }
                });
            search_next_button.button_press_event.connect((w, e) => {
                    if (search_text != "") {
                        update_search_text();
                        terminal.term.search_find_next();
                    }

                    return false;
                });
            search_previous_button.button_press_event.connect((w, e) => {
                    if (search_text != "") {
                        update_search_text();
                        terminal.term.search_find_previous();
                    }

                    return false;
                });
        }

        public void update_search_text() {
            string entry_text = search_entry.get_text().strip();
            search_text = entry_text;

            try {
                GLib.RegexCompileFlags flags = GLib.RegexCompileFlags.OPTIMIZE;
                flags |= GLib.RegexCompileFlags.CASELESS;
                string pattern = GLib.Regex.escape_string(search_text);

                var regex = new Regex(pattern, flags, 0);
                terminal.term.search_set_gregex(regex, 0);
                terminal.term.search_set_wrap_around(true);
            } catch (GLib.RegexError e) {
                stdout.printf("Got error %s", e.message);
            }

        }

        public void adjust_css_with_theme(Widgets.ConfigWindow config_window) {
            bool is_light_theme = config_window.is_light_theme();

            get_style_context().remove_class("search_light_box");
            get_style_context().remove_class("search_dark_box");
            search_entry.get_style_context().remove_class("search_dark_entry");
            search_entry.get_style_context().remove_class("search_light_entry");

            if (is_light_theme) {
                search_entry.get_style_context().add_class("search_light_entry");
                get_style_context().add_class("search_light_box");
            } else {
                search_entry.get_style_context().add_class("search_dark_entry");
                get_style_context().add_class("search_dark_box");
            }
        }

        public void show_clear_button() {
            if (clear_button_box.get_children().length() == 0) {
                clear_button_box.add(clear_button);
                show_all();
            }
        }

        public void hide_clear_button() {
            Utils.remove_all_children(clear_button_box);
        }
    }
}
