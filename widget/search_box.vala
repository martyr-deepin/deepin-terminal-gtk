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
    public class SearchBox : Gtk.Box {
        public Widgets.ImageButton search_image;
        public Entry search_entry;
        public Gtk.Box clear_button_box;
        public ImageButton clear_button;
        public ImageButton search_next_button;
        public ImageButton search_previous_button;
        
        public SearchBox(Widgets.ConfigWindow config_window) {
            search_image = new ImageButton("search", true);
            search_entry = new Entry();
            clear_button_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            clear_button = new ImageButton("search_clear", true);
            search_next_button = new ImageButton("search_next", true);
            search_previous_button = new ImageButton("search_previous", true);
            
            pack_start(search_image, false, false, 0);
            pack_start(search_entry, true, true, 0);
            pack_start(clear_button_box, false, false, 0);
            pack_start(search_previous_button, false, false, 0);
            pack_start(search_next_button, false, false, 0);
            
            search_image.margin_start = 10;
            search_image.set_valign(Gtk.Align.CENTER);
            search_entry.margin_end = 4;
            search_next_button.margin_top = 6;
            search_next_button.margin_end = 6;
            clear_button_box.margin_top = 12;
            clear_button_box.margin_end = 10;
            search_previous_button.margin_top = 6;
            search_previous_button.margin_end = 10;
            
            set_size_request(322, Constant.TITLEBAR_HEIGHT);
            set_valign(Gtk.Align.START);
            set_halign(Gtk.Align.END);
            
            adjust_css_with_theme(config_window);
            realize.connect((w) => {
                    ((Widgets.ConfigWindow) this.get_toplevel()).config.update.connect((w) => {
                            adjust_css_with_theme(config_window);
                        });
                });
        }
        
        public void adjust_css_with_theme(Widgets.ConfigWindow config_window) {
            bool is_light_theme = false;
            try {
                is_light_theme = config_window.config.config_file.get_string("theme", "style") == "light";
            } catch (Error e) {
                print("SearchBox adjust_css_with_theme: %s\n", e.message);
            }
                         
            get_style_context().remove_class("search_light_box");
            get_style_context().remove_class("search_dark_box");
            search_entry.get_style_context().remove_class("search_dark_entry");
            search_entry.get_style_context().remove_class("search_light_entry");
                    
            if (is_light_theme) {
                search_entry.get_style_context().add_class("search_light_entry");
                get_style_context().add_class("search_light_box");
            } else {
                search_entry.get_style_context().add_class("search_dark_entry");
                get_style_context().add_class("search_dark_box");
            }
        }
        
        public void show_clear_button() {
            if (clear_button_box.get_children().length() == 0) {
                clear_button_box.add(clear_button);
                show_all();
            }
        }
        
        public void hide_clear_button() {
            Utils.remove_all_children(clear_button_box);
        }
    }
}