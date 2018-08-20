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
    public class ServerButton : Widgets.PanelButton {
        public signal void edit_server(string server_info);
        public signal void login_server(string server_info);

        public ServerButton(string server_title, string server_content) {
            string[] server_infos = server_content.split("@");
            string display_name = "";
            if (server_infos.length > 2) {
                display_name = "%s@%s:%s".printf(server_infos[0], server_infos[1], server_infos[2]);
            } else {
                display_name = "%s@%s".printf(server_infos[0], server_infos[1]);
            }

            base(server_title, server_content, display_name, "server");

            click_edit_button.connect((w) => {
                    edit_server(server_content);
                });
            click_button.connect((w) => {
                    login_server(server_content);
                });
        }
    }
}
