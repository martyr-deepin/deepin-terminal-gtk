using Gtk;
using Vte;

namespace Widgets {
    public class Term : Gtk.ScrolledWindow {
        enum DropTargets {
            URILIST,
            STRING,
            TEXT
        }

        public Terminal term;
        public GLib.Pid child_pid;
        public string current_dir;
    
        public signal void change_dir(string dir);
        
        public int default_size;
        public double zoom_factor = 1.0;

        /* Following strings are used to build RegEx for matching URIs */
        const string USERCHARS = "-[:alnum:]";
        const string USERCHARS_CLASS = "[" + USERCHARS + "]";
        const string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
        const string HOSTCHARS_CLASS = "[-[:alnum:]]";
        const string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
        const string PORT = "(?:\\:[[:digit:]]{1,5})?";
        const string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
        const string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
        const string SCHEME = """(?:news:|telnet:|nntp:|file:\/|https?:|ftps?:|sftp:|webcal:
                                 |irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:
                                 |git\+ssh:|bzr:|bzr\+ssh:|svn:|svn\+ssh:|hg:|mailto:|magnet:)""";

        const string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
        const string URLPATH = "(?:(/" + PATHCHARS_CLASS + "+(?:[(]" + PATHCHARS_CLASS + "*[)])*" + PATHCHARS_CLASS + "*)*" + PATHTERM_CLASS + ")?";

        static const string[] regex_strings = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+"
        };
        
        public bool is_first_term; 
        
        public Term(bool first_term) {
            is_first_term = first_term;
            
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
            term.realize.connect((t) => {
                    t.grab_focus();
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
            term.key_press_event.connect(on_key_press);
            term.button_press_event.connect((event) => {
                string? uri = get_link ((long) event.x, (long) event.y);
                
                switch (event.button) {
                    case Gdk.BUTTON_PRIMARY:
                        if (event.state == Gdk.ModifierType.CONTROL_MASK && uri != null) {
                            try {
                                Gtk.show_uri (null, (!) uri, Gtk.get_current_event_time ());
                                return true;
                            } catch (GLib.Error error) {
                                warning ("Could Not Open link");
                            }
                        }

                        return false;
                }

                return false;
            });

            /* target entries specify what kind of data the terminal widget accepts */
            Gtk.TargetEntry uri_entry = { "text/uri-list", Gtk.TargetFlags.OTHER_APP, DropTargets.URILIST };
            Gtk.TargetEntry string_entry = { "STRING", Gtk.TargetFlags.OTHER_APP, DropTargets.STRING };
            Gtk.TargetEntry text_entry = { "text/plain", Gtk.TargetFlags.OTHER_APP, DropTargets.TEXT };

            Gtk.TargetEntry[] targets = { };
            targets += uri_entry;
            targets += string_entry;
            targets += text_entry;

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
            this.drag_data_received.connect(drag_received);

            /* Make Links Clickable */
            this.clickable(regex_strings);
            
            active_shell();
        
            set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            add(term);
        }
        
        private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            
            if (keyname == "Ctrl + C") {
                term.copy_clipboard();
            } else if (keyname == "Ctrl + V") {
                term.paste_clipboard();
            } else if (keyname == "Ctrl + =") {
                increment_size();
            } else if (keyname == "Ctrl + -") {
                decrement_size();
            } else if (keyname == "Ctrl + 0") {
                set_default_font_size();
            } else {
                return false;
            }
            
            return true;
        }

        public void increment_size () {
            Pango.FontDescription current_font = term.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();
            if (current_font.get_size () > 60000) return;

            zoom_factor += 0.1;
            current_font.set_size ((int) Math.floor (default_size * zoom_factor));
            term.set_font (current_font);
        }

        public void decrement_size () {
            Pango.FontDescription current_font = term.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();
            if (current_font.get_size () < 2048) return;

            zoom_factor -= 0.1;
            current_font.set_size ((int) Math.ceil (default_size * zoom_factor));
            term.set_font (current_font);
        }

        public void set_default_font_size () {
            Pango.FontDescription current_font = term.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();

            zoom_factor = 1.0;
            current_font.set_size (default_size);
            term.set_font (current_font);
        }

        private string? get_link (long x, long y) {
            long col = x / term.get_char_width ();
            long row = y / term.get_char_height ();
            int tag;

            // Vte.Terminal.match_check need a non-null tag instead of what is
            // written in the doc
            // (see: https://bugzilla.gnome.org/show_bug.cgi?id=676886)
            return term.match_check(col, row, out tag);
        }

        public void drag_received (Gdk.DragContext context, int x, int y,
                                   Gtk.SelectionData selection_data, uint target_type, uint time_) {
            switch (target_type) {
                case DropTargets.URILIST:
                    var uris = selection_data.get_uris ();
                    string path;
                    File file;

                    for (var i = 0; i < uris.length; i++) {
                         file = File.new_for_uri (uris[i]);
                         if ((path = file.get_path ()) != null) {
                             uris[i] = Shell.quote (path) + " ";
                        }
                    }

                    string uris_s = string.joinv ("", uris);
                    this.term.feed_child (uris_s, uris_s.length);

                    break;
                case DropTargets.STRING:
                case DropTargets.TEXT:
                    var data = selection_data.get_text ();

                    if (data != null) {
                        this.term.feed_child (data, data.length);
                    }

                    break;
            }
        }
        
        private void clickable (string[] str) {
            foreach (string exp in str) {
                try {
                    var regex = new GLib.Regex (exp);
                    int id = term.match_add_gregex (regex, 0);

                    term.match_set_cursor_type (id, Gdk.CursorType.HAND2);
                } catch (GLib.RegexError error) {
                    warning (error.message);
                }
            }
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