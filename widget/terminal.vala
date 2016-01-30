using Gtk;
using Vte;

namespace Widgets {
    public class Term : Gtk.ScrolledWindow {
        public Terminal term;
        public GLib.Pid process_id;
        public string working_directory = "";
    
        public Term() {
            term = new Terminal();
            term.background_transparent = true;
            term.set_opacity(0);
            term.child_exited.connect ((t)=> {
                    Gtk.main_quit();
                });

            var arguments = new string[0];
            var shell = get_shell();
        
            try {
                GLib.Shell.parse_argv(shell, out arguments);
            } catch (GLib.ShellError e) {
                print("Got error when get_shell: %s\n", e.message);
            }
        
            try {
                term.fork_command_full(PtyFlags.DEFAULT, working_directory, arguments, null, SpawnFlags.SEARCH_PATH, null, out process_id);
            } catch (GLib.Error e) {
                print("Got error when fork_command_full: %s\n", e.message);
            }
        
            set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            add(term);
        }
        
        private static string get_shell() {
            string? shell = Vte.get_user_shell();
            
            if (shell == null) {
                shell = "/bin/sh";
            }
            
            return (!)(shell);
        }
    }
}