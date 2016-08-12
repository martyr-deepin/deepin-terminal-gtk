using Gtk;
using Widgets;

namespace Widgets {
    public class ConfirmDialog : Widgets.BaseWindow {
        private int window_init_width = 480;
        private int window_init_height = 230;
        
        private int logo_margin_left = 20;
        private int text_margin_left = 104;
        private int box_margin_right = 20;
        private int box_margin_top = 14;
        private int text_size = 12;
        
        private Cairo.ImageSurface icon_surface;
        
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
            
            icon_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("dialog_icon.png"));
            Box box = new Box(Gtk.Orientation.VERTICAL, 0);
            
            Box content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            content_box.set_size_request(-1, 92);
            
            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            Temp_TextButton cancel_button = new Temp_TextButton("Cancel");
            Temp_TextButton confirm_button = new Temp_TextButton("Quit");
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
            
            box.pack_start(titlebar, false, false, 0);
            box.pack_start(content_box, true, true, 0);
            box.pack_start(button_box, false, false, 0);
            add_widget(box);
            
            show_all();
        }
        
        public override void draw_window_below(Cairo.Context cr) {
            Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_left, window_frame_margin_top, window_rect.width, window_rect.height, 5);
            
            // Draw icon.
            Draw.draw_surface(cr, icon_surface,
                              window_frame_margin_left + logo_margin_left,
                              window_frame_margin_top + box_margin_top);

            // Draw content.
            cr.set_source_rgba(0, 0, 0, 1);
            Draw.draw_text(this, cr, "Terminal still has running programs. \nAre you sure you want to quit?",
                           window_frame_margin_left + text_margin_left,
                           window_frame_margin_top + box_margin_top,
                           window_rect.width - text_margin_left - box_margin_right,
                           text_size);
            
        }
   }
}