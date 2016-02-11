using Gtk;
using Widgets;
using Gee;

namespace Widgets {
    public class HistoryDialog : Gtk.Window {
        public HistoryList history_list;
        public Entry entry;
        
        public signal void active_history(string history_command);
        
        public HistoryDialog(Gtk.Window window) {
            modal = true;
            set_transient_for(window);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_size_request(window.get_allocated_width() * 2 / 3,
                             window.get_allocated_height() * 2 / 3);
            set_resizable(false);
            
            Titlebar titlebar = new Titlebar();
            titlebar.close_button.button_press_event.connect((b) => {
                    exit();
                    
                    return false;
                });
            set_titlebar(titlebar);
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + window.get_allocated_width() / 6,
                 y + window.get_allocated_height() / 6);
            
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            entry = new Entry();
            entry.set_placeholder_text("Type history command...");
            entry.get_buffer().deleted_text.connect((buffer, p, nc) => {
                    history_list.match_input(buffer.get_text());
                });
            entry.get_buffer().inserted_text.connect((buffer, p, c, nc) => {
                    history_list.match_input(buffer.get_text());
                });
            entry.key_press_event.connect((w, e) => {
                    on_key_press(w, e);
                    
                    return false;
                });
            
            key_press_event.connect((w, e) => {
                    string keyname = Keymap.get_keyevent_name(e);
                    if (keyname == "Esc") {
                        exit();
                    }
                    
                    return false;
                });
            
            history_list = new HistoryList();
            history_list.list_history();
            history_list.active_item.connect((list, current_row) => {
                    string input = entry.get_buffer().get_text().strip();
                    
                    if (current_row >= 0) {
                        HistoryItem? item = (HistoryItem) history_list.list_items.get(current_row);
                        if (item != null) {
                            execute_history_command(item.history_text);
                        } else {
                            if (input != "") {
                                execute_history_command(input);
                            }
                        }
                    } else {
                        execute_history_command(input);
                    }
                });
            
            box.pack_start(entry, false, false, 0);
            box.pack_start(history_list, true, true, 0);
            add(box);
            
            draw.connect(on_draw);
            
            show_all();
        }
        
        public void execute_history_command(string command) {
            active_history(command);
            exit();
        }
        
        public void exit() {
            Gtk.Window window = get_transient_for();
            destroy();
            window.present();
        }
        
        public void on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            if (keyname == "Enter") {
                history_list.active_item(history_list.current_row);
            } else if (keyname == "Down") {
                history_list.select_next_item();
            } else if (keyname == "Up") {
                history_list.select_prev_item();
            } else if (keyname == "Home") {
                history_list.select_first_item();
            } else if (keyname == "End") {
                history_list.select_last_item();
            }
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            // HACKINGWAY: we need get shadow property from gtk css file to instead constant way.
            int shadow_left = 23;
            int shadow_right = 23;
            int shadow_up = 18;
            int shadow_down = 18;
            
            cr.set_source_rgba(0, 0, 0, 0.8);
            Draw.draw_rectangle(cr, 
                                alloc.x + shadow_left, 
                                alloc.y + shadow_up, 
                                alloc.width - shadow_left - shadow_right, 
                                alloc.height - shadow_up - shadow_down);

            cr.set_source_rgba(1, 1, 1, 0.8);
            Draw.draw_rectangle(cr, 
                                alloc.x + shadow_left, 
                                alloc.y + shadow_up, 
                                alloc.width - shadow_left - shadow_right, 
                                alloc.height - shadow_up - shadow_down,
                                false
                                );
            
            return false;
        }
    }

    public class HistoryList : ListView {
        public int height = 30;
        public ArrayList<HistoryItem> history_items;
        
        public HistoryList() {
            base();
            
            history_items = new ArrayList<HistoryItem>();
        }
        
        public void match_input(string input) {
            // Clear list view's items.
            list_items.clear();
            
            // Add match items.
            if (input != "") {
                ArrayList<HistoryItem> match_items = new ArrayList<HistoryItem>();
                foreach (HistoryItem item in history_items) {
                    if (input.match_string(item.history_text, true)) {
                        HistoryItem match_item = new HistoryItem(item.history_text);
                        match_items.add(match_item);
                    }
                }
                
                add_items(match_items);
            } else {
                add_items(history_items);
            }
        }
        
        public void list_history() {
            // Clear list view's items.
            list_items.clear();
            
            // Read history lines.
            // TODO: we need read HISTFILE instead .bash_history.
            GLib.List<string> list = new GLib.List<string>();
            File file = File.new_for_path(GLib.Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_variable("HOME"), ".bash_history"));
            try {
                FileInputStream @is = file.read();
                DataInputStream dis = new DataInputStream(@is);
                string line;

                while ((line = dis.read_line()) != null) {
                    list.append(line);
                }
            } catch (Error e) {
                stdout.printf ("Error: %s\n", e.message);
            }
            list.reverse();
            
            // Add in list view.
            HashSet<string> history_set = new HashSet<string>();
            foreach (string history_line in list) {
                if (history_set.add(history_line)) {
                    HistoryItem item = new HistoryItem(history_line);
                    history_items.add(item);
                }
            }
            
            add_items(history_items);
        }
        
        public override int get_item_height() {
            return height;
        }
        
        public override int[] get_column_widths() {
            return {-1};
        }
    }

    public class HistoryItem : ListItem {
        public string history_text;
        
        public HistoryItem(string text) {
            history_text = text;
        }
        
        public override void render_column_cell(Gtk.Widget widget, Cairo.Context cr, int column_index, int x, int y, int w, int h) {
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_text(widget, cr, history_text, x, y, w, h);
        }
    }
}