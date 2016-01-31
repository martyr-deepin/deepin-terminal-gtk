using Gtk;
using Widgets;

namespace Widgets {
    public class Titlebar : Gtk.EventBox {
        public Tabbar tabbar;
        public Box max_toggle_box;
        
        public ImageButton menu_button;
        public ImageButton min_button;
        public ImageButton max_button;
        public ImageButton unmax_button;
        public ImageButton close_button;
        
        public Titlebar() {
            visible_window = false;
            
            draw.connect(on_draw);
            
            tabbar = new Tabbar();
            tabbar.add_tab("Test new", 0);
            
            menu_button = new ImageButton("window_menu");
            min_button = new ImageButton("window_min");
            max_button = new ImageButton("window_max");
            unmax_button = new ImageButton("window_unmax");
            close_button = new ImageButton("window_close");
            
            max_toggle_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            
            min_button.button_press_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).iconify();
                    
                    return false;
                });
            max_button.button_press_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).maximize();

                    return false;
                });
            unmax_button.button_press_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).unmaximize();

                    return false;
                });
            close_button.button_press_event.connect((w, e) => {
                    Gtk.main_quit();
                    
                    return false;
                });
            
            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            
            max_toggle_box.add(max_button);
            box.pack_start(tabbar, true, true, 0);
            box.pack_start(menu_button, false, false, 0);
            box.pack_start(min_button, false, false, 0);
            box.pack_start(max_toggle_box, false, false, 0);
            box.pack_start(close_button, false, false, 0);
            
            add(box);
        }
        
        public void update_max_button() {
            foreach (Widget w in max_toggle_box.get_children()) {
                max_toggle_box.remove(w);
            }
            
            if ((((Gtk.Window) get_toplevel()).get_window().get_state() & Gdk.WindowState.MAXIMIZED) == Gdk.WindowState.MAXIMIZED) {
                max_toggle_box.add(unmax_button);
            } else {
                max_toggle_box.add(max_button);
            }
            
            max_toggle_box.show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            cr.set_source_rgba(0, 0, 0, 0.8);
            cr.set_operator (Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_operator (Cairo.Operator.OVER);
            
            foreach(Gtk.Widget w in this.get_children()) {
                w.draw(cr);
            };

            return true;
        }        
    }
}