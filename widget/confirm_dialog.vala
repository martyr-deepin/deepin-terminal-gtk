using Gtk;
using Widgets;

namespace Widgets {
    public class ConfirmDialog : Gtk.Window {
        private int window_width = 400;
        private int window_height = 200;
        
        public signal void confirm();
        
        public ConfirmDialog(string confirm_message, Gtk.Window window) {
            modal = true;
            set_transient_for(window);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_size_request(window_width, window_height);
            set_resizable(false);
            
            Titlebar titlebar = new Titlebar();
            titlebar.close_button.button_press_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            set_titlebar(titlebar);
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_width) / 2,
                 y + (window_alloc.height - window_height) / 2);
            
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            Label label = new Label("Terminal still has running programs. Are you sure you want to quit?");
            
            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            TextButton cancel_button = new TextButton("Cancel");
            TextButton confirm_button = new TextButton("OK");
            cancel_button.button_press_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            confirm_button.button_press_event.connect((b) => {
                    confirm();
                    destroy();
                    
                    return false;
                });
            cancel_button.set_size_request(-1, 20);
            confirm_button.set_size_request(-1, 20);
            button_box.pack_start(cancel_button, true, true, 0);
            button_box.pack_start(confirm_button, true, true, 0);
            
            add(box);
            box.pack_start(label, true, true, 0);
            box.pack_start(button_box, false, false, 0);
            
            draw.connect(on_draw);
            
            show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            // HACKINGWAY: we need get shadow property from gtk css file to instead constant way.
            int shadow_left = 23;
            int shadow_right = 23;
            int shadow_up = 18;
            int shadow_down = 18;
            
            cr.set_source_rgba(0, 0, 0, 0.8);
            Draw.draw_rectangle(cr, 
                                alloc.x + shadow_left, 
                                alloc.y + shadow_up, 
                                alloc.width - shadow_left - shadow_right, 
                                alloc.height - shadow_up - shadow_down);

            cr.set_source_rgba(1, 1, 1, 0.8);
            Draw.draw_rectangle(cr, 
                                alloc.x + shadow_left, 
                                alloc.y + shadow_up, 
                                alloc.width - shadow_left - shadow_right, 
                                alloc.height - shadow_up - shadow_down,
                                false
                                );
            
            return false;
        }
    }
}