using Cairo;
using Draw;
using Gtk;
using Pango;

namespace Widgets {
    public class Temp_TextButton : Gtk.Button {
        public string button_text;
        
        public Temp_TextButton(string text) {
            button_text = text;
			set_size_request(-1, 22);
            
            draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
			
            var state_flags = widget.get_state_flags();
            
            cr.set_source_rgba(1, 1, 1, 0.3);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, false);
			
            if ((state_flags & Gtk.StateFlags.ACTIVE) != 0) {
                cr.set_source_rgba(1, 1, 1, 0.8);
            } else if ((state_flags & Gtk.StateFlags.PRELIGHT) != 0) {
                cr.set_source_rgba(0.5, 1, 0.5, 0.8);
            } else {
                cr.set_source_rgba(0.5, 0.5, 0.5, 0.8);
            }
            Draw.draw_text(widget, cr, button_text, 0, 0, 
                           widget.get_allocated_width(),
                           widget.get_allocated_height(),
                           widget.get_allocated_height(),
                           Pango.Alignment.CENTER
                           );
            
            return true;
        }
    }
}