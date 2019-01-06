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

[DBus (name = "com.deepin.terminal")]
interface TerminalBus : Object {
    public abstract void exit() throws Error;
    public signal void quit();
}

namespace Widgets {
    public class Appbar : Gtk.Overlay {
        public int height = Constant.TITLEBAR_HEIGHT;
        public Box max_toggle_box;
        public Box window_button_box;
        public Box window_close_button_box;
        public Gtk.Widget? focus_widget;
        public Menu.Menu menu;
        public Tabbar tabbar;
        public Widgets.Window window;
        public Widgets.WindowEventArea event_area;
        public WindowButton close_button;
        public WindowButton max_button;
        public WindowButton menu_button;
        public WindowButton min_button;
        public WindowButton quit_fullscreen_button;
        public WindowButton unmax_button;
        public WorkspaceManager workspace_manager;
        public int logo_width = 48;
        public int titlebar_right_cache_width = 10;
        public int menu_button_width = Constant.WINDOW_BUTTON_WIDHT;

        public signal void close_window();
        public signal void exit_terminal();
        public signal void quit_fullscreen();

        public Appbar(TerminalApp app, Widgets.Window win, Tabbar tab_bar, WorkspaceManager manager, bool has_start) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            window = win;
            workspace_manager = manager;

            set_size_request(-1, height);

            if (has_start) {
                // If has one terminal start,
                // just call *first* temrinal's 'exit' function, then *first* terminal process will broadcast 'quit' signal,
                // all other terminals will quit when catch 'quit' signal that emit from *first* terminal.
                TerminalBus bus = null;
                try {
                    bus = Bus.get_proxy_sync(
                        BusType.SESSION,
                        "com.deepin.terminal",
                        "/com/deepin/terminal");
                    bus.quit.connect(() => {
                            window.quit();
                        });
                    exit_terminal.connect(() => {
                            try {
                                bus.exit();
                            } catch (Error e) {
                                stderr.printf("AppBar bus.ext: %s\n", e.message);
                            }
                        });
                } catch (Error e) {
                    stderr.printf("AppBar bus own: %s\n", e.message);
                }
            } else {
                // If current temrinal is *first* one,
                // broadcast 'quit' signal to other terminals and quit itself.
                exit_terminal.connect(() => {
                        app.exit();
                    });
            }

            tabbar = tab_bar;

            window_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            window_close_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

            // Hide all butons. Only right-click menu will be working
            if (Utils.is_tiling_wm()) menu_button_width = 0;

            menu_button = new WindowButton("window_menu", true, menu_button_width, Constant.TITLEBAR_HEIGHT);
            min_button = new WindowButton("window_min", true, menu_button_width, Constant.TITLEBAR_HEIGHT);
            max_button = new WindowButton("window_max", true, menu_button_width, Constant.TITLEBAR_HEIGHT);
            unmax_button = new WindowButton("window_unmax", true, menu_button_width, Constant.TITLEBAR_HEIGHT);
            close_button = new WindowButton("window_close", true, menu_button_width + Constant.CLOSE_BUTTON_MARGIN_RIGHT, Constant.TITLEBAR_HEIGHT);

            quit_fullscreen_button = new WindowButton("quit_fullscreen", true, Constant.WINDOW_BUTTON_WIDHT + Constant.CLOSE_BUTTON_MARGIN_RIGHT, Constant.TITLEBAR_HEIGHT);

            close_button.clicked.connect((w) => {
                    close_window();
                });
            quit_fullscreen_button.clicked.connect((w) => {
                    quit_fullscreen();
                });

            menu_button.clicked.connect((b) => {
                    focus_widget = ((Gtk.Window) menu_button.get_toplevel()).get_focus();

                    var menu_content = new List<Menu.MenuItem>();
                    menu_content.append(new Menu.MenuItem("new_window", _("New window")));
                    menu_content.append(new Menu.MenuItem("switch_theme", _("Switch theme")));
                    menu_content.append(new Menu.MenuItem("custom_commands", _("Custom commands")));
                    menu_content.append(new Menu.MenuItem("remote_manage", _("Remote management")));
                    menu_content.append(new Menu.MenuItem("", ""));
                    menu_content.append(new Menu.MenuItem("preference", _("Settings")));
                    if (Utils.is_command_exist("dman")) {
                        menu_content.append(new Menu.MenuItem("help", _("Help")));
                    }
                    menu_content.append(new Menu.MenuItem("about", _("About")));
                    menu_content.append(new Menu.MenuItem("exit", _("Exit")));

                    int menu_x, menu_y;
                    menu_button.translate_coordinates(menu_button.get_toplevel(), 0, 0, out menu_x, out menu_y);
                    Gtk.Allocation menu_rect;
                    menu_button.get_allocation(out menu_rect);
                    int window_x, window_y;
                    menu_button.get_toplevel().get_window().get_origin(out window_x, out window_y);

                    menu = new Menu.Menu(window_x + menu_x, window_y + menu_y + menu_rect.height, menu_content);
                    menu.click_item.connect(handle_menu_item_click);
                    menu.destroy.connect(handle_menu_destroy);
                });

            max_toggle_box = new Box(Gtk.Orientation.HORIZONTAL, 0);

            min_button.clicked.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).iconify();
                });
            max_button.clicked.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).maximize();
                });
            unmax_button.clicked.connect((w, e) => {
                    ((Gtk.Window) w.get_toplevel()).unmaximize();
                });

            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0);

            var logo_box = new Box(Gtk.Orientation.VERTICAL, 0);
            logo_box.set_size_request(logo_width, Constant.TITLEBAR_HEIGHT);
            Gtk.Image logo_image = new Gtk.Image.from_file(Utils.get_image_path("title_icon.svg"));
            logo_box.pack_start(logo_image, true, true, 0);
            box.pack_start(logo_box, false, false, 0);

            max_toggle_box.add(max_button);

            box.pack_start(tabbar, true, true, 0);
            var cache_area = new Gtk.EventBox();
            cache_area.set_size_request(titlebar_right_cache_width, -1);
            box.pack_start(cache_area, false, false, 0);
            box.pack_start(window_button_box, false, false, 0);
            box.pack_start(window_close_button_box, false, false, 0);

            show_window_button();

            event_area = new Widgets.WindowEventArea(this);
            // Don't override window button area.
            event_area.margin_end = Constant.CLOSE_BUTTON_WIDTH * 4;
            event_area.filter_double_click_callback = ((x, y) => {
                    int tabbar_x, tabbar_y;
                    this.translate_coordinates(tabbar, x, y, out tabbar_x, out tabbar_y);

                    return tabbar.is_at_tab_close_button((int) tabbar_x) != -1;
                });

            add(box);
            add_overlay(event_area);

            Gdk.RGBA background_color = Gdk.RGBA();

            box.draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);

                    try {
                        background_color = Utils.hex_to_rgba(window.config.config_file.get_string("theme", "background"));
                        if (window.window_is_fullscreen()) {
                            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, 0.8);
                        } else {
                            cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, window.config.config_file.get_double("general", "opacity"));
                        }
                        Draw.draw_rectangle(cr, 0, 0, rect.width, Constant.TITLEBAR_HEIGHT);
                    } catch (Error e) {
                        print("Main window: %s\n", e.message);
                    }

                    Utils.propagate_draw((Container) w, cr);

                    return true;
                });
        }

        public void show_window_button() {
            window_button_box.pack_start(menu_button, false, false, 0);
            window_button_box.pack_start(min_button, false, false, 0);
            window_button_box.pack_start(max_toggle_box, false, false, 0);

            Utils.remove_all_children(window_close_button_box);
            window_close_button_box.pack_start(close_button, false, false, 0);

            show_all();
        }

        public void hide_window_button() {
            Utils.remove_all_children(window_button_box);
            Utils.remove_all_children(window_close_button_box);

            window_close_button_box.pack_start(quit_fullscreen_button, false, false, 0);
        }

        public void handle_menu_item_click(string item_id) {
            switch(item_id) {
                case "new_window":
                    try {
                        GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("deepin-terminal", null, GLib.AppInfoCreateFlags.NONE);
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print("Appbar menu item 'new window': %s\n", e.message);
                    }
                    break;
                case "custom_commands":
                    workspace_manager.focus_workspace.show_command_panel(workspace_manager.focus_workspace);
                    break;
                case "remote_manage":
                    workspace_manager.focus_workspace.show_remote_panel(workspace_manager.focus_workspace);
                    break;
                case "switch_theme":
                    workspace_manager.focus_workspace.show_theme_panel(workspace_manager.focus_workspace);
                    break;
                case "help":
                    Utils.show_manual();
                    break;
                case "about":
                    var dialog = new AboutDialog(focus_widget);
                    dialog.transient_for_window((Widgets.ConfigWindow) this.get_toplevel());
                    break;
                case "exit":
                    // This just call exit_terminal signal, how to exit terminal looks signal exit_terminal's hooks that define at current class.
                    exit_terminal();
                    break;
                case "preference":
                    var preference = new Widgets.Preference((Widgets.ConfigWindow) this.get_toplevel(), ((Gtk.Window) this.get_toplevel()).get_focus());
                    preference.transient_for_window((Widgets.ConfigWindow) this.get_toplevel());
                    break;
            }
        }

        public void handle_menu_destroy() {
            menu = null;

            if (focus_widget != null) {
                focus_widget.grab_focus();
            }
        }

        public void update_max_button() {
            Utils.remove_all_children(max_toggle_box);

            if (((Widgets.Window) get_toplevel()).window_is_max()) {
                max_toggle_box.add(unmax_button);
            } else {
                max_toggle_box.add(max_button);
            }

            max_toggle_box.show_all();
        }
    }
}
