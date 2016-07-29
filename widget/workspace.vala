using Gtk;
using Widgets;
using Gee;
using Utils;

namespace Widgets {
    public class Workspace : Gtk.Overlay {
        public int index;
        public ArrayList<Term> term_list;
        public SearchBox? search_box;
		public RemotePanel? remote_panel;
        public Term? term_before_search;
        public string search_text;
        
        public int PANED_HANDLE_SIZE = 1;
        
        public signal void change_dir(int index, string dir);
        public signal void highlight_tab(int index);
        public signal void exit(int index);
        
        public Workspace(int workspace_index, string[]? commands, string? work_directory) {
            index = workspace_index;
            term_list = new ArrayList<Term>();
            
            Term term = new_term(true, commands, work_directory);
            
            add(term);
        }
        
        public Term new_term(bool first_term, string[]? commands, string? work_directory) {
            Term term = new Widgets.Term(first_term, commands, work_directory);
            term.change_dir.connect((term, dir) => {
                    change_dir(index, dir);
                });
			term.highlight_tab.connect((term) => {
					highlight_tab(index);
				});
            term.exit.connect((term) => {
                    close_term(term);
                });
            term.term.button_press_event.connect((w, e) => {
                    remove_search_box();
					remove_remote_panel();
                    
                    return false;
                });

            term_list.add(term);
            
            return term;
        }
        
        public bool has_active_term() {
            foreach (Term term in term_list) {
                if (term.has_foreground_process()) {
                    return true;
                }
            }
            
            return false;
        }
        
        public void close_focus_term() {
            Term focus_term = get_focus_term(this);
            if (focus_term.has_foreground_process()) {
                ConfirmDialog dialog = new ConfirmDialog(
                    "Terminal still has running programs. Are you sure you want to quit?",
                    (Window) focus_term.get_toplevel());
                dialog.confirm.connect((d) => {
                        close_term(focus_term);
                    });
            } else {
                close_term(focus_term);
            }
        }
		
		public void toggle_select_all() {
			Term focus_term = get_focus_term(this);
			focus_term.toggle_select_all();
		}
		
		public void close_other_terms() {
			Term focus_term = get_focus_term(this);
			
			bool has_active_process = false;
			foreach (Term term in term_list) {
				if (term != focus_term) {
				    if (term.has_foreground_process()) {
				    	has_active_process = true;
				    	
				    	break;
				    }
				}
			}
			
			if (has_active_process) {
				ConfirmDialog dialog = new ConfirmDialog(
					"Terminal still has running programs. Are you sure you want to quit?",
					(Window) focus_term.get_toplevel());
				dialog.confirm.connect((d) => {
						close_term_except(focus_term);
					});
			} else {
				close_term_except(focus_term);
			}
		}
		
		public void close_term_except(Term except_term) {
			// We need remove term from it's parent before remove all children from workspace.
			Widget parent_widget = except_term.get_parent();
            ((Container) parent_widget).remove(except_term);
			
			// Destory all other terminals, wow! ;)
			foreach (Widget w in get_children()) {
				w.destroy();
			}
			
			// Re-parent except terminal.
			term_list = new ArrayList<Term>();
			term_list.add(except_term);
			add(except_term);
		}
        
        public void close_term(Term term) {
            Container parent_widget = term.get_parent();
            parent_widget.remove(term);
            term.destroy();
            term_list.remove(term);
            
            clean_unused_parent(parent_widget);
        }
        
        public void clean_unused_parent(Gtk.Container container) {
            if (container.get_children().length() == 0) {
                if (container.get_type().is_a(typeof(Workspace))) {
                    exit(index);
                } else {
                    Container parent_widget = container.get_parent();
                    parent_widget.remove(container);
                    container.destroy();
                    
                    clean_unused_parent(parent_widget);
                }
            } else {
                if (container.get_type().is_a(typeof(Paned))) {
					var first_child = container.get_children().nth_data(0);
					if (first_child.get_type().is_a(typeof(Paned))) {
						((Term) ((Paned) first_child).get_children().nth_data(0)).focus_term();
					} else {
						((Term) first_child).focus_term();
					}
                }
            }
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
            paned.draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);
                    
                    cr.set_source_rgba(0, 0, 0, 0.8);
                    Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height);
                    
                    return false;
                });
            Term term = new_term(false, null, focus_term.current_dir);
            paned.pack1(focus_term, true, false);
            paned.pack2(term, true, false);
            
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                paned.set_position(alloc.width / 2); 
            } else {
                paned.set_position(alloc.height / 2); 
            }
                
            if (parent_widget.get_type().is_a(typeof(Workspace))) {
                ((Workspace) parent_widget).add(paned);
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
                    same_coordinate_terminals[0].focus_term();
                } else {
                    ArrayList<Term> bigger_match_terminals = new ArrayList<Term>();
                    foreach (Term t in intersects_terminals) {
                        Gtk.Allocation alloc = Utils.get_origin_allocation(t);;
                        
                        if (alloc.y < y && alloc.y + alloc.height >= y + h) {
                            bigger_match_terminals.add(t);
                        }
                    }
                    
                    if (bigger_match_terminals.size > 0) {
                        bigger_match_terminals[0].focus_term();
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
                            biggest_intersectant_terminal.focus_term();
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
                    same_coordinate_terminals[0].focus_term();
                } else {
                    ArrayList<Term> bigger_match_terminals = new ArrayList<Term>();
                    foreach (Term t in intersects_terminals) {
                        Gtk.Allocation alloc = Utils.get_origin_allocation(t);;
                        
                        if (alloc.x < x && alloc.x + alloc.width >= x + w) {
                            bigger_match_terminals.add(t);
                        }
                    }
                    
                    if (bigger_match_terminals.size > 0) {
                        bigger_match_terminals[0].focus_term();
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
                            biggest_intersectant_terminal.focus_term();
                        }
                    }
                }
            }
        }
        
        public void search() {
            if (search_box == null) {
                term_before_search = get_focus_term(this);
                search_text = "";
                
                search_box = new SearchBox();
                search_box.close_button.button_press_event.connect((w, e) => {
                        remove_search_box();
                        
                        return false;
                    });
                search_box.entry.key_press_event.connect((w, e) => {
                        string keyname = Keymap.get_keyevent_name(e);
                        
                        if (keyname == "Esc") {
                            remove_search_box();
                        }
                        
                        return false;
                    });
                search_box.entry.get_buffer().deleted_text.connect((buffer, p, nc) => {
                        update_search_text();
                    });
                search_box.entry.get_buffer().inserted_text.connect((buffer, p, c, nc) => {
                        update_search_text();
                    });
                search_box.entry.activate.connect((w) => {
                        if (search_text != "") {
                            term_before_search.term.search_find_next();
                        }
                    });
                search_box.set_size_request(100, -1);
                search_box.set_valign(Gtk.Align.START);
                search_box.set_halign(Gtk.Align.END);
                add_overlay(search_box);
                show_all();            
                
                search_box.entry.grab_focus();
            } else {
                search_box.entry.grab_focus();
            }
        }
        
        public void remove_search_box() {
            search_text = "";
            
            if (search_box != null) {
                remove(search_box);
                search_box.destroy();
                search_box = null;
            }
            
            if (term_before_search != null) {
                term_before_search.focus_term();
                term_before_search = null;
            }
        }
        
        public void update_search_text() {
            string entry_text = search_box.entry.get_text().strip();
            if (search_text != entry_text) {
                search_text = entry_text;
                
                try {
                    var regex = new Regex(Regex.escape_string(search_text), RegexCompileFlags.CASELESS);
                    term_before_search.term.search_set_gregex(regex, 0);
                    term_before_search.term.search_set_wrap_around(true);
                } catch (GLib.RegexError e) {
                    stdout.printf("Got error %s", e.message);
                }
            }
        }

		public void toggle_remote_panel(Workspace workspace) {
			if (remote_panel == null) {
				show_remote_panel(workspace);
			} else {
				remove_remote_panel();
			}
		}
		
		public void show_remote_panel(Workspace workspace) {
			if (remote_panel == null) {
				Gtk.Allocation rect;
				get_allocation(out rect);
				
				remote_panel = new RemotePanel(workspace);
				remote_panel.set_size_request(200, rect.height);
                remote_panel.set_valign(Gtk.Align.START);
                remote_panel.set_halign(Gtk.Align.START);
				add_overlay(remote_panel);
				
				show_all();
			}
		}
		
		public void remove_remote_panel() {
			if (remote_panel != null) {
				remove(remote_panel);
				remote_panel.destroy();
				remote_panel = null;
			}
		}
    }
}