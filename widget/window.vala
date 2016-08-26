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

using Cairo;
using Config;
using Gtk;
using Wnck;
using XUtils;

namespace Widgets {
    public class Window : Widgets.ConfigWindow {
        public Gdk.RGBA top_line_dark_color;
        public Gdk.RGBA top_line_light_color;
        public Gtk.Box fullscreen_box;
        public Gtk.Box spacing_box;
        public bool draw_tabbar_line = true;
        public int window_frame_margin_bottom = 60;
        public int window_frame_margin_end = 50;
        public int window_frame_margin_start = 50;
        public int window_frame_margin_top = 50;
        public int window_fullscreen_monitor_height = Constant.TITLEBAR_HEIGHT * 2;
        public int window_fullscreen_monitor_timeout = 150;
        public int window_fullscreen_response_height = 5;
        public int window_height;
        public int window_widget_margin_bottom = 2;
        public int window_widget_margin_end = 2;
        public int window_widget_margin_start = 2;
        public int window_widget_margin_top = 1;
        public int window_width;
        
        public Window() {
            transparent_window();
            init_window();
            
            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
            
            Gdk.Geometry geo = Gdk.Geometry();
            geo.min_width = rect.width / 3;
            geo.min_height = rect.height / 3;
            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE);
            
            top_line_dark_color = Utils.hex_to_rgba("#000000", 0.2);
            top_line_light_color = Utils.hex_to_rgba("#ffffff", 0.2);
            
            window_frame_box.margin_top = window_frame_margin_top;
            window_frame_box.margin_bottom = window_frame_margin_bottom;
            window_frame_box.margin_start = window_frame_margin_start;
            window_frame_box.margin_end = window_frame_margin_end;
            
            window_widget_box.margin_top = 2;
            window_widget_box.margin_bottom = 2;
            window_widget_box.margin_start = 2;
            window_widget_box.margin_end = 2;
                        
            try {
                var window_state = config.config_file.get_value("advanced", "window_state");
                var width = config.config_file.get_integer("advanced", "window_width");
                var height = config.config_file.get_integer("advanced", "window_height");
                if (width == 0 || height == 0) {
                    set_default_size(
                        rect.width / 2 + window_frame_margin_start + window_frame_margin_end,
                        rect.height / 2 + window_frame_margin_top + window_frame_margin_bottom);
                } else {
                    set_default_size(width, height);
                }
					
                    
                if (window_state == "maximize") {
                    maximize();
                } else if (window_state == "fullscreen") {
                    toggle_fullscreen();
                }
            } catch (GLib.KeyFileError e) {
                stdout.printf(e.message);
            }
            try{
                set_icon_from_file(Utils.get_image_path("deepin-terminal.svg"));
            } catch(Error er) {
                stdout.printf(er.message);
            }
        }
		
        public void transparent_window() {
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());
        }
        
        public void init_window() {
            set_decorated(false);
            
            window_frame_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            window_widget_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            add(window_frame_box);
            window_frame_box.pack_start(window_widget_box, true, true, 0);
            
            focus_in_event.connect((w) => {
                    update_style();
                    
                    return false;
                });
            
            focus_out_event.connect((w) => {
                    update_style();
                    
                    return false;
                });
            
            configure_event.connect((w) => {
                    int width, height;
                    get_size(out width, out height);
                    
                    Cairo.RectangleInt rect;
                    get_window().get_frame_extents(out rect);
                    
                    if (window_is_max() || window_is_fullscreen()) {
                        rect.x = 0;
                        rect.y = 0;
                        rect.width = width;
                        rect.height = height;
                    } else if (window_is_tiled()) {
                        int monitor = screen.get_monitor_at_window(screen.get_active_window());
                        Gdk.Rectangle screen_rect;
                        screen.get_monitor_geometry(monitor, out screen_rect);

                        if (rect.x + rect.width - window_frame_margin_start == screen_rect.width) {
                            rect.x = window_frame_margin_start;
                            rect.y = 0;
                            rect.width = width - window_frame_margin_start;
                            rect.height = height;
                        } else {
                            rect.x = 0;
                            rect.y = 0;
                            rect.width = width - window_frame_margin_end;
                            rect.height = height;
                        }
                    } else {
                        rect.x = window_frame_margin_start - Constant.RESPONSE_RADIUS;
                        rect.y = window_frame_margin_top - Constant.RESPONSE_RADIUS;
                        rect.width = width - window_frame_margin_start - window_frame_margin_end + Constant.RESPONSE_RADIUS * 2;
                        rect.height = height - window_frame_margin_top - window_frame_margin_bottom + Constant.RESPONSE_RADIUS * 2;
                    }
                    
                    var shape = new Cairo.Region.rectangle(rect);
                    get_window().input_shape_combine_region(shape, 0, 0);
                    
                    return false;
                });
            
            window_state_event.connect((w, e) => {
                    update_style();
                    
                    if (window_is_fullscreen() || window_is_max()) {
                        get_window().set_shadow_width(0, 0, 0, 0);
                                
                        window_frame_box.margin = 0;
                        
                        window_widget_box.margin_top = 1;
                        window_widget_box.margin_bottom = 0;
                        window_widget_box.margin_start = 0;
                        window_widget_box.margin_end = 0;
                    } else if (window_is_tiled()) {
                        Cairo.RectangleInt rect;
                        get_window().get_frame_extents(out rect);
                        
                        int monitor = screen.get_monitor_at_window(screen.get_active_window());
                        Gdk.Rectangle screen_rect;
                        screen.get_monitor_geometry(monitor, out screen_rect);
                        
                        int width, height;
                        get_size(out width, out height);

                        if (rect.x + rect.width - window_frame_margin_start == screen_rect.width) {
                            get_window().set_shadow_width(window_frame_margin_start, 0, 0, 0);
                            
                            window_frame_box.margin_left = window_frame_margin_start;
                            window_frame_box.margin_right = 0;
                            window_frame_box.margin_top = 0;
                            window_frame_box.margin_bottom = 0;
                        } else {
                            get_window().set_shadow_width(0, window_frame_margin_end, 0, 0);
                            
                            window_frame_box.margin_left = 0;
                            window_frame_box.margin_right = window_frame_margin_end;
                            window_frame_box.margin_top = 0;
                            window_frame_box.margin_bottom = 0;
                        }
                        
                        window_widget_box.margin_top = 1;
                        window_widget_box.margin_bottom = 1;
                        window_widget_box.margin_start = 1;
                        window_widget_box.margin_end = 1;
                    } else {
                        get_window().set_shadow_width(window_frame_margin_start, window_frame_margin_end, window_frame_margin_top, window_frame_margin_bottom);
                                
                        window_frame_box.margin_top = window_frame_margin_top;
                        window_frame_box.margin_bottom = window_frame_margin_bottom;
                        window_frame_box.margin_start = window_frame_margin_start;
                        window_frame_box.margin_end = window_frame_margin_end;
            
                        window_widget_box.margin_top = 2;
                        window_widget_box.margin_bottom = 2;
                        window_widget_box.margin_start = 2;
                        window_widget_box.margin_end = 2;
                    }
                    
                    return false;
                });
            
            button_press_event.connect((w, e) => {
                    if (window_is_normal()) {
                        int pointer_x, pointer_y;
                        e.device.get_position(null, out pointer_x, out pointer_y);
                            
                        var cursor_type = get_cursor_type(e.x_root, e.y_root);
                        if (cursor_type != null) {
                            resize_window(this, pointer_x, pointer_y, (int) e.button, cursor_type);
                        }
                    }
                    
                    return false;
                });
            
            leave_notify_event.connect((w, e) => {
                    if (window_is_normal()) {
                        GLib.Timeout.add(100, () => {
                                Gdk.Display gdk_display = Gdk.Display.get_default();
                                var seat = gdk_display.get_default_seat();
                                var device = seat.get_pointer();
                    
                                int pointer_x, pointer_y;
                                device.get_position(null, out pointer_x, out pointer_y);
                                var cursor_type = get_cursor_type(pointer_x, pointer_y);
                                if (cursor_type != null) {
                                    get_window().set_cursor(new Gdk.Cursor.for_display(Gdk.Display.get_default(), cursor_type));
                                } else {
                                    get_window().set_cursor(null);
                                }
                                
                                return focus_window;
                            });
                    }
                    
                    return false;
                });
            
            draw.connect_after((w, cr) => {
                    draw_window_below(cr);
                       
                    draw_window_widgets(cr);

                    draw_window_frame(cr);
                       
                    draw_window_above(cr);
                    
                    return true;
                });
            
            config.update.connect((w) => {
                    update_style();
                });
        }
        
        public void update_style() {
            clean_style();
            
            bool is_light_theme = is_light_theme();
            
            if (is_active) {
                if (window_is_normal()) {
                    if (is_light_theme) {
                        window_frame_box.get_style_context().add_class("window_light_shadow_active");
                    } else {
                        window_frame_box.get_style_context().add_class("window_dark_shadow_active");
                    }
                } else {
                    window_frame_box.get_style_context().add_class("window_noradius_shadow_active");
                }
            } else {
                if (window_is_normal()) {
                    if (is_light_theme) {
                        window_frame_box.get_style_context().add_class("window_light_shadow_inactive");
                    } else {
                        window_frame_box.get_style_context().add_class("window_dark_shadow_inactive");
                    }
                } else {
                    window_frame_box.get_style_context().add_class("window_noradius_shadow_inactive");
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
        
        public void add_widget(Gtk.Widget widget) {
            window_widget_box.pack_start(widget, true, true, 0);
        }

        public bool have_terminal_at_same_workspace() {
            var screen = Wnck.Screen.get_default();
            screen.force_update();
        
            var active_workspace = screen.get_active_workspace();
            foreach (Wnck.Window window in screen.get_windows()) {
                var workspace = window.get_workspace();
                if (workspace.get_number() == active_workspace.get_number()) {
                    if (window.get_name() == "deepin-terminal") {
                        return true;
                    }
                }
            }
        
            return false;
        }
    
		public override void toggle_fullscreen() {
            if (window_is_fullscreen()) {
                unfullscreen();
            } else {
                fullscreen();
            }
        }
        
        public void toggle_max() {
            if (window_is_max()) {
                unmaximize();
            } else {
                maximize();
            }
        }
        
        public virtual void draw_window_below(Cairo.Context cr) {
            
        }
        
        public bool window_is_max() {
            return Gdk.WindowState.MAXIMIZED in get_window().get_state();
        }
        
        public bool window_is_tiled() {
            return Gdk.WindowState.TILED in get_window().get_state();
        }
        
        public bool window_is_fullscreen() {
            return Gdk.WindowState.FULLSCREEN in get_window().get_state();
        }
        
        public bool window_is_normal() {
            return !window_is_max() && !window_is_fullscreen() && !window_is_tiled();
        }
        
        public void draw_window_frame(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;
            Gdk.RGBA frame_color;
            
            try {
                if (window_is_normal()) {
                    frame_color = Utils.hex_to_rgba(config.config_file.get_string("theme", "background"));
                    
                    // Draw line *innner* of window frame.
                    cr.save();
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity"));
                    // Bottom.
                    Draw.draw_rectangle(cr, x + 3, y + height - 2, width - 6, 1);
                    // Left.
                    Draw.draw_rectangle(cr, x + 1, y + Constant.TITLEBAR_HEIGHT + 2, 1, height - 45);
                    // Rigt..
                    Draw.draw_rectangle(cr, x + width - 2, y + Constant.TITLEBAR_HEIGHT + 2, 1, height - 45);
                    cr.restore();
                }
            } catch (Error e) {
                print("Window draw_window_frame: %s\n", e.message);
            }
        }

        public void draw_window_above(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
            
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            Gdk.RGBA frame_color = Gdk.RGBA();
            Gdk.RGBA active_tab_color = Gdk.RGBA();
            
            bool is_light_theme = is_light_theme();
            
            try {
                frame_color = Utils.hex_to_rgba(config.config_file.get_string("theme", "background"));
                active_tab_color = Utils.hex_to_rgba(config.config_file.get_string("theme", "tab"));
            } catch (GLib.KeyFileError e) {
                print("Window draw_window_above: %s\n", e.message);
            }
            
            try {
                if (window_is_fullscreen()) {
                    if (draw_tabbar_line) {
                        draw_titlebar_underline(cr, x, y, width, 1);
                        draw_active_tab_underline(cr, x + active_tab_underline_x - window_frame_box.margin_start, y + Constant.TITLEBAR_HEIGHT);
                    }
                } else if (window_is_max() || window_is_tiled()) {
                    draw_titlebar_underline(cr, x + 1, y, width - 2, 1);
                    draw_active_tab_underline(cr, x + active_tab_underline_x - window_frame_box.margin_start, y + Constant.TITLEBAR_HEIGHT + 1);
                } else {
                    // Draw line above at titlebar.
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity"));
                    Draw.draw_rectangle(cr, x + 3, y + 1, width - 6, 1);

                    if (is_light_theme) {
                        Utils.set_context_color(cr, top_line_light_color);
                    } else {
                        Utils.set_context_color(cr, top_line_dark_color);
                    }
                    Draw.draw_rectangle(cr, x + 3, y + 1, width - 6, 1);
                
                    cr.set_source_rgba(1, 1, 1, 0.0625 * config.config_file.get_double("general", "opacity")); // Draw top line at window.
                    Draw.draw_rectangle(cr, x + 3, y + 1, width - 6, 1);
                    
                    // Draw line around titlebar side.
                    cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, config.config_file.get_double("general", "opacity"));
                    // Left.
                    Draw.draw_rectangle(cr, x + 1, y + 3, 1, Constant.TITLEBAR_HEIGHT - 1);
                    // Right.
                    Draw.draw_rectangle(cr, x + width - 2, y + 3, 1, Constant.TITLEBAR_HEIGHT - 1);
                
                    if (is_light_theme) {
                        Utils.set_context_color(cr, top_line_light_color);
                    } else {
                        Utils.set_context_color(cr, top_line_dark_color);
                    }
                    // Left.
                    Draw.draw_rectangle(cr, x + 1, y + 3, 1, Constant.TITLEBAR_HEIGHT - 1);
                    // Right.
                    Draw.draw_rectangle(cr, x + width - 2, y + 3, 1, Constant.TITLEBAR_HEIGHT - 1);
                
                    draw_titlebar_underline(cr, x + 1, y, width - 2, 1);
                    draw_active_tab_underline(cr, x + active_tab_underline_x - window_frame_box.margin_start, y + Constant.TITLEBAR_HEIGHT);
                }
            } catch (Error e) {
                print("Window draw_window_above: %s\n", e.message);
            }
        }

        public void init_fullscreen_handler(Appbar appbar) {
            fullscreen_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            spacing_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            
            spacing_box.set_size_request(-1, Constant.TITLEBAR_HEIGHT);
            fullscreen_box.pack_start(spacing_box, false, false, 0);
            
            configure_event.connect((w) => {
                    if (window_is_fullscreen()) {
                        Utils.remove_all_children(fullscreen_box);
                        appbar.hide();
                        appbar.hide_window_button();
                        draw_tabbar_line = false;
                    } else {
                        Gtk.Widget? parent = spacing_box.get_parent();
                        if (parent == null) {
                            fullscreen_box.pack_start(spacing_box, false, false, 0);
                            appbar.show_all();
                            appbar.show_window_button();
                            draw_tabbar_line = true;
                        }
                    }
                        
                    return false;
                });
                
            motion_notify_event.connect((w, e) => {
                    if (window_is_fullscreen()) {
                        if (e.y_root < window_fullscreen_monitor_height) {
                            GLib.Timeout.add(window_fullscreen_monitor_timeout, () => {
                                    Gdk.Display gdk_display = Gdk.Display.get_default();
                                    var seat = gdk_display.get_default_seat();
                                    var device = seat.get_pointer();
                    
                                    int pointer_x, pointer_y;
                                    device.get_position(null, out pointer_x, out pointer_y);

                                    if (pointer_y < window_fullscreen_response_height) {
                                        appbar.show_all();
                                        draw_tabbar_line = true;
                                
                                        redraw_window();
                                    } else if (pointer_y > Constant.TITLEBAR_HEIGHT) {
                                        appbar.hide();
                                        draw_tabbar_line = false;                                
                                
                                        redraw_window();
                                    }
                                        
                                    return false;
                                });
                        }
                    }
                        
                    return false;
                });
        }

        public void show_window(WorkspaceManager workspace_manager, Tabbar tabbar) {
            Appbar appbar = new Appbar(this, tabbar, workspace_manager);
                
            appbar.set_valign(Gtk.Align.START);
            appbar.close_window.connect((w) => {
                    quit();
                });
            appbar.quit_fullscreen.connect((w) => {
                    toggle_fullscreen();
                });
            
            init(workspace_manager, tabbar);
            init_fullscreen_handler(appbar);
                
            window_state_event.connect((w) => {
                    appbar.update_max_button();
                    
                    return false;
                });
                
            if (!have_terminal_at_same_workspace()) {
                set_position(Gtk.WindowPosition.CENTER);
            }
                
            var overlay = new Gtk.Overlay();
            top_box.pack_start(fullscreen_box, false, false, 0);
            box.pack_start(top_box, false, false, 0);
            box.pack_start(workspace_manager, true, true, 0);
                
            overlay.add(box);
            overlay.add_overlay(appbar);
			
            add_widget(overlay);
            show_all();
        }
        
        public override void window_save_before_quit() {
            int width, height;
            get_size(out width, out height);
                    
            if (window_is_normal()) {
                config.config_file.set_integer("advanced", "window_width", width);
                config.config_file.set_integer("advanced", "window_height", height);
                config.save();
            }
        }
        
        public Gdk.CursorType? get_cursor_type(double x, double y) {
            int window_x, window_y;
            get_window().get_origin(out window_x, out window_y);
                        
            int width, height;
            get_size(out width, out height);
            
            print("** %f %f %f %f %i %i\n", x, y, window_x, window_y, width, height);
            
            var left_side_start = window_x + window_frame_margin_start - Constant.RESPONSE_RADIUS;
            var left_side_end = window_x + window_frame_margin_start;
            var right_side_start = window_x + width - window_frame_margin_end;
            var right_side_end = window_x + width - window_frame_margin_end + Constant.RESPONSE_RADIUS;
            var top_side_start = window_y + window_frame_margin_top - Constant.RESPONSE_RADIUS;;
            var top_side_end = window_y + window_frame_margin_top;
            var bottom_side_start = window_y + height - window_frame_margin_bottom;
            var bottom_side_end = window_y + height - window_frame_margin_bottom + Constant.RESPONSE_RADIUS;
            
            print("**** %s %s\n", 
                  (x > left_side_start && x < left_side_end).to_string(),
                  (y > top_side_end && y < bottom_side_start).to_string()
                  );
                            
            if (x > left_side_start && x < left_side_end) {
                if (y > top_side_start && y < top_side_end) {
                    return Gdk.CursorType.TOP_LEFT_CORNER;
                } else if (y > bottom_side_start && y < bottom_side_end) {
                    return Gdk.CursorType.BOTTOM_LEFT_CORNER;
                }
            } else if (x > right_side_start && x < right_side_end) {
                if (y > top_side_start && y < top_side_end) {
                    return Gdk.CursorType.TOP_RIGHT_CORNER;
                } else if (y > bottom_side_start && y < bottom_side_end) {
                    return Gdk.CursorType.BOTTOM_RIGHT_CORNER;
                }
            }

            if (x > left_side_start && x < left_side_end) {
                if (y > top_side_end && y < bottom_side_start) {
                    return Gdk.CursorType.LEFT_SIDE;
                }
            } else if (x > right_side_start && x < right_side_end) {
                if (y > top_side_end && y < bottom_side_start) {
                    return Gdk.CursorType.RIGHT_SIDE;
                }
            } else {
                if (y > top_side_start && y < top_side_end) {
                    return Gdk.CursorType.TOP_SIDE;
                } else if (y > bottom_side_start && y < bottom_side_end) {
                    return Gdk.CursorType.BOTTOM_SIDE;
                }
            }
            
            return null;
        }
    }
}