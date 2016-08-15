using Gtk;
using Widgets;

namespace Widgets {
    public class QuakeWindow : Widgets.ConfigWindow {
        public Gdk.RGBA active_tab_color;
        
        public int active_tab_underline_x;
		public int active_tab_underline_width;
        
        public int window_save_height;
        
        public int window_frame_margin_bottom = 60;
        
        public QuakeWindow() {
            active_tab_color = Gdk.RGBA();
            active_tab_color.parse("#2CA7F8");
            
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());

            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            set_decorated(false);
            set_keep_above(true);
            set_size_request(rect.width, rect.height / 3);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_type_hint(Gdk.WindowTypeHint.DIALOG);  // DIALOG hint will give right window effect
            move(rect.x, 0);
            
            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_frame_box.margin_bottom = window_frame_margin_bottom;
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

                    window_save_height = height - window_frame_margin_bottom;
                    
                    Cairo.RectangleInt input_shape_rect;
                    get_window().get_frame_extents(out input_shape_rect);
                    
                    input_shape_rect.x = 0;
                    input_shape_rect.y = 0;
                    input_shape_rect.width = width;
                    input_shape_rect.height = height - window_frame_margin_bottom;
                    
                    var shape = new Cairo.Region.rectangle(input_shape_rect);
                    get_window().input_shape_combine_region(shape, 0, 0);
                    
                    queue_draw();
                    
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
        
        public void toggle_quake_window() {
            Gdk.Screen screen = Gdk.Screen.get_default();
            int active_monitor = screen.get_monitor_at_window(screen.get_active_window());
            int window_monitor = screen.get_monitor_at_window(get_window());
            
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(active_monitor, out rect);
                
            if (active_monitor == window_monitor) {
                var window_state = get_window().get_state();
                if ((window_state & Gdk.WindowState.WITHDRAWN) == Gdk.WindowState.WITHDRAWN) {
                    move(rect.x, 0);
                    show_all();
                    present();
                } else {
                    // Because some desktop environment, such as DDE will grab keyboard focus when press keystroke. :(
                    // So i add 200ms timeout to wait desktop environment release keyboard focus and then get window active state.
                    // Otherwise, window is always un-active state that quake terminal can't toggle to hide.
                    GLib.Timeout.add(200, () => {
                            if (is_active) {
                                hide();
                            } else {
                                present();
                            }
                        
                        return false;
                        });
                }
            } else {
                move(rect.x, 0);
                show_all();
                present();
            }
        }
        
        public void add_widget(Gtk.Widget widget) {
            window_widget_box.pack_start(widget, true, true, 0);
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
        }
        
        public void draw_window_frame(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;
            Gdk.RGBA frame_color = Gdk.RGBA();
            
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
        
        public void draw_window_below(Cairo.Context cr) {
        }
        
        public void draw_window_above(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;
            Gdk.RGBA frame_color = Gdk.RGBA();
            try {
                frame_color.parse(config.config_file.get_string("theme", "color1"));
            } catch (GLib.KeyFileError e) {
                print(e.message);
            }

            // Draw line below at titlebar.
            cr.save();
            cr.set_source_rgba(0, 0, 0, 0.3);
            // cr.set_source_rgba(1, 0, 0, 1);
            Draw.draw_rectangle(cr, x + 1, y + height - 41, width - 2, 1);
            cr.restore();
						
            // Draw active tab underline *above* titlebar underline.
            cr.save();
            Utils.set_context_color(cr, active_tab_color);
            Draw.draw_rectangle(cr, x + active_tab_underline_x, y + height - 41, active_tab_underline_width, 2);
            cr.restore();
        }
    }
}