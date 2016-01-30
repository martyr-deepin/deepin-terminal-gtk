using Gtk;
using Widgets;

namespace Widgets {
    public class Workspace : Gtk.Box {
        public Gtk.Fixed fixed;
        public Widgets.Term term;
        
        public Workspace() {
            fixed = new Gtk.Fixed();
            
            term = new Widgets.Term();
            fixed.put(term, 0, 0);
            
            pack_start(fixed, true, true, 0);
        }
    }
}