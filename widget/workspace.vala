using Gtk;
using Widgets;

namespace Widgets {
    public class Workspace : Gtk.Box {
        public int index;
        
        public signal void change_dir(int index, string dir);
        
        public Workspace(int workspace_index) {
            index = workspace_index;
            Term term = new_term(true);
            
            pack_start(term, true, true, 0);
        }
        
        public Term new_term(bool first_term) {
            Term term = new Widgets.Term(first_term);
            term.change_dir.connect((term, dir) => {
                    change_dir(index, dir);
                });
            
            return term;
        }
        
        public Term get_focus_term(Container container) {
            Widget focus_child = container.get_focus_child();
            if (focus_child.get_type().is_a(typeof(Term))) {
                return (Term) focus_child;
            } else {
                return get_focus_term((Container) focus_child);
            }
        }
        
        public void split_horizontal() {
            split(Gtk.Orientation.HORIZONTAL);
        }
            
        public void split_vertical() {
            split(Gtk.Orientation.VERTICAL);
        }
        
        public void split(Orientation orientation) {
            Term focus_term = get_focus_term(this);
            
            Widget parent_widget = focus_term.get_parent();
            ((Container) parent_widget).remove(focus_term);
            Paned paned = new Paned(orientation);
            Term term = new_term(false);
            paned.pack1(focus_term, true, false);
            paned.pack2(term, true, false);
                
            if (parent_widget.get_type().is_a(typeof(Workspace))) {
                ((Workspace) parent_widget).pack_start(paned, true, true, 0);
            } else if (parent_widget.get_type().is_a(typeof(Paned))) {
                if (focus_term.is_first_term) {
                    ((Paned) parent_widget).pack1(paned, true, false);
                } else {
                    focus_term.is_first_term = true;
                    ((Paned) parent_widget).pack2(paned, true, false);
                }
                
            }
            
            this.show_all();
        }
    }
}