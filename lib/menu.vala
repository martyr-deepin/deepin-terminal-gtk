/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2017 Deepin, Inc.
 *               2011 ~ 2017 Wang Yong
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
		
		public MenuItem(string item_id, string item_text) {
			menu_item_id = item_id;
			menu_item_text = item_text;
		}
	}
	
	public class Menu : Object {
		MenuInterface menu_interface;
		
		public signal void click_item(string item_id);
		public signal void destroy();
		
		public Menu(int menu_x, int menu_y, List<MenuItem> menu_content) {
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
			
			show_menu(menu_x, menu_y, menu_content);
		}
		
	    public void show_menu(int x, int y, List<MenuItem> menu_content) {
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
	    
	    public string get_items_node(List<MenuItem> menu_content) {
	    	Json.Builder builder = new Json.Builder();
	    	    
	        builder.begin_object();
	    	
	        builder.set_member_name("items");
	    	builder.begin_array ();
	    	foreach (MenuItem item in menu_content) {
	    		builder.add_value(get_item_node(item.menu_item_id, item.menu_item_text));
	    	}
	    	builder.end_array ();
	    	
	    	builder.end_object ();
	        
	    	Json.Generator generator = new Json.Generator();
	    	generator.set_root(builder.get_root());
	    	
	        return generator.to_data(null);
	    }
	    
	    public Json.Node get_item_node(string item_id, string item_text) {
	    	Json.Builder builder = new Json.Builder();
	    	
	    	builder.begin_object();
	    	
	        builder.set_member_name("itemId");
	    	builder.add_string_value(item_id);
	    	
	        builder.set_member_name("itemText");
	    	builder.add_string_value(item_text);
	    	
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
	    	
	        builder.set_member_name("isSubMenu");
	    	builder.add_null_value();
	    	
	    	builder.end_object ();
	        
	        return builder.get_root();
	    }		
	}
}