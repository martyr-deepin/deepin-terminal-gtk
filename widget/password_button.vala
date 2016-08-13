using Gtk;
using Widgets;

namespace Widgets {
    public class PasswordButton : Gtk.EventBox {
        public Gtk.Box box;
        public Gtk.Entry entry;
        public Gtk.Box button_box;
        
        public ImageButton show_password_button;
        public ImageButton hide_password_button;
        
        public int height = 26;
        
        public PasswordButton() {
            visible_window = false;
            
            set_size_request(-1, height);
            
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            
            entry = new Gtk.Entry();
            entry.margin_top = 1;
            entry.margin_bottom = 1;
            entry.set_invisible_char('•');
            entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
            
            show_password_button = new ImageButton("password_show");
            hide_password_button = new ImageButton("password_hide");
            
            button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            box.pack_start(entry, true, true, 0);
            box.pack_start(button_box, false, false, 0);
            
            hide_password();
            
            show_password_button.button_release_event.connect((w, e) => {
                    show_password();
                    
                    return false;
                });

            hide_password_button.button_release_event.connect((w, e) => {
                    hide_password();
                    
                    return false;
                });
            
            add(box);
        }
        
        public void show_password() {
            Utils.remove_all_children(button_box);
            
            entry.get_style_context().remove_class("password_invisible_entry");
            entry.get_style_context().add_class("password_visible_entry");
            entry.set_visibility(true);
            button_box.pack_start(hide_password_button, false, false, 0);
            
            show_all();
        }
        
        public void hide_password() {
            Utils.remove_all_children(button_box);
            
            entry.get_style_context().remove_class("password_visible_entry");
            entry.get_style_context().add_class("password_invisible_entry");
            entry.set_visibility(false);
            button_box.pack_start(show_password_button, false, false, 0);
            
            show_all();
        }
    }
}