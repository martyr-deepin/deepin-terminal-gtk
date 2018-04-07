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
using Utils;

namespace Widgets {
    public class EntryMenu : Object {
        public bool config_theme_is_light;
        
        public EntryMenu() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
        }

        public Gtk.MenuItem get_menu_item(Gtk.Entry entry, string item_id, string item_text) {
            var item = new Gtk.MenuItem.with_label(item_text);
            if(item_text == "") {
                item = new Gtk.SeparatorMenuItem();
            }
            if (!config_theme_is_light) 
                item.get_style_context().add_class("gtk_menu_item");
            else 
                item.get_style_context().add_class("gtk_menu_item_light");

            item.activate.connect(() => { 
                handle_menu_item_click(entry, item_id); 
                });
            return item;
        }

        public void create_entry_menu(Gtk.Entry entry, int x, int y) {
            Gdk.Screen screen = Gdk.Screen.get_default();
            CssProvider provider = new Gtk.CssProvider();
            try {
                provider.load_from_data(Utils.get_menu_css());
            } catch (GLib.Error e) {
                warning("Something bad happened with CSS load %s", e.message);
            }
            Gtk.StyleContext.add_provider_for_screen(screen,provider,Gtk.STYLE_PROVIDER_PRIORITY_USER);

            Gtk.Menu menu_content = new Gtk.Menu();
            menu_content.get_style_context().add_class("gtk_menu");

            if (is_selection(entry)) {
                menu_content.append(get_menu_item(entry, "cut", _("Cut")));
                menu_content.append(get_menu_item(entry, "copy", _("Copy")));
            }
            menu_content.append(get_menu_item(entry, "paste", _("Paste")));
            menu_content.append(get_menu_item(entry, "", ""));
            if (is_selection(entry)) {
                menu_content.append(get_menu_item(entry, "delete", _("Delete")));
                menu_content.append(get_menu_item(entry, "", ""));
            }
            menu_content.append(get_menu_item(entry, "select_all", _("Select all")));
                        
            menu_content.show_all();
            menu_content.popup(null, null, null, 0, get_current_event_time());
        }

        public void handle_menu_item_click(Gtk.Entry entry, string item_id) {
            switch(item_id) {
                case "cut":
                    entry.cut_clipboard();
                    break;
                case "copy":
                    entry.copy_clipboard();
                    break;
                case "paste":
                    entry.paste_clipboard();
                    break;
                case "delete":
                    entry.delete_selection();
                    break;
                case "select_all":
                    entry.select_region(0, -1);
                    break;
            }
        }        
            
        public bool is_selection(Gtk.Entry entry) {
            int start_pos, end_pos;
            entry.get_selection_bounds(out start_pos, out end_pos);
                
            return start_pos != end_pos;
        }
    }
}