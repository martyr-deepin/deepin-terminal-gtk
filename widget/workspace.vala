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

using Animation;
using Gee;
using Gtk;
using Utils;
using Widgets;

namespace Widgets {
    public class Workspace : Gtk.Overlay {
        public WorkspaceManager workspace_manager;
        public AnimateTimer command_panel_hide_timer;
        public AnimateTimer command_panel_show_timer;
        public AnimateTimer encoding_panel_hide_timer;
        public AnimateTimer encoding_panel_show_timer;
        public AnimateTimer remote_panel_hide_timer;
        public AnimateTimer remote_panel_show_timer;
        public AnimateTimer theme_panel_hide_timer;
        public AnimateTimer theme_panel_show_timer;
        public ArrayList<Term> term_list;
        public CommandPanel? command_panel;
        public EncodingPanel? encoding_panel;
        public RemotePanel? remote_panel;
        public SearchPanel? search_panel;
        public Term? focus_terminal;
        public Term? terminal_before_popup;
        public ThemePanel? theme_panel;
        public HighlightFrame? highlight_frame;
        public int PANED_HANDLE_SIZE = 1;
        public int hide_slider_interval = 500;
        public int hide_slider_start_x;
        public int index;
        public int show_slider_interval = 500;
        public int show_slider_start_x;
        public uint? highlight_frame_timeout_source_id = null;

        private enum WorkspaceResizeKey {
            LEFT, RIGHT, UP, DOWN
        }

        public signal void change_title(int index, string dir);
        public signal void exit(int index);
        public signal void highlight_tab(int index);

        public Workspace(int workspace_index, string? work_directory, WorkspaceManager manager) {
            index = workspace_index;
            term_list = new ArrayList<Term>();
            workspace_manager = manager;

            remote_panel_show_timer = new AnimateTimer(AnimateTimer.ease_out_quint, show_slider_interval);
            remote_panel_show_timer.animate.connect(remote_panel_show_animate);

            remote_panel_hide_timer = new AnimateTimer(AnimateTimer.ease_in_quint, hide_slider_interval);
            remote_panel_hide_timer.animate.connect(remote_panel_hide_animate);

            theme_panel_show_timer = new AnimateTimer(AnimateTimer.ease_out_quint, show_slider_interval);
            theme_panel_show_timer.animate.connect(theme_panel_show_animate);

            theme_panel_hide_timer = new AnimateTimer(AnimateTimer.ease_in_quint, hide_slider_interval);
            theme_panel_hide_timer.animate.connect(theme_panel_hide_animate);

            encoding_panel_show_timer = new AnimateTimer(AnimateTimer.ease_out_quint, show_slider_interval);
            encoding_panel_show_timer.animate.connect(encoding_panel_show_animate);

            encoding_panel_hide_timer = new AnimateTimer(AnimateTimer.ease_in_quint, hide_slider_interval);
            encoding_panel_hide_timer.animate.connect(encoding_panel_hide_animate);

            command_panel_show_timer = new AnimateTimer(AnimateTimer.ease_out_quint, show_slider_interval);
            command_panel_show_timer.animate.connect(command_panel_show_animate);

            command_panel_hide_timer = new AnimateTimer(AnimateTimer.ease_in_quint, hide_slider_interval);
            command_panel_hide_timer.animate.connect(command_panel_hide_animate);

            Term term = new_term(true, work_directory);
            workspace_manager.set_first_term(term);

            add(term);
        }

        public Term new_term(bool first_term, string? work_directory) {
            Term term = new Widgets.Term(first_term, work_directory, workspace_manager);
            term.change_title.connect((term, dir) => {
                    change_title(index, dir);
                });
            term.highlight_tab.connect((term) => {
                    highlight_tab(index);
                });
            term.exit.connect((term) => {
                    remove_all_panels();
                    close_term(term);
                });
            term.exit_with_bad_code.connect((w, status) => {
                    reset_term(status);
                });
            term.term.button_press_event.connect((w, e) => {
                    remove_search_panel();
                    hide_theme_panel();
                    hide_remote_panel();
                    hide_encoding_panel();
                    hide_command_panel();

                    update_focus_terminal(term);

                    return false;
                });

            term_list.add(term);

            return term;
        }

        public void reset_term(int exit_status) {
            Term focus_term = get_focus_term(this);
            string term_dir = focus_term.get_cwd();

            split_vertical();
            close_term(focus_term);

            GLib.Timeout.add(500, () => {
                    if (term_dir.length > 0) {
                        Term new_focus_term = get_focus_term(this);
                        string switch_command = "cd %s\n".printf(term_dir);
                        new_focus_term.term.feed_child(switch_command.to_utf8());
                    }

                    return false;
                });

            print("Reset terminal after got exit status: %i\n", exit_status);
        }

        public bool has_active_term() {
            foreach (Term term in term_list) {
                if (term.has_foreground_process()) {
                    return true;
                }
            }

            return false;
        }

        public void close_focus_term() {
            Term focus_term = get_focus_term(this);
            if (focus_term.has_foreground_process()) {
                ConfirmDialog dialog = Widgets.create_running_confirm_dialog((Widgets.ConfigWindow) focus_term.get_toplevel());
                dialog.confirm.connect((d) => {
                        close_term(focus_term);
                    });
            } else {
                close_term(focus_term);
            }
        }

        public void toggle_select_all() {
            Term focus_term = get_focus_term(this);
            focus_term.toggle_select_all();
        }

        public void close_other_terms() {
            Term focus_term = get_focus_term(this);

            bool has_active_process = false;
            foreach (Term term in term_list) {
                if (term != focus_term) {
                    if (term.has_foreground_process()) {
                        has_active_process = true;

                        break;
                    }
                }
            }

            if (has_active_process) {
                ConfirmDialog dialog = Widgets.create_running_confirm_dialog((Widgets.ConfigWindow) focus_term.get_toplevel());
                dialog.confirm.connect((d) => {
                        close_term_except(focus_term);
                    });
            } else {
                close_term_except(focus_term);
            }
        }

        public void close_term_except(Term except_term) {
            // We need remove term from it's parent before remove all children from workspace.
            Widget parent_widget = except_term.get_parent();
            ((Container) parent_widget).remove(except_term);

            // Destroy all other terminals, wow! ;)
            foreach (Widget w in get_children()) {
                w.destroy();
            }

            // Re-parent except terminal.
            term_list = new ArrayList<Term>();
            term_list.add(except_term);
            add(except_term);
        }

        public void close_term(Term term) {
            Container parent_widget = term.get_parent();
            parent_widget.remove(term);
            term.destroy();
            term_list.remove(term);

            clean_unused_parent(parent_widget);
        }

        public void clean_unused_parent(Gtk.Container container) {
            if (container.get_children().length() == 0) {
                if (container.get_type().is_a(typeof(Workspace))) {
                    exit(index);
                } else {
                    Container parent_widget = container.get_parent();
                    parent_widget.remove(container);
                    container.destroy();

                    clean_unused_parent(parent_widget);
                }
            } else {
                if (container.get_type().is_a(typeof(Paned))) {
                    var first_child = container.get_children().nth_data(0);
                    if (first_child.get_type().is_a(typeof(Paned))) {
                        clean_unused_parent((Paned) first_child);
                    } else {
                        ((Term) first_child).focus_term();
                    }
                }
            }
        }

        public Term get_focus_term(Container container) {
            Widget focus_child = container.get_focus_child();
            if (terminal_before_popup != null) {
                return terminal_before_popup;
            } else if (focus_child.get_type().is_a(typeof(Term))) {
                return (Term) focus_child;
            } else {
                return get_focus_term((Container) focus_child);
            }
        }

        public void split_vertical() {
            // Get current terminal's server info.
            string? split_term_server_info = null;
            Term focus_term = get_focus_term(this);
            if (focus_term.server_info != null && focus_term.login_remote_server) {
                split_term_server_info = focus_term.server_info;
            }

            // Split terminal.
            split(Gtk.Orientation.HORIZONTAL);
            update_focus_terminal(get_focus_term(this));

            // Login server in timeout callback, otherwise login action can't execute.
            if (split_term_server_info != null) {
                GLib.Timeout.add(50, () => {
                        get_focus_term(this).login_server(split_term_server_info);

                        return false;
                    });
            }
        }

        public void split_horizontal() {
            // Get current terminal's server info.
            string? split_term_server_info = null;
            Term focus_term = get_focus_term(this);
            if (focus_term.server_info != null && focus_term.login_remote_server) {
                split_term_server_info = focus_term.server_info;
            }

            // Split terminal.
            split(Gtk.Orientation.VERTICAL);
            update_focus_terminal(get_focus_term(this));

            // Login server in timeout callback, otherwise login action can't execute.
            if (split_term_server_info != null) {
                GLib.Timeout.add(50, () => {
                        get_focus_term(this).login_server(split_term_server_info);

                        return false;
                    });
            }
        }

        public void split(Orientation orientation) {
            Term focus_term = get_focus_term(this);

            // blumia: This fix is a little bit dirty. Here we set the value of `terminal_before_popup` everytime we call split().
            //         Otherwish it will crash at get_focus_term(). Try comment the following line, open up a new terminal window,
            //         and press: Ctrl+Shfit+j > Ctrl+Shfit+q > Ctrl+Shfit+j > Alt+h > Ctrl+Shfit+j > (should crashed now)
            terminal_before_popup = focus_term;

            Gtk.Allocation alloc;
            focus_term.get_allocation(out alloc);

            Widget parent_widget = focus_term.get_parent();
            ((Container) parent_widget).remove(focus_term);
            Paned paned = new Paned(orientation);
            paned.draw.connect((w, cr) => {
                    var paned_widget = (Paned) w;

                    Utils.propagate_draw(paned_widget, cr);

                    Gtk.Allocation rect;
                    w.get_allocation(out rect);

                    int pos = paned_widget.get_position();
                    if (pos != 0 && paned_widget.get_child1() != null && paned_widget.get_child2() != null) {
                        cr.set_operator(Cairo.Operator.OVER);
                        Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) w.get_toplevel();
                        Gdk.RGBA paned_background_color;
                        try {
                            paned_background_color = Utils.hex_to_rgba(
                                parent_window.is_light_theme() ? "#bbbbbb" : "#111111",
                                parent_window.config.config_file.get_double("general", "opacity"));
                            Utils.set_context_color(cr, paned_background_color);
                        } catch (GLib.KeyFileError e) {
                            print("Workapce split: %s\n", e.message);
                        }

                        if (orientation == Gtk.Orientation.HORIZONTAL) {
                            Draw.draw_rectangle(cr, pos, 0, 1, rect.height);
                        } else {
                            Draw.draw_rectangle(cr, 0, pos, rect.width, 1);
                        }

                        cr.set_source_rgba(1, 1, 1, 0.1);
                        if (orientation == Gtk.Orientation.HORIZONTAL) {
                            Draw.draw_rectangle(cr, pos, 0, 1, rect.height);
                        } else {
                            Draw.draw_rectangle(cr, 0, pos, rect.width, 1);
                        }
                    }

                    return true;
                });

            Term term = new_term(false, focus_term.get_cwd());
            paned.pack1(focus_term, true, false);
            paned.pack2(term, true, false);

            if (orientation == Gtk.Orientation.HORIZONTAL) {
                paned.set_position(alloc.width / 2);
            } else {
                paned.set_position(alloc.height / 2);
            }

            if (parent_widget.get_type().is_a(typeof(Workspace))) {
                ((Workspace) parent_widget).add(paned);
            } else if (parent_widget.get_type().is_a(typeof(Paned))) {
                if (focus_term.is_first_term) {
                    ((Paned) parent_widget).pack1(paned, true, false);
                } else {
                    focus_term.is_first_term = true;
                    ((Paned) parent_widget).pack2(paned, true, false);
                }

            }

            this.show_all();
        }

        public void select_left_window() {
            select_horizontal_terminal(true);

            update_focus_terminal(get_focus_term(this));

            highlight_select_window();
        }

        public void select_right_window() {
            select_horizontal_terminal(false);

            update_focus_terminal(get_focus_term(this));

            highlight_select_window();
        }

        public void select_up_window() {
            select_vertical_terminal(true);

            update_focus_terminal(get_focus_term(this));

            highlight_select_window();
        }

        public void select_down_window() {
            select_vertical_terminal(false);

            update_focus_terminal(get_focus_term(this));

            highlight_select_window();
        }

        public void highlight_select_window() {
            try {
                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) this.get_toplevel();
                bool show_highlight_frame = parent_window.config.config_file.get_boolean("advanced", "show_highlight_frame");
                if (show_highlight_frame) {
                    // Get workspace allocation.
                    Gtk.Allocation rect;
                    this.get_allocation(out rect);

                    // Get terminal allocation and coordinate.
                    Term focus_term = get_focus_term(this);

                    int term_x, term_y;
                    focus_term.translate_coordinates(this, 0, 0, out term_x, out term_y);
                    Gtk.Allocation term_rect;
                    focus_term.get_allocation(out term_rect);

                    // Remove temp highlight frame and timeout source id.
                    if (highlight_frame != null) {
                        remove(highlight_frame);
                        highlight_frame = null;
                    }
                    if (highlight_frame_timeout_source_id != null) {
                        GLib.Source.remove(highlight_frame_timeout_source_id);
                        highlight_frame_timeout_source_id = null;
                    }

                    // Create new highlight frame.
                    highlight_frame = new HighlightFrame();
                    highlight_frame.set_size_request(term_rect.width, term_rect.height);
                    highlight_frame.margin_start = term_x;
                    highlight_frame.margin_end = rect.width - term_x - term_rect.width;
                    highlight_frame.margin_top = term_y;
                    highlight_frame.margin_bottom = rect.height - term_y - term_rect.height;
                    add_overlay(highlight_frame);
                    show_all();

                    // Hide highlight frame when timeout finish.
                    highlight_frame_timeout_source_id = GLib.Timeout.add(300, () => {
                            if (highlight_frame != null) {
                                remove(highlight_frame);
                                highlight_frame = null;
                            }

                            highlight_frame_timeout_source_id = null;

                            return false;
                        });
                }
            } catch (GLib.KeyFileError e) {
                print("%s\n", e.message);
            }
        }

        public ArrayList<Term> find_intersects_horizontal_terminals(Gtk.Allocation rect, bool left=true) {
            ArrayList<Term> intersects_terminals = new ArrayList<Term>();
            foreach (Term t in term_list) {
                Gtk.Allocation alloc = Utils.get_origin_allocation(t);

                if (alloc.y < rect.y + rect.height + PANED_HANDLE_SIZE && alloc.y + alloc.height + PANED_HANDLE_SIZE > rect.y) {
                    if (left) {
                        if (alloc.x + alloc.width + PANED_HANDLE_SIZE == rect.x) {
                            intersects_terminals.add(t);
                        }
                    } else {
                        if (alloc.x == rect.x + rect.width + PANED_HANDLE_SIZE) {
                            intersects_terminals.add(t);
                        }
                    }
                }
            }

            return intersects_terminals;
        }

        public void select_horizontal_terminal(bool left=true) {
            Term focus_term = get_focus_term(this);

            Gtk.Allocation rect = Utils.get_origin_allocation(focus_term);
            int y = rect.y;
            int h = rect.height;

            ArrayList<Term> intersects_terminals = find_intersects_horizontal_terminals(rect, left);
            if (intersects_terminals.size > 0) {
                ArrayList<Term> same_coordinate_terminals = new ArrayList<Term>();
                foreach (Term t in intersects_terminals) {
                    Gtk.Allocation alloc = Utils.get_origin_allocation(t);

                    if (alloc.y == y) {
                        same_coordinate_terminals.add(t);
                    }
                }

                if (same_coordinate_terminals.size > 0) {
                    same_coordinate_terminals[0].focus_term();
                } else {
                    ArrayList<Term> bigger_match_terminals = new ArrayList<Term>();
                    foreach (Term t in intersects_terminals) {
                        Gtk.Allocation alloc = Utils.get_origin_allocation(t);;

                        if (alloc.y < y && alloc.y + alloc.height >= y + h) {
                            bigger_match_terminals.add(t);
                        }
                    }

                    if (bigger_match_terminals.size > 0) {
                        bigger_match_terminals[0].focus_term();
                    } else {
                        Term biggest_intersectant_terminal = null;
                        int area = 0;
                        foreach (Term t in intersects_terminals) {
                            Gtk.Allocation alloc = Utils.get_origin_allocation(t);;

                            int term_area = alloc.height + h - (alloc.y - y).abs() - (alloc.y + alloc.height - y - h).abs() / 2;
                            if (term_area > area) {
                                biggest_intersectant_terminal = t;
                            }
                        }

                        if (biggest_intersectant_terminal != null) {
                            biggest_intersectant_terminal.focus_term();
                        }
                    }
                }
            }
        }

        public ArrayList<Term> find_intersects_vertical_terminals(Gtk.Allocation rect, bool up=true) {
            ArrayList<Term> intersects_terminals = new ArrayList<Term>();
            foreach (Term t in term_list) {
                Gtk.Allocation alloc = Utils.get_origin_allocation(t);

                if (alloc.x < rect.x + rect.width + PANED_HANDLE_SIZE && alloc.x + alloc.width + PANED_HANDLE_SIZE > rect.x) {
                    if (up) {
                        if (alloc.y + alloc.height + PANED_HANDLE_SIZE == rect.y) {
                            intersects_terminals.add(t);
                        }
                    } else {
                        if (alloc.y == rect.y + rect.height + PANED_HANDLE_SIZE) {
                            intersects_terminals.add(t);
                        }
                    }
                }
            }

            return intersects_terminals;
        }

        public void select_vertical_terminal(bool up=true) {
            Term focus_term = get_focus_term(this);

            Gtk.Allocation rect = Utils.get_origin_allocation(focus_term);
            int x = rect.x;
            int w = rect.width;

            ArrayList<Term> intersects_terminals = find_intersects_vertical_terminals(rect, up);
            if (intersects_terminals.size > 0) {
                ArrayList<Term> same_coordinate_terminals = new ArrayList<Term>();
                foreach (Term t in intersects_terminals) {
                    Gtk.Allocation alloc = Utils.get_origin_allocation(t);

                    if (alloc.x == x) {
                        same_coordinate_terminals.add(t);
                    }
                }

                if (same_coordinate_terminals.size > 0) {
                    same_coordinate_terminals[0].focus_term();
                } else {
                    ArrayList<Term> bigger_match_terminals = new ArrayList<Term>();
                    foreach (Term t in intersects_terminals) {
                        Gtk.Allocation alloc = Utils.get_origin_allocation(t);;

                        if (alloc.x < x && alloc.x + alloc.width >= x + w) {
                            bigger_match_terminals.add(t);
                        }
                    }

                    if (bigger_match_terminals.size > 0) {
                        bigger_match_terminals[0].focus_term();
                    } else {
                        Term biggest_intersectant_terminal = null;
                        int area = 0;
                        foreach (Term t in intersects_terminals) {
                            Gtk.Allocation alloc = Utils.get_origin_allocation(t);;

                            int term_area = alloc.width + w - (alloc.x - x).abs() - (alloc.x + alloc.width - x - w).abs() / 2;
                            if (term_area > area) {
                                biggest_intersectant_terminal = t;
                            }
                        }

                        if (biggest_intersectant_terminal != null) {
                            biggest_intersectant_terminal.focus_term();
                        }
                    }
                }
            }
        }

        public void search(string search_text="") {
            remove_remote_panel();
            remove_theme_panel();
            remove_encoding_panel();
            remove_command_panel();

            terminal_before_popup = get_focus_term(this);
            if (search_panel == null && terminal_before_popup != null) {

                search_panel = new SearchPanel(((Widgets.ConfigWindow) get_toplevel()), terminal_before_popup, search_text);
                search_panel.quit_search.connect((w) => {
                        remove_search_panel();
                    });
                add_overlay(search_panel);
                show_all();
            }

            search_panel.search_entry.grab_focus();
        }

        public void toggle_remote_panel(Workspace workspace) {
            if (remote_panel == null) {
                show_remote_panel(workspace);
            } else {
                hide_remote_panel();
            }
        }

        public void toggle_command_panel(Workspace workspace) {
            if (command_panel == null) {
                show_command_panel(workspace);
            } else {
                hide_command_panel();
            }
        }

        public void show_remote_panel(Workspace workspace) {
            remove_search_panel();
            remove_theme_panel();
            remove_encoding_panel();
            remove_command_panel();

            if (remote_panel == null) {
                Gtk.Allocation rect;
                get_allocation(out rect);

                remote_panel = new RemotePanel(workspace, workspace_manager);
                remote_panel.set_size_request(Constant.SLIDER_WIDTH, rect.height);
                add_overlay(remote_panel);

                show_all();

                remote_panel.margin_left = rect.width;
                show_slider_start_x = rect.width;
                remote_panel_show_timer.reset();
            }

            terminal_before_popup = get_focus_term(this);
        }

        public void show_command_panel(Workspace workspace) {
            remove_search_panel();
            remove_theme_panel();
            remove_encoding_panel();
            remove_remote_panel();

            if (command_panel == null) {
                Gtk.Allocation rect;
                get_allocation(out rect);

                command_panel = new CommandPanel(workspace, workspace_manager);
                command_panel.set_size_request(Constant.SLIDER_WIDTH, rect.height);
                add_overlay(command_panel);

                show_all();

                command_panel.margin_left = rect.width;
                show_slider_start_x = rect.width;
                command_panel_show_timer.reset();
            }

            terminal_before_popup = get_focus_term(this);
        }

        public void show_encoding_panel(Workspace workspace) {
            remove_search_panel();
            remove_remote_panel();
            remove_theme_panel();
            remove_command_panel();

            if (encoding_panel == null) {
                Gtk.Allocation rect;
                get_allocation(out rect);

                Term focus_term = get_focus_term(this);
                encoding_panel = new EncodingPanel(workspace, workspace_manager, focus_term);
                encoding_panel.set_size_request(Constant.ENCODING_SLIDER_WIDTH, rect.height);
                add_overlay(encoding_panel);

                show_all();

                encoding_panel.margin_left = rect.width;
                show_slider_start_x = rect.width;
                encoding_panel_show_timer.reset();
            }

            terminal_before_popup = get_focus_term(this);
        }

        public void remote_panel_show_animate(double progress) {
            remote_panel.margin_left = (int) (show_slider_start_x - Constant.SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                remote_panel_show_timer.stop();
            }
        }

        public void remote_panel_hide_animate(double progress) {
            remote_panel.margin_left = (int) (hide_slider_start_x + Constant.SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                remote_panel_hide_timer.stop();

                remove_remote_panel();
            }
        }

        public void show_theme_panel(Workspace workspace) {
            remove_search_panel();
            remove_remote_panel();
            remove_encoding_panel();
            remove_command_panel();

            if (theme_panel == null) {
                Gtk.Allocation rect;
                get_allocation(out rect);

                theme_panel = new ThemePanel(workspace, workspace_manager);
                theme_panel.set_size_request(Constant.THEME_SLIDER_WIDTH, rect.height);
                add_overlay(theme_panel);

                show_all();

                theme_panel.margin_left = rect.width;
                show_slider_start_x = rect.width;
                theme_panel_show_timer.reset();
            }

            terminal_before_popup = get_focus_term(this);
        }

        public void theme_panel_show_animate(double progress) {
            theme_panel.margin_left = (int) (show_slider_start_x - Constant.THEME_SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                theme_panel_show_timer.stop();
            }
        }

        public void theme_panel_hide_animate(double progress) {
            theme_panel.margin_left = (int) (hide_slider_start_x + Constant.THEME_SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                theme_panel_hide_timer.stop();

                remove_theme_panel();
            }
        }

        public void command_panel_show_animate(double progress) {
            command_panel.margin_left = (int) (show_slider_start_x - Constant.COMMAND_SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                command_panel_show_timer.stop();
            }
        }

        public void command_panel_hide_animate(double progress) {
            command_panel.margin_left = (int) (hide_slider_start_x + Constant.COMMAND_SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                command_panel_hide_timer.stop();

                remove_command_panel();
            }
        }

        public void encoding_panel_show_animate(double progress) {
            encoding_panel.margin_left = (int) (show_slider_start_x - Constant.ENCODING_SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                encoding_panel_show_timer.stop();
            }
        }

        public void encoding_panel_hide_animate(double progress) {
            encoding_panel.margin_left = (int) (hide_slider_start_x + Constant.ENCODING_SLIDER_WIDTH * progress);

            if (progress >= 1.0) {
                encoding_panel_hide_timer.stop();

                remove_encoding_panel();
            }
        }

        public void update_focus_terminal(Term term) {
            focus_terminal = term;
        }

        public void select_focus_terminal() {
            if (focus_terminal != null) {
                focus_terminal.focus_term();
            }
        }

        private void resize_workspace(Term term, WorkspaceResizeKey key) {
            Paned paned = (Paned) term.get_parent();

            // Trying to find needed paned widget with correct orientation. So for left/right keys paned should have horizontal orientation
            var correct_paned_found = is_paned_correct(paned, key);

            while (paned.get_parent().get_type().is_a(typeof(Paned)) && !correct_paned_found) {
                    paned = (Paned) paned.get_parent();
                    correct_paned_found = is_paned_correct(paned, key);
            }

            if (!correct_paned_found) return;

            int value = 0;
            if (key == WorkspaceResizeKey.LEFT || key == WorkspaceResizeKey.UP)
                value = -20;
            else //key == WorkspaceResizeKey.RIGHT || key == WorkspaceResizeKey.DOWN
                value = 20;

            int pos = paned.get_position() + value;
            paned.set_position(pos);
        }

        private bool is_paned_correct(Paned paned, WorkspaceResizeKey key) {
            return ((key == WorkspaceResizeKey.LEFT || key == WorkspaceResizeKey.RIGHT) && paned.get_orientation() == Gtk.Orientation.HORIZONTAL) 
            ||  ((key == WorkspaceResizeKey.UP || key == WorkspaceResizeKey.DOWN) && paned.get_orientation() == Gtk.Orientation.VERTICAL);
        }

        public void resize_workspace_left() {
            resize_workspace (get_focus_term(this), WorkspaceResizeKey.LEFT);
        }

        public void resize_workspace_right() {
            resize_workspace (get_focus_term(this), WorkspaceResizeKey.RIGHT);
        }

        public void resize_workspace_up() {
            resize_workspace (get_focus_term(this), WorkspaceResizeKey.UP);
        }

        public void resize_workspace_down() {
            resize_workspace (get_focus_term(this), WorkspaceResizeKey.DOWN);
        }

        public void remove_all_panels() {
            remove_search_panel();
            remove_remote_panel();
            remove_theme_panel();
            remove_encoding_panel();
            remove_command_panel();
        }

        public void remove_theme_panel() {
            remove_panel(theme_panel);
            theme_panel = null;
        }

        public void remove_command_panel() {
            remove_panel(command_panel);
            command_panel = null;
        }

        public void remove_encoding_panel() {
            remove_panel(encoding_panel);
            encoding_panel = null;
        }

        public void remove_search_panel() {
            remove_panel(search_panel);
            search_panel = null;
        }

        public void remove_remote_panel() {
            remove_panel(remote_panel);
            remote_panel = null;
        }

        private void remove_panel(Gtk.Widget? panel) {
            if (panel != null) {
                Gtk.Widget? panel_parent = panel.get_parent();
                if (panel_parent != null) {
                    ((Gtk.Container) panel_parent).remove(panel);
                }
                panel.destroy();
            }

            if (terminal_before_popup != null) {
                terminal_before_popup.focus_term();
                terminal_before_popup.term.unselect_all();
                terminal_before_popup = null;
            }
        }

        public void hide_remote_panel() {
            hide_panel(remote_panel, Constant.SLIDER_WIDTH, remote_panel_hide_timer);
        }

        public void hide_encoding_panel() {
            hide_panel(encoding_panel, Constant.ENCODING_SLIDER_WIDTH, encoding_panel_hide_timer);
        }

        public void hide_theme_panel() {
            hide_panel(theme_panel, Constant.THEME_SLIDER_WIDTH, theme_panel_hide_timer);
        }

        public void hide_command_panel() {
            hide_panel(command_panel, Constant.COMMAND_SLIDER_WIDTH, command_panel_hide_timer);
        }

        private void hide_panel(Gtk.Widget? panel, int panel_width, AnimateTimer timer) {
            if (panel != null) {
                Gtk.Allocation rect;
                get_allocation(out rect);

                hide_slider_start_x = rect.width - panel_width;
                timer.reset();
            }
        }
    }
}
