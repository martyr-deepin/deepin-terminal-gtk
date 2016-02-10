using Gtk;
using Widgets;

namespace Widgets {
    public class Titlebar : Gtk.EventBox {
        public Box max_toggle_box;
        
        public ImageButton close_button;
        
        public Titlebar() {
            visible_window = false;
            
            close_button = new ImageButton("window_close");
            close_button.set_halign(Gtk.Align.END);
            
            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            
            box.pack_start(close_button, true, true, 0);
            add(box);
        }
    }
}