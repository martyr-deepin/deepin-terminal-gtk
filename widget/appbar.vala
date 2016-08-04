using Gtk;
using Widgets;

namespace Widgets {
    public class Appbar : Gtk.EventBox {
        public Tabbar tabbar;
        public Box max_toggle_box;
        
        public ImageButton menu_button;
        public ImageButton min_button;
        public ImageButton max_button;
        public ImageButton unmax_button;
        public ImageButton close_button;
        public Application application;
		
		public int height = 40;
        
        public Gtk.Widget focus_widget;
        
		public Menu.Menu menu;
		
		public Gdk.RGBA background_color;
		
		public bool quake_mode = false;
        
        public Appbar(Tabbar tab_bar, bool mode, Application app) {
			quake_mode = mode;
			
			set_size_request(-1, height);
			
            tabbar = tab_bar;
            visible_window = false;
            application = app;
            
            draw.connect(on_draw);
            
            menu_button = new ImageButton("window_menu");
            min_button = new ImageButton("window_min");
            max_button = new ImageButton("window_max");
            unmax_button = new ImageButton("window_unmax");
            close_button = new ImageButton("window_close");
			
			int margin_top = (int) (height - menu_button.normal_surface.get_height()) / 2;
			menu_button.margin_top = margin_top;
			min_button.margin_top = margin_top;
			max_button.margin_top = margin_top;
			unmax_button.margin_top = margin_top;
			close_button.margin_top = margin_top;
            
            menu_button.button_release_event.connect((b) => {
                    focus_widget = ((Gtk.Window) menu_button.get_toplevel()).get_focus();
                    
                    var menu_content = new List<Menu.MenuItem>();
                    menu_content.append(new Menu.MenuItem("new_window", "New window"));
                    menu_content.append(new Menu.MenuItem("", ""));
                    menu_content.append(new Menu.MenuItem("preference", "Preference"));
                    menu_content.append(new Menu.MenuItem("help", "Help"));
                    menu_content.append(new Menu.MenuItem("about", "About"));
                    menu_content.append(new Menu.MenuItem("exit", "Exit"));
                    
                    int menu_x, menu_y;
                    menu_button.translate_coordinates(menu_button.get_toplevel(), 0, 0, out menu_x, out menu_y);
                    Gtk.Allocation menu_rect;
                    menu_button.get_allocation(out menu_rect);
                    int window_x, window_y;
                    menu_button.get_toplevel().get_window().get_origin(out window_x, out window_y);
                    
                    menu = new Menu.Menu(window_x + menu_x, window_y + menu_y + menu_rect.height, menu_content);
                    menu.click_item.connect(handle_menu_item_click);
                    menu.destroy.connect(handle_menu_destroy);
                    
                    return false;
                });
            
            max_toggle_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            
            min_button.button_release_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).iconify();
                    
                    return false;
                });
            max_button.button_release_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).maximize();

                    return false;
                });
            unmax_button.button_release_event.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).unmaximize();

                    return false;
                });
            
            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0);
			
			var logo_box = new Box(Gtk.Orientation.VERTICAL, 0);
			logo_box.set_size_request(48, 40);
			Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("title_icon.png"));
			logo_box.pack_start(logo_image, true, true, 0);
			box.pack_start(logo_box, false, false, 0);
			
            max_toggle_box.add(max_button);
            if (!quake_mode) {
                box.pack_start(tabbar, true, true, 0);
				var space_box = new Gtk.EventBox();
				space_box.set_size_request(150, -1);
				box.pack_start(space_box, false, false, 0);
            }
            box.pack_start(menu_button, false, false, 0);
            box.pack_start(min_button, false, false, 0);
            box.pack_start(max_toggle_box, false, false, 0);
            box.pack_start(close_button, false, false, 0);
			close_button.margin_right = 5;
            
            add(box);
        }
        
        public void handle_menu_item_click(string item_id) {
            switch(item_id) {
                case "new_window":
			    	break;
				case "help":
					break;
			    case "about":
                    new AboutDialog((Gtk.Window) this.get_toplevel(), focus_widget);
			    	break;
				case "exit":
                    application.quit();
					break;
                case "preference":
                    new Widgets.Preference((Gtk.Window) this.get_toplevel(), ((Gtk.Window) this.get_toplevel()).get_focus());
                    break;
            }
		}        
        
		public void handle_menu_destroy() {
			menu = null;
            
            if (focus_widget != null) {
                focus_widget.grab_focus();
            }
        }
        
        public void update_max_button() {
            Utils.remove_all_children(max_toggle_box);
            
            if ((((Gtk.Window) get_toplevel()).get_window().get_state() & Gdk.WindowState.MAXIMIZED) == Gdk.WindowState.MAXIMIZED) {
                max_toggle_box.add(unmax_button);
            } else {
                max_toggle_box.add(max_button);
            }
            
            max_toggle_box.show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            Widgets.Window window = (Widgets.Window) this.get_toplevel();

			try {
				background_color.parse(window.config.config_file.get_string("theme", "color1"));
				cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
            cr.set_operator (Cairo.Operator.SOURCE);
            cr.paint();
			
			// Draw background under titlebar.
            cr.set_operator(Cairo.Operator.OVER);
			cr.set_source_rgba(0, 0, 0, 0.2);
			Draw.draw_rectangle(cr, 0, 0, rect.width, height);
			
			cr.set_operator (Cairo.Operator.OVER);
            
			foreach(Gtk.Widget w in this.get_children()) {
                w.draw(cr);
            };

            return true;
        }        
    }
}