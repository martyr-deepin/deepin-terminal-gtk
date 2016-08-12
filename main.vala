using Gtk;
using Gdk;
using Vte;
using Widgets;
using Keymap;

[DBus (name = "com.deepin.terminal")]
public class TerminalApp : Application {
    public static void on_bus_acquired(DBusConnection conn, TerminalApp app) {
        try {
            conn.register_object("/com/deepin/terminal", app);
        } catch (IOError e) {
            stderr.printf("Could not register service\n");
        }
    }
}

[DBus (name = "com.deepin.quake_terminal")]
public class QuakeTerminalApp : Application {
    public static void on_bus_acquired(DBusConnection conn, QuakeTerminalApp app) {
        try {
            conn.register_object("/com/deepin/quake_terminal", app);
        } catch (IOError e) {
            stderr.printf("Could not register service\n");
        }
    }
    
    public void show_or_hide() {
        this.window.toggle_quake_window();
    }
}

[DBus (name = "com.deepin.quake_terminal")]
interface QuakeDaemon : Object {
    public abstract void show_or_hide() throws IOError;
}


public class Application : Object {
    public Widgets.Window window;
    public WorkspaceManager workspace_manager;
	public HotkeyPreview hotkey_preview;
    
	private static bool version = false;
	private static bool quake_mode = false;
	private static string? work_directory = null;
    
    /* command_e (-e) is used for running commands independently (not inside a shell) */
    [CCode (array_length = false, array_null_terminated = true)]
	private static string[]? commands = null;
    private static string title = null;
	
	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "Print version info and exit", null },
		{ "work-directory", 'w', 0, OptionArg.FILENAME, ref work_directory, "Set shell working directory", "DIRECTORY" },
		{ "quake-mode", 0, 0, OptionArg.NONE, ref quake_mode, "Quake mode", null },
        { "execute", 'e', 0, OptionArg.STRING_ARRAY, ref commands, "Run a program in terminal", "" },
		{ "execute", 'x', 0, OptionArg.STRING_ARRAY, ref commands, "Same as -e", "" },
		{ "execute", 'T', 0, OptionArg.STRING_ARRAY, ref title, "Title, just for compliation", "" },
        
		// list terminator
		{ null }
	};
    
    public void run(bool has_start) {
        if (has_start && quake_mode) {
            try {
                QuakeDaemon daemon = Bus.get_proxy_sync(BusType.SESSION, "com.deepin.quake_terminal", "/com/deepin/quake_terminal");
                daemon.show_or_hide();
            } catch (IOError e) {
                stderr.printf("%s\n", e.message);
            }
            
            Gtk.main_quit();
        } else {
            Utils.load_css_theme(Utils.get_root_path("style.css"));
            
            Tabbar tabbar = new Tabbar(quake_mode);
            Appbar appbar = new Appbar(tabbar, quake_mode, this);
            workspace_manager = new WorkspaceManager(appbar.tabbar, commands, work_directory); 
            
            appbar.tabbar.press_tab.connect((t, tab_index, tab_id) => {
					appbar.tabbar.unhighlight_tab(tab_id);
					workspace_manager.switch_workspace(tab_id);
                });
            appbar.tabbar.close_tab.connect((t, tab_index, tab_id) => {
                    Workspace focus_workspace = workspace_manager.workspace_map.get(tab_id);
                    if (focus_workspace.has_active_term()) {
                        ConfirmDialog dialog = new ConfirmDialog(
                            "Terminal still has running programs. Are you sure you want to quit?",
                            window);
                        dialog.confirm.connect((d) => {
                                appbar.tabbar.destroy_tab(tab_index);
                                workspace_manager.remove_workspace(tab_id);
                            });
                    } else {
                        appbar.tabbar.destroy_tab(tab_index);
                        workspace_manager.remove_workspace(tab_id);
                    }
                });
            appbar.tabbar.new_tab.connect((t) => {
                    workspace_manager.new_workspace_with_current_directory();
                });
            appbar.close_button.button_release_event.connect((w, e) => {
                    quit();
                    
                    return false;
                });
            
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            
            window = new Widgets.Window(quake_mode);
			tabbar.draw_active_tab_underline.connect((t, x, width) => {
					int offset_x, offset_y;
					tabbar.translate_coordinates(window, 0, 0, out offset_x, out offset_y);
					
					window.active_tab_underline_x = x + offset_x;
					window.active_tab_underline_width = width;
					
					window.queue_draw();
				});
            
            window.destroy.connect((t) => {
                    quit();
                });
            window.window_state_event.connect((w) => {
                    appbar.update_max_button();
                    
                    return false;
                });
            window.key_press_event.connect(on_key_press);
			window.key_release_event.connect(on_key_release);
            
            if (!has_start) {
                window.set_position(Gtk.WindowPosition.CENTER);
            }
            
            if (quake_mode) {
				box.pack_start(workspace_manager, true, true, 0);
                Widgets.EventBox event_box = new Widgets.EventBox();
                event_box.add(tabbar);
                box.pack_start(event_box, false, false, 0);
                
                // First focus terminal after show quake terminal.
                // Sometimes, some popup window (like wine program's popup notify window) will grab focus,
                // so call window.present to make terminal get focus.
                window.show.connect((t) => {
                        window.present();
                    });
            } else {
				box.pack_start(appbar, false, false, 0);
				box.pack_start(workspace_manager, true, true, 0);
            }
			
			
			// window.add(box);
			window.add_widget(box);
			window.show_all();
        }
    }
    
    public void quit() {
        if (workspace_manager.has_active_term()) {
            ConfirmDialog dialog = new ConfirmDialog(
                "Terminal still has running programs. Are you sure you want to quit?",
                window);
            dialog.confirm.connect((d) => {
                    Gtk.main_quit();
                });
        } else {
            Gtk.main_quit();
        }
    }
    
    private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
		try {
            string keyname = Keymap.get_keyevent_name(key_event);
            string[] ctrl_num_keys = {"Ctrl + 1", "Ctrl + 2", "Ctrl + 3", "Ctrl + 4", "Ctrl + 5", "Ctrl + 6", "Ctrl + 7", "Ctrl + 8", "Ctrl + 9"};
		    
			var search_key = window.config.config_file.get_string("keybind", "search");
		    if (search_key != "" && keyname == search_key) {
		    	workspace_manager.focus_workspace.search();
		    	return true;
		    }
		    
		    var new_workspace_key = window.config.config_file.get_string("keybind", "new_workspace");
		    if (new_workspace_key != "" && keyname == new_workspace_key) {
				workspace_manager.new_workspace_with_current_directory();
				return true;
		    }
		    
		    var close_workspace_key = window.config.config_file.get_string("keybind", "close_workspace");
		    if (close_workspace_key != "" && keyname == close_workspace_key) {
		    	workspace_manager.tabbar.close_current_tab();
		    	return true;
		    }
		    	
		    var next_workspace_key = window.config.config_file.get_string("keybind", "next_workspace");
		    if (next_workspace_key != "" && keyname == next_workspace_key) {
		    	workspace_manager.tabbar.select_next_tab();
		    	return true;
		    }
		    	
		    var previous_workspace_key = window.config.config_file.get_string("keybind", "previous_workspace");
		    if (previous_workspace_key != "" && keyname == previous_workspace_key) {
		    	workspace_manager.tabbar.select_previous_tab();
		    	return true;
		    }
		    
		    var split_vertically_key = window.config.config_file.get_string("keybind", "split_vertically");
		    if (split_vertically_key != "" && keyname == split_vertically_key) {
		    	workspace_manager.focus_workspace.split_vertical();
		    	return true;
		    }
		    
		    var split_horizontally_key = window.config.config_file.get_string("keybind", "split_horizontally");
		    if (split_horizontally_key != "" && keyname == split_horizontally_key) {
		    	workspace_manager.focus_workspace.split_horizontal();
		    	return true;
		    }
		    
		    var select_up_window_key = window.config.config_file.get_string("keybind", "select_up_window");
		    if (select_up_window_key != "" && keyname == select_up_window_key) {
		    	workspace_manager.focus_workspace.select_up_window();
		    	return true;
		    }
		    
		    var select_down_window_key = window.config.config_file.get_string("keybind", "select_down_window");
		    if (select_down_window_key != "" && keyname == select_down_window_key) {
		    	workspace_manager.focus_workspace.select_down_window();
		    	return true;
		    }
		    
		    var select_left_window_key = window.config.config_file.get_string("keybind", "select_left_window");
		    if (select_left_window_key != "" && keyname == select_left_window_key) {
		    	workspace_manager.focus_workspace.select_left_window();
		    	return true;
		    }
		    
		    var select_right_window_key = window.config.config_file.get_string("keybind", "select_right_window");
		    if (select_right_window_key != "" && keyname == select_right_window_key) {
		    	workspace_manager.focus_workspace.select_right_window();
		    	return true;
		    }
		    
		    var close_window_key = window.config.config_file.get_string("keybind", "close_window");
		    if (close_window_key != "" && keyname == close_window_key) {
		    	workspace_manager.focus_workspace.close_focus_term();
		    	return true;
		    }
		    
		    var close_other_windows_key = window.config.config_file.get_string("keybind", "close_other_windows");
		    if (close_other_windows_key != "" && keyname == close_other_windows_key) {
		    	workspace_manager.focus_workspace.close_other_terms();
		    	return true;
		    }
		    
		    var toggle_fullscreen_key = window.config.config_file.get_string("keybind", "toggle_fullscreen");
		    if (toggle_fullscreen_key != "" && keyname == toggle_fullscreen_key) {
		    	if (!quake_mode) {
		    		window.toggle_fullscreen();
		    	}
		    	return true;
		    }
		    
		    var show_helper_window_key = window.config.config_file.get_string("keybind", "show_helper_window");
		    if (show_helper_window_key != "" && keyname == show_helper_window_key) {
		    	if (hotkey_preview == null) {
		    		hotkey_preview = new HotkeyPreview(quake_mode);
		    	}
		    	return true;
		    }
		    
		    var show_remote_panel_key = window.config.config_file.get_string("keybind", "show_remote_panel");
		    if (show_remote_panel_key != "" && keyname == show_remote_panel_key) {
		    	workspace_manager.focus_workspace.toggle_remote_panel(workspace_manager.focus_workspace);
		    	return true;
		    }
		    
		    var select_all_key = window.config.config_file.get_string("keybind", "select_all");
		    if (select_all_key != "" && keyname == select_all_key) {
		    	workspace_manager.focus_workspace.toggle_select_all();
		    	return true;
		    }
		    
		    if (keyname in ctrl_num_keys) {
                workspace_manager.switch_workspace_with_index(int.parse(Keymap.get_key_name(key_event.keyval)));
		    	return true;
            }
            
            return false;
		} catch (GLib.KeyFileError e) {
			print(e.message);
			
			return false;
		}
    }
	
	private bool on_key_release(Gtk.Widget widget, Gdk.EventKey key_event) {
		if (Keymap.is_no_key_press(key_event)) {
			if (hotkey_preview != null) {
				hotkey_preview.destroy();
				hotkey_preview = null;
			}
		}
		
		return false;
	}
    
    public static void main(string[] args) {
        // NOTE: Parse option '-e' or '-x' by myself.
        // OptionContext's function always lost argument after option '-e' or '-x'.
        string[] argv;
        string command = "";
        foreach (string a in args[1:args.length]) {
            command = command + " " + a;
        }

        try {
            Shell.parse_argv(command, out argv);
        } catch (ShellError e) {
            warning(e.message);
        }
        bool start_parse_command = false;
        string user_command = "";
        foreach (string arg in argv) {
            if (arg == "-e" || arg == "-x") {
                start_parse_command = true;
            } else if (arg.has_prefix("-")) {
                if (start_parse_command) {
                    start_parse_command = false;
                }
            } else {
                if (start_parse_command) {
                    user_command = user_command + " " + arg;
                }
            }
            
        }
        
        
        try {
			var opt_context = new OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		} catch (OptionError e) {
			stdout.printf ("error: %s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
		}
        
        // User 'user_command' instead OptionContext's 'commands'.
        try {
            Shell.parse_argv(user_command, out commands);
        } catch (ShellError e) {
            warning(e.message);
        }
        
        if (version) {
			stdout.printf("Deepin Terminal 2.0\n");
        } else {
            Gtk.init(ref args);
            
            if (quake_mode) {
                QuakeTerminalApp app = new QuakeTerminalApp();
                Bus.own_name(BusType.SESSION,
                             "com.deepin.quake_terminal",
                             BusNameOwnerFlags.NONE,
                             ((con) => {QuakeTerminalApp.on_bus_acquired(con, app);}),
                             () => {app.run(false);},
                             () => {app.run(true);});
            } else {
                TerminalApp app = new TerminalApp();
                Bus.own_name(BusType.SESSION,
                             "com.deepin.terminal",
                             BusNameOwnerFlags.NONE,
                             ((con) => {TerminalApp.on_bus_acquired(con, app);}),
                             () => {app.run(false);},
                             () => {app.run(true);});
            }
            
            Gtk.main();
        }
    }
}