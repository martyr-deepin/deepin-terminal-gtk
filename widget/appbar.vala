using Gtk;
using Widgets;

namespace Widgets {
    public class Appbar : Gtk.Overlay {
        public Tabbar tabbar;
        public Box max_toggle_box;
        
        public ImageButton menu_button;
        public ImageButton min_button;
        public ImageButton max_button;
        public ImageButton unmax_button;
        public ImageButton close_button;
        public Application application;
		
		public int height = Constant.TITLEBAR_HEIGHT;
        
        public Gtk.Widget focus_widget;
        
		public Menu.Menu menu;
		
		public Gdk.RGBA background_color;
		
		public bool quake_mode = false;
        
        public Widgets.WindowEventArea event_area;
        
        public WorkspaceManager workspace_manager;
        
        public Appbar(Tabbar tab_bar, bool mode, Application app, WorkspaceManager manager) {
			quake_mode = mode;
            workspace_manager = manager;
			
			set_size_request(-1, height);
			
            tabbar = tab_bar;
            application = app;
            
            
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
                    menu_content.append(new Menu.MenuItem("remote_manage", "Connect remote"));
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
			logo_box.set_size_request(48, Constant.TITLEBAR_HEIGHT);
			Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("title_icon.png"));
			logo_box.pack_start(logo_image, true, true, 0);
			box.pack_start(logo_box, false, false, 0);
			
            max_toggle_box.add(max_button);
            if (!quake_mode) {
                box.pack_start(tabbar, true, true, 0);
				var space_box = new Gtk.EventBox();
				space_box.set_size_request(30, -1);
				box.pack_start(space_box, false, false, 0);
            }
            box.pack_start(menu_button, false, false, 0);
            box.pack_start(min_button, false, false, 0);
            box.pack_start(max_toggle_box, false, false, 0);
            box.pack_start(close_button, false, false, 0);
			close_button.margin_end = 5;
            
            event_area = new Widgets.WindowEventArea(this);
            // Don't override window button area.
            event_area.margin_end = 27 * 4;
            draw.connect(on_draw);
            
            add(box);
            add_overlay(event_area);
        }
        
        public void handle_menu_item_click(string item_id) {
            switch(item_id) {
                case "new_window":
                    try {
                        GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline(application.start_path, null, GLib.AppInfoCreateFlags.NONE);
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print(e.message);
                    }
			    	break;
                case "remote_manage":
                    workspace_manager.focus_workspace.show_remote_panel(workspace_manager.focus_workspace);
                    break;
				case "help":
                    try {
                        GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("dman deepin-terminal", null, GLib.AppInfoCreateFlags.NONE);
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print(e.message);
                    }
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
            
            if (((Widgets.BaseWindow) get_toplevel()).window_is_max()) {
                max_toggle_box.add(unmax_button);
            } else {
                max_toggle_box.add(max_button);
            }
            
            max_toggle_box.show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            

			cr.save();
			try {
                if (quake_mode) {
                    Widgets.QuakeWindow window = (Widgets.QuakeWindow) this.get_toplevel();
                    
                    background_color.parse(window.config.config_file.get_string("theme", "color1"));
                    cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
                    // cr.set_source_rgba(1, 0, 0, 1);				
                    Draw.draw_rectangle(cr, 0, 0, rect.width, height);
                    
                    cr.set_source_rgba(0, 0, 0, 0.2);				
                    // cr.set_source_rgba(1, 0, 0, 1);				
                    Draw.draw_rectangle(cr, 0, 0, rect.width, height);
                } else {
                    Widgets.Window window = (Widgets.Window) this.get_toplevel();
                    if (window.window_is_normal) {
                        background_color.parse(window.config.config_file.get_string("theme", "color1"));
                        cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
                        Draw.draw_rectangle(cr, 1, 0, rect.width - 2, 1);
                        Draw.draw_rectangle(cr, 0, 1, rect.width, height - 1);
                    } else {
                        background_color.parse(window.config.config_file.get_string("theme", "color1"));
                        cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
                        // cr.set_source_rgba(1, 0, 0, 1);				
                        Draw.draw_rectangle(cr, 0, 0, rect.width, height);
                    
                        cr.set_source_rgba(0, 0, 0, 0.2);				
                        // cr.set_source_rgba(1, 0, 0, 1);				
                        Draw.draw_rectangle(cr, 0, 0, rect.width, height);
                    }
                }
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
			cr.restore();
			
			foreach(Gtk.Widget w in this.get_children()) {
                w.draw(cr);
            };

            return true;
        }        
    }
}