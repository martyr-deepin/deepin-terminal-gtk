using Gtk;
using Gdk;
using Vte;
using Widgets;
using Keymap;

private class Application {
    public Widgets.Window window;
    public WorkspaceManager workspace_manager;
    
	private static bool version = false;
	private static bool quake_mode = false;
	private static string? work_directory = null;
    
    /* command_e (-e) is used for running commands independently (not inside a shell) */
    [CCode (array_length = false, array_null_terminated = true)]
	private static string[]? commands = null;
    
    private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "Print version info and exit", null },
		{ "work-directory", 'w', 0, OptionArg.FILENAME, ref work_directory, "Set shell working directory", "DIRECTORY" },
		{ "quake-mode", 0, 0, OptionArg.NONE, ref quake_mode, "Quake mode", null },
        { "execute", 'e', 0, OptionArg.STRING_ARRAY, ref commands, "Run a program in terminal", "" },
		{ "execute", 'x', 0, OptionArg.STRING_ARRAY, ref commands, "Same as -e", "" },
        
		// list terminator
		{ null }
	};
    
    private Application() {
        Utils.load_css_theme("style.css");
        
        Titlebar titlebar = new Titlebar();
        workspace_manager = new WorkspaceManager(titlebar.tabbar, commands, work_directory); 
        
        titlebar.tabbar.press_tab.connect((t, tab_index, tab_id) => {
                workspace_manager.switch_workspace(tab_id);
            });
        titlebar.tabbar.close_tab.connect((t, tab_index, tab_id) => {
                workspace_manager.remove_workspace(tab_id);
            });
        
        window = new Widgets.Window();
        
        window.destroy.connect((t) => {
                Gtk.main_quit();
            });
        window.window_state_event.connect((w) => {
                titlebar.update_max_button();
                
                return false;
            });
        window.key_press_event.connect(on_key_press);
        
        window.set_position(Gtk.WindowPosition.CENTER);
        window.set_titlebar(titlebar);
        window.add(workspace_manager);
        window.show_all();
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
        } else if (keyname in ctrl_num_keys) {
            workspace_manager.switch_workspace_with_index(int.parse(Keymap.get_key_name(key_event.keyval)));
        } else if (keyname == "F11") {
            window.toggle_fullscreen();
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
        } else {
            return false;
        }
        
        return true;
    }
    
    private static void main(string[] args) {
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
            new Application();
            Gtk.main();
        }
    }
}