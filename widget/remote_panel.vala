using Gtk;
using Widgets;
using Utils;
using Gee;

namespace Widgets {
	public class RemotePanel : Gtk.VBox {
		string config_file_path = Utils.get_config_file_path("server_config.ini");
		
		public RemotePanel() {
			show_homepage();
			
			draw.connect(on_draw);
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            cr.set_source_rgba(0, 0, 0, 0.8);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height);
            
            return false;
        }
		
		public void show_homepage() {
			Utils.destroy_all_children(this);
			
			HashMap<string, int> groups = new HashMap<string, int>();
			ArrayList<ArrayList<string>> ungroups = new ArrayList<ArrayList<string>>();
			        
			KeyFile config_file = new KeyFile();
			try {
				config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
				
			    foreach (unowned string option in config_file.get_groups ()) {
			    	string group_name = config_file.get_value(option, "GroupName");
					
					if (group_name == "") {
						ArrayList<string> ungroup = new ArrayList<string>();
						ungroup.add(config_file.get_value(option, "Name"));
						ungroup.add(option);
			    		ungroups.add(ungroup);
			    	} else {
						if (groups.has_key(group_name)) {
							int group_item_number = groups.get(group_name);
							groups.set(group_name, group_item_number + 1);
						} else {
							groups.set(group_name, 1);
						}
			    	}
			    }
			} catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
					print("show_homepage error: %s\n", e.message);
				}
			}
			
			if (groups.size > 0 || ungroups.size > 1) {
			    Entry search_entry = new Entry();
			    search_entry.set_placeholder_text("Search");
			    pack_start(search_entry, false, false, 0);
			}
			
			TextButton add_server_button = new TextButton("Add server");
			add_server_button.button_press_event.connect((w, e) => {
					show_add_server_page();
					
					return false;
				});
			pack_start(add_server_button, false, false, 0);
			
			if (ungroups.size + groups.size > 0) {
                var view = new TreeView();
                var scrolledwindow = new ScrolledWindow(null, null);
                view.set_headers_visible(false);
                scrolledwindow.add(view);
                pack_start(scrolledwindow, true, true, 0);
                
                var listmodel = new Gtk.ListStore(4, typeof(string), typeof(string), typeof(string), typeof(string));
                view.set_model(listmodel);

                view.insert_column_with_attributes(-1, "Name", new CellRendererText (), "text", 0);
                
                TreeIter iter;
                
				foreach (var group_entry in groups.entries) {
                    listmodel.append(out iter);
                    listmodel.set(iter, 0, "%s\n%i".printf(group_entry.key, group_entry.value));
				}
				
				foreach (var ungroup_list in ungroups) {
                    listmodel.append(out iter);
                    listmodel.set(iter, 0, "%s\n%s".printf(ungroup_list[0], ungroup_list[1]));
				}
            }
			
			show_all();
		}
		
		public void show_add_server_page() {
			Utils.destroy_all_children(this);
			
			// FIXME: back button.
			
			Entry address_entry = new Entry();
			address_entry.set_placeholder_text("IP address");
			pack_start(address_entry, false, false, 0);

			Entry user_entry = new Entry();
			user_entry.set_placeholder_text("Username");
			pack_start(user_entry, false, false, 0);

			Entry password_entry = new Entry();
			password_entry.set_placeholder_text("Password");
			password_entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
			pack_start(password_entry, false, false, 0);
			
			// FIXME: split line.
			
			ThemeSelector theme_selector = new ThemeSelector();
			pack_start(theme_selector, false, false, 0);

			Entry port_entry = new Entry();
			port_entry.set_placeholder_text("Port");
			pack_start(port_entry, false, false, 0);
			
			ComboBox encode_box = new ComboBox();
			pack_start(encode_box, false, false, 0);
			
			// FIXME: split line.
			
			Entry name_entry = new Entry();
			name_entry.set_placeholder_text("Name");
			pack_start(name_entry, false, false, 0);

			Entry groupname_entry = new Entry();
			groupname_entry.set_placeholder_text("Groupname");
			pack_start(groupname_entry, false, false, 0);
			
			TextButton add_server_button = new TextButton("Add server");
			pack_start(add_server_button, false, false, 0);
			
			add_server_button.button_press_event.connect((w, e) => {
					add_server(
						address_entry.get_text(),
						user_entry.get_text(),
						password_entry.get_text(),
						"",
						port_entry.get_text(),
						"",
						name_entry.get_text(),
						groupname_entry.get_text()
						);
					
					show_homepage();
					
					return false;
				});
			
			show_all();
		}
		
		public void add_server(
			string server_address,
			string user,
			string password,
			string theme,
			string port,
			string encode,
			string name,
			string group_name
			) {
			if (user != "" && server_address != "") {
			    Utils.touch_dir(Utils.get_config_dir());
			    
			    KeyFile config_file = new KeyFile();
			    try {
			    	config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
			    } catch (Error e) {
					if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
						print("show_homepage error: %s\n", e.message);
					}
			    }
			    
			    // Use ',' as array-element-separator instead of ';'.
			    config_file.set_list_separator (',');
			    
			    string gname = "%s@%s".printf(user, server_address);
			    config_file.set_string(gname, "Name", name);
			    config_file.set_string(gname, "GroupName", group_name);
			    config_file.set_string(gname, "Password", password);
			    config_file.set_string(gname, "Theme", theme);
			    config_file.set_string(gname, "Port", port);
			    config_file.set_string(gname, "Encode", encode);
			    
			    try {
			    	config_file.save_to_file(config_file_path);
			    } catch (Error e) {
			    	print("add_server error occur when config_file.save_to_file %s: %s\n", config_file_path, e.message);
			    }
			}
		}
		
		public void show_edit_server_page() {
			
		}
		
		public void show_search_page() {
			
		}
	}
}