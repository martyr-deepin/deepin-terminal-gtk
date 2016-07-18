using Gtk;
using Widgets;

namespace Widgets {
    public class AboutDialog : Gtk.Window {
        public int window_width = 400;
        public int window_height = 360;

        public Gtk.Widget focus_widget;
        
        public AboutDialog(Gtk.Window window, Gtk.Widget widget) {
            focus_widget = widget;
            
            set_transient_for(window);
            set_default_geometry(window_width, window_height);
            set_resizable(false);
            set_modal(true);
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_width) / 2,
                 y + (window_alloc.height - window_height) / 3);
            
            var titlebar = new Titlebar();
            set_titlebar(titlebar);
            
            titlebar.close_button.button_press_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.add(box);
            
            var about_widget = new AboutWidget();
            box.pack_start(about_widget, true, true, 0);
            
            show_all();
        }
    }
}