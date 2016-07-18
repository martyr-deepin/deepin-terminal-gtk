using Gtk;
using Widgets;

namespace Widgets {
    public Gtk.Widget focus_widget;
    public int window_width = 300;
    public int window_height = 200;

    public class Preference : Gtk.Window {
        
        
        public Preference(Gtk.Window window, Gtk.Widget widget) {
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
            
            draw.connect(on_draw);
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            show_all();
        }
        
    private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);
            
            return true;
        }        
    }
}