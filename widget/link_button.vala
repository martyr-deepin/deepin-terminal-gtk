using Gtk;

namespace Widgets {
    public class LinkButton : Widgets.ClickEventBox {
        public string link_name;
        public string link_uri;
        public string link_css;
        
        public LinkButton(string link_name, string link_uri, string link_css) {
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                                     | Gdk.EventMask.BUTTON_RELEASE_MASK
                                     | Gdk.EventMask.POINTER_MOTION_MASK
                                     | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            visible_window = false;
            
            var link_label = new Gtk.Label(null);
            link_label.set_text(link_name);
            link_label.get_style_context().add_class(link_css);
            add(link_label);
            enter_notify_event.connect((w, e) => {
                    var display = Gdk.Display.get_default();
                    get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND1));
                    
                    return false;
                });
            leave_notify_event.connect((w, e) => {
                    get_window().set_cursor(null);
                    
                    return false;
                });
            clicked.connect((w, e) => {
                    Gdk.Screen screen = Gdk.Screen.get_default();
                    try {
                        Gtk.show_uri(screen, link_uri, e.time);
                    } catch (GLib.Error e) {
                        print("LinkButton: %s\n", e.message);
                    }
                });            
        }
    }
}