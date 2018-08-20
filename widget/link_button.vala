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
    public class LinkButton : Widgets.ClickEventBox {
        public string link_css;
        public string link_name;
        public string link_uri;

        public LinkButton(string link_name, string link_uri, string link_css) {
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                       | Gdk.EventMask.BUTTON_RELEASE_MASK
                       | Gdk.EventMask.POINTER_MOTION_MASK
                       | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            visible_window = false;

            var link_label = new Gtk.Label(null);
            link_label.set_text(link_name);
            link_label.get_style_context().add_class(link_css);
            add(link_label);
            enter_notify_event.connect((w, e) => {
                    var display = Gdk.Display.get_default();
                    get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND1));

                    return false;
                });
            leave_notify_event.connect((w, e) => {
                    get_window().set_cursor(null);

                    return false;
                });
            clicked.connect((w, e) => {
                    Gdk.Screen screen = Gdk.Screen.get_default();
                    try {
                        Gtk.show_uri(screen, link_uri, e.time);
                    } catch (GLib.Error e) {
                        print("LinkButton: %s\n", e.message);
                    }
                });
        }
    }
}
