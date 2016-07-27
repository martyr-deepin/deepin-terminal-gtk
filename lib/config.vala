using GLib;

namespace Config {
    public class Config : GLib.Object {
        public string config_file_path = Utils.get_config_file_path("config.ini");
        public KeyFile config_file;

        public signal void update();
        
        public Config() {
            config_file = new KeyFile();

            var file = File.new_for_path(config_file_path);
            if (!file.query_exists()) {
                init_config();
            } else {
                load_config();
            }
        }
        
        public void init_config() {
            config_file.set_string("general", "theme", "deepin");
            config_file.set_double("general", "opacity", 0.8);
            config_file.set_string("general", "font", "文泉驿等宽微米黑");
            config_file.set_integer("general", "font_size", 11);
            
            config_file.set_string("keybind", "copy_clipboard", "Ctrl + Shift + c");
            config_file.set_string("keybind", "paste_clipboard", "Ctrl + Shift + v");
            config_file.set_string("keybind", "scroll_page_up", "Shift + PageUp");
            config_file.set_string("keybind", "scroll_page_down", "Shift + PageDown");
            config_file.set_string("keybind", "search", "Ctrl + Shift + f");
            config_file.set_string("keybind", "zoom_in", "Ctrl + =");
            config_file.set_string("keybind", "zoom_out", "Ctrl + -");
            config_file.set_string("keybind", "revert_default_size", "Ctrl + 0");
            
            config_file.set_string("keybind", "new_workspace", "Ctrl + Shift + t");
            config_file.set_string("keybind", "close_workspace", "Ctrl + Shift + w");
            config_file.set_string("keybind", "next_workspace", "Ctrl + Tab");
            config_file.set_string("keybind", "previous_workspace", "Ctrl + Shift + Tab");
            config_file.set_string("keybind", "split_vertically", "Ctrl + Shift + v");
            config_file.set_string("keybind", "split_horizontally", "Ctrl + Shift + h");
            config_file.set_string("keybind", "focus_up_terminal", "Alt + k");
            config_file.set_string("keybind", "focus_down_terminal", "Alt + j");
            config_file.set_string("keybind", "focus_left_terminal", "Alt + h");
            config_file.set_string("keybind", "focus_right_terminal", "Alt + l");
            config_file.set_string("keybind", "close_terminal", "Ctrl + d");
            
            config_file.set_string("keybind", "toggle_fullscreen", "F11");
            config_file.set_string("keybind", "show_helper_window", "Ctrl + Shift + /");
            config_file.set_string("keybind", "show_remote_panel", "Ctrl + 9");
            
            config_file.set_string("advanced", "cursor_shape", "block");
            config_file.set_boolean("advanced", "cursor_blink_mode", true);
            
            config_file.set_boolean("advanced", "scroll_on_key", true);
            config_file.set_boolean("advanced", "scroll_on_output", false);
            config_file.set_integer("advanced", "scroll_line", 0);
            config_file.set_string("advanced", "window_state", "window");
            config_file.set_integer("advanced", "window_width", 0);
            config_file.set_integer("advanced", "window_height", 0);

            save();
        }
        
        public void load_config() {
            try {
                config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
            } catch (Error e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
					print("Config: %s\n", e.message);
				}
			}
        }
        
        public void save() {
            try {
			    Utils.touch_dir(Utils.get_config_dir());
				
                config_file.save_to_file(config_file_path);
            } catch (GLib.FileError e) {
				if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
					print("save: %s\n", e.message);
				}
			}
        }
    }
}