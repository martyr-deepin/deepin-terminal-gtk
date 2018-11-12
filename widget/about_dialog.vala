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
    public class AboutDialog : Widgets.Dialog {
        public Gtk.Widget? focus_widget;

        public AboutDialog(Gtk.Widget? widget) {
            focus_widget = widget;

            var overlay = new Gtk.Overlay();

            var close_button = Widgets.create_close_button();
            close_button.clicked.connect((b) => {
                    this.destroy();
                });

            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });

            var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            button_box.pack_start(close_button, true, true, 0);

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(button_box, false, false, 0);

            var about_widget = new AboutWidget();
            box.pack_start(about_widget, true, true, 0);

            set_init_size(500, 460);

            int about_text_height = Draw.get_text_render_height(
                about_widget,
                about_widget.about_text,
                window_init_width - about_widget.about_x * 2,
                about_widget.about_height,
                about_widget.about_height,
                Pango.Alignment.LEFT,
                "top",
                window_init_width - about_widget.about_x * 2);

            window_init_height += about_text_height;

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
