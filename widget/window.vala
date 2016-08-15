using Gtk;
using Config;
using Cairo;

namespace Widgets {
    public class Window : Widgets.BaseWindow {
        public int active_tab_underline_x;
		public int active_tab_underline_width;
		
		public Gdk.RGBA active_tab_color;

        public Window() {
            active_tab_color = Gdk.RGBA();
            active_tab_color.parse("#2CA7F8");
			
            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            Gdk.Geometry geo = Gdk.Geometry();
            geo.min_width = rect.width / 3;
            geo.min_height = rect.height / 3;
            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE);
            
            add_margins();
            try {
                var window_state = config.config_file.get_value("advanced", "window_state");
                var width = config.config_file.get_integer("advanced", "window_width");
                var height = config.config_file.get_integer("advanced", "window_height");
                if (width == 0 || height == 0) {
                    set_window_size(rect.width * 2 / 3, rect.height * 2 / 3);
                } else {
                    set_window_size(width, height);
                }
					
                    
                if (window_state == "maximize") {
                    maximize();
                } else if (window_state == "fullscreen") {
                    toggle_fullscreen();
                }
            } catch (GLib.KeyFileError e) {
                stdout.printf(e.message);
            }
            
            destroy.connect((w) => {
                    config.config_file.set_integer("advanced", "window_width", window_save_width);
                    config.config_file.set_integer("advanced", "window_height", window_save_height);
                    config.save();
                });

            try{
                set_icon_from_file(Utils.get_image_path("deepin-terminal.svg"));
            } catch(Error er) {
                stdout.printf(er.message);
            }
        }
		
        public override void draw_window_above(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            Gdk.RGBA frame_color = Gdk.RGBA();
            try {
                frame_color.parse(config.config_file.get_string("theme", "color1"));
            } catch (GLib.KeyFileError e) {
                print(e.message);
            }
            
            // Draw line around titlebar side.
            Utils.set_context_color(cr, frame_color);
            // cr.set_source_rgba(1, 0, 0, 1);
            if (window_is_normal) {
                // Left.
                Draw.draw_rectangle(cr, x + 1, y + 3, 1, 38);
                // Right.
                Draw.draw_rectangle(cr, x + width - 2, y + 3, 1, 38);
            } else {
                // Left.
                Draw.draw_rectangle(cr, x + 1, y, 1, 41);
                // Right.
                Draw.draw_rectangle(cr, x + width - 2, y, 1, 41);
            }
                            
            // Draw line below at titlebar.
            cr.save();
            cr.set_source_rgba(0, 0, 0, 0.3);
            // cr.set_source_rgba(1, 0, 0, 1);
            Draw.draw_rectangle(cr, x + 1, y + 41, width - 2, 1);
            cr.restore();
						
            // Draw active tab underline *above* titlebar underline.
            cr.save();
            Utils.set_context_color(cr, active_tab_color);
            Draw.draw_rectangle(cr, x + active_tab_underline_x - window_frame_box.margin_start, y + Constant.TITLEBAR_HEIGHT, active_tab_underline_width, 2);
            cr.restore();
        }
    }
}