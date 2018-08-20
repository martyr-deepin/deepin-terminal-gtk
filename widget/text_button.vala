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
    public class TextButton : Widgets.ClickEventBox {
        public bool is_hover = false;
        public Gdk.RGBA text_hover_color;
        public Gdk.RGBA text_normal_color;
        public Gdk.RGBA text_press_color;
        public int button_text_size = 10;
        public int height = 30;
        public string button_text;

        public TextButton(string text, string normal_color_string, string hover_color_string, string press_color_string) {
            set_size_request(-1, height);

            button_text = text;

            text_normal_color = Utils.hex_to_rgba(normal_color_string);
            text_hover_color = Utils.hex_to_rgba(hover_color_string);
            text_press_color = Utils.hex_to_rgba(press_color_string);

            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                       | Gdk.EventMask.BUTTON_RELEASE_MASK
                       | Gdk.EventMask.POINTER_MOTION_MASK
                       | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            visible_window = false;

            enter_notify_event.connect((w, e) => {
                    var display = Gdk.Display.get_default();
                    get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND1));

                    is_hover = true;
                    queue_draw();

                    return false;
                });
            leave_notify_event.connect((w, e) => {
                    get_window().set_cursor(null);

                    is_hover = false;
                    queue_draw();

                    return false;
                });

            button_press_event.connect((w, e) => {
                    queue_draw();

                    return false;
                });
            button_release_event.connect((w, e) => {
                    is_hover = false;
                    queue_draw();

                    return false;
                });
            clicked.connect((w, e) => {
                    get_window().set_cursor(null);
                });

            draw.connect(on_draw);
        }

        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);

            if (is_hover) {
                if (is_press) {
                    Utils.set_context_color(cr, text_press_color);
                    Draw.draw_text(cr, button_text, 0, 0, rect.width, rect.height, button_text_size, Pango.Alignment.CENTER);
                } else {
                    Utils.set_context_color(cr, text_hover_color);
                    Draw.draw_text(cr, button_text, 0, 0, rect.width, rect.height, button_text_size, Pango.Alignment.CENTER);
                }
            } else {
                Utils.set_context_color(cr, text_normal_color);
                Draw.draw_text(cr, button_text, 0, 0, rect.width, rect.height, button_text_size, Pango.Alignment.CENTER);
            }

            return true;
        }
    }

    public TextButton create_link_button(string text) {
        return new TextButton(text, "#0082FA", "#16B8FF", "#0060B9");
    }

    public TextButton create_delete_button(string text) {
        return new TextButton(text, "#FF5A5A", "#FF142D", "#AF0000");
    }
}
