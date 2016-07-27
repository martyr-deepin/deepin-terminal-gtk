using Gtk;
using Widgets;

namespace Widgets {
	public class CursorToggleButton : Gtk.Bin {
		public int cursor_width = 36;
		public int cursor_height = 26;
		
		public signal void change_cursor_state(string active_state);
		
		public CursorStyleButton block_button;
		public CursorStyleButton ibeam_button;
		public CursorStyleButton underline_button;
		
		public CursorToggleButton() {
			set_size_request(cursor_width, cursor_height * 3);
			
			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			
			block_button = new CursorStyleButton("cursor_block");
			ibeam_button = new CursorStyleButton("cursor_ibeam");
			underline_button = new CursorStyleButton("cursor_underline");
			
			block_button.active.connect((w) => {
					set_cursor_state("block");
					change_cursor_state("block");
				});

			ibeam_button.active.connect((w) => {
					set_cursor_state("ibeam");
					change_cursor_state("ibeam");
				});
			
			underline_button.active.connect((w) => {
					set_cursor_state("underline");
					change_cursor_state("underline");
				});
			
			box.pack_start(block_button, false, false, 0);
			box.pack_start(ibeam_button, false, false, 0);
			box.pack_start(underline_button, false, false, 0);
			
			this.add(box);
			
			show_all();
		}
		
		public void set_cursor_state(string name) {
			if (name == "block") {
				block_button.set_active(true);
				ibeam_button.set_active(false);
				underline_button.set_active(false);
			} else if (name == "ibeam") {
				block_button.set_active(false);
				ibeam_button.set_active(true);
				underline_button.set_active(false);
			} else if (name == "underline") {
				block_button.set_active(false);
				ibeam_button.set_active(false);
				underline_button.set_active(true);
			}
		}
	}
	
	public class CursorStyleButton : Gtk.Button {
		public bool is_active = false;
		public int cursor_width = 36;
		public int cursor_height = 26;
		
        Cairo.ImageSurface normal_surface;
        Cairo.ImageSurface hover_surface;
        Cairo.ImageSurface press_surface;
        Cairo.ImageSurface checked_surface;
		
		public signal void active();
		
		public CursorStyleButton(string icon_name) {
			set_size_request(cursor_width, cursor_height);
			
            normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(icon_name + "_normal.png"));
            hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(icon_name + "_hover.png"));
            press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(icon_name + "_press.png"));
            checked_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(icon_name + "_checked.png"));
			
			button_press_event.connect((w) => {
					active();
					
					return false;
				});
			
			draw.connect(on_draw);
		}
		
		public void set_active(bool active) {
			is_active = active;
			
			queue_draw();
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
			var state_flags = widget.get_state_flags();
            
			if (is_active) {
				Draw.draw_surface(cr, checked_surface);
			} else if ((state_flags & Gtk.StateFlags.ACTIVE) != 0) {
                Draw.draw_surface(cr, press_surface);
            } else if ((state_flags & Gtk.StateFlags.PRELIGHT) != 0) {
                Draw.draw_surface(cr, hover_surface);
            } else {
                Draw.draw_surface(cr, normal_surface);                
            }
			 
            return true;
        }		
	}
}