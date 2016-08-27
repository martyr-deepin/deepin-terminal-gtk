/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2016 Deepin, Inc.
 *               2011 ~ 2016 Wang Yong
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
using Widgets;
using Utils;
using Gee;

namespace Widgets {
	public class ThemePanel : Gtk.HBox {
		public Widgets.ConfigWindow parent_window;
		public WorkspaceManager workspace_manager;
        public Gdk.RGBA background_color;
        public Gdk.RGBA line_dark_color;
        public Gdk.RGBA line_light_color;
        public Gtk.Box home_page_box;
        public Gtk.ScrolledWindow scrolledwindow;
        public Gtk.Widget focus_widget;
        public KeyFile config_file;
        public Widgets.Switcher switcher;
        public Workspace workspace;
        public int back_button_margin_left = 8;
        public int back_button_margin_top = 6;
        public int split_line_margin_left = 1;
        public int theme_button_padding = 5;
        public int width = Constant.SLIDER_WIDTH;
        
        public delegate void UpdatePageAfterEdit();
		
		public ThemePanel(Workspace space, WorkspaceManager manager) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
            
            workspace = space;
			workspace_manager = manager;
            
            config_file = new KeyFile();
            
            line_dark_color = Utils.hex_to_rgba("#ffffff", 0.1);
            line_light_color = Utils.hex_to_rgba("#000000", 0.1);
            
            focus_widget = ((Gtk.Window) workspace.get_toplevel()).get_focus();
			parent_window = (Widgets.ConfigWindow) workspace.get_toplevel();
            try {
                background_color = Utils.hex_to_rgba(parent_window.config.config_file.get_string("theme", "background"));
            } catch (Error e) {
                print("ThemePanel init: %s\n", e.message);
            }
            
            switcher = new Widgets.Switcher(width);
            
            home_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            set_size_request(width, -1);
            home_page_box.set_size_request(width, -1);
            
            pack_start(switcher, true, true, 0);
            
            show_home_page();
			
			draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
            
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, 0.8);
            Draw.draw_rectangle(cr, 1, 0, rect.width - 1, rect.height);
            
            if (is_light_theme) {
                Utils.set_context_color(cr, line_light_color);
            } else {
                Utils.set_context_color(cr, line_dark_color);
            }
            Draw.draw_rectangle(cr, 0, 0, 1, rect.height);
            
            return false;
        }
		
		public void show_home_page(Gtk.Widget? start_widget=null) {
            try {
                scrolledwindow = new ScrolledWindow(null, null);
                scrolledwindow.get_style_context().add_class("scrolledwindow");
                scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
                scrolledwindow.get_vscrollbar().get_style_context().add_class("light_scrollbar");
                home_page_box.pack_start(scrolledwindow, true, true, 0);
            
                var theme_name = parent_window.config.config_file.get_string("general", "theme");
                var theme_list = new ThemeList(theme_name);
                theme_list.active_theme.connect((active_theme_name) => {
                        parent_window.config.config_file.set_string("general", "theme", active_theme_name);
                        parent_window.config.set_theme(active_theme_name);
                        parent_window.config.save();
                        parent_window.config.update();
                    });
            
                scrolledwindow.add(theme_list);
            
                switcher.add_to_left_box(home_page_box);

                realize.connect((w) => {
                        int widget_x, widget_y;
                        theme_list.translate_coordinates(theme_list.active_theme_button, 0, 0, out widget_x, out widget_y);
                    
                        print("%i %i\n", widget_x, widget_y);
                    
                        var adjust = scrolledwindow.get_vadjustment();
                        adjust.set_value(Math.fabs(widget_y));
                    });
            
                show_all();
            } catch (Error e) {
                print("ThemePanel show_home_page: %s\n", e.message);
            }
		}
    }
}