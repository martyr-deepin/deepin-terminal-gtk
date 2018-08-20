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

namespace XUtils {
    public static int _NET_WM_MOVERESIZE_MOVE = 8;
    public static int _NET_WM_MOVERESIZE_SIZE_BOTTOM = 5;
    public static int _NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT = 6;
    public static int _NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT = 4;
    public static int _NET_WM_MOVERESIZE_SIZE_LEFT = 7;
    public static int _NET_WM_MOVERESIZE_SIZE_RIGHT = 3;
    public static int _NET_WM_MOVERESIZE_SIZE_TOP = 1;
    public static int _NET_WM_MOVERESIZE_SIZE_TOPLEFT = 0;
    public static int _NET_WM_MOVERESIZE_SIZE_TOPRIGHT = 2;

    public void seat_ungrab() {
        Gdk.Display gdk_display = Gdk.Display.get_default();
        var seat = gdk_display.get_default_seat();
        seat.ungrab();
    }

    public void move_window(Gtk.Widget widget, int x, int y, int button) {
        seat_ungrab();
        send_message((int)((Gdk.X11.Window) widget.get_toplevel().get_window()).get_xid(),
                     (long) x,
                     (long) y,
                     _NET_WM_MOVERESIZE_MOVE,
                     button,
                     0  // this value must be 0, otherwise moveresize won't work.
                     );
    }

    public void resize_window(Gtk.Widget widget, int x, int y, int button, Gdk.CursorType cursor_type) {
        int? action = cursor_type_to_action(cursor_type);
        if (action != null) {
            seat_ungrab();
            send_message((int)((Gdk.X11.Window) widget.get_toplevel().get_window()).get_xid(),
                         (long) x,
                         (long) y,
                         action,
                         button,
                         1
                         );
        }
    }

    public int? cursor_type_to_action(Gdk.CursorType cursor_type) {
        if (cursor_type == Gdk.CursorType.TOP_LEFT_CORNER) {
            return _NET_WM_MOVERESIZE_SIZE_TOPLEFT;
        } else if (cursor_type == Gdk.CursorType.TOP_SIDE) {
            return _NET_WM_MOVERESIZE_SIZE_TOP;
        } else if (cursor_type == Gdk.CursorType.TOP_RIGHT_CORNER) {
            return _NET_WM_MOVERESIZE_SIZE_TOPRIGHT;
        } else if (cursor_type == Gdk.CursorType.RIGHT_SIDE) {
            return _NET_WM_MOVERESIZE_SIZE_RIGHT;
        } else if (cursor_type == Gdk.CursorType.BOTTOM_RIGHT_CORNER) {
            return _NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT;
        } else if (cursor_type == Gdk.CursorType.BOTTOM_SIDE) {
            return _NET_WM_MOVERESIZE_SIZE_BOTTOM;
        } else if (cursor_type == Gdk.CursorType.BOTTOM_LEFT_CORNER) {
            return _NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT;
        } else if (cursor_type == Gdk.CursorType.LEFT_SIDE) {
            return _NET_WM_MOVERESIZE_SIZE_LEFT;
        }

        return null;
    }

    public void send_message(int xid, long x, long y, int action, int button, int secret_value) {
        weak X.Display display = Gdk.X11.get_default_xdisplay();
        weak X.Window xrootwindow = display.root_window(0);

        X.Event event = X.Event();

        event.xclient.type = X.EventType.ClientMessage;
        event.xclient.message_type = Gdk.X11.get_xatom_by_name("_NET_WM_MOVERESIZE");
        event.xclient.display = display;
        event.xclient.window = xid;
        event.xclient.format = 32;
        event.xclient.data.l[0] = x;
        event.xclient.data.l[1] = y;
        event.xclient.data.l[2] = action;
        event.xclient.data.l[3] = button;
        event.xclient.data.l[4] = secret_value;

        display.send_event(
            xrootwindow,
            false,
            X.EventMask.SubstructureNotifyMask | X.EventMask.SubstructureRedirectMask,
            ref event);

        display.flush();
    }
}
