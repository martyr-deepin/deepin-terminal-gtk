/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2016 Deepin, Inc.
 *               2011 ~ 2016 Wang Yong
 *
 * Author:     Wang Yong <wangyong@deepin.com>
 * Maintainer: Wang Yong <wangyong@deepin.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */ 

using Gtk;
using Widgets;

namespace Widgets {
    public class RemoteServerDialog : Widgets.Dialog {
        public Gtk.Box advanced_options_box;
        public Gtk.Box box;
        public Gtk.Box server_action_box;
        public Gtk.ComboBoxText backspace_key_box;
        public Gtk.ComboBoxText del_key_box;
        public Gtk.ComboBoxText encode_box;
        public Gtk.Entry address_entry;
        public Gtk.Entry command_entry;
        public Gtk.Entry groupname_entry;
        public Gtk.Entry name_entry;
        public Gtk.Entry path_entry;
        public Gtk.Entry port_entry;
        public Gtk.Entry user_entry;
        public Gtk.Grid advanced_grid;
        public Gtk.Widget focus_widget;
        public Widgets.ConfigWindow parent_window;
        public Widgets.PasswordButton password_button;
        public Widgets.FileButton file_button;
        public Widgets.TextButton delete_server_button;
        public Widgets.TextButton show_advanced_button;
        public int action_button_margin_top = 20;
        public int font_size = 11;
        public int grid_height = 24;
        public int label_margin_left = 14;
        public int max_server_name_length = 50;
        public int option_widget_margin_end = 5;
        public int option_widget_margin_top = 5;
        public int port_label_margin_left = 21;
        public int preference_margin_end = 20;
        public int preference_margin_start = 20;
        public int preference_margin_top = 10;
        public int preference_name_margin_left = 10;
        public int preference_name_width = 0;
        public int preference_widget_width = 100;
        public int window_expand_height = 530;
        public string? server_info;
        
        public signal void add_server(string address,
                                      string username,
                                      string password,
                                      string private_key,
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
                                       string private_key,
                                       string port,
                                       string encode,
                                       string path,
                                       string command,
                                       string nickname,
                                       string groupname,
                                       string backspace_key,
                                       string delete_key
                                       );
        
        public signal void delete_server(string address, string username);
        
        public RemoteServerDialog(Widgets.ConfigWindow window, Gtk.Widget widget, string? info=null, KeyFile? config_file=null) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
            
            window_init_width = 480;
            window_init_height = 360;
            
            var font_description = new Pango.FontDescription();
            font_description.set_size((int)(font_size * Pango.SCALE));
            int max_width = 0;
            string[] label_names = {_("Server name"), _("Address"), _("Username"), _("Password"), _("Certificate"), _("Path"), _("Command"), _("Group"), _("Encoding"), _("Backspace key"), _("Delete key")};
            foreach (string label_name in label_names) {
                var layout = create_pango_layout(label_name);
                layout.set_font_description(font_description);
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                max_width = int.max(max_width, name_width);
            }
            preference_name_width = max_width + preference_name_margin_left;
            
            try {
                parent_window = window;
                focus_widget = widget;
                server_info = info;
                
                box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                
                var top_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                top_box.margin_bottom = preference_margin_top;
                
                var event_area = new Widgets.WindowEventArea(this);
                event_area.margin_end = Constant.CLOSE_BUTTON_WIDTH;
                
                var overlay = new Gtk.Overlay();
                overlay.add(top_box);
                overlay.add_overlay(event_area);
                
                box.pack_start(overlay, false, false, 0);
                
                // Make label center of titlebar.
                var spacing_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                spacing_box.set_size_request(Constant.CLOSE_BUTTON_WIDTH, -1);
                top_box.pack_start(spacing_box, false, false, 0);
                
                Gtk.Label title_label = new Gtk.Label(null);
                title_label.get_style_context().add_class("remote_server_label");
                top_box.pack_start(title_label, true, true, 0);
                                  
                if (server_info != null) {
                    title_label.set_text(_("Edit Server"));
                } else {
                    title_label.set_text(_("Add Server"));
                }
                
                var close_button = Widgets.create_close_button();
                close_button.clicked.connect((b) => {
                        this.destroy();
                    });
            
                top_box.pack_start(close_button, false, false, 0);
            
                destroy.connect((w) => {
                        if (focus_widget != null) {
                            focus_widget.grab_focus();
                        }
                    });
            
                var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                content_box.set_halign(Gtk.Align.CENTER);
                content_box.margin_start = preference_margin_start;
                content_box.margin_end = preference_margin_end;
                box.pack_start(content_box, false, false, 0);
                
                var grid = new Gtk.Grid();
                grid.margin_end = label_margin_left;
                content_box.pack_start(grid, false, false, 0);

                // Nick name.
                Label name_label = new Gtk.Label(null);
                name_entry = new Entry();
                if (server_info != null) {
                    name_entry.set_text(config_file.get_value(server_info, "Name"));
                }
                name_entry.set_placeholder_text(_("Required"));
                create_key_row(name_label, name_entry, "%s:".printf(_("Server name")), grid);

                // Address.
                Label address_label = new Gtk.Label(null);
                address_label.margin_start = label_margin_left;
                address_label.set_text("%s:".printf(_("Address")));
                address_label.get_style_context().add_class("preference_label");
                address_label.set_xalign(0);
                address_entry = new Entry();
                if (server_info != null) {
                    address_entry.set_text(server_info.split("@")[1]);
                }
                address_entry.set_width_chars(label_margin_left);
                address_entry.set_placeholder_text(_("Required"));
                address_entry.margin_start = label_margin_left;
                address_entry.get_style_context().add_class("preference_entry");
                Label port_label = new Gtk.Label(null);
                port_label.margin_start = port_label_margin_left;
                port_label.set_text("%s:".printf(_("Port")));
                port_label.get_style_context().add_class("preference_label");
                port_entry = new Entry();
                port_entry.set_placeholder_text(_("Required"));
                if (server_info != null) {
                    port_entry.set_text(config_file.get_value(server_info, "Port"));
                } else {
                    port_entry.set_text("22");
                }
                port_entry.set_width_chars(4);
                port_entry.margin_start = label_margin_left;
                port_entry.get_style_context().add_class("preference_entry");
            
                var address_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                address_box.pack_start(address_entry, true, true, 0);
                address_box.pack_start(port_label, false, false, 0);
                address_box.pack_start(port_entry, false, false, 0);
            
                grid_attach_next_to(grid, address_label, name_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
                grid_attach_next_to(grid, address_box, address_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
                
                adjust_option_widgets(address_label, address_box);
            
                // Username.
                Label user_label = new Gtk.Label(null);
                user_entry = new Entry();
                if (server_info != null) {
                    user_entry.set_text(server_info.split("@")[0]);
                }
                user_entry.set_placeholder_text(_("Required"));
                create_follow_key_row(user_label, user_entry, "%s:".printf(_("Username")), address_label, grid);
            
                // Password.
                Label password_label = new Gtk.Label(null);
                password_button = new Widgets.PasswordButton();
                if (server_info != null) {
                    string password = Utils.lookup_password(server_info.split("@")[0], server_info.split("@")[1]);
                    password_button.entry.set_text(password);
                }
                create_follow_key_row(password_label, password_button, "%s:".printf(_("Password")), user_label, grid);
            
                // File.
                Label file_label = new Gtk.Label(null);
                file_button = new Widgets.FileButton();
                if (server_info != null) {
                    try {
                        file_button.entry.set_text(config_file.get_value(server_info, "PrivateKey"));
                    } catch (GLib.KeyFileError e) {
                        if (FileUtils.test(Utils.get_default_private_key_path(), FileTest.EXISTS)) {
                            file_button.entry.set_text(Utils.get_default_private_key_path());
                        }
                    }
                }
                create_follow_key_row(file_label, file_button, "%s:".printf(_("Certificate")), password_label, grid);
            
                // Advanced box.
                advanced_options_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                advanced_grid = new Gtk.Grid();
                advanced_grid.margin_end = label_margin_left;
                content_box.pack_start(advanced_options_box, false, false, 0);
                
                // Group name.
                Label group_name_label = new Gtk.Label(null);
                groupname_entry = new Entry();
                if (server_info != null) {
                    groupname_entry.set_text(config_file.get_value(server_info, "GroupName"));
                }
                groupname_entry.set_placeholder_text(_("Optional"));
                groupname_entry.set_width_chars(30);  // this line is expand width of entry.
                create_key_row(group_name_label, groupname_entry, "%s:".printf(_("Group")), advanced_grid);

                // Path.
                Label path_label = new Gtk.Label(null);
                path_entry = new Entry();
                if (server_info != null) {
                    path_entry.set_text(config_file.get_value(server_info, "Path"));
                }
                path_entry.set_placeholder_text(_("Optional"));
                create_follow_key_row(path_label, path_entry, "%s:".printf(_("Path")), group_name_label, advanced_grid);

                // Command.
                Label command_label = new Gtk.Label(null);
                command_entry = new Entry();
                if (server_info != null) {
                    command_entry.set_text(config_file.get_value(server_info, "Command"));
                }
                command_entry.set_placeholder_text(_("Optional"));
                create_follow_key_row(command_label, command_entry, "%s:".printf(_("Command")), path_label, advanced_grid);
            
                // Encoding.
                Label encode_label = new Gtk.Label(null);
                encode_box = new ComboBoxText();
                foreach (string name in parent_window.config.encoding_names) {
                    encode_box.append(name, name);
                }
                if (server_info != null) {
                    encode_box.set_active(parent_window.config.encoding_names.index_of(config_file.get_value(server_info, "Encode")));
                } else {
                    encode_box.set_active(parent_window.config.encoding_names.index_of("UTF-8"));
                }
                create_follow_key_row(encode_label, encode_box, "%s:".printf(_("Encoding")), command_label, advanced_grid, "preference_comboboxtext");
            
                // Backspace sequence.
                Label backspace_key_label = new Gtk.Label(null);
                backspace_key_box = new ComboBoxText();
                foreach (string name in parent_window.config.backspace_key_erase_names) {
                    backspace_key_box.append(name, parent_window.config.erase_map.get(name));
                }
                if (server_info != null) {
                    backspace_key_box.set_active(parent_window.config.backspace_key_erase_names.index_of(config_file.get_value(server_info, "Backspace")));
                } else {
                    backspace_key_box.set_active(parent_window.config.backspace_key_erase_names.index_of("ascii-del"));
                }
                create_follow_key_row(backspace_key_label, backspace_key_box, "%s:".printf(_("Backspace key")), encode_label, advanced_grid, "preference_comboboxtext");

                // Delete sequence.
                Label del_key_label = new Gtk.Label(null);
                del_key_box = new ComboBoxText();
                foreach (string name in parent_window.config.del_key_erase_names) {
                    del_key_box.append(name, parent_window.config.erase_map.get(name));
                }
                if (server_info != null) {
                    del_key_box.set_active(parent_window.config.del_key_erase_names.index_of(config_file.get_value(server_info, "Del")));
                } else {
                    del_key_box.set_active(parent_window.config.del_key_erase_names.index_of("escape-sequence"));
                }
                create_follow_key_row(del_key_label, del_key_box, "%s:".printf(_("Delete key")), backspace_key_label, advanced_grid, "preference_comboboxtext");
            
                server_action_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                show_advanced_button = Widgets.create_link_button(_("Advanced options"));
                show_advanced_button.clicked.connect((w) => {
                        show_advanced_options();
                    });
                
                server_action_box.pack_start(show_advanced_button, true, true, 0);
                content_box.pack_start(server_action_box, true, true, 0);
            
                Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
                button_box.margin_top = action_button_margin_top;
                DialogButton cancel_button = new Widgets.DialogButton(_("Cancel"), "left", "text");
                string button_name;
                if (server_info != null) {
                    button_name = _("Save");
                } else {
                    button_name = _("Add");
                }
                DialogButton confirm_button = new Widgets.DialogButton(button_name, "right", "action");
                cancel_button.clicked.connect((b) => {
                        destroy();
                    });
                confirm_button.clicked.connect((b) => {
                        if (server_info != null) {
                            if (name_entry.get_text().strip() != "" && address_entry.get_text().strip() != "" && port_entry.get_text().strip() != "" && user_entry.get_text().strip() != "") {
                                edit_server(address_entry.get_text(),
                                            user_entry.get_text(),
                                            password_button.entry.get_text(),
                                            file_button.entry.get_text(),
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
                        } else {
                            if (name_entry.get_text().strip() != "" && address_entry.get_text().strip() != "" && port_entry.get_text().strip() != "" && user_entry.get_text().strip() != "") {
                                add_server(address_entry.get_text(),
                                           user_entry.get_text(),
                                           password_button.entry.get_text(),
                                           file_button.entry.get_text(),
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
                        }
                    });
                
                var tab_order_list = new List<Gtk.Widget>();
                tab_order_list.append((Gtk.Widget) cancel_button);
                tab_order_list.append((Gtk.Widget) confirm_button);
                button_box.set_focus_chain(tab_order_list);
                button_box.set_focus_child(confirm_button);
            
                button_box.pack_start(cancel_button, true, true, 0);
                button_box.pack_start(confirm_button, true, true, 0);
                box.pack_start(button_box, false, false, 0);
            
                add_widget(box);
            } catch (Error e) {
                error ("%s", e.message);
            }
        }
        
        public void show_advanced_options() {
            set_default_geometry(window_init_width, window_expand_height);
            
            Utils.destroy_all_children(server_action_box);
            if (server_info != null) {
                delete_server_button = Widgets.create_delete_button(_("Delete server"));
                delete_server_button.clicked.connect((w) => {
                        this.hide();
                        
                        var server_name = name_entry.get_text();
                        if (server_name.length > max_server_name_length) {
                            server_name = server_name.substring(0, max_server_name_length) + " ... "; 
                        }
                        
                        var confirm_dialog = new Widgets.ConfirmDialog(
                            _("Delete server"), 
                            "%s %s?".printf(_("Are you sure to delete"), server_name), 
                            _("Cancel"), 
                            _("Delete"));
                        confirm_dialog.transient_for_window(parent_window);
                        confirm_dialog.cancel.connect((w) => {
                                this.destroy();
                            });
                        confirm_dialog.confirm.connect((w) => {
                                delete_server(address_entry.get_text(), user_entry.get_text());
                                this.destroy();
                            });
                    });
                server_action_box.pack_start(delete_server_button, true, true, 0);
            }
            
            advanced_options_box.pack_start(advanced_grid, false, false, 0);
            
            show_all();
        }
        
        public void create_key_row(Gtk.Label label, Gtk.Widget widget, string name, Gtk.Grid grid, string class_name="preference_entry") {
			label.set_text(name);
            label.margin_start = label_margin_left;
            label.get_style_context().add_class("preference_label");
            widget.get_style_context().add_class(class_name);
            widget.margin_start = label_margin_left;

            adjust_option_widgets(label, widget);
            grid_attach(grid, label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(grid, widget, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
        
        public void create_follow_key_row(Gtk.Label label, Gtk.Widget widget, string name, Gtk.Label previous_label, Gtk.Grid grid, string class_name="preference_entry") {
			label.set_text(name);
            label.margin_start = label_margin_left;
            label.get_style_context().add_class("preference_label");
            widget.get_style_context().add_class(class_name);
            widget.margin_start = label_margin_left;
            
            adjust_option_widgets(label, widget);
            grid_attach_next_to(grid, label, previous_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid_attach_next_to(grid, widget, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
		
        public void adjust_option_widgets(Gtk.Label name_widget, Gtk.Widget value_widget) {
            name_widget.set_xalign(0);
            name_widget.set_size_request(preference_name_width, grid_height);
            
            value_widget.set_size_request(preference_widget_width, grid_height);
        }
        
        public void grid_attach(Gtk.Grid grid, Gtk.Widget child, int left, int top, int width, int height) {
            child.margin_top = option_widget_margin_top;
            child.margin_bottom = option_widget_margin_end;
            grid.attach(child, left, top, width, height);
        }
        
        public void grid_attach_next_to(Gtk.Grid grid, Gtk.Widget child, Gtk.Widget sibling, Gtk.PositionType side, int width, int height) {
            child.margin_top = option_widget_margin_top;
            child.margin_bottom = option_widget_margin_end;
            grid.attach_next_to(child, sibling, side, width, height);
        }
    }
}