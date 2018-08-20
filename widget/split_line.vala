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
    public class SplitLine : Gtk.Box {
        public int split_line_margin_left = 1;

        public SplitLine() {
            margin_left = split_line_margin_left;
            set_size_request(-1, 1);

            draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);

                    bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
                    if (is_light_theme) {
                        cr.set_source_rgba(0, 0, 0, 0.1);
                    } else {
                        cr.set_source_rgba(1, 1, 1, 0.1);
                    }
                    Draw.draw_rectangle(cr, 0, 0, rect.width, 1);

                    return true;
                });
        }
    }
}
