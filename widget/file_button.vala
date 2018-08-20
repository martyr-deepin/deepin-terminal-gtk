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
    public class FileButton : Gtk.EventBox {
        public Gtk.Box box;
        public Gtk.Box button_box;
        public ImageButton file_add_button;
        public Widgets.Entry entry;
        public int height = 26;

        public FileButton() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            visible_window = false;

            set_size_request(-1, height);

            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            entry = new Widgets.Entry();
            entry.margin_top = 1;
            entry.margin_bottom = 1;

            file_add_button = new ImageButton("file_add");

            button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            box.pack_start(entry, true, true, 0);
            box.pack_start(button_box, false, false, 0);

            entry.get_style_context().add_class("file_add_entry");
            button_box.pack_start(file_add_button, false, false, 0);

            file_add_button.clicked.connect((w, e) => {
                    select_private_key_file();
                });

            add(box);
        }

        public void select_private_key_file() {
            Gtk.FileChooserAction action = Gtk.FileChooserAction.OPEN;
            var chooser = new Gtk.FileChooserDialog(_("Select the private key file"),
                    get_toplevel() as Gtk.Window, action);
            chooser.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
            chooser.set_select_multiple(true);
            chooser.add_button(_("Select"), Gtk.ResponseType.ACCEPT);

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                entry.set_text(chooser.get_file().get_path());
            }

            chooser.destroy();
        }
    }
}
