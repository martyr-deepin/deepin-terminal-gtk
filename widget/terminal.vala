using Gtk;
using Vte;

namespace Widgets {
    public class Term : Gtk.ScrolledWindow {
        public Terminal term;
        public GLib.Pid child_pid;
        public string current_dir;
    
        public signal void change_dir(string dir);
        
        public Term() {
            Gdk.RGBA background_color = Gdk.RGBA();
            background_color.parse("#000000");
            background_color.alpha = 0.8;

            Gdk.RGBA foreground_color = Gdk.RGBA();
            foreground_color.parse("#00FF00");
            
            string[] hex_palette = { "#000000", "#FF6C60", "#A8FF60", "#FFFFCC", "#96CBFE",
                                     "#FF73FE", "#C6C5FE", "#EEEEEE", "#000000", "#FF6C60",
                                     "#A8FF60", "#FFFFB6", "#96CBFE", "#FF73FE", "#C6C5FE",
                                     "#EEEEEE" };

            Gdk.RGBA[] palette = new Gdk.RGBA[16];

            for (int i = 0; i < hex_palette.length; i++) {
                Gdk.RGBA new_color= Gdk.RGBA();
                new_color.parse(hex_palette[i]);

                palette[i] = new_color;
            }

            term = new Terminal();
            term.set_colors(foreground_color, background_color, palette);
            term.child_exited.connect ((t)=> {
                    Gtk.main_quit();
                });
            term.window_title_changed.connect((t) => {
                    string working_directory;
                    string[] spawn_args = {"readlink", "/proc/%i/cwd".printf(child_pid)};
                    try {
                        Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out working_directory);
                    } catch (SpawnError e) {
                        print("Got error when spawn_sync: %s\n", e.message);
                    }
                    
                    if (working_directory.length > 0) {
                        working_directory = working_directory[0:working_directory.length - 1];
                        if (current_dir != working_directory) {
                            change_dir(GLib.Path.get_basename(working_directory));
                            current_dir = working_directory;
                        }
                    }
                });

            active_shell();
        
            set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            add(term);
        }
        
        public void active_shell(string dir = GLib.Environment.get_current_dir ()) {
            string shell = "";
            string?[] envv = null;

            if (shell == "") {
                shell = Vte.get_user_shell();
            }

            try {
                term.spawn_sync (Vte.PtyFlags.DEFAULT, dir, {shell}, envv, SpawnFlags.SEARCH_PATH, null, out child_pid, null);
            } catch (Error e) {
                warning(e.message);
            }
        }
    }
}