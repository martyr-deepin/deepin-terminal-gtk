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
using Gdk;
using Vte;
using Widgets;
using Keymap;
using Wnck;

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
        this.quake_window.toggle_quake_window();
    }
}

[DBus (name = "com.deepin.quake_terminal")]
interface QuakeDaemon : Object {
    public abstract void show_or_hide() throws IOError;
}


public class Application : Object {
    public Widgets.Window window;
    public Widgets.QuakeWindow quake_window;
    public WorkspaceManager workspace_manager;
    
    public string start_path;
    
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
    
    public void run(string path, bool has_start) {
        if (has_start && quake_mode) {
            try {
                QuakeDaemon daemon = Bus.get_proxy_sync(BusType.SESSION, "com.deepin.quake_terminal", "/com/deepin/quake_terminal");
                daemon.show_or_hide();
            } catch (IOError e) {
                stderr.printf("%s\n", e.message);
            }
            
            Gtk.main_quit();
        } else {
            start_path = path;
            Utils.load_css_theme(Utils.get_root_path("style.css"));
            
            Tabbar tabbar = new Tabbar();
            workspace_manager = new WorkspaceManager(tabbar, commands, work_directory); 
            
            tabbar.press_tab.connect((t, tab_index, tab_id) => {
					tabbar.unhighlight_tab(tab_id);
					workspace_manager.switch_workspace(tab_id);
                });
            tabbar.close_tab.connect((t, tab_index, tab_id) => {
                    Widgets.Workspace focus_workspace = workspace_manager.workspace_map.get(tab_id);
                    if (focus_workspace.has_active_term()) {
                        ConfirmDialog dialog;
                        if (quake_mode) {
                            dialog = new ConfirmDialog();
                            dialog.transient_for_window(quake_window);
                        } else {
                            dialog = new ConfirmDialog();
                            dialog.transient_for_window(window);
                        }
                        dialog.confirm.connect((d) => {
                                tabbar.destroy_tab(tab_index);
                                workspace_manager.remove_workspace(tab_id);
                            });
                    } else {
                        tabbar.destroy_tab(tab_index);
                        workspace_manager.remove_workspace(tab_id);
                    }
                });
            tabbar.new_tab.connect((t) => {
                    workspace_manager.new_workspace_with_current_directory();
                });
            
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            Box top_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            Gdk.RGBA background_color = Gdk.RGBA();
            
            if (quake_mode) {
                quake_window = new Widgets.QuakeWindow();
                tabbar.draw_active_tab_underline.connect((t, x, width) => {
                        int offset_x, offset_y;
                        tabbar.translate_coordinates(quake_window, 0, 0, out offset_x, out offset_y);
					
                        quake_window.active_tab_underline_x = x + offset_x;
                        quake_window.active_tab_underline_width = width;
					
                        quake_window.queue_draw();
                    });
                
                top_box.draw.connect((w, cr) => {
                        Gtk.Allocation rect;
                        w.get_allocation(out rect);
                        
                        try {
                            background_color.parse(quake_window.config.config_file.get_string("theme", "background"));
                            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, quake_window.config.config_file.get_double("general", "opacity"));
                            Draw.draw_rectangle(cr, 0, 0, rect.width, Constant.TITLEBAR_HEIGHT);
                        } catch (Error e) {
                            print("Main quake mode: %s\n", e.message);
                        }
                    
                        Utils.propagate_draw(top_box, cr);
                        
                        return true;
                    });
            
            
                quake_window.delete_event.connect((w) => {
                        quit();
                        
                        return true;
                    });
                quake_window.destroy.connect((t) => {
                        quit();
                    });
                quake_window.key_press_event.connect((w, e) => {
                        return on_key_press(w, e);
                    });
                
                box.pack_start(workspace_manager, true, true, 0);
                Widgets.EventBox event_box = new Widgets.EventBox();
                top_box.pack_start(tabbar, true, true, 0);
                event_box.add(top_box);
                box.pack_start(event_box, false, false, 0);
                
                // First focus terminal after show quake terminal.
                // Sometimes, some popup window (like wine program's popup notify window) will grab focus,
                // so call window.present to make terminal get focus.
                quake_window.show.connect((t) => {
                        quake_window.present();
                    });
                
                quake_window.add_widget(box);
                quake_window.show_all();
            } else {
                window = new Widgets.Window();
                Appbar appbar = new Appbar(tabbar, this, workspace_manager);
                appbar.close_button.button_release_event.connect((w, e) => {
                        quit();
                    
                        return false;
                    });
            
                top_box.draw.connect((w, cr) => {
                        Gtk.Allocation rect;
                        w.get_allocation(out rect);
                        
                        try {
                            background_color.parse(window.config.config_file.get_string("theme", "background"));
                            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
                            Draw.draw_rectangle(cr, 0, 0, rect.width, Constant.TITLEBAR_HEIGHT);
                        } catch (Error e) {
                            print("Main window: %s\n", e.message);
                        }
                    
                        Utils.propagate_draw(top_box, cr);

                        return true;
                    });
            
                tabbar.draw_active_tab_underline.connect((t, x, width) => {
                        int offset_x, offset_y;
                        tabbar.translate_coordinates(window, 0, 0, out offset_x, out offset_y);
					
                        window.active_tab_underline_x = x + offset_x;
                        window.active_tab_underline_width = width;
					
                        window.queue_draw();
                    });
            
                window.delete_event.connect((w) => {
                        quit();
                        
                        return true;
                    });
                window.destroy.connect((t) => {
                        quit();
                    });
                window.window_state_event.connect((w) => {
                        appbar.update_max_button();
                    
                        return false;
                    });
                window.key_press_event.connect((w, e) => {
                        return on_key_press(w, e);
                    });
                
                window.configure_event.connect((w) => {
                        workspace_manager.focus_workspace.remove_remote_panel();
                        
                        return false;
                    });
                
                if (!have_terminal_at_same_workspace()) {
                    window.set_position(Gtk.WindowPosition.CENTER);
                }
            
                top_box.pack_start(appbar, true, true, 0);
                box.pack_start(top_box, false, false, 0);
                box.pack_start(workspace_manager, true, true, 0);
			
                window.add_widget(box);
                window.show_all();
            }
        }
    }
    
    public bool have_terminal_at_same_workspace() {
        var screen = Wnck.Screen.get_default();
        screen.force_update();
        
        var active_workspace = screen.get_active_workspace();
        foreach (Wnck.Window window in screen.get_windows()) {
            var workspace = window.get_workspace();
            if (workspace.get_number() == active_workspace.get_number()) {
                if (window.get_name() == "deepin-terminal") {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    public void quit() {
        if (workspace_manager.has_active_term()) {
            ConfirmDialog dialog = new ConfirmDialog();
            dialog.transient_for_window(window);
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
            
            KeyFile config_file;
            if (quake_mode) {
                config_file = quake_window.config.config_file;
            } else {
                config_file = window.config.config_file;
            }
		    
            var search_key = config_file.get_string("keybind", "search");
		    if (search_key != "" && keyname == search_key) {
		    	workspace_manager.focus_workspace.search();
		    	return true;
		    }
		    
		    var new_workspace_key = config_file.get_string("keybind", "new_workspace");
		    if (new_workspace_key != "" && keyname == new_workspace_key) {
				workspace_manager.new_workspace_with_current_directory();
				return true;
		    }
		    
		    var close_workspace_key = config_file.get_string("keybind", "close_workspace");
		    if (close_workspace_key != "" && keyname == close_workspace_key) {
		    	workspace_manager.tabbar.close_current_tab();
		    	return true;
		    }
		    	
		    var next_workspace_key = config_file.get_string("keybind", "next_workspace");
		    if (next_workspace_key != "" && keyname == next_workspace_key) {
		    	workspace_manager.tabbar.select_next_tab();
		    	return true;
		    }
		    	
		    var previous_workspace_key = config_file.get_string("keybind", "previous_workspace");
		    if (previous_workspace_key != "" && keyname == previous_workspace_key) {
		    	workspace_manager.tabbar.select_previous_tab();
		    	return true;
		    }
		    
		    var split_vertically_key = config_file.get_string("keybind", "split_vertically");
		    if (split_vertically_key != "" && keyname == split_vertically_key) {
		    	workspace_manager.focus_workspace.split_vertical();
		    	return true;
		    }
		    
		    var split_horizontally_key = config_file.get_string("keybind", "split_horizontally");
		    if (split_horizontally_key != "" && keyname == split_horizontally_key) {
		    	workspace_manager.focus_workspace.split_horizontal();
		    	return true;
		    }
		    
		    var select_up_window_key = config_file.get_string("keybind", "select_up_window");
		    if (select_up_window_key != "" && keyname == select_up_window_key) {
		    	workspace_manager.focus_workspace.select_up_window();
		    	return true;
		    }
		    
		    var select_down_window_key = config_file.get_string("keybind", "select_down_window");
		    if (select_down_window_key != "" && keyname == select_down_window_key) {
		    	workspace_manager.focus_workspace.select_down_window();
		    	return true;
		    }
		    
		    var select_left_window_key = config_file.get_string("keybind", "select_left_window");
		    if (select_left_window_key != "" && keyname == select_left_window_key) {
		    	workspace_manager.focus_workspace.select_left_window();
		    	return true;
		    }
		    
		    var select_right_window_key = config_file.get_string("keybind", "select_right_window");
		    if (select_right_window_key != "" && keyname == select_right_window_key) {
		    	workspace_manager.focus_workspace.select_right_window();
		    	return true;
		    }
		    
		    var close_window_key = config_file.get_string("keybind", "close_window");
		    if (close_window_key != "" && keyname == close_window_key) {
		    	workspace_manager.focus_workspace.close_focus_term();
		    	return true;
		    }
		    
		    var close_other_windows_key = config_file.get_string("keybind", "close_other_windows");
		    if (close_other_windows_key != "" && keyname == close_other_windows_key) {
		    	workspace_manager.focus_workspace.close_other_terms();
		    	return true;
		    }
		    
		    var toggle_fullscreen_key = config_file.get_string("keybind", "toggle_fullscreen");
		    if (toggle_fullscreen_key != "" && keyname == toggle_fullscreen_key) {
		    	if (!quake_mode) {
		    		window.toggle_fullscreen();
		    	}
		    	return true;
		    }
		    
		    var show_helper_window_key = config_file.get_string("keybind", "show_helper_window");
		    if (show_helper_window_key != "" && keyname == show_helper_window_key) {
		    	return true;
		    }
		    
		    var show_remote_panel_key = config_file.get_string("keybind", "show_remote_panel");
		    if (show_remote_panel_key != "" && keyname == show_remote_panel_key) {
		    	workspace_manager.focus_workspace.toggle_remote_panel(workspace_manager.focus_workspace);
		    	return true;
		    }
		    
		    var select_all_key = config_file.get_string("keybind", "select_all");
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
			print("Main on_key_press: %s\n", e.message);
			
			return false;
		}
    }
	
    public static void main(string[] args) {
        // NOTE: Parse option '-e' or '-x' by myself.
        // OptionContext's function always lost argument after option '-e' or '-x'.
        string[] argv;
        string command = "";

        var start_path = GLib.File.new_for_path(args[0]).get_path();
        
        foreach (string a in args[1:args.length]) {
            command = command + " " + a;
        }

        try {
            Shell.parse_argv(command, out argv);
        } catch (ShellError e) {
            if (!(e is ShellError.EMPTY_STRING)) {
                warning("Main main: %s\n", e.message);
            }
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
            if (!(e is ShellError.EMPTY_STRING)) {
                warning("Main main: %s\n", e.message);
            }
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
                             () => {app.run(start_path, false);},
                             () => {app.run(start_path, true);});
            } else {
                TerminalApp app = new TerminalApp();
                Bus.own_name(BusType.SESSION,
                             "com.deepin.terminal",
                             BusNameOwnerFlags.NONE,
                             ((con) => {TerminalApp.on_bus_acquired(con, app);}),
                             () => {app.run(start_path, false);},
                             () => {app.run(start_path, true);});
            }
            
            Gtk.main();
        }
    }
}