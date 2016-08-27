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
using Gee;

namespace Widgets {
    public class ThemeButton : Gtk.EventBox {
        public string theme_name;
        public int button_radius = 4;
        public KeyFile theme_file;
        public Gdk.RGBA background_color;
        public Gdk.RGBA foreground_color;
        public Gdk.RGBA content_color;
        public Gdk.RGBA frame_dark_color;
        public Gdk.RGBA frame_light_color;
        public Gdk.RGBA active_color;
        public int title_padding_x = 10;
        public int title_padding_y = 15;
        public int title_font_size = 11;
        public int content_padding_x = 10;
        public int content_padding_y = 34;
        public int content_font_size = 11;
        public bool is_active = false;
        
        public ThemeButton(string name) {
            theme_name = name;
            
            try {
                theme_file = new KeyFile();
                theme_file.load_from_file(Utils.get_theme_path(theme_name), KeyFileFlags.NONE);
                background_color = Utils.hex_to_rgba(theme_file.get_string("theme", "background").strip());
                background_color.alpha = 0.8;
                foreground_color = Utils.hex_to_rgba(theme_file.get_string("theme", "foreground").strip());
                content_color = Utils.hex_to_rgba(theme_file.get_string("theme", "color_2").strip());
                frame_dark_color = Utils.hex_to_rgba("#ffffff");
                frame_dark_color.alpha = 0.1;
                frame_light_color = Utils.hex_to_rgba("#000000");
                frame_light_color.alpha = 0.1;
                active_color = Utils.hex_to_rgba("#2ca7f8");
            } catch (Error e) {
                print("ThemeButton: %s\n", e.message);
            }
            
            visible_window = false;

            set_size_request(Constant.THEME_BUTTON_WIDTH, Constant.THEME_BUTTON_HEIGHT);
            margin_start = (Constant.SLIDER_WIDTH - Constant.THEME_BUTTON_WIDTH) / 2;
            margin_end = (Constant.SLIDER_WIDTH - Constant.THEME_BUTTON_WIDTH) / 2;
            
            draw.connect(on_draw);
        }
        
        public void active() {
            is_active = true;
            
            queue_draw();
        }
        
        public void inactive() {
            is_active = false;
            
            queue_draw();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
            
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, background_color.alpha);
            Draw.draw_rounded_rectangle(cr, 0, 0, rect.width, rect.height, button_radius);

            cr.set_source_rgba(foreground_color.red, foreground_color.green, foreground_color.blue, foreground_color.alpha);
            Draw.draw_text(cr, "deepin@linux > _", title_padding_x, title_padding_y, rect.width, rect.height, title_font_size, Pango.Alignment.LEFT, "top");

            cr.set_source_rgba(content_color.red, content_color.green, content_color.blue, content_color.alpha);
            Draw.draw_text(cr, "hello world!", content_padding_x, content_padding_y, rect.width, rect.height, content_font_size, Pango.Alignment.LEFT, "top");
            
            if (is_light_theme) {
                cr.set_source_rgba(frame_light_color.red, frame_light_color.green, frame_light_color.blue, frame_light_color.alpha);
            } else {
                cr.set_source_rgba(frame_dark_color.red, frame_dark_color.green, frame_dark_color.blue, frame_dark_color.alpha);
            }
            Draw.draw_rounded_rectangle(cr, 0, 0, rect.width, rect.height, button_radius, false);
            
            cr.set_line_width(2);
            if (is_active) {
                cr.set_source_rgba(active_color.red, active_color.green, active_color.blue, active_color.alpha);
            }
            Draw.draw_rounded_rectangle(cr, 0, 0, rect.width, rect.height, button_radius, false);
            
            return true;
        }
    }

    public class ThemeList : Gtk.VBox {
        public int theme_button_padding = Constant.THEME_BUTTON_PADDING;
        public HashMap<string, ThemeButton> theme_button_map;
        public ThemeButton? active_theme_button = null;
        
        public signal void active_theme(string theme_name);
        
        public ThemeList(string default_theme) {
            theme_button_map = new HashMap<string, ThemeButton>();
            
            foreach (string theme_name in Utils.list_files(Utils.get_theme_dir())) {
                var button = new Widgets.ThemeButton(theme_name);
                pack_start(button, false, false, theme_button_padding);
                
                button.button_press_event.connect((w, e) => {
                        active_button(theme_name);
                        active_theme(theme_name);
                        
                        return false;
                    });
                
                theme_button_map.set(theme_name, button);
            }

            active_button(default_theme);
        }
        
        public void active_button(string theme_name) {
            if (active_theme_button != null) {
                active_theme_button.inactive();
            }
            
            if (theme_button_map.has_key(theme_name)) {
                active_theme_button = theme_button_map.get(theme_name);
            } else {
                active_theme_button = theme_button_map.get("deepin");
            }
            active_theme_button.active();
        }
    }
}