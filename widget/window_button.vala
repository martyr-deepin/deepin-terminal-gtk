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

using Cairo;
using Draw;
using Gtk;
using Utils;

namespace Widgets {
    public class WindowButton : Widgets.ClickEventBox {
        public Cairo.ImageSurface hover_dark_surface;
        public Cairo.ImageSurface hover_light_surface;
        public Cairo.ImageSurface normal_dark_surface;
        public Cairo.ImageSurface normal_light_surface;
        public Cairo.ImageSurface press_dark_surface;
        public Cairo.ImageSurface press_light_surface;
        public bool is_hover = false;
        public bool is_theme_button;
        public int surface_y;

        public WindowButton(string image_path, bool theme_button=false, int width, int height) {
            is_theme_button = theme_button;

            if (is_theme_button) {
                normal_dark_surface = Utils.create_image_surface(image_path + "_dark_normal.svg");
                hover_dark_surface = Utils.create_image_surface(image_path + "_dark_hover.svg");
                press_dark_surface = Utils.create_image_surface(image_path + "_dark_press.svg");

                normal_light_surface = Utils.create_image_surface(image_path + "_light_normal.svg");
                hover_light_surface = Utils.create_image_surface(image_path + "_light_hover.svg");
                press_light_surface = Utils.create_image_surface(image_path + "_light_press.svg");
            } else {
                normal_dark_surface = Utils.create_image_surface(image_path + "_normal.svg");
                hover_dark_surface = Utils.create_image_surface(image_path + "_hover.svg");
                press_dark_surface = Utils.create_image_surface(image_path + "_press.svg");
            }

            set_size_request(width, height);

            surface_y = (height - normal_dark_surface.get_height() / get_scale_factor()) / 2;

            draw.connect(on_draw);
            enter_notify_event.connect((w, e) => {
                    is_hover = true;
                    queue_draw();

                    // set cursor.
                    get_window().set_cursor(new Gdk.Cursor.for_display(Gdk.Display.get_default(),
                                                                       Gdk.CursorType.HAND1));

                    return false;
                });
            leave_notify_event.connect((w, e) => {
                    is_hover = false;
                    queue_draw();

                    get_window().set_cursor(null);

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
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            bool is_light_theme = false;
            var top_level = get_toplevel();
            if (top_level.get_type().is_a(typeof(Widgets.Dialog))) {
                is_light_theme = ((Widgets.Dialog) top_level).transient_window.is_light_theme();
            } else {
                is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
            }

            if (is_hover) {
                if (is_press) {
                    if (is_theme_button && is_light_theme) {
                        Draw.draw_surface(cr, press_light_surface, 0, surface_y);
                    } else {
                        Draw.draw_surface(cr, press_dark_surface, 0, surface_y);
                    }
                } else {
                    if (is_theme_button && is_light_theme) {
                        Draw.draw_surface(cr, hover_light_surface, 0, surface_y);
                    } else {
                        Draw.draw_surface(cr, hover_dark_surface, 0, surface_y);
                    }
                }
            } else {
                if (is_theme_button && is_light_theme) {
                    Draw.draw_surface(cr, normal_light_surface, 0, surface_y);
                } else {
                    Draw.draw_surface(cr, normal_dark_surface, 0, surface_y);
                }
            }

            return true;
        }
    }

    public WindowButton create_close_button() {
        var close_button = new WindowButton("titlebar_close", false, Constant.WINDOW_BUTTON_WIDHT + Constant.CLOSE_BUTTON_MARGIN_RIGHT, Constant.TITLEBAR_HEIGHT);
        close_button.set_halign(Gtk.Align.END);

        return close_button;
    }
}
