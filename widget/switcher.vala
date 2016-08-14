using Gtk;
using Widgets;
using Animation;

namespace Widgets {
    public class Switcher : Gtk.VBox {
        public int width;
        
        public Gtk.ScrolledWindow scrolledwindow;
        public Gtk.Box box;
        public Gtk.Box left_box;
        public Gtk.Box right_box;
        
        public AnimateTimer timer;
        public int animation_start_x;
        public int animation_end_x;
        
        public Switcher(int w) {
            width = w;
            
            scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            scrolledwindow.get_style_context().add_class("scrolledwindow");
            scrolledwindow.get_vscrollbar().get_style_context().add_class("preference_scrollbar");
            scrolledwindow.get_hscrollbar().get_style_context().add_class("preference_scrollbar");
            
			timer = new AnimateTimer(AnimateTimer.ease_in_out, 400);
			timer.animate.connect(on_animate);
            
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            left_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            right_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            set_size_request(width, -1);
            scrolledwindow.set_size_request(width, -1);
            box.set_size_request(width * 2, -1);
            left_box.set_size_request(width, -1);
            right_box.set_size_request(width, -1);
            
            box.pack_start(left_box, true, true, 0);
            box.pack_start(right_box, true, true, 0);
            scrolledwindow.add(box);
            pack_start(scrolledwindow, true, true, 0);
        }
        
        public void add_to_left_box(Gtk.Widget start_widget) {
            Utils.remove_all_children(left_box);
            
            left_box.pack_start(start_widget, true, true, 0);
            show_all();
        }
        
        public void scroll_to_right(Gtk.Widget start_widget, Gtk.Widget end_widget) {
            Utils.remove_all_children(left_box);
            Utils.remove_all_children(right_box);
            
            left_box.pack_start(start_widget, true, true, 0);
            right_box.pack_start(end_widget, true, true, 0);

            var adjust = scrolledwindow.get_hadjustment();
            adjust.set_value(0);
            
            show_all();
            
            animation_start_x = 0;
            animation_end_x = width;

            timer.reset();
        }
        
        public void scroll_to_left(Gtk.Widget start_widget, Gtk.Widget end_widget) {
            Utils.remove_all_children(left_box);
            Utils.remove_all_children(right_box);
            
            left_box.pack_start(end_widget, true, true, 0);
            right_box.pack_start(start_widget, true, true, 0);
            
            var adjust = scrolledwindow.get_hadjustment();
            adjust.set_value(width);
            
            show_all();
            
            animation_start_x = width;
            animation_end_x = 0;

            timer.reset();
        }
        
		public void on_animate(double progress) {
			var adjust = scrolledwindow.get_hadjustment();
			adjust.set_value(animation_start_x + (int) (animation_end_x - animation_start_x) * progress);
            
            if (progress >= 1.0) {
				timer.stop();
			}
		}
    }
}