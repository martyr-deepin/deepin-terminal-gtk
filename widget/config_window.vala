using Gtk;
using Widgets;

namespace Widgets {
    public class ConfigWindow : Gtk.Window {
        public Config.Config config;

        public Gtk.Box window_frame_box;
        public Gtk.Box window_widget_box;
        
        public ConfigWindow() {
            load_config();
        }
        
        public void load_config() {
            config = new Config.Config();
            config.update.connect((w) => {
                    update_terminal(this);
                    
                    queue_draw();
                });
        }
        
        public void update_terminal(Gtk.Container container) {
            container.forall((child) => {
                    var child_type = child.get_type();
                    
                    if (child_type.is_a(typeof(Widgets.Term))) {
                        ((Widgets.Term) child).setup_from_config();
                    } else if (child_type.is_a(typeof(Gtk.Container))) {
                        update_terminal((Gtk.Container) child);
                    }
                });
        }
    }
}