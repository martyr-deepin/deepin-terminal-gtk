using Gtk;
using Widgets;
using Utils;
using Gee;

namespace Widgets {
	public class RemotePanel : Gtk.VBox {
		string config_file_path = Utils.get_config_file_path("server-config.conf");
        
        public Workspace workspace;
		public WorkspaceManager workspace_manager;
        public Gtk.Widget focus_widget;
		
		public Widgets.Window parent_window;
		
		public RemotePanel(Workspace space, WorkspaceManager manager) {
            workspace = space;
			workspace_manager = manager;
			
            focus_widget = ((Gtk.Window) workspace.get_toplevel()).get_focus();
			parent_window = (Widgets.Window) workspace.get_toplevel();
            
			show_home_page();
			
			draw.connect(on_draw);
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            cr.set_source_rgba(0, 0, 0, 0.8);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height);
            
            return false;
        }
		
		public void show_home_page() {
			Utils.destroy_all_children(this);
			
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
					print("show_home_page error: %s\n", e.message);
				}
			}
			
			if (groups.size > 0 || ungroups.size > 1) {
			    Entry search_entry = new Entry();
			    search_entry.set_placeholder_text("Search");
			    pack_start(search_entry, false, false, 0);
                
                search_entry.activate.connect((entry) => {
                        show_search_page(entry.get_text(), "");
                    });
			}
			
			Temp_TextButton add_server_button = new Temp_TextButton("Add server");
			add_server_button.button_release_event.connect((w, e) => {
                    var remote_server = new Widgets.RemoteServer(parent_window, this);
                    remote_server.add_server.connect((server, address, username, password, port, encode, path, command, nickname, groupname, backspace_key, delete_key) => {
                            add_server(address, username, password, port, encode, path, command, nickname, groupname, backspace_key, delete_key);
                        });
                    remote_server.show_all();
					
					return false;
				});
			pack_start(add_server_button, false, false, 0);
			
			if (ungroups.size + groups.size > 0) {
                var view = get_server_view(true, "");
                
                TreeIter iter;
                
				foreach (var group_entry in groups.entries) {
                    ((Gtk.ListStore) view.model).append(out iter);
                    ((Gtk.ListStore) view.model).set(iter, 0, "%s\n%i".printf(group_entry.key, group_entry.value));
				}
				
				foreach (var ungroup_list in ungroups) {
                    ((Gtk.ListStore) view.model).append(out iter);
                    ((Gtk.ListStore) view.model).set(iter, 0, "%s\n%s".printf(ungroup_list[0], ungroup_list[1]), 1, "go-home");
				}
                
            }
			
			show_all();
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
                                       
                string password = lookup_password(server_info.split("@")[0], server_info.split("@")[1]);
                
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
                                       
                workspace.remove_remote_panel();
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
        
        public void show_group_page(string group_name) {
            Utils.destroy_all_children(this);
            
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

			Temp_TextButton add_server_button = new Temp_TextButton("Back");
			add_server_button.button_release_event.connect((w, e) => {
					show_home_page();
					
					return false;
				});
			pack_start(add_server_button, false, false, 0);
            
			if (ungroups.size > 1) {
			    Entry search_entry = new Entry();
			    search_entry.set_placeholder_text("Search");
			    pack_start(search_entry, false, false, 0);
                
                search_entry.activate.connect((entry) => {
                        show_search_page(entry.get_text(), group_name);
                    });
			}
			
            if (ungroups.size > 0) {
                var view = get_server_view(false, group_name);
                
                TreeIter iter;
                
                foreach (var ungroup_list in ungroups) {
                    ((Gtk.ListStore) view.model).append(out iter);
                    ((Gtk.ListStore) view.model).set(iter, 0, "%s\n%s".printf(ungroup_list[0], ungroup_list[1]), 1, "go-home");
				}
            }
            
            show_all();
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
						print("show_home_page error: %s\n", e.message);
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

                store_password(user, server_address, password);
			    
			    try {
			    	config_file.save_to_file(config_file_path);
			    } catch (Error e) {
			    	print("add_server error occur when config_file.save_to_file %s: %s\n", config_file_path, e.message);
			    }
			}
		}
        
        public string lookup_password(string user, string server_address) {
            var password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                                    Secret.SchemaFlags.NONE,
                                                    "number", Secret.SchemaAttributeType.INTEGER,
                                                    "string", Secret.SchemaAttributeType.STRING,
                                                    "even", Secret.SchemaAttributeType.BOOLEAN);
            
            string password;

            try {
                password = Secret.password_lookup_sync(password_schema, null, null, "number", 8, "string", "eight", "even", true);
                // print("Lookup password: '%s'\n", password);
            } catch (Error e) {
                error ("%s", e.message);
            }
            
            if (password == null) {
                return "";
            } else {
                return password;
            }
        }
        
        public void store_password(string user, string server_address, string password) {
            var password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                                    Secret.SchemaFlags.NONE,
                                                    "number", Secret.SchemaAttributeType.INTEGER,
                                                    "string", Secret.SchemaAttributeType.STRING,
                                                    "even", Secret.SchemaAttributeType.BOOLEAN);
            
            var attributes = new GLib.HashTable<string,string>(null, null);
            attributes["number"] = "8";
            attributes["string"] = "eight";
            attributes["even"] = "true";
            
            try {
                Secret.password_clear_sync(password_schema, null, "number", 8, "string", "eight", "even", true);
                // print("Remove password: %s %s\n".printf(user, server_address));
            } catch (Error e) {
                error ("%s", e.message);
            }

            Secret.password_storev.begin(password_schema, attributes, Secret.COLLECTION_DEFAULT,
                                         "com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                         password,
                                         null, (obj, async_res) => {
                                             try {
                                                 Secret.password_store.end(async_res);
                                                 // print("Store password: %s %s %s\n", user, server_address, password);
                                             } catch (Error e) {
                                                 error ("%s", e.message);
                                             }
                                         });

        }
        
		public void show_edit_server_page(string server_info, bool is_homepage, string group_name) {
            Utils.destroy_all_children(this);
            
			KeyFile config_file = new KeyFile();
            
			try {
				config_file.load_from_file(config_file_path, KeyFileFlags.NONE);

			    Temp_TextButton add_server_button = new Temp_TextButton("Back");
			    add_server_button.button_release_event.connect((w, e) => {
                        if (is_homepage) {
                            show_home_page();
                        } else {
                            show_group_page(group_name);
                        }
			    		
			    		return false;
			    	});
            
			    pack_start(add_server_button, false, false, 0);
                
                Entry address_entry = new Entry();
			    address_entry.set_text(server_info.split("@")[1]);
			    address_entry.set_placeholder_text("IP address");
			    pack_start(address_entry, false, false, 0);
                
			    Entry user_entry = new Entry();
			    user_entry.set_text(server_info.split("@")[0]);
			    user_entry.set_placeholder_text("Username");
			    pack_start(user_entry, false, false, 0);
                
			    Entry password_entry = new Entry();
                string password = lookup_password(server_info.split("@")[0], server_info.split("@")[1]);
			    password_entry.set_text(password);
			    password_entry.set_placeholder_text("Password");
                password_entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
                password_entry.set_visibility(false);
			    pack_start(password_entry, false, false, 0);
			    
			    // FIXME: split line.
			    
				Entry port_entry = new Entry();
			    port_entry.set_text(config_file.get_value(server_info, "Port"));
			    port_entry.set_placeholder_text("Port");
			    pack_start(port_entry, false, false, 0);
			    
			    // FIXME: split line.
				ComboBoxText encode_box = new ComboBoxText();
				foreach (string name in parent_window.config.encoding_names) {
					encode_box.append(name, name);
				}
				encode_box.set_active(parent_window.config.encoding_names.index_of(config_file.get_value(server_info, "Encode")));
			    pack_start(encode_box, false, false, 0);
			    
			    ComboBoxText backspace_key_box = new ComboBoxText();
			    foreach (string name in parent_window.config.backspace_key_erase_names) {
			    	backspace_key_box.append(name, parent_window.config.erase_map.get(name));
			    }
			    backspace_key_box.set_active(parent_window.config.backspace_key_erase_names.index_of(config_file.get_value(server_info, "Backspace")));
			    pack_start(backspace_key_box, false, false, 0);
			    
			    ComboBoxText del_key_box = new ComboBoxText();
			    foreach (string name in parent_window.config.del_key_erase_names) {
			    	del_key_box.append(name, parent_window.config.erase_map.get(name));
			    }
			    del_key_box.set_active(parent_window.config.del_key_erase_names.index_of(config_file.get_value(server_info, "Del")));
			    pack_start(del_key_box, false, false, 0);
			
				Entry path_entry = new Entry();
			    path_entry.set_text(config_file.get_value(server_info, "Path"));
			    path_entry.set_placeholder_text("Path");
			    pack_start(path_entry, false, false, 0);
				
				Entry command_entry = new Entry();
			    command_entry.set_text(config_file.get_value(server_info, "Command"));
			    command_entry.set_placeholder_text("Command");
			    pack_start(command_entry, false, false, 0);
                
			    // FIXME: split line.
			    
			    Entry name_entry = new Entry();
			    name_entry.set_text(config_file.get_value(server_info, "Name"));
			    name_entry.set_placeholder_text("Name");
			    pack_start(name_entry, false, false, 0);
                
			    Entry groupname_entry = new Entry();
			    groupname_entry.set_text(config_file.get_value(server_info, "GroupName"));
			    groupname_entry.set_placeholder_text("GroupName");
			    pack_start(groupname_entry, false, false, 0);
			    
			    Temp_TextButton save_button = new Temp_TextButton("Save");
			    pack_start(save_button, false, false, 0);
                
			    save_button.button_release_event.connect((w, e) => {
                        try {
                            // First, remove old server info from config file.
                            if (config_file.has_group(server_info)) {
                                config_file.remove_group(server_info);
                            }
                        } catch (Error e) {
                            error ("%s", e.message);
                        }
                        
                        // Second, add new server info.
			    		add_server(
			    			address_entry.get_text(),
			    			user_entry.get_text(),
			    			password_entry.get_text(),
							port_entry.get_text(),
			    			parent_window.config.encoding_names[encode_box.get_active()],
                            path_entry.get_text(),
                            command_entry.get_text(),
							name_entry.get_text(),
			    			groupname_entry.get_text(),
							parent_window.config.backspace_key_erase_names[backspace_key_box.get_active()],
							parent_window.config.del_key_erase_names[del_key_box.get_active()]
			    			);
			    		
                        if (is_homepage) {
                            show_home_page();
                        } else {
                            show_group_page(group_name);
                        }
                        
			    		return false;
			    	});
                
			} catch (Error e) {
                print("show_edit_server_page error: %s\n", e.message);
			}
            
            show_all();
		}
		
		public void show_search_page(string search_text, string group_name) {
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
                
                // Destroy child after entry.get_text(), otherwise entry.get_text() return random value.
			    Utils.destroy_all_children(this);
                
                Temp_TextButton add_server_button = new Temp_TextButton("Back");
                add_server_button.button_release_event.connect((w, e) => {
                        if (group_name == "") {
                            show_home_page();
                        } else {
                            show_group_page(group_name);
                        }
			        		
                        return false;
                    });
                
                pack_start(add_server_button, false, false, 0);

                var view = get_server_view(true, "");
                    
                TreeIter iter;
                    
                foreach (var ungroup_list in ungroups) {
                    ((Gtk.ListStore) view.model).append(out iter);
                    ((Gtk.ListStore) view.model).set(iter, 0, "%s\n%s".printf(ungroup_list[0], ungroup_list[1]), 1, "go-home");
                }
			    
			    show_all();
			} catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
					print("show_home_page error: %s\n", e.message);
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
        
        public TreeView get_server_view(bool is_homepage, string group_name) {
            var view = new TreeView();
            var scrolledwindow = new ScrolledWindow(null, null);
            view.set_headers_visible(false);
            scrolledwindow.add(view);
            pack_start(scrolledwindow, true, true, 0);
            
            var listmodel = new Gtk.ListStore(4, typeof(string), typeof(string), typeof(string), typeof(string));
            view.set_model(listmodel);

            view.insert_column_with_attributes(-1, "Name", new CellRendererText(), "text", 0);
            
            Gtk.CellRendererPixbuf pixbuf = new Gtk.CellRendererPixbuf();
            Gtk.TreeViewColumn column = new Gtk.TreeViewColumn();
            column.set_title("Details");
            column.pack_start(pixbuf, false);
            column.add_attribute(pixbuf, "icon-name", 1);
            view.append_column(column);
            
            view.row_activated.connect((path, column) => {
                       Gtk.TreeIter activated_iter;
                       if (view.model.get_iter(out activated_iter, path)) {
                           string iter_content;
                           view.model.get(activated_iter, 0, out iter_content);
                           string[] row_content = iter_content.split("\n");
                           if ("@" in row_content[1]) {
                               login_server(row_content[1]);
                           } else {
                               show_group_page(row_content[0]);
                           }
                       }
                });
            
            view.button_press_event.connect((e) => {
                    if (Utils.is_left_button(e)) {
                        Gtk.TreePath? path;
                        Gtk.TreeViewColumn? click_column;
                        bool valid = view.get_path_at_pos((int) e.x, (int) e.y, out path, out click_column, null, null);
                        
                        if (valid) {
                            Gtk.TreeIter activated_iter;
                            if (view.model.get_iter(out activated_iter, path)) {
                                string iter_content;
                                view.model.get(activated_iter, 0, out iter_content);
                                string[] row_content = iter_content.split("\n");
                                if ("@" in row_content[1] && click_column.get_title() == "Details") {
                                    show_edit_server_page(row_content[1], is_homepage, group_name);
                                }
                            }
                        }
                    }
                    
                    return false;
                });
            
            
            return view;
        }
    }
}