using Gtk;
using Widgets;
using Gee;

namespace Widgets {
    public class WorkspaceManager : Gtk.Box {
        public Tabbar tabbar;
        public int workspace_index;
        public HashMap<int, Workspace> workspace_map;
        
        public WorkspaceManager(Tabbar t) {
            tabbar = t;

            workspace_index = 0;
            workspace_map = new HashMap<int, Workspace>();
            
            new_workspace();
        }
        
        public void new_workspace() {
            Utils.remove_all_children(this);
            
            workspace_index++;
            Widgets.Workspace workspace = new Widgets.Workspace(workspace_index);
            workspace_map.set(workspace_index, workspace);
            workspace.change_dir.connect((workspace, index, dir) => {
                    tabbar.rename_tab(index, dir);
                });
            
            pack_start(workspace, true, true, 0);
            tabbar.add_tab("", workspace_index);
            tabbar.select_tab_with_id(workspace_index);
            
            show_all();
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
            pack_start(workspace, true, true, 0);
            
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
                pack_start(workspace, true, true, 0);
            
                show_all();
            }
        }
    }
}