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

namespace Widgets {
    public class AboutWidget : Gtk.Box {
        public Cairo.ImageSurface icon_surface;
        public Cairo.ImageSurface logo_surface;
        public int about_height = 9;
        public int about_x = 38;
        public int about_y = 251;
        public int height = 320;
        public int homepage_y = 210;
        public int icon_y = 13;
        public int logo_y = 176;
        public int name_height = 13;
        public int name_y = 113;
        public int version_height = 12;
        public int version_size = 11;
        public int version_y = 146;
        public string about_text;
        
        public AboutWidget() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
            
            about_text = _("Deepin Terminal is an advanced terminal emulator with workspace, multiple windows, remote management, quake mode and other features. It sharpens your focus in the world of command line!");
            
            icon_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("icon.png"));
            logo_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("logo.png"));
            
            set_size_request(-1, height);

            var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            var homepage_area = new Gtk.EventBox();
            homepage_area.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                                     | Gdk.EventMask.BUTTON_RELEASE_MASK
                                     | Gdk.EventMask.POINTER_MOTION_MASK
                                     | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            homepage_area.margin_top = homepage_y;
            homepage_area.visible_window = false;
            var homepage_label = new Gtk.Label(null);
            homepage_label.set_text("www.deepin.org");
            homepage_label.get_style_context().add_class("link");
            homepage_area.add(homepage_label);
            homepage_area.enter_notify_event.connect((w, e) => {
                    var display = Gdk.Display.get_default();
                    get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND1));
                    
                    return false;
                });
            homepage_area.leave_notify_event.connect((w, e) => {
                    get_window().set_cursor(null);
                    
                    return false;
                });
            homepage_area.button_release_event.connect((w, e) => {
                    Gdk.Screen screen = Gdk.Screen.get_default();
                    try {
                        Gtk.show_uri(screen, "https://www.deepin.org", e.time);
                    } catch (GLib.Error e) {
                        print("About dialog homepage: %s\n", e.message);
                    }
                    
                    return false;
                });
            
            content_box.pack_start(homepage_area, false, false, 0);
            pack_start(content_box, true, true, 0);

            draw.connect(on_draw);
            
            show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            // Draw icon.
            Draw.draw_surface(cr, icon_surface, (rect.width - icon_surface.get_width()) / 2, icon_y);
            
            // Draw name.
            cr.set_source_rgba(0, 0, 0, 1);
            Draw.draw_text(cr, _("Deepin Terminal"), 0, name_y, rect.width, name_height, name_height, Pango.Alignment.CENTER, "top");
            
            // Draw version.
            cr.set_source_rgba(0.4, 0.4, 0.4, 1);
            Draw.draw_text(cr, "%s: %.01f".printf(_("Version"), Constant.VERSION), 0, version_y, rect.width, version_height, version_size, Pango.Alignment.CENTER, "top");
            
            // Draw logo.
            Draw.draw_surface(cr, logo_surface, (rect.width - logo_surface.get_width()) / 2, logo_y);
            
            // Draw about.
            cr.set_source_rgba(0.1, 0.1, 0.1, 1);
            Draw.draw_text(cr, about_text, about_x, about_y, rect.width - about_x * 2, about_height, about_height, Pango.Alignment.CENTER, "top", rect.width - about_x * 2);
            
            Utils.propagate_draw(this, cr);
            
            return true;
        }        
    }
}