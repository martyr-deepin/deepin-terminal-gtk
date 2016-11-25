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
	public class RemotePanel : BasePanel {
        public Gtk.Box group_page_box;
        public Gtk.ScrolledWindow? group_page_scrolledwindow;
        public KeyFile config_file;
        public int width = Constant.SLIDER_WIDTH;
        public string config_file_path = Utils.get_config_file_path("server-config.conf");
        
        public delegate void UpdatePageAfterEdit();
		
		public RemotePanel(Workspace space, WorkspaceManager manager) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
            
            workspace = space;
			workspace_manager = manager;
            
            config_file = new KeyFile();
            
            focus_widget = ((Gtk.Window) workspace.get_toplevel()).get_focus();
			parent_window = (Widgets.ConfigWindow) workspace.get_toplevel();
            try {
                background_color = Utils.hex_to_rgba(parent_window.config.config_file.get_string("theme", "background"));
            } catch (Error e) {
                print("RemotePanel init: %s\n", e.message);
            }
            
            switcher = new Widgets.Switcher(width);
            
            group_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            set_size_request(width, -1);
            home_page_box.set_size_request(width, -1);
            group_page_box.set_size_request(width, -1);
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
		
        public override void create_home_page() {
			Utils.destroy_all_children(home_page_box);
            home_page_scrolledwindow = null;
            
            HashMap<string, int> groups = new HashMap<string, int>();
			ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
			        
			try {
                load_config();
				
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
                print("RemotePanel config path: %s\n", config_file_path);
                
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print("RemotePanel create_home_page: %s\n", e.message);
				}
			}
			
			if (groups.size > 0 || ungroups.size > 1) {
			    Widgets.SearchEntry search_entry = new Widgets.SearchEntry();
                home_page_box.pack_start(search_entry, false, false, 0);
                
                search_entry.search_entry.activate.connect((entry) => {
                        if (entry.get_text().strip() != "") {
                            show_search_page(entry.get_text(), "", home_page_box);
                        }
                    });
                
                var split_line = new SplitLine(parent_window.is_light_theme());
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
			
            var split_line = new SplitLine(parent_window.is_light_theme());
            home_page_box.pack_start(split_line, false, false, 0);
                
			Widgets.AddButton add_server_button = create_add_server_button();
            add_server_button.margin_left = 16;
            add_server_button.margin_right = 16;
            add_server_button.margin_top = 16;
            add_server_button.margin_bottom = 16;
            home_page_box.pack_start(add_server_button, false, false, 0);
        }
        
        public void login_server(string server_info) {
            load_config();
            
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
                
                string[] server_infos = server_info.split("@");
                                       
                string password = "";
                if (server_info.length > 2) {
                    password = Utils.lookup_password(server_infos[0], server_infos[1], server_infos[2]);
                } else {
                    password = Utils.lookup_password(server_infos[0], server_infos[1]);
                }
                
                ssh_script_content = ssh_script_content.replace("<<USER>>", server_infos[0]);
                ssh_script_content = ssh_script_content.replace("<<SERVER>>", server_infos[1]);
                if (server_infos.length > 2) {
                    ssh_script_content = ssh_script_content.replace("<<PORT>>", server_infos[2]);
                } else {
                    ssh_script_content = ssh_script_content.replace("<<PORT>>", config_file.get_value(server_info, "Port"));
                }
                
                bool use_private_key = true;
                string private_key_file = "";
                try {
                    private_key_file = config_file.get_value(server_info, "PrivateKey");
                    use_private_key = FileUtils.test(private_key_file, FileTest.EXISTS);
                } catch (GLib.KeyFileError e) {
                    use_private_key = false;
                }
                
                if (use_private_key) {
                    ssh_script_content = ssh_script_content.replace("<<PRIVATE_KEY>>", " -i %s".printf(private_key_file));
                    ssh_script_content = ssh_script_content.replace("<<PASSWORD>>", "");
                    ssh_script_content = ssh_script_content.replace("<<AUTHENTICATION>>", "yes");
                } else {
                    ssh_script_content = ssh_script_content.replace("<<PRIVATE_KEY>>", "");
                    ssh_script_content = ssh_script_content.replace("<<PASSWORD>>", password);                        
                    ssh_script_content = ssh_script_content.replace("<<AUTHENTICATION>>", "no");
                }
                
                var path = config_file.get_string(server_info, "Path");
                var command = config_file.get_string(server_info, "Command");
                
                string remote_command = "echo %s &&".printf(_("Welcome to Deepin Terminal, please make sure that rz and sz commands have been installed in the server before right clicking to upload and download files."));
                if (path.strip() != "") {
                    remote_command += "cd %s && ".printf(path);
                }
                if (command.strip() != "") {
                    remote_command += "%s && ".printf(command);
                }
                
                ssh_script_content = ssh_script_content.replace("<<REMOTE_COMMAND>>", remote_command);
                                       
                // Create temporary expect script file, and the file will
                // be delete by itself.
                FileIOStream iostream;
                var tmpfile = File.new_tmp("deepin-terminal-XXXXXX", out iostream);
                OutputStream ostream = iostream.output_stream;
                DataOutputStream dos = new DataOutputStream(ostream);
                dos.put_string(ssh_script_content);
                
                // Enable for debug.
                // print("%s\n", ssh_script_content);
                
                workspace.hide_remote_panel();
                if (focus_widget != null) {
                    focus_widget.grab_focus();
                }

                Term focus_term = workspace_manager.focus_workspace.get_focus_term(workspace_manager.focus_workspace);
                if (focus_term.has_foreground_process()) {
                    workspace_manager.new_workspace_with_current_directory(true);
                }
                
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
								string login_command = "expect -f " + tmpfile.get_path() + "\n";
                                term.expect_file_path = tmpfile.get_path();
								term.term.feed_child(login_command, login_command.length);
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
            
            ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
            
			try {
                load_config();
                
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
            top_box.set_size_request(-1, Constant.REMOTE_PANEL_SEARCHBAR_HEIGHT);
			group_page_box.pack_start(top_box, false, false, 0);
            
			ImageButton back_button = new Widgets.ImageButton("back", true);
            back_button.margin_left = back_button_margin_left;
            back_button.margin_top = back_button_margin_top;
			back_button.clicked.connect((w) => {
					show_home_page(group_page_box);
                });
			top_box.pack_start(back_button, false, false, 0);
            
            var split_line = new SplitLine(parent_window.is_light_theme());
            group_page_box.pack_start(split_line, false, false, 0);
            
			if (ungroups.size > 1) {
			    Widgets.SearchEntry search_entry = new Widgets.SearchEntry();
                top_box.pack_start(search_entry, true, true, 0);
                
                search_entry.search_entry.activate.connect((entry) => {
                        if (entry.get_text().strip() != "") {
                            show_search_page(entry.get_text(), group_name, group_page_box);
                        }
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
            string private_key,
			int port,
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
			    
                load_config();
			    
			    // Use ',' as array-element-separator instead of ';'.
			    config_file.set_list_separator (',');
			    
			    string gname = "%s@%s@%i".printf(user, server_address, port);
			    config_file.set_string(gname, "Name", name);
			    config_file.set_string(gname, "GroupName", group_name);
				config_file.set_string(gname, "Command", command);
                config_file.set_string(gname, "Path", path);
			    config_file.set_string(gname, "Encode", encode);
			    config_file.set_string(gname, "Backspace", backspace);
			    config_file.set_string(gname, "Del", delete);
                config_file.set_string(gname, "PrivateKey", private_key);

                Utils.store_password(user, server_address, port, password);
			    
			    try {
			    	config_file.save_to_file(config_file_path);
                } catch (Error e) {
			    	print("add_server error occur when config_file.save_to_file %s: %s\n", config_file_path, e.message);
			    }
			}
		}
        
        public override void create_search_page(string search_text, string group_name) {
            Utils.destroy_all_children(search_page_box);
            search_page_scrolledwindow = null;

			try {
                load_config();
				
                ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
                
			    foreach (unowned string option in config_file.get_groups ()) {
                    if (group_name == "" || group_name == config_file.get_value(option, "GroupName")) {
                        ArrayList<string> match_list = new ArrayList<string>();
                        match_list.add(option);
                        foreach (string key in config_file.get_keys(option)) {
                            if (key == "Name" || key == "GroupName" || key == "Command" || key == "Path") {
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
                }
                
                var top_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                top_box.set_size_request(-1, Constant.REMOTE_PANEL_SEARCHBAR_HEIGHT);
                search_page_box.pack_start(top_box, false, false, 0);
            
                ImageButton back_button = new Widgets.ImageButton("back", true);
                back_button.margin_left = back_button_margin_left;
                back_button.margin_top = back_button_margin_top;
                back_button.clicked.connect((w) => {
                        if (group_name == "") {
                            show_home_page(search_page_box);
                        } else {
                            show_group_page(group_name, search_page_box, "scroll_to_left");
                        }
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
                    print("RemotePanel create_search_page: %s\n", e.message);
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
            load_config();
            
            var remote_server_dialog = new Widgets.RemoteServerDialog(parent_window, this, server_info, config_file);
            remote_server_dialog.transient_for_window(parent_window);
            remote_server_dialog.delete_server.connect((server, address, username) => {
                    try {
                        // First, remove old server info from config file.
                        if (config_file.has_group(server_info)) {
                            config_file.remove_group(server_info);
                            config_file.save_to_file(config_file_path);
                        }
                        
                        func();
                    } catch (Error e) {
                        error ("%s", e.message);
                    }
                });
            remote_server_dialog.edit_server.connect((
                server, address, username, password, private_key, port, 
                encode, path, command, nickname, groupname, 
                backspace_key, delete_key) => {
                                                         try {
                                                             // First, remove old server info from config file.
                                                             if (config_file.has_group(server_info)) {
                                                                 config_file.remove_group(server_info);
                                                                 config_file.save_to_file(config_file_path);
                                                             }
                                                      
                                                             // Second, add new server info.
                                                             add_server(address, username, password, private_key, port, encode, path, 
                                                                        command, nickname, groupname, backspace_key, delete_key);
                                                  
                                                             func();
                                                      
                                                             remote_server_dialog.destroy();
                                                         } catch (Error e) {
                                                             error ("%s", e.message);
                                                         }
                                              });
                                    
            remote_server_dialog.show_all();
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
        
        public Widgets.AddButton create_add_server_button() {
			Widgets.AddButton add_server_button = new Widgets.AddButton(parent_window.is_light_theme(), _("Add server"));
			add_server_button.clicked.connect((w) => {
                    var remote_server_dialog = new Widgets.RemoteServerDialog(parent_window, this);
                    remote_server_dialog.transient_for_window(parent_window);
                    remote_server_dialog.add_server.connect((server, address, username, password, private_key, port, encode, path, command, nickname, groupname, backspace_key, delete_key) => {
                            add_server(address, username, password, private_key, port, encode, path, command, nickname, groupname, backspace_key, delete_key);
                            update_home_page();
                            remote_server_dialog.destroy();
                        });
                    remote_server_dialog.show_all();
                });

            return add_server_button;
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
    }
}