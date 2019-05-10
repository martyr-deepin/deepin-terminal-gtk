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
using Widgets;
using XUtils;

namespace Widgets {
    public class QuakeWindow : Widgets.ConfigWindow {
        public double window_default_height_scale = 0.3;
        public double window_max_height_scale = 0.7;
        public int press_x;
        public int press_y;
        public int window_frame_margin_bottom = 60;

        public QuakeWindow() {
            quake_mode = true;

            set_app_paintable(true); // set_app_paintable is necessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());

            int monitor = config.get_terminal_monitor();

            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);

            set_decorated(false);
            set_keep_above(true);

            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            // NOTE: Don't change other type, otherwise window can't resize by user.
            set_type_hint(Gdk.WindowTypeHint.MENU);
            move(rect.x, 0);

            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_widget_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            add(window_frame_box);
            window_frame_box.pack_start(window_widget_box, true, true, 0);

            realize.connect((w) => {
                    update_frame();

                    try {
                        var quake_window_fullscreen = config.config_file.get_boolean("advanced", "quake_window_fullscreen");
                        if (quake_window_fullscreen) {
                            fullscreen();
                        } else {
                            // Don't make quake window too height that can't resize quake window from bottom edge.
                            var config_height = config.config_file.get_double("advanced", "quake_window_height");
                            if (config_height > window_max_height_scale) {
                                config_height = window_max_height_scale;
                            }

                            // Set default size.
                            if (config_height == 0) {
                                set_default_size(rect.width, (int) (rect.height * window_default_height_scale));
                            } else {
                                set_default_size(rect.width, (int) (rect.height * double.min(config_height, 1.0)));
                            }
                        }
                    } catch (Error e) {
                        print("QuakeWindow init: %s\n", e.message);
                    }
                });

            focus_in_event.connect((w) => {
                    update_style();

                    return false;
                });

            focus_out_event.connect((w) => {
                    update_style();

                    try {
                        // Hide quake window when lost focus, and config option 'hide_quakewindow_after_lost_focus' must be true, variable 'show_quake_menu' must be fasle.
                        // If variable 'show_quake_menu' is true, lost focus signal is cause by click right menu on quake terminal.
                        if (config.config_file.get_boolean("advanced", "hide_quakewindow_after_lost_focus")) {
                            if (show_quake_menu) {
                                show_quake_menu = false;
                            } else {
                                GLib.Timeout.add(200, () => {
                                        var window_state = get_window().get_state();
                                        // Because some desktop environment, such as DDE will grab keyboard focus when press keystroke. :(
                                        //
                                        // When press quakewindow shortcuts will make code follow order: `focus_out event -> toggle_quake_window'.
                                        // focus_out event will make quakewindow hide immediately, quakewindow will show again when execute toggle_quake_window.
                                        // At last, quakewindow will execute 'hide' and 'show' actions twice, not just simple hide window.
                                        //
                                        // So i add 200ms timeout to wait toggle_quake_window execute,
                                        // focus_out event will hide window if it find window is show state after execute toggle_quake_window.
                                        if (!(Gdk.WindowState.WITHDRAWN in window_state)) {
                                            hide();
                                        }

                                        return false;
                                    });
                                // hide();
                            }
                        }
                    } catch (Error e) {
                        print("quake_window focus_out_event: %s\n", e.message);
                    }

                    return false;
                });

            configure_event.connect((w) => {
                    // Update input shape.
                    int width, height;
                    get_size(out width, out height);

                    Cairo.RectangleInt input_shape_rect;
                    get_window().get_frame_extents(out input_shape_rect);

                    if (screen_monitor.is_composited()) {
                        input_shape_rect.x = 0;
                        input_shape_rect.y = 0;
                        input_shape_rect.width = width;
                        input_shape_rect.height = height - window_frame_box.margin_bottom + Constant.RESPONSE_RADIUS;
                    }

                    var shape = new Cairo.Region.rectangle(input_shape_rect);
                    get_window().input_shape_combine_region(shape, 0, 0);

                    // Update blur area.
                    update_blur_status();

                    window_save_before_quit();

                    return false;
                });

            window_frame_box.button_press_event.connect((w, e) => {
                    if (!screen_monitor.is_composited()) {
                        var cursor_type = get_frame_cursor_type(e.x_root, e.y_root);
                        if (cursor_type != null) {
                            e.device.get_position(null, out press_x, out press_y);

                            GLib.Timeout.add(10, () => {
                                    int pointer_x, pointer_y;
                                    e.device.get_position(null, out pointer_x, out pointer_y);

                                    if (pointer_x != press_x || pointer_y != press_y) {
                                        pointer_x *= get_scale_factor();
                                        pointer_y *= get_scale_factor();
                                        resize_window(this, pointer_x, pointer_y, (int) e.button, Gdk.CursorType.BOTTOM_SIDE);

                                        return false;
                                    } else {
                                        return true;
                                    }
                                });
                        }
                    }

                    return false;
                });

            button_press_event.connect((w, e) => {
                    var cursor_type = get_cursor_type(e.x_root, e.y_root);
                    if (cursor_type != null) {
                        e.device.get_position(null, out press_x, out press_y);

                        GLib.Timeout.add(10, () => {
                                int pointer_x, pointer_y;
                                e.device.get_position(null, out pointer_x, out pointer_y);

                                if (pointer_x != press_x || pointer_y != press_y) {
                                    pointer_x *= get_scale_factor();
                                    pointer_y *= get_scale_factor();
                                    resize_window(this, pointer_x, pointer_y, (int) e.button, Gdk.CursorType.BOTTOM_SIDE);

                                    return false;
                                } else {
                                    return true;
                                }
                            });
                    }

                    return false;
                });

            draw.connect_after((w, cr) => {
                    draw_window_widgets(cr);

                    draw_window_above(cr);

                    return true;
                });

            config.update.connect((w) => {
                    update_style();

                    update_blur_status(true);
                });
        }

        public void update_blur_status(bool force_update=false) {
            try {
                int width, height;
                get_size(out width, out height);

                if (width != resize_cache_width || height != resize_cache_height || force_update) {
                    resize_cache_width = width;
                    resize_cache_height = height;

                    unowned X.Display xdisplay = (get_window().get_display() as Gdk.X11.Display).get_xdisplay();
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    var atom_NET_WM_DEEPIN_BLUR_REGION_ROUNDED = xdisplay.intern_atom("_NET_WM_DEEPIN_BLUR_REGION_ROUNDED", false);

                    var blur_background = config.config_file.get_boolean("advanced", "blur_background");
                    if (blur_background) {
                        Cairo.RectangleInt blur_rect;
                        get_window().get_frame_extents(out blur_rect);

                        if (screen_monitor.is_composited()) {
                            blur_rect.x = 0;
                            blur_rect.y = 0;
                            blur_rect.width = width;
                            blur_rect.height = height - window_frame_box.margin_bottom;
                        }

                        blur_rect.x = (int) (blur_rect.x * Utils.get_default_monitor_scale());
                        blur_rect.y = (int) (blur_rect.y * Utils.get_default_monitor_scale());
                        blur_rect.width = (int) (blur_rect.width * Utils.get_default_monitor_scale());
                        blur_rect.height = (int) (blur_rect.height * Utils.get_default_monitor_scale());

                        ulong[] data = {(ulong) blur_rect.x, (ulong) blur_rect.y, (ulong) blur_rect.width, (ulong) blur_rect.height, 8, 8};
                        xdisplay.change_property(
                            xid,
                            atom_NET_WM_DEEPIN_BLUR_REGION_ROUNDED,
                            X.XA_CARDINAL,
                            32,
                            X.PropMode.Replace,
                            (uchar[])data,
                            ((ulong[]) data).length);
                    } else {
                        ulong[] data = {0, 0, 0, 0, 0, 0};
                        xdisplay.change_property(
                            xid,
                            atom_NET_WM_DEEPIN_BLUR_REGION_ROUNDED,
                            X.XA_CARDINAL,
                            32,
                            X.PropMode.Replace,
                            (uchar[])data,
                            ((ulong[]) data).length);
                    }
                }
            } catch (GLib.KeyFileError e) {
                print("%s\n", e.message);
            }
        }

        public void add_widget(Gtk.Widget widget) {
            window_widget_box.pack_start(widget, true, true, 0);
        }

        public void toggle_quake_window() {
            Gdk.Screen screen = Gdk.Screen.get_default();
            int monitor = config.get_terminal_monitor();
            int window_monitor = screen.get_monitor_at_window(get_window());

            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);

            if (monitor == window_monitor) {
                var window_state = get_window().get_state();
                if (Gdk.WindowState.WITHDRAWN in window_state) {
                    show_quake_window(rect);
                } else {

                    try {
                        // When option hide_quakewindow_after_lost_focus enable.
                        // Focus terminal if terminal is not active, only hide temrinal after terminal focus.
                        if (config.config_file.get_boolean("advanced", "hide_quakewindow_when_active")) {
                            // Because some desktop environment, such as DDE will grab keyboard focus when press keystroke. :(
                            // So i add 200ms timeout to wait desktop environment release keyboard focus and then get window active state.
                            // Otherwise, window is always un-active state that quake terminal can't toggle to hide.
                            GLib.Timeout.add(200, () => {
                                    if (is_active) {
                                        hide();
                                    } else {
                                        // blumia: present(), which send `_NET_ACTIVE_WINDOW` with current time (0) as timestamp,
                                        //         doesn't works under KWin, a correct timestamp form X-server start is required.
                                        //present();
                                        present_with_time(Gdk.X11.get_server_time((Gdk.X11.Window)get_window()));
                                    }

                                    return false;
                                });
                        }
                        // Hide terminal immediately if option hide_quakewindow_when_active is false.
                        else {
                            hide();
                        }
                    } catch (Error e) {
                        print("quake_window toggle_quake_window: %s\n", e.message);
                    }
                }
            } else {
                show_quake_window(rect);
            }
        }

        public void show_quake_window(Gdk.Rectangle rect) {
            // Init.
            int width, height;
            get_size(out width, out height);
            show_all();

            // Resize quake terminal window's width along with monitor's width.
            get_window().move_resize(rect.x, 0, rect.width, height);

            // Present window.
            present();
        }

        public void update_style() {
            clean_style();

            bool is_light_theme = is_light_theme();

            if (is_active) {
                if (is_light_theme) {
                    if (screen_monitor.is_composited()) {
                        window_frame_box.get_style_context().add_class("window_light_shadow_active");
                    } else {
                        window_frame_box.get_style_context().add_class("window_light_noshadow_active");
                    }
                } else {
                    if (screen_monitor.is_composited()) {
                        window_frame_box.get_style_context().add_class("window_dark_shadow_active");
                    } else {
                        window_frame_box.get_style_context().add_class("window_dark_noshadow_active");
                    }
                }
            } else {
                if (is_light_theme) {
                    if (screen_monitor.is_composited()) {
                        window_frame_box.get_style_context().add_class("window_light_shadow_inactive");
                    } else {
                        window_frame_box.get_style_context().add_class("window_light_noshadow_inactive");
                    }
                } else {
                    if (screen_monitor.is_composited()) {
                        window_frame_box.get_style_context().add_class("window_dark_shadow_inactive");
                    } else {
                        window_frame_box.get_style_context().add_class("window_dark_noshadow_inactive");
                    }
                }
            }
        }

        public void clean_style() {
            window_frame_box.get_style_context().remove_class("window_light_shadow_inactive");
            window_frame_box.get_style_context().remove_class("window_dark_shadow_inactive");
            window_frame_box.get_style_context().remove_class("window_light_shadow_active");
            window_frame_box.get_style_context().remove_class("window_dark_shadow_active");
            window_frame_box.get_style_context().remove_class("window_noradius_shadow_inactive");
            window_frame_box.get_style_context().remove_class("window_noradius_shadow_active");
            window_frame_box.get_style_context().remove_class("window_light_noshadow_inactive");
            window_frame_box.get_style_context().remove_class("window_dark_noshadow_inactive");
            window_frame_box.get_style_context().remove_class("window_light_noshadow_active");
            window_frame_box.get_style_context().remove_class("window_dark_noshadow_active");
            window_frame_box.get_style_context().remove_class("window_noradius_noshadow_inactive");
            window_frame_box.get_style_context().remove_class("window_noradius_noshadow_active");
        }

        public void draw_window_widgets(Cairo.Context cr) {
            Utils.propagate_draw(this, cr);
        }

        public void draw_window_above(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);

            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;

            int titlebar_y = y;
            if (get_scale_factor() > 1) {
                titlebar_y += 1;
            }

            draw_titlebar_underline(cr, x, titlebar_y + height - Constant.TITLEBAR_HEIGHT - 1, width, -1);
            draw_active_tab_underline(cr, x + active_tab_underline_x, titlebar_y + height - Constant.TITLEBAR_HEIGHT - 1);
        }

        public void show_window(WorkspaceManager workspace_manager, Tabbar tabbar) {
            Gdk.RGBA background_color = Gdk.RGBA();

            init(workspace_manager, tabbar);
            // First focus terminal after show quake terminal.
            // Sometimes, some popup window (like wine program's popup notify window) will grab focus,
            // so call window.present to make terminal get focus.
            show.connect((t) => {
                    present();
                });

            top_box.draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);

                    try {
                        background_color = Utils.hex_to_rgba(config.config_file.get_string("theme", "background"));
                        cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, config.config_file.get_double("general", "opacity"));
                        Draw.draw_rectangle(cr, 0, 0, rect.width, Constant.TITLEBAR_HEIGHT);
                    } catch (Error e) {
                        print("Main quake mode: %s\n", e.message);
                    }

                    Utils.propagate_draw(top_box, cr);

                    return true;
                });

            top_box.pack_start(tabbar, true, true, 0);
            box.pack_start(workspace_manager, true, true, 0);

            try {
                if (config.config_file.get_boolean("advanced", "show_quakewindow_tab")) {
                    box.pack_start(top_box, false, false, 0);
                }
            } catch (Error e) {
                print("Main quake mode: %s\n", e.message);
            }

            add_widget(box);
            show_all();
        }

        public override void window_save_before_quit() {
            int monitor = config.get_terminal_monitor();
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);

            int width, height;
            get_size(out width, out height);

            config.load_config();
            config.config_file.set_double("advanced", "quake_window_height", height * 1.0 / rect.height);
            config.save();
        }

        public override Gdk.CursorType? get_cursor_type(double x, double y) {
            int window_x, window_y;
            get_window().get_origin(out window_x, out window_y);

            int width, height;
            get_size(out width, out height);

            var bottom_side_start = window_y + height - window_frame_margin_bottom;
            var bottom_side_end = window_y + height - window_frame_margin_bottom + Constant.RESPONSE_RADIUS;;

            if (y > bottom_side_start && y < bottom_side_end) {
                return Gdk.CursorType.BOTTOM_SIDE;
            } else {
                return null;
            }
        }

        public override Gdk.CursorType? get_frame_cursor_type(double x, double y) {
            int window_x, window_y;
            get_window().get_origin(out window_x, out window_y);

            int width, height;
            get_size(out width, out height);

            var bottom_side_start = window_y + height - Constant.RESPONSE_RADIUS;
            var bottom_side_end = window_y + height;

            if (y > bottom_side_start && y < bottom_side_end) {
                return Gdk.CursorType.BOTTOM_SIDE;
            } else {
                return null;
            }
        }

        public override void update_frame() {
            update_style();

            if (screen_monitor.is_composited()) {
                window_frame_box.margin_bottom = window_frame_margin_bottom;
                get_window().set_shadow_width(0, 0, 0, window_frame_margin_bottom);
            } else {
                window_frame_box.margin_bottom = 0;
                get_window().set_shadow_width(0, 0, 0, 0);
            }
        }
    }
}
