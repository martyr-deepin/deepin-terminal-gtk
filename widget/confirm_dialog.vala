using Gtk;
using Widgets;

namespace Widgets {
    public class ConfirmDialog : Widgets.BaseWindow {
        private int window_init_width = 480;
        private int window_init_height = 230;
        
        private int logo_margin_left = 20;
        private int logo_margin_right = 20;
        private int text_margin_right = 20;
        private int box_margin_top = 14;
        private int box_margin_bottom = 14;
        
        public signal void confirm();
        
        public ConfirmDialog(string confirm_message, Gtk.Window window) {
            modal = true;
            set_transient_for(window);
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_size_request(window_init_width, window_init_height);
            set_resizable(false);
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_init_width) / 2,
                 y + (window_alloc.height - window_init_height) / 2);
            
            // Add widgets.
            var overlay = new Gtk.Overlay();
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            var close_button = new ImageButton("titlebar_close");
            close_button.set_halign(Gtk.Align.END);
            
            close_button.button_release_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            var close_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            close_button_box.pack_start(close_button, true, true, 0);

            var content_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            content_button_box.margin_top = box_margin_top;
            content_button_box.margin_bottom = box_margin_bottom;
            
            Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("dialog_icon.png"));
            logo_image.margin_left = logo_margin_left;
            logo_image.margin_right = logo_margin_right;
            Label label = new Gtk.Label(null);
            label.get_style_context().add_class("dialog-label");
            label.set_text("Terminal still has running programs. \nAre you sure you want to quit?");
            label.margin_right = text_margin_right;
            
            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            DialogButton cancel_button = new Widgets.DialogButton("Cancel", "left", "text");
            DialogButton confirm_button = new Widgets.DialogButton("Quit", "right", "warning");
            cancel_button.button_release_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            confirm_button.button_release_event.connect((b) => {
                    confirm();
                    destroy();
                    
                    return false;
                });
            
            close_button_box.pack_start(close_button, true, true, 0);
            content_button_box.pack_start(logo_image, false, false, 0);
            content_button_box.pack_start(label, true, true, 0);
            button_box.pack_start(cancel_button, true, true, 0);
            button_box.pack_start(confirm_button, true, true, 0);
            box.pack_start(close_button_box, false, false, 0);
            box.pack_start(content_button_box, true, true, 0);
            box.pack_start(button_box, true, true, 0);
            
            var event_area = new Widgets.WindowEventArea(this);
            event_area = new Widgets.WindowEventArea(this);
            event_area.margin_right = 27;
            event_area.margin_bottom = window_init_height - 40;
            
            overlay.add(box);
            overlay.add_overlay(event_area);
            
            add_widget(overlay);
            
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