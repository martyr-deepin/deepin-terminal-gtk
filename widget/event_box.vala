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

namespace Widgets {
    public class EventBox : Gtk.EventBox {
        public EventBox() {
            visible_window = false;
            
            draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            Widgets.ConfigWindow window = (Widgets.ConfigWindow) this.get_toplevel();

 			try {
				cr.set_source_rgba(0, 0, 0, window.config.config_file.get_double("general", "opacity"));
			} catch (GLib.KeyFileError e) {
				print("EventBox: %s\n", e.message);
			}
			cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_operator(Cairo.Operator.OVER);
            
            foreach(Gtk.Widget w in this.get_children()) {
                w.draw(cr);
            };

            return true;
        }
    }
}