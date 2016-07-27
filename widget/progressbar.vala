using Gtk;
using Widgets;

namespace Widgets {
	public class ProgressBar : Gtk.EventBox {
		public int height = 10;
		public double percent;
		
		public signal void update(double percent);
		
		public ProgressBar(double init_percent) {
			percent = init_percent;
			set_size_request(-1, height);
			
			set_visible_window(false);
			
			button_press_event.connect((w, e) => {
					Gtk.Allocation rect;
					w.get_allocation(out rect);
					
					set_percent(percent = e.x * 1.0 / rect.width);
					
					return false;
				});
			draw.connect(on_draw);
			
			show_all();
		}
		
		public void set_percent(double new_percent) {
			percent = new_percent;
			
			update(percent);
			
			queue_draw();
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
			cr.set_source_rgba(1, 0, 1, 1);
			Draw.draw_rectangle(cr, 0, 0, rect.width, height);
			
			cr.set_source_rgba(0, 1, 1, 1);
			Draw.draw_rectangle(cr, 0, 0, (int) (rect.width * percent), height);
            
            return true;
        }
	}
}
