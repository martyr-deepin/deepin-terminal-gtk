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
    public class AddButton : Gtk.Button {
        public int height = 36;

        public AddButton(string button_name) {
            set_label("＋ %s".printf(button_name));
            set_size_request(-1, height);

            realize.connect((w) => {
                    bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
                    if (is_light_theme) {
                        get_style_context().add_class("add_button_light");
                    } else {
                        get_style_context().add_class("add_button_dark");
                    }
                });
        }
    }
}
