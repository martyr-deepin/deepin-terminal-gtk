/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2018 Deepin, Inc.
 *               2011 ~ 2018 Wang Yong
 *
 * Author:     Wang Yong <wangyong@deepin.com>
 * Maintainer: Wang Yong <wangyong@deepin.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
namespace Menu {
    [DBus (name = "com.deepin.menu.Manager")]
    interface MenuManagerInterface : Object {
        public abstract string RegisterMenu() throws IOError;
    }

    [DBus (name = "com.deepin.menu.Menu")]
    interface MenuInterface : Object {
        public abstract void ShowMenu(string menu_json_content) throws IOError;
		public signal void ItemInvoked(string item_id, bool checked);
		public signal void MenuUnregistered();
	}

	public class MenuItem : Object {
		public string menu_item_id;
		public string menu_item_text;
		public List<MenuItem> menu_item_submenu;

		public MenuItem(string item_id, string item_text) {
			menu_item_id = item_id;
			menu_item_text = item_text;

			menu_item_submenu = new List<MenuItem>();
		}

		public void add_submenu_item(MenuItem item) {
			menu_item_submenu.append(item);
		}
	}

	public class Menu : Object {
		MenuInterface menu_interface;
		public List<MenuItem> menu_content;
		public MenuItem? search_submenu;

		public bool config_theme_is_light = false;
		public bool is_gtk_menu = false;
		public Gtk.Menu? gtk_menu;
		public Gtk.Menu? gtk_search_submenu;

		public signal void click_item(string item_id);
		public signal void destroy();

		public Menu(bool light_theme) {
			try {
			    MenuManagerInterface menu_manager_interface = Bus.get_proxy_sync(BusType.SESSION, "com.deepin.menu", "/com/deepin/menu");
			    string menu_object_path = menu_manager_interface.RegisterMenu();

				menu_interface = Bus.get_proxy_sync(BusType.SESSION, "com.deepin.menu", menu_object_path);
			    menu_interface.ItemInvoked.connect((item_id, checked) => {
						click_item(item_id);
			    	});
				menu_interface.MenuUnregistered.connect(() => {
						destroy();
					});
			} catch (IOError e) {
				stderr.printf ("%s\n", e.message);
			}

			config_theme_is_light = light_theme;
			if (is_gtk_menu)
				create_gtk_menu();

			menu_content = new List<MenuItem>();
		}

		public void create_gtk_menu() {
			Gdk.Screen screen = Gdk.Screen.get_default();
            CssProvider provider = new Gtk.CssProvider();
            try {
                provider.load_from_data(Utils.get_menu_css());
            } catch (GLib.Error e) {
                    warning("Something bad happened with CSS load %s", e.message);
            }
            Gtk.StyleContext.add_provider_for_screen(screen,provider,Gtk.STYLE_PROVIDER_PRIORITY_USER);
            gtk_menu = new Gtk.Menu();
            gtk_menu.get_style_context().add_class("gtk_menu");
            gtk_menu.destroy.connect(handle_gtk_menu_destroy);
		}

		public void create_submenu(string item_id, string item_text) {
            if (is_gtk_menu) {
                gtk_search_submenu = new Gtk.Menu();
                var item = new Gtk.MenuItem.with_label(item_text);
                if (!config_theme_is_light)
                    item.get_style_context().add_class("gtk_menu_item");
                else
                    item.get_style_context().add_class("gtk_menu_item_light");

                item.activate.connect(() => {
                    click_item(item_id);
                });
                item.set_submenu(gtk_search_submenu);
                gtk_menu.append(item);
            } else {
                search_submenu = new MenuItem(item_id, item_text);
                append(search_submenu);
            }
        }

        public void add_submenu_item(string item_id, string item_text) {
            if (is_gtk_menu) {
                var item = new Gtk.MenuItem.with_label(item_text);
                if(item_text == "") {
                    item = new Gtk.SeparatorMenuItem();
                }
                if (!config_theme_is_light) 
                    item.get_style_context().add_class("gtk_menu_item");
                else 
                    item.get_style_context().add_class("gtk_menu_item_light");

                item.activate.connect(() => { 
                    click_item(item_id); 
                });
                gtk_search_submenu.add(item);
            } else {
                search_submenu.add_submenu_item(new MenuItem(item_id, item_text));
            }
        }

		public void append(MenuItem menu_item) {
			if (is_gtk_menu) {
				var item = new Gtk.MenuItem.with_label(menu_item.menu_item_text);
                if(menu_item.menu_item_text == "") {
                    item = new Gtk.SeparatorMenuItem();
                }
                if (!config_theme_is_light) 
                    item.get_style_context().add_class("gtk_menu_item");
                else 
                    item.get_style_context().add_class("gtk_menu_item_light");

                item.activate.connect(() => { 
                    click_item(menu_item.menu_item_id); 
                });
                gtk_menu.append(item);
			} else {
				menu_content.append(menu_item);
			}
		}

	    public void show_menu(int x, int y) {
	    	if (is_gtk_menu) {
	    		show_gtk_menu();
	    		return;
	    	}

			// since GTK only supports integral scaling yet DDE supports fractional scaling,
			// the scale on both sides may not be the same, so we need to negtiate here.
			var scale = Utils.get_default_monitor_scale();
			var dde_scale = Utils.get_dde_scale_ratio();

			if (scale != dde_scale) {
				x = (int)(x * scale / dde_scale);
				y = (int)(y * scale / dde_scale);
			}

	    	try {
	    	    Json.Builder builder = new Json.Builder();

	            builder.begin_object();

	            builder.set_member_name("x");
	            builder.add_int_value(x);

	            builder.set_member_name("y");
	            builder.add_int_value(y);

	            builder.set_member_name("isDockMenu");
	            builder.add_boolean_value(false);

	    		builder.set_member_name("menuJsonContent");
	    		builder.add_string_value(get_items_node(menu_content));

	    	    builder.end_object ();

	    	    Json.Generator generator = new Json.Generator();
	            Json.Node root = builder.get_root();
	            generator.set_root(root);

	            string menu_json_content = generator.to_data(null);

	    	    menu_interface.ShowMenu(menu_json_content);
	    	} catch (IOError e) {
	    		stderr.printf ("%s\n", e.message);
	    	}
	    }

	    public void show_gtk_menu() {
	    	gtk_menu.show_all();
            gtk_menu.popup(null, null, null, 0, get_current_event_time());
            gtk_menu = null;
	    }

	    public string get_items_node(List<MenuItem> menu_content) {
	    	Json.Builder builder = new Json.Builder();

	        builder.begin_object();

	        builder.set_member_name("items");
	    	builder.begin_array ();
	    	foreach (MenuItem item in menu_content) {
			builder.add_value(get_item_node(item));
	    	}
	    	builder.end_array ();

	    	builder.end_object ();

	    	Json.Generator generator = new Json.Generator();
	    	generator.set_root(builder.get_root());

	        return generator.to_data(null);
	    }

	    public Json.Node get_item_node(MenuItem item) {
	    	Json.Builder builder = new Json.Builder();

	    	builder.begin_object();

	        builder.set_member_name("itemId");
		builder.add_string_value(item.menu_item_id);

	        builder.set_member_name("itemText");
		builder.add_string_value(item.menu_item_text);

	        builder.set_member_name("itemIcon");
	    	builder.add_string_value("");

	        builder.set_member_name("itemIconHover");
	    	builder.add_string_value("");

	        builder.set_member_name("itemIconInactive");
	    	builder.add_string_value("");

	        builder.set_member_name("itemExtra");
	    	builder.add_string_value("");

	        builder.set_member_name("isActive");
	    	builder.add_boolean_value(true);

	        builder.set_member_name("checked");
	    	builder.add_boolean_value(false);

		builder.set_member_name("itemSubMenu");
		unowned List<MenuItem> submenu_items = item.menu_item_submenu;

		if (submenu_items.length() == 0) {
			builder.add_null_value();
		} else {
			Json.Builder _builder = new Json.Builder();

			_builder.begin_object ();

			_builder.set_member_name("items");

			_builder.begin_array ();
			foreach (MenuItem _item in submenu_items) {
				_builder.add_value(get_item_node(_item));
			}
			_builder.end_array ();

			_builder.end_object ();

			builder.add_value(_builder.get_root());
		}

	    	builder.end_object ();

	        return builder.get_root();
	    }

	    public void handle_gtk_menu_destroy() {
        	search_submenu = null;
        	gtk_search_submenu = null;
		}
	}
}
