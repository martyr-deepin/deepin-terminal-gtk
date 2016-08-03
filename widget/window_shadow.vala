using Gtk;

namespace Widgets {
	public class WindowShadow : Gtk.Window {
		public int shadow_radius = 20;
		
		public WindowShadow(int width, int height) {
			set_decorated(false);
            set_app_paintable(true); // set_app_paintable is neccessary step to make window transparent.
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
			// set_can_focus(false);
			
            Gdk.Screen screen = Gdk.Screen.get_default();
            set_visual(screen.get_rgba_visual());
			
			set_size_request(width + shadow_radius * 4, height + shadow_radius * 4);
			
			set_position(Gtk.WindowPosition.CENTER);
			
			draw.connect(on_draw);
		}
		
		public void set_window_size(int width, int height) {
			resize(width + shadow_radius * 4, height + shadow_radius * 4);
		}
		
		public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);

			Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, rect.width, rect.height);
			Cairo.Context surface_cr = new Cairo.Context(surface);
			
			surface_cr.set_source_rgba(1, 0, 0, 1);
			Draw.draw_rounded_rectangle(surface_cr, shadow_radius * 2, shadow_radius * 2, rect.width - shadow_radius * 4, rect.height - shadow_radius * 4, 4.0);
			
			cr.set_source_rgba(0, 0, 0, 0);
			Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height);
			
			Utils.ExponentialBlur.surface(surface, shadow_radius);
			
			Draw.draw_surface(cr, surface);                
			
			print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
			
			return true;
        }
	}
}
	