using Cairo;
using Draw;
using Gtk;
using Utils;

namespace Widgets {
    public class DialogButton : Gtk.EventBox {
        public Cairo.ImageSurface left_normal_surface;
        public Cairo.ImageSurface left_hover_surface;
        public Cairo.ImageSurface left_press_surface;
        public Cairo.ImageSurface right_normal_surface;
        public Cairo.ImageSurface right_hover_surface;
        public Cairo.ImageSurface right_press_surface;
        
        public Gdk.RGBA text_normal_color;
        public Gdk.RGBA text_hover_color;
        public Gdk.RGBA text_press_color;
        public Gdk.RGBA text_action_color;
        public Gdk.RGBA text_warning_color;
        
        public string? button_text;
        public int button_text_size = 12;
        public int button_margin_y = 6;
		
		public bool is_hover = false;
		public bool is_press = false;
        
        public string button_direction;
        public string button_type;
        
        public DialogButton(string? text=null, string direction="left", string type="text") {
            var image_path = "dialog_button";
			left_normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_left_normal.png"));
            left_hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_left_hover.png"));
            left_press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_left_press.png"));
			right_normal_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_right_normal.png"));
            right_hover_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_right_hover.png"));
            right_press_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path(image_path + "_right_press.png"));
            
            button_text = text;
            button_direction = direction;
            button_type = type;
            
            if (button_text != null) {
                text_normal_color = Gdk.RGBA();
                text_normal_color.parse("#303030");
                
                text_hover_color = Gdk.RGBA();
                text_hover_color.parse("#FFFFFF");

                text_press_color = Gdk.RGBA();
                text_press_color.parse("#FFFFFF");
                
                text_action_color = Gdk.RGBA();
                text_action_color.parse("#0087FF");
                
                text_warning_color = Gdk.RGBA();
                text_warning_color.parse("#FF4343");
            }
            
            set_size_request(this.left_normal_surface.get_width(), this.left_normal_surface.get_height());
            
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
            if (button_direction == "left") {
                if (is_press) {
                    Draw.draw_surface(cr, left_press_surface);
                    if (button_text != null) {
                        Utils.set_context_color(cr, text_press_color);
                        Draw.draw_text(widget, cr, button_text, 0, button_margin_y, left_normal_surface.get_width(), button_text_size, Pango.Alignment.CENTER);
                    }
                } else if (is_hover) {
                    Draw.draw_surface(cr, left_hover_surface);
                    if (button_text != null) {
                        Utils.set_context_color(cr, text_hover_color);
                        Draw.draw_text(widget, cr, button_text, 0, button_margin_y, left_normal_surface.get_width(), button_text_size, Pango.Alignment.CENTER);
                    }
                } else {
                    Draw.draw_surface(cr, left_normal_surface);                
                    if (button_text != null) {
                        if (button_type == "text") {
                            Utils.set_context_color(cr, text_normal_color);
                        } else if (button_type == "action") {
                            Utils.set_context_color(cr, text_action_color);
                        } else if (button_type == "warning") {
                            Utils.set_context_color(cr, text_warning_color);
                        }
                        Draw.draw_text(widget, cr, button_text, 0, button_margin_y, left_normal_surface.get_width(), button_text_size, Pango.Alignment.CENTER);
                    }
                }
            } else {
                if (is_press) {
                    Draw.draw_surface(cr, right_press_surface);
                    if (button_text != null) {
                        Utils.set_context_color(cr, text_press_color);
                        Draw.draw_text(widget, cr, button_text, 0, button_margin_y, right_normal_surface.get_width(), button_text_size, Pango.Alignment.CENTER);
                    }
                } else if (is_hover) {
                    Draw.draw_surface(cr, right_hover_surface);
                    if (button_text != null) {
                        Utils.set_context_color(cr, text_hover_color);
                        Draw.draw_text(widget, cr, button_text, 0, button_margin_y, right_normal_surface.get_width(), button_text_size, Pango.Alignment.CENTER);
                    }
                } else {
                    Draw.draw_surface(cr, right_normal_surface);                
                    if (button_text != null) {
                        if (button_type == "text") {
                            Utils.set_context_color(cr, text_normal_color);
                        } else if (button_type == "action") {
                            Utils.set_context_color(cr, text_action_color);
                        } else if (button_type == "warning") {
                            Utils.set_context_color(cr, text_warning_color);
                        }
                        Draw.draw_text(widget, cr, button_text, 0, button_margin_y, right_normal_surface.get_width(), button_text_size, Pango.Alignment.CENTER);
                    }
                }
            }
            
            return true;
        }
    }
}