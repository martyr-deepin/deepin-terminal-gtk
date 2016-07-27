using Gtk;
using Config;

namespace Widgets {
    public class Window : Gtk.Window {
        public Config.Config config;
        
		private bool is_fullscreen = false;
        private int window_width;
        private int window_height;
        
        public Window(bool quake_mode) {
            config = new Config.Config();
			
            config.update.connect((w) => {
                    update_terminal(this);
                });

            // Make window transparent.
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());
            
            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            if (quake_mode) {
                set_decorated(false);
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
            
            configure_event.connect((w) => {
                    get_size(out window_width, out window_height);
                    
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

        public void change_opacity(double offset) {
			try {
				double background_opacity = config.config_file.get_double("general", "opacity");
				config.config_file.set_double("general", "opacity", double.min(double.max(background_opacity + offset, 0.2), 1));
				config.save();
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
            
            queue_draw();
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