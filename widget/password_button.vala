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
    public class PasswordButton : Gtk.EventBox {
        public Gtk.Box box;
        public Gtk.Box button_box;
        public ImageButton hide_password_button;
        public ImageButton show_password_button;
        public Widgets.Entry entry;
        public int height = 26;

        public PasswordButton() {
            visible_window = false;

            set_size_request(-1, height);

            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            entry = new Widgets.Entry();
            entry.margin_top = 1;
            entry.margin_bottom = 1;
            entry.set_invisible_char('●');
            entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);

            show_password_button = new ImageButton("password_show");
            hide_password_button = new ImageButton("password_hide");

            button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            box.pack_start(entry, true, true, 0);
            box.pack_start(button_box, false, false, 0);

            init();

            show_password_button.clicked.connect((w, e) => {
                    show_password();
                });

            hide_password_button.clicked.connect((w, e) => {
                    hide_password();
                });

            entry.get_buffer().deleted_text.connect((buffer, p, nc) => {
                    string entry_text = entry.get_text().strip();
                    if (entry_text == "") {
                        entry.get_style_context().remove_class("password_invisible_entry");
                        entry.get_style_context().add_class("password_visible_entry");
                    } else {
                        if (entry.get_visibility()) {
                            entry.get_style_context().remove_class("password_invisible_entry");
                            entry.get_style_context().add_class("password_visible_entry");
                        } else {
                            entry.get_style_context().remove_class("password_visible_entry");
                            entry.get_style_context().add_class("password_invisible_entry");
                        }
                    }
                });

            entry.get_buffer().inserted_text.connect((buffer, p, c, nc) => {
                    string entry_text = entry.get_text().strip();
                    if (entry_text == "") {
                        entry.get_style_context().remove_class("password_invisible_entry");
                        entry.get_style_context().add_class("password_visible_entry");
                    } else {
                        if (entry.get_visibility()) {
                            entry.get_style_context().remove_class("password_invisible_entry");
                            entry.get_style_context().add_class("password_visible_entry");
                        } else {
                            entry.get_style_context().remove_class("password_visible_entry");
                            entry.get_style_context().add_class("password_invisible_entry");
                        }
                    }
                });


            add(box);
        }

        public void init() {
            Utils.remove_all_children(button_box);

            entry.get_style_context().remove_class("password_invisible_entry");
            entry.get_style_context().add_class("password_visible_entry");
            entry.set_visibility(false);
            button_box.pack_start(show_password_button, false, false, 0);

            show_all();
        }

        public void show_password() {
            Utils.remove_all_children(button_box);

            entry.get_style_context().remove_class("password_invisible_entry");
            entry.get_style_context().add_class("password_visible_entry");
            entry.set_visibility(true);
            button_box.pack_start(hide_password_button, false, false, 0);

            show_all();
        }

        public void hide_password() {
            Utils.remove_all_children(button_box);

            entry.get_style_context().remove_class("password_visible_entry");
            entry.get_style_context().add_class("password_invisible_entry");
            entry.set_visibility(false);
            button_box.pack_start(show_password_button, false, false, 0);

            show_all();
        }
    }
}
