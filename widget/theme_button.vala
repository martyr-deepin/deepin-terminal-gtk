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
    public class ThemeButton : Gtk.EventBox {
        public Cairo.ImageSurface active_theme_border_surface;
        public Cairo.ImageSurface dark_theme_border_surface;
        public Cairo.ImageSurface light_theme_border_surface;
        public Gdk.RGBA background_color;
        public Gdk.RGBA prompt_color_host;
        public Gdk.RGBA prompt_color_path;
        public Gdk.RGBA foreground_color;
        public KeyFile theme_file;
        public bool is_active = false;
        public bool is_light_color;
        public int background_padding = 2;
        public int border_padding = 1;
        public int button_radius = 5;
        public int content_font_size = 11;
        public int content_padding_x = 14;
        public int content_padding_y = 25;
        public int title_font_size = 11;
        public int title_padding_x = 14;
        public int title_padding_y = 6;
        public string theme_name;

        public ThemeButton(string name) {
            theme_name = name;

            try {
                theme_file = new KeyFile();
                theme_file.load_from_file(Utils.get_theme_path(theme_name), KeyFileFlags.NONE);
                background_color = Utils.hex_to_rgba(theme_file.get_string("theme", "background").strip());
                is_light_color = Utils.is_light_color(theme_file.get_string("theme", "background").strip());

                background_color.alpha = 0.8;
                foreground_color = Utils.hex_to_rgba(theme_file.get_string("theme", "foreground").strip());
                prompt_color_host = Utils.hex_to_rgba(theme_file.get_string("theme", "color_11").strip());
                prompt_color_path = Utils.hex_to_rgba(theme_file.get_string("theme", "color_13").strip());

                dark_theme_border_surface = Utils.create_image_surface("dark_theme_border.svg");
                light_theme_border_surface = Utils.create_image_surface("light_theme_border.svg");
                active_theme_border_surface = Utils.create_image_surface("active_theme_border.svg");
            } catch (Error e) {
                print("ThemeButton: %s\n", e.message);
            }

            visible_window = false;

            set_size_request(Constant.THEME_BUTTON_WIDTH, Constant.THEME_BUTTON_HEIGHT);
            margin_start = (Constant.THEME_SLIDER_WIDTH - Constant.THEME_BUTTON_WIDTH) / 2;
            margin_end = (Constant.THEME_SLIDER_WIDTH - Constant.THEME_BUTTON_WIDTH) / 2;

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

            int clip_width = rect.width - background_padding * 2;
            int clip_height = rect.height - background_padding * 2;

            cr.save();
            // Clip round rectangle when DPI > 1, for perfect radius effect.
            if (get_scale_factor() > 1) {
                Draw.clip_rounded_rectangle(
                    cr,
                    background_padding,
                    background_padding,
                    clip_width,
                    clip_height,
                    button_radius / get_scale_factor() + 1);
            }
            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, background_color.alpha);
            Draw.fill_rounded_rectangle(
                cr,
                background_padding,
                background_padding,
                clip_width,
                clip_height,
                button_radius / get_scale_factor());
            cr.restore();

            string prompt_host = "dde@linux:", prompt_path = "~/Theme";

            Draw.set_context_source_color(cr, prompt_color_host);
            Draw.draw_text(cr, prompt_host, title_padding_x, title_padding_y, rect.width, rect.height, title_font_size, Pango.Alignment.LEFT, "top");
            int prompt_host_width = Draw.get_text_render_width(cr, prompt_host, clip_width, clip_height, title_font_size);

            Draw.set_context_source_color(cr, prompt_color_path);
            Draw.draw_text(cr, prompt_path, title_padding_x + prompt_host_width, title_padding_y, rect.width, rect.height, title_font_size, Pango.Alignment.LEFT, "top");
            int prompt_host_n_path_width = Draw.get_text_render_width(cr, prompt_path, clip_width, clip_height, title_font_size) + prompt_host_width;

            Draw.set_context_source_color(cr, foreground_color);
            Draw.draw_text(cr, "$ _", title_padding_x + prompt_host_n_path_width, title_padding_y, rect.width, rect.height, title_font_size, Pango.Alignment.LEFT, "top");

            Draw.set_context_source_color(cr, foreground_color);
            Draw.draw_text(cr, theme_name, content_padding_x, content_padding_y, rect.width, rect.height, content_font_size, Pango.Alignment.LEFT, "top");

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

    public class ThemeList : Gtk.VBox {
        public int theme_button_padding = Constant.THEME_BUTTON_PADDING;
        public HashMap<string, ThemeButton> theme_button_map;
        public ThemeButton? active_theme_button = null;

        public signal void active_theme(string theme_name);

        public ThemeList(string default_theme) {
            theme_button_map = new HashMap<string, ThemeButton>();

            var theme_names = Utils.list_files(Utils.get_theme_dir());
            var additional_theme_names = Utils.list_files(Utils.get_additional_theme_dir());
            theme_names.add_all(additional_theme_names);
            theme_names.sort((CompareDataFunc) compare_color_brightness);
            foreach (string theme_name in theme_names) {
                var button = new Widgets.ThemeButton(theme_name);
                pack_start(button, false, false, theme_button_padding);

                button.button_press_event.connect((w, e) => {
                        if (Utils.is_left_button(e)) {
                            active_button(theme_name);
                            active_theme(theme_name);
                        }

                        return false;
                    });

                theme_button_map.set(theme_name, button);
            }

            active_button(default_theme);
        }

        public static int compare_color_brightness(string a, string b) {
            try {
                var a_theme_file = new KeyFile();
                a_theme_file.load_from_file(Utils.get_theme_path((string) a), KeyFileFlags.NONE);
                var a_background_color = Utils.get_color_brightness(a_theme_file.get_string("theme", "background").strip());

                var b_theme_file = new KeyFile();
                b_theme_file.load_from_file(Utils.get_theme_path((string) b), KeyFileFlags.NONE);
                var b_background_color = Utils.get_color_brightness(b_theme_file.get_string("theme", "background").strip());

                if (a_background_color > b_background_color) {
                    return 1;
                }

                if (a_background_color == b_background_color) {
                    return 0;
                }
            } catch (Error e) {
                print("compare_color_brightness: %s\n", e.message);
            }

            return -1;
        }

        public void active_button(string theme_name) {
            if (active_theme_button != null) {
                active_theme_button.inactive();
            }

            if (theme_button_map.has_key(theme_name)) {
                active_theme_button = theme_button_map.get(theme_name);
            } else {
                active_theme_button = theme_button_map.get("deepin");
            }
            active_theme_button.active();
        }
    }
}
