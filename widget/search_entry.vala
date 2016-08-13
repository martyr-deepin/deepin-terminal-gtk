using Gtk;
using Widgets;
using Animation;

namespace Widgets {
    public class SearchEntry : Gtk.EventBox {
        public Gtk.Image search_image;
        public Gtk.Label search_label;
        public Gtk.Entry search_entry;

        public Gtk.Box display_box;
        public Gtk.Box box;
        
        public int height = 36;
        
		AnimateTimer timer;
        public int animation_time = 600;
        public int search_image_margin_x = 18;
        public int search_image_animate_start_x;
        
        public SearchEntry() {
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                            | Gdk.EventMask.BUTTON_RELEASE_MASK
                            | Gdk.EventMask.POINTER_MOTION_MASK
                            | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            visible_window = false;
            set_size_request(-1, height);
            
			timer = new AnimateTimer(AnimateTimer.ease_in_out, animation_time);
			timer.animate.connect(on_animate);
            
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            display_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            
            search_image = new Gtk.Image.from_file(Utils.get_image_path("search.png"));
            search_label = new Gtk.Label(null);
            search_label.set_text("search");
            search_label.get_style_context().add_class("remote_search_label");
            display_box.pack_start(search_image, false, false, 0);
            display_box.pack_start(search_label, false, false, 0);
            display_box.set_halign(Gtk.Align.CENTER);
            
            search_entry = new Entry();
            search_entry.set_placeholder_text("Search");
            search_entry.get_style_context().add_class("remote_search_entry");
            
            switch_to_display();
            
            button_press_event.connect((w, e) => {
                    display_box.set_halign(Gtk.Align.START);
                    display_box.remove(search_label);
                    
                    search_label.translate_coordinates(this, 0, 0, out search_image_animate_start_x, null);
                    search_image.margin_left = search_image_margin_x + search_image_animate_start_x;
                    
                    timer.reset();
                    
                    return false;
                });
            
            add(box);
        }
        
        public void on_animate(double progress) {
            search_image.margin_left = search_image_margin_x + (int) (search_image_animate_start_x * (1.0 - progress));
            
			if (progress >= 1.0) {
				timer.stop();
                switch_to_input();
			}
		}
		
        public void switch_to_display() {
            Utils.destroy_all_children(box);
            
            box.pack_start(display_box, true, true, 0);
            
            show_all();
        }
        
        public void switch_to_input() {
             Utils.destroy_all_children(box);

             box.pack_start(search_image, false, false, 0);
             box.pack_start(search_entry, true, true, 0);
             
             search_image.margin_left = search_image_margin_x;
             search_entry.grab_focus();
             
             show_all();
        }
    }
}