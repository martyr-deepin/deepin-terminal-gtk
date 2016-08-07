using Gtk;
using Config;
using Cairo;

namespace Widgets {
    public class BaseWindow : Gtk.Window {
        public Config.Config config;
        
        public double window_frame_radius = 5.0;
        public int window_shadow_radius;
        public int window_active_shadow_radius = 20;
        public int window_inactive_shadow_radius = 14;
        public int window_shadow_offset_y = 10;
        
        public int window_frame_margin_top = 40;
        public int window_frame_margin_bottom = 40;
        public int window_frame_margin_left = 40;
        public int window_frame_margin_right = 40;
        
        public int window_widget_margin_top = 1;
        public int window_widget_margin_bottom = 2;
        public int window_widget_margin_left = 2;
        public int window_widget_margin_right = 2;
        
        public Gtk.Box window_frame_box;
        public Gtk.Box window_widget_box;
        
        public bool window_is_normal = true;
        public bool window_frameless;
        
        public int window_width;
        public int window_height;
        
        public Gtk.Widget window_widget;
        
        public Cairo.ImageSurface shadow_surface;
        public int shadow_surface_width = 0;
        public int shadow_surface_height = 0;

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
            
            window_shadow_radius = window_active_shadow_radius;
            
            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_widget_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            add(window_frame_box);
            window_frame_box.pack_start(window_widget_box, true, true, 0);
            
            focus_in_event.connect((w) => {
                    window_shadow_radius = window_active_shadow_radius;

                    queue_draw();
                    
                    return false;
                });
            
            focus_out_event.connect((w) => {
                    window_shadow_radius = window_inactive_shadow_radius;
                    
                    queue_draw();
                    
                    return false;
                });
            
            configure_event.connect((w) => {
                    int width, height;
                    get_size(out width, out height);
                    window_width = width - window_frame_box.margin_left - window_frame_box.margin_right;
                    window_height = height - window_frame_box.margin_top - window_frame_box.margin_bottom;
                    
                    if (window_width != shadow_surface_width || window_height != shadow_surface_height) {
                        update_shadow_surface();
                        
                        shadow_surface_width = window_width;
                        shadow_surface_height = window_height;
                    }
					
                    queue_draw();
					
					return false;
                });

            window_state_event.connect((w, e) => {
                    if (!window_frameless) {
                        var state = e.new_window_state;
                        if (Gdk.WindowState.MAXIMIZED in state || Gdk.WindowState.FULLSCREEN in state || Gdk.WindowState.TILED in state) {
                            window_is_normal = false;
                                
                            remove_margins();
                        } else {
                            window_is_normal = true;
                                
                            add_margins();
                        }
                    }
                    
                    return false;
                });
            
            draw.connect_after((w, cr) => {
                    draw_window_below(cr);
                       
                    if (!window_frameless && window_is_normal) {
                        draw_window_shadow(cr);
                    }
                       
                    draw_window_widgets(cr);

                    draw_window_frame(cr);
                       
                    draw_window_above(cr);
                    
                    return true;
                });
        }
        
        public void add_margins() {
            window_frame_box.margin_top = window_frame_margin_top;
            window_frame_box.margin_bottom = window_frame_margin_bottom;
            window_frame_box.margin_left = window_frame_margin_left;
            window_frame_box.margin_right = window_frame_margin_right;
            
            window_widget_box.margin_top = window_widget_margin_top;
            window_widget_box.margin_bottom = window_widget_margin_bottom;
            window_widget_box.margin_left = window_widget_margin_left;
            window_widget_box.margin_right = window_widget_margin_right;
        }
        
        public void remove_margins() {
            window_frame_box.margin = 0;
        }
        
        public void draw_window_shadow(Cairo.Context cr) {
            cr.save();
            
            Gtk.Allocation rect;
            get_allocation(out rect);

            cr.set_source_rgba(0, 0, 0, 0);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);
            cr.paint();
            
            // Top.
            cr.rectangle(0, 0, rect.width, window_frame_box.margin_top);
            // Top-Left.
            cr.rectangle(window_frame_box.margin_left, window_frame_box.margin_top, window_frame_radius, 1);
            cr.rectangle(window_frame_box.margin_left, window_frame_box.margin_top, 1, window_frame_radius);
            cr.rectangle(window_frame_box.margin_left + 1, window_frame_box.margin_top + 1, 2, 1);
            cr.rectangle(window_frame_box.margin_left + 1, window_frame_box.margin_top + 1, 1, 2);
            // Top-Right.
            cr.rectangle(rect.width - window_frame_box.margin_right - window_frame_radius, window_frame_box.margin_top, window_frame_radius, 1);
            cr.rectangle(rect.width - window_frame_box.margin_right - 1, window_frame_box.margin_top, 1, window_frame_radius);
            cr.rectangle(rect.width - window_frame_box.margin_right - 3, window_frame_box.margin_top + 1, 2, 1);
            cr.rectangle(rect.width - window_frame_box.margin_right - 2, window_frame_box.margin_top + 1, 1, 2);
            // Left.
            cr.rectangle(0, 0, window_frame_box.margin_left, rect.height - window_frame_radius);
            // Right.
            cr.rectangle(rect.width - window_frame_box.margin_right, 0, window_frame_box.margin_right, rect.height - window_frame_radius);
            // Bottom.
            cr.rectangle(0, rect.height - window_frame_box.margin_bottom - window_frame_radius, rect.width, window_frame_box.margin_bottom + window_frame_radius);
            cr.clip();
			
            Draw.draw_surface(cr, shadow_surface, 0, window_shadow_offset_y);                
            cr.restore();
        }
        
        public void update_shadow_surface() {
            Gtk.Allocation rect;
            get_allocation(out rect);
            
            shadow_surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, rect.width, rect.height);
            Cairo.Context shadow_surface_cr = new Cairo.Context(shadow_surface);
			
            shadow_surface_cr.set_source_rgba(1, 0, 0, 1);
            // shadow_surface_cr.set_source_rgba(0, 0, 0, 0.3);
            Draw.draw_rounded_rectangle(
                shadow_surface_cr,
                window_frame_box.margin_left,
                window_frame_box.margin_top,
                rect.width - window_frame_box.margin_left - window_frame_box.margin_right,
                rect.height - window_frame_box.margin_top - window_frame_box.margin_bottom,
                window_frame_radius);
            
            Utils.ExponentialBlur.surface(shadow_surface, window_shadow_radius);
        }
        
        public void draw_window_widgets(Cairo.Context cr) {
            Utils.propagate_draw(this, cr);
            // Utils.propagate_draw((Gtk.Container) window_widget, cr);
        }
        
        public void draw_window_frame(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_left;
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
            
            window_widget = widget;
        }

		public void toggle_fullscreen () {
            var state = get_window().get_state();
            if (Gdk.WindowState.FULLSCREEN in state) {
                unfullscreen();
            } else {
                fullscreen();
            }
        }
        
        public void set_window_size(int width, int height) {
            if (window_frameless) {
                set_size_request(width, height);
            } else {
                set_default_size(
                    width + window_frame_margin_left + window_frame_margin_right,
                    height + window_frame_margin_top + window_frame_margin_bottom);
            }
        }
        
        public virtual void draw_window_below(Cairo.Context cr) {
            
        }
        
        public virtual void draw_window_above(Cairo.Context cr) {
            
        }
    }
}