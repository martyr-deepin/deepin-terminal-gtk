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
using Utils;
using Gee;

namespace Widgets {
	public class CommandPanel : Gtk.HBox {
		public Widgets.ConfigWindow parent_window;
		public WorkspaceManager workspace_manager;
		public string config_file_path = Utils.get_config_file_path("command-config.conf");
        public Gdk.RGBA background_color;
        public Gdk.RGBA line_dark_color;
        public Gdk.RGBA line_light_color;
        public Gtk.Box home_page_box;
        public Gtk.Box search_page_box;
        public Gtk.ScrolledWindow? home_page_scrolledwindow;
        public Gtk.ScrolledWindow? search_page_scrolledwindow;
        public Gtk.Widget focus_widget;
        public KeyFile config_file;
        public Widgets.Switcher switcher;
        public Workspace workspace;
        public int back_button_margin_left = 8;
        public int back_button_margin_top = 6;
        public int width = Constant.SLIDER_WIDTH;
        
        public delegate void UpdatePageAfterEdit();
		
		public CommandPanel(Workspace space, WorkspaceManager manager) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
            
            workspace = space;
			workspace_manager = manager;
            
            config_file = new KeyFile();
            
            line_dark_color = Utils.hex_to_rgba("#ffffff", 0.1);
            line_light_color = Utils.hex_to_rgba("#000000", 0.1);
            
            focus_widget = ((Gtk.Window) workspace.get_toplevel()).get_focus();
			parent_window = (Widgets.ConfigWindow) workspace.get_toplevel();
            try {
                background_color = Utils.hex_to_rgba(parent_window.config.config_file.get_string("theme", "background"));
            } catch (Error e) {
                print("CommandPanel init: %s\n", e.message);
            }
            
            switcher = new Widgets.Switcher(width);
            
            home_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            search_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            set_size_request(width, -1);
            home_page_box.set_size_request(width, -1);
            search_page_box.set_size_request(width, -1);
            
            pack_start(switcher, true, true, 0);
            
            show_home_page();
			
			draw.connect(on_draw);
        }
        
        public void load_config() {
            var file = File.new_for_path(config_file_path);
            if (!file.query_exists()) {
			    Utils.touch_dir(Utils.get_config_dir());
                Utils.create_file(config_file_path);
            } else {
                try {
                    config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
                } catch (Error e) {
                    if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                        print("Config: %s\n", e.message);
                    }
                }
            }
        }
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
            
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, 0.8);
            Draw.draw_rectangle(cr, 1, 0, rect.width - 1, rect.height);
            
            if (is_light_theme) {
                Utils.set_context_color(cr, line_light_color);
            } else {
                Utils.set_context_color(cr, line_dark_color);
            }
            Draw.draw_rectangle(cr, 0, 0, 1, rect.height);
            
            return false;
        }
		
		public void show_home_page(Gtk.Widget? start_widget=null) {
            create_home_page();
            
            if (start_widget == null) {
                switcher.add_to_left_box(home_page_box);
            } else {
                switcher.scroll_to_left(start_widget, home_page_box);
            }
			
			show_all();
		}

        public void create_home_page() {
			Utils.destroy_all_children(home_page_box);
            home_page_scrolledwindow = null;
            
			ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
			        
            load_config();
				
            foreach (unowned string option in config_file.get_groups ()) {
                add_group_item(option, ungroups, config_file);
            }
			
			if (ungroups.size > 1) {
			    Widgets.SearchEntry search_entry = new Widgets.SearchEntry();
                home_page_box.pack_start(search_entry, false, false, 0);
                
                search_entry.search_entry.activate.connect((entry) => {
                        if (entry.get_text().strip() != "") {
                            show_search_page(entry.get_text(), home_page_box);
                        }
                    });
                
                var split_line = new SplitLine(parent_window.is_light_theme());
                home_page_box.pack_start(split_line, false, false, 0);
			}

            home_page_scrolledwindow = create_scrolled_window();
            home_page_box.pack_start(home_page_scrolledwindow, true, true, 0);
            
            var command_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            home_page_scrolledwindow.add(command_box);
            
			if (ungroups.size > 0) {
                foreach (var ungroup_list in ungroups) {
                    var command_button = create_command_button(ungroup_list[0], ungroup_list[1], ungroup_list[2]);
                    command_button.edit_command.connect((w, command_name) => {
                            edit_command(command_name, () => {
                                    update_home_page();
                                });
                        });
                    command_box.pack_start(command_button, false, false, 0);
                }
                
            }
			
            var split_line = new SplitLine(parent_window.is_light_theme());
            home_page_box.pack_start(split_line, false, false, 0);
                
			Widgets.AddButton add_command_button = create_add_command_button();
            add_command_button.margin_left = 16;
            add_command_button.margin_right = 16;
            add_command_button.margin_top = 16;
            add_command_button.margin_bottom = 16;
            home_page_box.pack_start(add_command_button, false, false, 0);
        }
        
        public void add_command(
			string name,
			string command,
			string shortcut) {
			if (name != "" && command != "") {
			    Utils.touch_dir(Utils.get_config_dir());
			    
                load_config();
			    
			    // Use ',' as array-element-separator instead of ';'.
			    config_file.set_list_separator (',');
			    
			    config_file.set_string(name, "Command", command);
			    config_file.set_string(name, "Shortcut", shortcut);
                
			    try {
			    	config_file.save_to_file(config_file_path);
                } catch (Error e) {
			    	print("add_command error occur when config_file.save_to_file %s: %s\n", config_file_path, e.message);
			    }
			}
		}
        
        public void show_search_page(string search_text, Gtk.Widget start_widget) {
            create_search_page(search_text);

            switcher.scroll_to_right(start_widget, search_page_box);
            
            show_all();
		}

        public void create_search_page(string search_text) {
            Utils.destroy_all_children(search_page_box);
            search_page_scrolledwindow = null;

			try {
                load_config();
				
                ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
                
			    foreach (unowned string option in config_file.get_groups ()) {
                    ArrayList<string> match_list = new ArrayList<string>();
                    match_list.add(option);
                    foreach (string key in config_file.get_keys(option)) {
                        if (key == "Command" || key == "Shortcut") {
                            match_list.add(config_file.get_value(option, key));
                        }
                    }
                    foreach (string match_text in match_list) {
                        if (match_text.down().contains(search_text.down())) {
                            add_group_item(option, ungroups, config_file);

                            // Just add option one times.
                            break;
                        }
                    }
                }
                
                var top_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                top_box.set_size_request(-1, Constant.REMOTE_PANEL_SEARCHBAR_HEIGHT);
                search_page_box.pack_start(top_box, false, false, 0);
            
                ImageButton back_button = new Widgets.ImageButton("back", true);
                back_button.margin_left = back_button_margin_left;
                back_button.margin_top = back_button_margin_top;
                back_button.clicked.connect((w) => {
                        show_home_page(search_page_box);
                    });
                top_box.pack_start(back_button, false, false, 0);
                
                var search_label = new Gtk.Label(null);
                search_label.set_text("%s %s".printf(_("Search:"), search_text));
                search_label.get_style_context().add_class("remote_search_label");
                top_box.pack_start(search_label, true, true, 0);
                
                var split_line = new SplitLine(parent_window.is_light_theme());
                search_page_box.pack_start(split_line, false, false, 0);
                
                search_page_scrolledwindow = create_scrolled_window();
                search_page_box.pack_start(search_page_scrolledwindow, true, true, 0);
            
                var command_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                search_page_scrolledwindow.add(command_box);
            
                foreach (var ungroup_list in ungroups) {
                    var command_button = create_command_button(ungroup_list[0], ungroup_list[1], ungroup_list[2]);
                    command_button.edit_command.connect((w, command_name) => {
                            edit_command(command_name, () => {
                                    update_search_page(search_text);
                                });
                        });
                    command_box.pack_start(command_button, false, false, 0);
                }
            } catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print("CommandPanel create_search_page: %s\n", e.message);
				}
			}
            
        }
        
        public void add_group_item(string option, ArrayList<ArrayList<string>> lists, KeyFile config_file) {
			try {
                ArrayList<string> list = new ArrayList<string>();
                list.add(option);
                list.add(config_file.get_value(option, "Command"));
                list.add(config_file.get_value(option, "Shortcut"));
                lists.add(list);
            } catch (Error e) {
                print("add_group_item error: %s\n", e.message);
			}
        }
        
        public void edit_command(string command_name, UpdatePageAfterEdit func) {
            load_config();

            var command_dialog = new Widgets.CommandDialog(parent_window, null, this, command_name, config_file);
            command_dialog.transient_for_window(parent_window);
            command_dialog.delete_command.connect((name) => {
                    try {
                        // First, remove old command info from config file.
                        if (config_file.has_group(command_name)) {
                            config_file.remove_group(command_name);
                            config_file.save_to_file(config_file_path);
                        }
                        
                        func();
                    } catch (Error e) {
                        error ("%s", e.message);
                    }
                });
            command_dialog.edit_command.connect((name, command, shortcut) => {
                                                         try {
                                                             // First, remove old command info from config file.
                                                             if (config_file.has_group(command_name)) {
                                                                 config_file.remove_group(command_name);
                                                                 config_file.save_to_file(config_file_path);
                                                             }
                                                      
                                                             // Second, add new command info.
                                                             add_command(name, command, shortcut);
                                                  
                                                             func();
                                                      
                                                             command_dialog.destroy();
                                                         } catch (Error e) {
                                                             error ("%s", e.message);
                                                         }
                                              });
                                    
            command_dialog.show_all();
        }
        
        public Gtk.ScrolledWindow create_scrolled_window() {
            var scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.get_style_context().add_class("scrolledwindow");
            scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            scrolledwindow.get_vscrollbar().get_style_context().add_class("light_scrollbar");

            return scrolledwindow;
        }
        
        public Widgets.CommandButton create_command_button(string name, string value, string shortcut) {
            var command_button = new Widgets.CommandButton(name, value, shortcut);
            command_button.execute_command.connect((w, command) => {
                    execute_command(command);
                });
            return command_button;
        }
        
        public void execute_command(string command) {
            Term focus_term = workspace_manager.focus_workspace.get_focus_term(workspace_manager.focus_workspace);
            var command_string = "%s\n".printf(command);
            focus_term.term.feed_child(command_string, command_string.length);
            
            workspace.hide_command_panel();
            focus_widget.grab_focus();
        }
        
        public Widgets.AddButton create_add_command_button() {
			Widgets.AddButton add_command_button = new Widgets.AddButton(parent_window.is_light_theme(), _("Add command"));
			add_command_button.clicked.connect((w) => {
                    Term focus_term = workspace_manager.focus_workspace.get_focus_term(workspace_manager.focus_workspace);
                    var command_dialog = new Widgets.CommandDialog(parent_window, focus_term, this);
                    command_dialog.transient_for_window(parent_window);
                    command_dialog.add_command.connect((name, command, shortcut) => {
                            add_command(name, command, shortcut);
                            update_home_page();
                            command_dialog.destroy();
                        });
                    command_dialog.show_all();
                });

            return add_command_button;
        }
        
        public void update_home_page() {
            double scroll_value = 0;
            if (home_page_scrolledwindow != null) {
                scroll_value = home_page_scrolledwindow.get_vadjustment().get_value();
            }
                            
            create_home_page();
            
            switcher.add_to_left_box(home_page_box);
            
            if (home_page_scrolledwindow != null) {
                home_page_scrolledwindow.get_vadjustment().set_value(scroll_value);
            }
            
            show_all();
        }
        
        public void update_search_page(string search_text) {
            double scroll_value = 0;
            if (search_page_scrolledwindow != null) {
                scroll_value = search_page_scrolledwindow.get_vadjustment().get_value();
            }
                            
			create_search_page(search_text);
            
            switcher.add_to_left_box(search_page_box);

            if (search_page_scrolledwindow != null) {
                search_page_scrolledwindow.get_vadjustment().set_value(scroll_value);
            }
            
            show_all();
        }
    }
}