using Gtk;
using Widgets;

namespace Widgets {
    public class Preference : Gtk.Window {
        public Gtk.Widget focus_widget;
        public int window_width = 540;
        public int window_height = 480;
        public int slidebar_width = 150;
        
        public int preference_name_width = 180;
        public int preference_widget_width = 200;
        public int grid_height = 22;

        public Preference(Gtk.Window window, Gtk.Widget widget) {
            focus_widget = widget;
            
            set_transient_for(window);
            set_default_geometry(window_width, window_height);
            set_resizable(false);
            set_modal(true);
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_width) / 2,
                 y + (window_alloc.height - window_height) / 3);
            
            var titlebar = new Titlebar();
            set_titlebar(titlebar);
            
            titlebar.close_button.button_press_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            var preference_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.add(preference_box);
            
            var slidebar = new PreferenceSlidebar();
            slidebar.set_size_request(slidebar_width, -1);
            preference_box.pack_start(slidebar, false, false, 0);
            
            var scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.set_size_request(window_width - slidebar_width, -1);
            scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            preference_box.pack_start(scrolledwindow, false, false, 0);
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            scrolledwindow.add(box);
            
            var basic_segement = get_first_segement("Basic");
            box.pack_start(basic_segement, false, false, 0);

            var theme_segement = get_second_segement("Theme");
            box.pack_start(theme_segement, false, false, 0);
            
            var theme_grid = new Gtk.Grid();
            box.pack_start(theme_grid, false, false, 0);
            
            var theme_label = new Gtk.Label("Theme:");
            var theme_combox = new Gtk.ComboBox();
            adjust_option_widgets(theme_label, theme_combox);
            theme_grid.attach(theme_label, 0, 0, preference_name_width, grid_height);
            theme_grid.attach_next_to(theme_combox, theme_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            var opacity_grid = new Gtk.Grid();
            box.pack_start(opacity_grid, false, false, 0);
            
            var opacity_label = new Gtk.Label("Opacity:");
            var opacity_progressbar = new Gtk.ProgressBar();
            adjust_option_widgets(opacity_label, opacity_progressbar);
            opacity_grid.attach(opacity_label, 0, 0, preference_name_width, grid_height);
            opacity_grid.attach_next_to(opacity_progressbar, opacity_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            var font_grid = new Gtk.Grid();
            box.pack_start(font_grid, false, false, 0);
            
            var font_label = new Gtk.Label("Font:");
            var font_combox = new Gtk.ComboBox();
            adjust_option_widgets(font_label, font_combox);
            font_grid.attach(font_label, 0, 0, preference_name_width, grid_height);
            font_grid.attach_next_to(font_combox, font_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            var font_size_label = new Gtk.Label("Font size:");
            var font_size_spinbutton = new Gtk.SpinButton(null, 0, 0);
            adjust_option_widgets(font_size_label, font_size_spinbutton);
            font_grid.attach_next_to(font_size_label, font_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            font_grid.attach_next_to(font_size_spinbutton, font_size_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            var cursor_segement = get_second_segement("Cursor");
            box.pack_start(cursor_segement, false, false, 0);
            
            var cursor_grid = new Gtk.Grid();
            box.pack_start(cursor_grid, false, false, 0);
            
            var cursor_style_label = new Gtk.Label("Cursor style:");
            var cursor_style_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var cursor_style_block_button = new Gtk.Button();
            var cursor_style_line_button = new Gtk.Button();
            var cursor_style_underline_button = new Gtk.Button();
            cursor_style_box.pack_start(cursor_style_block_button, false, false, 0);
            cursor_style_box.pack_start(cursor_style_line_button, false, false, 0);
            cursor_style_box.pack_start(cursor_style_underline_button, false, false, 0);
            adjust_option_widgets(cursor_style_label, cursor_style_box);
            cursor_grid.attach(cursor_style_label, 0, 0, preference_name_width, grid_height);
            cursor_grid.attach_next_to(cursor_style_box, cursor_style_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            create_follow_check_row("cursor blink", cursor_style_label, cursor_grid);
            
            var scroll_segement = get_second_segement("Scroll");
            box.pack_start(scroll_segement, false, false, 0);
            
            var scroll_grid = new Gtk.Grid();
            box.pack_start(scroll_grid, false, false, 0);
            
            var scroll_on_key_box = create_check_row("scroll on key", scroll_grid);
            var scroll_on_outoupt_box = create_follow_check_row("scroll on output", scroll_on_key_box, scroll_grid);
            
            var scroll_line_label = new Gtk.Label("Scroll line:");
            var scroll_line_spinbutton = new Gtk.SpinButton(null, 0, 0);
            adjust_option_widgets(scroll_line_label, scroll_line_spinbutton);
            scroll_grid.attach_next_to(scroll_line_label, scroll_on_outoupt_box, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            scroll_grid.attach_next_to(scroll_line_spinbutton, scroll_line_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            var hotkey_segement = get_first_segement("Hotkey");
            box.pack_start(hotkey_segement, false, false, 0);
            
            var terminal_key_segement = get_second_segement("Terminal");
            box.pack_start(terminal_key_segement, false, false, 0);
            
            var terminal_key_grid = new Gtk.Grid();
            box.pack_start(terminal_key_grid, false, false, 0);
            
            var copy_key_label = create_key_row("Copy: ", terminal_key_grid);
            var paste_key_label = create_follow_key_row("Paste: ", copy_key_label, terminal_key_grid);
            var scroll_up_key_label = create_follow_key_row("Scroll up: ", paste_key_label, terminal_key_grid);
            var scroll_down_key_label = create_follow_key_row("Scroll down: ", scroll_up_key_label, terminal_key_grid);
            var search_key_label = create_follow_key_row("Search: ", scroll_down_key_label, terminal_key_grid);
            var zoom_in_key_label = create_follow_key_row("Zoom in: ", search_key_label, terminal_key_grid);
            var zoom_out_key_label = create_follow_key_row("Zoom out: ", zoom_in_key_label, terminal_key_grid);
            create_follow_key_row("Default size: ", zoom_out_key_label, terminal_key_grid);
            
            var workspace_key_segement = get_second_segement("Workspace");
            box.pack_start(workspace_key_segement, false, false, 0);
            
            var workspace_key_grid = new Gtk.Grid();
            box.pack_start(workspace_key_grid, false, false, 0);
            
            var new_workspace_key_label = create_key_row("New workspace: ", workspace_key_grid);
            var close_workspace_key_label = create_follow_key_row("Close workspace: ", new_workspace_key_label, workspace_key_grid);
            var previous_workspace_key_label = create_follow_key_row("Previous workspace: ", close_workspace_key_label, workspace_key_grid);
            var next_workspace_key_label = create_follow_key_row("Next workspace: ", previous_workspace_key_label, workspace_key_grid);
            var split_vertically_key_label = create_follow_key_row("Split vertically: ", next_workspace_key_label, workspace_key_grid);
            var split_horizontally_key_label = create_follow_key_row("Split horizontally: ", split_vertically_key_label, workspace_key_grid);
            var select_up_terminal_key_label = create_follow_key_row("Select up terminal: ", split_horizontally_key_label, workspace_key_grid);
            var select_down_terminal_key_label = create_follow_key_row("Select down terminal: ", select_up_terminal_key_label, workspace_key_grid);
            var select_left_terminal_key_label = create_follow_key_row("Select left terminal: ", select_down_terminal_key_label, workspace_key_grid);
            var select_right_terminal_key_label = create_follow_key_row("Select right terminal: ", select_left_terminal_key_label, workspace_key_grid);
            create_follow_key_row("Close terminal: ", select_right_terminal_key_label, workspace_key_grid);
            
            var advanced_key_segement = get_second_segement("Advanced");
            box.pack_start(advanced_key_segement, false, false, 0);
            
            var advanced_key_grid = new Gtk.Grid();
            box.pack_start(advanced_key_grid, false, false, 0);
            
            var fullscreen_key_label = create_key_row("Fullscreen: ", advanced_key_grid);
            var display_hotkey_terminal_key_label = create_follow_key_row("Display hotkey: ", fullscreen_key_label, advanced_key_grid);
            create_follow_key_row("Remote manage: ", display_hotkey_terminal_key_label, advanced_key_grid);
            
            var about_segement = get_first_segement("About");
            box.pack_start(about_segement, false, false, 0);
            
            var about_widget = new AboutWidget();
            box.pack_start(about_widget, false, false, 0);
            
            var reset_button = new Gtk.Button();
            box.pack_start(reset_button, false, false, 0);
            
            show_all();
        }
        
        public Gtk.Widget get_first_segement(string name) {
            var segement = new Gtk.Label(null);
            segement.set_markup("<big><b>%s</b></big>".printf(name));
            segement.set_xalign(0);
            segement.margin_top = 10;
            segement.margin_end = 5;

            return (Gtk.Widget) segement;
        }

        public Gtk.Widget get_second_segement(string name) {
            var segement = new Gtk.Label(null);
            segement.set_markup("<b>%s</b>".printf(name));
            segement.set_xalign(0);
            segement.margin_left = 5;
            segement.margin_top = 10;
            segement.margin_end = 5;

            return (Gtk.Widget) segement;
        }
        
        public Gtk.Label create_key_row(string name, Gtk.Grid grid) {
            var label = new Gtk.Label(name);
            var entry = new Gtk.Entry();
            adjust_option_widgets(label, entry);
            grid.attach(label, 0, 0, preference_name_width, grid_height);
            grid.attach_next_to(entry, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            return label;
        }
        
        public Gtk.Label create_follow_key_row(string name, Gtk.Label previous_label, Gtk.Grid grid) {
            var label = new Gtk.Label(name);
            var entry = new Gtk.Entry();
            adjust_option_widgets(label, entry);
            grid.attach_next_to(label, previous_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid.attach_next_to(entry, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            return label;
        }
        
        public void adjust_option_widgets(Gtk.Label name_widget, Gtk.Widget value_widget) {
            name_widget.set_xalign(0);
            name_widget.set_size_request(preference_name_width, grid_height);
            name_widget.margin_left = 10;
            name_widget.margin_top = 5;
            name_widget.margin_end = 5;
            
            value_widget.set_size_request(preference_widget_width, grid_height);
            value_widget.margin_top = 5;
            value_widget.margin_end = 5;
            value_widget.margin_right = 10;
        }
        
        public Gtk.Box create_check_row(string name, Gtk.Grid grid) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var checkbutton = new Gtk.CheckButton();
            var label = new Gtk.Label(name);
            adjust_option_checkbutton(label, checkbutton);
            
            box.pack_start(checkbutton, false, false, 0);
            box.pack_start(label, false, false, 0);
            grid.attach(box, 0, 0, preference_name_width, grid_height);
            
            return box;
        }
        
        public Gtk.Box create_follow_check_row(string name, Gtk.Widget previous_widget, Gtk.Grid grid) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var checkbutton = new Gtk.CheckButton();
            var label = new Gtk.Label(name);
            adjust_option_checkbutton(label, checkbutton);
            
            box.pack_start(checkbutton, false, false, 0);
            box.pack_start(label, false, false, 0);
            grid.attach_next_to(box, previous_widget, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            
            return box;
        }
        
        public void adjust_option_checkbutton(Gtk.Label label, Gtk.CheckButton checkbutton) {
            label.margin_top = 5;
            label.margin_end = 5;
            
            checkbutton.margin_left = 10;
            checkbutton.margin_right = 5;
            checkbutton.margin_top = 5;
            checkbutton.margin_end = 5;
        }
    }
}