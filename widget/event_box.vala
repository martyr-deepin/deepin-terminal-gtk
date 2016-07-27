using Gtk;

namespace Widgets {
    public class EventBox : Gtk.EventBox {
        public EventBox() {
            visible_window = false;
            
            draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            Widgets.Window window = (Widgets.Window) this.get_toplevel();

 			try {
				cr.set_source_rgba(0, 0, 0, window.config.config_file.get_double("general", "opacity"));
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
			cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_operator(Cairo.Operator.OVER);
            
            foreach(Gtk.Widget w in this.get_children()) {
                w.draw(cr);
            };

            return true;
        }
    }
}