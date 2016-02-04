using Gtk;
using Widgets;
using Gee;

namespace Widgets {
    public class Workspace : Gtk.Box {
        public int index;
        public ArrayList<Term> term_list;
        
        public int PANED_HANDLE_SIZE = 1;
        
        public signal void change_dir(int index, string dir);
        
        public Workspace(int workspace_index) {
            index = workspace_index;
            term_list = new ArrayList<Term>();
            
            Term term = new_term(true);
            
            pack_start(term, true, true, 0);
        }
        
        public Term new_term(bool first_term) {
            Term term = new Widgets.Term(first_term);
            term.change_dir.connect((term, dir) => {
                    change_dir(index, dir);
                });
            term_list.add(term);
            
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
            
            Gtk.Allocation alloc;
            focus_term.get_allocation(out alloc);
            
            Widget parent_widget = focus_term.get_parent();
            ((Container) parent_widget).remove(focus_term);
            Paned paned = new Paned(orientation);
            Term term = new_term(false);
            paned.pack1(focus_term, true, false);
            paned.pack2(term, true, false);
            
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                paned.set_position(alloc.width / 2); 
            } else {
                paned.set_position(alloc.height / 2); 
            }
                
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
        
        public void focus_left_terminal() {
            focus_horizontal_terminal(true);
        }
        
        public void focus_right_terminal() {
            focus_horizontal_terminal(false);
        }
        
        public void focus_up_terminal() {
            focus_vertical_terminal(true);
        }
        
        public void focus_down_terminal() {
            focus_vertical_terminal(false);
        }
        
        public ArrayList<Term> find_intersects_horizontal_terminals(Gtk.Allocation rect, bool left=true) {
            ArrayList<Term> intersects_terminals = new ArrayList<Term>();
            foreach (Term t in term_list) {
                Gtk.Allocation alloc = Utils.get_origin_allocation(t);
                
                if (alloc.y < rect.y + rect.height + PANED_HANDLE_SIZE && alloc.y + alloc.height + PANED_HANDLE_SIZE > rect.y) {
                    if (left) {
                        if (alloc.x + alloc.width + PANED_HANDLE_SIZE == rect.x) {
                            intersects_terminals.add(t);
                        }
                    } else {
                        if (alloc.x == rect.x + rect.width + PANED_HANDLE_SIZE) {
                            intersects_terminals.add(t);
                        }
                    }
                }
            }
            
            return intersects_terminals;
        }
        
        public void focus_horizontal_terminal(bool left=true) {
            Term focus_terminal = get_focus_term(this);
            
            Gtk.Allocation rect = Utils.get_origin_allocation(focus_terminal);
            int y = rect.y;
            int h = rect.height;

            ArrayList<Term> intersects_terminals = find_intersects_horizontal_terminals(rect, left);
            if (intersects_terminals.size > 0) {
                ArrayList<Term> same_coordinate_terminals = new ArrayList<Term>();
                foreach (Term t in intersects_terminals) {
                    Gtk.Allocation alloc = Utils.get_origin_allocation(t);
                    
                    if (alloc.y == y) {
                        same_coordinate_terminals.add(t);
                    }
                }
                
                if (same_coordinate_terminals.size > 0) {
                    same_coordinate_terminals[0].term.grab_focus();
                } else {
                    ArrayList<Term> bigger_match_terminals = new ArrayList<Term>();
                    foreach (Term t in intersects_terminals) {
                        Gtk.Allocation alloc = Utils.get_origin_allocation(t);;
                        
                        if (alloc.y < y && alloc.y + alloc.height >= y + h) {
                            bigger_match_terminals.add(t);
                        }
                    }
                    
                    if (bigger_match_terminals.size > 0) {
                        bigger_match_terminals[0].term.grab_focus();
                    } else {
                        Term biggest_intersectant_terminal = null;
                        int area = 0;
                        foreach (Term t in intersects_terminals) {
                            Gtk.Allocation alloc = Utils.get_origin_allocation(t);;
                            
                            int term_area = alloc.height + h - (alloc.y - y).abs() - (alloc.y + alloc.height - y - h).abs() / 2;
                            if (term_area > area) {
                                biggest_intersectant_terminal = t;
                            }
                        }
                        
                        if (biggest_intersectant_terminal != null) {
                            biggest_intersectant_terminal.term.grab_focus();
                        }
                    }
                }
            }
        }
        
        public ArrayList<Term> find_intersects_vertical_terminals(Gtk.Allocation rect, bool up=true) {
            ArrayList<Term> intersects_terminals = new ArrayList<Term>();
            foreach (Term t in term_list) {
                Gtk.Allocation alloc = Utils.get_origin_allocation(t);
                
                if (alloc.x < rect.x + rect.width + PANED_HANDLE_SIZE && alloc.x + alloc.width + PANED_HANDLE_SIZE > rect.x) {
                    if (up) {
                        if (alloc.y + alloc.height + PANED_HANDLE_SIZE == rect.y) {
                            intersects_terminals.add(t);
                        }
                    } else {
                        if (alloc.y == rect.y + rect.height + PANED_HANDLE_SIZE) {
                            intersects_terminals.add(t);
                        }
                    }
                }
            }
            
            return intersects_terminals;
        }
        
        public void focus_vertical_terminal(bool up=true) {
            Term focus_terminal = get_focus_term(this);
            
            Gtk.Allocation rect = Utils.get_origin_allocation(focus_terminal);
            int x = rect.x;
            int w = rect.width;

            ArrayList<Term> intersects_terminals = find_intersects_vertical_terminals(rect, up);
            if (intersects_terminals.size > 0) {
                ArrayList<Term> same_coordinate_terminals = new ArrayList<Term>();
                foreach (Term t in intersects_terminals) {
                    Gtk.Allocation alloc = Utils.get_origin_allocation(t);
                    
                    if (alloc.x == x) {
                        same_coordinate_terminals.add(t);
                    }
                }
                
                if (same_coordinate_terminals.size > 0) {
                    same_coordinate_terminals[0].term.grab_focus();
                } else {
                    ArrayList<Term> bigger_match_terminals = new ArrayList<Term>();
                    foreach (Term t in intersects_terminals) {
                        Gtk.Allocation alloc = Utils.get_origin_allocation(t);;
                        
                        if (alloc.x < x && alloc.x + alloc.width >= x + w) {
                            bigger_match_terminals.add(t);
                        }
                    }
                    
                    if (bigger_match_terminals.size > 0) {
                        bigger_match_terminals[0].term.grab_focus();
                    } else {
                        Term biggest_intersectant_terminal = null;
                        int area = 0;
                        foreach (Term t in intersects_terminals) {
                            Gtk.Allocation alloc = Utils.get_origin_allocation(t);;
                            
                            int term_area = alloc.width + w - (alloc.x - x).abs() - (alloc.x + alloc.width - x - w).abs() / 2;
                            if (term_area > area) {
                                biggest_intersectant_terminal = t;
                            }
                        }
                        
                        if (biggest_intersectant_terminal != null) {
                            biggest_intersectant_terminal.term.grab_focus();
                        }
                    }
                }
            }
        }
    }
}