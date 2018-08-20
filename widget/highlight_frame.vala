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
using Widgets;

namespace Widgets {
    public class HighlightFrame : Gtk.EventBox {
        public Gdk.RGBA foreground_color = Gdk.RGBA();

        public HighlightFrame() {
            draw.connect(on_draw);
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);

            try {
                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) this.get_toplevel();
                foreground_color = Utils.hex_to_rgba(parent_window.config.config_file.get_string("theme", "foreground"));
            } catch (GLib.KeyFileError e) {
                print("HighlightFrame: %s\n", e.message);
            }

            cr.set_source_rgba(foreground_color.red, foreground_color.green, foreground_color.blue, 0.4);
            Draw.draw_rectangle(cr, rect.x, rect.y, rect.width, rect.height, false);

            return true;
        }
    }
}
