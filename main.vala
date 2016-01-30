using Gtk;
using Gdk;
using Vte;
using Widgets;

private class Application {
    public Gtk.Window window;
    
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
        
        Widgets.Workspace workspace = new Widgets.Workspace();
        
        window.destroy.connect((t) => {
                Gtk.main_quit();
            });
        
        window.window_state_event.connect((w) => {
                titlebar.update_max_button();
                
                return false;
            });
        
        window.set_position(Gtk.WindowPosition.CENTER);
        window.set_titlebar(titlebar);
        window.add(workspace);
        window.show_all();
    }
    
    private static void main(string[] args) {
        Gtk.init(ref args);
        new Application();
        Gtk.main();
    }
}