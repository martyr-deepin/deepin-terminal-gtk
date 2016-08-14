using Gtk;
using Config;
using Cairo;

namespace Widgets {
    public class BaseWindow : Gtk.Window {
        public Config.Config config;
        
        public double window_frame_radius = 5.0;
        public int window_shadow_offset_y = 10;
        
        public int window_frame_margin_top = 50;
        public int window_frame_margin_bottom = 60;
        public int window_frame_margin_start = 50;
        public int window_frame_margin_end = 50;
        
        public int window_widget_margin_top = 1;
        public int window_widget_margin_bottom = 2;
        public int window_widget_margin_start = 2;
        public int window_widget_margin_end = 2;
        
        public int window_save_width = 0;
        public int window_save_height = 0;
        
        public Gtk.Box window_frame_box;
        public Gtk.Box window_widget_box;
        
        public bool window_is_normal = true;
        public bool window_frameless;
        
        public int window_width;
        public int window_height;
        
        public BaseWindow(bool frameless=false) {
            window_frameless = frameless;
            
            load_config();
            transparent_window();
            init_window();
        }
        
        public void load_config() {
            config = new Config.Config();
        }
        
        public void transparent_window() {
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());
        }
        
        public void init_window() {
            set_decorated(false);
            
            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_widget_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            add(window_frame_box);
            window_frame_box.pack_start(window_widget_box, true, true, 0);
            
            focus_in_event.connect((w) => {
                    shadow_active();
                    
                    return false;
                });
            
            focus_out_event.connect((w) => {
                    shadow_inactive();
                    
                    return false;
                });
            
            configure_event.connect((w) => {
                    int width, height;
                    get_size(out width, out height);
                    
                    if (!window_is_max() && !window_is_fullscreen() && !window_is_tiled()) {
                    
                        window_save_width = width - window_frame_margin_start - window_frame_margin_end;
                        window_save_height = height - window_frame_margin_top - window_frame_margin_bottom;
                    }
                    
                    Cairo.RectangleInt rect;
                    get_window().get_frame_extents(out rect);
                    
                    if (window_is_max() || window_is_fullscreen() || window_is_tiled()) {
                        rect.x = 0;
                        rect.y = 0;
                        rect.width = width;
                        rect.height = height;
                    } else {
                        rect.x = window_frame_margin_start;
                        rect.y = window_frame_margin_top;
                        rect.width = width - window_frame_margin_start - window_frame_margin_end;
                        rect.height = height - window_frame_margin_top - window_frame_margin_bottom;
                    }
                    
                    var shape = new Cairo.Region.rectangle(rect);
                    get_window().input_shape_combine_region(shape, 0, 0);
                    
                    queue_draw();
					
					return false;
                });
            
            window_state_event.connect((w, e) => {
                    if (!window_frameless) {
                        if (window_is_max() || window_is_fullscreen() || window_is_tiled()) {
                            window_is_normal = false;
                            get_window().set_shadow_width(0, 0, 0, 0);
                                
                            remove_margins();
                        } else {
                            window_is_normal = true;
                            
                            get_window().set_shadow_width(window_frame_margin_start, window_frame_margin_end, window_frame_margin_top, window_frame_margin_bottom);
                                
                            add_margins();
                        }
                    }
                    
                    return false;
                });
            
            motion_notify_event.connect((w, e) => {
                    int response_radius = 5;
                    if (!window_frameless && get_resizable()) {
                        var display = Gdk.Display.get_default();
                        
                        int window_x, window_y;
                        get_window().get_origin(out window_x, out window_y);
                        
                        int width, height;
                        get_size(out width, out height);
                        
                        var left_side_start = window_x + window_frame_margin_start;
                        var left_side_end = window_x + window_frame_margin_start + response_radius;
                        var right_side_start = window_x + width - window_frame_margin_end - response_radius;
                        var right_side_end = window_x + width - window_frame_margin_end;
                        var top_side_start = window_y + window_frame_margin_top;
                        var top_side_end = window_y + window_frame_margin_top + response_radius;
                        var bottom_side_start = window_y + height - window_frame_margin_bottom - response_radius;
                        var bottom_side_end = window_y + height - window_frame_margin_bottom;
                        
                        if (e.x_root > left_side_start && e.x_root < left_side_end) {
                            if (e.y_root > top_side_start && e.y_root < top_side_end) {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.TOP_LEFT_CORNER));
                            } else if (e.y_root > bottom_side_start && e.y_root < bottom_side_end) {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.BOTTOM_LEFT_CORNER));
                            } else {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.LEFT_SIDE));
                            }
                        } else if (e.x_root > right_side_start && e.x_root < right_side_end) {
                            if (e.y_root > top_side_start && e.y_root < top_side_end) {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.TOP_RIGHT_CORNER));
                            } else if (e.y_root > bottom_side_start && e.y_root < bottom_side_end) {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.BOTTOM_RIGHT_CORNER));
                            } else {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.RIGHT_SIDE));
                            }
                        } else {
                            if (e.y_root > top_side_start && e.y_root < top_side_end) {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.TOP_SIDE));
                            } else if (e.y_root > bottom_side_start && e.y_root < bottom_side_end) {
                                get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.BOTTOM_SIDE));
                            } else {
                                get_window().set_cursor(null);
                            }
                        }
                    }
                    
                    return false;
                });
            
            draw.connect_after((w, cr) => {
                    draw_window_below(cr);
                       
                    draw_window_widgets(cr);

                    draw_window_frame(cr);
                       
                    draw_window_above(cr);
                    
                    return true;
                });
        }
        
        public void add_margins() {
            window_frame_box.margin_top = window_frame_margin_top;
            window_frame_box.margin_bottom = window_frame_margin_bottom;
            window_frame_box.margin_start = window_frame_margin_start;
            window_frame_box.margin_end = window_frame_margin_end;
            
            window_widget_box.margin_top = window_widget_margin_top;
            window_widget_box.margin_bottom = window_widget_margin_bottom;
            window_widget_box.margin_start = window_widget_margin_start;
            window_widget_box.margin_end = window_widget_margin_end;
        }
        
        public void remove_margins() {
            window_frame_box.margin = 0;
        }
        
        public void shadow_active() {
            window_widget_box.get_style_context().remove_class("window_shadow_inactive");
            window_widget_box.get_style_context().add_class("window_shadow_active");
        }
        
        public void shadow_inactive() {
            window_widget_box.get_style_context().remove_class("window_shadow_active");
            window_widget_box.get_style_context().add_class("window_shadow_inactive");
        }
        
        public void draw_window_widgets(Cairo.Context cr) {
            Utils.propagate_draw(this, cr);
            // Utils.propagate_draw((Gtk.Container) window_widget, cr);
        }
        
        public void draw_window_frame(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;
            Gdk.RGBA frame_color = Gdk.RGBA();
            
            if (!window_frameless && window_is_normal) {
                try {
                    frame_color.parse(config.config_file.get_string("theme", "color1"));
                
                    // Draw inner dot *under* window　frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity") * 0.6);
                    // Top.
                    Draw.draw_rectangle(cr, x + 4, y, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 5, y, 1, 1);
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 4, y + height - 1, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 5, y + height - 1, 1, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x, y + 4, 1, 1);
                    Draw.draw_rectangle(cr, x, y + height - 5, 1, 1);
                    // Rigt.
                    Draw.draw_rectangle(cr, x + width - 1, y + 4, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 1, y + height - 5, 1, 1);
                    cr.restore();
					
                    // Draw middle dot *under* window　frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity") * 0.4);
                    // Top.
                    Draw.draw_rectangle(cr, x + 3, y, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 4, y, 1, 1);
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 3, y + height - 1, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 4, y + height - 1, 1, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x, y + 3, 1, 1);
                    Draw.draw_rectangle(cr, x, y + height - 4, 1, 1);
                    // Rigt.
                    Draw.draw_rectangle(cr, x + width - 1, y + 3, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 1, y + height - 4, 1, 1);
                    cr.restore();

                    // Draw out dot *under* window　frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity") * 0.2);
                    // Top.
                    Draw.draw_rectangle(cr, x + 2, y, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 3, y, 1, 1);
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 2, y + height - 1, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 3, y + height - 1, 1, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x, y + 2, 1, 1);
                    Draw.draw_rectangle(cr, x, y + height - 3, 1, 1);
                    // Rigt.
                    Draw.draw_rectangle(cr, x + width - 1, y + 2, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 1, y + height - 3, 1, 1);
                    cr.restore();

                    // Draw out_corner dot *under* window　frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity") * 0.25);
                    // Top left.
                    Draw.draw_rectangle(cr, x + 1, y + 1, 1, 1);
                    // Top right.
                    Draw.draw_rectangle(cr, x + width - 2, y + 1, 1, 1);
                    // Bottm left.
                    Draw.draw_rectangle(cr, x + 1, y + height - 2, 1, 1);
                    // Bottom right.
                    Draw.draw_rectangle(cr, x + width - 2, y + height - 2, 1, 1);
                    cr.restore();
					
                    // Draw out dot *under* window　frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity") * 0.5);
                    // Top.
                    Draw.draw_rectangle(cr, x + 2, y + 1, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 3, y + 1, 1, 1);
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 2, y + height - 2, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 3, y + height - 2, 1, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x + 1, y + 2, 1, 1);
                    Draw.draw_rectangle(cr, x + 1, y+ height - 3, 1, 1);
                    // Rigt.
                    Draw.draw_rectangle(cr, x + width - 2, y + 2, 1, 1);
                    Draw.draw_rectangle(cr, x + width - 2, y + height - 3, 1, 1);
                    cr.restore();
					
                    // Draw window frame.
                    cr.save();
                    cr.set_source_rgba(0, 0, 0, config.config_file.get_double("general", "opacity"));
                    // Top.
                    Draw.draw_rectangle(cr, x + 5, y, width - 10, 1);
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 5, y + height - 1, width - 10, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x, y + 5, 1, height - 10);
                    // Rigt..
                    Draw.draw_rectangle(cr, x + width - 1, y + 5, 1, height - 10);
                    cr.restore();

                    // Draw line *innner* of window frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity"));
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 3, y + height - 2, width - 6, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x + 1, y + 3, 1, height - 6);
                    // Rigt..
                    Draw.draw_rectangle(cr, x + width - 2, y + 3, 1, height - 6);
                    cr.restore();

                    // Draw line below of window frame.
                    // cr.set_operator(Cairo.Operator.OVER);
                    cr.set_source_rgba(1, 1, 1, 0.0625 * config.config_file.get_double("general", "opacity"));
                    // cr.set_source_rgba(1, 0, 0, 1);
                    Draw.draw_rectangle(cr, x + 3, y + 1, width - 6, 1);
                } catch (GLib.KeyFileError e) {
                    print(e.message);
                }
            } else {
                try {
                    // Draw window frame.
                    cr.save();
                    cr.set_source_rgba(0, 0, 0, config.config_file.get_double("general", "opacity"));
                    Draw.draw_rectangle(cr, x, y, width, height, false);
                    
                    // Draw line *innner* of window frame.
                    frame_color.parse(config.config_file.get_string("theme", "color1"));
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity"));
                    Draw.draw_rectangle(cr, x + 1, y + 1, width - 2 , height - 2, false);
                } catch (GLib.KeyFileError e) {
                    print(e.message);
                }
            }
        }
        
        public void add_widget(Gtk.Widget widget) {
            window_widget_box.pack_start(widget, true, true, 0);
        }

		public void toggle_fullscreen() {
            if (window_is_fullscreen()) {
                unfullscreen();
            } else {
                fullscreen();
            }
        }
        
        public void toggle_max() {
            if (window_is_max()) {
                unmaximize();
            } else {
                maximize();
            }
        }
        
        public void set_window_size(int width, int height) {
            if (window_frameless) {
                set_size_request(width, height);
            } else {
                set_default_size(
                    width + window_frame_margin_start + window_frame_margin_end,
                    height + window_frame_margin_top + window_frame_margin_bottom);
            }
        }
        
        public virtual void draw_window_below(Cairo.Context cr) {
            
        }
        
        public virtual void draw_window_above(Cairo.Context cr) {
            
        }
        
        public bool window_is_max() {
            return Gdk.WindowState.MAXIMIZED in get_window().get_state();
        }
        
        public bool window_is_tiled() {
            return Gdk.WindowState.TILED in get_window().get_state();
        }
        
        public bool window_is_fullscreen() {
            return Gdk.WindowState.FULLSCREEN in get_window().get_state();
        }
    }
}
