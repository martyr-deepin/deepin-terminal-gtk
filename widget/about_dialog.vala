using Gtk;
using Widgets;

namespace Widgets {
    public class AboutDialog : Widgets.BaseWindow {
        public int window_init_width = 500;
        public int window_init_height = 470;

        public Gtk.Widget focus_widget;
        
        public AboutDialog(Gtk.Window window, Gtk.Widget widget) {
            focus_widget = widget;
            
            set_transient_for(window);
            set_default_geometry(window_init_width, window_init_height);
            set_resizable(false);
            set_modal(true);
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_init_width) / 2,
                 y + (window_alloc.height - window_init_height) / 3);
            
            var titlebar = new Titlebar();
            
            titlebar.close_button.button_release_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(titlebar, false, false, 0);
            
            var about_widget = new AboutWidget();
            box.pack_start(about_widget, true, true, 0);
            
            add_widget(box);
            show_all();
        }
        
        public override void draw_window_below(Cairo.Context cr) {
            Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_left, window_frame_margin_top, window_rect.width, window_rect.height, 5);
        }
    }
}