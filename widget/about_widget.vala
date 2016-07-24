using Gtk;
using Widgets;

namespace Widgets {
    public class AboutWidget : Gtk.DrawingArea {
        public int height = 400;
        
        public int icon_y = 30;
        public int name_y = 134;
        public int name_height = 18;
        public int version_y = 164;
        public int version_height = 12;
        public int logo_y = 188;
        public int homepage_y = 211;
        public int homepage_height = 13;
        public int about_y = 250;
        public int about_x = 38;
        public int about_height = 140;
        
        public Cairo.ImageSurface icon_surface;
        public Cairo.ImageSurface logo_surface;
        
        public AboutWidget() {
            icon_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("icon.png"));
            logo_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("logo.png"));
            
            set_size_request(-1, height);

            draw.connect(on_draw);
            
            show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);
            
            // Draw icon.
            Draw.draw_surface(cr, icon_surface, (rect.width - icon_surface.get_width()) / 2, icon_y);
            
            // Draw name.
            cr.set_source_rgba(0, 0, 0, 1);
            Draw.draw_text(widget, cr, "Deepin Terminal", 0, name_y, rect.width, name_height, Pango.Alignment.CENTER);
            
            // Draw version.
            cr.set_source_rgba(0.4, 0.4, 0.4, 1);
            Draw.draw_text(widget, cr, "Version: 2.0", 0, version_y, rect.width, version_height, Pango.Alignment.CENTER);
            
            // Draw logo.
            Draw.draw_surface(cr, logo_surface, (rect.width - logo_surface.get_width()) / 2, logo_y);
            
            // Draw homepage.
            cr.set_source_rgba(0, 0.3, 0.9, 1);
            Draw.draw_text(widget, cr, "www.deepin.org", 0, homepage_y, rect.width, homepage_height, Pango.Alignment.CENTER);
            
            // Draw about.
            cr.set_source_rgba(0.1, 0.1, 0.1, 1);
            Draw.draw_text(widget, cr, "Deepin terminal is a terminal emulator with screen split, workspace and remote machine manage.\n\nDeepin terminal is a free software licensed under GNU GPLv3.", about_x, about_y, rect.width - about_x * 2, about_height, Pango.Alignment.CENTER);
            
            return true;
        }        
    }
}