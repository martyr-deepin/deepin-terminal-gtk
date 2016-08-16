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

using Cairo;
using Draw;
using Gtk;
using Utils;

namespace Widgets {
    public class ImageButton : Gtk.EventBox {
        public Cairo.ImageSurface normal_surface;
        public Cairo.ImageSurface hover_surface;
        public Cairo.ImageSurface press_surface;
        
        public Gdk.RGBA text_normal_color;
        public Gdk.RGBA text_hover_color;
        public Gdk.RGBA text_press_color;
        
        public string? button_text;
        public int button_text_size = 14;
		
		public bool is_hover = false;
		public bool is_press = false;
        
		public signal void click();
        
        public ImageButton(string image_path, string? text=null, int text_size=12) {
			normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_normal.png"));
            hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_hover.png"));
            press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_press.png"));
            
            button_text = text;
            button_text_size = text_size;
            
            if (button_text != null) {
                text_normal_color = Gdk.RGBA();
                text_normal_color.parse("#0699FF");
                
                text_hover_color = Gdk.RGBA();
                text_hover_color.parse("#FFFFFF");

                text_press_color = Gdk.RGBA();
                text_press_color.parse("#FFFFFF");
            }
            
            set_size_request(this.normal_surface.get_width(), this.normal_surface.get_height());
            
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
                    if (is_press) {
                        click();
                    }
                    
					is_press = false;
					queue_draw();
					
					return false;
				});
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            if (is_hover) {
                if (is_press) {
                    Draw.draw_surface(cr, press_surface);
                    if (button_text != null) {
                        Utils.set_context_color(cr, text_press_color);
                        Draw.draw_text(widget, cr, button_text, 0, 10, normal_surface.get_width(), button_text_size, button_text_size, Pango.Alignment.CENTER);
                    }
                } else {
                    Draw.draw_surface(cr, hover_surface);
                    if (button_text != null) {
                        Utils.set_context_color(cr, text_hover_color);
                        Draw.draw_text(widget, cr, button_text, 0, 10, normal_surface.get_width(), button_text_size, button_text_size, Pango.Alignment.CENTER);
                    }
                }
            } else {
                Draw.draw_surface(cr, normal_surface);                
                if (button_text != null) {
                    Utils.set_context_color(cr, text_normal_color);
                    Draw.draw_text(widget, cr, button_text, 0, 10, normal_surface.get_width(), button_text_size, button_text_size, Pango.Alignment.CENTER);
                }
            }
            
            return true;
        }
    }
}