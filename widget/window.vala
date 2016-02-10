using Gtk;

namespace Widgets {
    public class Window : Gtk.Window {
        public double background_opacity = 0.8;
        private bool is_fullscreen = false;
        
        public Window(bool quake_mode) {
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
                move(rect.x, 0);
            } else {
                set_default_size(rect.width * 2 / 3, rect.height * 2 / 3);
            }

            try{
                set_icon_from_file("image/deepin-terminal.svg");
            } catch(Error er) {
                stdout.printf(er.message);
            }
        }

        public void change_opacity(double offset) {
            background_opacity = double.min(double.max(background_opacity + offset, 0.2), 1);
            
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
    }
}