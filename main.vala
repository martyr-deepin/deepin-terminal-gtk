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
            
            Tabbar tabbar = new Tabbar();
            Appbar appbar = new Appbar(tabbar, quake_mode, this);
            workspace_manager = new WorkspaceManager(appbar.tabbar, commands, work_directory); 
            
            appbar.tabbar.press_tab.connect((t, tab_index, tab_id) => {
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
                    workspace_manager.new_workspace(null, null);
                });
            appbar.close_button.button_press_event.connect((w, e) => {
                    quit();
                    
                    return false;
                });
            
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            
            window = new Widgets.Window(quake_mode);
            
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
            
            box.pack_start(workspace_manager, true, true, 0);
            if (quake_mode) {
                Widgets.EventBox event_box = new Widgets.EventBox();
                event_box.add(tabbar);
                box.pack_start(event_box, false, false, 0);
                
                // First focus terminal after show quake terminal.
                // Sometimes, some popup window (like wine program's popup notify window) will grab focus,
                // so call window.present to make terminal get focus.
                window.show.connect((t) => {
                        window.present();
                    });
            }
            
            window.set_titlebar(appbar);
            window.add(box);
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
        string keyname = Keymap.get_keyevent_name(key_event);
        string[] ctrl_num_keys = {"Ctrl + 1", "Ctrl + 2", "Ctrl + 3", "Ctrl + 4", "Ctrl + 5", "Ctrl + 6", "Ctrl + 7", "Ctrl + 8", "Ctrl + 9"};
        
        if (keyname == "Ctrl + T") {
            workspace_manager.new_workspace(null, null);
        } else if (keyname == "Ctrl + W") {
            workspace_manager.tabbar.close_current_tab();
        } else if (keyname == "Ctrl + Tab") {
            workspace_manager.tabbar.select_next_tab();
        } else if (keyname == "Ctrl + ISO_Left_Tab") {
            workspace_manager.tabbar.select_prev_tab();
        } else if (keyname == "Ctrl + q") {
            workspace_manager.focus_workspace.close_focus_term();
        } else if (keyname == "Ctrl + Q") {
			workspace_manager.focus_workspace.close_other_terms();
		} else if (keyname in ctrl_num_keys) {
            workspace_manager.switch_workspace_with_index(int.parse(Keymap.get_key_name(key_event.keyval)));
        } else if (keyname == "F11") {
			if (!quake_mode) {
				window.toggle_fullscreen();
			}
        } else if (keyname == "Ctrl + F") {
            workspace_manager.focus_workspace.search();
        } else if (keyname == "Ctrl + S") {
			workspace_manager.focus_workspace.toggle_remote_panel(workspace_manager.focus_workspace);
		} else if (keyname == "Ctrl + A") {
			workspace_manager.focus_workspace.toggle_select_all();
		} else if (keyname == "Ctrl + h") {
            workspace_manager.focus_workspace.split_horizontal();
        } else if (keyname == "Ctrl + H") {
            workspace_manager.focus_workspace.split_vertical();
        } else if (keyname == "Alt + h") {
            workspace_manager.focus_workspace.focus_left_terminal();
        } else if (keyname == "Alt + l") {
            workspace_manager.focus_workspace.focus_right_terminal();
        } else if (keyname == "Alt + j") {
            workspace_manager.focus_workspace.focus_down_terminal();
        } else if (keyname == "Alt + k") {
            workspace_manager.focus_workspace.focus_up_terminal();
        } else if (keyname == "Ctrl + ?") {
			if (hotkey_preview == null) {
				hotkey_preview = new HotkeyPreview(quake_mode);
			}
		} else {
            return false;
        }
        
        return true;
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
        try {
			var opt_context = new OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		} catch (OptionError e) {
			stdout.printf ("error: %s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
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