/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2018 Deepin, Inc.
 *               2011 ~ 2018 Wang Yong
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
    public class CommandDialog : Widgets.Dialog {
        public Gtk.Box box;
        public Gtk.Box command_action_box;
        public Gtk.Box content_box;
        public Widgets.DropdownTextButton backspace_key_box;
        public Widgets.DropdownTextButton del_key_box;
        public Widgets.DropdownTextButton encode_box;
        public Gtk.Grid advanced_grid;
        public Gtk.Widget? focus_widget;
        public Term? focus_term;
        public Widgets.ConfigWindow parent_window;
        public Widgets.Entry command_entry;
        public Widgets.Entry groupname_entry;
        public Widgets.Entry name_entry;
        public Widgets.Entry path_entry;
        public Widgets.Entry port_entry;
        public Widgets.Entry user_entry;
        public Widgets.FileButton file_button;
        public Widgets.PasswordButton password_button;
        public Widgets.ShortcutEntry shortcut_entry;
        public Widgets.TextButton delete_command_button;
        public Widgets.TextButton show_advanced_button;
        public int action_button_margin_top = 20;
        public int font_size = 11;
        public int grid_height = 24;
        public int label_margin_left = 14;
        public int max_command_name_length = 50;
        public int preference_margin_end = 10;
        public int preference_margin_start = 10;
        public int preference_margin_top = 10;
        public int preference_name_margin_left = 10;
        public int preference_name_width = 0;
        public int preference_widget_width = 300;
        public int window_expand_height = 330;
        public string? command_info;

        public signal void add_command(string name,
                                      string command,
                                      string shortcut
                                      );
        public signal void edit_command(string name,
                                       string command,
                                       string shortcut
                                       );

        public signal void delete_command(string name);

        public CommandDialog(Widgets.ConfigWindow window, Term? term, Gtk.Widget? widget, string? info=null, KeyFile? config_file=null) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            set_init_size(480, 320);

            var font_description = new Pango.FontDescription();
            font_description.set_size((int)(font_size * Pango.SCALE));
            int max_width = 0;
            string[] label_names = {_("Name"), _("Content"), _("Shortcuts")};
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
                focus_term = term;
                focus_widget = widget;
                command_info = info;

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

                if (command_info != null) {
                    title_label.set_text(_("Edit Command"));
                } else {
                    title_label.set_text(_("Add Command"));
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

                content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                content_box.set_halign(Gtk.Align.CENTER);
                content_box.margin_start = preference_margin_start;
                content_box.margin_end = preference_margin_end;
                box.pack_start(content_box, false, false, 0);

                var grid = new Gtk.Grid();
                grid.margin_end = label_margin_left;
                content_box.pack_start(grid, false, false, 0);

                // Name.
                Label name_label = new Gtk.Label(null);
                name_entry = new Widgets.Entry();
                if (command_info != null) {
                    name_entry.set_text(command_info);
                }
                name_entry.set_placeholder_text(_("Required"));
                create_key_row(name_label, name_entry, _("Name:"), grid);

                // Command.
                Label command_label = new Gtk.Label(null);
                command_entry = new Widgets.Entry();
                if (command_info != null) {
                    command_entry.set_text(config_file.get_value(command_info, "Command"));
                } else {
                    if (focus_term != null) {
                        command_entry.set_text(focus_term.get_selection_text());
                    }
                }
                command_entry.set_placeholder_text(_("Required"));
                create_follow_key_row(command_label, command_entry, _("Command:"), name_label, grid);

                // Shortcut.
                Label shortcut_label = new Gtk.Label(null);
                shortcut_entry = new Widgets.ShortcutEntry();
                if (command_info != null) {
                    shortcut_entry.set_text(config_file.get_value(command_info, "Shortcut"));
                }
                create_follow_key_row(shortcut_label, shortcut_entry, _("Shortcuts:"), command_label, grid);

                command_action_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                command_action_box.set_size_request(-1, 30);
                content_box.pack_start(command_action_box, false, false, 0);

                if (command_info != null) {
                    add_delete_button();
                }

                Box button_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
                button_box.margin_top = action_button_margin_top;
                DialogButton cancel_button = new Widgets.DialogButton(_("Cancel"), "left", "text", parent_window.screen_monitor.is_composited());
                string button_name;
                if (command_info != null) {
                    button_name = _("Save");
                } else {
                    button_name = _("Add");
                }
                DialogButton confirm_button = new Widgets.DialogButton(button_name, "right", "action", parent_window.screen_monitor.is_composited());
                cancel_button.clicked.connect((b) => {
                        destroy();
                    });
                confirm_button.clicked.connect((b) => {
                        if (command_info != null) {
                            if (name_entry.get_text().strip() != "" && command_entry.get_text().strip() != "") {
                                edit_command(name_entry.get_text(),
                                             command_entry.get_text(),
                                             shortcut_entry.get_text()
                                             );
                            }
                        } else {
                            if (name_entry.get_text().strip() != "" && command_entry.get_text().strip() != "") {
                                add_command(name_entry.get_text(),
                                            command_entry.get_text(),
                                            shortcut_entry.get_text()
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

        public void add_delete_button() {
            delete_command_button = Widgets.create_delete_button(_("Delete command"));
            delete_command_button.clicked.connect((w) => {
                    this.hide();

                    var command_name = name_entry.get_text();
                    if (command_name.length > max_command_name_length) {
                        command_name = command_name.substring(0, max_command_name_length) + " ... ";
                    }

                    var confirm_dialog = new Widgets.ConfirmDialog(
                        _("Delete command"),
                        _("Are you sure you want to delete %s?").printf(command_name),
                        _("Cancel"),
                        _("Delete"));
                    confirm_dialog.transient_for_window(parent_window);
                    confirm_dialog.cancel.connect((w) => {
                            this.destroy();
                        });
                    confirm_dialog.confirm.connect((w) => {
                            delete_command(name_entry.get_text());
                            this.destroy();
                        });
                });

            command_action_box.pack_start(delete_command_button, true, true, 0);

            command_action_box.show_all();
        }

        public Label create_label(string text) {
            Label label = new Gtk.Label(null);
            label.margin_start = label_margin_left;
            label.set_text(text);
            label.get_style_context().add_class("preference_label");
            label.set_xalign(0);

            return label;
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
            // NOTE:
            // set_hexpand is very important to make widget in grid to expand space horizaontally.
            value_widget.set_hexpand(true);
        }
    }
}
