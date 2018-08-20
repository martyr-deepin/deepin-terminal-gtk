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
    public class ClickEventBox : Gtk.EventBox {
        public bool is_press = false;

        public signal void clicked(Gdk.EventButton event);

        public ClickEventBox() {
            button_press_event.connect((w, e) => {
                    is_press = true;

                    return false;
                });

            button_release_event.connect((w, e) => {
                    if (is_press && Utils.is_left_button(e) && Utils.pointer_in_widget_area(this)) {
                        clicked(e);
                    }

                    is_press = false;

                    return false;
                });
        }
    }
}
