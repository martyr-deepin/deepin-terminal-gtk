using Gtk;
using Widgets;

namespace Widgets {
    public class ConfirmDialog : Widgets.BaseWindow {
        private int window_init_width = 500;
        private int window_init_height = 310;
        
        public signal void confirm();
        
        public ConfirmDialog(string confirm_message, Gtk.Window window) {
            modal = true;
            set_transient_for(window);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_size_request(window_init_width, window_init_height);
            set_resizable(false);
            
            Titlebar titlebar = new Titlebar();
            titlebar.close_button.button_release_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_init_width) / 2,
                 y + (window_alloc.height - window_init_height) / 2);
            
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            Label label = new Label("Terminal still has running programs. Are you sure you want to quit?");
            
            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            TextButton cancel_button = new TextButton("Cancel");
            TextButton confirm_button = new TextButton("OK");
            cancel_button.button_release_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            confirm_button.button_release_event.connect((b) => {
                    confirm();
                    destroy();
                    
                    return false;
                });
            cancel_button.set_size_request(-1, 20);
            confirm_button.set_size_request(-1, 20);
            button_box.pack_start(cancel_button, true, true, 0);
            button_box.pack_start(confirm_button, true, true, 0);
            
            add_widget(box);
            box.pack_start(titlebar, false, false, 0);
            box.pack_start(label, true, true, 0);
            box.pack_start(button_box, false, false, 0);
            
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