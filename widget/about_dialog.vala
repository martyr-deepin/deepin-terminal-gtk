using Gtk;
using Widgets;

namespace Widgets {
    public class AboutDialog : Gtk.Window {
        public int window_width = 400;
        public int window_height = 340;

        // FIXME: shadow size should get css value from system theme.
        public int shadow_x = 52;
        public int shadow_y = 40;
        
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
        
        Cairo.ImageSurface icon_surface;
        Cairo.ImageSurface logo_surface;
        
        public AboutDialog(Gtk.Window window) {
            set_transient_for(window);
            set_default_geometry(window_width, window_height);
            set_resizable(false);
            set_modal(true);
            
            icon_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("icon.png"));
            logo_surface = new Cairo.ImageSurface.from_png(Utils.get_image_path("logo.png"));
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_width) / 2,
                 y + (window_alloc.height - window_height) / 3);
            
            var titlebar = new Titlebar();
            set_titlebar(titlebar);
            
            titlebar.close_button.button_press_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            draw.connect(on_draw);
            
            show_all();
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);
            
            // Draw icon.
            Draw.draw_surface(cr, icon_surface, shadow_x + (window_width - icon_surface.get_width()) / 2, shadow_y + icon_y);
            
            // Draw name.
            cr.set_source_rgba(0, 0, 0, 1);
            Draw.draw_text(widget, cr, "Deepin Terminal", 0, shadow_y + name_y, rect.width, name_height, Pango.Alignment.CENTER);
            
            // Draw version.
            cr.set_source_rgba(0.4, 0.4, 0.4, 1);
            Draw.draw_text(widget, cr, "Version: 2.0", 0, shadow_y + version_y, rect.width, version_height, Pango.Alignment.CENTER);
            
            // Draw logo.
            Draw.draw_surface(cr, logo_surface, shadow_x + (window_width - logo_surface.get_width()) / 2, shadow_y + logo_y);
            
            // Draw homepage.
            cr.set_source_rgba(0, 0.3, 0.9, 1);
            Draw.draw_text(widget, cr, "www.deepin.org", 0, shadow_y + homepage_y, rect.width, homepage_height, Pango.Alignment.CENTER);
            
            // Draw about.
            cr.set_source_rgba(0.1, 0.1, 0.1, 1);
            Draw.draw_text(widget, cr, "Deepin terminal is a terminal emulator with screen split, workspace and remote machine manage.\n\nDeepin terminal is a free software licensed under GNU GPLv3.", about_x, shadow_y + about_y, rect.width - about_x * 2, about_height, Pango.Alignment.CENTER);
            
            
            return true;
        }
    }
}