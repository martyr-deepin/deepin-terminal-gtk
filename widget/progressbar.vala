using Gtk;
using Widgets;

namespace Widgets {
	public class ProgressBar : Gtk.EventBox {
        public int width = 200;
		public int height = 22;
        public int line_height = 2;
        public int line_margin_top = 10;
		public double percent;
		
        public Gdk.RGBA foreground_color;
        public Gdk.RGBA background_color;
        
        public Cairo.ImageSurface pointer_surface;
        
		public signal void update(double percent);
		
		public ProgressBar(double init_percent) {
			percent = init_percent;
			set_size_request(width, height);
            
            foreground_color = Gdk.RGBA();
            foreground_color.parse("#2ca7f8");
            background_color = Gdk.RGBA();
            background_color.parse("#A4A4A4");
            pointer_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("progress_pointer.png"));
			
			set_visible_window(false);
			
			button_press_event.connect((w, e) => {
					Gtk.Allocation rect;
					w.get_allocation(out rect);
					
					set_percent(e.x * 1.0 / rect.width);
                    
                    return false;
				});
            motion_notify_event.connect((w, e) => {
					Gtk.Allocation rect;
					w.get_allocation(out rect);
					
					set_percent(e.x * 1.0 / rect.width);
					
					return false;
                });
            
			draw.connect(on_draw);
			
			show_all();
		}
		
		public void set_percent(double new_percent) {
            percent = double.max(0.2, double.min(new_percent, 1.0));
            
			update(percent);
			
			queue_draw();
		}
		
		private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            Utils.set_context_color(cr, background_color);
			Draw.draw_rectangle(cr, 0, line_margin_top, rect.width, line_height);
			
			cr.set_source_rgba(1, 0, 1, 1);
            Utils.set_context_color(cr, foreground_color);
			Draw.draw_rectangle(cr, 0, line_margin_top, (int) (rect.width * percent), line_height);
            
            Draw.draw_surface(cr,
                              pointer_surface,
                              int.max(0, int.min((int) (rect.width * percent) - pointer_surface.get_width() / 2, rect.width - pointer_surface.get_width() + 3)),
                              0);
            
            return true;
        }
	}
}
