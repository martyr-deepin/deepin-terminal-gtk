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
using Utils;

namespace Widgets {
    public class ConfigWindow : Gtk.Window {
        public Config.Config config;
        public Gdk.RGBA title_line_dark_color;
        public Gdk.RGBA title_line_light_color;
        public Gdk.Screen screen_monitor;
        public Gtk.Box box;
        public Gtk.Box top_box;
        public Gtk.Box window_frame_box;
        public Gtk.Box window_widget_box;
        public WorkspaceManager workspace_manager;
        public bool quake_mode = false;
        public bool show_quake_menu = false;
        public bool? config_theme_is_light;
        public int active_tab_underline_width;
        public int active_tab_underline_x;
        public int cache_height = 0;
        public int cache_width = 0;
        public int reset_timeout_delay = 150;
        public int resize_cache_x = 0;
        public int resize_cache_y = 0;
        public int resize_cache_width = 0;
        public int resize_cache_height = 0;
        public int resize_timeout_delay = 150;
        public uint? reset_timeout_source_id = null;
        public uint? resize_timeout_source_id = null;

        private bool is_show_shortcut_viewer = false;

        public ConfigWindow() {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            load_config();

            title_line_dark_color = Utils.hex_to_rgba("#000000", 0.3);
            title_line_light_color = Utils.hex_to_rgba("#000000", 0.1);
        }

        public void init(WorkspaceManager manager, Tabbar tabbar) {
            set_redraw_on_allocate(true);

            workspace_manager = manager;
            box = new Box(Gtk.Orientation.VERTICAL, 0);
            top_box = new Box(Gtk.Orientation.HORIZONTAL, 0);

            screen_monitor = Gdk.Screen.get_default();
            screen_monitor.composited_changed.connect(() => {
                    update_frame();
                });

            delete_event.connect((w) => {
                    quit();

                    return true;
                });

            destroy.connect((t) => {
                    quit();
                });

            key_press_event.connect((w, e) => {
                    return on_key_press(w, e);
                });

            key_release_event.connect((w, e) => {
                    return on_key_release(w, e);
                });

            enter_notify_event.connect((w, e) => {
                    if (resize_timeout_source_id == null) {
                        resize_timeout_source_id = GLib.Timeout.add(resize_timeout_delay, () => {
                                int pointer_x, pointer_y;
                                Utils.get_pointer_position(out pointer_x, out pointer_y);

                                if (!window_is_normal()) {
                                    get_window().set_cursor(null);
                                } else if (pointer_x != resize_cache_x || pointer_y != resize_cache_y) {
                                    resize_cache_x = pointer_x;
                                    resize_cache_y = pointer_y;

                                    var cursor_type = get_cursor_type(pointer_x, pointer_y);
                                    var display = Gdk.Display.get_default();
                                    if (cursor_type != null) {
                                        get_window().set_cursor(new Gdk.Cursor.for_display(display, cursor_type));
                                    } else {
                                        get_window().set_cursor(null);
                                    }
                                }

                                return true;
                            });
                    }

                    return false;
                });

            enter_notify_event.connect((w, e) => {
                    if (resize_timeout_source_id == null) {
                        resize_timeout_source_id = GLib.Timeout.add(resize_timeout_delay, () => {
                                int pointer_x, pointer_y;
                                Utils.get_pointer_position(out pointer_x, out pointer_y);

                                if (!window_is_normal()) {
                                    get_window().set_cursor(null);
                                } else if (pointer_x != resize_cache_x || pointer_y != resize_cache_y) {
                                    resize_cache_x = pointer_x;
                                    resize_cache_y = pointer_y;

                                    var cursor_type = get_cursor_type(pointer_x, pointer_y);
                                    var display = Gdk.Display.get_default();
                                    if (cursor_type != null) {
                                        get_window().set_cursor(new Gdk.Cursor.for_display(display, cursor_type));
                                    } else {
                                        get_window().set_cursor(null);
                                    }
                                }

                                return true;
                            });
                    }

                    return false;
                });

            leave_notify_event.connect((w, e) => {
                    if (resize_timeout_source_id != null) {
                        GLib.Source.remove(resize_timeout_source_id);
                        resize_timeout_source_id = null;
                    }

                    if (reset_timeout_source_id == null) {
                        reset_timeout_source_id = GLib.Timeout.add(reset_timeout_delay, () => {
                                int pointer_x, pointer_y;
                                Utils.get_pointer_position(out pointer_x, out pointer_y);

                                var cursor_type = get_cursor_type(pointer_x, pointer_y);
                                var display = Gdk.Display.get_default();
                                if (cursor_type != null) {
                                    get_window().set_cursor(new Gdk.Cursor.for_display(display, cursor_type));
                                } else {
                                    get_window().set_cursor(null);
                                }

                                if (cursor_type == null) {
                                    GLib.Source.remove(reset_timeout_source_id);
                                    reset_timeout_source_id = null;
                                }

                                return cursor_type != null;
                            });
                    }

                    return false;
                });

            focus_out_event.connect((w) => {
                    remove_shortcut_viewer();

                    return false;
                });

            configure_event.connect((w) => {
                    int width, height;
                    get_size(out width, out height);

                    if (cache_width != width || cache_height != height) {
                        foreach (var workspace_entry in workspace_manager.workspace_map.entries) {
                            workspace_entry.value.remove_theme_panel();
                            workspace_entry.value.remove_remote_panel();
                            workspace_entry.value.remove_encoding_panel();
                            workspace_entry.value.remove_command_panel();
                        }

                        cache_width = width;
                        cache_height = height;
                    }

                    return false;
                });

            init_active_tab_underline(tabbar);
        }

        public void init_active_tab_underline(Tabbar tabbar) {
            tabbar.update_tab_underline.connect((t, x, width) => {
                    int offset_x, offset_y;
                    tabbar.translate_coordinates(this, 0, 0, out offset_x, out offset_y);

                    int tab_x = x + offset_x;
                    int tab_width = width;

                    if (tab_x != active_tab_underline_x || tab_width != active_tab_underline_width) {
                        active_tab_underline_x = x + offset_x;
                        active_tab_underline_width = width;

                        redraw_window();
                    }
                });
        }

        public void load_config() {
            config = new Config.Config();
            config.update.connect((w) => {
                    update_theme_style();

                    update_terminal(this);

                    redraw_window();
                });
        }

        public void update_terminal(Gtk.Container container) {
            container.forall((child) => {
                    var child_type = child.get_type();

                    if (child_type.is_a(typeof(Widgets.Term))) {
                        ((Widgets.Term) child).setup_from_config();
                    } else if (child_type.is_a(typeof(Gtk.Container))) {
                        update_terminal((Gtk.Container) child);
                    }
                });
        }

        public void show_shortcut_viewer(int x, int y) {
            remove_shortcut_viewer();

            if (!is_show_shortcut_viewer) {
                string data = get_shortcut_data();

                try {
                    GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline(
                        "deepin-shortcut-viewer -j='%s' -p=%i,%i".printf(data, x, y),
                        null,
                        GLib.AppInfoCreateFlags.NONE);

                    appinfo.launch(null, null);
                    is_show_shortcut_viewer = true;
                } catch (Error e) {
                    print("ConfigWindow show_shortcut_viewer: %s\n", e.message);
                }
            }
        }

        public void remove_shortcut_viewer() {
            if (is_show_shortcut_viewer) {
                try {
                    GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline(
                        "deepin-shortcut-viewer -j=''",
                        null,
                        GLib.AppInfoCreateFlags.NONE);
                    appinfo.launch(null, null);
                } catch (Error e) {
                    print("Main on_key_press: %s\n", e.message);
                }

                is_show_shortcut_viewer = false;
            }
        }

        public string get_shortcut_data() {
            // Build a object:
            Json.Builder builder = new Json.Builder();

            try {

                builder.begin_object ();
                builder.set_member_name("shortcut");

                builder.begin_array();

                // Terminal shortcuts.
                builder.begin_object ();
                builder.set_member_name("groupItems");

                builder.begin_array();

                insert_shortcut_key(builder, _("Copy"), config.config_file.get_string("shortcut", "copy"));;
                insert_shortcut_key(builder, _("Paste"), config.config_file.get_string("shortcut", "paste"));;
                insert_shortcut_key(builder, _("Open"), config.config_file.get_string("shortcut", "open"));;
                insert_shortcut_key(builder, _("Search"), config.config_file.get_string("shortcut", "search"));;
                insert_shortcut_key(builder, _("Zoom in"), config.config_file.get_string("shortcut", "zoom_in"));;
                insert_shortcut_key(builder, _("Zoom out"), config.config_file.get_string("shortcut", "zoom_out"));;
                insert_shortcut_key(builder, _("Default size"), config.config_file.get_string("shortcut", "default_size"));;
                insert_shortcut_key(builder, _("Select all"), config.config_file.get_string("shortcut", "select_all"));;
                insert_shortcut_key(builder, _("Jump to next command"), config.config_file.get_string("shortcut", "jump_to_next_command"));;
                insert_shortcut_key(builder, _("Jump to previous command"), config.config_file.get_string("shortcut", "jump_to_previous_command"));;

                builder.end_array();

                builder.set_member_name("groupName");
                builder.add_string_value(_("Terminal"));
                builder.end_object();

                // Workspace shortcuts.

                builder.begin_object ();
                builder.set_member_name("groupItems");

                builder.begin_array();

                var select_workspace_key = config.config_file.get_string("shortcut", "select_workspace");
                var new_theme_terminal_key = config.config_file.get_string("shortcut", "new_theme_terminal");
                insert_shortcut_key(builder, _("New workspace"), config.config_file.get_string("shortcut", "new_workspace"));;
                insert_shortcut_key(builder, _("Close workspace"), config.config_file.get_string("shortcut", "close_workspace"));;
                insert_shortcut_key(builder, _("Next workspace"), config.config_file.get_string("shortcut", "next_workspace"));;
                insert_shortcut_key(builder, _("Previous workspace"), config.config_file.get_string("shortcut", "previous_workspace"));;
                insert_shortcut_key(builder, _("Select workspace"), "%s + 1 ~ %s + 9".printf(select_workspace_key, select_workspace_key));;
                insert_shortcut_key(builder, _("Open terminal with a new theme"), "%s + 1 ~ %s + 9".printf(new_theme_terminal_key, new_theme_terminal_key));;
                insert_shortcut_key(builder, _("Vertical split"), config.config_file.get_string("shortcut", "vertical_split"));;
                insert_shortcut_key(builder, _("Horizontal split"), config.config_file.get_string("shortcut", "horizontal_split"));;
                insert_shortcut_key(builder, _("Select upper window"), config.config_file.get_string("shortcut", "select_upper_window"));;
                insert_shortcut_key(builder, _("Select lower window"), config.config_file.get_string("shortcut", "select_lower_window"));;
                insert_shortcut_key(builder, _("Select left window"), config.config_file.get_string("shortcut", "select_left_window"));;
                insert_shortcut_key(builder, _("Select right window"), config.config_file.get_string("shortcut", "select_right_window"));;
                insert_shortcut_key(builder, _("Close window"), config.config_file.get_string("shortcut", "close_window"));;
                insert_shortcut_key(builder, _("Close other windows"), config.config_file.get_string("shortcut", "close_other_windows"));;

                builder.end_array();

                builder.set_member_name("groupName");
                builder.add_string_value(_("Workspace"));
                builder.end_object();

                // Advanced shortcuts.
                builder.begin_object ();
                builder.set_member_name("groupItems");

                builder.begin_array();

                insert_shortcut_key(builder, _("Rename title"), config.config_file.get_string("shortcut", "rename_title"));;
                insert_shortcut_key(builder, _("Toggle fullscreen"), config.config_file.get_string("shortcut", "switch_fullscreen"));;
                insert_shortcut_key(builder, _("Display shortcuts"), config.config_file.get_string("shortcut", "display_shortcuts"));;
                insert_shortcut_key(builder, _("Custom commands"), config.config_file.get_string("shortcut", "custom_commands"));;
                insert_shortcut_key(builder, _("Remote management"), config.config_file.get_string("shortcut", "remote_management"));;

                builder.end_array();

                builder.set_member_name("groupName");
                builder.add_string_value(_("Advanced"));
                builder.end_object();


                builder.end_array();

                builder.end_object();
            } catch (Error e) {
                print("Main get_shortcut_data: %s\n", e.message);
            }

            // Generate a string:
            Json.Generator generator = new Json.Generator();
            Json.Node root = builder.get_root();
            generator.set_root(root);

            return generator.to_data(null);
        }

        public void insert_shortcut_key(Json.Builder builder, string name, string key) {
            builder.begin_object ();
            builder.set_member_name("name");
            builder.add_string_value(name);

            builder.set_member_name("value");
            builder.add_string_value(key);
            builder.end_object();
        }

        public void quit() {
            if (workspace_manager.has_active_term()) {
                ConfirmDialog dialog = Widgets.create_running_confirm_dialog(this);
                dialog.confirm.connect((d) => {
                        window_save_before_quit();
                        fast_quit();
                    });
            } else {
                window_save_before_quit();
                fast_quit();
            }
        }

        private void fast_quit() {
            // Hide main window before real quit, it's will make user feel terminal quit faster. ;)
            hide();
            Gtk.main_quit();
        }

        private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            try {
                string keyname = Keymap.get_keyevent_name(key_event);
                var select_workspace_key = config.config_file.get_string("shortcut", "select_workspace");
                string[] select_workspace_shortcuts = {
                    "%s + 1".printf(select_workspace_key),
                    "%s + 2".printf(select_workspace_key),
                    "%s + 3".printf(select_workspace_key),
                    "%s + 4".printf(select_workspace_key),
                    "%s + 5".printf(select_workspace_key),
                    "%s + 6".printf(select_workspace_key),
                    "%s + 7".printf(select_workspace_key),
                    "%s + 8".printf(select_workspace_key),
                    "%s + 9".printf(select_workspace_key)
                };

                var new_theme_terminal_key = config.config_file.get_string("shortcut", "new_theme_terminal");
                string[] new_terminal_shortcuts = {
                    "%s + 1".printf(new_theme_terminal_key),
                    "%s + 2".printf(new_theme_terminal_key),
                    "%s + 3".printf(new_theme_terminal_key),
                    "%s + 4".printf(new_theme_terminal_key),
                    "%s + 5".printf(new_theme_terminal_key),
                    "%s + 6".printf(new_theme_terminal_key),
                    "%s + 7".printf(new_theme_terminal_key),
                    "%s + 8".printf(new_theme_terminal_key),
                    "%s + 9".printf(new_theme_terminal_key)
                };

                if (keyname == "F1") {
                    Utils.show_manual();

                    return true;
                }

                var search_key = config.config_file.get_string("shortcut", "search");
                if (search_key != "" && keyname == search_key) {
                    Term focus_term = workspace_manager.focus_workspace.get_focus_term(workspace_manager.focus_workspace);
                    workspace_manager.focus_workspace.search(focus_term.get_selection_text());
                    return true;
                }

                var close_workspace_key = config.config_file.get_string("shortcut", "close_workspace");
                if (close_workspace_key != "" && keyname == close_workspace_key) {
                    workspace_manager.tabbar.close_current_tab();
                    return true;
                }

                var next_workspace_key = config.config_file.get_string("shortcut", "next_workspace");
                if (next_workspace_key != "" && keyname == next_workspace_key) {
                    workspace_manager.tabbar.select_next_tab();
                    return true;
                }

                var previous_workspace_key = config.config_file.get_string("shortcut", "previous_workspace");
                if (previous_workspace_key != "" && keyname == previous_workspace_key) {
                    workspace_manager.tabbar.select_previous_tab();
                    return true;
                }

                var resize_workspace_left_key = config.config_file.get_string("shortcut", "resize_workspace_left");
                if (resize_workspace_left_key != "" && keyname == resize_workspace_left_key) {
                    workspace_manager.focus_workspace.resize_workspace_left();
                    return true;
                }

                var resize_workspace_right_key = config.config_file.get_string("shortcut", "resize_workspace_right");
                if (resize_workspace_right_key != "" && keyname == resize_workspace_right_key) {
                    workspace_manager.focus_workspace.resize_workspace_right();
                    return true;
                }

                var resize_workspace_up_key = config.config_file.get_string("shortcut", "resize_workspace_up");
                if (resize_workspace_up_key != "" && keyname == resize_workspace_up_key) {
                    workspace_manager.focus_workspace.resize_workspace_up();
                    return true;
                }

                var resize_workspace_down_key = config.config_file.get_string("shortcut", "resize_workspace_down");
                if (resize_workspace_down_key != "" && keyname == resize_workspace_down_key) {
                    workspace_manager.focus_workspace.resize_workspace_down();
                    return true;
                }

                var split_vertically_key = config.config_file.get_string("shortcut", "vertical_split");
                if (split_vertically_key != "" && keyname == split_vertically_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.split_vertical();
                    return true;
                }

                var split_horizontally_key = config.config_file.get_string("shortcut", "horizontal_split");
                if (split_horizontally_key != "" && keyname == split_horizontally_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.split_horizontal();
                    return true;
                }

                var select_up_window_key = config.config_file.get_string("shortcut", "select_upper_window");
                if (select_up_window_key != "" && keyname == select_up_window_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.select_up_window();
                    return true;
                }

                var select_down_window_key = config.config_file.get_string("shortcut", "select_lower_window");
                if (select_down_window_key != "" && keyname == select_down_window_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.select_down_window();
                    return true;
                }

                var select_left_window_key = config.config_file.get_string("shortcut", "select_left_window");
                if (select_left_window_key != "" && keyname == select_left_window_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.select_left_window();
                    return true;
                }

                var select_right_window_key = config.config_file.get_string("shortcut", "select_right_window");
                if (select_right_window_key != "" && keyname == select_right_window_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.select_right_window();
                    return true;
                }

                var close_window_key = config.config_file.get_string("shortcut", "close_window");
                if (close_window_key != "" && keyname == close_window_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.close_focus_term();
                    return true;
                }

                var close_other_windows_key = config.config_file.get_string("shortcut", "close_other_windows");
                if (close_other_windows_key != "" && keyname == close_other_windows_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.close_other_terms();
                    return true;
                }

                var toggle_fullscreen_key = config.config_file.get_string("shortcut", "switch_fullscreen");
                if (toggle_fullscreen_key != "" && keyname == toggle_fullscreen_key) {
                    if (!quake_mode) {
                        toggle_fullscreen();
                    }
                    return true;
                }

                var rename_title_key = config.config_file.get_string("shortcut", "rename_title");
                if (rename_title_key != "" && keyname == rename_title_key) {
                    Term focus_term = workspace_manager.focus_workspace.get_focus_term(workspace_manager.focus_workspace);
                    focus_term.rename_title();

                    return true;
                }

                if (Utils.is_command_exist("deepin-shortcut-viewer")) {
                    var show_helper_window_key = config.config_file.get_string("shortcut", "display_shortcuts");
                    if (show_helper_window_key != "" && keyname == show_helper_window_key) {
                        int x, y;
                        if (quake_mode) {
                            Gdk.Screen screen = Gdk.Screen.get_default();
                            int monitor = config.get_terminal_monitor();
                            Gdk.Rectangle rect;
                            screen.get_monitor_geometry(monitor, out rect);

                            x = rect.width / 2;
                            y = rect.height / 2;

                            show_shortcut_viewer(x, y);
                        } else {
                            Gtk.Allocation window_rect;
                            get_allocation(out window_rect);

                            int win_x, win_y;
                            get_window().get_origin(out win_x, out win_y);

                            x = win_x + window_rect.width / 2;
                            y = win_y + window_rect.height / 2;
                            show_shortcut_viewer(x, y);
                        }

                        return true;
                    }
                }

                var show_command_panel_key = config.config_file.get_string("shortcut", "custom_commands");
                if (show_command_panel_key != "" && keyname == show_command_panel_key) {
                    workspace_manager.focus_workspace.toggle_command_panel(workspace_manager.focus_workspace);
                    return true;
                }

                var show_remote_panel_key = config.config_file.get_string("shortcut", "remote_management");
                if (show_remote_panel_key != "" && keyname == show_remote_panel_key) {
                    workspace_manager.focus_workspace.toggle_remote_panel(workspace_manager.focus_workspace);
                    return true;
                }

                var select_all_key = config.config_file.get_string("shortcut", "select_all");
                if (select_all_key != "" && keyname == select_all_key) {
                    workspace_manager.focus_workspace.remove_all_panels();
                    workspace_manager.focus_workspace.toggle_select_all();
                    return true;
                }

                if (keyname in select_workspace_shortcuts) {
                    workspace_manager.switch_workspace_with_index(int.parse(Keymap.get_key_name(key_event.keyval)));
                    return true;
                }

                if (keyname in new_terminal_shortcuts) {
                    var theme_name = config.config_file.get_string("theme_terminal", "theme%i".printf(int.parse(Keymap.get_key_name(key_event.keyval))));

                    try {
                        GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("deepin-terminal --load-theme '%s'".printf(theme_name), null, GLib.AppInfoCreateFlags.NONE);
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print("Appbar menu item 'new window': %s\n", e.message);
                    }

                    return true;
                }

                return false;
            } catch (GLib.KeyFileError e) {
                print("Main on_key_press: %s\n", e.message);

                return false;
            }
        }

        private bool on_key_release(Gtk.Widget widget, Gdk.EventKey key_event) {
            if (Keymap.is_no_key_press(key_event)) {
                if (Utils.is_command_exist("deepin-shortcut-viewer")) {
                    remove_shortcut_viewer();
                }
            }

            try {
                string keyname = Keymap.get_keyevent_name(key_event);
                var new_workspace_key = config.config_file.get_string("shortcut", "new_workspace");
                if (new_workspace_key != "" && keyname == new_workspace_key) {
                    workspace_manager.new_workspace_with_current_directory();
                    return true;
                }
            } catch (GLib.KeyFileError e) {
                print("Main on_key_release: %s\n", e.message);

                return false;
            }

            return false;
        }

        public bool is_light_theme() {
            if (config_theme_is_light == null) {
                update_theme_style();
            }

            return config_theme_is_light;
        }

        public void update_theme_style() {
            try {
                config_theme_is_light = config.config_file.get_string("theme", "style") == "light";
            } catch (Error e) {
                print("ConfigWindow update_theme_style: %s\n", e.message);
            }
        }

        public void draw_titlebar_underline(Cairo.Context cr, int x, int y, int width, int offset) {
            // Draw line below at titlebar.
            cr.save();
            if (is_light_theme()) {
                Utils.set_context_color(cr, title_line_light_color);
            } else {
                Utils.set_context_color(cr, title_line_dark_color);
            }
            // cr.set_source_rgba(1, 0, 0, 1);
            Draw.draw_rectangle(cr, x, y + Constant.TITLEBAR_HEIGHT + offset, width, 1);
            cr.restore();
        }

        public void draw_active_tab_underline(Cairo.Context cr, int x, int y) {
            Gdk.RGBA active_tab_color = Gdk.RGBA();

            try {
                active_tab_color = Utils.hex_to_rgba(config.config_file.get_string("theme", "tab"));
            } catch (GLib.KeyFileError e) {
                print("QuakeWindow draw_window_above: %s\n", e.message);
            }

            cr.save();
            Utils.set_context_color(cr, active_tab_color);
            Draw.draw_rectangle(cr, x, y, active_tab_underline_width, Constant.ACTIVE_TAB_UNDERLINE_HEIGHT);
            cr.restore();
        }

        public virtual void toggle_fullscreen() {
        }

        public virtual void window_save_before_quit() {
        }

        public virtual Gdk.CursorType? get_frame_cursor_type(double x, double y) {
            return null;
        }

        public virtual void update_frame() {
        }

        public virtual Gdk.CursorType? get_cursor_type(double x, double y) {
            return null;
        }

        public void redraw_window() {
            queue_draw();
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
    }
}
