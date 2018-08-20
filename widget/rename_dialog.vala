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
    public class RenameDialog : Widgets.Dialog {
        private DialogButton cancel_button;
        private DialogButton rename_button;
        private int box_margin_bottom = 24;
        private int box_margin_end = 20;
        private int box_margin_top = 4;
        private int content_margin_top = 3;
        private int logo_margin_end = 20;
        private int logo_margin_start = 20;
        private int title_margin_top = 7;

        public signal void cancel();
        public signal void rename(string new_title);

        public RenameDialog(string title, string content, string cancel_text, string rename_text) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            set_init_size(480, 230);

            // Add widgets.
            var overlay = new Gtk.Overlay();
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            var close_button = Widgets.create_close_button();
            close_button.clicked.connect((b) => {
                    this.destroy();
                });
            var close_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            close_button_box.pack_start(close_button, true, true, 0);

            var content_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            content_button_box.margin_top = box_margin_top;
            content_button_box.margin_bottom = box_margin_bottom;
            content_button_box.margin_end = box_margin_end;

            Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("dialog_icon.svg"));
            logo_image.margin_start = logo_margin_start;
            logo_image.margin_end = logo_margin_end;

            var label_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            Label title_label = new Gtk.Label(null);
            title_label.set_halign(Gtk.Align.START);
            title_label.get_style_context().add_class("dialog_title");
            title_label.set_text(title);
            title_label.margin_top = title_margin_top;

            var title_entry = new Widgets.Entry();
            title_entry.set_text(content);
            title_entry.margin_top = content_margin_top;
            title_entry.get_style_context().add_class("preference_entry");

            title_entry.activate.connect((entry) => {
                    rename(entry.get_text());
                    destroy();
                });

            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            if (cancel_text != "") {
                cancel_button = new Widgets.DialogButton(cancel_text, "left", "text", screen_monitor.is_composited());
                cancel_button.clicked.connect((b) => {
                        cancel();
                        destroy();
                    });
            }
            if (cancel_text != "") {
                rename_button = new Widgets.DialogButton(rename_text, "right", "warning", screen_monitor.is_composited());
            } else {
                rename_button = new Widgets.DialogButton(rename_text, "middle", "warning", screen_monitor.is_composited());
            }
            rename_button.clicked.connect((b) => {
                    rename(title_entry.get_text());
                    destroy();
                });

            var tab_order_list = new List<Gtk.Widget>();
            tab_order_list.append((Gtk.Widget) title_entry);
            if (cancel_text != "") {
                tab_order_list.append((Gtk.Widget) cancel_button);
            }
            tab_order_list.append((Gtk.Widget) rename_button);
            button_box.set_focus_chain(tab_order_list);
            button_box.set_focus_child(title_entry);

            close_button_box.pack_start(close_button, true, true, 0);
            label_box.pack_start(title_label, false, false, 0);
            label_box.pack_start(title_entry, false, false, 0);
            content_button_box.pack_start(logo_image, false, false, 0);
            content_button_box.pack_start(label_box, true, true, 0);
            if (cancel_text != "") {
                button_box.pack_start(cancel_button, true, true, 0);
            }
            button_box.pack_start(rename_button, true, true, 0);
            box.pack_start(close_button_box, false, false, 0);
            box.pack_start(content_button_box, true, true, 0);
            box.pack_start(button_box, true, true, 0);

            var event_area = new Widgets.WindowEventArea(this);
            event_area.margin_end = Constant.CLOSE_BUTTON_WIDTH;
            if (screen_monitor.is_composited()) {
                event_area.margin_bottom = window_init_height - window_frame_margin_top - window_frame_margin_bottom - Constant.TITLEBAR_HEIGHT;
            } else {
                event_area.margin_bottom = window_init_height - Constant.TITLEBAR_HEIGHT;
            }

            overlay.add(box);
            overlay.add_overlay(event_area);

            add_widget(overlay);
        }
    }
}
