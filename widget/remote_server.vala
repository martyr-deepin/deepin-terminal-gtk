using Gtk;
using Widgets;

namespace Widgets {
    public class RemoteServer : Widgets.BaseWindow {
        public int window_init_width = 480;
        public int window_init_height = 370;
        public int window_expand_height = 540;
        
        public int preference_name_width = 80;
        public int preference_widget_width = 100;
        public int grid_height = 24;
        
        public Gtk.Widget focus_widget;
        public Gtk.Box advanced_options_box;
        public Gtk.Box show_advanced_box;
        public Gtk.Box box;
        
        public RemoteServer(Gtk.Window window, Gtk.Widget widget) {
            focus_widget = widget;
            
            set_transient_for(window);
            set_default_geometry(window_init_width, window_init_height);
            set_resizable(false);
            set_modal(true);
			set_type_hint(Gdk.WindowTypeHint.DIALOG);  // DIALOG hint will give right window effect
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_init_width) / 2,
                 y + (window_alloc.height - window_init_height) / 3);
            
            var titlebar = new Titlebar();
            titlebar.close_button.button_release_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(titlebar, false, false, 0);
            
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            var grid = new Gtk.Grid();
            grid.margin_end = 14;
            box.pack_start(grid, false, false, 0);

            // Nick name.
            Label name_label = new Gtk.Label(null);
            name_label.margin_start = 14;
			Entry name_entry = new Entry();
			name_entry.set_placeholder_text("fill");
            create_key_row(name_label, name_entry, "Nick name:", grid);

            // Address.
            Label address_label = new Gtk.Label(null);
            address_label.margin_start = 14;
			address_label.set_text("IP Address:");
			address_label.get_style_context().add_class("preference-label");
			Entry address_entry = new Entry();
			address_entry.set_placeholder_text("fill");
            address_entry.margin_start = 14;
            address_entry.get_style_context().add_class("preference-entry");
            Label port_label = new Gtk.Label(null);
            port_label.margin_start = 28;
            port_label.set_text("Port:");
            port_label.get_style_context().add_class("preference-label");
			Entry port_entry = new Entry();
            port_entry.set_width_chars(4);
			port_entry.set_text("22");
            port_entry.margin_start = 14;
            port_entry.get_style_context().add_class("preference-entry");
            
            var address_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            address_box.pack_start(address_entry, true, true, 0);
            address_box.pack_start(port_label, false, false, 0);
            address_box.pack_start(port_entry, false, false, 0);
            
            grid_attach_next_to(grid, address_label, name_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid_attach_next_to(grid, address_box, address_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            // Username.
            Label user_label = new Gtk.Label(null);
            user_label.margin_start = 14;
			Entry user_entry = new Entry();
			user_entry.set_placeholder_text("fill");
            create_follow_key_row(user_label, user_entry, "User name:", address_label, grid);
            
            // Password.
            Label password_label = new Gtk.Label(null);
            password_label.margin_start = 14;
			Entry password_entry = new Entry();
			password_entry.set_placeholder_text("fill");
			password_entry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
            password_entry.set_visibility(false);
            create_follow_key_row(password_label, password_entry, "Password:", user_label, grid);
            
            var advanced_options_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(advanced_options_box, false, false, 0);
            
            show_advanced_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var show_advanced_area = new Gtk.EventBox();
            show_advanced_area.add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                                     | Gdk.EventMask.BUTTON_RELEASE_MASK
                                     | Gdk.EventMask.POINTER_MOTION_MASK
                                     | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            show_advanced_area.visible_window = false;
            var show_advanced_label = new Gtk.Label(null);
            show_advanced_label.margin_start = 14;
            show_advanced_label.set_markup("<span size='%i'>%s</span>".printf(11 * Pango.SCALE, "advanced options"));
            show_advanced_label.get_style_context().add_class("link");
            show_advanced_area.add(show_advanced_label);
            show_advanced_area.enter_notify_event.connect((w, e) => {
                    var display = Gdk.Display.get_default();
                    get_window().set_cursor(new Gdk.Cursor.for_display(display, Gdk.CursorType.HAND1));
                    
                    return false;
                });
            show_advanced_area.leave_notify_event.connect((w, e) => {
                    get_window().set_cursor(null);
                    
                    return false;
                });
            show_advanced_area.button_release_event.connect((w, e) => {
                    show_advanced_options();
                    
                    return false;
                });
            show_advanced_area.set_halign(Gtk.Align.CENTER);
            show_advanced_box.pack_start(show_advanced_area, true, true, 0);
            box.pack_start(show_advanced_box, true, true, 0);
            
            Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
            DialogButton cancel_button = new Widgets.DialogButton("Cancel", "left", "text");
            DialogButton confirm_button = new Widgets.DialogButton("Add", "right", "action");
            cancel_button.button_release_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            confirm_button.button_release_event.connect((b) => {
                    destroy();
                    
                    return false;
                });
            button_box.pack_start(cancel_button, false, false, 0);
            button_box.pack_start(confirm_button, false, false, 0);
            box.pack_start(button_box, false, false, 0);
            
            add_widget(box);
        }
        
        public void show_advanced_options() {
            set_default_geometry(window_init_width, window_expand_height);
            
            box.remove(show_advanced_box);
            
            var grid = new Gtk.Grid();
            grid.margin_end = 14;
            advanced_options_box.pack_start(grid, false, false, 0);

            // Group name.
            Label group_name_label = new Gtk.Label(null);
            group_name_label.margin_start = 14;
			Entry group_name_entry = new Entry();
			group_name_entry.set_placeholder_text("option");
            create_key_row(group_name_label, group_name_entry, "Group name:", grid);

            // Path.
            Label path_label = new Gtk.Label(null);
            path_label.margin_start = 14;
			Entry path_entry = new Entry();
			path_entry.set_placeholder_text("option");
            create_follow_key_row(path_label, path_entry, "Path:", group_name_label, grid);

            // Command.
            Label command_label = new Gtk.Label(null);
            command_label.margin_start = 14;
			Entry command_entry = new Entry();
			command_entry.set_placeholder_text("option");
            create_follow_key_row(command_label, command_entry, "Command:", path_label, grid);
        }
        
        public void create_key_row(Gtk.Label label, Gtk.Entry entry, string name, Gtk.Grid grid) {
			label.set_text(name);
            label.margin_start = 14;
            label.get_style_context().add_class("preference-label");
            entry.get_style_context().add_class("preference-entry");
            entry.margin_start = 14;

            grid_attach(grid, label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(grid, entry, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
        
        public void create_follow_key_row(Gtk.Label label, Gtk.Entry entry, string name, Gtk.Label previous_label, Gtk.Grid grid) {
			label.set_text(name);
            label.margin_start = 14;
            label.get_style_context().add_class("preference-label");
            entry.get_style_context().add_class("preference-entry");
            entry.margin_start = 14;
            
            grid_attach_next_to(grid, label, previous_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid_attach_next_to(grid, entry, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
		
        public void grid_attach(Gtk.Grid grid, Gtk.Widget child, int left, int top, int width, int height) {
            child.margin_top = 5;
            child.margin_bottom = 5;
            grid.attach(child, left, top, width, height);
        }
        
        public void grid_attach_next_to(Gtk.Grid grid, Gtk.Widget child, Gtk.Widget sibling, Gtk.PositionType side, int width, int height) {
            child.margin_top = 5;
            child.margin_bottom = 5;
            grid.attach_next_to(child, sibling, side, width, height);
        }
         
        public override void draw_window_below(Cairo.Context cr) {
            Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_start, window_frame_margin_top, window_rect.width, window_rect.height, 5);
        }
    }
}