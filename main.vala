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

using Gdk;
using Gtk;
using Keymap;
using Vte;
using Widgets;

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


const string GETTEXT_PACKAGE = "deepin-terminal"; 

public class Application : Object {
    
	private static bool quake_mode = false;
	private static string? work_directory = null;
    /* command_e (-e) is used for running commands independently (not inside a shell) */
    [CCode (array_length = false, array_null_terminated = true)]
	public static string? command = null;
    public static string[]? environment = null;
    private static bool version = false;
    private static string title = null;
    public Widgets.QuakeWindow quake_window;
    public Widgets.Window window;
    public WorkspaceManager workspace_manager;
    public static bool debug = false;
	
    private bool inited = false;

	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "Print version info and exit", null },
		{ "work-directory", 'w', 0, OptionArg.FILENAME, ref work_directory, "Set shell working directory", "DIRECTORY" },
        { "execute", 'e', 0, OptionArg.STRING, ref command, "Run a program in terminal", null },
		{ "execute", 'x', 0, OptionArg.STRING, ref command, "Same as -e", null },
		{ "title", 'T', 0, OptionArg.STRING, ref title, "Title, this option does not make sense for the deepin terminal", null },
		{ "debug", 'd', 0, OptionArg.NONE, ref debug, "Enable debug mode for perfermance test", null },
		{ "quake-mode", 0, 0, OptionArg.NONE, ref quake_mode, "Quake mode", null },
        { "env", 0, 0, OptionArg.STRING_ARRAY, ref environment, "Add environment variable to the child\'s environment", "VAR=VALUE" },
        { null }
	};

    public static void main(string[] args) {
        // NOTE: set IBUS_NO_SNOOPER_APPS variable to avoid Ctrl + 5 eat by input method (such as fcitx.);
        Environment.set_variable("IBUS_DISABLE_SNOOPER", "1", true);
        
        Intl.setlocale();
        Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
        Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
        
        try {
			var opt_context = new OptionContext("Deepin terminal");
            opt_context.set_summary ("Deepin terminal, allowing you to focus more on the command line in the world.");
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		} catch (OptionError e) {
			stdout.printf ("error: %s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
		}
        
        if (version) {
			stdout.printf("Deepin Terminal %.01f\n".printf(Constant.VERSION));
            stdout.printf ("Copyright 2011-2016 Deepin, Inc.\n");
        } else {
            Gtk.init(ref args);
            
            if (debug) {
                Gdk.Window.set_debug_updates(debug);
            }
            
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
            } catch (IOError e) {
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
                tabbar.init(workspace_manager, quake_window);
            } else {
                window = new Widgets.Window();
                window.show_window(workspace_manager, tabbar);
                tabbar.init(workspace_manager, window);
            }
            
        }
    }
}
