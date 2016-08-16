using Gtk;
using Widgets;

namespace Widgets {
    public class ConfirmDialog : Widgets.Dialog {
        private int window_init_width = 480;
        private int window_init_height = 230;
        
        private int logo_margin_start = 20;
        private int logo_margin_end = 20;
        private int box_margin_top = 4;
        private int box_margin_bottom = 24;
        private int box_margin_end = 20;
        private int title_margin_top = 12;
        private int content_margin_top = 8;
        
        public signal void confirm();
        
        public ConfirmDialog(Gtk.Window window) {
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
            close_button.margin_top = 3;
            close_button.margin_right = 3;
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
            content_button_box.margin_end = box_margin_end;
            
            Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("dialog_icon.png"));
            logo_image.margin_start = logo_margin_start;
            logo_image.margin_end = logo_margin_end;
            
            var label_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            Label title_label = new Gtk.Label(null);
            title_label.set_halign(Gtk.Align.START);
            title_label.get_style_context().add_class("dialog_title");
            title_label.set_text("Terminal still has running programs");
            title_label.margin_top = title_margin_top;

            Label content_label = new Gtk.Label(null);
            content_label.set_halign(Gtk.Align.START);
            content_label.get_style_context().add_class("dialog_content");
            content_label.set_text("Are you sure you want to quit?");
            content_label.margin_top = content_margin_top;
            
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
            label_box.pack_start(title_label, false, false, 0);
            label_box.pack_start(content_label, false, false, 0);
            content_button_box.pack_start(logo_image, false, false, 0);
            content_button_box.pack_start(label_box, true, true, 0);
            button_box.pack_start(cancel_button, true, true, 0);
            button_box.pack_start(confirm_button, true, true, 0);
            box.pack_start(close_button_box, false, false, 0);
            box.pack_start(content_button_box, true, true, 0);
            box.pack_start(button_box, true, true, 0);
            
            var event_area = new Widgets.WindowEventArea(this);
            event_area.margin_end = 27;
            event_area.margin_bottom = cancel_button.left_normal_surface.get_height();
            
            overlay.add(box);
            overlay.add_overlay(event_area);
            
            add_widget(overlay);
            
            show_all();
        }
        
        public override void draw_window_below(Cairo.Context cr) {
            Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_start, window_frame_margin_top, window_rect.width, window_rect.height, 5);
        }        
    }
}