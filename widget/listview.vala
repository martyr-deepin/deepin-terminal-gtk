using Gtk;
using Draw;
using Gee;
using Keymap;

namespace Widgets {
    public class ListView : DrawingArea {
        public Gdk.RGBA background_color;
        public Gdk.RGBA item_select_color;
        public ArrayList<ListItem> list_items;
        public int start_row = 0;
        public int current_row = 0;
        
        public signal void active_item(int item_index);
        
        public ListView() {
            set_can_focus(true);  // make widget can receive key event 
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.KEY_PRESS_MASK
                        | Gdk.EventMask.KEY_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            background_color = Gdk.RGBA();
            background_color.parse("#000000");
            item_select_color = Gdk.RGBA();
            item_select_color.parse("#111111");
            
            list_items = new ArrayList<ListItem>();
            
            draw.connect(on_draw);
            key_press_event.connect((w, e) => {
                    on_key_press(w, e);
                    
                    return false;
                });
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            if (get_item_height() > 0 && list_items.size > 0) {
                var render_widths = get_render_widths(alloc.width);
                
                var row_counter = start_row;
                var row_y = 0;
                foreach (ListItem item in list_items[start_row:list_items.size]) {
                    var column_counter = 0;
                    var column_x = 0;
                    
                    if (row_counter == current_row) {
                        Utils.set_context_color(cr, item_select_color);
                        Draw.draw_rectangle(cr, 0, row_y, alloc.width, get_item_height());
                    }
                    
                    foreach (int width in render_widths) {
                        cr.save();
                        clip_rectangle(cr, column_x, row_y, width, get_item_height());
                        item.render_column_cell(this, cr, column_counter, column_x, row_y, width, get_item_height());
                        cr.restore();
                        
                        column_x += width;
                        column_counter++;
                    }
                    
                    row_y += get_item_height();
                    row_counter++;
                    
                    if (row_y > alloc.height) {
                        break;
                    }
                }
            }
            
            return true;
        }
        
        public void on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            if (keyname == "Down") {
                select_next_item();
            } else if (keyname == "Up") {
                select_prev_item();
            } else if (keyname == "Home") {
                select_last_item();
            } else if (keyname == "End") {
                select_first_item();
            } else if (keyname == "Enter") {
                active_item(current_row);
            }
        }
        
        public void select_next_item() {
            current_row = int.min(list_items.size - 1, current_row + 1);
            
            visible_item(true);
            
            queue_draw();
        }
        
        public void select_prev_item() {
            current_row = int.max(0, current_row - 1);
            
            visible_item(false);
            
            queue_draw();
        }
        
        public void select_first_item() {
            current_row = 0;
            
            visible_item(false);
            
            queue_draw();
        }
        
        public void select_last_item() {
            current_row = list_items.size - 1;
            
            visible_item(true);
            
            queue_draw();
        }
        
        public void scroll_vertical(bool scroll_up) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            int scroll_rows = alloc.height / get_item_height();
            int scroll_offset = 2;
            
            if (scroll_up) {
                start_row = int.min(get_max_start_row(), start_row + scroll_rows - scroll_offset);
                current_row = int.min(get_max_current_row(), current_row + scroll_rows - scroll_offset);
            } else {
                start_row = int.max(0, start_row - scroll_rows + scroll_offset);
                current_row = int.max(0, current_row - scroll_rows + scroll_offset);
            }
            
            queue_draw();
        }

        public void visible_item(bool scroll_down) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            if (scroll_down) {
                if ((current_row - start_row + 1) * get_item_height() > alloc.height) {
                    start_row = (current_row * get_item_height() - alloc.height) / get_item_height() + 2;
                }
            } else {
                if (current_row < start_row) {
                    start_row = int.max(0, current_row);
                }
            }
        }
        
        public int[] get_render_widths(int alloc_width) {
            var item_column_widths = get_column_widths();
            int expand_times = 0;
            int fixed_width = 0;
            foreach (int width in item_column_widths) {
                if (width == -1) {
                    expand_times++;
                } else {
                    fixed_width += width;
                }
            }
            
            int[] render_widths = {};
            if (expand_times > 0) {
                int expand_width = (alloc_width - fixed_width) / expand_times;
                foreach (int width in item_column_widths) {
                    if (width == -1) {
                        render_widths += expand_width;
                    } else {
                        render_widths += width;
                    }
                }
            } else {
                render_widths = item_column_widths;
            }

            return render_widths;
        }
        
        public void add_items(ArrayList<ListItem> items) {
            list_items.add_all(items);
            
            if (current_row > list_items.size - 1) {
                current_row = get_max_current_row();
            }
            
            if (start_row > list_items.size - 1) {
                start_row = get_max_start_row();
            }
            
            queue_draw();
        }
        
        private int get_max_current_row() {
            return int.max(0, list_items.size - 1);
        }
        
        private int get_max_start_row() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            return int.max(0, (list_items.size * get_item_height() - alloc.height) / get_item_height() + 1);
        }
        
        public virtual int[] get_column_widths() {
            print("You should implement 'get_column_widths' in your application code.\n");
            
            return {};
        }

        public virtual int get_item_height() {
            print("You should implement 'get_height' in your application code.\n");

            return 0;
        }
    }

    public abstract class ListItem : Object {
        public abstract void render_column_cell(Gtk.Widget widget, Cairo.Context cr, int column_index, int x, int y, int w, int h);
    }
}