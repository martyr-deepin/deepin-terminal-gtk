using Gtk;

namespace Widgets {
    public class Window : Gtk.Window {
        public double background_opacity = 0.8;
        private bool is_fullscreen = false;
        
        public Window() {
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());
            
            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            set_default_size(rect.width * 2 / 3, rect.height * 2 / 3);

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
    }
}