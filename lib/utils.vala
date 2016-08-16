using Gdk;
using Gtk;
using Gee;

extern char* project_path();
extern string font_match(string family);
extern string[] list_mono_fonts(out int num);

namespace Utils {
    public ArrayList<string> list_files(string path) {
        ArrayList<string> files = new ArrayList<string>();
        
        try {
            FileEnumerator enumerator = File.new_for_path(path).enumerate_children(
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                
            FileInfo info = null;
            while (((info = enumerator.next_file()) != null)) {
                if (info.get_file_type() != FileType.DIRECTORY) {
                    files.add(info.get_name());
                }
            }
        } catch (Error e) {
            print("list_files: %s\n", e.message);
        }
        
        return files;
    }

    public bool move_window(Gtk.Widget widget, Gdk.EventButton event, Gtk.Window window) {
        if (is_left_button(event)) {
            window.begin_move_drag(
                (int)event.button, 
                (int)event.x_root, 
                (int)event.y_root, 
                event.time);
        }
        
        return false;
    }

    public void toggle_max_window(Gtk.Window window) {
        var window_state = window.get_window().get_state();
        if (Gdk.WindowState.MAXIMIZED in window_state) {
            window.unmaximize();
        } else {
            window.maximize();
        }
    }

    public bool is_left_button(Gdk.EventButton event) {
        return event.button == 1;
    }

    public bool is_double_click(Gdk.EventButton event) {
        return event.button == 1 && event.type == Gdk.EventType.2BUTTON_PRESS;
    }

    public void load_css_theme(string css_path) {
        var screen = Gdk.Screen.get_default();
        var css_provider = new Gtk.CssProvider();
        try {
            css_provider.load_from_path(css_path);
        } catch (GLib.Error e) {
            print("Got error when load css: %s\n", e.message);
        }
        Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }

    public bool is_pointer_out_widget(Gtk.Widget widget) {
        Gtk.Allocation alloc;
        widget.get_allocation(out alloc);
        
        int wx;
        int wy;
        widget.get_toplevel().get_window().get_origin(out wx, out wy);
        
        int px;
        int py;
        var device = Gtk.get_current_event_device ();
        widget.get_toplevel().get_window().get_device_position(device, out px, out py, null);
        
        int rect_start_x = wx + alloc.x;
        int rect_start_y = wx + alloc.y;
        int rect_end_x = rect_start_x + alloc.width;
        int rect_end_y = rect_start_y + alloc.height;

        return (px < rect_start_x || px > rect_end_x || py < rect_start_y || py > rect_end_y);
    }

    public void set_context_color(Cairo.Context cr, Gdk.RGBA color) {
        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
    }

    public void propagate_draw(Gtk.Container widget, Cairo.Context cr) {
        if (widget.get_children().length() > 0) {
            foreach (Gtk.Widget child in widget.get_children()) {
                widget.propagate_draw(child, cr);
            }
        }
    }

    public string slice_string(string str, int unichar_num) {
        string slice_str = "";
            
        unichar c;
        for (int i = 0; str.get_next_char(ref i, out c);) {
            if (i > unichar_num) {
                return slice_str.concat("... ");
            } else {
                slice_str = slice_str.concat(c.to_string());
            }
        }
            
        return slice_str;
    }

    public void touch_dir(string dir) {
        var dir_file = GLib.File.new_for_path(dir);
        if (!dir_file.query_exists()) {
            try {
                dir_file.make_directory_with_parents(null);
            } catch (GLib.Error err) {
                print("Could not create dir: %s\n", err.message);
            }
        }
    }

    public void remove_all_children(Gtk.Container container) {
        foreach (Widget w in container.get_children()) {
            container.remove(w);
        }
    }
	
    public void destroy_all_children(Gtk.Container container) {
        foreach (Widget w in container.get_children()) {
            container.remove(w);
			w.destroy();
        }
    }
	
	public Gtk.Allocation get_origin_allocation(Gtk.Widget w) {
        Gtk.Allocation alloc;
        w.get_allocation(out alloc);
        
        w.translate_coordinates(w.get_toplevel(), 0, 0, out alloc.x, out alloc.y);
        return alloc;
    }

    public string get_command_output(string cmd) {
    	try {
    	    int exit_code;
    	    string std_out;
    	    Process.spawn_command_line_sync(cmd, out std_out, null, out exit_code);
    	    return std_out;
    	} catch (Error e){
    	    return "";
    	}
    }

    public string get_image_path(string image_name) {
        return GLib.Path.build_path(Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) project_path()), "image", image_name);
    }

    public string get_theme_path(string theme_name) {
        return GLib.Path.build_path(Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) project_path()), "theme", theme_name);
    }

    public string get_theme_dir() {
        return GLib.Path.build_path(Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) project_path()), "theme");
    }

    public string get_root_path(string file_path) {
        return GLib.Path.build_path(Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) project_path()), file_path);
    }
	
	public string get_config_dir() {
		return GLib.Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_user_config_dir(), "deepin", "deepin-terminal");
	}
	
	public string get_config_file_path(string config_name) {
		return GLib.Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_user_config_dir(), "deepin", "deepin-terminal", config_name);
	}

    public string get_ssh_script_path() {
        return GLib.Path.build_path(Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) project_path()), "ssh_login.sh");
    }

    public string lookup_password(string user, string server_address) {
        var password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                                Secret.SchemaFlags.NONE,
                                                "number", Secret.SchemaAttributeType.INTEGER,
                                                "string", Secret.SchemaAttributeType.STRING,
                                                "even", Secret.SchemaAttributeType.BOOLEAN);
            
        string password;
        
        try {
            password = Secret.password_lookup_sync(password_schema, null, null, "number", 8, "string", "eight", "even", true);
                // print("Lookup password: '%s'\n", password);
        } catch (Error e) {
            error ("%s", e.message);
        }
        
        if (password == null) {
            return "";
        } else {
            return password;
        }
    }
    
    public void store_password(string user, string server_address, string password) {
        var password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                                Secret.SchemaFlags.NONE,
                                                "number", Secret.SchemaAttributeType.INTEGER,
                                                "string", Secret.SchemaAttributeType.STRING,
                                                "even", Secret.SchemaAttributeType.BOOLEAN);
        
        var attributes = new GLib.HashTable<string,string>(null, null);
        attributes["number"] = "8";
        attributes["string"] = "eight";
        attributes["even"] = "true";
        
        try {
            Secret.password_clear_sync(password_schema, null, "number", 8, "string", "eight", "even", true);
            // print("Remove password: %s %s\n".printf(user, server_address));
        } catch (Error e) {
            error ("%s", e.message);
        }

        Secret.password_storev.begin(password_schema, attributes, Secret.COLLECTION_DEFAULT,
                                     "com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                     password,
                                     null, (obj, async_res) => {
                                         try {
                                             Secret.password_store.end(async_res);
                                             // print("Store password: %s %s %s\n", user, server_address, password);
                                         } catch (Error e) {
                                             error ("%s", e.message);
                                         }
                                     });

    }


}