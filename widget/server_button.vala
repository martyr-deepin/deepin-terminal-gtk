using Gtk;
using Widgets;

namespace Widgets {
    public class ServerButton : Gtk.EventBox {
        public Cairo.ImageSurface surface;
        public Cairo.ImageSurface server_edit_normal_surface;
        public Cairo.ImageSurface server_edit_hover_surface;
        public Cairo.ImageSurface server_edit_press_surface;
        
        public Gdk.RGBA title_color;
        public Gdk.RGBA content_color;
        public Gdk.RGBA press_color;
        public Gdk.RGBA hover_color;
        
        public string title;
        public string content;
        
        public int image_x = 12;
        public int image_y = 4;
        
        public int text_x = 72;
        public int title_y = 8;
        public int content_y = 30;
        
        public int edit_button_x = 254;
        public int edit_button_y = 19;
        
        public int text_width = 136;
        public int title_size = 11;
        public int content_size = 10;
		
		public bool is_hover = false;
		public bool is_press = false;

		public bool is_at_edit_button_area = false;
		
        public int width = Constant.SLIDER_WIDTH;
        public int height = 56;
        
        public bool display_bottom_line = true;
        
        public signal void login_server(string server_info);
        public signal void edit_server(string server_info);
        
        public ServerButton(string server_title, string server_content) {
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                            | Gdk.EventMask.BUTTON_RELEASE_MASK
                            | Gdk.EventMask.POINTER_MOTION_MASK
                            | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            title = server_title;
            content = server_content;
            
			surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server.png"));
			server_edit_normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_normal.png"));
			server_edit_hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_hover.png"));
			server_edit_press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("server_edit_press.png"));
            
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
                    if (is_press) {
                        if (e.x > edit_button_x && e.x < edit_button_x + server_edit_normal_surface.get_width()
                            && e.y > edit_button_y && e.y < height - server_edit_normal_surface.get_height()) {
                            edit_server(server_content);
                        } else {
                            login_server(server_content);
                        }
                    }
					
					is_press = false;
					queue_draw();
                    
					return false;
				});
            motion_notify_event.connect((w, e) => {
                    if (e.x > edit_button_x && e.x < edit_button_x + server_edit_normal_surface.get_width()
                        && e.y > edit_button_y && e.y < height - server_edit_normal_surface.get_height()) {
                        is_at_edit_button_area = true;
                    } else {
                        is_at_edit_button_area = false;
                    }
					queue_draw();
                    
                    return false;
                });
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Draw.draw_surface(cr, surface, image_x, image_y);
            
            if (is_hover) {
                if (is_at_edit_button_area) {
                    if (is_press) {
                        Draw.draw_surface(cr, server_edit_press_surface, edit_button_x, edit_button_y);
                    } else if (is_hover) {
                        Draw.draw_surface(cr, server_edit_hover_surface, edit_button_x, edit_button_y);
                    }
                } else {
                    Draw.draw_surface(cr, server_edit_normal_surface, edit_button_x, edit_button_y);
                }
            }
            
            Utils.set_context_color(cr, title_color);
            Draw.draw_text(widget, cr, title, text_x, title_y, text_width, height, title_size, Pango.Alignment.LEFT);

            Utils.set_context_color(cr, content_color);
            Draw.draw_text(widget, cr, content, text_x, content_y, text_width, height, content_size, Pango.Alignment.LEFT);
            
            if (display_bottom_line) {
                cr.set_source_rgba(1, 1, 1, 0.05);
                Draw.draw_rectangle(cr, 8, height - 1, width - 16, 1);
            }
            
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