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
    public class PreferenceSlidebar : Gtk.Grid {
        public int width = 160;
		public int height = 30;
        
        public int segement_spacing = 20;
		
		public signal void click_item(string name);
        
        public PreferenceSlideItem focus_segement_item;
		
        public PreferenceSlidebar() {
			set_size_request(width, -1);
			
            var spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            spacing_box.set_size_request(-1, Constant.TITLEBAR_HEIGHT);
            this.attach(spacing_box, 0, 0, width, height);
            
            var basic_segement = new PreferenceSlideItem(this, "Basic", "basic", true);
			this.attach_next_to(basic_segement, spacing_box, Gtk.PositionType.BOTTOM, width, height);
            
            var theme_segement = new PreferenceSlideItem(this, "Theme", "theme", false);
			this.attach_next_to(theme_segement, basic_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var theme_spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            theme_spacing_box.set_size_request(-1, segement_spacing);
            this.attach_next_to(theme_spacing_box, theme_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var hotkey_segement = new PreferenceSlideItem(this, "Hotkey", "hotkey", true);
			this.attach_next_to(hotkey_segement, theme_spacing_box, Gtk.PositionType.BOTTOM, width, height);

            var terminal_key_segement = new PreferenceSlideItem(this, "Terminal", "temrinal_key", false);
			this.attach_next_to(terminal_key_segement, hotkey_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var workspace_key_segement = new PreferenceSlideItem(this, "Workspace", "workspace_key", false);
			this.attach_next_to(workspace_key_segement, terminal_key_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var advanced_key_segement = new PreferenceSlideItem(this, "Advanced", "advanced_key", false);
			this.attach_next_to(advanced_key_segement, workspace_key_segement, Gtk.PositionType.BOTTOM, width, height);

            var advanced_key_spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            advanced_key_spacing_box.set_size_request(-1, segement_spacing);
            this.attach_next_to(advanced_key_spacing_box, advanced_key_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var advanced_segement = new PreferenceSlideItem(this, "Advanced", "advanced", true);
			this.attach_next_to(advanced_segement, advanced_key_spacing_box, Gtk.PositionType.BOTTOM, width, height);
            
            var cursor_segement = new PreferenceSlideItem(this, "Cursor", "cursor", false);
			this.attach_next_to(cursor_segement, advanced_segement, Gtk.PositionType.BOTTOM, width, height);

            var scroll_segement = new PreferenceSlideItem(this, "Scroll", "scroll", false);
			this.attach_next_to(scroll_segement, cursor_segement, Gtk.PositionType.BOTTOM, width, height);

            var window_segement = new PreferenceSlideItem(this, "Window", "window", false);
			this.attach_next_to(window_segement, cursor_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var window_spacing_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_spacing_box.set_size_request(-1, segement_spacing);
            this.attach_next_to(window_spacing_box, window_segement, Gtk.PositionType.BOTTOM, width, height);
            
            var about_segement = new PreferenceSlideItem(this, "About", "about", true);
			this.attach_next_to(about_segement, window_spacing_box, Gtk.PositionType.BOTTOM, width, height);
            
            add_focus_handler(basic_segement);
            add_focus_handler(theme_segement);
            add_focus_handler(hotkey_segement);
            add_focus_handler(terminal_key_segement);
            add_focus_handler(workspace_key_segement);
            add_focus_handler(advanced_key_segement);
            add_focus_handler(advanced_segement);
            add_focus_handler(cursor_segement);
            add_focus_handler(scroll_segement);
            add_focus_handler(window_segement);
            add_focus_handler(about_segement);
            focus_item(basic_segement);
            
            draw.connect(on_draw);
            
            show_all();
        }
        
        public void focus_item(PreferenceSlideItem item) {
            if (focus_segement_item != null) {
                focus_segement_item.is_selected = false;
                focus_segement_item.queue_draw();
            }
            
            focus_segement_item = item;
            focus_segement_item.is_selected = true;
            queue_draw();
        }
        
        public void add_focus_handler(PreferenceSlideItem item) {
            item.button_press_event.connect((w, e) => {
                    focus_item(item);
                    
                    return false;
                });
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            cr.set_source_rgba(0, 0, 0, 0.1);
            Draw.draw_rectangle(cr, alloc.width - 1, 0, 1, alloc.height);
            
            return false;
        }
    }

    public class PreferenceSlideItem : Gtk.EventBox {
        public string item_name;
        public bool item_active;
        public bool is_first_segement;
        
        public int first_segement_margin = 30;
        public int second_segement_margin = 40;
        
        public int first_segement_size = 12;
        public int second_segement_size = 10;
        
        public Gdk.RGBA first_segement_text_color;
        public Gdk.RGBA second_segement_text_color;
        public Gdk.RGBA highlight_text_color;
        
        public bool is_selected = false;
        
        public int width = 160;
        public int height = 30;
        
        public PreferenceSlideItem(PreferenceSlidebar bar, string display_name, string name, bool is_first) {
			set_visible_window(false);
            
            item_name = display_name;
            is_first_segement = is_first;
            
            first_segement_text_color = Gdk.RGBA();
            first_segement_text_color.parse("#00162C");

            second_segement_text_color = Gdk.RGBA();
            second_segement_text_color.parse("#303030");
            
            highlight_text_color = Gdk.RGBA();
            highlight_text_color.parse("#2ca7f8");
            
            set_size_request(width, height);
			
			button_press_event.connect((w, e) => {
					bar.click_item(name);
					
					return false;
				});
            
            draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rectangle(cr, 0, 0, rect.width - 1, rect.height, true);
            
            if (is_selected) {
                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 0.20);
                Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);
                
                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 0.10);
                Draw.draw_rectangle(cr, 0, 0, rect.width, 1, true);

                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 0.10);
                Draw.draw_rectangle(cr, 0, rect.height - 1, rect.width, 1, true);
                
                cr.set_source_rgba(43 / 255.0, 167 / 255.0, 248 / 255.0, 1);
                Draw.draw_rectangle(cr, rect.width - 3, 0, 3, rect.height, true);
            }
            
            if (is_first_segement) {
                if (is_selected) {
                    Utils.set_context_color(cr, highlight_text_color);
                } else {
                    Utils.set_context_color(cr, first_segement_text_color);
                }
                Draw.draw_text(cr, item_name, first_segement_margin, 0, rect.width - first_segement_margin, rect.height, first_segement_size);
            } else {
                if (is_selected) {
                    Utils.set_context_color(cr, highlight_text_color);
                } else {
                    Utils.set_context_color(cr, second_segement_text_color);
                }
                Draw.draw_text(cr, item_name, second_segement_margin, 0, rect.width - second_segement_margin, rect.height, second_segement_size);
            }
            
            return true;
        }
    }
}