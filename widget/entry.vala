using Gtk;
using Utils;

namespace Widgets {
    public class Entry : Gtk.Entry {
        public Widgets.EntryMenu menu;
        
        public Entry() {
            button_press_event.connect((w, e) => {
                    if (Utils.is_right_button(e)) {
                        menu = new Widgets.EntryMenu();
                        menu.create_entry_menu(this, (int) e.x_root, (int) e.y_root);
                        
                        return true;
                    }
                    
                    return false;
                });
        }
    }
}