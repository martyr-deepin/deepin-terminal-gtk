using Gtk;
using Config;
using Cairo;

namespace Widgets {
    public class Window : Widgets.BaseWindow {
        public int active_tab_underline_x;
		public int active_tab_underline_width;
		
		public Gdk.RGBA active_tab_color;

        public Window(bool frameless) {
			window_frameless = frameless;
			
            active_tab_color = Gdk.RGBA();
            active_tab_color.parse("#2CA7F8");
			
            config.update.connect((w) => {
                    update_terminal(this);
                    
                    queue_draw();
                });

            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            if (window_frameless) {
                remove_margins();
                set_keep_above(true);
                set_window_size(rect.width, rect.height / 3);
                set_skip_taskbar_hint(true);
                set_skip_pager_hint(true);
                set_type_hint(Gdk.WindowTypeHint.DIALOG);  // DIALOG hint will give right window effect
                move(rect.x, 0);
            } else {
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
            }
            
            destroy.connect((w) => {
                    var state = get_window().get_state();
                    if (!window_frameless && !(Gdk.WindowState.FULLSCREEN in state) && !is_maximized) {
                        config.config_file.set_integer("advanced", "window_width", window_width);
                        config.config_file.set_integer("advanced", "window_height", window_height);
                        config.save();
                    }
                });

            try{
                set_icon_from_file(Utils.get_image_path("deepin-terminal.svg"));
            } catch(Error er) {
                stdout.printf(er.message);
            }
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
        
        public override void draw_window_above(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_left;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;
            Gdk.RGBA frame_color = Gdk.RGBA();
            try {
                frame_color.parse(config.config_file.get_string("theme", "color1"));
            } catch (GLib.KeyFileError e) {
                print(e.message);
            }
            
            // Draw line around titlebar side.
            Utils.set_context_color(cr, frame_color);
            // cr.set_source_rgba(1, 0, 0, 1);
            if (!window_frameless && window_is_normal) {
                // Left.
                Draw.draw_rectangle(cr, x + 1, y + 3, 1, 38);
                // Right.
                Draw.draw_rectangle(cr, x + width - 2, y + 3, 1, 38);
            } else if (!window_frameless) {
                // Left.
                Draw.draw_rectangle(cr, x + 1, y, 1, 41);
                // Right.
                Draw.draw_rectangle(cr, x + width - 2, y, 1, 41);
            }
                            
            // Draw line below at titlebar.
            cr.save();
            if (window_frameless) {
                cr.set_source_rgba(0, 0, 0, 0.3);
                // cr.set_source_rgba(1, 0, 0, 1);
                Draw.draw_rectangle(cr, x + 1, y + height - 41, width - 2, 1);
            } else {
                cr.set_source_rgba(0, 0, 0, 0.3);
                // cr.set_source_rgba(1, 0, 0, 1);
                Draw.draw_rectangle(cr, x + 1, y + 41, width - 2, 1);
            }
            cr.restore();
						
            // Draw active tab underline *above* titlebar underline.
            cr.save();
            if (window_frameless) {
                Utils.set_context_color(cr, active_tab_color);
                Draw.draw_rectangle(cr, x + active_tab_underline_x, y + height - 41, active_tab_underline_width, 2);
            } else {
                Utils.set_context_color(cr, active_tab_color);
                Draw.draw_rectangle(cr, x + active_tab_underline_x - window_frame_box.margin_left, y + 40, active_tab_underline_width, 2);
            }
            cr.restore();
        }
        
        public void update_terminal(Gtk.Container container) {
            container.forall((child) => {
                    var child_type = child.get_type();
                    
                    if (child_type.is_a(typeof(Widgets.Term))) {
                        ((Widgets.Term) child).setup_from_config();
                    } else if (child_type.is_a(typeof(Gtk.Container))) {
                        update_terminal((Gtk.Container) child);
                    }
                });
        }
    }
}