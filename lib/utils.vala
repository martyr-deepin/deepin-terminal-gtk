using Gdk;
using Gtk;

extern char* project_path();

namespace Utils {
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

    public string get_root_path(string file_path) {
        return GLib.Path.build_path(Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) project_path()), file_path);
    }
}