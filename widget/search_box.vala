using Gtk;
using Widgets;

namespace Widgets {
    public class SearchBox : Gtk.Box {
        public Entry entry;
        public ImageButton close_button;
        
        public SearchBox() {
            entry = new Entry();
            close_button = new ImageButton("window_close");
            
            pack_start(entry, true, true, 0);
            pack_start(close_button, false, false, 0);
        }
    }
}