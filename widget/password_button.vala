using Gtk;
using Widgets;

namespace Widgets {
    public class PasswordButton : Gtk.EventBox {
        public Gtk.Box box;
        public Gtk.Entry entry;
        
        public ImageButton show_password_button;
        public ImageButton hide_password_button;
        
        public int height = 26;
        
        public PasswordButton() {
            visible_window = false;
            
            set_size_request(-1, height);
            
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            
            entry = new Gtk.Entry();
            entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
            entry.set_visibility(false);
            entry.get_style_context().add_class("password-entry");

            show_password_button = new ImageButton("password_show");
            hide_password_button = new ImageButton("password_hide");

            box.pack_start(entry, true, true, 0);
            box.pack_start(show_password_button, false, false, 0);
            
            add(box);
        }
    }
}