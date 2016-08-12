using Gtk;
using Widgets;

namespace Widgets {
    public class WindowEventArea : Gtk.EventBox {
        public Gtk.Container drawing_area;
        
        public double press_x = 0;
        public double press_y = 0;
        
        public Gdk.Window root_window;
        public weak X.Display display;
        public weak X.Window xrootwindow;
        private weak Gdk.Display gdk_display;
        private Gdk.X11.Window x11_root_window;
        
        public const int _NET_WM_MOVERESIZE_MOVE = 8;
        
        public Gtk.Widget? child_before_leave;
    
        public WindowEventArea(Gtk.Container area) {
            drawing_area = area;
            
            visible_window = false;
            
            // Get default gdk display
            this.gdk_display = Gdk.Display.get_default();
	    
            // Get default xdisplay
            this.display = Gdk.X11.get_default_xdisplay();
	    
            // Get rootwindow
            this.root_window = Gdk.get_default_root_window();
            this.xrootwindow = this.display.root_window(0);
	    
            // And set x11_root_window!
            this.x11_root_window = (Gdk.X11.Window)this.root_window;            
            
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
                    this.display.ungrab_pointer((int) e.time);
                    
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
                                var seat = this.gdk_display.get_default_seat();
                                seat.ungrab();
                                send_message((long) (pointer_x),
                                             (long) (pointer_y),
                                             _NET_WM_MOVERESIZE_MOVE,
                                             (int) e.button
                                             );
                                        
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
        
        public void send_message(long x, long y, int action, int button) {
            X.Event event = X.Event();
	    
            event.xclient.type = X.EventType.ClientMessage;
            event.xclient.message_type = Gdk.X11.get_xatom_by_name("_NET_WM_MOVERESIZE");
            event.xclient.display = this.display;
            event.xclient.window = (int)((Gdk.X11.Window) this.get_toplevel().get_window()).get_xid();
            event.xclient.format = 32;
            event.xclient.data.l[0] = x;
            event.xclient.data.l[1] = y;
            event.xclient.data.l[2] = action;
            event.xclient.data.l[3] = button;
            event.xclient.data.l[4] = 0;  // this value must be 0, otherwise moveresize won't work.
	    
            this.display.send_event(
                this.xrootwindow,
                false,
                X.EventMask.SubstructureNotifyMask | X.EventMask.SubstructureRedirectMask,
                ref event);
                                        
            this.display.flush();
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
