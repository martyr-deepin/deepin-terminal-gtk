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
        public string current_dir;
		public bool has_select_all = false;
    
        public signal void change_dir(string dir);
        
        public int default_size;
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
        public Gdk.RGBA background_color;
        public Gdk.RGBA foreground_color;
        public Gdk.RGBA[] palette;
		
		public Menu.Menu menu;
        
        public signal void exit();
		
        
        public Term(bool first_term, string[]? commands, string? work_directory) {
            is_first_term = first_term;
            
            background_color = Gdk.RGBA();
            background_color.parse("#000000");
            background_color.alpha = 0.8;

            foreground_color = Gdk.RGBA();
            foreground_color.parse("#00FF00");
            
            string[] hex_palette = { "#000000", "#FF6C60", "#A8FF60", "#FFFFCC", "#96CBFE",
                                     "#FF73FE", "#C6C5FE", "#EEEEEE", "#000000", "#FF6C60",
                                     "#A8FF60", "#FFFFB6", "#96CBFE", "#FF73FE", "#C6C5FE",
                                     "#EEEEEE" };

            palette = new Gdk.RGBA[16];

            for (int i = 0; i < hex_palette.length; i++) {
                Gdk.RGBA new_color= Gdk.RGBA();
                new_color.parse(hex_palette[i]);

                palette[i] = new_color;
            }

            term = new Terminal();
            term.child_exited.connect ((t)=> {
                    exit();
                });
            term.destroy.connect((t) => {
                    kill_fg();
                });
            term.realize.connect((t) => {
            
                    term.set_colors(foreground_color, background_color, palette);
                    focus_term();
                });
            term.draw.connect((t) => {
                    Widgets.Window window = (Widgets.Window) term.get_toplevel();
                    background_color.alpha = window.background_opacity;
                    term.set_colors(foreground_color, background_color, palette);
                    
                    return false;
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
							if (test.get_type().is_a(typeof(Window))) {
								Gtk.Adjustment vadj = term.get_vadjustment();
								double value = vadj.get_value();
								double page_size = vadj.get_page_size();
								double upper = vadj.get_upper();
								
								// Send notify when out of visible area.
								if (value + page_size < upper) {
									complete_notify_send();
								}
							} else {
								// Send notify when terminal tab is hidden.
								complete_notify_send();
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
							
							var menu_content = new List<Menu.MenuItem>();
							if (term.get_has_selection()) {
								menu_content.append(new Menu.MenuItem("copy", "Copy"));
							}
							menu_content.append(new Menu.MenuItem("paste", "Paste"));
							menu_content.append(new Menu.MenuItem("", ""));
							menu_content.append(new Menu.MenuItem("horizontal_split", "Horizontal split"));
							menu_content.append(new Menu.MenuItem("vertical_split", "Vertical split"));
							menu_content.append(new Menu.MenuItem("close_terminal", "Close terminal"));
							menu_content.append(new Menu.MenuItem("", ""));
							menu_content.append(new Menu.MenuItem("new_workspace", "New workspace"));
							menu_content.append(new Menu.MenuItem("", ""));
							menu_content.append(new Menu.MenuItem("fullscreen", "Fullscreen"));
							menu_content.append(new Menu.MenuItem("search", "Search"));
							menu_content.append(new Menu.MenuItem("display_hotkey", "Display hotkey"));
							menu_content.append(new Menu.MenuItem("", ""));
							menu_content.append(new Menu.MenuItem("preference", "Preference"));
							
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
            
            if (work_directory != null) {
                active_shell(work_directory);
            } else {
                active_shell();
            }
            
            string program_string = "";
            if (commands != null) {
                foreach (string command in commands) {
                    program_string = program_string.concat(command);
                }
                run_program(program_string);
            }
            
            set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            add(term);
        }
		
		public void handle_menu_item_click(string item_id) {
			var workspace_manager = get_workspace_manager(null);
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
					case "close_terminal":
						workspace_manager.focus_workspace.close_focus_term();
						break;
					case "new_workspace":
						workspace_manager.new_workspace(null, null);
						break;
			    }
			} else {
				print("handle_menu_item_click: impossible here!\n");
			}
			
		}
		
		public WorkspaceManager get_workspace_manager(Container? container) {
			if (container == null) {
				Container window = (Container) term.get_toplevel();
				return get_workspace_manager(window);
			} else {
				if (container.get_type().is_a(typeof(WorkspaceManager))) {
					return (WorkspaceManager) container;
				} else {
					return get_workspace_manager((Container) container.get_children().nth_data(0));
				}
			}
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
                if (scroll_event.direction == Gdk.ScrollDirection.UP) {
                    Widgets.Window window = (Widgets.Window) term.get_toplevel();
                    window.change_opacity(0.1);
                } else if (scroll_event.direction == Gdk.ScrollDirection.DOWN) {
                    Widgets.Window window = (Widgets.Window) term.get_toplevel();
                    window.change_opacity(-0.1);
                }
            }

            return false;
        }
        
        private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            
            if (keyname == "Ctrl + C") {
                term.copy_clipboard();
            } else if (keyname == "Ctrl + V") {
                term.paste_clipboard();
            } else if (keyname == "Ctrl + =") {
                increment_size();
            } else if (keyname == "Ctrl + -") {
                decrement_size();
            } else if (keyname == "Ctrl + 0") {
                set_default_font_size();
            } else {
                return false;
            }
            
            return true;
        }

        public void increment_size () {
            Pango.FontDescription current_font = term.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();
            if (current_font.get_size () > 60000) return;

            zoom_factor += 0.1;
            current_font.set_size ((int) Math.floor (default_size * zoom_factor));
            term.set_font (current_font);
        }

        public void decrement_size () {
            Pango.FontDescription current_font = term.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();
            if (current_font.get_size () < 2048) return;

            zoom_factor -= 0.1;
            current_font.set_size ((int) Math.ceil (default_size * zoom_factor));
            term.set_font (current_font);
        }

        public void set_default_font_size () {
            Pango.FontDescription current_font = term.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();

            zoom_factor = 1.0;
            current_font.set_size (default_size);
            term.set_font (current_font);
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
                    this.term.feed_child (uris_s, uris_s.length);

                    break;
                case DropTargets.STRING:
                case DropTargets.TEXT:
                    var data = selection_data.get_text ();

                    if (data != null) {
                        this.term.feed_child (data, data.length);
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

        public void active_shell(string dir = GLib.Environment.get_current_dir()) {
            string shell = "";
            string?[] envv = null;
            
            if (shell == "") {
                shell = Vte.get_user_shell();
            }
            
            try {
                term.spawn_sync (Vte.PtyFlags.DEFAULT, dir, {shell}, envv, SpawnFlags.SEARCH_PATH, null, out child_pid, null);
            } catch (Error e) {
                warning(e.message);
            }
        }
        
        public void run_program(string program_string) {
            try {
                string[]? program_with_args = null;
                Shell.parse_argv (program_string, out program_with_args);

                term.spawn_sync (Vte.PtyFlags.DEFAULT, null, program_with_args,
                                 null, SpawnFlags.SEARCH_PATH, null, out this.child_pid, null);
            } catch (Error e) {
                warning (e.message);
            }
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
		
		public void complete_notify_send() {
			try {
				string notify_command = "notify-send 'Deepin terminal' 'Command finished, please check.' -i %s".printf(Utils.get_image_path("deepin-terminal.svg"));
				Process.spawn_command_line_async(notify_command);
			} catch (Error e) {
				print("complete_notify_send: error %s\n", e.message);
			}
		}
	}
}