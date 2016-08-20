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
	public class ProgressBar : Gtk.EventBox {
        public int width = 200;
		public int height = 22;
        public int line_height = 2;
        public int line_margin_top = 10;
        public int draw_pointer_offset = 3;
		public double percent;
		
        public Gdk.RGBA foreground_color;
        public Gdk.RGBA background_color;
        
        public Cairo.ImageSurface pointer_surface;
        
		public signal void update(double percent);
		
		public ProgressBar(double init_percent) {
			percent = init_percent;
			set_size_request(width, height);
            
            foreground_color = Gdk.RGBA();
            foreground_color.parse("#2ca7f8");
            background_color = Gdk.RGBA();
            background_color.parse("#A4A4A4");
            pointer_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("progress_pointer.png"));
			
			set_visible_window(false);
			
			button_press_event.connect((w, e) => {
					Gtk.Allocation rect;
					w.get_allocation(out rect);
					
					set_percent(e.x * 1.0 / rect.width);
                    
                    return false;
				});
            motion_notify_event.connect((w, e) => {
					Gtk.Allocation rect;
					w.get_allocation(out rect);
					
					set_percent(e.x * 1.0 / rect.width);
					
					return false;
                });
            
			draw.connect(on_draw);
			
			show_all();
		}
		
		public void set_percent(double new_percent) {
            percent = double.max(Constant.TERMINAL_MIN_OPACITY, double.min(new_percent, 1.0));
            
			update(percent);
			
			queue_draw();
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            Utils.set_context_color(cr, background_color);
			Draw.draw_rectangle(cr, 0, line_margin_top, rect.width, line_height);
			
			cr.set_source_rgba(1, 0, 1, 1);
            Utils.set_context_color(cr, foreground_color);
			Draw.draw_rectangle(cr, 0, line_margin_top, (int) (rect.width * percent), line_height);
            
            Draw.draw_surface(cr,
                              pointer_surface,
                              int.max(0, int.min((int) (rect.width * percent) - pointer_surface.get_width() / 2, rect.width - pointer_surface.get_width() + draw_pointer_offset)),
                              0);
            
            return true;
        }
	}
}
