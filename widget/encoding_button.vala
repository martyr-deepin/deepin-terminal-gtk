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

using Gee;
using Gtk;
using Widgets;

namespace Widgets {
    public class EncodingButton : Gtk.EventBox {
        public Cairo.ImageSurface active_theme_border_surface;
        public Cairo.ImageSurface dark_theme_border_surface;
        public Cairo.ImageSurface light_theme_border_surface;
        public Gdk.RGBA background_color;
        public Gdk.RGBA content_color;
        public Gdk.RGBA foreground_color;
        public KeyFile theme_file;
        public bool is_active = false;
        public bool is_light_color;
        public int background_padding = 2;
        public int border_padding = 1;
        public int button_radius = 5;
        public int content_font_size = 11;
        public int content_padding_x = 24;
        public int content_padding_y = 15;
        public string encoding_name;

        public EncodingButton(string name, Workspace space) {
            encoding_name = name;

            try {
                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) space.get_toplevel();
                var theme_name = parent_window.config.config_file.get_string("general", "theme");

                theme_file = new KeyFile();
                theme_file.load_from_file(Utils.get_theme_path(theme_name), KeyFileFlags.NONE);
                background_color = Utils.hex_to_rgba(theme_file.get_string("theme", "background").strip());
                is_light_color = Utils.is_light_color(theme_file.get_string("theme", "background").strip());

                background_color.alpha = 0.8;
                foreground_color = Utils.hex_to_rgba(theme_file.get_string("theme", "foreground").strip());
                content_color = Utils.hex_to_rgba(theme_file.get_string("theme", "color_2").strip());

                dark_theme_border_surface = Utils.create_image_surface("dark_theme_border.svg");
                light_theme_border_surface = Utils.create_image_surface("light_theme_border.svg");
                active_theme_border_surface = Utils.create_image_surface("active_theme_border.svg");
            } catch (Error e) {
                print("EncodingButton: %s\n", e.message);
            }

            visible_window = false;

            set_size_request(Constant.ENCODING_BUTTON_WIDTH, Constant.ENCODING_BUTTON_HEIGHT);
            margin_start = (Constant.ENCODING_SLIDER_WIDTH - Constant.ENCODING_BUTTON_WIDTH) / 2;
            margin_end = (Constant.ENCODING_SLIDER_WIDTH - Constant.ENCODING_BUTTON_WIDTH) / 2;

            draw.connect(on_draw);
        }

        public void active() {
            is_active = true;

            queue_draw();
        }

        public void inactive() {
            is_active = false;

            queue_draw();
        }

        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);

            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, background_color.alpha);
            Draw.fill_rounded_rectangle(cr, background_padding, background_padding, rect.width - background_padding * 2, rect.height - background_padding * 2, button_radius);

            cr.set_source_rgba(content_color.red, content_color.green, content_color.blue, content_color.alpha);
            Draw.draw_text(cr, encoding_name, content_padding_x, content_padding_y, rect.width, rect.height, content_font_size, Pango.Alignment.LEFT, "top");

            if (is_active) {
                Draw.draw_surface(cr, active_theme_border_surface);
            } else if (is_light_color) {
                Draw.draw_surface(cr, light_theme_border_surface, border_padding, border_padding);
            } else {
                Draw.draw_surface(cr, dark_theme_border_surface, border_padding, border_padding);
            }

            return true;
        }
    }

    public class EncodingList : Gtk.VBox {
        public int encoding_button_padding = Constant.ENCODING_BUTTON_PADDING;
        public HashMap<string, EncodingButton> encoding_button_map;
        public EncodingButton? active_encoding_button = null;

        public signal void active_encoding(string encoding_name);

        public EncodingList(string temrinal_encoding, ArrayList<string> encoding_names, Workspace space) {
            encoding_button_map = new HashMap<string, EncodingButton>();

            foreach (string encoding_name in encoding_names) {
                var button = new Widgets.EncodingButton(encoding_name, space);
                pack_start(button, false, false, encoding_button_padding);

                button.button_press_event.connect((w, e) => {
                        if (Utils.is_left_button(e)) {
                            active_button(encoding_name);
                            active_encoding(encoding_name);
                        }

                        return false;
                    });

                encoding_button_map.set(encoding_name, button);
            }

            active_button(temrinal_encoding);
        }

        public void active_button(string encoding_name) {
            if (active_encoding_button != null) {
                active_encoding_button.inactive();
            }

            active_encoding_button = encoding_button_map.get(encoding_name);
            active_encoding_button.active();
        }
    }
}
