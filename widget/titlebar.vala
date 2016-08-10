using Gtk;
using Widgets;

namespace Widgets {
    public class Titlebar : Gtk.Overlay {
        public Box max_toggle_box;
        
        public ImageButton close_button;
        
        public Widgets.WindowEventArea event_area;
        
        public Titlebar() {
            close_button = new ImageButton("titlebar_close");
            close_button.set_halign(Gtk.Align.END);
            
            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start(close_button, true, true, 0);
            
            event_area = new Widgets.WindowEventArea(this);
            event_area.margin_right = 27;

            add(box);
            add_overlay(event_area);
            
            set_size_request(-1, 40);
        }
    }
}