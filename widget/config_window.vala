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
    public class ConfigWindow : Gtk.Window {
        public Config.Config config;
    
        public Gtk.Box window_frame_box;
        public Gtk.Box window_widget_box;
            
        public int active_tab_underline_x;
		public int active_tab_underline_width;
		
        private bool is_show_shortcut_viewer = false;
            
        public ConfigWindow() {
            load_config();
        }
            
        public void load_config() {
            config = new Config.Config();
            config.update.connect((w) => {
                    update_terminal(this);
                        
                    queue_draw();
                });
        }
            
        public void update_terminal(Gtk.Container container) {
            container.forall((child) => {
                    var child_type = child.get_type();
                        
                    if (child_type.is_a(typeof(Widgets.Term))) {
                        ((Widgets.Term) child).setup_from_config();
                    } else if (child_type.is_a(typeof(Gtk.Container))) {
                        update_terminal((Gtk.Container) child);
                    }
                });
        }
        
        public void show_shortcut_viewer(int x, int y) {
            remove_shortcut_viewer();
            
            if (!is_show_shortcut_viewer) {
                string data = get_shortcut_data();
                
                try {
                    GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline(
                        "deepin-shortcut-viewer -j='%s' -p=%i,%i".printf(data, x, y),
                        null,
                        GLib.AppInfoCreateFlags.NONE);
                    
                    appinfo.launch(null, null);
                    is_show_shortcut_viewer = true;
                } catch (Error e) {
                    print("ConfigWindow show_shortcut_viewer: %s\n", e.message);
                }
            }
        }
        
        public void remove_shortcut_viewer() {
            if (is_show_shortcut_viewer) {
                try {
                    GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline(
                        "deepin-shortcut-viewer -j=''",
                        null,
                        GLib.AppInfoCreateFlags.NONE);
                    appinfo.launch(null, null);
                } catch (Error e) {
                    print("Main on_key_press: %s\n", e.message);
                }
                    
                is_show_shortcut_viewer = false;
            }
        }
    	
        public string get_shortcut_data() {
            // Build a object:
            Json.Builder builder = new Json.Builder();
            
            try {
    
                builder.begin_object ();
                builder.set_member_name("shortcut");
                    
                builder.begin_array();
    
                // Terminal shortcuts.
                builder.begin_object ();
                builder.set_member_name("groupItems");
            
                builder.begin_array();
    
                insert_shortcut_key(builder, "Copy clipboard", config.config_file.get_string("keybind", "copy_clipboard"));;
                insert_shortcut_key(builder, "Paste clipboard", config.config_file.get_string("keybind", "paste_clipboard"));;
                insert_shortcut_key(builder, "Search", config.config_file.get_string("keybind", "search"));;
                insert_shortcut_key(builder, "Zoom in", config.config_file.get_string("keybind", "zoom_in"));;
                insert_shortcut_key(builder, "Zoom out", config.config_file.get_string("keybind", "zoom_out"));;
                insert_shortcut_key(builder, "Default size", config.config_file.get_string("keybind", "revert_default_size"));;
                insert_shortcut_key(builder, "Select all", config.config_file.get_string("keybind", "select_all"));;
                    
                builder.end_array();
                    
                builder.set_member_name("groupName");
                builder.add_string_value("Terminal");
                builder.end_object();
            
                // Workspace shortcuts.
                    
                builder.begin_object ();
                builder.set_member_name("groupItems");
            
                builder.begin_array();
    
                insert_shortcut_key(builder, "New workspace", config.config_file.get_string("keybind", "new_workspace"));;
                insert_shortcut_key(builder, "Close workspace", config.config_file.get_string("keybind", "close_workspace"));;
                insert_shortcut_key(builder, "Next workspace", config.config_file.get_string("keybind", "next_workspace"));;
                insert_shortcut_key(builder, "Previous workspace", config.config_file.get_string("keybind", "previous_workspace"));;
                insert_shortcut_key(builder, "Select workspace", "Ctrl + 1 ~ Ctrl + 9");;
                insert_shortcut_key(builder, "Split vertically", config.config_file.get_string("keybind", "split_vertically"));;
                insert_shortcut_key(builder, "Split horizontally", config.config_file.get_string("keybind", "split_horizontally"));;
                insert_shortcut_key(builder, "Select up down", config.config_file.get_string("keybind", "select_up_window"));;
                insert_shortcut_key(builder, "Select down down", config.config_file.get_string("keybind", "select_down_window"));;
                insert_shortcut_key(builder, "Select left down", config.config_file.get_string("keybind", "select_left_window"));;
                insert_shortcut_key(builder, "Select right down", config.config_file.get_string("keybind", "select_right_window"));;
                insert_shortcut_key(builder, "Close window", config.config_file.get_string("keybind", "close_window"));;
                insert_shortcut_key(builder, "Close other window", config.config_file.get_string("keybind", "close_other_windows"));;
                    
                builder.end_array();
                    
                builder.set_member_name("groupName");
                builder.add_string_value("Workspace");
                builder.end_object();
            
                // Advanced shortcuts.
                builder.begin_object ();
                builder.set_member_name("groupItems");
            
                builder.begin_array();
    
                insert_shortcut_key(builder, "Toggle fullscreen", config.config_file.get_string("keybind", "toggle_fullscreen"));;
                insert_shortcut_key(builder, "Show helper window", config.config_file.get_string("keybind", "show_helper_window"));;
                insert_shortcut_key(builder, "Show remote panel", config.config_file.get_string("keybind", "show_remote_panel"));;
            
                builder.end_array();
                    
                builder.set_member_name("groupName");
                builder.add_string_value("Advanced");
                builder.end_object();
            
                    
                builder.end_array();
    
                builder.end_object();
            } catch (Error e) {
                print("Main get_shortcut_data: %s\n", e.message);
            }
    
            // Generate a string:
            Json.Generator generator = new Json.Generator();
            Json.Node root = builder.get_root();
            generator.set_root(root);
    
            return generator.to_data(null);
        }
        
        public void insert_shortcut_key(Json.Builder builder, string name, string key) {
            builder.begin_object ();
            builder.set_member_name("name");
            builder.add_string_value(name);
            
            builder.set_member_name("value");
            builder.add_string_value(key);
            builder.end_object();
        }
        
        public void draw_active_tab_underline(Tabbar tabbar) {
            tabbar.draw_active_tab_underline.connect((t, x, width) => {
                    int offset_x, offset_y;
                    tabbar.translate_coordinates(this, 0, 0, out offset_x, out offset_y);
					
                    active_tab_underline_x = x + offset_x;
                    active_tab_underline_width = width;
					
                    queue_draw();
                });
        }
    }
}