using Gtk;
using Widgets;
using XUtils;

namespace Widgets {
    public class WindowEventArea : Gtk.EventBox {
        public Gtk.Container drawing_area;
        
        public double press_x = 0;
        public double press_y = 0;
        
        public Gtk.Widget? child_before_leave;
    
        public WindowEventArea(Gtk.Container area) {
            drawing_area = area;
            
            visible_window = false;
            
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                       | Gdk.EventMask.BUTTON_RELEASE_MASK
                       | Gdk.EventMask.POINTER_MOTION_MASK
                       | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            // draw.connect((w, cr) => {
            //         Gtk.Allocation rect;
            //         w.get_allocation(out rect);

            //         cr.set_source_rgba(1, 0, 0, 0.5);
            //         Draw.draw_rectangle(cr, 0, 0, rect.width, rect.height);
                    
            //         return true;
            //     });
            
            leave_notify_event.connect((w, e) => {
                    if (child_before_leave != null) {
                        var e2 = e.copy();
                        e2.crossing.window = child_before_leave.get_window();
                        
                        child_before_leave.get_window().ref();
                        ((Gdk.Event*) e2)->put();
                        
                        child_before_leave = null;
                    }
                    
                    return false;
            });
            
            motion_notify_event.connect((w, e) => {
                    var child = get_child_at_pos(drawing_area, (int) e.x, (int) e.y);
                    child_before_leave = child;
                    
                    if (child != null) {
                        int x, y;
                        drawing_area.translate_coordinates(child, (int) e.x, (int) e.y, out x, out y);
                    
                        Gdk.EventMotion* event;
                        event = (Gdk.EventMotion) new Gdk.Event(Gdk.EventType.MOTION_NOTIFY);
                        event->window = child.get_window();
                        event->send_event = 1;
                        event->time = e.time;
                        event->x = x;
                        event->y = y;
                        event->x_root = e.x_root;
                        event->y_root = e.y_root;
                        event->state = e.state;
                        event->is_hint = e.is_hint;
                        event->device = e.device;
                        event->axes = e.axes;
                        ((Gdk.Event*) event)->put();
                    }
                    
                    return true;
                });
            
            button_press_event.connect((w, e) => {
                    e.device.get_position(null, out press_x, out press_y);

                    GLib.Timeout.add(10, () => {
                            int pointer_x, pointer_y;
                            e.device.get_position(null, out pointer_x, out pointer_y);
                                
                            if (pointer_x != press_x || pointer_y != press_y) {
                                move_window(this, pointer_x, pointer_y, (int) e.button);
                                return false;
                            } else {
                                return true;
                            }
                        });
                    
                    
                    var child = get_child_at_pos(drawing_area, (int) e.x, (int) e.y);
                    if (child != null) {
                        int x, y;
                        drawing_area.translate_coordinates(child, (int) e.x, (int) e.y, out x, out y);
                    
                        Gdk.EventButton* event;
                        event = (Gdk.EventButton) new Gdk.Event(Gdk.EventType.BUTTON_PRESS);
                        event->window = child.get_window();
                        event->send_event = 1;
                        event->time = e.time;
                        event->x = x;
                        event->y = y;
                        event->x_root = e.x_root;
                        event->y_root = e.y_root;
                        event->state = e.state;
                        event->device = e.device;
                        event->button = e.button;
                        ((Gdk.Event*) event)->put();
                    }
                    
                    if (e.type == Gdk.EventType.2BUTTON_PRESS) {
                        ((Widgets.BaseWindow) this.get_toplevel()).toggle_max();
                    }
                    
                    return true;
                });

            button_release_event.connect((w, e) => {
                    var child = get_child_at_pos(drawing_area, (int) e.x, (int) e.y);
                    if (child != null) {
                        int x, y;
                        drawing_area.translate_coordinates(child, (int) e.x, (int) e.y, out x, out y);
                    
                        Gdk.EventButton* event;
                        event = (Gdk.EventButton) new Gdk.Event(Gdk.EventType.BUTTON_RELEASE);
                        event->window = child.get_window();
                        event->send_event = 1;
                        event->time = e.time;
                        event->x = x;
                        event->y = y;
                        event->x_root = e.x_root;
                        event->y_root = e.y_root;
                        event->state = e.state;
                        event->device = e.device;
                        event->button = e.button;
                        ((Gdk.Event*) event)->put();
                    }
                    
                    return true;
                });
        }
        
        public Gtk.Widget? get_child_at_pos(Gtk.Container container, int x, int y) {
            if (container.get_children().length() > 0) {
                foreach (Gtk.Widget child in container.get_children()) {
                    Gtk.Allocation child_rect;
                    child.get_allocation(out child_rect);

                    int child_x, child_y;
                    child.translate_coordinates(container, 0, 0, out child_x, out child_y);
                    
                    if (x >= child_x && x <= child_x + child_rect.width && y >= child_y && y <= child_y + child_rect.height) {
                        if (child.get_type().is_a(typeof(Gtk.Container))) {
                            return get_child_at_pos((Gtk.Container) child, x - child_x, y - child_y);
                        } else {
                            return child;
                        }
                    }
                }
            }

            return null;
        }
    }
}
