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

using Gee;
using Gtk;
using Widgets;

namespace Widgets {
    public class WorkspaceManager : Gtk.Box {
        private Widgets.Term? first_term;
        private bool has_first_term_created;
        public HashMap<int, Workspace> workspace_map;
        public Tabbar tabbar;
        public Workspace focus_workspace;
        public int workspace_index;

        public WorkspaceManager(Tabbar t, string? work_directory) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            tabbar = t;

            workspace_index = 0;
            workspace_map = new HashMap<int, Workspace>();

            has_first_term_created = false;

            new_workspace(work_directory);
        }

        public void set_first_term(Widgets.Term term) {
            // Set first terminal to make only first create tab terminal execute -e commands,
            // all terminals created by user's new_tab action won't execute -e commands.
            if (!has_first_term_created) {
                first_term = term;
                has_first_term_created = true;
            }
        }

        public bool is_first_term(Widgets.Term term) {
            if (first_term == null) {
                return true;
            } else {
                return first_term == term;
            }
        }

        public void pack_workspace(Workspace workspace) {
            focus_workspace = workspace;
            pack_start(workspace, true, true, 0);

            workspace.select_focus_terminal();
        }

        public void new_workspace_with_current_directory(bool remote_serve_action=false) {
            Term focus_term = focus_workspace.get_focus_term(this);
            new_workspace(focus_term.get_cwd(), remote_serve_action);
        }

        public void new_workspace(string? work_directory, bool remote_serve_action=false) {
            if (tabbar.allowed_add_tab || remote_serve_action) {
                Utils.remove_all_children(this);

                workspace_index++;

                tabbar.add_tab("", workspace_index);
                Widgets.Workspace workspace = new Widgets.Workspace(workspace_index, work_directory, this);
                workspace_map.set(workspace_index, workspace);
                workspace.change_title.connect((workspace, index, dir) => {
                        tabbar.rename_tab(index, dir);
                    });
                workspace.highlight_tab.connect((workspace, index) => {
                        tabbar.highlight_tab(index);
                    });
                workspace.exit.connect((workspace, index) => {
                        tabbar.close_current_tab();
                    });

                pack_workspace(workspace);

                tabbar.select_tab_with_id(workspace_index);

                show_all();
            } else {
                var config_window = (Widgets.ConfigWindow) get_toplevel();
                if (!config_window.quake_mode) {
                    try {
                        GLib.AppInfo appinfo;
                        if (work_directory != null) {
                            appinfo = GLib.AppInfo.create_from_commandline("deepin-terminal --work-directory=%s".printf(work_directory), null, GLib.AppInfoCreateFlags.NONE);
                        } else {
                            appinfo = GLib.AppInfo.create_from_commandline("deepin-terminal", null, GLib.AppInfoCreateFlags.NONE);
                        }
                        appinfo.launch(null, null);
                    } catch (GLib.Error e) {
                        print("new_workspace: %s\n", e.message);
                    }
                }
            }
        }

        public void switch_workspace_with_index(int index) {
            if (index == 1) {
                tabbar.select_first_tab();
            } else if (index == 9) {
                tabbar.select_end_tab();
            } else if (index > 0 && index <= tabbar.tab_list.size) {
                tabbar.select_nth_tab(index - 1);
            }
        }

        public void switch_workspace(int workspace_index) {
            Utils.remove_all_children(this);

            var workspace = workspace_map.get(workspace_index);
            pack_workspace(workspace);

            show_all();
        }

        public void remove_workspace(int index) {
            workspace_map.get(index).destroy();
            workspace_map.unset(index);

            if (tabbar.tab_list.size == 0) {
                var config_window = (Widgets.ConfigWindow) get_toplevel();
                config_window.quit();
            } else {
                int workspace_index = tabbar.tab_list.get(tabbar.tab_index);
                Utils.remove_all_children(this);

                var workspace = workspace_map.get(workspace_index);
                pack_workspace(workspace);

                show_all();
            }
        }

        public bool has_active_term() {
            foreach (var workspace_entry in workspace_map.entries) {
                if (workspace_entry.value.has_active_term()) {
                    return true;
                }
            }

            return false;
        }
    }
}
