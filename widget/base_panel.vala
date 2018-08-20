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

namespace Widgets {
    public class BasePanel : Gtk.HBox {
        public Widgets.ConfigWindow parent_window;
        public WorkspaceManager workspace_manager;
        public Gdk.RGBA background_color;
        public Gdk.RGBA line_dark_color;
        public Gdk.RGBA line_light_color;
        public Gtk.Box home_page_box;
        public Gtk.Box search_page_box;
        public Gtk.ScrolledWindow? home_page_scrolledwindow;
        public Gtk.ScrolledWindow? search_page_scrolledwindow;
        public Gtk.Widget? focus_widget;
        public Widgets.Switcher switcher;
        public Workspace workspace;
        public int back_button_margin_left = 8;
        public int back_button_margin_top = 6;

        public BasePanel() {
            home_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            search_page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            line_dark_color = Utils.hex_to_rgba("#ffffff", 0.1);
            line_light_color = Utils.hex_to_rgba("#000000", 0.1);
        }

        public Gtk.ScrolledWindow create_scrolled_window() {
            var scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.get_style_context().add_class("scrolledwindow");
            scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            scrolledwindow.get_vscrollbar().get_style_context().add_class("light_scrollbar");

            return scrolledwindow;
        }

        public void update_search_page(string search_text, string group_name) {
            double scroll_value = 0;
            if (search_page_scrolledwindow != null) {
                scroll_value = search_page_scrolledwindow.get_vadjustment().get_value();
            }

            create_search_page(search_text, group_name);

            switcher.add_to_left_box(search_page_box);

            if (search_page_scrolledwindow != null) {
                search_page_scrolledwindow.get_vadjustment().set_value(scroll_value);
            }

            show_all();
        }

        public void show_home_page(Gtk.Widget? start_widget=null) {
            create_home_page();

            if (start_widget == null) {
                switcher.add_to_left_box(home_page_box);
            } else {
                switcher.scroll_to_left(start_widget, home_page_box);
            }

            show_all();
        }

        public void show_search_page(string search_text, string group_name, Gtk.Widget start_widget) {
            create_search_page(search_text, group_name);

            switcher.scroll_to_right(start_widget, search_page_box);

            show_all();
        }

        public void update_home_page() {
            double scroll_value = 0;
            if (home_page_scrolledwindow != null) {
                scroll_value = home_page_scrolledwindow.get_vadjustment().get_value();
            }

            create_home_page();

            switcher.add_to_left_box(home_page_box);

            if (home_page_scrolledwindow != null) {
                home_page_scrolledwindow.get_vadjustment().set_value(scroll_value);
            }

            show_all();
        }

        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
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

        public virtual void create_search_page(string search_text, string group_name) {
        }

        public virtual void create_home_page() {
        }
    }
}
