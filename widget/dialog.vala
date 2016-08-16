using Gtk;
using Widgets;

namespace Widgets {
    public class Dialog : Widgets.BaseWindow {
        public Dialog() {
            
        }
            
        public override void draw_window_frame(Cairo.Context cr) {
            Gtk.Allocation window_frame_rect;
            window_frame_box.get_allocation(out window_frame_rect);
                
            int x = window_frame_box.margin_start;
            int y = window_frame_box.margin_top;
            int width = window_frame_rect.width;
            int height = window_frame_rect.height;
            Gdk.RGBA frame_color = Gdk.RGBA();
                
            try {
                frame_color.parse(config.config_file.get_string("theme", "color1"));
                        
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|***|
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|   |   |
                // |---+---+---+---+---+---|
                // |###|###|###|   |   |   |
                // |---+---+---+---+---+---|
                // |***|   |   |   |   |   |
                // |---+---+---+---+---+---|
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.63 * 0.2);
                // Top.
                Draw.draw_rectangle(cr, x + 5, y, 1, 1);
                Draw.draw_rectangle(cr, x + width - 6, y, 1, 1);
                // Bottom.
                Draw.draw_rectangle(cr, x + 5, y + height - 1, 1, 1);
                Draw.draw_rectangle(cr, x + width - 6, y + height - 1, 1, 1);
                // Left.
                Draw.draw_rectangle(cr, x, y + 5, 1, 1);
                Draw.draw_rectangle(cr, x, y + height - 6, 1, 1);
                // Rigt.
                Draw.draw_rectangle(cr, x + width - 1, y + 5, 1, 1);
                Draw.draw_rectangle(cr, x + width - 1, y + height - 6, 1, 1);
                cr.restore();
                        
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|***|
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|   |   |
                // |---+---+---+---+---+---|
                // |###|###|###|   |   |   |
                // |---+---+---+---+---+---|
                // |   |***|   |   |   |   |
                // |---+---+---+---+---+---|
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.56 * 0.2);
                // Top.
                Draw.draw_rectangle(cr, x + 4, y, 1, 1);
                Draw.draw_rectangle(cr, x + width - 5, y, 1, 1);
                // Bottom.
                Draw.draw_rectangle(cr, x + 4, y + height - 1, 1, 1);
                Draw.draw_rectangle(cr, x + width - 5, y + height - 1, 1, 1);
                // Left.
                Draw.draw_rectangle(cr, x, y + 4, 1, 1);
                Draw.draw_rectangle(cr, x, y + height - 5, 1, 1);
                // Rigt.
                Draw.draw_rectangle(cr, x + width - 1, y + 4, 1, 1);
                Draw.draw_rectangle(cr, x + width - 1, y + height - 5, 1, 1);
                cr.restore();
    					
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|***|
                // |---+---+---+---+---+---|
                // |###|###|###|###|   |   |
                // |---+---+---+---+---+---|
                // |###|###|###|   |   |   |
                // |---+---+---+---+---+---|
                // |   |   |***|   |   |   |
                // |---+---+---+---+---+---|
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.47 * 0.2);
                // Top.
                Draw.draw_rectangle(cr, x + 3, y, 1, 1);
                Draw.draw_rectangle(cr, x + width - 4, y, 1, 1);
                // Bottom.
                Draw.draw_rectangle(cr, x + 3, y + height - 1, 1, 1);
                Draw.draw_rectangle(cr, x + width - 4, y + height - 1, 1, 1);
                // Left.
                Draw.draw_rectangle(cr, x, y + 3, 1, 1);
                Draw.draw_rectangle(cr, x, y + height - 4, 1, 1);
                // Rigt.
                Draw.draw_rectangle(cr, x + width - 1, y + 3, 1, 1);
                Draw.draw_rectangle(cr, x + width - 1, y + height - 4, 1, 1);
                cr.restore();
    
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|   |***|
                // |---+---+---+---+---+---|
                // |###|###|###|   |   |   |
                // |---+---+---+---+---+---|
                // |   |   |   |***|   |   |
                // |---+---+---+---+---+---|
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.21 * 0.2);
                // Top.
                Draw.draw_rectangle(cr, x + 2, y, 1, 1);
                Draw.draw_rectangle(cr, x + width - 3, y, 1, 1);
                // Bottom.
                Draw.draw_rectangle(cr, x + 2, y + height - 1, 1, 1);
                Draw.draw_rectangle(cr, x + width - 3, y + height - 1, 1, 1);
                // Left.
                Draw.draw_rectangle(cr, x, y + 2, 1, 1);
                Draw.draw_rectangle(cr, x, y + height - 3, 1, 1);
                // Rigt.
                Draw.draw_rectangle(cr, x + width - 1, y + 2, 1, 1);
                Draw.draw_rectangle(cr, x + width - 1, y + height - 3, 1, 1);
                cr.restore();
    
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|   |   |
                // |---+---+---+---+---+---|
                // |###|###|###|   |***|   |
                // |---+---+---+---+---+---|
                // |   |   |   |   |   |   |
                // |---+---+---+---+---+---|
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.28 * 0.2);
                // Top left.
                Draw.draw_rectangle(cr, x + 1, y + 1, 1, 1);
                // Top right.
                Draw.draw_rectangle(cr, x + width - 2, y + 1, 1, 1);
                // Bottm left.
                Draw.draw_rectangle(cr, x + 1, y + height - 2, 1, 1);
                // Bottom right.
                Draw.draw_rectangle(cr, x + width - 2, y + height - 2, 1, 1);
                cr.restore();
                        
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|###|   |
                // |---+---+---+---+---+---|
                // |###|###|###|###|***|   |
                // |---+---+---+---+---+---|
                // |###|###|###|***|   |   |
                // |---+---+---+---+---+---|
                // |   |   |   |   |   |   |
                // |---+---+---+---+---+---|
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.56 * 0.2);
                // Top.
                Draw.draw_rectangle(cr, x + 2, y + 1, 1, 1);
                Draw.draw_rectangle(cr, x + width - 3, y + 1, 1, 1);
                // Bottom.
                Draw.draw_rectangle(cr, x + 2, y + height - 2, 1, 1);
                Draw.draw_rectangle(cr, x + width - 3, y + height - 2, 1, 1);
                // Left.
                Draw.draw_rectangle(cr, x + 1, y + 2, 1, 1);
                Draw.draw_rectangle(cr, x + 1, y+ height - 3, 1, 1);
                // Rigt.
                Draw.draw_rectangle(cr, x + width - 2, y + 2, 1, 1);
                Draw.draw_rectangle(cr, x + width - 2, y + height - 3, 1, 1);
                cr.restore();
    					
                // Draw window frame.
                cr.save();
                cr.set_source_rgba(0, 0, 0, 0.70 * 0.2);
                // Top.
                Draw.draw_rectangle(cr, x + 6, y, width - 12, 1);
                // Bottom.
                Draw.draw_rectangle(cr, x + 6, y + height - 1, width - 12, 1);
                // Left.
                Draw.draw_rectangle(cr, x, y + 6, 1, height - 12);
                // Rigt..
                Draw.draw_rectangle(cr, x + width - 1, y + 6, 1, height - 12);
                cr.restore();
            } catch (Error e) {
                print(e.message);
            }
        }
    }
}