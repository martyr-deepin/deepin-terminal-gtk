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
    public class ImageButton : Widgets.ClickEventBox {
        public bool is_hover = false;
        public Cairo.ImageSurface hover_dark_surface;
        public Cairo.ImageSurface hover_light_surface;
        public Cairo.ImageSurface normal_dark_surface;
        public Cairo.ImageSurface normal_light_surface;
        public Cairo.ImageSurface press_dark_surface;
        public Cairo.ImageSurface press_light_surface;
        public Gdk.RGBA text_hover_color;
        public Gdk.RGBA text_normal_color;
        public Gdk.RGBA text_press_color;
        public bool is_theme_button;
        public int button_text_size = 14;
        public string? button_text;

        public ImageButton(string image_path, bool theme_button=false, string? text=null, int text_size=12) {
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

            button_text = text;
            button_text_size = text_size;

            if (button_text != null) {
                text_normal_color = Utils.hex_to_rgba("#0699FF");
                text_hover_color = Utils.hex_to_rgba("#FFFFFF");
                text_press_color = Utils.hex_to_rgba("#FFFFFF");
            }

            set_size_request(this.normal_dark_surface.get_width() / get_scale_factor(),
                             this.normal_dark_surface.get_height() / get_scale_factor());

            draw.connect(on_draw);
            enter_notify_event.connect((w, e) => {
                    is_hover = true;
                    queue_draw();

                    return false;
                });
            leave_notify_event.connect((w, e) => {
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
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            bool is_light_theme = false;
            var top_level = get_toplevel();
            if (top_level.get_type().is_a(typeof(Widgets.Dialog))) {
                is_light_theme = ((Widgets.Dialog) top_level).transient_window.is_light_theme();
            } else {
                is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
            }

            var ratio = get_scale_factor();

            if (is_hover) {
                if (is_press) {
                    if (is_theme_button && is_light_theme) {
                        Draw.draw_surface(cr, press_light_surface);
                    } else {
                        Draw.draw_surface(cr, press_dark_surface);
                    }

                    if (button_text != null) {
                        Utils.set_context_color(cr, text_press_color);
                        Draw.draw_text(cr, button_text, 0, 0, normal_dark_surface.get_width() / ratio, normal_dark_surface.get_height() / ratio, button_text_size, Pango.Alignment.CENTER);
                    }
                } else {
                    if (is_theme_button && is_light_theme) {
                        Draw.draw_surface(cr, hover_light_surface);
                    } else {
                        Draw.draw_surface(cr, hover_dark_surface);
                    }

                    if (button_text != null) {
                        Utils.set_context_color(cr, text_hover_color);
                        Draw.draw_text(cr, button_text, 0, 0, normal_dark_surface.get_width() / ratio, normal_dark_surface.get_height() / ratio, button_text_size, Pango.Alignment.CENTER);
                    }
                }
            } else {
                if (is_theme_button && is_light_theme) {
                    Draw.draw_surface(cr, normal_light_surface);
                } else {
                    Draw.draw_surface(cr, normal_dark_surface);
                }

                if (button_text != null) {
                    Utils.set_context_color(cr, text_normal_color);
                    Draw.draw_text(cr, button_text, 0, 0, normal_dark_surface.get_width() / ratio, normal_dark_surface.get_height() / ratio, button_text_size, Pango.Alignment.CENTER);
                }
            }

            return true;
        }
    }
}
