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
using Vte;
using Widgets;
using Menu;
using Utils;

namespace Widgets {
    public class Term : Gtk.ScrolledWindow {
        enum DropTargets {
            URILIST,
            STRING,
            TEXT
        }

        public Terminal term;
        public GLib.Pid child_pid;
        public uint launch_idle_id;
        public string current_dir;
		public bool has_select_all = false;
    
        public signal void change_dir(string dir);
        public signal void highlight_tab();
        
		public int font_size = 0;
        public double zoom_factor = 1.0;

        /* Following strings are used to build RegEx for matching URIs */
        const string USERCHARS = "-[:alnum:]";
        const string USERCHARS_CLASS = "[" + USERCHARS + "]";
        const string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
        const string HOSTCHARS_CLASS = "[-[:alnum:]]";
        const string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
        const string PORT = "(?:\\:[[:digit:]]{1,5})?";
        const string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
        const string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
        const string SCHEME = """(?:news:|telnet:|nntp:|file:\/|https?:|ftps?:|sftp:|webcal:
                                 |irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:
                                 |git\+ssh:|bzr:|bzr\+ssh:|svn:|svn\+ssh:|hg:|mailto:|magnet:)""";

        const string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
        const string URLPATH = "(?:(/" + PATHCHARS_CLASS + "+(?:[(]" + PATHCHARS_CLASS + "*[)])*" + PATHCHARS_CLASS + "*)*" + PATHTERM_CLASS + ")?";

        static const string[] regex_strings = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+"
        };
        
        public bool is_first_term; 
		
		public Menu.Menu menu;
		
        public Gdk.RGBA background_color = Gdk.RGBA();
		public Gdk.RGBA foreground_color = Gdk.RGBA();
        
        public signal void exit();
        
        private bool enter_sz_command = false;
        private string save_file_directory = "";
		
		public WorkspaceManager workspace_manager;
		
		public Term(bool first_term, string[]? commands, string? work_directory, WorkspaceManager manager) {
			workspace_manager = manager;
            is_first_term = first_term;
            
            get_style_context().add_class("scrolledwindow");
            get_vscrollbar().get_style_context().add_class("terminal_scrollbar");
            
			term = new Terminal();
			
            term.child_exited.connect ((t)=> {
                    exit();
                });
            term.destroy.connect((t) => {
                    kill_fg();
                });
            term.realize.connect((t) => {
                    setup_from_config();
					
                    focus_term();
                });
            term.window_title_changed.connect((t) => {
                    string working_directory;
                    string[] spawn_args = {"readlink", "/proc/%i/cwd".printf(child_pid)};
                    try {
                        Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out working_directory);
                    } catch (SpawnError e) {
                        print("Got error when spawn_sync: %s\n", e.message);
                    }
                    
                    if (working_directory.length > 0) {
                        working_directory = working_directory[0:working_directory.length - 1];
                        if (current_dir != working_directory) {
                            change_dir(GLib.Path.get_basename(working_directory));
                            current_dir = working_directory;
                        }

						// Command finish will trigger 'window-title-changed' signal emit.
						// we will notify user if terminal is hide or cursor out of visible area.
						var test = term.get_toplevel();
						if (test != null) {
							if (test.get_type().is_a(typeof(Window)) || test.get_type().is_a(typeof(QuakeWindow))) {
								Gtk.Adjustment vadj = term.get_vadjustment();
								double value = vadj.get_value();
								double page_size = vadj.get_page_size();
								double upper = vadj.get_upper();
								
								// Send notify when out of visible area.
								if (value + page_size < upper) {
									highlight_tab();
								}
							} else {
								highlight_tab();
							}
						}
                    }
                });
            term.key_press_event.connect(on_key_press);
            term.scroll_event.connect(on_scroll);
			term.button_press_event.connect((event) => {
					has_select_all = false;
					
					string? uri = term.match_check_event(event, null);
                
                    switch (event.button) {
                        case Gdk.BUTTON_PRIMARY:
                            if (event.state == Gdk.ModifierType.CONTROL_MASK && uri != null) {
                                try {
                                    Gtk.show_uri (null, (!) uri, Gtk.get_current_event_time ());
                                    return true;
                                } catch (GLib.Error error) {
                                    warning ("Could Not Open link");
                                }
                            }
				    
                            return false;
						case Gdk.BUTTON_SECONDARY:
							// Grab focus terminal first. 
							term.grab_focus();
                            
                            bool in_quake_window = this.get_toplevel().get_type().is_a(typeof(Widgets.QuakeWindow));
                            
                            var menu_content = new List<Menu.MenuItem>();
							if (term.get_has_selection()) {
								menu_content.append(new Menu.MenuItem("copy", "Copy"));
							}
							menu_content.append(new Menu.MenuItem("paste", "Paste"));
							menu_content.append(new Menu.MenuItem("", ""));
                            
                            if (!in_quake_window) {
                                menu_content.append(new Menu.MenuItem("horizontal_split", "Horizontal split"));
                                menu_content.append(new Menu.MenuItem("vertical_split", "Vertical split"));
                                menu_content.append(new Menu.MenuItem("close_window", "Close window"));
                                menu_content.append(new Menu.MenuItem("", ""));
                            }
                            
							menu_content.append(new Menu.MenuItem("new_workspace", "New workspace"));
							menu_content.append(new Menu.MenuItem("", ""));
                            
                            if (!in_quake_window) {
                                menu_content.append(new Menu.MenuItem("fullscreen", "Fullscreen"));
                            }
                            
							menu_content.append(new Menu.MenuItem("search", "Search"));
                            menu_content.append(new Menu.MenuItem("remote_manage", "Connect remote"));
                            menu_content.append(new Menu.MenuItem("", ""));
                            menu_content.append(new Menu.MenuItem("upload_file", "Upload file"));
							menu_content.append(new Menu.MenuItem("download_file", "Download file"));
                            
                            if (!in_quake_window) {
                                menu_content.append(new Menu.MenuItem("", ""));
                                menu_content.append(new Menu.MenuItem("preference", "Preference"));
                            }
							
							menu = new Menu.Menu((int) event.x_root, (int) event.y_root, menu_content);
							menu.click_item.connect(handle_menu_item_click);
							menu.destroy.connect(handle_menu_destroy);
							
							return false;
                    }
					
                    return false;
				});
			
            /* target entries specify what kind of data the terminal widget accepts */
            Gtk.TargetEntry uri_entry = { "text/uri-list", Gtk.TargetFlags.OTHER_APP, DropTargets.URILIST };
            Gtk.TargetEntry string_entry = { "STRING", Gtk.TargetFlags.OTHER_APP, DropTargets.STRING };
            Gtk.TargetEntry text_entry = { "text/plain", Gtk.TargetFlags.OTHER_APP, DropTargets.TEXT };

            Gtk.TargetEntry[] targets = { };
            targets += uri_entry;
            targets += string_entry;
            targets += text_entry;

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
            this.drag_data_received.connect(drag_received);

            /* Make Links Clickable */
            this.clickable(regex_strings);
            
            // NOTE: if terminal start with option '-e', use functional 'launch_command' and don't use function 'launch_shell'.
            // terminal will crash if we launch_command after launch_shell.
            if (commands != null) {
                string program_string = "";
                foreach (string command in commands) {
                    program_string = program_string + " " + command;
                }
                
                launch_command(program_string, work_directory);
            } else {
                launch_shell(work_directory);
            }
            
            set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            add(term);
        }
		
		public void handle_menu_item_click(string item_id) {
			if (workspace_manager.get_type().is_a(typeof(WorkspaceManager))) {
			    switch(item_id) {
			    	case "paste":
			    		term.paste_clipboard();
			    		break;
					case "copy":
						term.copy_clipboard();
						break;
			    	case "search":
						workspace_manager.focus_workspace.search();
			    		break;
					case "horizontal_split":
						workspace_manager.focus_workspace.split_horizontal();
						break;
					case "vertical_split":
						workspace_manager.focus_workspace.split_vertical();
						break;
					case "close_window":
						workspace_manager.focus_workspace.close_focus_term();
						break;
					case "new_workspace":
						workspace_manager.new_workspace_with_current_directory();
						break;
					case "remote_manage":
						workspace_manager.focus_workspace.show_remote_panel(workspace_manager.focus_workspace);
						break;
                    case "upload_file":
                        upload_file();
                        break;
                    case "download_file":
                        download_file();
                        break;
                    case "preference":
                        var preference = new Widgets.Preference((Gtk.Window) this.get_toplevel(), ((Gtk.Window) this.get_toplevel()).get_focus());
                        preference.transient_for_window((Gtk.Window) this.get_toplevel());
                        break;
                        
			    }
			} else {
				print("handle_menu_item_click: impossible here!\n");
			}
			
		}
        
        
        public void upload_file () {
            Gtk.FileChooserAction action = Gtk.FileChooserAction.OPEN;
            var chooser = new Gtk.FileChooserDialog("Open file", null, action);
            chooser.add_button("Cancel", Gtk.ResponseType.CANCEL);
            chooser.set_select_multiple(true);
            chooser.add_button("Open", Gtk.ResponseType.ACCEPT);
            
            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                var file_list = chooser.get_files();
                
                press_ctrl_at();
                GLib.Timeout.add(500, () => {
                        string upload_command = "sz ";
                        foreach (File file in file_list) {
                            upload_command = upload_command + file.get_path() + " ";
                        }
                        upload_command = upload_command + "\n";
                        
                        this.term.feed_child(upload_command, upload_command.length);
                        
                        return false;
                        });
                
            }
            
            chooser.destroy();
        }
        
        public void download_file() {
            Gtk.FileChooserAction action = Gtk.FileChooserAction.SELECT_FOLDER;
            var chooser = new Gtk.FileChooserDialog("Select save directory", null, action);
            chooser.add_button("Cancel", Gtk.ResponseType.CANCEL);
            chooser.add_button("Save", Gtk.ResponseType.ACCEPT);
            
            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                save_file_directory = chooser.get_filename();
                
                press_ctrl_a();
                
                GLib.Timeout.add(100, () => {
                        press_ctrl_k();
                        
                        GLib.Timeout.add(100, () => {
                                string command = "read -e -p \"Type file to download: \" file; sz $file\n";
                                this.term.feed_child(command, command.length);
                                
                                enter_sz_command = true;
                                
                                return false;
                            });
                        
                        return false;
                    });
            }
            
            chooser.destroy();
        }
        
        public void execute_download() {
            // Switch to zssh local directory.
            press_ctrl_at();
            
            GLib.Timeout.add(100, () => {
                    // Switch directory in zssh.
                    string switch_command = "cd %s\n".printf(save_file_directory);
                    this.term.feed_child(switch_command, switch_command.length);
                    
                    // Do rz command to download file.
                    GLib.Timeout.add(100, () => {
                            string download_command = "rz\n";
                            this.term.feed_child(download_command, download_command.length);
                
                            return false;
                        });
                    return false;
                    });
        }
        
        public void press_ctrl_at() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 64;
            event->state = (Gdk.ModifierType) 33554437;
            event->hardware_keycode = (uint16) 11;
            ((Gdk.Event*) event)->put();
        }
        
        public void press_ctrl_k() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 75;
            event->state = (Gdk.ModifierType) 33554437;
            event->hardware_keycode = (uint16) 45;
            ((Gdk.Event*) event)->put();
        }
        
        public void press_ctrl_a() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 97;
            event->state = (Gdk.ModifierType) 33554436;
            event->hardware_keycode = (uint16) 38;
            ((Gdk.Event*) event)->put();
        }

        public void press_ctrl_e() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 69;
            event->state = (Gdk.ModifierType) 33554437;
            event->hardware_keycode = (uint16) 26;
            ((Gdk.Event*) event)->put();
        }
        
		public void handle_menu_destroy() {
			menu = null;
		}
        
        public void focus_term() {
            term.grab_focus();
            if (current_dir != null) {
                change_dir(GLib.Path.get_basename(current_dir));
            }
        }
        
        public bool on_scroll(Gtk.Widget widget, Gdk.EventScroll scroll_event) {
            if ((scroll_event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
				try {
					Widgets.ConfigWindow window = (Widgets.ConfigWindow) term.get_toplevel();
				
					double old_opacity = window.config.config_file.get_double("general", "opacity");
					double new_opacity = old_opacity;
				
					if (scroll_event.delta_y < 0) {
						new_opacity = double.min(double.max(old_opacity + 0.1, 0.2), 1);
					} else if (scroll_event.delta_y > 0) {
						new_opacity = double.min(double.max(old_opacity - 0.1, 0.2), 1);
					}
			
					if (new_opacity != old_opacity) {
						window.config.config_file.set_double("general", "opacity", new_opacity);
						window.config.save();
					
						window.config.update();
					}
                    
                    return true;
				} catch (GLib.KeyFileError e) {
					print("Terminal on_scroll: %s\n", e.message);
				}
            }

            return false;
        }
        
        private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
			try {
                string keyname = Keymap.get_keyevent_name(key_event);
                
			    Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();
			    
			    var copy_key = parent_window.config.config_file.get_string("keybind", "copy_clipboard");
			    if (copy_key != "" && keyname == copy_key) {
			    	term.copy_clipboard();
			    	return true;
			    }
			    
			    var paste_key = parent_window.config.config_file.get_string("keybind", "paste_clipboard");
			    if (paste_key != "" && keyname == paste_key) {
			    	term.paste_clipboard();
			    	return true;
			    }
			    
				var zoom_in_key = parent_window.config.config_file.get_string("keybind", "zoom_in");
			    if (zoom_in_key != "" && keyname == zoom_in_key) {
			    	increment_size();
			    	return true;
			    }
			    
			    var zoom_out_key = parent_window.config.config_file.get_string("keybind", "zoom_out");
			    if (zoom_out_key != "" && keyname == zoom_out_key) {
			    	decrement_size();
			    	return true;
			    }
			    
			    var zoom_reset_key = parent_window.config.config_file.get_string("keybind", "revert_default_size");
			    if (zoom_reset_key != "" && keyname == zoom_reset_key) {
			    	set_default_font_size();
			    	return true;
			    }
			    
                if (keyname == "Enter" || keyname == "Ctrl + m") {
                    if (enter_sz_command) {
                        execute_download();
                        enter_sz_command = false;
                    }
                }
                
                return false;
			} catch (GLib.KeyFileError e) {
				print("Terminal on_key_press: %s\n", e.message);
				
				return false;
			}
        }
		
		public void update_font_info() {
			try {
				Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();
				var font = parent_window.config.config_file.get_string("general", "font");
				Pango.FontDescription current_font = new Pango.FontDescription();
				current_font.set_family(font);
				current_font.set_size((int) (font_size * zoom_factor));
				term.set_font(current_font);
			} catch (GLib.KeyFileError e) {
				print("Terminal update_font_info: %s\n", e.message);
			}
		}

        public void increment_size () {
			if (zoom_factor < 3) {
				zoom_factor += 0.1;
				
				update_font_info();
			}
		}

        public void decrement_size () {
			if (zoom_factor > 0.8) {
				zoom_factor -= 0.1;
				
				update_font_info();
			}
		}

        public void set_default_font_size () {
			zoom_factor = 1.0;
			update_font_info();
		}

        public void drag_received (Gdk.DragContext context, int x, int y,
                                   Gtk.SelectionData selection_data, uint target_type, uint time_) {
            switch (target_type) {
                case DropTargets.URILIST:
                    var uris = selection_data.get_uris ();
                    string path;
                    File file;

                    for (var i = 0; i < uris.length; i++) {
                         file = File.new_for_uri (uris[i]);
                         if ((path = file.get_path ()) != null) {
                             uris[i] = Shell.quote (path) + " ";
                        }
                    }

                    string uris_s = string.joinv ("", uris);
                    this.term.feed_child(uris_s, uris_s.length);

                    break;
                case DropTargets.STRING:
                case DropTargets.TEXT:
                    var data = selection_data.get_text ();

                    if (data != null) {
                        this.term.feed_child(data, data.length);
                    }

                    break;
            }
        }
        
        private void clickable (string[] str) {
            foreach (string exp in str) {
                try {
                    var regex = new GLib.Regex(exp,
											   GLib.RegexCompileFlags.OPTIMIZE |
											   GLib.RegexCompileFlags.MULTILINE,
											   0);
                    int id = term.match_add_gregex(regex, 0);

                    term.match_set_cursor_type (id, Gdk.CursorType.HAND2);
                } catch (GLib.RegexError error) {
                    warning (error.message);
                }
            }
        }

        public void launch_shell(string? dir) {
            string directory;
            if (dir == null) {
                directory = GLib.Environment.get_current_dir();
            } else {
                directory = dir;
            }

            string? shell;
            
            shell = Vte.get_user_shell();
            if (shell == null || shell[0] == '\0') {
                shell = Environment.get_variable("SHELL");
            }
            if (shell == null || shell[0] == '\0') {
                shell = "/bin/sh";
            }
            
            launch_command(shell, directory);
        }
        
        public void launch_command(string command, string? dir) {
            string directory;
            if (dir == null) {
                directory = GLib.Environment.get_current_dir();
            } else {
                directory = dir;
            }
            
            string[] argv;

            try {
                Shell.parse_argv(command, out argv);
            } catch (ShellError e) {
            if (!(e is ShellError.EMPTY_STRING)) {
                warning("Terminal launch_command: %s\n", e.message);
            }
            }
            launch_idle_id = GLib.Idle.add(() => {
                    try {
                        term.spawn_sync(Vte.PtyFlags.DEFAULT,
                                        directory,
                                        argv,
                                        null,
                                        GLib.SpawnFlags.SEARCH_PATH,
                                        null, /* child setup */
                                        out child_pid,
                                        null /* cancellable */);
                    } catch (Error e) {
                        warning("Terminal launch_idle_id: %s\n", e.message);
                    }
                    
                    launch_idle_id = 0;
                    return false;
                });
        }        
        
        public bool try_get_foreground_pid (out int pid) {
            if (this.term.get_pty() == null) {
                pid = -1;
                return false;
            } else {
                int pty_fd = this.term.get_pty().fd;
                int fgpid = Posix.tcgetpgrp(pty_fd);
                
                if (fgpid != this.child_pid && fgpid != -1) {
                    pid = (int) fgpid;
                    return true;
                } else {
                    pid = -1;
                    return false;
                }
            }
        }

        public bool has_foreground_process () {
            return try_get_foreground_pid(null);
        }

        public void kill_fg() {
            int fg_pid;
            if (this.try_get_foreground_pid(out fg_pid)) {
                Posix.kill(fg_pid, Posix.SIGKILL);
            }
        }
		
		public void toggle_select_all() {
			if (has_select_all) {
				term.unselect_all();
			} else {
				term.select_all();
			}
			
			has_select_all = !has_select_all;
		}
		
		public void setup_from_config() {
            try {
                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();
                
                var is_cursor_blink = parent_window.config.config_file.get_boolean("advanced", "cursor_blink_mode");
                if (is_cursor_blink) {
                    term.set_cursor_blink_mode(Vte.CursorBlinkMode.ON);
                } else {
                    term.set_cursor_blink_mode(Vte.CursorBlinkMode.OFF);
                }
                
                var scroll_lines = parent_window.config.config_file.get_integer("advanced", "scroll_line");
                term.set_scrollback_lines(scroll_lines);
				
				var cursor_shape = parent_window.config.config_file.get_string("advanced", "cursor_shape");
				if (cursor_shape == "block") {
					term.set_cursor_shape(Vte.CursorShape.BLOCK);
				} else if (cursor_shape == "ibeam") {
					term.set_cursor_shape(Vte.CursorShape.IBEAM);
				} else if (cursor_shape == "underline") {
					term.set_cursor_shape(Vte.CursorShape.UNDERLINE);
				}
				
				background_color.parse(parent_window.config.config_file.get_string("theme", "background"));
				background_color.alpha = parent_window.config.config_file.get_double("general", "opacity");
				foreground_color.parse(parent_window.config.config_file.get_string("theme", "foreground"));
				var palette = new Gdk.RGBA[16];
				for (int i = 0; i < 16; i++) {
					Gdk.RGBA new_color= Gdk.RGBA();
					new_color.parse(parent_window.config.config_file.get_string("theme", "color_%i".printf(i + 1)));

					palette[i] = new_color;
				}
				term.set_colors(foreground_color, background_color, palette);
				
				var config_size = parent_window.config.config_file.get_integer("general", "font_size");
				font_size = config_size * Pango.SCALE;
				update_font_info();
				
				queue_draw();
            } catch (GLib.KeyFileError e) {
                stdout.printf(e.message);
            }
        }
	}
}