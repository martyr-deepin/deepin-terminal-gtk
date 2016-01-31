using Gtk;
using Widgets;

namespace Widgets {
    public class Workspace : Gtk.Box {
        public Widgets.Term term;
        public int index;
        
        public signal void change_dir(int index, string dir);
        
        public Workspace(int workspace_index) {
            index = workspace_index;
            term = new Widgets.Term();
            term.change_dir.connect((term, dir) => {
                    change_dir(index, dir);
                });
            
            pack_start(term, true, true, 0);
        }
    }
}