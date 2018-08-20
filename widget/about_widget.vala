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
    public class AboutWidget : Gtk.Box {
        public Cairo.ImageSurface icon_surface;
        public Cairo.ImageSurface logo_surface;
        public int about_height = 9;
        public int about_x = 38;
        public int about_y = 270;
        public int acknowledgments_y = 10;
        public int height = 320;
        public int homepage_y = 200;
        public int icon_y = 13;
        public int logo_y = 176;
        public int name_height = 13;
        public int name_y = 106;
        public int version_height = 12;
        public int version_size = 9;
        public int version_y = 146;
        public string about_text;

        public AboutWidget() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            about_text = _("Deepin Terminal is an advanced terminal emulator with workspace, multiple windows, remote management, quake mode and other features.\n\nIt sharpens your focus in the world of command line!");

            icon_surface = Utils.create_image_surface("icon.svg");
            logo_surface = Utils.create_image_surface("logo.svg");

            set_size_request(-1, height);

            var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            content_box.margin_top = homepage_y;

            // Add homepage.
            try {
                // Check deepin system's version is whether professional.
                string os_version_path = "/etc/deepin-version";
                bool is_professional = false;
                var version_file = File.new_for_path(os_version_path);
                if (version_file.query_exists()) {
                    var version_config_file = new KeyFile();
                    version_config_file.load_from_file(os_version_path, KeyFileFlags.NONE);

                    is_professional = version_config_file.get_string("Release", "Type") == "Professional";
                }

                string homepage_name = is_professional ? "www.deepin.com" : "www.deepin.org";
                string homepage_link = "https://" + homepage_name;

                var homepage_area = new Widgets.LinkButton(homepage_name, homepage_link, "homepage");
                content_box.pack_start(homepage_area, false, false, 0);
            } catch (Error e) {
                print("AboutWidget error: %s", e.message);
            }

            var acknowledgments_area = new Widgets.LinkButton(_("Acknowledgments"), "https://www.deepin.org/acknowledgments/deepin-terminal", "acknowledgments");
            acknowledgments_area.margin_top = acknowledgments_y;
            content_box.pack_start(acknowledgments_area, false, false, 0);

            pack_start(content_box, true, true, 0);

            draw.connect(on_draw);

            show_all();
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);

            // Draw icon.
            Draw.draw_surface(cr, icon_surface, (rect.width - icon_surface.get_width() / get_scale_factor()) / 2, icon_y);

            // Draw name.
            cr.set_source_rgba(0, 0, 0, 1);
            Draw.draw_text(cr, _("Deepin Terminal"), 0, name_y, rect.width, name_height, name_height, Pango.Alignment.CENTER, "top");

            // Draw version.
            cr.set_source_rgba(0.4, 0.4, 0.4, 1);
            Draw.draw_text(cr, "%s %s".printf(_("Version:"), Constant.VERSION), 0, version_y, rect.width, version_height, version_size, Pango.Alignment.CENTER, "top");

            // Draw logo.
            Draw.draw_surface(cr, logo_surface, (rect.width - logo_surface.get_width() / get_scale_factor()) / 2, logo_y);

            // Draw about.
            cr.set_source_rgba(0.1, 0.1, 0.1, 1);
            Draw.draw_text(cr, about_text, about_x, about_y, rect.width - about_x * 2, about_height, about_height, Pango.Alignment.CENTER, "top", rect.width - about_x * 2);

            Utils.propagate_draw(this, cr);

            return true;
        }
    }
}
