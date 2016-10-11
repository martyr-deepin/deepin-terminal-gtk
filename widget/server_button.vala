/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2016 Deepin, Inc.
 *               2011 ~ 2016 Wang Yong
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
    public class ServerButton : Gtk.EventBox {
        public bool is_at_edit_button_area = false;
		public bool is_hover = false;
		public bool is_press = false;
        public Cairo.ImageSurface server_dark_surface;
        public Cairo.ImageSurface server_edit_hover_dark_surface;
        public Cairo.ImageSurface server_edit_hover_light_surface;
        public Cairo.ImageSurface server_edit_normal_dark_surface;
        public Cairo.ImageSurface server_edit_normal_light_surface;
        public Cairo.ImageSurface server_edit_press_dark_surface;
        public Cairo.ImageSurface server_edit_press_light_surface;
        public Cairo.ImageSurface server_light_surface;
        public Gdk.RGBA content_dark_color;
        public Gdk.RGBA content_light_color;
        public Gdk.RGBA hover_dark_color;
        public Gdk.RGBA hover_light_color;
        public Gdk.RGBA line_dark_color;
        public Gdk.RGBA line_light_color;
        public Gdk.RGBA press_dark_color;
        public Gdk.RGBA press_light_color;
        public Gdk.RGBA title_dark_color;
        public Gdk.RGBA title_light_color;
        public bool display_bottom_line = true;
        public bool has_login = false;
        public int content_size = 10;
        public int content_y = 27;
        public int edit_button_x = 254;
        public int edit_button_y;
        public int height = 56;
        public int image_x = 12;
        public int text_width = 136;
        public int text_x = 72;
        public int title_size = 11;
        public int title_y = 5;
        public int width = Constant.SLIDER_WIDTH;
        public string content;
        public string title;
        
        public signal void edit_server(string server_info);
        public signal void login_server(string server_info);
        
        public ServerButton(string server_title, string server_content) {
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                            | Gdk.EventMask.BUTTON_RELEASE_MASK
                            | Gdk.EventMask.POINTER_MOTION_MASK
                            | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            title = server_title;
            content = server_content;
            
			server_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_dark.png"));
			server_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_light.png"));
			server_edit_normal_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_dark_normal.png"));
			server_edit_hover_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_dark_hover.png"));
			server_edit_press_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_dark_press.png"));
			server_edit_normal_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_light_normal.png"));
			server_edit_hover_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_light_hover.png"));
			server_edit_press_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_light_press.png"));
            
            title_dark_color = Utils.hex_to_rgba("#FFFFFF");
            content_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.5);
            press_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.1);
            hover_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.1);
            title_light_color = Utils.hex_to_rgba("#303030");
            content_light_color = Utils.hex_to_rgba("#000000", 0.5);
            press_light_color = Utils.hex_to_rgba("#000000", 0.1);
            hover_light_color = Utils.hex_to_rgba("#000000", 0.1);
            line_dark_color = Utils.hex_to_rgba("#ffffff", 0.05);
            line_light_color = Utils.hex_to_rgba("#000000", 0.05);
            
            set_size_request(width, height);
            
            edit_button_y = (height - server_edit_press_dark_surface.get_height()) / 2;
            
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
					is_press = true;
					queue_draw();
					
					return false;
				});
			button_release_event.connect((w, e) => {
                    if (is_press && Utils.pointer_in_widget_area(this)) {
                        if (e.x > edit_button_x && e.x < edit_button_x + server_edit_normal_dark_surface.get_width()
                            && e.y > edit_button_y && e.y < height - server_edit_normal_dark_surface.get_height()) {
                            edit_server(server_content);
                        } else {
                            // Avoid user double click on button to login server twice.
                            if (!has_login) {
                                has_login = true;
                                login_server(server_content);
                            }
                        }
                    }
					
					is_hover = false;
					is_press = false;
					queue_draw();
                    
					return false;
				});
            motion_notify_event.connect((w, e) => {
                    if (e.x > edit_button_x && e.x < edit_button_x + server_edit_normal_dark_surface.get_width()
                        && e.y > edit_button_y && e.y < height - server_edit_normal_dark_surface.get_height()) {
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
                Draw.draw_surface(cr, server_light_surface, image_x, 0, 0, height);
            } else {
                Draw.draw_surface(cr, server_dark_surface, image_x, 0, 0, height);
            }
            
            
            if (is_hover) {
                if (is_at_edit_button_area) {
                    if (is_press) {
                        if (is_light_theme) {
                            Draw.draw_surface(cr, server_edit_press_light_surface, edit_button_x, 0, 0, height);
                        } else {
                            Draw.draw_surface(cr, server_edit_press_dark_surface, edit_button_x, 0, 0, height);
                        }
                    } else if (is_hover) {
                        if (is_light_theme) {
                            Draw.draw_surface(cr, server_edit_hover_light_surface, edit_button_x, 0, 0, height);
                        } else {
                            Draw.draw_surface(cr, server_edit_hover_dark_surface, edit_button_x, 0, 0, height);
                        }
                    }
                } else {
                    if (is_light_theme) {
                        Draw.draw_surface(cr, server_edit_normal_light_surface, edit_button_x, 0, 0, height);
                    } else {
                        Draw.draw_surface(cr, server_edit_normal_dark_surface, edit_button_x, 0, 0, height);
                    }
                    
                }
            }
            
            if (is_light_theme) {
                Utils.set_context_color(cr, title_light_color);
            } else {
                Utils.set_context_color(cr, title_dark_color);
            }
            Draw.draw_text(cr, title, text_x, title_y, text_width, height, title_size, Pango.Alignment.LEFT, "top");

            if (is_light_theme) {
                Utils.set_context_color(cr, content_light_color);
            } else {
                Utils.set_context_color(cr, content_dark_color);
            }
            Draw.draw_text(cr, content, text_x, content_y, text_width, height, content_size, Pango.Alignment.LEFT, "top");
            
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