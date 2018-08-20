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
    public class PanelButton : Widgets.ClickEventBox {
        public bool is_hover = false;
        public Cairo.ImageSurface button_dark_surface;
        public Cairo.ImageSurface button_edit_hover_dark_surface;
        public Cairo.ImageSurface button_edit_hover_light_surface;
        public Cairo.ImageSurface button_edit_normal_dark_surface;
        public Cairo.ImageSurface button_edit_normal_light_surface;
        public Cairo.ImageSurface button_edit_press_dark_surface;
        public Cairo.ImageSurface button_edit_press_light_surface;
        public Cairo.ImageSurface button_light_surface;
        public Gdk.RGBA button_content_dark_color;
        public Gdk.RGBA button_content_light_color;
        public Gdk.RGBA button_name_dark_color;
        public Gdk.RGBA button_name_light_color;
        public Gdk.RGBA hover_dark_color;
        public Gdk.RGBA hover_light_color;
        public Gdk.RGBA line_dark_color;
        public Gdk.RGBA line_light_color;
        public Gdk.RGBA press_dark_color;
        public Gdk.RGBA press_light_color;
        public bool display_bottom_line = true;
        public bool has_click = false;
        public bool is_at_edit_button_area = false;
        public int button_content_size = 10;
        public int button_content_y = 27;
        public int button_name_size = 11;
        public int button_name_y = 5;
        public int edit_button_x = 254;
        public int edit_button_y;
        public int height = 56;
        public int image_x = 12;
        public int text_width = Constant.SLIDER_PANEL_TEXT_WIDTH;
        public int text_x = 72;
        public int width = Constant.SLIDER_WIDTH;
        public string button_content;
        public string button_name;
        public string? button_display_name;

        public signal void click_button();
        public signal void click_edit_button();

        public PanelButton(string name, string content, string? display_name, string edit_button_name) {
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                            | Gdk.EventMask.BUTTON_RELEASE_MASK
                            | Gdk.EventMask.POINTER_MOTION_MASK
                            | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            button_name = name;
            button_content = content;
            button_display_name = display_name;

            button_dark_surface = Utils.create_image_surface("%s_dark.svg".printf(edit_button_name));
            button_light_surface = Utils.create_image_surface("%s_light.svg".printf(edit_button_name));
            button_edit_normal_dark_surface = Utils.create_image_surface("button_edit_dark_normal.svg");
            button_edit_hover_dark_surface = Utils.create_image_surface("button_edit_dark_hover.svg");
            button_edit_press_dark_surface = Utils.create_image_surface("button_edit_dark_press.svg");
            button_edit_normal_light_surface = Utils.create_image_surface("button_edit_light_normal.svg");
            button_edit_hover_light_surface = Utils.create_image_surface("button_edit_light_hover.svg");
            button_edit_press_light_surface = Utils.create_image_surface("button_edit_light_press.svg");

            button_name_dark_color = Utils.hex_to_rgba("#FFFFFF");
            button_content_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.5);
            press_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.1);
            hover_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.1);
            button_name_light_color = Utils.hex_to_rgba("#303030");
            button_content_light_color = Utils.hex_to_rgba("#000000", 0.5);
            press_light_color = Utils.hex_to_rgba("#000000", 0.1);
            hover_light_color = Utils.hex_to_rgba("#000000", 0.1);
            line_dark_color = Utils.hex_to_rgba("#ffffff", 0.05);
            line_light_color = Utils.hex_to_rgba("#000000", 0.05);

            set_size_request(width, height);

            edit_button_y = (height - button_edit_press_dark_surface.get_height()) / 2;

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
            clicked.connect((w, e) => {
                    if (e.x > edit_button_x && e.x < edit_button_x + button_edit_normal_dark_surface.get_width()
                        && e.y > edit_button_y && e.y < height - button_edit_normal_dark_surface.get_height()) {
                        click_edit_button();
                    } else {
                        // Avoid user double click on button to login button twice.
                        if (!has_click) {
                            has_click = true;
                            click_button();
                        }
                    }
                });
            motion_notify_event.connect((w, e) => {
                    if (e.x > edit_button_x && e.x < edit_button_x + button_edit_normal_dark_surface.get_width()
                        && e.y > edit_button_y && e.y < height - button_edit_normal_dark_surface.get_height()) {
                        is_at_edit_button_area = true;
                    } else {
                        is_at_edit_button_area = false;
                    }
                    queue_draw();

                    return false;
                });
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {

            bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();

            if (is_light_theme) {
                Draw.draw_surface(cr, button_light_surface, image_x, 0, 0, height);
            } else {
                Draw.draw_surface(cr, button_dark_surface, image_x, 0, 0, height);
            }


            if (is_hover) {
                if (is_at_edit_button_area) {
                    if (is_press) {
                        if (is_light_theme) {
                            Draw.draw_surface(cr, button_edit_press_light_surface, edit_button_x, 0, 0, height);
                        } else {
                            Draw.draw_surface(cr, button_edit_press_dark_surface, edit_button_x, 0, 0, height);
                        }
                    } else if (is_hover) {
                        if (is_light_theme) {
                            Draw.draw_surface(cr, button_edit_hover_light_surface, edit_button_x, 0, 0, height);
                        } else {
                            Draw.draw_surface(cr, button_edit_hover_dark_surface, edit_button_x, 0, 0, height);
                        }
                    }
                } else {
                    if (is_light_theme) {
                        Draw.draw_surface(cr, button_edit_normal_light_surface, edit_button_x, 0, 0, height);
                    } else {
                        Draw.draw_surface(cr, button_edit_normal_dark_surface, edit_button_x, 0, 0, height);
                    }

                }
            }

            if (is_light_theme) {
                Utils.set_context_color(cr, button_name_light_color);
            } else {
                Utils.set_context_color(cr, button_name_dark_color);
            }
            Draw.draw_text(cr, button_name, text_x, button_name_y, text_width, height, button_name_size, Pango.Alignment.LEFT, "top");

            if (is_light_theme) {
                Utils.set_context_color(cr, button_content_light_color);
            } else {
                Utils.set_context_color(cr, button_content_dark_color);
            }
            if (button_display_name != null) {
                Draw.draw_text(cr, button_display_name, text_x, button_content_y, text_width, height, button_content_size, Pango.Alignment.LEFT, "top");
            } else {
                Draw.draw_text(cr, button_content, text_x, button_content_y, text_width, height, button_content_size, Pango.Alignment.LEFT, "top");
            }

            if (display_bottom_line) {
                if (is_light_theme) {
                    Utils.set_context_color(cr, line_light_color);
                } else {
                    Utils.set_context_color(cr, line_dark_color);
                }
                Draw.draw_rectangle(cr, 8, height - 1, width - 16, 1);
            }

            if (is_press) {
                if (is_light_theme) {
                    Utils.set_context_color(cr, press_light_color);
                } else {
                    Utils.set_context_color(cr, press_dark_color);
                }
                Draw.draw_rectangle(cr, 0, 0, width, height);
            } else if (is_hover) {
                if (is_light_theme) {
                    Utils.set_context_color(cr, hover_light_color);
                } else {
                    Utils.set_context_color(cr, hover_dark_color);
                }
                Draw.draw_rectangle(cr, 0, 0, width, height);
            }

            return true;
        }
    }
}
