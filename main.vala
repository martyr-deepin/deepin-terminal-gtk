using Gtk;
using Gdk;
using Vte;
using Widgets;
using Keymap;

private class Application {
    public Gtk.Window window;
    public WorkspaceManager workspace_manager;
    
    private Application() {
        Utils.load_css_theme("style.css");
        
        Gdk.Screen screen = Gdk.Screen.get_default();
        
        window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
        window.set_visual(screen.get_rgba_visual());
        window.set_default_size(screen.get_width() * 2 / 3, screen.get_height() * 2 / 3);
        
        try{
            window.set_icon_from_file("image/deepin-terminal.svg");
        } catch(Error er) {
            stdout.printf(er.message);
        }
        
        Titlebar titlebar = new Titlebar();
        workspace_manager = new WorkspaceManager(titlebar.tabbar); 
        
        titlebar.tabbar.press_tab.connect((t, tab_index, tab_id) => {
                workspace_manager.switch_workspace(tab_id);
            });
        titlebar.tabbar.close_tab.connect((t, tab_index, tab_id) => {
                workspace_manager.remove_workspace(tab_id);
            });
        
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
            
            return true;
        } else if (keyname == "Ctrl + w") {
            workspace_manager.tabbar.close_current_tab();
            
            return true;
        } else if (keyname == "Ctrl + Tab") {
            workspace_manager.tabbar.select_next_tab();
            
            return true;
        } else if (keyname == "Ctrl + ISO_Left_Tab") {
            workspace_manager.tabbar.select_prev_tab();
            
            return true;
        } else if (keyname in ctrl_num_keys) {
            workspace_manager.switch_workspace_with_index(int.parse(Keymap.get_key_name(key_event.keyval)));
            
            return true;
        } else {
            return false;
        }
    }
    
    private static void main(string[] args) {
        Gtk.init(ref args);
        new Application();
        Gtk.main();
    }
}