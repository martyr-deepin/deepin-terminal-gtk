using Gtk;
using Widgets;
using Utils;
using Gee;

namespace Widgets {
	public class RemotePanel : Gtk.HBox {
		string config_file_path = Utils.get_config_file_path("server-config.conf");
        
        public Workspace workspace;
		public WorkspaceManager workspace_manager;
        public Gtk.Widget focus_widget;
		
		public Widgets.ConfigWindow parent_window;
        public Gdk.RGBA background_color;
        
        public Widgets.Switcher switcher;
        
        public Gtk.Box home_page_box;
        public Gtk.Box group_page_box;
        public Gtk.Box search_page_box;
        
        public Gtk.ScrolledWindow? home_page_scrolledwindow;
        public Gtk.ScrolledWindow? group_page_scrolledwindow;
        public Gtk.ScrolledWindow? search_page_scrolledwindow;
        
        public int width = Constant.SLIDER_WIDTH;
        
        public delegate void UpdatePageAfterEdit();
		
		public RemotePanel(Workspace space, WorkspaceManager manager) {
            workspace = space;
			workspace_manager = manager;
            
            focus_widget = ((Gtk.Window) workspace.get_toplevel()).get_focus();
			parent_window = (Widgets.ConfigWindow) workspace.get_toplevel();
            background_color = Gdk.RGBA();
            try {
                background_color.parse(parent_window.config.config_file.get_string("theme", "color1"));
            } catch (Error e) {
                print(e.message);
            }
            
            switcher = new Widgets.Switcher(width);
            
            home_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            group_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            search_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            set_size_request(width, -1);
            home_page_box.set_size_request(width, -1);
            group_page_box.set_size_request(width, -1);
            search_page_box.set_size_request(width, -1);
            
            pack_start(switcher, true, true, 0);
            
            show_home_page();
			
			draw.connect(on_draw);
        }
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, 0.8);
            Draw.draw_rectangle(cr, 1, 0, rect.width - 1, rect.height);
            
            cr.set_source_rgba(1, 1, 1, 0.1);
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
            
            HashMap<string, int> groups = new HashMap<string, int>();
			ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
			        
			KeyFile config_file = new KeyFile();
			try {
				config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
				
			    foreach (unowned string option in config_file.get_groups ()) {
			    	string group_name = config_file.get_value(option, "GroupName");
					
					if (group_name == "") {
                        add_group_item(option, ungroups, config_file);
                    } else {
						if (groups.has_key(group_name)) {
							int group_item_number = groups.get(group_name);
							groups.set(group_name, group_item_number + 1);
						} else {
							groups.set(group_name, 1);
						}
			    	}
			    }
			} catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print(e.message);
				}
			}
			
			if (groups.size > 0 || ungroups.size > 1) {
			    Widgets.SearchEntry search_entry = new Widgets.SearchEntry();
                home_page_box.pack_start(search_entry, false, false, 0);
                
                search_entry.search_entry.activate.connect((entry) => {
                        show_search_page(entry.get_text(), "", home_page_box);
                    });
                
                var split_line = create_split_line();
                split_line.margin_left = 1;
                home_page_box.pack_start(split_line, false, false, 0);
			}

            home_page_scrolledwindow = create_scrolled_window();
            home_page_box.pack_start(home_page_scrolledwindow, true, true, 0);
            
            var server_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            home_page_scrolledwindow.add(server_box);
            
			if (ungroups.size + groups.size > 0) {
                foreach (var group_entry in groups.entries) {
                    var server_group_button = create_server_group_button(group_entry.key, group_entry.value);
                    server_box.pack_start(server_group_button, false, false, 0);
                }
				
				foreach (var ungroup_list in ungroups) {
                    var server_button = create_server_button(ungroup_list[0], ungroup_list[1]);
                    server_button.edit_server.connect((w, server_info) => {
                            edit_server(server_info, () => {
                                    update_home_page();
                                });
                        });
                    server_box.pack_start(server_button, false, false, 0);
                }
                
            }
			
			Widgets.AddServerButton add_server_button = create_add_server_button();
            home_page_box.pack_start(add_server_button, false, false, 0);
        }
        
        public void login_server(string server_info) {
			KeyFile config_file = new KeyFile();
            
			try {
				config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
			} catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
					print("login_server error: %s\n", e.message);
				}
			}
            
            // A reference to our file
            var file = File.new_for_path(Utils.get_ssh_script_path());

            if (!file.query_exists ()) {
                stderr.printf("File '%s' doesn't exist.\n", file.get_path());
            }

            try {
                var dis = new DataInputStream(file.read());
                string line;
                string ssh_script_content = "";                                       
                while ((line = dis.read_line(null)) != null) {
                    ssh_script_content = ssh_script_content.concat("%s\n".printf(line));
                }
                                       
                string password = Utils.lookup_password(server_info.split("@")[0], server_info.split("@")[1]);
                
                ssh_script_content = ssh_script_content.replace("<<USER>>", server_info.split("@")[0]);
                ssh_script_content = ssh_script_content.replace("<<SERVER>>", server_info.split("@")[1]);
                ssh_script_content = ssh_script_content.replace("<<PASSWORD>>", password);
                ssh_script_content = ssh_script_content.replace("<<PORT>>", config_file.get_value(server_info, "Port"));
                                       
                // Create temporary expect script file, and the file will
                // be delete by itself.
                FileIOStream iostream;
                var tmpfile = File.new_tmp("deepin-terminal-XXXXXX", out iostream);
                OutputStream ostream = iostream.output_stream;
                DataOutputStream dos = new DataOutputStream(ostream);
                dos.put_string(ssh_script_content);
                                       
                workspace.hide_remote_panel();
                focus_widget.grab_focus();

				workspace_manager.new_workspace_with_current_directory();
				GLib.Timeout.add(10, () => {
						try {
							Term term = workspace_manager.focus_workspace.get_focus_term(workspace_manager.focus_workspace);
							term.term.set_encoding(config_file.get_value(server_info, "Encode"));
						
							var backspace_binding = config_file.get_value(server_info, "Backspace");
							if (backspace_binding == "auto") {
								term.term.set_backspace_binding(Vte.EraseBinding.AUTO);
							} else if (backspace_binding == "escape-sequence") {
								term.term.set_backspace_binding(Vte.EraseBinding.DELETE_SEQUENCE);
							} else if (backspace_binding == "ascii-del") {
								term.term.set_backspace_binding(Vte.EraseBinding.ASCII_DELETE);
							} else if (backspace_binding == "control-h") {
								term.term.set_backspace_binding(Vte.EraseBinding.ASCII_BACKSPACE);
							} else if (backspace_binding == "tty") {
								term.term.set_backspace_binding(Vte.EraseBinding.TTY);
							} 
						
						
							var del_binding = config_file.get_value(server_info, "Del");
							if (del_binding == "auto") {
								term.term.set_delete_binding(Vte.EraseBinding.AUTO);
							} else if (del_binding == "escape-sequence") {
								term.term.set_delete_binding(Vte.EraseBinding.DELETE_SEQUENCE);
							} else if (del_binding == "ascii-del") {
								term.term.set_delete_binding(Vte.EraseBinding.ASCII_DELETE);
							} else if (del_binding == "control-h") {
								term.term.set_delete_binding(Vte.EraseBinding.ASCII_BACKSPACE);
							} else if (del_binding == "tty") {
								term.term.set_delete_binding(Vte.EraseBinding.TTY);
							} 
						
							if (term != null) {
								string command = "expect -f " + tmpfile.get_path() + "\n";
								term.term.feed_child(command, command.length);
								
								string user_path_command = "cd %s\n".printf(config_file.get_string(server_info, "Path"));
								term.term.feed_child(user_path_command, user_path_command.length);
								
								GLib.Timeout.add(10, () => {
										try {
											string user_command = "%s\n".printf(config_file.get_string(server_info, "Command"));
											term.term.feed_child(user_command, user_command.length);
										} catch (GLib.KeyFileError e) {
											error("%s", e.message);
										}
										
										return false;
									});
							}
						} catch (Error e) {
							error ("%s", e.message);
						}
                        
                        return false;
					});
            } catch (Error e) {
                error ("%s", e.message);
            }
        }
        
        public void show_group_page(string group_name, Gtk.Widget start_widget, string directoin) {
            create_group_page(group_name);

            if (directoin == "scroll_to_right") {
                switcher.scroll_to_right(start_widget, group_page_box);
            } else if (directoin == "scroll_to_left") {
                switcher.scroll_to_left(start_widget, group_page_box);
            }
            
            show_all();
        }
        
        public void create_group_page(string group_name) {
			Utils.destroy_all_children(group_page_box);
            group_page_scrolledwindow = null;
            
			KeyFile config_file = new KeyFile();
            
			ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
            
			try {
				config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
                
                foreach (unowned string option in config_file.get_groups ()) {
                    string gname = config_file.get_value(option, "GroupName");
                    
                    if (gname == group_name) {
                        add_group_item(option, ungroups, config_file);
                    }
                }
			} catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
					print("login_server error: %s\n", e.message);
				}
			}

            var top_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            top_box.set_size_request(-1, 36);
			group_page_box.pack_start(top_box, false, false, 0);
            
			ImageButton back_button = new Widgets.ImageButton("back");
            back_button.margin_left = 8;
            back_button.margin_top = 6;
			back_button.click.connect((w) => {
					show_home_page(group_page_box);
                });
			top_box.pack_start(back_button, false, false, 0);
            
            var split_line = create_split_line();
            split_line.margin_left = 1;
            group_page_box.pack_start(split_line, false, false, 0);
            
			if (ungroups.size > 1) {
			    Widgets.SearchEntry search_entry = new Widgets.SearchEntry();
                top_box.pack_start(search_entry, true, true, 0);
                
                search_entry.search_entry.activate.connect((entry) => {
                        show_search_page(entry.get_text(), group_name, group_page_box);
                    });
			}
			
            group_page_scrolledwindow = create_scrolled_window();
            group_page_box.pack_start(group_page_scrolledwindow, true, true, 0);
            
            var server_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            group_page_scrolledwindow.add(server_box);
            
            if (ungroups.size > 0) {
                foreach (var ungroup_list in ungroups) {
                    var server_button = create_server_button(ungroup_list[0], ungroup_list[1]);
                    server_button.edit_server.connect((w, server_info) => {
                            edit_server(server_info, () => {
                                    update_group_page(group_name);
                                });
                        });
                    server_box.pack_start(server_button, false, false, 0);
                }
            }
        }
		
        public void add_server(
			string server_address,
			string user,
			string password,
			string port,
			string encode,
			string path,
            string command,
			string name,
			string group_name,
			string backspace,
			string delete
			) {
			if (user != "" && server_address != "") {
			    Utils.touch_dir(Utils.get_config_dir());
			    
			    KeyFile config_file = new KeyFile();
			    try {
			    	config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
			    } catch (Error e) {
					if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                        print(e.message);
					}
			    }
			    
			    // Use ',' as array-element-separator instead of ';'.
			    config_file.set_list_separator (',');
			    
			    string gname = "%s@%s".printf(user, server_address);
			    config_file.set_string(gname, "Name", name);
			    config_file.set_string(gname, "GroupName", group_name);
				config_file.set_string(gname, "Command", command);
                config_file.set_string(gname, "Path", path);
				config_file.set_string(gname, "Port", port);
			    config_file.set_string(gname, "Encode", encode);
			    config_file.set_string(gname, "Backspace", backspace);
			    config_file.set_string(gname, "Del", delete);

                Utils.store_password(user, server_address, password);
			    
			    try {
			    	config_file.save_to_file(config_file_path);
			    } catch (Error e) {
			    	print("add_server error occur when config_file.save_to_file %s: %s\n", config_file_path, e.message);
			    }
			}
		}
        
        public void show_search_page(string search_text, string group_name, Gtk.Widget start_widget) {
            create_search_page(search_text, group_name);

            switcher.scroll_to_right(start_widget, search_page_box);
            
            show_all();
		}

        public void create_search_page(string search_text, string group_name) {
            Utils.destroy_all_children(search_page_box);
            search_page_scrolledwindow = null;

            KeyFile config_file = new KeyFile();
			try {
				config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
				
                ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
                
			    foreach (unowned string option in config_file.get_groups ()) {
                    if (group_name == "" || group_name == config_file.get_value(option, "GroupName")) {
                        ArrayList<string> match_list = new ArrayList<string>();
                        match_list.add(option);
                        foreach (string key in config_file.get_keys(option)) {
                            match_list.add(config_file.get_value(option, key));
                        }
                        foreach (string match_text in match_list) {
                            if (match_text.contains(search_text)) {
                                add_group_item(option, ungroups, config_file);

                                // Just add option one times.
                                break;
                            }
                        }
                    }
                }
                
                var top_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                top_box.set_size_request(-1, 36);
                search_page_box.pack_start(top_box, false, false, 0);
            
                ImageButton back_button = new Widgets.ImageButton("back");
                back_button.margin_left = 8;
                back_button.margin_top = 6;
                back_button.click.connect((w) => {
                        if (group_name == "") {
                            show_home_page(search_page_box);
                        } else {
                            show_group_page(group_name, search_page_box, "scroll_to_left");
                        }
                    });
                top_box.pack_start(back_button, false, false, 0);
                
                var search_label = new Gtk.Label(null);
                search_label.set_text("search: %s".printf(search_text));
                search_label.get_style_context().add_class("remote_search_label");
                top_box.pack_start(search_label, true, true, 0);
                
                var split_line = create_split_line();
                split_line.margin_left = 1;
                search_page_box.pack_start(split_line, false, false, 0);
                
                search_page_scrolledwindow = create_scrolled_window();
                search_page_box.pack_start(search_page_scrolledwindow, true, true, 0);
            
                var server_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                search_page_scrolledwindow.add(server_box);
            
                foreach (var ungroup_list in ungroups) {
                    var server_button = create_server_button(ungroup_list[0], ungroup_list[1]);
                    server_button.edit_server.connect((w, server_info) => {
                            edit_server(server_info, () => {
                                    update_search_page(search_text, group_name);
                                });
                        });
                    server_box.pack_start(server_button, false, false, 0);
                }
            } catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print(e.message);
				}
			}
            
        }
        
        public void add_group_item(string option, ArrayList<ArrayList<string>> lists, KeyFile config_file) {
			try {
                ArrayList<string> list = new ArrayList<string>();
                list.add(config_file.get_value(option, "Name"));
                list.add(option);
                lists.add(list);
            } catch (Error e) {
                print("add_group_item error: %s\n", e.message);
			}
        }
        
        public void edit_server(string server_info, UpdatePageAfterEdit func) {
            KeyFile config_file = new KeyFile();
            try {
                config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
            } catch (Error e) {
                if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print(e.message);
                }
            }
            var remote_server = new Widgets.RemoteServer(parent_window, this, server_info, config_file);
            remote_server.edit_server.connect((
                server, address, username, password, port, 
                encode, path, command, nickname, groupname, 
                backspace_key, delete_key) => {
                                                  try {
                                                      // First, remove old server info from config file.
                                                      if (config_file.has_group(server_info)) {
                                                          config_file.remove_group(server_info);
                                                          config_file.save_to_file(config_file_path);
                                                      }
                                                  } catch (Error e) {
                                                      error ("%s", e.message);
                                                  }
                                                                          
                                                  // Second, add new server info.
                                                  add_server(address, username, password, port, encode, path, 
                                                             command, nickname, groupname, backspace_key, delete_key);
                                                  
                                                  func();
                                              });
                                    
            remote_server.show_all();
        }
        
        public Gtk.ScrolledWindow create_scrolled_window() {
            var scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.get_style_context().add_class("scrolledwindow");
            scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            scrolledwindow.get_vscrollbar().get_style_context().add_class("preference_scrollbar");

            return scrolledwindow;
        }
        
        public Widgets.ServerButton create_server_button(string name, string info) {
            var server_button = new Widgets.ServerButton(name, info);
            server_button.login_server.connect((w, server_info) => {
                    login_server(server_info);
                });
            return server_button;
        }
        
        public Widgets.ServerGroupButton create_server_group_button(string group_name, int server_number) {
            var server_group_button = new Widgets.ServerGroupButton(group_name, server_number);
            server_group_button.show_group_servers.connect((w, group_name) => {
                    show_group_page(group_name, home_page_box, "scroll_to_right");
                });

            return server_group_button;
        }
        
        public Widgets.AddServerButton create_add_server_button() {
			Widgets.AddServerButton add_server_button = new Widgets.AddServerButton();
			add_server_button.button_release_event.connect((w, e) => {
                    var remote_server = new Widgets.RemoteServer(parent_window, this);
                    remote_server.add_server.connect((server, address, username, password, port, encode, path, command, nickname, groupname, backspace_key, delete_key) => {
                            add_server(address, username, password, port, encode, path, command, nickname, groupname, backspace_key, delete_key);

                            update_home_page();
                        });
                    remote_server.show_all();
					
					return false;
				});

            return add_server_button;
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
        
        public void update_group_page(string group_name) {
            double scroll_value = 0;
            if (group_page_scrolledwindow != null) {
                scroll_value = group_page_scrolledwindow.get_vadjustment().get_value();
            }
                            
            create_group_page(group_name);
            
            switcher.add_to_left_box(group_page_box);

            if (group_page_scrolledwindow != null) {
                group_page_scrolledwindow.get_vadjustment().set_value(scroll_value);
            }
            
            show_all();
        }
        
        public void update_search_page(string search_text, string group_name) {
            double scroll_value = 0;
            if (search_page_scrolledwindow != null) {
                scroll_value = search_page_scrolledwindow.get_vadjustment().get_value();
            }
                            
			create_search_page(search_text, group_name);
            
            switcher.add_to_left_box(search_page_box);

            if (search_page_scrolledwindow != null) {
                search_page_scrolledwindow.get_vadjustment().set_value(scroll_value);
            }
            
            show_all();
        }
        
        public Gtk.Box create_split_line() {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.set_size_request(-1, 1);
            
            box.draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);
                    
                    cr.set_source_rgba(1, 1, 1, 0.1);
                    Draw.draw_rectangle(cr, 0, 0, rect.width, 1);
                    
                    return true;
                });
            
            return box;
        }
    }
}