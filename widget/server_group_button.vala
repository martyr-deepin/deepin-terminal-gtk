using Gtk;
using Widgets;

namespace Widgets {
    public class ServerGroupButton : Gtk.EventBox {
        public Cairo.ImageSurface surface;
        public Cairo.ImageSurface arrow_surface;
        
        public Gdk.RGBA title_color;
        public Gdk.RGBA content_color;
        public Gdk.RGBA press_color;
        public Gdk.RGBA hover_color;
        
        public string title;
        public int server_number;
        
        public int image_x = 12;
        public int image_y = 4;

        public int arrow_x = 244;
        public int arrow_y = 23;
        
        public int text_x = 72;
        public int title_y = 8;
        public int content_y = 30;
        public int text_width = 136;
        public int title_size = 12;
        public int content_size = 11;
		
		public bool is_hover = false;
		public bool is_press = false;
        
        public int width = 280;
        public int height = 56;
        
        public signal void show_group_servers(string group_name);
        
        public ServerGroupButton(string server_title, int number) {
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                            | Gdk.EventMask.BUTTON_RELEASE_MASK
                            | Gdk.EventMask.POINTER_MOTION_MASK
                            | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            title = server_title;
            server_number = number;
            
			surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_group.png"));
			arrow_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("list_arrow.png"));
            
            title_color = Gdk.RGBA();
            title_color.parse("#FFFFFF");
                
            content_color = Gdk.RGBA();
            content_color.parse("#FFFFFF");
            content_color.alpha = 0.5;

            press_color = Gdk.RGBA();
            press_color.parse("#FFFFFF");
            press_color.alpha = 0.1;
            
            hover_color = Gdk.RGBA();
            hover_color.parse("#FFFFFF");
            hover_color.alpha = 0.1;
            
            set_size_request(width, height);
            
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
                    
                    show_group_servers(server_title);
                    
					return false;
				});
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Draw.draw_surface(cr, surface, image_x, image_y);
            Draw.draw_surface(cr, arrow_surface, arrow_x, arrow_y);
            
            Utils.set_context_color(cr, title_color);
            Draw.draw_text(widget, cr, title, text_x, title_y, text_width, height, title_size, Pango.Alignment.LEFT);

            Utils.set_context_color(cr, content_color);
            string content;
            if (server_number > 1) {
                content = "%i servers".printf(server_number);
            } else {
                content = "1 server";
            }
            Draw.draw_text(widget, cr, content, text_x, content_y, text_width, height, content_size, Pango.Alignment.LEFT);
            
            if (is_press) {
                Utils.set_context_color(cr, press_color);
                Draw.draw_rectangle(cr, 0, 0, width, height);
            } else if (is_hover) {
                Utils.set_context_color(cr, hover_color);
                Draw.draw_rectangle(cr, 0, 0, width, height);
            }
            
            return true;
        }
    }
}