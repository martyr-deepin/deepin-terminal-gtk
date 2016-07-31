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
		
		public HashMap<string, string> encoding_map;
		public ArrayList<string> encoding_names;
		
		public HashMap<string, string> erase_map;
		public ArrayList<string> backspace_key_erase_names;
		public ArrayList<string> del_key_erase_names;
        
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
			string[] encoding_list = {"UTF-8", "GB18030", "GB2312", "GBK", "BIG5", "BIG5-HKSCS", "ISO-8859-1",  "ISO-8859-2", "ISO-8859-3", "ISO-8859-4", "ISO-8859-5", "ISO-8859-6", "ISO-8859-7", "ISO-8859-8", "ISO-8859-8-I", "ISO-8859-9", "ISO-8859-10", "ISO-8859-13", "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "ARMSCII-8", "CP866", "EUC-JP", "EUC-KR", "EUC-TW", "GEORGIAN-PS", "IBM850", "IBM852", "IBM855", "IBM857", "IBM862", "IBM864", "ISO-2022-JP", "ISO-2022-KR", "ISO-IR-111", "KOI8-R", "KOI8-U", "MAC_ARABIC", "MAC_CE", "MAC_CROATIAN", "MAC-CYRILLIC", "MAC_DEVANAGARI", "MAC_FARSI", "MAC_GREEK", "MAC_GUJARATI", "MAC_GURMUKHI", "MAC_HEBREW", "MAC_ICELANDIC", "MAC_ROMAN", "MAC_ROMANIAN", "MAC_TURKISH", "MAC_UKRAINIAN", "SHIFT_JIS", "TCVN", "TIS-620", "UHC", "VISCII", "WINDOWS-1250", "WINDOWS-1251", "WINDOWS-1252", "WINDOWS-1253", "WINDOWS-1254", "WINDOWS-1255", "WINDOWS-1256", "WINDOWS-1257", "WINDOWS-1258"};
			foreach (string name in encoding_list) {
				encoding_names.add(name);
			}
			
			encoding_map = new HashMap<string, string>();
            encoding_map.set("ISO-8859-1", "Western");
            encoding_map.set("ISO-8859-2", "Central European");
            encoding_map.set("ISO-8859-3", "South European");
            encoding_map.set("ISO-8859-4", "Baltic");
            encoding_map.set("ISO-8859-5", "Cyrillic");
            encoding_map.set("ISO-8859-6", "Arabic");
            encoding_map.set("ISO-8859-7", "Greek");
            encoding_map.set("ISO-8859-8", "Hebrew Visual");
            encoding_map.set("ISO-8859-8-I", "Hebrew");
            encoding_map.set("ISO-8859-9", "Turkish");
            encoding_map.set("ISO-8859-10", "Nordic");
            encoding_map.set("ISO-8859-13", "Baltic");
            encoding_map.set("ISO-8859-14", "Celtic");
            encoding_map.set("ISO-8859-15", "Western");
            encoding_map.set("ISO-8859-16", "Romanian");
            encoding_map.set("UTF-8", "Unicode");
            encoding_map.set("ARMSCII-8", "Armenian");
            encoding_map.set("BIG5", "Chinese Traditional");
            encoding_map.set("BIG5-HKSCS", "Chinese Traditional");
            encoding_map.set("CP866", "Cyrillic/Russian");
            encoding_map.set("EUC-JP", "Japanese");
            encoding_map.set("EUC-KR", "Korean");
            encoding_map.set("EUC-TW", "Chinese Traditional");
            encoding_map.set("GB18030", "Chinese Simplified");
            encoding_map.set("GB2312", "Chinese Simplified");
            encoding_map.set("GBK", "Chinese Simplified");
            encoding_map.set("GEORGIAN-PS", "Georgian");
            encoding_map.set("IBM850", "Western");
            encoding_map.set("IBM852", "Central European");
            encoding_map.set("IBM855", "Cyrillic");
            encoding_map.set("IBM857", "Turkish");
            encoding_map.set("IBM862", "Hebrew");
            encoding_map.set("IBM864", "Arabic");
            encoding_map.set("ISO-2022-JP", "Japanese");
            encoding_map.set("ISO-2022-KR", "Korean");
            encoding_map.set("ISO-IR-111", "Cyrillic");
            encoding_map.set("KOI8-R", "Cyrillic");
            encoding_map.set("KOI8-U", "Cyrillic/Ukrainian");
            encoding_map.set("MAC_ARABIC", "Arabic");
            encoding_map.set("MAC_CE", "Central European");
            encoding_map.set("MAC_CROATIAN", "Croatian");
            encoding_map.set("MAC-CYRILLIC", "Cyrillic");
            encoding_map.set("MAC_DEVANAGARI", "Hindi");
            encoding_map.set("MAC_FARSI", "Persian");
            encoding_map.set("MAC_GREEK", "Greek");
            encoding_map.set("MAC_GUJARATI", "Gujarati");
            encoding_map.set("MAC_GURMUKHI", "Gurmukhi");
            encoding_map.set("MAC_HEBREW", "Hebrew");
            encoding_map.set("MAC_ICELANDIC", "Icelandic");
            encoding_map.set("MAC_ROMAN", "Western");
            encoding_map.set("MAC_ROMANIAN", "Romanian");
            encoding_map.set("MAC_TURKISH", "Turkish");
            encoding_map.set("MAC_UKRAINIAN", "Cyrillic/Ukrainian");
            encoding_map.set("SHIFT_JIS", "Japanese");
            encoding_map.set("TCVN", "Vietnamese");
            encoding_map.set("TIS-620", "Thai");
            encoding_map.set("UHC", "Korean");
            encoding_map.set("VISCII", "Vietnamese");
            encoding_map.set("WINDOWS-1250", "Central European");
            encoding_map.set("WINDOWS-1251", "Cyrillic");
            encoding_map.set("WINDOWS-1252", "Western");
            encoding_map.set("WINDOWS-1253", "Greek");
            encoding_map.set("WINDOWS-1254", "Turkish");
            encoding_map.set("WINDOWS-1255", "Hebrew");
            encoding_map.set("WINDOWS-1256", "Arabic");
            encoding_map.set("WINDOWS-1257", "Baltic");
            encoding_map.set("WINDOWS-1258", "Vietnamese");
			
			
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
            config_file.set_string("keybind", "split_vertically", "Ctrl + H");
            config_file.set_string("keybind", "split_horizontally", "Ctrl + h");
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