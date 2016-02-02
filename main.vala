using Gtk;
using Gdk;
using Vte;
using Widgets;
using Keymap;

private class Application {
    public Widgets.Window window;
    public WorkspaceManager workspace_manager;
    
    private Application() {
        Utils.load_css_theme("style.css");
        
        Titlebar titlebar = new Titlebar();
        workspace_manager = new WorkspaceManager(titlebar.tabbar); 
        
        titlebar.tabbar.press_tab.connect((t, tab_index, tab_id) => {
                workspace_manager.switch_workspace(tab_id);
            });
        titlebar.tabbar.close_tab.connect((t, tab_index, tab_id) => {
                workspace_manager.remove_workspace(tab_id);
            });
        
        window = new Widgets.Window();
        window.destroy.connect((t) => {
                Gtk.main_quit();
            });
        window.window_state_event.connect((w) => {
                titlebar.update_max_button();
                
                return false;
            });
        window.key_press_event.connect(on_key_press);
        
        window.set_position(Gtk.WindowPosition.CENTER);
        window.set_titlebar(titlebar);
        window.add(workspace_manager);
        window.show_all();
    }
    
    private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
        string keyname = Keymap.get_keyevent_name(key_event);
        string[] ctrl_num_keys = {"Ctrl + 1", "Ctrl + 2", "Ctrl + 3", "Ctrl + 4", "Ctrl + 5", "Ctrl + 6", "Ctrl + 7", "Ctrl + 8", "Ctrl + 9"};
        
        if (keyname == "Ctrl + t") {
            workspace_manager.new_workspace();
        } else if (keyname == "Ctrl + w") {
            workspace_manager.tabbar.close_current_tab();
        } else if (keyname == "Ctrl + Tab") {
            workspace_manager.tabbar.select_next_tab();
        } else if (keyname == "Ctrl + ISO_Left_Tab") {
            workspace_manager.tabbar.select_prev_tab();
        } else if (keyname in ctrl_num_keys) {
            workspace_manager.switch_workspace_with_index(int.parse(Keymap.get_key_name(key_event.keyval)));
        } else if (keyname == "F11") {
            window.toggle_fullscreen();
        } else if (keyname == "Ctrl + h") {
            workspace_manager.split_workspace_horizontal();
        } else if (keyname == "Ctrl + H") {
            workspace_manager.split_workspace_vertical();
        } else {
            return false;
        }
        
        return true;
    }
    
    private static void main(string[] args) {
        Gtk.init(ref args);
        new Application();
        Gtk.main();
    }
}