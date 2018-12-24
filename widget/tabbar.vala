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
using GLib;
using Gee;
using Gtk;
using Utils;
using Widgets;

namespace Widgets {
    public class Tabbar : Gtk.DrawingArea {
        public Gdk.RGBA tab_split_dark_color;
        public Gdk.RGBA tab_split_light_color;
        public HashMap<int, bool> tab_highlight_map;
        private Cairo.ImageSurface add_hover_dark_surface;
        private Cairo.ImageSurface add_hover_light_surface;
        private Cairo.ImageSurface add_normal_dark_surface;
        private Cairo.ImageSurface add_normal_light_surface;
        private Cairo.ImageSurface add_press_dark_surface;
        private Cairo.ImageSurface add_press_light_surface;
        private Cairo.ImageSurface close_hover_surface;
        private Cairo.ImageSurface close_normal_surface;
        private Cairo.ImageSurface close_press_surface;
        private bool draw_hover = false;
        private bool is_button_press = false;
        private double draw_scale = 1.0;
        private int add_button_width = 50;
        private int button_press_x = 0;
        private int button_press_y = 0;
        private int close_button_padding_x = 28;
        private int hover_x = 0;
        private int tab_min_width = 80;
        private int tab_split_width = 1;
        private int text_padding_x = 20;
        public ArrayList<int> tab_list;
        public Gdk.RGBA hover_arrow_color;
        public Gdk.RGBA inactive_arrow_color;
        public Gdk.RGBA tab_text_color;
        public Gdk.RGBA text_active_color;
        public Gdk.RGBA text_dark_color;
        public Gdk.RGBA text_highlight_color;
        public Gdk.RGBA text_hover_dark_color;
        public Gdk.RGBA text_hover_light_color;
        public Gdk.RGBA text_light_color;
        public HashMap<int, string> tab_name_map;
        public Pango.FontDescription font_description;
        public bool allowed_add_tab = true;
        public int font_size = 11;
        public int height = Constant.TITLEBAR_HEIGHT;
        public int hover_clip_right_offset = 6;
        public int min_tab_width = 70;
        public int tab_index = 0;

        public signal void press_tab(int tab_index, int tab_id);
        public signal void update_tab_underline(int x, int width);
        public signal void close_tab(int tab_index, int tab_id);
        public signal void new_tab();

        public Tabbar() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
            tab_highlight_map = new HashMap<int, bool>();

            font_description = new Pango.FontDescription();
            font_description.set_size((int)(font_size * Pango.SCALE));

            set_size_request(-1, height);

            close_normal_surface = Utils.create_image_surface("tab_close_normal.svg");
            close_hover_surface = Utils.create_image_surface("tab_close_hover.svg");
            close_press_surface = Utils.create_image_surface("tab_close_press.svg");

            add_normal_dark_surface = Utils.create_image_surface("tab_add_dark_normal.svg");
            add_hover_dark_surface = Utils.create_image_surface("tab_add_dark_hover.svg");
            add_press_dark_surface = Utils.create_image_surface("tab_add_dark_press.svg");
            add_normal_light_surface = Utils.create_image_surface("tab_add_light_normal.svg");
            add_hover_light_surface = Utils.create_image_surface("tab_add_light_hover.svg");
            add_press_light_surface = Utils.create_image_surface("tab_add_light_press.svg");

            inactive_arrow_color = Utils.hex_to_rgba("#393937");
            hover_arrow_color = Utils.hex_to_rgba("#494943");
            text_hover_dark_color = Utils.hex_to_rgba("#ffffff");
            text_hover_light_color = Utils.hex_to_rgba("#000000");
            text_dark_color = Utils.hex_to_rgba("#ffffff", 0.8);
            text_light_color = Utils.hex_to_rgba("#000000", 0.8);
            text_highlight_color = Utils.hex_to_rgba("#ff9600");
            tab_split_dark_color = Utils.hex_to_rgba("#ffffff", 0.05);
            tab_split_light_color = Utils.hex_to_rgba("#000000", 0.05);
            text_active_color = Gdk.RGBA();
            tab_text_color = Gdk.RGBA();

            draw.connect(on_draw);
            configure_event.connect(on_configure);
            button_press_event.connect(on_button_press);
            button_release_event.connect(on_button_release);
            motion_notify_event.connect(on_motion_notify);
            leave_notify_event.connect(on_leave_notify);
        }

        public void init(WorkspaceManager workspace_manager, Widgets.ConfigWindow window) {
            press_tab.connect((t, tab_index, tab_id) => {
                    unhighlight_tab(tab_id);
                    workspace_manager.switch_workspace(tab_id);
                });

            close_tab.connect((t, tab_index, tab_id) => {
                    Widgets.Workspace focus_workspace = workspace_manager.workspace_map.get(tab_id);
                    if (focus_workspace.has_active_term()) {
                        ConfirmDialog dialog;
                        dialog = Widgets.create_running_confirm_dialog(window);

                        dialog.confirm.connect((d) => {
                                destroy_tab(tab_index);
                                workspace_manager.remove_workspace(tab_id);
                            });
                    } else {
                        destroy_tab(tab_index);
                        workspace_manager.remove_workspace(tab_id);
                    }
                });

            new_tab.connect((t) => {
                    workspace_manager.new_workspace_with_current_directory();
                });
        }

        public void reset() {
            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
            tab_index = 0;
        }

        public void add_tab(string tab_name, int tab_id) {
            tab_list.add(tab_id);
            tab_name_map.set(tab_id, tab_name);

            update_tab_scale();

            queue_draw();
        }

        public void rename_tab(int tab_id, string tab_name) {
            tab_name_map.set(tab_id, tab_name);

            if (is_focus_tab(tab_id)) {
                update_window_title(tab_name);
            }

            update_tab_scale();

            queue_draw();
        }

        public void highlight_tab(int tab_id) {
            if (!tab_highlight_map.has_key(tab_id)) {
                tab_highlight_map.set(tab_id, true);

                queue_draw();
            }
        }

        public void unhighlight_tab(int tab_id) {
            if (tab_highlight_map.has_key(tab_id)) {
                tab_highlight_map.unset(tab_id);

                queue_draw();
            }
        }

        public bool is_focus_tab(int tab_id) {
            int? index = tab_list.index_of(tab_id);
            if (index != null) {
                return tab_index == index;
            } else {
                return false;
            }
        }

        public void select_next_tab() {
            var index = tab_index + 1;
            if (index >= tab_list.size) {
                index = 0;
            }
            switch_tab(index);
        }

        public void select_previous_tab() {
            var index = tab_index - 1;
            if (index < 0) {
                index = tab_list.size - 1;
            }
            switch_tab(index);
        }

        public void select_first_tab() {
            switch_tab(0);
        }

        public void select_end_tab() {
            var index = 0;
            if (tab_list.size == 0) {
                index = 0;
            } else {
                index = tab_list.size - 1;
            }
            switch_tab(index);
        }

        public void select_nth_tab(int index) {
            switch_tab(index);
        }

        public void select_tab_with_id(int tab_id) {
            switch_tab(tab_list.index_of(tab_id));
        }

        public void close_current_tab() {
            close_nth_tab(tab_index);
        }

        public void close_nth_tab(int index) {
            if (tab_list.size > 0) {
                var tab_id = tab_list.get(index);
                close_tab(index, tab_id);
            }
        }

        public void destroy_tab(int index) {
            var tab_id = tab_list.get(index);

            tab_list.remove_at(index);
            tab_name_map.unset(tab_id);

            if (tab_list.size == 0) {
                tab_index = 0;
            } else if (tab_index >= tab_list.size) {
                tab_index = tab_list.size - 1;
            }

            update_tab_scale();

            queue_draw();
        }

        public bool on_configure(Gtk.Widget widget, Gdk.EventConfigure event) {
            update_tab_scale();

            queue_draw();

            return false;
        }

        public bool on_button_press(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = true;

            event.device.get_position(null, out button_press_x, out button_press_y);

            return false;
        }

        public bool on_button_release(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = false;

            if (is_action_mouse_button(event)) {
                int button_release_x, button_release_y;
                event.device.get_position(null, out button_release_x, out button_release_y);

                if (button_release_x == button_press_x && button_release_y == button_press_y) {
                    var release_x = (int)event.x;

                    Gtk.Allocation alloc;
                    widget.get_allocation(out alloc);

                    int draw_x = 0;
                    int counter = 0;
                    foreach (int tab_id in tab_list) {
                        int name_width, name_height;
                        get_text_size(tab_name_map.get(tab_id), out name_width, out name_height);
                        int tab_width = get_tab_width(name_width);

                        if (release_x > draw_x && release_x < draw_x + tab_width) {
                            if (release_x > draw_x && release_x < draw_x + tab_width - get_tab_close_button_padding()) {
                                if(is_left_button(event)) {
                                    select_nth_tab(counter);
    
                                    press_tab(counter, tab_id);
                                    return false;
                                }

                                if(is_mouse_wheel(event)) {
                                    close_nth_tab(counter);
                                    return false;
                                }                                
                            } else if (release_x > draw_x + tab_width - get_tab_close_button_padding()) {
                                close_nth_tab(counter);
                                return false;
                            }
                        }

                        draw_x += tab_width;

                        counter++;
                    }

                    if (release_x > draw_x && release_x < draw_x + add_button_width) {
                        new_tab();
                    }

                    queue_draw();
                }
            }

            return false;
        }

        public int is_at_tab_close_button(int x) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            int draw_x = 0;
            int counter = 0;
            foreach (int tab_id in tab_list) {
                int name_width, name_height;
                get_text_size(tab_name_map.get(tab_id), out name_width, out name_height);
                int tab_width = get_tab_width(name_width);

                if (x > draw_x && x < draw_x + tab_width) {
                    if (x > draw_x + tab_width - get_tab_close_button_padding()) {
                        return counter;
                    }
                }

                draw_x += tab_width;

                counter++;
            }

            return -1;
        }

        public bool on_motion_notify(Gtk.Widget widget, Gdk.EventMotion event) {
            draw_hover = true;
            hover_x = (int) event.x;

            queue_draw();

            return false;
        }

        public bool on_leave_notify(Gtk.Widget widget, Gdk.EventCrossing event) {
            draw_hover = false;
            hover_x = 0;

            queue_draw();

            return false;
        }

        public void update_tab_scale() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            int tab_width = 0;
            foreach (int tab_id in tab_list) {
                int name_width, name_height;
                get_text_size(tab_name_map.get(tab_id), out name_width, out name_height);

                tab_width += get_tab_render_width(name_width);
            }

            if (tab_width + add_button_width > alloc.width) {
                // FIXME: I know 0.97 is magic number, this number avoid add_button render out of area of tabbar.
                // Welcome to fix this.
                draw_scale = (double) alloc.width / (tab_width + add_button_width) * 0.97;
            } else {
                draw_scale = 1.0;
            }
        }

        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();

            // Draw tab splitter.
            int draw_x = 0;
            int counter = 0;
            foreach (int tab_id in tab_list) {
                int name_width, name_height;
                get_text_size(tab_name_map.get(tab_id), out name_width, out name_height);

                int tab_width = get_tab_width(name_width);

                if (is_light_theme) {
                    Utils.set_context_color(cr, tab_split_light_color);
                } else {
                    Utils.set_context_color(cr, tab_split_dark_color);
                }
                if (counter < tab_list.size) {
                    Draw.draw_rectangle(cr, draw_x, 0, tab_split_width, height);
                }

                draw_x += tab_width;

                counter++;
            }

            draw_x = 0;
            counter = 0;
            try {
                text_active_color = Utils.hex_to_rgba(((Widgets.ConfigWindow) this.get_toplevel()).config.config_file.get_string("theme", "tab"));
            } catch (Error e) {
                print("Tabbar draw: %s\n", e.message);
            }

            int max_tab_width = 0;
            int max_tab_height = 0;
            foreach (int tab_id in tab_list) {
                int name_width, name_height;
                var layout = get_text_size(tab_name_map.get(tab_id), out name_width, out name_height);

                int tab_width = get_tab_width(name_width);

                max_tab_height = int.max(max_tab_height, name_height);

                if (tab_highlight_map.has_key(tab_id)) {
                    tab_text_color = text_highlight_color;
                } else {
                    if (is_light_theme) {
                        tab_text_color = text_light_color;
                    } else {
                        tab_text_color = text_dark_color;
                    }
                }

                if (counter == tab_index) {
                    cr.save();
                    clip_rectangle(cr, draw_x, 0, tab_width, height);

                    update_tab_underline(draw_x, tab_width + 1);

                    cr.restore();

                    tab_text_color = text_active_color;
                } else {
                    var is_hover = false;

                    if (draw_hover) {
                        if (hover_x > draw_x && hover_x < draw_x + tab_width) {
                            is_hover = true;
                        }
                    }

                    if (is_hover) {
                        cr.save();
                        clip_rectangle(cr, draw_x, 0, tab_width + 1, height);

                        if (is_light_theme) {
                            Utils.set_context_color(cr, tab_split_light_color);
                        } else {
                            Utils.set_context_color(cr, tab_split_dark_color);
                        }
                        Draw.draw_rectangle(cr, draw_x, 0, tab_width + 1, height);

                        cr.restore();

                        if (is_light_theme) {
                            tab_text_color = text_hover_light_color;
                        } else {
                            tab_text_color = text_hover_dark_color;
                        }
                    } else {
                        cr.set_source_rgba(0, 0, 0, 0);
                        Draw.draw_rectangle(cr, draw_x, 0, tab_width, height);
                    }
                }

                if (draw_hover) {
                    if (hover_x > draw_x && hover_x < draw_x + tab_width) {
                        if (hover_x > draw_x + tab_width - get_tab_close_button_padding()) {
                            if (is_button_press) {
                                Draw.draw_surface(cr, close_press_surface, draw_x + tab_width - get_tab_close_button_padding(), 0, 0, height);
                            } else {
                                Draw.draw_surface(cr, close_hover_surface, draw_x + tab_width - get_tab_close_button_padding(), 0, 0, height);
                            }
                        } else {
                            Draw.draw_surface(cr, close_normal_surface, draw_x + tab_width - get_tab_close_button_padding(), 0, 0, height);
                        }
                    }
                }

                // Draw tab text.
                cr.save();
                clip_rectangle(cr, draw_x + get_tab_text_padding(), 0, tab_width - get_tab_text_padding() * 2, height);

                Utils.set_context_color(cr, tab_text_color);
                var is_hover = false;
                if (draw_hover) {
                    if (hover_x > draw_x && hover_x < draw_x + tab_width) {
                        is_hover = true;
                    }
                }

                int text_render_y = (alloc.height - max_tab_height) / 2;
                if (is_hover) {
                    cr.rectangle(draw_x, text_render_y, tab_width - get_tab_close_button_padding() - hover_clip_right_offset, height);
                    cr.clip();
                }
                Draw.draw_layout(cr, layout, draw_x + get_tab_text_padding(), text_render_y);
                cr.restore();

                draw_x += tab_width;

                max_tab_width = int.max(max_tab_width, tab_width);

                counter++;
            }

            // Don't allowed add tab when scale too small.
            allowed_add_tab = max_tab_width > min_tab_width || draw_scale >= 1.0;

            if (hover_x > draw_x && hover_x < draw_x + add_button_width) {
                if (is_button_press) {
                    if (is_light_theme) {
                        Draw.draw_surface(cr, add_press_light_surface, draw_x, 0, 0, height);
                    } else {
                        Draw.draw_surface(cr, add_press_dark_surface, draw_x, 0, 0, height);
                    }
                } else if (draw_hover) {
                    if (is_light_theme) {
                        Draw.draw_surface(cr, add_hover_light_surface, draw_x, 0, 0, height);
                    } else {
                        Draw.draw_surface(cr, add_hover_dark_surface, draw_x, 0, 0, height);
                    }
                }
            } else {
                if (is_light_theme) {
                    Draw.draw_surface(cr, add_normal_light_surface, draw_x, 0, 0, height);
                } else {
                    Draw.draw_surface(cr, add_normal_dark_surface, draw_x, 0, 0, height);
                }
            }

            return true;
        }

        public int get_tab_render_width(int name_width) {
            return int.max(name_width + get_tab_text_padding() * 2, tab_min_width);
        }

        public int get_tab_width(int name_width) {
            return int.max((int) ((name_width + get_tab_text_padding() * 2) * draw_scale), (int) (tab_min_width * draw_scale));
        }

        public int get_tab_text_padding() {
            return text_padding_x;
        }

        public int get_tab_close_button_padding() {
            return close_button_padding_x;
        }

        public void switch_tab(int new_index) {
            tab_index = new_index;

            press_tab(tab_index, tab_list.get(tab_index));

            queue_draw();
        }

        public Pango.Layout get_text_size(string text, out int width, out int height) {
            var layout = create_pango_layout(text);
            layout.set_font_description(font_description);
            layout.get_pixel_size(out width, out height);

            return layout;
        }

        public void update_window_title(string title) {
            ((Gtk.Window) get_toplevel()).set_title("%s - %s".printf(title, _("Deepin Terminal")));
        }
    }
}
