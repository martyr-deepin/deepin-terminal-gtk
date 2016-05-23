using Gtk;

namespace Widgets {
	public class ThemeSelector : Gtk.DrawingArea {
		public ThemeSelector() {
			set_size_request(-1, 22);
			
			draw.connect(on_draw);
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            cr.set_source_rgba(1, 0, 0, 0.8);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height);
            
            return false;
        }
	}
}