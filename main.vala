/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2017 Deepin, Inc.
 *               2011 ~ 2017 Wang Yong
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

using Gdk;
using Gee;
using Gtk;
using Keymap;
using Vte;
using Widgets;

[DBus (name = "com.deepin.terminal")]
public class TerminalApp : Application {
    public static void on_bus_acquired(DBusConnection conn, TerminalApp app) {
        try {
            conn.register_object("/com/deepin/terminal", app);
        } catch (Error e) {
            stderr.printf("Could not register service\n");
        }
    }

    public void exit() {
        quit();
        window.quit();
    }

    public signal void quit();
}

[DBus (name = "com.deepin.quake_terminal")]
public class QuakeTerminalApp : Application {
    public static void on_bus_acquired(DBusConnection conn, QuakeTerminalApp app) {
        try {
            conn.register_object("/com/deepin/quake_terminal", app);
        } catch (Error e) {
            stderr.printf("Could not register service\n");
        }
    }

    public void show_or_hide() {
        this.quake_window.toggle_quake_window();
    }
}

[DBus (name = "com.deepin.quake_terminal")]
interface QuakeDaemon : Object {
    public abstract void show_or_hide() throws Error;
}


const string GETTEXT_PACKAGE = "deepin-terminal";

public class Application : Object {

    private static bool quake_mode = false;
    private static string? window_mode = null;
    private static string? work_directory = null;
    private static string? load_theme = null;

    // pass_options just for print help information, we need parse -e or -x commands myself.
    [CCode (array_length = false, array_null_terminated = true)]
    public static string[]? pass_options = null;

    public Widgets.QuakeWindow quake_window;
    public Widgets.Window window;
    public WorkspaceManager workspace_manager;
    public static ArrayList<string> commands;
    public static int64 start_time;

    private bool inited = false;
    private static bool version = false;

    public static void main(string[] args) {
        start_time = GLib.get_real_time() / 1000;

        // NOTE: set IBUS_NO_SNOOPER_APPS variable to avoid Ctrl + 5 eat by input method (such as fcitx.);
        Environment.set_variable("IBUS_DISABLE_SNOOPER", "1", true);

        // Set 'NO_AT_BRIDGE' environment variable with 1 to dislable accessibility dbus warning.
        Environment.set_variable("NO_AT_BRIDGE", "1", true);

        Intl.setlocale();
        Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
        Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

        // Need parse -e or -x commands my self, OptionEntry just will got first argument after -e or -x.
        commands = new ArrayList<string>();
        bool find_command_flag = false;
        foreach (string arg in args) {
            if (find_command_flag) {
                commands.add(arg);
            }

            if (arg == "-e" || arg == "-x") {
                find_command_flag = true;
            }
        }

        try {
            string window_mode_description = "%s (normal, maximize, fullscreen)".printf(_("Set the terminal window mode"));

            GLib.OptionEntry[] pass_options = {
                OptionEntry() {
                    long_name="version",
                    short_name=0,
                    flags=0,
                    arg=OptionArg.NONE,
                    arg_data=&version,
                    description=_("Display version"),
                    arg_description=null
                },
                OptionEntry() {
                    long_name="work-directory",
                    short_name='w',
                    flags=0,
                    arg=OptionArg.FILENAME,
                    arg_data=&work_directory,
                    description=_("Set the terminal startup directory"),
                    arg_description=null
                },
                OptionEntry() {
                    long_name="window-mode",
                    short_name='m',
                    flags=0,
                    arg=OptionArg.STRING,
                    arg_data=&window_mode,
                    description=window_mode_description,
                    arg_description=null
                },
                OptionEntry() {
                    long_name="execute",
                    short_name='e',
                    flags=0,
                    arg=OptionArg.STRING_ARRAY,
                    arg_data=&pass_options,
                    description=_("Run a program in the terminal"),
                    arg_description=null
                },
                OptionEntry() {
                    long_name="execute",
                    short_name='x',
                    flags=0,
                    arg=OptionArg.STRING_ARRAY,
                    arg_data=&pass_options,
                    description=_("Run a program in the terminal"),
                    arg_description=null
                },
                OptionEntry() {
                    long_name="quake-mode",
                    short_name='q',
                    flags=0,
                    arg=OptionArg.NONE,
                    arg_data=&quake_mode,
                    description=_("Quake mode"),
                    arg_description=null
                },
                OptionEntry() {
                    long_name="load-theme",
                    short_name='l',
                    flags=0,
                    arg=OptionArg.STRING,
                    arg_data=&load_theme,
                    description=_("Load theme"),
                    arg_description=null
                },
                OptionEntry()
            };

            var opt_context = new OptionContext(_("Deepin Terminal"));
            opt_context.set_summary(_("Deepin Teminal is an advanced terminal emulator with window-splitting, workspaces, remote management, Quake mode and other features."));
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(pass_options, null);
            opt_context.parse(ref args);
        } catch (OptionError e) {
            // Don't print option error, avoid confuse user.
        }

        if (version) {
            stdout.printf("Deepin Terminal %s\n".printf(Constant.VERSION));
            stdout.printf ("Copyright 2011-2017 Deepin, Inc.\n");
        } else {
            Gtk.init(ref args);

            // Just for debug perfermance.
            // Gdk.Window.set_debug_updates(true);

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

    public void run(bool has_start) {
        // Bus.own_name is callback, when application exit will execute `run` function.
        // Use inited variable to avoid application run by Bus.own_name release.
        if (inited) {
            return;
        }
        inited = true;

        if (has_start && quake_mode) {
            try {
                QuakeDaemon daemon = Bus.get_proxy_sync(BusType.SESSION, "com.deepin.quake_terminal", "/com/deepin/quake_terminal");
                daemon.show_or_hide();
            } catch (Error e) {
                stderr.printf("%s\n", e.message);
            }

            Gtk.main_quit();
        } else {
            Utils.load_css_theme(Utils.get_root_path("style.css"));

            Tabbar tabbar = new Tabbar();
            workspace_manager = new WorkspaceManager(tabbar, work_directory);

            if (quake_mode) {
                quake_window = new Widgets.QuakeWindow();
                quake_window.show_window(workspace_manager, tabbar);
                Utils.write_log("Deepin quake terminal start in: %s\n".printf((GLib.get_real_time() / 1000 - Application.start_time).to_string()));
                tabbar.init(workspace_manager, quake_window);
            } else {
                window = new Widgets.Window(window_mode);
                window.set_has_resize_grip(true);

                // Change theme temporary if 'load_theme' option is valid.
                if (load_theme != null) {
                    window.config.load_temp_theme(load_theme);
                }

                window.show_window((TerminalApp) this, workspace_manager, tabbar, has_start);
                Utils.write_log("Deepin terminal start in: %s\n".printf((GLib.get_real_time() / 1000 - Application.start_time).to_string()));
                tabbar.init(workspace_manager, window);
            }

        }
    }
}
