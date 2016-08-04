using Gtk;
using Config;
using Cairo;

namespace Widgets {
    public class Window : Gtk.Window {
        public Config.Config config;
        
		private bool is_fullscreen = false;
        private int window_width;
        private int window_height;
		
		private bool is_radius = false;
		
		public bool quake_mode = false;
		
		public Widgets.WindowShadow window_shadow;
		
		public int active_tab_underline_x;
		public int active_tab_underline_width;
		
		public Gdk.RGBA active_tab_color;

        public Window(bool mode) {
			quake_mode = mode;
			
            active_tab_color = Gdk.RGBA();
            active_tab_color.parse("#2CA7F8");
			
            config = new Config.Config();
			
            config.update.connect((w) => {
                    update_terminal(this);
					
					queue_draw();
                });

            // Make window transparent.
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());

			int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
			set_decorated(false);
			
			if (quake_mode) {
                set_keep_above(true);
                set_size_request(rect.width, rect.height / 3);
                set_skip_taskbar_hint(true);
                set_skip_pager_hint(true);
                set_type_hint(Gdk.WindowTypeHint.DIALOG);  // DIALOG hint will give right window effect
                move(rect.x, 0);
            } else {
                try {
                    var window_state = config.config_file.get_value("advanced", "window_state");
                    var width = config.config_file.get_integer("advanced", "window_width");
                    var height = config.config_file.get_integer("advanced", "window_height");
                    if (width == 0 || height == 0) {
                        set_default_size(rect.width * 2 / 3, rect.height * 2 / 3);
					} else {
                        set_default_size(width, height);
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
            
			window_state_event.connect((w, e) => {
					var state = e.new_window_state;
					if (Gdk.WindowState.MAXIMIZED in state || Gdk.WindowState.FULLSCREEN in state || Gdk.WindowState.TILED in state) {
						is_radius = false;
						
						print("* no radius state\n");
					} else {
						is_radius = true;
						
						print("* radius state\n");
					}
					
					return false;
				});
			
			// event.connect((w, e) => {
			// 		print("%s\n", e.type.to_string());
					
			// 		return false;
			// 	});
			
			draw.connect((w, cr) => {
					try {
						Utils.propagate_draw(this, cr);
					
						if (!quake_mode) {
							// Draw line *under* of window frame.
							cr.save();
							Gdk.RGBA under_frame_color = Gdk.RGBA();
							under_frame_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(under_frame_color.red, under_frame_color.green, under_frame_color.blue, config.config_file.get_double("general", "opacity"));
							// Top.
							Draw.draw_rectangle(cr, 5, 0, window_width - 10, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 5, window_height - 1, window_width - 10, 1);
							// Left.
							Draw.draw_rectangle(cr, 0, 5, 1, window_height - 10);
							// Rigt..
							Draw.draw_rectangle(cr, window_width - 1, 5, 1, window_height - 10);
							cr.restore();
					
							// Draw inner dot *under* window　frame.
							cr.save();
							Gdk.RGBA inner_dot_color = Gdk.RGBA();
							inner_dot_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(inner_dot_color.red, inner_dot_color.green, inner_dot_color.blue, config.config_file.get_double("general", "opacity") * 0.6);
							// Top.
							Draw.draw_rectangle(cr, 4, 0, 1, 1);
							Draw.draw_rectangle(cr, window_width - 5, 0, 1, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 4, window_height - 1, 1, 1);
							Draw.draw_rectangle(cr, window_width - 5, window_height - 1, 1, 1);
							// Left.
							Draw.draw_rectangle(cr, 0, 4, 1, 1);
							Draw.draw_rectangle(cr, 0, window_height - 5, 1, 1);
							// Rigt.
							Draw.draw_rectangle(cr, window_width - 1, 4, 1, 1);
							Draw.draw_rectangle(cr, window_width - 1, window_height - 5, 1, 1);
							cr.restore();
					
							// Draw middle dot *under* window　frame.
							cr.save();
							Gdk.RGBA middle_dot_color = Gdk.RGBA();
							middle_dot_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(middle_dot_color.red, middle_dot_color.green, middle_dot_color.blue, config.config_file.get_double("general", "opacity") * 0.4);
							// Top.
							Draw.draw_rectangle(cr, 3, 0, 1, 1);
							Draw.draw_rectangle(cr, window_width - 4, 0, 1, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 3, window_height - 1, 1, 1);
							Draw.draw_rectangle(cr, window_width - 4, window_height - 1, 1, 1);
							// Left.
							Draw.draw_rectangle(cr, 0, 3, 1, 1);
							Draw.draw_rectangle(cr, 0, window_height - 4, 1, 1);
							// Rigt.
							Draw.draw_rectangle(cr, window_width - 1, 3, 1, 1);
							Draw.draw_rectangle(cr, window_width - 1, window_height - 4, 1, 1);
							cr.restore();

							// Draw out dot *under* window　frame.
							cr.save();
							Gdk.RGBA out_dot_color = Gdk.RGBA();
							out_dot_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(out_dot_color.red, out_dot_color.green, out_dot_color.blue, config.config_file.get_double("general", "opacity") * 0.2);
							// Top.
							Draw.draw_rectangle(cr, 2, 0, 1, 1);
							Draw.draw_rectangle(cr, window_width - 3, 0, 1, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 2, window_height - 1, 1, 1);
							Draw.draw_rectangle(cr, window_width - 3, window_height - 1, 1, 1);
							// Left.
							Draw.draw_rectangle(cr, 0, 2, 1, 1);
							Draw.draw_rectangle(cr, 0, window_height - 3, 1, 1);
							// Rigt.
							Draw.draw_rectangle(cr, window_width - 1, 2, 1, 1);
							Draw.draw_rectangle(cr, window_width - 1, window_height - 3, 1, 1);
							cr.restore();

							// Draw out_corner dot *under* window　frame.
							cr.save();
							Gdk.RGBA out_corner_dot_color = Gdk.RGBA();
							out_corner_dot_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(out_corner_dot_color.red, out_corner_dot_color.green, out_corner_dot_color.blue, config.config_file.get_double("general", "opacity") * 0.25);
							// Top left.
							Draw.draw_rectangle(cr, 1, 1, 1, 1);
							// Top right.
							Draw.draw_rectangle(cr, window_width - 2, 1, 1, 1);
							// Bottm left.
							Draw.draw_rectangle(cr, 1, window_height - 2, 1, 1);
							// Bottom right.
							Draw.draw_rectangle(cr, window_width - 2, window_height - 2, 1, 1);
							cr.restore();
					
							// Draw out dot *under* window　frame.
							cr.save();
							Gdk.RGBA inner_corner_color = Gdk.RGBA();
							inner_corner_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(inner_corner_color.red, inner_corner_color.green, inner_corner_color.blue, config.config_file.get_double("general", "opacity") * 0.5);
							// Top.
							Draw.draw_rectangle(cr, 2, 1, 1, 1);
							Draw.draw_rectangle(cr, window_width - 3, 1, 1, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 2, window_height - 2, 1, 1);
							Draw.draw_rectangle(cr, window_width - 3, window_height - 2, 1, 1);
							// Left.
							Draw.draw_rectangle(cr, 1, 2, 1, 1);
							Draw.draw_rectangle(cr, 1, window_height - 3, 1, 1);
							// Rigt.
							Draw.draw_rectangle(cr, window_width - 2, 2, 1, 1);
							Draw.draw_rectangle(cr, window_width - 2, window_height - 3, 1, 1);
							cr.restore();
					
							// Draw window frame.
							cr.save();
							Gdk.RGBA frame_color = Gdk.RGBA();
							frame_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(0, 0, 0, config.config_file.get_double("general", "opacity"));
							// Top.
							Draw.draw_rectangle(cr, 5, 0, window_width - 10, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 5, window_height - 1, window_width - 10, 1);
							// Left.
							Draw.draw_rectangle(cr, 0, 5, 1, window_height - 10);
							// Rigt..
							Draw.draw_rectangle(cr, window_width - 1, 5, 1, window_height - 10);
							cr.restore();

							// Draw line *innner* of window frame.
							cr.save();
							Gdk.RGBA inner_frame_color = Gdk.RGBA();
							inner_frame_color.parse(config.config_file.get_string("theme", "color1"));
							cr.set_source_rgba(inner_frame_color.red, inner_frame_color.green, inner_frame_color.blue, config.config_file.get_double("general", "opacity"));
							// cr.set_source_rgba(1, 0, 0, 1);
							// Top.
							Draw.draw_rectangle(cr, 3, 1, window_width - 6, 1);
							// Bottom.
							Draw.draw_rectangle(cr, 3, window_height - 2, window_width - 6, 1);
							// Left.
							Draw.draw_rectangle(cr, 1, 3, 1, window_height - 6);
							// Rigt..
							Draw.draw_rectangle(cr, window_width - 2, 3, 1, window_height - 6);
							cr.restore();

							// Draw line below of window frame.
							cr.set_operator(Cairo.Operator.OVER);
							cr.set_source_rgba(1, 1, 1, 0.0625 * config.config_file.get_double("general", "opacity"));
							// cr.set_source_rgba(1, 0, 0, 1);
							Draw.draw_rectangle(cr, 3, 1, window_width - 6, 1);
					
							// Draw line around titlebar side.
							cr.set_operator(Cairo.Operator.OVER);
							cr.set_source_rgba(0, 0, 0, 0.2);
							// Left.
							Draw.draw_rectangle(cr, 1, 3, 1, 38);
							// Right.
							Draw.draw_rectangle(cr, window_width - 2, 3, 1, 38);
						}
						
						// Draw line below at titlebar.
						cr.save();
						if (quake_mode) {
							cr.set_source_rgba(0, 0, 0, 0.3);
							Draw.draw_rectangle(cr, 1, window_height - 42, window_width - 2, 1);
						} else {
							cr.set_source_rgba(0, 0, 0, 0.3);
							Draw.draw_rectangle(cr, 1, 41, window_width - 2, 1);
						}
						cr.restore();
						
						// Draw active tab underline *above* titlebar underline.
						cr.save();
						if (quake_mode) {
							Utils.set_context_color(cr, active_tab_color);
							Draw.draw_rectangle(cr, active_tab_underline_x, window_height - 42, active_tab_underline_width, 2);
						} else {
							Utils.set_context_color(cr, active_tab_color);
							Draw.draw_rectangle(cr, active_tab_underline_x, 40, active_tab_underline_width, 2);
						}
						cr.restore();
					} catch (GLib.KeyFileError e) {
						print(e.message);
					}
					
					return true;
				});
			
			configure_event.connect((w) => {
                    get_size(out window_width, out window_height);
					
					int x, y;
					get_window().get_origin(out x, out y);
					
					print("%i %i %i %i\n", x, y, window_width, window_height);
					
					adjust_shape();
					queue_draw();
					
					return false;
                });
			
			destroy.connect((w) => {
                    if (!quake_mode && !is_fullscreen && !is_maximized) {
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
		
		public void adjust_shape() {
			if (!quake_mode) {
				Surface surface = new ImageSurface(Format.ARGB32, window_width, window_height);
				Context cr = new Context (surface);
				
				cr.set_source_rgb(0, 0, 0);
				cr.set_operator(Cairo.Operator.CLEAR);
				cr.paint();
				
				cr.set_operator(Cairo.Operator.OVER);
				cr.set_source_rgb(1, 1, 1);
					
				print(is_radius.to_string() + "\n");
				if (is_radius) {
					Draw.draw_rectangle(cr, 2, 0, window_width - 4, window_height);
					Draw.draw_rectangle(cr, 0, 2, window_width, window_height - 4);
					
					Draw.draw_rectangle(cr, 1, 1, 1, 1);
					Draw.draw_rectangle(cr, window_width - 2, 1, 1, 1);
					Draw.draw_rectangle(cr, window_width - 2, window_height - 2, 1, 1);
					Draw.draw_rectangle(cr, 1, window_height - 2, 1, 1);
					// Draw.draw_rounded_rectangle(cr, 0, 0, window_width, window_height, 1);
						
					var region = Gdk.cairo_region_create_from_surface(surface);
					this.get_window().shape_combine_region(region, 0, 0);
					print("!!!!!! \n");
				} else {
					Draw.draw_rectangle(cr, 0, 0, window_width, window_height);
						
					var region = Gdk.cairo_region_create_from_surface(surface);
					this.get_window().shape_combine_region(region, 0, 0);
					print("###### \n");
				}
			}
		}

		public void toggle_fullscreen () {
            if (is_fullscreen) {
                unfullscreen();
                is_fullscreen = false;
            } else {
                fullscreen();
                is_fullscreen = true;
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