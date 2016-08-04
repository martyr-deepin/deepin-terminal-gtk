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
		public HashMap<int, bool> tab_highlight_map;
        public int height = 40;
        public int tab_index = 0;
        
        public Gdk.RGBA inactive_arrow_color;
        public Gdk.RGBA hover_arrow_color;
        public Gdk.RGBA text_hover_color;
        public Gdk.RGBA text_active_color;
        public Gdk.RGBA text_color;
        public Gdk.RGBA text_highlight_color;
		public Gdk.RGBA tab_split_color;
        
        private Cairo.ImageSurface close_hover_surface;
        private Cairo.ImageSurface close_normal_surface;
        private Cairo.ImageSurface close_press_surface;
        
        private Cairo.ImageSurface add_hover_surface;
        private Cairo.ImageSurface add_normal_surface;
        private Cairo.ImageSurface add_press_surface;

        private double draw_scale = 1.0;
        
        private bool draw_hover = false;
        private bool is_button_press = false;
        
        private int add_button_width = 50;
        private int add_button_padding_x = 0;
        private int add_button_padding_y = 0;
        
        private int tab_split_width = 1;
        
        private int text_padding_x = 36;
        private int close_button_padding_x = 28;
        private int close_button_padding_y = 0;
        private int draw_padding_y = 12;
        private int hover_x = 0;
        
		public signal void press_tab(int tab_index, int tab_id);
        public signal void close_tab(int tab_index, int tab_id);
        public signal void new_tab();
		public signal void draw_active_tab_underline(int x, int width);
		
		public bool quake_mode = false;
		
        
        public Tabbar(bool mode) {
			quake_mode = mode;
			
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
			tab_highlight_map = new HashMap<int, bool>();
            
            set_size_request(-1, height);
            
            close_normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("tab_close_normal.png"));
            close_hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("tab_close_hover.png"));
            close_press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("tab_close_press.png"));

            add_normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("tab_add_normal.png"));
            add_hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("tab_add_hover.png"));
            add_press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("tab_add_press.png"));
            
            inactive_arrow_color = Gdk.RGBA();
            inactive_arrow_color.parse("#393937");

            hover_arrow_color = Gdk.RGBA();
            hover_arrow_color.parse("#494943");
            
            text_hover_color = Gdk.RGBA();
            text_hover_color.parse("#ffffff");
            
            text_active_color = Gdk.RGBA();
            text_active_color.parse("#2CA7F8");
            
            text_color = Gdk.RGBA();
			text_color.red = 1;
			text_color.green = 1;
			text_color.blue = 1;
			text_color.alpha = 0.8;

            text_highlight_color = Gdk.RGBA();
            text_highlight_color.parse("#ff9600");
			
			tab_split_color = Gdk.RGBA();
			tab_split_color.red = 1;
			tab_split_color.green = 1;
			tab_split_color.blue = 1;
			tab_split_color.alpha = 0.05;
			
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
            
            update_tab_scale();
            
            queue_draw();
        }
        
        public void rename_tab(int tab_id, string tab_name) {
            tab_name_map.set(tab_id, tab_name);
            
            update_tab_scale();
            
            queue_draw();
        }
		
		public void highlight_tab(int tab_id) {
			if (!tab_highlight_map.has_key(tab_id)) {
				tab_highlight_map.set(tab_id, true);
				
				queue_draw();
			}
		}
		
		public void unhighlight_tab(int tab_id) {
			if (tab_highlight_map.has_key(tab_id)) {
				tab_highlight_map.unset(tab_id);
				
				queue_draw();
			}
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
        
        public void select_previous_tab() {
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
                close_tab(index, tab_id);
            }
        }
        
        public void destroy_tab(int index) {
            var tab_id = tab_list.get(index);
                
            tab_list.remove_at(index);
            tab_name_map.unset(tab_id);

            if (tab_list.size == 0) {
                tab_index = 0;
            } else if (tab_index >= tab_list.size) {
                tab_index = tab_list.size - 1;
            }
            
            update_tab_scale();
            
            queue_draw();
        }
        
        public bool on_configure(Gtk.Widget widget, Gdk.EventConfigure event) {
            update_tab_scale();
            
            queue_draw();
            
            return false;
        }
        
        public bool on_button_press(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = true;
            
            var press_x = (int)event.x;
            
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            int draw_x = 0;
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                int tab_width = (int) (get_tab_width(name_width) * draw_scale);

                if (press_x > draw_x && press_x < draw_x + tab_width - close_button_padding_x) {
                    select_nth_tab(counter);
                        
                    press_tab(counter, tab_id);
                    return false;
                }
                
                draw_x += tab_width;
                
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
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                int tab_width = (int) (get_tab_width(name_width) * draw_scale);

                if (release_x > draw_x && release_x < draw_x + tab_width) {
                    if (release_x > draw_x + tab_width - close_button_padding_x) {
                        close_nth_tab(counter);
                        return false;
                    }
					
					// Click tab to unlight tab if have.
					unhighlight_tab(tab_id);
                }
                
                draw_x += tab_width;
                
                counter++;
            }
            
            if (release_x > draw_x + add_button_padding_x && release_x < draw_x + add_button_padding_x + add_button_width) {
                new_tab();
            }
            
            queue_draw();
            
            return false;
        }
        
        public bool on_motion_notify(Gtk.Widget widget, Gdk.EventMotion event) {
            draw_hover = true;
            hover_x = (int) event.x;
            
            queue_draw();
            
            return false;
        }
        
        public bool on_leave_notify(Gtk.Widget widget, Gdk.EventCrossing event) {
            draw_hover = false;
            hover_x = 0;
            
            queue_draw();
            
            return false;
        }
        
        public void update_tab_scale() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            int tab_add_button_width = add_button_width + add_button_padding_x * 2;
            int tab_width = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                
                tab_width += get_tab_width(name_width);
            }
            
            if (tab_width + tab_add_button_width > alloc.width) {
                draw_scale = (double) alloc.width / tab_width * 0.97;
            } else {
                draw_scale = 1.0;
            }
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
			
			if (quake_mode) {
				// Draw background under titlebar.
				cr.set_operator(Cairo.Operator.OVER);
				cr.set_source_rgba(0, 0, 0, 0.2);
				Draw.draw_rectangle(cr, 0, 0, alloc.width, height);
				
				// Draw bottom line.
				cr.set_operator(Cairo.Operator.OVER);
				cr.set_source_rgba(1, 1, 1, 0.05);
				Draw.draw_rectangle(cr, 0, alloc.height - 2, alloc.width, 1);
			}				
            
            int draw_x = 0;
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height, name_scale_width;
                layout.get_pixel_size(out name_width, out name_height);
                name_scale_width = (int) (name_width * draw_scale);
                int tab_width = (int) (get_tab_width(name_width) * draw_scale);
                
				Gdk.RGBA tab_text_color;
				if (tab_highlight_map.has_key(tab_id)) {
					tab_text_color = text_highlight_color;
				} else {
					tab_text_color = text_color;
				}
                
                if (counter == tab_index) {
                    cr.save();
                    clip_rectangle(cr, draw_x, 0, tab_width, height);
                    
					draw_active_tab_underline(draw_x, tab_width - 1);
					
                    cr.restore();
                    
                    tab_text_color = text_active_color;
                } else {
                    var is_hover = false;
                    
                    if (draw_hover) {
                        if (hover_x > draw_x && hover_x < draw_x + tab_width) {
                            is_hover = true;
                        }
                    }
                    
                    if (is_hover) {
                        cr.save();
                        clip_rectangle(cr, draw_x, 0, tab_width, height);
                    
						Utils.set_context_color(cr, tab_split_color);
						Draw.draw_rectangle(cr, draw_x, 0, tab_width, height);
                    
                        cr.restore();
                        
                        tab_text_color = text_active_color;
                    } else {
                        cr.set_source_rgba(0, 0, 0, 0);
                        Draw.draw_rectangle(cr, draw_x, 0, tab_width, height);
                    }
                }
                
                if (draw_hover) {
                    if (hover_x > draw_x && hover_x < draw_x + tab_width) {
                        if (hover_x > draw_x + tab_width - close_button_padding_x) {
                            if (is_button_press) {
                                Draw.draw_surface(cr, close_press_surface, draw_x + tab_width - close_button_padding_x, draw_padding_y + close_button_padding_y);
                            } else {
                                Draw.draw_surface(cr, close_hover_surface, draw_x + tab_width - close_button_padding_x, draw_padding_y + close_button_padding_y);
                            }
                        } else {
                            Draw.draw_surface(cr, close_normal_surface, draw_x + tab_width - close_button_padding_x, draw_padding_y + close_button_padding_y);
                        }
                    }
                }
                
                // Draw tab splitter.
				// But don't draw last splitter to avoid duplicate with 'add' button.
				Utils.set_context_color(cr, tab_split_color);
				if (counter < tab_list.size - 1) {
					Draw.draw_rectangle(cr, draw_x + tab_width - tab_split_width, 0, tab_split_width, height);
				}
                
                // Draw tab text.
                cr.save();
                clip_rectangle(cr, draw_x + text_padding_x, 0, tab_width - text_padding_x * 2, height);
                
                Utils.set_context_color(cr, tab_text_color);
                Draw.draw_layout(cr, layout, draw_x + text_padding_x, draw_padding_y);
                
                cr.restore();
                
                draw_x += tab_width;
                
                counter++;
            }
            
            if (hover_x > draw_x + add_button_padding_x && hover_x < draw_x + add_button_padding_x + add_button_width) {
                if (is_button_press) {
                    Draw.draw_surface(cr, add_press_surface, draw_x + add_button_padding_x, add_button_padding_y);
                } else if (draw_hover) {
                    Draw.draw_surface(cr, add_hover_surface, draw_x + add_button_padding_x, add_button_padding_y);
                }
            } else {
                Draw.draw_surface(cr, add_normal_surface, draw_x + add_button_padding_x, add_button_padding_y);
            }
            
            return true;
        }

        public int get_tab_width(int name_width) {
            return name_width + text_padding_x * 2;
        }
        
        public void switch_tab(int new_index) {
            tab_index = new_index;
            
            press_tab(tab_index, tab_list.get(tab_index));
                
            queue_draw();
        }
    }
}