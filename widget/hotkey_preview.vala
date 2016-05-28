using Gtk;
using Draw;

namespace Widgets {
	public class HotkeyPreview : Gtk.Window {
		public string[] terminal_hotkeys;
		public string[] workspace_hotkeys;
		public string[] advanced_hotkeys;
		
        public Gdk.RGBA title_color;
        public Gdk.RGBA hotkey_color;
        public Gdk.RGBA frame_color;
		
		public int title_padding_y = 30;
		public int title_padding_x = 50;
		public int title_height = 40;
		public int hotkey_padding_y = 10;
		public int hotkey_height = 30;
		public int frame_width = 2;
		public int hotkey_width = 300;
		
		public bool quake_mode = false;
		
		public HotkeyPreview(bool q_mode) {
			quake_mode = q_mode;
			
			set_decorated(false);
			set_keep_above(true);
			set_skip_taskbar_hint(true);
			set_skip_pager_hint(true);
			set_accept_focus(false);
			
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());
			
            int monitor = screen.get_monitor_at_window(screen.get_active_window());
            Gdk.Rectangle rect;
            screen.get_monitor_geometry(monitor, out rect);
			set_default_size(rect.width * 3 / 5, rect.height * 2 / 5);
			
			set_position(Gtk.WindowPosition.CENTER);
			
            title_color = Gdk.RGBA();
            title_color.parse("#ffffff");

            hotkey_color = Gdk.RGBA();
            hotkey_color.parse("#aaaaaa");

            frame_color = Gdk.RGBA();
            frame_color.parse("#ffffff");
			
			terminal_hotkeys = {
				"Copy : Ctrl + Shift + c",
				"Paste : Ctrl + Shift + v",
				"Scroll up : Shift + up",
				"Scroll down : Shift + down",
				"Search : Ctrl + Shift + f",
				"Remote manage : Ctrl + Shift + s",
				"Select word : Double click",
				"Open url : Ctrl + LeftButton",
				"Zoom in : Ctrl + -",
				"Zoom out : Ctrl + =",
				"Zoom reset : Ctrl + 0",
			};

			workspace_hotkeys = {
				"New workspace : Ctrl + Shift + t",
				"Next workspace : Ctrl + tab",
				"Previous workspace : Ctrl + Shift + tab",
				"Close workspace : Ctrl + Shift + q",
				"Switch workspace : Ctrl + number",
				"Split vertically : Ctrl + Shift + h",
				"Split horizontally : Ctrl + h",
				"Focus up terminal : Alt + k",
				"Focus down terminal : Alt + j",
				"Focus left terminal : Alt + h",
				"Focus right terminal : Alt + l",
				"Close terminal : Ctrl + Shift + w",
			};

			advanced_hotkeys = {
				"Toggle fullscreen : F11",
				"Display hotkey : Ctrl + Shift + /",
				"Adjust opacity : Ctrl + ScrollButton",
			};
			
			draw.connect(on_draw);
			
			show_all();
		}

		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
			// Draw frame.
			cr.set_line_width(frame_width);
			Utils.set_context_color(cr, frame_color);
			draw_rectangle(cr, rect.x + frame_width, rect.y + frame_width, rect.width - frame_width * 2, rect.height - frame_width * 2, false);
			
			// Draw terminal hotkeys.
			Utils.set_context_color(cr, title_color);
			draw_text(widget, cr, "Terminal hotkeys", rect.x + title_padding_x, rect.y + title_padding_y, hotkey_width, title_height);
			Utils.set_context_color(cr, hotkey_color);
			int terminal_hotkey_count = 0;
			foreach (string terminal_hotkey in terminal_hotkeys) {
				draw_text(widget, cr, terminal_hotkey, rect.x + title_padding_x, rect.y + title_padding_y + title_height + terminal_hotkey_count * hotkey_height, hotkey_width, title_height);
				terminal_hotkey_count++;
			}

			// Draw workspace hotkeys.
			Utils.set_context_color(cr, title_color);
			draw_text(widget, cr, "Workspace hotkeys", rect.x + title_padding_x + hotkey_width, rect.y + title_padding_y, hotkey_width, title_height);
			Utils.set_context_color(cr, hotkey_color);
			int workspace_hotkey_count = 0;
			foreach (string workspace_hotkey in workspace_hotkeys) {
				draw_text(widget, cr, workspace_hotkey, rect.x + title_padding_x + hotkey_width, rect.y + title_padding_y + title_height + workspace_hotkey_count * hotkey_height, hotkey_width, title_height);
				workspace_hotkey_count++;
			}

			// Draw advanced hotkeys.
			Utils.set_context_color(cr, title_color);
			draw_text(widget, cr, "Advanced hotkeys", rect.x + title_padding_x + hotkey_width * 2, rect.y + title_padding_y, hotkey_width, title_height);
			Utils.set_context_color(cr, hotkey_color);
			int advanced_hotkey_count = 0;
			foreach (string advanced_hotkey in advanced_hotkeys) {
				if (advanced_hotkey != "Toggle fullscreen" || !quake_mode) {
					draw_text(widget, cr, advanced_hotkey, rect.x + title_padding_x + hotkey_width * 2, rect.y + title_padding_y + title_height + advanced_hotkey_count * hotkey_height, hotkey_width, title_height);
					advanced_hotkey_count++;
				}
			}
			
			return false;
		}
	}
}