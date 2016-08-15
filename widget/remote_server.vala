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
        public Widgets.ConfigWindow parent_window;
        
        public Gtk.Entry address_entry;
        public Gtk.Entry user_entry;
        public Widgets.PasswordButton password_button;
        public Gtk.Entry port_entry;
        public Gtk.ComboBoxText encode_box;
        public Gtk.Entry path_entry;
        public Gtk.Entry name_entry;
        public Gtk.Entry command_entry;
        public Gtk.Entry groupname_entry;
        public Gtk.ComboBoxText backspace_key_box;
        public Gtk.ComboBoxText del_key_box;
        
        public Gtk.Grid advanced_grid;
        
        public string? server_info;
        
        public KeyFile? config_file;
        
        public signal void add_server(string address,
                                      string username,
                                      string password,
                                      string port,
                                      string encode,
                                      string path,
                                      string command,
                                      string nickname,
                                      string groupname,
                                      string backspace_key,
                                      string delete_key
                                      );
        public signal void edit_server(string address,
                                       string username,
                                       string password,
                                       string port,
                                       string encode,
                                       string path,
                                       string command,
                                       string nickname,
                                       string groupname,
                                       string backspace_key,
                                       string delete_key
                                       );
        
        public RemoteServer(Widgets.ConfigWindow window, Gtk.Widget widget, string? info=null, KeyFile? config=null) {
            try {
                parent_window = window;
                focus_widget = widget;
                server_info = info;
                config_file = config;
            
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
                name_entry = new Entry();
                if (server_info != null) {
                    name_entry.set_text(config_file.get_value(server_info, "Name"));
                }
                name_entry.set_placeholder_text("fill");
                create_key_row(name_label, name_entry, "Nick name:", grid);

                // Address.
                Label address_label = new Gtk.Label(null);
                address_label.margin_start = 14;
                address_label.set_text("IP Address:");
                address_label.get_style_context().add_class("preference_label");
                address_entry = new Entry();
                if (server_info != null) {
                    address_entry.set_text(server_info.split("@")[1]);
                }
                address_entry.set_width_chars(14);
                address_entry.set_placeholder_text("fill");
                address_entry.margin_start = 14;
                address_entry.get_style_context().add_class("preference_entry");
                Label port_label = new Gtk.Label(null);
                port_label.margin_start = 28;
                port_label.set_text("Port:");
                port_label.get_style_context().add_class("preference_label");
                port_entry = new Entry();
                if (server_info != null) {
                    port_entry.set_text(config_file.get_value(server_info, "Port"));
                } else {
                    port_entry.set_text("22");
                }
                port_entry.set_width_chars(4);
                port_entry.margin_start = 14;
                port_entry.get_style_context().add_class("preference_entry");
            
                var address_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                address_box.pack_start(address_entry, true, true, 0);
                address_box.pack_start(port_label, false, false, 0);
                address_box.pack_start(port_entry, false, false, 0);
            
                grid_attach_next_to(grid, address_label, name_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
                grid_attach_next_to(grid, address_box, address_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
                // Username.
                Label user_label = new Gtk.Label(null);
                user_label.margin_start = 14;
                user_entry = new Entry();
                if (server_info != null) {
                    user_entry.set_text(server_info.split("@")[0]);
                }
                user_entry.set_placeholder_text("fill");
                create_follow_key_row(user_label, user_entry, "User name:", address_label, grid);
            
                // Password.
                Label password_label = new Gtk.Label(null);
                password_label.margin_start = 14;
                password_button = new Widgets.PasswordButton();
                if (server_info != null) {
                    string password = Utils.lookup_password(server_info.split("@")[0], server_info.split("@")[1]);
                    password_button.entry.set_text(password);
                }
                password_button.entry.set_placeholder_text("fill");
                create_follow_key_row(password_label, password_button, "Password:", user_label, grid);
            
                advanced_options_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                advanced_grid = new Gtk.Grid();
                advanced_grid.margin_end = 14;
                box.pack_start(advanced_options_box, false, false, 0);

                // Group name.
                Label group_name_label = new Gtk.Label(null);
                group_name_label.margin_start = 14;
                groupname_entry = new Entry();
                if (server_info != null) {
                    groupname_entry.set_text(config_file.get_value(server_info, "GroupName"));
                }
                groupname_entry.set_placeholder_text("option");
                groupname_entry.set_width_chars(30);  // this line is expand width of entry.
                create_key_row(group_name_label, groupname_entry, "Group:", advanced_grid);

                // Path.
                Label path_label = new Gtk.Label(null);
                path_label.margin_start = 14;
                path_entry = new Entry();
                if (server_info != null) {
                    path_entry.set_text(config_file.get_value(server_info, "Path"));
                }
                path_entry.set_placeholder_text("option");
                create_follow_key_row(path_label, path_entry, "Path:", group_name_label, advanced_grid);

                // Command.
                Label command_label = new Gtk.Label(null);
                command_label.margin_start = 14;
                command_entry = new Entry();
                if (server_info != null) {
                    command_entry.set_text(config_file.get_value(server_info, "Command"));
                }
                command_entry.set_placeholder_text("option");
                create_follow_key_row(command_label, command_entry, "Command:", path_label, advanced_grid);
            
                // Encoding.
                Label encode_label = new Gtk.Label(null);
                encode_label.margin_start = 14;
                encode_box = new ComboBoxText();
                foreach (string name in parent_window.config.encoding_names) {
                    encode_box.append(name, name);
                }
                if (server_info != null) {
                    encode_box.set_active(parent_window.config.encoding_names.index_of(config_file.get_value(server_info, "Encode")));
                } else {
                    encode_box.set_active(parent_window.config.encoding_names.index_of("UTF-8"));
                }
                create_follow_key_row(encode_label, encode_box, "Encode:", command_label, advanced_grid, "preference_comboboxtext");
            
                // Backspace sequence.
                Label backspace_key_label = new Gtk.Label(null);
                backspace_key_label.margin_start = 14;
                backspace_key_box = new ComboBoxText();
                foreach (string name in parent_window.config.backspace_key_erase_names) {
                    backspace_key_box.append(name, parent_window.config.erase_map.get(name));
                }
                if (server_info != null) {
                    backspace_key_box.set_active(parent_window.config.backspace_key_erase_names.index_of(config_file.get_value(server_info, "Backspace")));
                } else {
                    backspace_key_box.set_active(parent_window.config.backspace_key_erase_names.index_of("ascii-del"));
                }
                create_follow_key_row(backspace_key_label, backspace_key_box, "Backspace:", encode_label, advanced_grid, "preference_comboboxtext");

                // Delete sequence.
                Label del_key_label = new Gtk.Label(null);
                del_key_label.margin_start = 14;
                del_key_box = new ComboBoxText();
                foreach (string name in parent_window.config.del_key_erase_names) {
                    del_key_box.append(name, parent_window.config.erase_map.get(name));
                }
                if (server_info != null) {
                    del_key_box.set_active(parent_window.config.del_key_erase_names.index_of(config_file.get_value(server_info, "Del")));
                } else {
                    del_key_box.set_active(parent_window.config.del_key_erase_names.index_of("escape-sequence"));
                }
                create_follow_key_row(del_key_label, del_key_box, "Delete:", backspace_key_label, advanced_grid, "preference_comboboxtext");
            
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
                button_box.margin_top = 30;
                DialogButton cancel_button = new Widgets.DialogButton("Cancel", "left", "text");
                string button_name;
                if (server_info != null) {
                    button_name = "Save";
                } else {
                    button_name = "Add";
                }
                DialogButton confirm_button = new Widgets.DialogButton(button_name, "right", "action");
                cancel_button.button_release_event.connect((b) => {
                        destroy();
                    
                        return false;
                    });
                confirm_button.button_release_event.connect((b) => {
                        if (server_info != null) {
                            edit_server(address_entry.get_text(),
                                        user_entry.get_text(),
                                        password_button.entry.get_text(),
                                        port_entry.get_text(),
                                        parent_window.config.encoding_names[encode_box.get_active()],
                                        path_entry.get_text(),
                                        command_entry.get_text(),
                                        name_entry.get_text(),
                                        groupname_entry.get_text(),
                                        parent_window.config.backspace_key_erase_names[backspace_key_box.get_active()],
                                        parent_window.config.del_key_erase_names[del_key_box.get_active()]
                                        );
                        } else {
                            add_server(address_entry.get_text(),
                                       user_entry.get_text(),
                                       password_button.entry.get_text(),
                                       port_entry.get_text(),
                                       parent_window.config.encoding_names[encode_box.get_active()],
                                       path_entry.get_text(),
                                       command_entry.get_text(),
                                       name_entry.get_text(),
                                       groupname_entry.get_text(),
                                       parent_window.config.backspace_key_erase_names[backspace_key_box.get_active()],
                                       parent_window.config.del_key_erase_names[del_key_box.get_active()]
                                       );
                        }
                    
                        destroy();
                    
                        return false;
                    });
                button_box.pack_start(cancel_button, false, false, 0);
                button_box.pack_start(confirm_button, false, false, 0);
                box.pack_start(button_box, false, false, 0);
            
                add_widget(box);
            } catch (Error e) {
                error ("%s", e.message);
            }
        }
        
        public void show_advanced_options() {
            set_default_geometry(window_init_width, window_expand_height);
            
            box.remove(show_advanced_box);
            advanced_options_box.pack_start(advanced_grid, false, false, 0);
            
            show_all();
        }
        
        public void create_key_row(Gtk.Label label, Gtk.Widget widget, string name, Gtk.Grid grid, string class_name="preference_entry") {
			label.set_text(name);
            label.margin_start = 14;
            label.get_style_context().add_class("preference_label");
            widget.get_style_context().add_class(class_name);
            widget.margin_start = 14;

            adjust_option_widgets(label, widget);
            grid_attach(grid, label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(grid, widget, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
        
        public void create_follow_key_row(Gtk.Label label, Gtk.Widget widget, string name, Gtk.Label previous_label, Gtk.Grid grid, string class_name="preference_entry") {
			label.set_text(name);
            label.margin_start = 14;
            label.get_style_context().add_class("preference_label");
            widget.get_style_context().add_class(class_name);
            widget.margin_start = 14;
            
            adjust_option_widgets(label, widget);
            grid_attach_next_to(grid, label, previous_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid_attach_next_to(grid, widget, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
		
        public void adjust_option_widgets(Gtk.Label name_widget, Gtk.Widget value_widget) {
            name_widget.set_xalign(0);
            name_widget.set_size_request(preference_name_width, grid_height);
            name_widget.margin_top = 5;
            name_widget.margin_bottom = 5;
            
            value_widget.set_size_request(preference_widget_width, grid_height);
            value_widget.margin_top = 5;
            value_widget.margin_bottom = 5;
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