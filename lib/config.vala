using GLib;
using Gee;

namespace Config {
    public class Config : GLib.Object {
        public string config_file_path = Utils.get_config_file_path("config.conf");
        public KeyFile config_file;
		
		public HashMap<string, ArrayList<string>> theme_map;
		public ArrayList<string> theme_names;

        public signal void update();
		
		public string default_mono_font = "";
		public double default_opacity = 0.8;
		public int default_size = 11;
        
        public Config() {
			default_mono_font = font_match("mono");
			
            config_file = new KeyFile();

			theme_names = new ArrayList<string>();
			string[] names = {"deepin", "solarized"};
			foreach (string name in names) {
				theme_names.add(name);
			}
			theme_map = new HashMap<string, ArrayList<string>>();
			add_theme("deepin", {"#000000", "#073642", "#586e75", "#657b83","#839496", "#93a1a1", "#eee8d5", "#00ff00", "#b58900", "#cb4b16", "#dc322f", "#d33682", "#6c71c4", "#268bd2", "#2aa198", "#859900" });
			add_theme("solarized", {"#002b36", "#073642", "#586e75", "#657b83","#839496", "#93a1a1", "#eee8d5", "#fdf6e3", "#b58900", "#cb4b16", "#dc322f", "#d33682", "#6c71c4", "#268bd2", "#2aa198", "#859900" });
			
            var file = File.new_for_path(config_file_path);
            if (!file.query_exists()) {
                init_config();
            } else {
                load_config();
            }
        }
		
		public void add_theme(string theme_name, string[] theme_colors) {
			var theme_list = new ArrayList<string>();
			foreach (string color in theme_colors) {
				theme_list.add(color);
			}
			
			theme_map.set(theme_name, theme_list);
		}
		
		public void set_theme(string theme_name) {
			var theme_colors = theme_map.get(theme_name);
			for (int i = 0; i < 16; i++) {
				config_file.set_string("theme", "color%i".printf(i + 1), theme_colors[i]);
			}
		}
        
        public void init_config() {
            config_file.set_string("general", "theme", "deepin");
            config_file.set_double("general", "opacity", default_opacity);
            config_file.set_string("general", "font", default_mono_font);
            config_file.set_integer("general", "font_size", default_size);
            
            config_file.set_string("keybind", "copy_clipboard", "Ctrl + C");
            config_file.set_string("keybind", "paste_clipboard", "Ctrl + V");
			config_file.set_string("keybind", "search", "Ctrl + F");
            config_file.set_string("keybind", "zoom_in", "Ctrl + =");
            config_file.set_string("keybind", "zoom_out", "Ctrl + -");
            config_file.set_string("keybind", "revert_default_size", "Ctrl + 0");
            config_file.set_string("keybind", "select_all", "Ctrl + A");
            
            config_file.set_string("keybind", "new_workspace", "Ctrl + T");
            config_file.set_string("keybind", "close_workspace", "Ctrl + W");
            config_file.set_string("keybind", "next_workspace", "Ctrl + Tab");
            config_file.set_string("keybind", "previous_workspace", "Ctrl + ISO_Left_Tab");
            config_file.set_string("keybind", "split_vertically", "Ctrl + h");
            config_file.set_string("keybind", "split_horizontally", "Ctrl + H");
            config_file.set_string("keybind", "focus_up_terminal", "Alt + k");
            config_file.set_string("keybind", "focus_down_terminal", "Alt + j");
            config_file.set_string("keybind", "focus_left_terminal", "Alt + h");
            config_file.set_string("keybind", "focus_right_terminal", "Alt + l");
            config_file.set_string("keybind", "close_focus_terminal", "Ctrl + q");
            config_file.set_string("keybind", "close_other_terminal", "Ctrl + Q");
            
            config_file.set_string("keybind", "toggle_fullscreen", "F11");
            config_file.set_string("keybind", "show_helper_window", "Ctrl + ?");
            config_file.set_string("keybind", "show_remote_panel", "Ctrl + 9");
            
            config_file.set_string("advanced", "cursor_shape", "block");
            config_file.set_boolean("advanced", "cursor_blink_mode", true);
            
            config_file.set_boolean("advanced", "scroll_on_key", true);
            config_file.set_boolean("advanced", "scroll_on_output", false);
            config_file.set_integer("advanced", "scroll_line", 0);
            config_file.set_string("advanced", "window_state", "window");
            config_file.set_integer("advanced", "window_width", 0);
            config_file.set_integer("advanced", "window_height", 0);
			
			config_file.set_string("theme", "color1", "#000000");
			config_file.set_string("theme", "color2", "#073642");
			config_file.set_string("theme", "color3", "#586e75");
			config_file.set_string("theme", "color4", "#657b83");
			config_file.set_string("theme", "color5", "#839496");
			config_file.set_string("theme", "color6", "#93a1a1");
			config_file.set_string("theme", "color7", "#eee8d5");
			config_file.set_string("theme", "color8", "#00ff00");
			config_file.set_string("theme", "color9", "#b58900");
			config_file.set_string("theme", "color10", "#cb4b16");
			config_file.set_string("theme", "color11", "#dc322f");
			config_file.set_string("theme", "color12", "#d33682");
			config_file.set_string("theme", "color13", "#6c71c4");
			config_file.set_string("theme", "color14", "#268bd2");
			config_file.set_string("theme", "color15", "#2aa198");
			config_file.set_string("theme", "color16", "#859900");

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