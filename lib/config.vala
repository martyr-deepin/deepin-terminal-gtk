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

using GLib;
using Gee;

namespace Config {
    public class Config : GLib.Object {
        public ArrayList<string> backspace_key_erase_names;
        public ArrayList<string> del_key_erase_names;
        public ArrayList<string> encoding_names;
        public HashMap<string, string> erase_map;
        public double default_opacity = 0.9;
        public int default_size = 11;
        public string default_mono_font = "";
        public KeyFile config_file;
        public string config_file_path = Utils.get_config_file_path("config.conf");
        public string? temp_theme = null;

        public signal void update();

        public Config() {
            default_mono_font = font_match("mono");

            config_file = new KeyFile();

            backspace_key_erase_names = new ArrayList<string>();
            string[] backspace_key_erase_list = {"ascii-del", "auto", "control-h", "escape-sequence", "tty"};
            foreach (string name in backspace_key_erase_list) {
                backspace_key_erase_names.add(name);
            }

            del_key_erase_names = new ArrayList<string>();
            string[] del_key_erase_list = {"escape-sequence", "ascii-del", "auto", "control-h", "tty"};
            foreach (string name in del_key_erase_list) {
                del_key_erase_names.add(name);
            }

            erase_map = new HashMap<string, string>();
            erase_map.set("ascii-del", "ascii-del");
            erase_map.set("auto", "auto");
            erase_map.set("control-h", "control-h");
            erase_map.set("escape-sequence", "escape-sequence");
            erase_map.set("tty", "tty");

            encoding_names = new ArrayList<string>();
            string[] encoding_list = {"UTF-8", "UTF-16", "GB18030", "GB2312", "GBK", "BIG5", "BIG5-HKSCS", "ISO-8859-1",  "ISO-8859-2", "ISO-8859-3", "ISO-8859-4", "ISO-8859-5", "ISO-8859-6", "ISO-8859-7", "ISO-8859-8", "ISO-8859-8-I", "ISO-8859-9", "ISO-8859-10", "ISO-8859-13", "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "ARMSCII-8", "CP866", "EUC-JP", "EUC-KR", "EUC-TW", "GEORGIAN-PS", "IBM850", "IBM852", "IBM855", "IBM857", "IBM862", "IBM864", "ISO-2022-JP", "ISO-2022-KR", "ISO-IR-111", "KOI8-R", "KOI8-U", "MAC_ARABIC", "MAC_CE", "MAC_CROATIAN", "MAC-CYRILLIC", "MAC_DEVANAGARI", "MAC_FARSI", "MAC_GREEK", "MAC_GUJARATI", "MAC_GURMUKHI", "MAC_HEBREW", "MAC_ICELANDIC", "MAC_ROMAN", "MAC_ROMANIAN", "MAC_TURKISH", "MAC_UKRAINIAN", "SHIFT_JIS", "TCVN", "TIS-620", "UHC", "VISCII", "WINDOWS-1250", "WINDOWS-1251", "WINDOWS-1252", "WINDOWS-1253", "WINDOWS-1254", "WINDOWS-1255", "WINDOWS-1256", "WINDOWS-1257", "WINDOWS-1258"};
            foreach (string name in encoding_list) {
                encoding_names.add(name);
            }

            var file = File.new_for_path(config_file_path);
            if (!file.query_exists()) {
                init_config();
            } else {
                load_config();
            }
        }

        public void init_config() {
            try {
                config_file.set_string("general", "theme", "deepin");
                config_file.set_double("general", "opacity", default_opacity);
                config_file.set_string("general", "font", default_mono_font);
                config_file.set_integer("general", "font_size", default_size);

                config_file.set_string("shortcut", "copy", "Ctrl + Shift + c");
                config_file.set_string("shortcut", "paste", "Ctrl + Shift + v");
                config_file.set_string("shortcut", "open", "Ctrl + Shift + x");
                config_file.set_string("shortcut", "search", "Ctrl + Shift + f");
                config_file.set_string("shortcut", "zoom_in", "Ctrl + =");
                config_file.set_string("shortcut", "zoom_out", "Ctrl + -");
                config_file.set_string("shortcut", "default_size", "Ctrl + 0");
                config_file.set_string("shortcut", "select_all", "Ctrl + Shift + a");
                config_file.set_string("shortcut", "jump_to_next_command", "Shift + Down");
                config_file.set_string("shortcut", "jump_to_previous_command", "Shift + Up");

                config_file.set_string("shortcut", "new_workspace", "Ctrl + Shift + t");
                config_file.set_string("shortcut", "close_workspace", "Ctrl + Shift + w");
                config_file.set_string("shortcut", "next_workspace", "Ctrl + Tab");
                config_file.set_string("shortcut", "previous_workspace", "Ctrl + Shift + Tab");
                config_file.set_string("shortcut", "vertical_split", "Ctrl + Shift + j");
                config_file.set_string("shortcut", "horizontal_split", "Ctrl + Shift + h");
                config_file.set_string("shortcut", "select_upper_window", "Alt + k");
                config_file.set_string("shortcut", "select_lower_window", "Alt + j");
                config_file.set_string("shortcut", "select_left_window", "Alt + h");
                config_file.set_string("shortcut", "select_right_window", "Alt + l");
                config_file.set_string("shortcut", "close_window", "Ctrl + Alt + q");
                config_file.set_string("shortcut", "close_other_windows", "Ctrl + Shift + q");

                config_file.set_string("shortcut", "rename_title", "F2");
                config_file.set_string("shortcut", "switch_fullscreen", "F11");
                config_file.set_string("shortcut", "display_shortcuts", "Ctrl + Shift + ?");
                config_file.set_string("shortcut", "custom_commands", "Ctrl + [");
                config_file.set_string("shortcut", "remote_management", "Ctrl + /");
                config_file.set_string("shortcut", "select_workspace", "Alt");
                config_file.set_string("shortcut", "new_theme_terminal", "Ctrl + Alt");

                config_file.set_string("advanced", "cursor_shape", "block");
                config_file.set_boolean("advanced", "cursor_blink_mode", true);
                config_file.set_boolean("advanced", "cursor_auto_hide", false);

                config_file.set_boolean("advanced", "scroll_on_key", true);
                config_file.set_boolean("advanced", "scroll_on_output", false);
                config_file.set_integer("advanced", "scroll_line", -1);
                config_file.set_string("advanced", "use_on_starting", "window");
                config_file.set_boolean("advanced", "blur_background", false);
                config_file.set_integer("advanced", "window_width", 0);
                config_file.set_integer("advanced", "window_height", 0);
                config_file.set_double("advanced", "quake_window_height", 0);
                config_file.set_boolean("advanced", "quake_window_fullscreen", false);
                config_file.set_string("advanced", "remote_commands", "zssh");
                config_file.set_boolean("advanced", "hide_quakewindow_after_lost_focus", false);
                config_file.set_boolean("advanced", "show_quakewindow_tab", true);
                config_file.set_boolean("advanced", "follow_active_window", true);
                config_file.set_boolean("advanced", "hide_quakewindow_when_active", true);
                config_file.set_boolean("advanced", "print_notify_after_script_finish", true);
                config_file.set_boolean("advanced", "run_as_login_shell", false);
                config_file.set_boolean("advanced", "show_highlight_frame", false);
                config_file.set_boolean("advanced", "copy_on_select", false);
                config_file.set_boolean("advanced", "tabbar_at_the_bottom", false);
                config_file.set_boolean("advanced", "audible_bell", false);
                config_file.set_boolean("advanced", "always_hide_resize_grip", false);

                config_file.set_string("theme", "color_1", "#073642");
                config_file.set_comment("theme", "color_1", "host");
                config_file.set_string("theme", "color_2", "#bdb76b");
                config_file.set_comment("theme", "color_2", "string");
                config_file.set_string("theme", "color_3", "#859900");
                config_file.set_comment("theme", "color_3", "command");
                config_file.set_string("theme", "color_4", "#b58900");
                config_file.set_comment("theme", "color_4", "command");
                config_file.set_string("theme", "color_5", "#ffd700");
                config_file.set_comment("theme", "color_5", "path");
                config_file.set_string("theme", "color_6", "#d33682");
                config_file.set_comment("theme", "color_6", "variable");
                config_file.set_string("theme", "color_7", "#2aa198");
                config_file.set_comment("theme", "color_7", "prompt");
                config_file.set_string("theme", "color_8", "#eee8d5");
                config_file.set_string("theme", "color_9", "#002b36");
                config_file.set_string("theme", "color_10", "#8b0000");
                config_file.set_comment("theme", "color_10", "error");
                config_file.set_string("theme", "color_11", "#00ff00");
                config_file.set_comment("theme", "color_11", "execute");
                config_file.set_string("theme", "color_12", "#657b83");
                config_file.set_string("theme", "color_13", "#1e90ff");
                config_file.set_comment("theme", "color_13", "folder");
                config_file.set_string("theme", "color_14", "#6c71c4");
                config_file.set_string("theme", "color_15", "#93a1a1");
                config_file.set_string("theme", "color_16", "#fdf6e3");
                config_file.set_string("theme", "background", "#000000");
                config_file.set_string("theme", "foreground", "#00cd00");
                config_file.set_string("theme", "tab", "#2CA7F8");
                config_file.set_string("theme", "style", "dark");

                config_file.set_string("theme_terminal", "theme1", "solarized dark");
                config_file.set_string("theme_terminal", "theme2", "bim");
                config_file.set_string("theme_terminal", "theme3", "hemisu light");
                config_file.set_string("theme_terminal", "theme4", "gruvbox light");
                config_file.set_string("theme_terminal", "theme5", "elementary");
                config_file.set_string("theme_terminal", "theme6", "azu");
                config_file.set_string("theme_terminal", "theme7", "aco");
                config_file.set_string("theme_terminal", "theme8", "miu");
                config_file.set_string("theme_terminal", "theme9", "material");
            } catch (Error e) {
                print("Config init_config: %s\n", e.message);
            }

            save();
        }

        public void check_string(string group, string key, string value) {
            try {
                if (!config_file.has_group(group) || !config_file.has_key(group, key)) {
                    config_file.set_string(group, key, value);
                } else {
                    config_file.get_string(group, key);
                }
            } catch (KeyFileError e) {
                print("check_string: %s\n", e.message);

                config_file.set_string(group, key, value);
                print("Reset [%s] %s with %s\n", group, key, value);
            }
        }

        public void check_font(string group, string key, string value) {
            try {
                if (!config_file.has_group(group) || !config_file.has_key(group, key)) {
                    config_file.set_string(group, key, value);
                } else {
                    var font = config_file.get_string(group, key);
                    bool mono_font_exist = false;
                    int num;
                    string[] mono_or_dot_fonts = (string[]) list_mono_or_dot_fonts(out num);

                    for (int i = 0; i < num; i++) {
                        if (font == mono_or_dot_fonts[i]) {
                            mono_font_exist = true;
                            break;
                        }
                    }

                    if (!mono_font_exist) {
                        config_file.set_string(group, key, value);
                        print("Font '%s' is not exist in system, use '%s' instead.\n", font, value);
                    }
                }
            } catch (KeyFileError e) {
                print("check_font: %s\n", e.message);

                config_file.set_string(group, key, value);
                print("Reset [%s] %s with %s\n", group, key, value);
            }
        }

        public void check_integer(string group, string key, int value) {
            try {
                if (!config_file.has_group(group) || !config_file.has_key(group, key)) {
                    print("** start!\n");
                    config_file.set_integer(group, key, value);
                } else {
                    config_file.get_integer(group, key);
                }
            } catch (KeyFileError e) {
                print("check_integer: %s\n", e.message);

                config_file.set_integer(group, key, value);
                print("Reset [%s] %s with %i\n", group, key, value);
            }
        }

        public void check_double(string group, string key, double value) {
            try {
                if (!config_file.has_group(group) || !config_file.has_key(group, key)) {
                    config_file.set_double(group, key, value);
                } else {
                    config_file.get_double(group, key);
                }
            } catch (KeyFileError e) {
                print("check_double: %s\n", e.message);

                config_file.set_double(group, key, value);
                print("Reset [%s] %s with %f\n", group, key, value);
            }
        }

        public void check_boolean(string group, string key, bool value) {
            try {
                if (!config_file.has_group(group) || !config_file.has_key(group, key)) {
                    config_file.set_boolean(group, key, value);
                } else {
                    config_file.get_boolean(group, key);
                }
            } catch (KeyFileError e) {
                print("check_boolean: %s\n", e.message);

                config_file.set_boolean(group, key, value);
                print("Reset [%s] %s with %s\n", group, key, value.to_string());
            }
        }

        public void check_config() {
            try {
                config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
            } catch (Error e) {
                if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print("Config check_config: %s\n", e.message);
                }
            }

            check_string("general", "theme", "deepin");
            check_double("general", "opacity", default_opacity);
            check_font("general", "font", default_mono_font);
            check_integer("general", "font_size", default_size);

            check_string("shortcut", "copy", "Ctrl + Shift + c");
            check_string("shortcut", "paste", "Ctrl + Shift + v");
            check_string("shortcut", "open", "Ctrl + Shift + x");
            check_string("shortcut", "search", "Ctrl + Shift + f");
            check_string("shortcut", "zoom_in", "Ctrl + =");
            check_string("shortcut", "zoom_out", "Ctrl + -");
            check_string("shortcut", "default_size", "Ctrl + 0");
            check_string("shortcut", "jump_to_next_command", "Shift + Down");
            check_string("shortcut", "jump_to_previous_command", "Shift + Up");
            check_string("shortcut", "select_all", "Ctrl + Shift + a");

            check_string("shortcut", "new_workspace", "Ctrl + Shift + t");
            check_string("shortcut", "close_workspace", "Ctrl + Shift + w");
            check_string("shortcut", "next_workspace", "Ctrl + Tab");
            check_string("shortcut", "previous_workspace", "Ctrl + Shift + Tab");

            check_string("shortcut", "resize_workspace_up", "Ctrl + Alt + Up");
            check_string("shortcut", "resize_workspace_down", "Ctrl + Alt + Down");
            check_string("shortcut", "resize_workspace_left", "Ctrl + Alt + Left");
            check_string("shortcut", "resize_workspace_right", "Ctrl + Alt + Right");

            check_string("shortcut", "vertical_split", "Ctrl + Shift + j");
            check_string("shortcut", "horizontal_split", "Ctrl + Shift + h");
            check_string("shortcut", "select_upper_window", "Alt + k");
            check_string("shortcut", "select_lower_window", "Alt + j");
            check_string("shortcut", "select_left_window", "Alt + h");
            check_string("shortcut", "select_right_window", "Alt + l");
            check_string("shortcut", "close_window", "Ctrl + Alt + q");
            check_string("shortcut", "close_other_windows", "Ctrl + Shift + q");

            check_string("shortcut", "rename_title", "F2");
            check_string("shortcut", "switch_fullscreen", "F11");
            check_string("shortcut", "display_shortcuts", "Ctrl + Shift + ?");
            check_string("shortcut", "custom_commands", "Ctrl + [");
            check_string("shortcut", "remote_management", "Ctrl + /");
            check_string("shortcut", "select_workspace", "Alt");
            check_string("shortcut", "new_theme_terminal", "Ctrl + Alt");

            check_string("advanced", "cursor_shape", "block");
            check_boolean("advanced", "cursor_blink_mode", true);
            check_boolean("advanced", "cursor_auto_hide", false);
            check_boolean("advanced", "bold_is_bright", false);
            check_boolean("advanced", "audible_bell", false);
            check_boolean("advanced", "always_hide_resize_grip", false);

            check_boolean("advanced", "scroll_on_key", true);
            check_boolean("advanced", "scroll_on_output", false);
            check_integer("advanced", "scroll_line", -1);
            check_string("advanced", "use_on_starting", "window");
            check_boolean("advanced", "blur_background", false);
            check_integer("advanced", "window_width", 0);
            check_integer("advanced", "window_height", 0);
            check_double("advanced", "quake_window_height", 0);
            check_boolean("advanced", "quake_window_fullscreen", false);
            check_string("advanced", "remote_commands", "ssh;zssh;tmux;screen");
            check_boolean("advanced", "hide_quakewindow_after_lost_focus", false);
            check_boolean("advanced", "show_quakewindow_tab", true);
            check_boolean("advanced", "follow_active_window", true);
            check_boolean("advanced", "hide_quakewindow_when_active", true);
            check_boolean("advanced", "print_notify_after_script_finish", true);
            check_boolean("advanced", "run_as_login_shell", false);
            check_boolean("advanced", "show_highlight_frame", false);
            check_boolean("advanced", "copy_on_select", false);
            check_boolean("advanced", "tabbar_at_the_bottom", false);

            check_string("theme", "color_1", "#073642");
            check_string("theme", "color_2", "#bdb76b");  // string
            check_string("theme", "color_3", "#859900");
            check_string("theme", "color_4", "#b58900");
            check_string("theme", "color_5", "#ffd700");  // path
            check_string("theme", "color_6", "#d33682");
            check_string("theme", "color_7", "#2aa198");
            check_string("theme", "color_8", "#eee8d5");
            check_string("theme", "color_9", "#002b36");
            check_string("theme", "color_10", "#8b0000");  // error
            check_string("theme", "color_11", "#00ff00");  // exec
            check_string("theme", "color_12", "#657b83");
            check_string("theme", "color_13", "#1e90ff");  // folder
            check_string("theme", "color_14", "#6c71c4");
            check_string("theme", "color_15", "#93a1a1");
            check_string("theme", "color_16", "#fdf6e3");
            check_string("theme", "background", "#000000");  // background
            check_string("theme", "foreground", "#00cd00");  // foreground
            check_string("theme", "tab", "#2CA7F8");         // tab
            check_string("theme", "style", "dark");          // style

            check_string("theme_terminal", "theme1", "solarized dark");
            check_string("theme_terminal", "theme2", "bim");
            check_string("theme_terminal", "theme3", "hemisu light");
            check_string("theme_terminal", "theme4", "gruvbox light");
            check_string("theme_terminal", "theme5", "elementary");
            check_string("theme_terminal", "theme6", "azu");
            check_string("theme_terminal", "theme7", "aco");
            check_string("theme_terminal", "theme8", "miu");
            check_string("theme_terminal", "theme9", "material");

            save();
        }

        public void load_config() {
            try {
                check_config();

                config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
            } catch (Error e) {
                if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print("Config load_config: %s\n", e.message);
                }
            }
        }

        public void load_temp_theme(string theme_name) {
            update_theme(theme_name);
            temp_theme = theme_name;
        }

        public void set_theme(string theme_name) {
            // Set temp theme with null to override.
            temp_theme = null;

            update_theme(theme_name);
            save();
            update();
        }

        public void update_theme(string theme_name) {
            try {
                KeyFile theme_file = new KeyFile();
                theme_file.load_from_file(Utils.get_theme_path(theme_name), KeyFileFlags.NONE);

                foreach (string key in theme_file.get_keys("theme")) {
                    config_file.set_string("theme", key, theme_file.get_string("theme", key).strip());
                }

                var background = theme_file.get_string("theme", "background").strip();
                if (Utils.is_light_color(background)) {
                    config_file.set_string("theme", "style", "light");
                } else {
                    config_file.set_string("theme", "style", "dark");
                }

                config_file.set_string("general", "theme", theme_name);
            } catch (Error e) {
                print("Config update_theme: %s\n", e.message);
            }
        }

        public void save() {
            try {
                Utils.touch_dir(Utils.get_config_dir());

                // Restore config file theme if temp_theme is not null.
                if (temp_theme != null) {
                    try {
                        var theme_file = new KeyFile();
                        theme_file.load_from_file(config_file_path, KeyFileFlags.NONE);

                        var theme_name = theme_file.get_string("general", "theme").strip();
                        update_theme(theme_name);
                    } catch (KeyFileError e) {
                        print("save: %s\n", e.message);
                    }
                }

                config_file.save_to_file(config_file_path);
            } catch (GLib.FileError e) {
                if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                    print("save: %s\n", e.message);
                }
            }
        }

        public int get_terminal_monitor() {
            bool follow_active_window = true;

            try {
                follow_active_window = config_file.get_boolean("advanced", "follow_active_window");
            } catch (Error e) {
                print("Config get_terminal_monitor: %s\n", e.message);
            }

            Gdk.Screen screen = Gdk.Screen.get_default();
            if (follow_active_window) {
                return Utils.get_active_monitor(screen);
            } else {
                return Utils.get_pointer_monitor(screen);
            }
        }
    }
}
