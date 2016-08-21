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
    public class Appbar : Gtk.Overlay {
        public Tabbar tabbar;
        public Box max_toggle_box;
        
        public Box window_button_box;
        public Box window_close_button_box;
        
        public ImageButton menu_button;
        public ImageButton min_button;
        public ImageButton max_button;
        public ImageButton unmax_button;
        public ImageButton close_button;
        public ImageButton quit_fullscreen_button;
		
		public int height = Constant.TITLEBAR_HEIGHT;
        public int close_button_margin_right = 5;
        public int logo_width = 48;
        public int titlebar_right_cache_width = 30;
        
        public Gtk.Widget focus_widget;
        
		public Menu.Menu menu;
		
        public Widgets.WindowEventArea event_area;
        
        public Widgets.Window window;
        
        public WorkspaceManager workspace_manager;
        
        public signal void close_window();
        public signal void quit_fullscreen();
        
        public Appbar(Widgets.Window win, Tabbar tab_bar, WorkspaceManager manager) {
            window = win;
            workspace_manager = manager;
			
			set_size_request(-1, height);
			
            tabbar = tab_bar;
            
            window_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            window_close_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            
            menu_button = new ImageButton("window_menu", true);
            min_button = new ImageButton("window_min", true);
            max_button = new ImageButton("window_max", true);
            unmax_button = new ImageButton("window_unmax", true);
            close_button = new ImageButton("window_close", true);
            quit_fullscreen_button = new ImageButton("quit_fullscreen", true);
			
			int margin_top = (int) (height - menu_button.normal_dark_surface.get_height()) / 2;
            int margin_right = 6;
			menu_button.margin_top = margin_top;
			min_button.margin_top = margin_top;
			max_button.margin_top = margin_top;
			unmax_button.margin_top = margin_top;
			close_button.margin_top = margin_top;
            quit_fullscreen_button.margin_top = margin_top;
            quit_fullscreen_button.margin_right = margin_right;
            
            close_button.click.connect((w) => {
                    close_window();
                });
            quit_fullscreen_button.click.connect((w) => {
                    quit_fullscreen();
                });
            
            menu_button.button_release_event.connect((b) => {
                    focus_widget = ((Gtk.Window) menu_button.get_toplevel()).get_focus();
                    
                    var menu_content = new List<Menu.MenuItem>();
                    menu_content.append(new Menu.MenuItem("new_window", "New window"));
                    menu_content.append(new Menu.MenuItem("remote_manage", "Connect remote"));
                    menu_content.append(new Menu.MenuItem("", ""));
                    menu_content.append(new Menu.MenuItem("preference", "Preference"));
                    if (Utils.is_command_exist("dman")) {
                        menu_content.append(new Menu.MenuItem("help", "Help"));
                    }
                    menu_content.append(new Menu.MenuItem("about", "About"));
                    menu_content.append(new Menu.MenuItem("exit", "Exit"));
                    
                    int menu_x, menu_y;
                    menu_button.translate_coordinates(menu_button.get_toplevel(), 0, 0, out menu_x, out menu_y);
                    Gtk.Allocation menu_rect;
                    menu_button.get_allocation(out menu_rect);
                    int window_x, window_y;
                    menu_button.get_toplevel().get_window().get_origin(out window_x, out window_y);
                    
                    menu = new Menu.Menu(window_x + menu_x, window_y + menu_y + menu_rect.height, menu_content);
                    menu.click_item.connect(handle_menu_item_click);
                    menu.destroy.connect(handle_menu_destroy);
                    
                    return false;
                });
            
            max_toggle_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            
            min_button.button_release_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).iconify();
                    
                    return false;
                });
            max_button.button_release_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).maximize();

                    return false;
                });
            unmax_button.button_release_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).unmaximize();

                    return false;
                });
            
            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0);
			
			var logo_box = new Box(Gtk.Orientation.VERTICAL, 0);
			logo_box.set_size_request(logo_width, Constant.TITLEBAR_HEIGHT);
			Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("title_icon.png"));
			logo_box.pack_start(logo_image, true, true, 0);
			box.pack_start(logo_box, false, false, 0);
			
            max_toggle_box.add(max_button);

            box.pack_start(tabbar, true, true, 0);
            var cache_area = new Gtk.EventBox();
            cache_area.set_size_request(titlebar_right_cache_width, -1);
            box.pack_start(cache_area, false, false, 0);
            box.pack_start(window_button_box, false, false, 0);
            box.pack_start(window_close_button_box, false, false, 0);
            close_button.margin_end = close_button_margin_right;
            
            show_window_button();
            
            event_area = new Widgets.WindowEventArea(this);
            // Don't override window button area.
            event_area.margin_end = Constant.CLOSE_BUTTON_WIDTH * 4;
            
            add(box);
            add_overlay(event_area);
            
            Gdk.RGBA background_color = Gdk.RGBA();
            
            box.draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);
                        
                    try {
                        background_color = Utils.hex_to_rgba(window.config.config_file.get_string("theme", "background"));
                        if (window.window_is_fullscreen()) {
                            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, 0.8);
                        } else {
                            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
                        }
                        Draw.draw_rectangle(cr, 0, 0, rect.width, Constant.TITLEBAR_HEIGHT);
                    } catch (Error e) {
                        print("Main window: %s\n", e.message);
                    }
                    
                    Utils.propagate_draw(box, cr);

                    return true;
                });
        }
        
        public void show_window_button() {
            window_button_box.pack_start(menu_button, false, false, 0);
            window_button_box.pack_start(min_button, false, false, 0);
            window_button_box.pack_start(max_toggle_box, false, false, 0);
            
            Utils.remove_all_children(window_close_button_box);
            window_close_button_box.pack_start(close_button, false, false, 0);
            
            show_all();
        }
        
        public void hide_window_button() {
            Utils.remove_all_children(window_button_box);
            Utils.remove_all_children(window_close_button_box);
            
            window_close_button_box.pack_start(quit_fullscreen_button, false, false, 0);
        }
        
        public void handle_menu_item_click(string item_id) {
            switch(item_id) {
                case "new_window":
                    try {
                        GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("deepin-terminal", null, GLib.AppInfoCreateFlags.NONE);
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print("Appbar menu item 'new window': %s\n", e.message);
                    }
			    	break;
                case "remote_manage":
                    workspace_manager.focus_workspace.show_remote_panel(workspace_manager.focus_workspace);
                    break;
				case "help":
                    try {
                        GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("dman deepin-terminal", null, GLib.AppInfoCreateFlags.NONE);
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print("Appbar menu item 'help': %s\n", e.message);
                    }
					break;
			    case "about":
                    var dialog = new AboutDialog(focus_widget);
                    dialog.transient_for_window((Widgets.ConfigWindow) this.get_toplevel());
			    	break;
				case "exit":
                    window.quit();
					break;
                case "preference":
                    var preference = new Widgets.Preference((Widgets.ConfigWindow) this.get_toplevel(), ((Gtk.Window) this.get_toplevel()).get_focus());
                    preference.transient_for_window((Widgets.ConfigWindow) this.get_toplevel());
                    break;
            }
		}        
        
		public void handle_menu_destroy() {
			menu = null;
            
            if (focus_widget != null) {
                focus_widget.grab_focus();
            }
        }
        
        public void update_max_button() {
            Utils.remove_all_children(max_toggle_box);
            
            if (((Widgets.Window) get_toplevel()).window_is_max()) {
                max_toggle_box.add(unmax_button);
            } else {
                max_toggle_box.add(max_button);
            }
            
            max_toggle_box.show_all();
        }
    }
}