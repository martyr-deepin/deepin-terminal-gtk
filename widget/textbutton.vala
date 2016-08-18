using Gtk;
using Widgets;

namespace Widgets {
    public class TextButton : Gtk.EventBox {
        public Gdk.RGBA text_normal_color;
        public Gdk.RGBA text_hover_color;
        public Gdk.RGBA text_press_color;
        
        public int height = 30;
        public int button_text_size = 10;
        public int button_y = 7;
        
        public string button_text;
        
        public signal void click();
        
        public bool is_press = false;
		public bool is_hover = false;
        
        public TextButton(string text, string normal_color_string, string hover_color_string, string press_color_string) {
            set_size_request(-1, height);
            
            button_text = text;
            
            text_normal_color = Gdk.RGBA();
            text_normal_color.parse(normal_color_string);

            text_hover_color = Gdk.RGBA();
            text_hover_color.parse(hover_color_string);

            text_press_color = Gdk.RGBA();
            text_press_color.parse(press_color_string);
            
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                       | Gdk.EventMask.BUTTON_RELEASE_MASK
                       | Gdk.EventMask.POINTER_MOTION_MASK
                       | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            visible_window = false;
            
            enter_notify_event.connect((w, e) => {
                    var display = Gdk.Display.get_default();
                    get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND1));
                    
					is_hover = true;
					queue_draw();
                    
                    return false;
                });
            leave_notify_event.connect((w, e) => {
                    get_window().set_cursor(null);
                    
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
                        click();
                    }
                    
                    is_press = false;
                    queue_draw();
                    
                    return false;
                });
            
            draw.connect(on_draw);
        }

        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            if (is_hover) {
                if (is_press) {
                    Utils.set_context_color(cr, text_press_color);
                    Draw.draw_text(widget, cr, button_text, 0, button_y, rect.width, button_text_size, button_text_size, Pango.Alignment.CENTER);
                } else {
                    Utils.set_context_color(cr, text_hover_color);
                    Draw.draw_text(widget, cr, button_text, 0, button_y, rect.width, button_text_size, button_text_size, Pango.Alignment.CENTER);
                }
            } else {
                Utils.set_context_color(cr, text_normal_color);
                Draw.draw_text(widget, cr, button_text, 0, button_y, rect.width, button_text_size, button_text_size, Pango.Alignment.CENTER);
            }
            
            return true;            
        }
    }

    public TextButton create_link_button(string text) {
        return new TextButton(text, "#0082FA", "#16B8FF", "#0060B9");
    }

    public TextButton create_delete_button(string text) {
        return new TextButton(text, "#FF5A5A", "#FF142D", "#AF0000");
    }
}