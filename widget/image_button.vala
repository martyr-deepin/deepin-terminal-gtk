using Cairo;
using Draw;
using Gtk;
using Utils;

namespace Widgets {
    public class ImageButton : Gtk.EventBox {
        public Cairo.ImageSurface normal_surface;
        public Cairo.ImageSurface hover_surface;
        public Cairo.ImageSurface press_surface;
		
		public bool is_hover = false;
		public bool is_press = false;
        
        public ImageButton(string image_path) {
			normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_normal.png"));
            hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_hover.png"));
            press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_press.png"));
            
            set_size_request(this.normal_surface.get_width(), this.normal_surface.get_height());
            
            draw.connect(on_draw);
			enter_notify_event.connect((w, e) => {
					is_hover = true;
					queue_draw();
					
					return false;
				});
			leave_notify_event.connect((w, e) => {
					is_hover = false;
					queue_draw();
					
					return false;
				});
			button_press_event.connect((w, e) => {
					is_press = true;
					queue_draw();
					
					return false;
				});
			button_release_event.connect((w, e) => {
					is_press = false;
					queue_draw();
					
					return false;
				});
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
			if (is_press) {
                Draw.draw_surface(cr, press_surface);
            } else if (is_hover) {
                Draw.draw_surface(cr, hover_surface);
            } else {
                Draw.draw_surface(cr, normal_surface);                
            }
            
            return true;
        }
    }
}