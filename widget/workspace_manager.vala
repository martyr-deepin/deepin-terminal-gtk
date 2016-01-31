using Gtk;
using Widgets;

namespace Widgets {
    public class WorkspaceManager : Gtk.Box {
        public Tabbar tabbar;
        public int workspace_index;
        
        public WorkspaceManager(Tabbar t) {
            tabbar = t;

            workspace_index = 0;
            
            new_workspace();
        }
        
        public void new_workspace() {
            foreach (Widget w in get_children()) {
                this.remove(w);
            }
            
            workspace_index++;
            Widgets.Workspace workspace = new Widgets.Workspace(workspace_index);
            workspace.change_dir.connect((workspace, index, dir) => {
                    tabbar.rename_tab(index, dir);
                });
            pack_start(workspace, true, true, 0);
            
            tabbar.add_tab("", workspace_index);
        }
    }
}