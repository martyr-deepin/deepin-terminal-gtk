using Gtk;
using Widgets;

namespace Widgets {
    public class Workspace : Gtk.Box {
        public Widgets.Term term;
        
        public Workspace() {
            term = new Widgets.Term();
            
            pack_start(term, true, true, 0);
        }
    }
}