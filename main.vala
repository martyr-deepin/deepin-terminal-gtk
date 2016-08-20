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
                            dialog = Widgets.create_running_confirm_dialog(quake_window);
                        } else {
                            dialog = Widgets.create_running_confirm_dialog(window);
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
                quake_window.draw_active_tab_underline(tabbar);
                
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
            
                quake_window.init_event_handler(workspace_manager);
                
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
                Appbar appbar = new Appbar(window, tabbar, workspace_manager);
                var overlay = new Gtk.Overlay();
                
                appbar.set_valign(Gtk.Align.START);
                
                var fullscreen_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                top_box.pack_start(fullscreen_box, false, false, 0);
                
                var spacing_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                spacing_box.set_size_request(-1, Constant.TITLEBAR_HEIGHT);
                fullscreen_box.pack_start(spacing_box, false, false, 0);
                
                box.pack_start(top_box, false, false, 0);
                box.pack_start(workspace_manager, true, true, 0);
                
                appbar.close_window.connect((w) => {
                        window.quit();
                    });
                appbar.quit_fullscreen.connect((w) => {
                        window.toggle_fullscreen();
                    });
            
                window.draw_active_tab_underline(tabbar);
                
                window.init_event_handler(workspace_manager);
                window.window_state_event.connect((w) => {
                        appbar.update_max_button();
                    
                        return false;
                    });
                
                if (!window.have_terminal_at_same_workspace()) {
                    window.set_position(Gtk.WindowPosition.CENTER);
                }

                window.configure_event.connect((w) => {
                        if (window.window_is_fullscreen()) {
                            Utils.remove_all_children(fullscreen_box);
                            appbar.hide();
                            appbar.hide_window_button();
                            window.draw_tabbar_line = false;
                        } else {
                            Gtk.Widget? parent = spacing_box.get_parent();
                            if (parent == null) {
                                fullscreen_box.pack_start(spacing_box, false, false, 0);
                                appbar.show_all();
                                appbar.show_window_button();
                                window.draw_tabbar_line = true;
                            }
                        }
                        
                        return false;
                    });
                
                window.motion_notify_event.connect((w, e) => {
                        if (window.window_is_fullscreen()) {
                            if (e.y_root < window.window_fullscreen_monitor_height) {
                                GLib.Timeout.add(window.window_fullscreen_monitor_timeout, () => {
                                        Gdk.Display gdk_display = Gdk.Display.get_default();
                                        var seat = gdk_display.get_default_seat();
                                        var device = seat.get_pointer();
                    
                                        int pointer_x, pointer_y;
                                        device.get_position(null, out pointer_x, out pointer_y);

                                        if (pointer_y < window.window_fullscreen_response_height) {
                                            appbar.show_all();
                                            window.draw_tabbar_line = true;
                                
                                            window.queue_draw();
                                        } else if (pointer_y > Constant.TITLEBAR_HEIGHT) {
                                            appbar.hide();
                                            window.draw_tabbar_line = false;                                
                                
                                            window.queue_draw();
                                        }
                                        
                                        return false;
                                    });
                            }
                        }
                        
                        return false;
                    });
                
                overlay.add(box);
                overlay.add_overlay(appbar);
			
                window.add_widget(overlay);
                window.show_all();
            }
        }
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