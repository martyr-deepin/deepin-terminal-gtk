using Gtk;
using Widgets;

namespace Widgets {
    public class PreferenceSlidebar : Gtk.ListBox {
        public PreferenceSlidebar() {
            var basic_segement = new PreferenceSlideItem("Basic", true);
            this.insert(basic_segement, -1);
            
            var theme_segement = new PreferenceSlideItem("Theme", false);
            this.insert(theme_segement, -1);

            var cursor_segement = new PreferenceSlideItem("Cursor", false);
            this.insert(cursor_segement, -1);

            var scroll_segement = new PreferenceSlideItem("Scroll", false);
            this.insert(scroll_segement, -1);
            
            var hotkey_segement = new PreferenceSlideItem("Hotkey", true);
            this.insert(hotkey_segement, -1);

            var terminal_segement = new PreferenceSlideItem("Terminal", false);
            this.insert(terminal_segement, -1);
            
            var workspace_segement = new PreferenceSlideItem("Workspace", false);
            this.insert(workspace_segement, -1);
            
            var advanced_segement = new PreferenceSlideItem("Advanced", false);
            this.insert(advanced_segement, -1);
            
            var about_segement = new PreferenceSlideItem("About", true);
            this.insert(about_segement, -1);
            
            show_all();
        }
    }

    public class PreferenceSlideItem : Gtk.DrawingArea {
        public string item_name;
        public bool item_active;
        public bool is_first_segement;
        
        public int first_segement_margin = 10;
        public int second_segement_margin = 15;
        
        public PreferenceSlideItem(string name, bool is_first) {
            item_name = name;
            is_first_segement = is_first;
            
            set_size_request(150, 22);
            
            draw.connect(on_draw);
        }
        
        private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation rect;
            widget.get_allocation(out rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height, true);
            
            cr.set_source_rgba(0, 0, 0, 1);
            if (is_first_segement) {
                Draw.draw_text(widget, cr, item_name, first_segement_margin, 0, rect.width - first_segement_margin, rect.height);
            } else {
                Draw.draw_text(widget, cr, item_name, second_segement_margin, 0, rect.width - second_segement_margin, rect.height);
            }
            
            return true;
        }
    }
}