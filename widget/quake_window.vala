/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2016 Deepin, Inc.
 *               2011 ~ 2016 Wang Yong
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
            
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());

            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            set_decorated(false);
            set_keep_above(true);
            
            realize.connect((w) => {
                    get_window().set_shadow_width(0, 0, 0, window_frame_margin_bottom);

                    try {
                        var config_height = config.config_file.get_double("advanced", "quake_window_height");
                        if (config_height == 0) {
                            set_default_size(rect.width, (int) (rect.height * window_default_height_scale));
                        } else {
                            set_default_size(rect.width, (int) (rect.height * double.min(config_height, 1.0)));
                        }
                
                        if (config_height > window_max_height_scale) {
                            Gdk.Geometry geo = Gdk.Geometry();
                            geo.min_width = rect.width;
                            geo.min_height = (int) (rect.height * window_default_height_scale);
                            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE);            
                    
                            if (config_height >= 1.0) {
                                maximize();
                            }
                        } else {
                            Gdk.Geometry geo = Gdk.Geometry();
                            geo.min_width = rect.width;
                            geo.min_height = (int) (rect.height * window_default_height_scale);
                            geo.max_width = rect.width;
                            geo.max_height = (int) (rect.height * window_max_height_scale);
                            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);            
                        }
                    } catch (Error e) {
                        print("QuakeWindow init: %s\n", e.message);
                    }
                });
            
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            // NOTE: Don't change other type, otherwise window can't resize by user.
            set_type_hint(Gdk.WindowTypeHint.MENU);
            move(rect.x, 0);
            
            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_frame_box.margin_bottom = window_frame_margin_bottom;
            window_widget_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            add(window_frame_box);
            window_frame_box.pack_start(window_widget_box, true, true, 0);

            focus_in_event.connect((w) => {
                    update_style();
                    
                    return false;
                });
            
            focus_out_event.connect((w) => {
                    update_style();
                    
                    try {
                        if (config.config_file.get_boolean("advanced", "hide_quakewindow_after_lost_focus")) {
                            hide();
                        }
                    } catch (Error e) {
                        print("quake_window focus_out_event: %s\n", e.message);
                    }
                    
                    return false;
                });
            
            configure_event.connect((w) => {
                    int width, height;
                    get_size(out width, out height);

                    Cairo.RectangleInt input_shape_rect;
                    get_window().get_frame_extents(out input_shape_rect);
                    
                    input_shape_rect.x = 0;
                    input_shape_rect.y = 0;
                    input_shape_rect.width = width;
                    input_shape_rect.height = height - window_frame_margin_bottom + Constant.RESPONSE_RADIUS;
                    
                    var shape = new Cairo.Region.rectangle(input_shape_rect);
                    get_window().input_shape_combine_region(shape, 0, 0);
                    
                    window_save_before_quit();
                    
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
                });
        }
        
        public void add_widget(Gtk.Widget widget) {
            window_widget_box.pack_start(widget, true, true, 0);
        }
        
        public void toggle_quake_window() {
            Gdk.Screen screen = Gdk.Screen.get_default();
            int active_monitor = screen.get_monitor_at_window(screen.get_active_window());
            int window_monitor = screen.get_monitor_at_window(get_window());
            
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(active_monitor, out rect);
                
            if (active_monitor == window_monitor) {
                var window_state = get_window().get_state();
                if (Gdk.WindowState.WITHDRAWN in window_state) {
                    show_all();
                    present();
                    move(rect.x, 0);
                } else {
                    // Because some desktop environment, such as DDE will grab keyboard focus when press keystroke. :(
                    // So i add 200ms timeout to wait desktop environment release keyboard focus and then get window active state.
                    // Otherwise, window is always un-active state that quake terminal can't toggle to hide.
                    GLib.Timeout.add(200, () => {
                            if (is_active) {
                                hide();
                            } else {
                                present();
                            }
                        
                        return false;
                        });
                }
            } else {
                show_all();
                present();
                move(rect.x, 0);
            }
        }
        
        public void update_style() {
            clean_style();
            
            bool is_light_theme = is_light_theme();
            
            if (is_active) {
                if (is_light_theme) {
                    window_frame_box.get_style_context().add_class("window_light_shadow_active");
                } else {
                    window_frame_box.get_style_context().add_class("window_dark_shadow_active");
                }
            } else {
                if (is_light_theme) {
                    window_frame_box.get_style_context().add_class("window_light_shadow_inactive");
                } else {
                    window_frame_box.get_style_context().add_class("window_dark_shadow_inactive");
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
            
            draw_titlebar_underline(cr, x, y + height - Constant.TITLEBAR_HEIGHT - 1, width, -1);
            draw_active_tab_underline(cr, x + active_tab_underline_x, y + height - Constant.TITLEBAR_HEIGHT - 1);
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
            box.pack_start(top_box, false, false, 0);
                
            add_widget(box);
            show_all();
        }
        
        public override void window_save_before_quit() {
            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            int width, height;
            get_size(out width, out height);
                    
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
    }
}