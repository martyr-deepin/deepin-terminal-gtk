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
using Gee;

namespace Widgets {
    public class WorkspaceManager : Gtk.Box {
        public Tabbar tabbar;
        public int workspace_index;
        public HashMap<int, Workspace> workspace_map;
        public Workspace focus_workspace;
        
        public WorkspaceManager(Tabbar t, string[]? commands, string? work_directory) {
            tabbar = t;

            workspace_index = 0;
            workspace_map = new HashMap<int, Workspace>();
            
            new_workspace(commands, work_directory);
        }
        
        public void pack_workspace(Workspace workspace) {
            focus_workspace = workspace;
            pack_start(workspace, true, true, 0);
        }
		
		public void new_workspace_with_current_directory(bool remote_serve_action=false) {
			Term focus_term = focus_workspace.get_focus_term(this);
			new_workspace(null, focus_term.current_dir, remote_serve_action);
		}
        
        public void new_workspace(string[]? commands, string? work_directory, bool remote_serve_action=false) {
            if (tabbar.allowed_add_tab || remote_serve_action) {
                Utils.remove_all_children(this);
            
                workspace_index++;
                
                tabbar.add_tab("", workspace_index);
                Widgets.Workspace workspace = new Widgets.Workspace(workspace_index, commands, work_directory, this);
                workspace_map.set(workspace_index, workspace);
                workspace.change_dir.connect((workspace, index, dir) => {
                        tabbar.rename_tab(index, dir);
                    });
                workspace.highlight_tab.connect((workspace, index) => {
                        tabbar.highlight_tab(index);
                    });
                workspace.exit.connect((workspace, index) => {
                        tabbar.close_current_tab();
                    });
            
                pack_workspace(workspace);
            
			
                // Some shell can't pass working directory to vte terminal. 
                // We check tab name when tab first time add.
                // If tab haven't name, we named with "deepin".
                GLib.Timeout.add(200, () => {
                        if (tabbar.tab_name_map.get(workspace_index) == "") {
                            tabbar.rename_tab(workspace_index, "deepin");
                        }
					
                        return false;
                    });
                tabbar.select_tab_with_id(workspace_index);
            
                show_all();
            } else {
                ConfirmDialog dialog = new ConfirmDialog("Haven't space to add tab", "Please remove unused tab first", "Cancel", "OK");
                dialog.transient_for_window((Widgets.ConfigWindow) (this.get_toplevel()));
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
                Gtk.main_quit();
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