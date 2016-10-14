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
    public class CommandButton : Widgets.ClickEventBox {
        public bool is_at_edit_button_area = false;
		public bool is_hover = false;
        public Cairo.ImageSurface command_dark_surface;
        public Cairo.ImageSurface command_edit_hover_dark_surface;
        public Cairo.ImageSurface command_edit_hover_light_surface;
        public Cairo.ImageSurface command_edit_normal_dark_surface;
        public Cairo.ImageSurface command_edit_normal_light_surface;
        public Cairo.ImageSurface command_edit_press_dark_surface;
        public Cairo.ImageSurface command_edit_press_light_surface;
        public Cairo.ImageSurface command_light_surface;
        public Gdk.RGBA command_shortcut_dark_color;
        public Gdk.RGBA command_shortcut_light_color;
        public Gdk.RGBA hover_dark_color;
        public Gdk.RGBA hover_light_color;
        public Gdk.RGBA line_dark_color;
        public Gdk.RGBA line_light_color;
        public Gdk.RGBA press_dark_color;
        public Gdk.RGBA press_light_color;
        public Gdk.RGBA command_name_dark_color;
        public Gdk.RGBA command_name_light_color;
        public bool display_bottom_line = true;
        public bool has_login = false;
        public int command_shortcut_size = 10;
        public int command_shortcut_y = 27;
        public int edit_button_x = 254;
        public int edit_button_y;
        public int height = 56;
        public int image_x = 12;
        public int text_width = 136;
        public int text_x = 72;
        public int command_name_size = 11;
        public int command_name_y = 5;
        public int width = Constant.SLIDER_WIDTH;
        public string command_shortcut;
        public string command_name;
        public string command_value;
        
        public signal void edit_command(string command_name);
        public signal void execute_command(string command_value);
        
        public CommandButton(string name, string value, string shortcut) {
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                            | Gdk.EventMask.BUTTON_RELEASE_MASK
                            | Gdk.EventMask.POINTER_MOTION_MASK
                            | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            command_name = name;
            command_value = value;
            command_shortcut = shortcut;
            
			command_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("command_dark.png"));
			command_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("command_light.png"));
			command_edit_normal_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("button_edit_dark_normal.png"));
			command_edit_hover_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("button_edit_dark_hover.png"));
			command_edit_press_dark_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("button_edit_dark_press.png"));
			command_edit_normal_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("button_edit_light_normal.png"));
			command_edit_hover_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("button_edit_light_hover.png"));
			command_edit_press_light_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("button_edit_light_press.png"));
            
            command_name_dark_color = Utils.hex_to_rgba("#FFFFFF");
            command_shortcut_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.5);
            press_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.1);
            hover_dark_color = Utils.hex_to_rgba("#FFFFFF", 0.1);
            command_name_light_color = Utils.hex_to_rgba("#303030");
            command_shortcut_light_color = Utils.hex_to_rgba("#000000", 0.5);
            press_light_color = Utils.hex_to_rgba("#000000", 0.1);
            hover_light_color = Utils.hex_to_rgba("#000000", 0.1);
            line_dark_color = Utils.hex_to_rgba("#ffffff", 0.05);
            line_light_color = Utils.hex_to_rgba("#000000", 0.05);
            
            set_size_request(width, height);
            
            edit_button_y = (height - command_edit_press_dark_surface.get_height()) / 2;
            
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
                    if (e.x > edit_button_x && e.x < edit_button_x + command_edit_normal_dark_surface.get_width()
                        && e.y > edit_button_y && e.y < height - command_edit_normal_dark_surface.get_height()) {
                        edit_command(command_name);
                    } else {
                        // Avoid user double click on button to login command twice.
                        if (!has_login) {
                            has_login = true;
                            execute_command(command_value);
                        }
                    }
                });
            motion_notify_event.connect((w, e) => {
                    if (e.x > edit_button_x && e.x < edit_button_x + command_edit_normal_dark_surface.get_width()
                        && e.y > edit_button_y && e.y < height - command_edit_normal_dark_surface.get_height()) {
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
                Draw.draw_surface(cr, command_light_surface, image_x, 0, 0, height);
            } else {
                Draw.draw_surface(cr, command_dark_surface, image_x, 0, 0, height);
            }
            
            
            if (is_hover) {
                if (is_at_edit_button_area) {
                    if (is_press) {
                        if (is_light_theme) {
                            Draw.draw_surface(cr, command_edit_press_light_surface, edit_button_x, 0, 0, height);
                        } else {
                            Draw.draw_surface(cr, command_edit_press_dark_surface, edit_button_x, 0, 0, height);
                        }
                    } else if (is_hover) {
                        if (is_light_theme) {
                            Draw.draw_surface(cr, command_edit_hover_light_surface, edit_button_x, 0, 0, height);
                        } else {
                            Draw.draw_surface(cr, command_edit_hover_dark_surface, edit_button_x, 0, 0, height);
                        }
                    }
                } else {
                    if (is_light_theme) {
                        Draw.draw_surface(cr, command_edit_normal_light_surface, edit_button_x, 0, 0, height);
                    } else {
                        Draw.draw_surface(cr, command_edit_normal_dark_surface, edit_button_x, 0, 0, height);
                    }
                    
                }
            }
            
            if (is_light_theme) {
                Utils.set_context_color(cr, command_name_light_color);
            } else {
                Utils.set_context_color(cr, command_name_dark_color);
            }
            Draw.draw_text(cr, command_name, text_x, command_name_y, text_width, height, command_name_size, Pango.Alignment.LEFT, "top");

            if (is_light_theme) {
                Utils.set_context_color(cr, command_shortcut_light_color);
            } else {
                Utils.set_context_color(cr, command_shortcut_dark_color);
            }
            Draw.draw_text(cr, command_shortcut, text_x, command_shortcut_y, text_width, height, command_shortcut_size, Pango.Alignment.LEFT, "top");
            
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