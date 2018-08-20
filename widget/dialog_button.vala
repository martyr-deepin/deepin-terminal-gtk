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

using Cairo;
using Draw;
using Gtk;
using Utils;

namespace Widgets {
    public class DialogButton : Gtk.Button {
        public DialogButton(string? text=null, string direction="left", string type="text", bool has_radius=true) {
            set_label(text);
            set_size_request(-1, Constant.DIALOG_BUTTON_HEIGHT);
            if (direction == "middle") {
                if (has_radius) {
                    get_style_context().add_class("dialog_button_%s".printf(type));
                } else {
                    get_style_context().add_class("dialog_noradius_button_%s".printf(type));
                }
            } else {
                if (has_radius) {
                    get_style_context().add_class("dialog_button_%s_%s".printf(direction, type));
                } else {
                    get_style_context().add_class("dialog_noradius_button_%s_%s".printf(direction, type));
                }
            }

            enter_notify_event.connect((w) => {
                    grab_focus();

                    return false;
                });
        }
    }
}
