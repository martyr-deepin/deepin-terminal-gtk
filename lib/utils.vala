/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2018 Deepin, Inc.
 *               2011 ~ 2018 Wang Yong
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
using Rsvg;
using Cairo;

extern char* project_path();
extern string font_match(string family);
extern string[] list_mono_or_dot_fonts(out int num);
private static bool is_tiling = false;
private static bool tiling_checked = false;

namespace Utils {
    [DBus (name = "com.deepin.Manual.Open")]
    interface DeepinManualInterface : Object {
        public abstract void ShowManual(string appName) throws GLib.Error;
    }

    public Gdk.RGBA hex_to_rgba(string hex_color, double alpha=1.0) {
        Gdk.RGBA rgba_color = Gdk.RGBA();
        rgba_color.parse(hex_color);
        rgba_color.alpha = alpha;

        return rgba_color;
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

    public bool is_light_color(string color_string) {
        Gdk.RGBA color = Gdk.RGBA();
        color.parse(color_string);

        double r = color.red;
        double g = color.green;
        double b = color.blue;

        double max_v = double.max(r, double.max(g, b));
        double min_v = double.min(r, double.min(g, b));

        double s;

        if (max_v == 0) {
            s = 0.0;
        } else {
            s = 1.0 - min_v / max_v;
        }

        b = max_v;

        return b > 0.35 && s < 0.7;
    }

    public double get_color_brightness(string color_string) {
        Gdk.RGBA color = Gdk.RGBA();
        color.parse(color_string);

        double r = color.red;
        double g = color.green;
        double b = color.blue;

        double max_v = double.max(r, double.max(g, b));
        double min_v = double.min(r, double.min(g, b));

        double s;

        if (max_v == 0) {
            s = 0.0;
        } else {
            s = 1.0 - min_v / max_v;
        }

        b = max_v;

        return b;
    }

    public bool is_tiling_wm() {
        // This check needed to prevent multiple queries to Process.spawn
        if (tiling_checked) return is_tiling;
        var output = "";
        try {
            // This command returns something if one of this WMs will be running or "" if non
            Process.spawn_command_line_sync (@"pidof i3 xmonad wmii wmfs wingo subtle sway stumpwm spectrwm snapwm ratpoison qtile notion herbstluftwm frankenwm dwm bspwm awesome alopex", out output);
        } catch (GLib.SpawnError e) {
            warning("Something bad happened with pidof command %s", e.message);
        }
        is_tiling = output != "";
        tiling_checked = true;
        return is_tiling;
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

    public void create_file(string file_path) {
        var file = GLib.File.new_for_path(file_path);
        if (!file.query_exists()) {
            try {
                file.create(GLib.FileCreateFlags.NONE, null);
            } catch (GLib.Error e) {
                print("create_file: %s\n", e.message);
            }
        }
    }

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
        } catch (GLib.Error e) {
            print("list_files: %s\n", e.message);
        }

        return files;
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

    public bool is_mouse_wheel(Gdk.EventButton event) {
        return event.button == 2;
    }

    public bool is_right_button(Gdk.EventButton event) {
        return event.button == 3;
    }

    public bool is_action_mouse_button(Gdk.EventButton event) {
        return is_left_button(event) || is_mouse_wheel(event);
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

    public bool is_command_exist(string command_name) {
        string? paths = Environment.get_variable("PATH");

        foreach (string bin_path in paths.split(":")) {
            var file = File.new_for_path(GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, bin_path, command_name));
            if (file.query_exists()) {
                return true;
            }
        }

        return false;
    }

    public string get_command_output(string cmd) {
        try {
            int exit_code;
            string std_out;
            Process.spawn_command_line_sync(cmd, out std_out, null, out exit_code);
            return std_out;
        } catch (GLib.Error e){
            return "";
        }
    }

    public string get_proc_file_content(string proc_file_path) {
        try {
            uint8[] data;
            GLib.FileUtils.get_data(proc_file_path, out data);
            if (data != null) {
                for(var i=0; i<data.length-1; i++){
                    if (data[i]==0) {
                        data[i]=' ';
                    }
                }

                return (string) data;
            } else {
                return "";
            }
        } catch (GLib.Error e) {
            print("get_proc_file_content: %s\n", e.message);
            return "";
        }
    }

    public string get_image_path(string image_name) {
#if TEST_BUILD
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "image", image_name);
#else
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "share", "deepin-terminal", "image", image_name);
#endif
    }

    public string get_theme_path(string theme_name) {
#if TEST_BUILD
        var theme_path = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "theme", theme_name);
#else
        var theme_path = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "share", "deepin-terminal", "theme", theme_name);
#endif
        var dir_file = GLib.File.new_for_path(theme_path);
        if (!dir_file.query_exists())
           theme_path = get_additional_theme_path(theme_name);
        return theme_path;
    }

    public string get_additional_theme_path(string theme_name) {
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) get_additional_theme_dir()), "themes", theme_name);
    }

    public string get_theme_dir() {
#if TEST_BUILD
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "theme");
#else
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "share", "deepin-terminal", "theme");
#endif
    }

    public string get_additional_theme_dir() {
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, GLib.Path.get_dirname((string) get_config_dir()), "deepin-terminal", "themes");
    }

    public string get_root_path(string file_path) {
#if TEST_BUILD
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), file_path);
#else
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, (string) project_path(), "share", "deepin-terminal", file_path);
#endif
    }

    public string get_config_dir() {
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, Environment.get_user_config_dir(), "deepin", "deepin-terminal");
    }

    public string get_config_file_path(string config_name) {
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, Environment.get_user_config_dir(), "deepin", "deepin-terminal", config_name);
    }

    public string get_ssh_script_path() {
#if TEST_BUILD
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S,  (string) project_path(), "ssh_login.sh");
#else
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S,  (string) project_path(), "lib", "deepin-terminal", "ssh_login.sh");
#endif
    }

    public string get_default_private_key_path() {
        return GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, Environment.get_home_dir(), ".ssh", "id_rsa");
    }

    public string lookup_password(string user, string server_address, string? port=null) {
        Secret.Schema? password_schema;
        if (port == null) {
            password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                                Secret.SchemaFlags.NONE,
                                                "number", Secret.SchemaAttributeType.INTEGER,
                                                "string", Secret.SchemaAttributeType.STRING,
                                                "even", Secret.SchemaAttributeType.BOOLEAN);
        } else {
            password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s.%s".printf(user, server_address, port),
                                                Secret.SchemaFlags.NONE,
                                                "number", Secret.SchemaAttributeType.INTEGER,
                                                "string", Secret.SchemaAttributeType.STRING,
                                                "even", Secret.SchemaAttributeType.BOOLEAN);
        }

        string password;

        try {
            password = Secret.password_lookup_sync(password_schema, null, null, "number", 8, "string", "eight", "even", true);
            // print("Lookup password: '%s'\n", password);
        } catch (GLib.Error e) {
            error ("%s", e.message);
        }

        if (password == null) {
            return "";
        } else {
            return password;
        }
    }

    public void store_password(string user, string server_address, int port, string password) {
        var password_schema = new Secret.Schema("com.deepin.terminal.password.%s.%s.%i".printf(user, server_address, port),
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
        } catch (GLib.Error e) {
            print("%s", e.message);
            return;
        }

        Secret.password_storev.begin(password_schema, attributes, Secret.COLLECTION_DEFAULT,
                                     "com.deepin.terminal.password.%s.%s".printf(user, server_address),
                                     password,
                                     null, (obj, async_res) => {
                                         try {
                                             Secret.password_store.end(async_res);
                                         } catch (GLib.Error e) {
                                             print("%s", e.message);
                                             return;
                                         }
                                     });

    }

    public void get_pointer_position(out int x, out int y) {
        Gdk.Display gdk_display = Gdk.Display.get_default();
        var seat = gdk_display.get_default_seat();
        var device = seat.get_pointer();

        device.get_position(null, out x, out y);
    }

    public bool pointer_in_widget_area(Gtk.Widget widget) {
        int pointer_x, pointer_y;
        Utils.get_pointer_position(out pointer_x, out pointer_y);

        Gtk.Allocation widget_rect = get_origin_allocation(widget);

        int window_x, window_y;
        widget.get_toplevel().get_window().get_root_origin(out window_x, out window_y);

        return pointer_x > window_x + widget_rect.x && pointer_x < window_x + widget_rect.x + widget_rect.width && pointer_y > window_y + widget_rect.y && pointer_y < window_y + widget_rect.y + widget_rect.height;
    }

    public void show_manual() {
        try {
            DeepinManualInterface deepin_manual_interface = Bus.get_proxy_sync(BusType.SESSION, "com.deepin.Manual.Open", "/com/deepin/Manual/Open");
            deepin_manual_interface.ShowManual("deepin-terminal");
        } catch (GLib.Error e) {
            print("show_manual: %s\n", e.message);
        }
    }

    public void write_log(string log) {
        var log_file_dir = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir(), "deepin", "deepin-terminal");
        var log_file = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir(), "deepin", "deepin-terminal", "deepin-terminal.log");
        touch_dir(log_file_dir);
        try {
            FileUtils.set_contents(log_file, log);
        } catch (GLib.Error e) {
            print("write_log: %s\n", e.message);
        }
    }

    public Cairo.ImageSurface create_image_surface(string surface_path) {
        try {
            var scale = get_default_monitor_scale();
            Rsvg.Handle r = new Rsvg.Handle.from_file(Utils.get_image_path(surface_path));
            Rsvg.DimensionData d = r.get_dimensions();
            Cairo.ImageSurface cs = new Cairo.ImageSurface(Cairo.Format.ARGB32, (int)(d.width * scale), (int)(d.height * scale));
            cs.set_device_scale(scale, scale);
            Cairo.Context c = new Cairo.Context(cs);
            r.render_cairo(c);

            return cs;
        } catch (GLib.Error e) {
            print("create_image_surface: %s %s\n", surface_path, e.message);

            Cairo.ImageSurface cs = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
            return cs;
        }
    }

    public int get_active_monitor(Gdk.Screen screen) {
        var window = screen.get_active_window();
        if (window != null) {
            return screen.get_monitor_at_window(window);
        } else {
            return screen.get_primary_monitor();
        }
    }

    public double get_default_monitor_scale() {
        var display = Display.get_default();
        if (display != null) {
            var monitor = display.get_primary_monitor();
            if (monitor != null) {
                return monitor.get_scale_factor();
            }
        }
        return 1.0;
    }

    public double get_dde_scale_ratio() {
        var scaleStr = GLib.Environment.get_variable("QT_SCALE_FACTOR");
        if (scaleStr == null) {
            var dpiStr = GLib.Environment.get_variable("QT_FONT_DPI");
            if (dpiStr == null) {
                return 1.0;
            }
            return double.parse(dpiStr)/96;
        }

        var parsedScale = double.parse(scaleStr);
        return parsedScale == 0 ? 1.0 : parsedScale;
    }

    public int get_pointer_monitor(Gdk.Screen screen) {
        int x, y;
        get_pointer_position(out x, out y);

        return screen.get_monitor_at_point(x, y);
    }

    public string get_process_cmdline(int pid) {
        var cmd_file = File.new_for_path ("/proc/%d/cmdline".printf(pid));
        string command = "";
        if (!cmd_file.query_exists()) {
            return command;
        }

        try {
            var dis = new DataInputStream (cmd_file.read ());
            uint8[] data = new uint8[4097];
            var size = dis.read (data);

            if (size <= 0) {
                command = "";
            }

            for (int pos = 0; pos < size; pos++) {
                if (data[pos] == '\0' || data[pos] == '\n') {
                    data[pos] = ' ';
                }
            }

            command = (string) data;
        } catch (GLib.Error e) {
            warning ("%s\n", e.message);
        }

        return command;
    }
}
