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
    public class Dialog : Gtk.Window {
        public Gtk.Box window_frame_box;
        public Gtk.Box window_widget_box;
        public Widgets.ConfigWindow transient_window;
        public int window_frame_margin_bottom = 60;
        public int window_frame_margin_end = 50;
        public int window_frame_margin_start = 50;
        public int window_frame_margin_top = 50;
        public int window_frame_radius = 5;
        public int window_init_height;
        public int window_init_width;
        
        public Dialog() {
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());

            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_modal(true);
            set_resizable(false);
            set_type_hint(Gdk.WindowTypeHint.DIALOG);  // DIALOG hint will give right window effect
            
            set_decorated(false);
            
            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_widget_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            add(window_frame_box);
            window_frame_box.pack_start(window_widget_box, true, true, 0);
            
            focus_in_event.connect((w) => {
                    shadow_active();
                    
                    return false;
                });
            
            focus_out_event.connect((w) => {
                    shadow_inactive();
                    
                    return false;
                });

            configure_event.connect((w) => {
                    int width, height;
                    get_size(out width, out height);
                    
                    Cairo.RectangleInt rect;
                    get_window().get_frame_extents(out rect);
                    
                    rect.x = window_frame_margin_start;
                    rect.y = window_frame_margin_top;
                    rect.width = width - window_frame_margin_start - window_frame_margin_end;
                    rect.height = height - window_frame_margin_top - window_frame_margin_bottom;
                    
                    var shape = new Cairo.Region.rectangle(rect);
                    get_window().input_shape_combine_region(shape, 0, 0);
                    
                    queue_draw();
					
                    return false;
                });

            window_state_event.connect((w, e) => {
                    get_window().set_shadow_width(window_frame_margin_start, window_frame_margin_end, window_frame_margin_top, window_frame_margin_bottom);
                                
                    window_frame_box.margin_top = window_frame_margin_top;
                    window_frame_box.margin_bottom = window_frame_margin_bottom;
                    window_frame_box.margin_start = window_frame_margin_start;
                    window_frame_box.margin_end = window_frame_margin_end;
            
                    window_widget_box.margin = 0;
                    
                    return false;
                });
            
            
            key_press_event.connect((w, e) => {
                    string keyname = Keymap.get_keyevent_name(e);
                    if (keyname == "Esc") {
                        this.destroy();
                    }
                    
                    return false;
                });
            
            draw.connect_after((w, cr) => {
                    draw_window_below(cr);
                       
                    draw_window_widgets(cr);

                    draw_window_frame(cr);
                       
                    draw_window_above(cr);
                    
                    return true;
                });
        }
        
        public void transient_for_window(Widgets.ConfigWindow window) {
            transient_window = window;
            
            set_transient_for(window);
            show_all();
        }
        
        public void shadow_active() {
            window_frame_box.get_style_context().remove_class("dialog_shadow_inactive");
            window_frame_box.get_style_context().add_class("dialog_shadow_active");
        }
        
        public void shadow_inactive() {
            window_frame_box.get_style_context().remove_class("dialog_shadow_active");
            window_frame_box.get_style_context().add_class("dialog_shadow_inactive");
        }
        
        public void draw_window_widgets(Cairo.Context cr) {
            Utils.propagate_draw(this, cr);
        }
        
        public void add_widget(Gtk.Widget widget) {
            window_widget_box.pack_start(widget, true, true, 0);
        }
        
        public void draw_window_below(Cairo.Context cr) {
             Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_start, window_frame_margin_top, window_rect.width, window_rect.height, window_frame_radius);
        }
        
        public void draw_window_frame(Cairo.Context cr) {
            
        }
        
        public virtual void draw_window_above(Cairo.Context cr) {
            
        }
    }
}