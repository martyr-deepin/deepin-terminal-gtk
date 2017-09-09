using Gtk;

namespace Widgets {
    public class SplitLine : Gtk.Box {
        public int split_line_margin_left = 1;

        public SplitLine() {
            margin_left = split_line_margin_left;
            set_size_request(-1, 1);

            draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);

                    bool is_light_theme = ((Widgets.ConfigWindow) get_toplevel()).is_light_theme();
                    if (is_light_theme) {
                        cr.set_source_rgba(0, 0, 0, 0.1);
                    } else {
                        cr.set_source_rgba(1, 1, 1, 0.1);
                    }
                    Draw.draw_rectangle(cr, 0, 0, rect.width, 1);

                    return true;
                });
        }
    }
}