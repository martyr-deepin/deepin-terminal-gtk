using Cairo;
using Draw;
using Gtk;
using Pango;

namespace Widgets {
    public class TextButton : Gtk.Button {
        public string button_text;
        
        public TextButton(string text) {
            button_text = text;
            
            draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            var state_flags = widget.get_state_flags();
            
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
                           Pango.Alignment.CENTER
                           );
            
            return true;
        }
    }
}