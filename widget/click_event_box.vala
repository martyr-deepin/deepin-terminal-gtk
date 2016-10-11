using Gtk;
using Utils;

namespace Widgets {
    public class ClickEventBox : Gtk.EventBox {
		public bool is_press = false;
        
		public signal void click(Gdk.EventButton event);

        public ClickEventBox() {
			button_press_event.connect((w, e) => {
					is_press = true;
					
					return false;
				});
            
			button_release_event.connect((w, e) => {
                    if (is_press && Utils.pointer_in_widget_area(this)) {
                        click(e);
                    }
                    
					is_press = false;
                    
					return false;
				});
        }
    }
}