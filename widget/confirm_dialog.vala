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
    public class ConfirmDialog : Widgets.Dialog {
        private DialogButton cancel_button;
        private DialogButton confirm_button;
        private int box_margin_bottom = 24;
        private int box_margin_end = 20;
        private int box_margin_top = 4;
        private int content_margin_top = 3;
        private int logo_margin_end = 20;
        private int logo_margin_start = 20;
        private int title_margin_top = 7;

        public signal void cancel();
        public signal void confirm();

        public ConfirmDialog(string title, string content, string cancel_text, string confirm_text) {
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

            Label content_label = new Gtk.Label(null);
            content_label.set_halign(Gtk.Align.START);
            content_label.get_style_context().add_class("dialog_content");
            content_label.set_text(content);
            content_label.margin_top = content_margin_top;

            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            if (cancel_text != "") {
                cancel_button = new Widgets.DialogButton(cancel_text, "left", "text", screen_monitor.is_composited());
                cancel_button.clicked.connect((b) => {
                        cancel();
                        destroy();
                    });
            }
            if (cancel_text != "") {
                confirm_button = new Widgets.DialogButton(confirm_text, "right", "warning", screen_monitor.is_composited());
            } else {
                confirm_button = new Widgets.DialogButton(confirm_text, "middle", "warning", screen_monitor.is_composited());
            }
            confirm_button.clicked.connect((b) => {
                    confirm();
                    destroy();
                });

            var tab_order_list = new List<Gtk.Widget>();
            if (cancel_text != "") {
                tab_order_list.append((Gtk.Widget) cancel_button);
            }
            tab_order_list.append((Gtk.Widget) confirm_button);
            button_box.set_focus_chain(tab_order_list);
            button_box.set_focus_child(confirm_button);

            close_button_box.pack_start(close_button, true, true, 0);
            label_box.pack_start(title_label, false, false, 0);
            label_box.pack_start(content_label, false, false, 0);
            content_button_box.pack_start(logo_image, false, false, 0);
            content_button_box.pack_start(label_box, true, true, 0);
            if (cancel_text != "") {
                button_box.pack_start(cancel_button, true, true, 0);
            }
            button_box.pack_start(confirm_button, true, true, 0);
            box.pack_start(close_button_box, false, false, 0);
            box.pack_start(content_button_box, true, true, 0);
            box.pack_start(button_box, true, true, 0);

            var event_area = new Widgets.WindowEventArea(this);
            event_area.margin_end = Constant.CLOSE_BUTTON_WIDTH;
            event_area.margin_bottom = Constant.DIALOG_BUTTON_HEIGHT;

            overlay.add(box);
            overlay.add_overlay(event_area);

            add_widget(overlay);
        }
    }

    public ConfirmDialog create_running_confirm_dialog(Widgets.ConfigWindow window) {
        ConfirmDialog dialog = new ConfirmDialog(_("Programs are still running in terminal"), _("Are you sure you want to exit?"), _("Cancel"), _("Exit"));
        dialog.transient_for_window(window);

        return dialog;
    }
}
