using Cairo;
using Draw;
using Gee;
using Gtk;
using Utils;
using Widgets;
using GLib;

namespace Widgets {
    public class Tabbar : Gtk.DrawingArea {
        public ArrayList<int> tab_list;
        public HashMap<int, string> tab_name_map;
        public int height = 30;
        public int tab_index = 0;
        
        public Gdk.Color inactive_arrow_color = Utils.color_from_string("#393937");
        public Gdk.Color hover_arrow_color = Utils.color_from_string("#494943");
        public Gdk.Color hover_text_color = Utils.color_from_string("#ffffff");
        public Gdk.Color text_active_color = Utils.color_from_string("#ffffff");
        public Gdk.Color text_color = Utils.color_from_string("#aaaaaa");
        public Gdk.Color percent_color = Utils.color_from_string("#3880AB");
        
        private Cairo.ImageSurface close_hover_surface;
        private Cairo.ImageSurface close_normal_surface;
        private Cairo.ImageSurface close_press_surface;
        private bool draw_arrow = false;
        private bool draw_hover = false;
        private bool is_button_press = false;
        private int arrow_padding_x = 4;
        private int arrow_padding_y = 10;
        private int arrow_draw_padding_y = 1;
        private int arrow_width = 16;
        private int text_padding_x = 12;
        private int close_button_padding_x = 16;
        private int close_button_padding_y = 0;
        private int close_button_width = 12;
        private int draw_offset = 0;
        private int draw_padding_y = 8;
        private int hover_x = 0;
        
        public Gdk.RGBA tab_active_center_color;
        public Gdk.RGBA tab_active_edge_color;
        public Gdk.RGBA tab_hover_center_color;
        public Gdk.RGBA tab_hover_edge_color;
        
        public signal void press_tab(int tab_index, int tab_id);
        public signal void close_tab(int tab_index, int tab_id);
        
        public Tabbar() {
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
            
            set_size_request(-1, height);
            
            close_normal_surface = new Cairo.ImageSurface.from_png("image/tab_close_normal.png");
            close_hover_surface = new Cairo.ImageSurface.from_png("image/tab_close_hover.png");
            close_press_surface = new Cairo.ImageSurface.from_png("image/tab_close_press.png");
            
            tab_active_center_color = Gdk.RGBA();
            tab_active_center_color.parse("#44FFC4");
            tab_active_center_color.alpha = 0.25;
            
            tab_active_edge_color = Gdk.RGBA();
            tab_active_edge_color.parse("#22FF90");
            tab_active_edge_color.alpha = 0;

            tab_hover_center_color = Gdk.RGBA();
            tab_hover_center_color.parse("#ffffff");
            tab_hover_center_color.alpha = 0.15;
            
            tab_hover_edge_color = Gdk.RGBA();
            tab_hover_edge_color.parse("#ffffff");
            tab_hover_edge_color.alpha = 0;
            
            draw.connect(on_draw);
            configure_event.connect(on_configure);
            button_press_event.connect(on_button_press);
            button_release_event.connect(on_button_release);
            motion_notify_event.connect(on_motion_notify);
            leave_notify_event.connect(on_leave_notify);
        }
        
        public void reset() {
            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
            tab_index = 0;
        }
        
        public void add_tab(string tab_name, int tab_id) {
            tab_list.add(tab_id);
            tab_name_map.set(tab_id, tab_name);
            
            out_of_area();
            
            queue_draw();
        }
        
        public void rename_tab(int tab_id, string tab_name) {
            tab_name_map.set(tab_id, tab_name);
            
            queue_draw();
        }

        public bool is_focus_tab(int tab_id) {
            int? index = tab_list.index_of(tab_id);
            if (index != null) {
                return tab_index == index;
            } else {
                return false;
            }
        }
        
        public void select_next_tab() {
            var index = tab_index + 1;
            if (index >= tab_list.size) {
                index = 0;
            }
            switch_tab(index);
        }
        
        public void select_prev_tab() {
            var index = tab_index - 1;
            if (index < 0) {
                index = tab_list.size - 1;
            }
            switch_tab(index);
        }
        
        public void select_first_tab() {
            switch_tab(0);
        }
        
        public void select_end_tab() {
            var index = 0;
            if (tab_list.size == 0) {
                index = 0;
            } else {
                index = tab_list.size - 1;
            }
            switch_tab(index);
        }
        
        public void select_nth_tab(int index) {
            switch_tab(index);
        }
        
        public void select_tab_with_id(int tab_id) {
            switch_tab(tab_list.index_of(tab_id));
        }

        public void close_current_tab() {
            close_nth_tab(tab_index);
        }
        
        public void close_nth_tab(int index) {
            if (tab_list.size > 0) {
                var tab_id = tab_list.get(index);
                
                tab_list.remove_at(index);
                tab_name_map.unset(tab_id);

                if (tab_list.size == 0) {
                    tab_index = 0;
                } else if (tab_index >= tab_list.size) {
                    tab_index = tab_list.size - 1;
                }
                
                close_tab(index, tab_id);
                
                out_of_area();
                make_current_visible(false);
                
                queue_draw();
            }
        }
        
        public void scroll_left() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            draw_offset += alloc.width / 2;
            if (draw_offset > 0) {
                draw_offset = 0;
            }
            
            queue_draw();
        }
        
        public void scroll_right() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            int draw_x = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += get_tab_width(name_width);
            }
            
            draw_offset -= alloc.width / 2;
            if (draw_offset < alloc.width - arrow_width * 2 - draw_x) {
                draw_offset = alloc.width - arrow_width * 2 - draw_x;
            }
            
            queue_draw();
        }
        
        public bool on_configure(Gtk.Widget widget, Gdk.EventConfigure event) {
            out_of_area();
            make_current_visible(true);
            
            return false;
        }
        
        public bool on_button_press(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = true;
            
            var press_x = (int)event.x;
            
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            if (draw_arrow) {
                if (press_x < arrow_width) {
                    scroll_left();
                    return true;
                } else if (press_x > alloc.width - arrow_width) {
                    scroll_right();
                    return true;
                }
            }
            
            int draw_x = 0;
            if (draw_arrow) {
                draw_x += arrow_width + draw_offset;
            }
            
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += text_padding_x;
                
                if (press_x > draw_x && press_x < draw_x + get_tab_width(name_width)) {
                    if (press_x < draw_x + name_width + text_padding_x) {
                        select_nth_tab(counter);
                        
                        press_tab(counter, tab_id);
                        return false;
                    }
                }
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter++;
            }
            
            queue_draw();
            
            return false;
        }

        public bool on_button_release(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = false;
            
            var release_x = (int)event.x;
            
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            int draw_x = 0;
            if (draw_arrow) {
                draw_x += arrow_width + draw_offset;
            }
            
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += text_padding_x;
                
                if (release_x > draw_x && release_x < draw_x + get_tab_width(name_width)) {
                    if (release_x > draw_x + name_width) {
                        close_nth_tab(counter);
                        return false;
                    }
                }
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter++;
            }
            
            queue_draw();
            
            return false;
        }
        
        public bool on_motion_notify(Gtk.Widget widget, Gdk.EventMotion event) {
            draw_hover = true;
            hover_x = (int)event.x;
            
            queue_draw();
            
            return false;
        }
        
        public bool on_leave_notify(Gtk.Widget widget, Gdk.EventCrossing event) {
            draw_hover = false;
            hover_x = 0;
            
            queue_draw();
            
            return false;
        }
        
        public int make_current_visible(bool left) {
            if (draw_arrow) {
                Gtk.Allocation alloc;
                this.get_allocation(out alloc);
                
                int draw_x = 0;
                int counter = 0;
                foreach (int tab_id in tab_list) {
                    var layout = create_pango_layout(tab_name_map.get(tab_id));
                    int name_width, name_height;
                    layout.get_pixel_size(out name_width, out name_height);
                    
                    if (tab_index == 0) {
                        draw_offset = 0;
                        return draw_offset;
                    } else {
                        if (left) {
                            draw_x += get_tab_width(name_width);
                            
                            if (counter == tab_index) {
                                if (draw_x > -draw_offset + alloc.width - arrow_width * 2) {
                                    draw_offset = alloc.width - draw_x - arrow_width - close_button_width;
                                    return draw_offset;
                                }
                            }
                        } else {
                            if (tab_index == tab_list.size - 1) {
                                draw_offset = -draw_x + alloc.width - arrow_width - get_tab_width(name_width) - close_button_width;
                            } else if (counter == tab_index) {
                                if (draw_x < -draw_offset - arrow_width) {
                                    draw_offset = -draw_x + arrow_width - close_button_width;
                                    return draw_offset;
                                }
                            }
                            
                            draw_x += get_tab_width(name_width);
                        }
                    }
                    
                    counter++;
                }
                
                return draw_offset;
            }
            
            return 0;
        }
        
        public bool out_of_area() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            int draw_x = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                
                draw_x += get_tab_width(name_width);
                
                if (draw_x > alloc.width) {
                    draw_arrow = true;
                    return true;
                }
            }
            
            draw_arrow = false;
            draw_offset = 0;
            return false;
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            if (draw_arrow) {
                Utils.set_context_color(cr, inactive_arrow_color);
                Draw.draw_rectangle(cr, 0, arrow_draw_padding_y, arrow_width, alloc.height - arrow_draw_padding_y * 2);
                
                if (draw_hover) {
                    if (hover_x < arrow_width) {
                        Utils.set_context_color(cr, hover_text_color);
                    } else {
                        Utils.set_context_color(cr, text_color);
                    }
                } else {
                    Utils.set_context_color(cr, text_color);
                }
                Draw.draw_text(this, cr, "<", arrow_padding_x, arrow_padding_y);
                
                Utils.set_context_color(cr, inactive_arrow_color);
                Draw.draw_rectangle(cr, alloc.width - arrow_width, arrow_draw_padding_y, arrow_width, alloc.height - arrow_draw_padding_y * 2);
                
                if (draw_hover) {
                    if (hover_x > alloc.width - arrow_width) {
                        Utils.set_context_color(cr, hover_text_color);
                    } else {
                        Utils.set_context_color(cr, text_color);
                    }
                } else {
                    Utils.set_context_color(cr, text_color);
                }
                Draw.draw_text(this, cr, ">", alloc.width - arrow_width + arrow_padding_x, arrow_padding_y);
                
                Draw.clip_rectangle(cr, arrow_width, 0, alloc.width - arrow_width * 2, alloc.height);
            }
            
            int draw_x = 0;
            if (draw_arrow) {
                draw_x += arrow_width + draw_offset;
            }
            
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                
                Gdk.Color tab_text_color = text_color;
                
                if (counter == tab_index) {
                    cr.save();
                    clip_rectangle(cr, draw_x, 0, get_tab_width(name_width), height);
                    
                    double scale_x = 1;
                    double scale_y = ((double) height * 2) / get_tab_width(name_width);
                    cr.translate(0, height / 2);
                    cr.scale(scale_x, scale_y);
                    Draw.draw_radial(cr, draw_x, get_tab_width(name_width), height, tab_active_center_color, tab_active_edge_color);
                    
                    cr.restore();
                    
                    tab_text_color = text_active_color;
                } else {
                    var is_hover = false;
                    
                    if (draw_hover) {
                        if (hover_x > draw_x && hover_x < draw_x + get_tab_width(name_width)) {
                            is_hover = true;
                        }
                    }
                    
                    if (is_hover) {
                        cr.save();
                        clip_rectangle(cr, draw_x, 0, get_tab_width(name_width), height);
                    
                        double scale_x = 1;
                        double scale_y = ((double) height * 2) / get_tab_width(name_width);
                        cr.translate(0, height / 2);
                        cr.scale(scale_x, scale_y);
                        Draw.draw_radial(cr, draw_x, get_tab_width(name_width), height, tab_hover_center_color, tab_hover_edge_color);
                    
                        cr.restore();
                        
                        tab_text_color = text_active_color;
                    } else {
                        cr.set_source_rgba(0, 0, 0, 0);
                        Draw.draw_rectangle(cr, draw_x, 0, get_tab_width(name_width), height);
                    }
                }
                
                if (draw_hover) {
                    if (hover_x > draw_x && hover_x < draw_x + get_tab_width(name_width)) {
                        if (hover_x > draw_x + name_width) {
                            if (is_button_press) {
                                Draw.draw_surface(cr, close_press_surface, draw_x + name_width + close_button_padding_x, draw_padding_y + close_button_padding_y);
                            } else {
                                Draw.draw_surface(cr, close_hover_surface, draw_x + name_width + close_button_padding_x, draw_padding_y + close_button_padding_y);
                            }
                        } else {
                            Draw.draw_surface(cr, close_normal_surface, draw_x + name_width + close_button_padding_x, draw_padding_y + close_button_padding_y);
                        }
                    }
                }
                cr.set_source_rgba(1, 1, 1, 0.1);
                Draw.draw_rectangle(cr, draw_x + get_tab_width(name_width) - 1, 0, 1, height);
                
                Utils.set_context_color(cr, tab_text_color);
                Draw.draw_layout(cr, layout, draw_x + text_padding_x, draw_padding_y);
                
                draw_x += name_width + close_button_width + text_padding_x * 2;
                
                counter++;
            }
            
            return true;
        }

        public int get_tab_width(int name_width) {
            return name_width + close_button_width + text_padding_x * 2;
        }
        
        public void switch_tab(int new_index) {
            tab_index = new_index;
            
            press_tab(tab_index, tab_list.get(tab_index));
                
            make_current_visible(true);
            queue_draw();
        }
    }
}