using Gtk;
using Widgets;
using Gee;
using Animation;

namespace Widgets {
    public class Preference : Widgets.BaseWindow {
        public Gtk.Widget focus_widget;
        public int window_init_width = 780;
        public int window_init_height = 670;
        public int slidebar_width = 160;
        
        public int preference_name_width = 180;
        public int preference_widget_width = 200;
        public int grid_height = 24;
		
		public ScrolledWindow scrolledwindow;
		
		public Widgets.Window parent_window;
		
		public Gtk.Label theme_label;
		public Gtk.ComboBoxText theme_combox;
		public Gtk.Label opacity_label;
		public Widgets.ProgressBar opacity_progressbar;
		public Gtk.Label font_label;
		public Gtk.ComboBoxText font_combox;
		public Gtk.Label window_label;
		public Gtk.ComboBoxText window_combox;
		
		public Gtk.Label copy_key_label;
		public Gtk.Entry copy_key_entry;
		public Gtk.Label paste_key_label;
		public Gtk.Entry paste_key_entry;
		public Gtk.Label search_key_label;
		public Gtk.Entry search_key_entry;
		public Gtk.Label zoom_in_key_label;
		public Gtk.Entry zoom_in_key_entry;
		public Gtk.Label zoom_out_key_label;
		public Gtk.Entry zoom_out_key_entry;
		public Gtk.Label zoom_reset_key_label;
		public Gtk.Entry zoom_reset_key_entry;
		public Gtk.Label select_all_key_label;
		public Gtk.Entry select_all_key_entry;
		public Gtk.Label new_workspace_key_label;
		public Gtk.Entry new_workspace_key_entry;
		public Gtk.Label close_workspace_key_label;
		public Gtk.Entry close_workspace_key_entry;
		public Gtk.Label previous_workspace_key_label;
		public Gtk.Entry previous_workspace_key_entry;
		public Gtk.Label next_workspace_key_label;
		public Gtk.Entry next_workspace_key_entry;
		public Gtk.Label split_vertically_key_label;
		public Gtk.Entry split_vertically_key_entry;
		public Gtk.Label split_horizontally_key_label;
		public Gtk.Entry split_horizontally_key_entry;
		public Gtk.Label select_up_window_key_label;
		public Gtk.Entry select_up_window_key_entry;
		public Gtk.Label select_down_window_key_label;
		public Gtk.Entry select_down_window_key_entry;
		public Gtk.Label select_left_window_key_label;
		public Gtk.Entry select_left_window_key_entry;
		public Gtk.Label select_right_window_key_label;
		public Gtk.Entry select_right_window_key_entry;
		public Gtk.Label close_window_key_label;
		public Gtk.Entry close_window_key_entry;
		public Gtk.Label close_other_windows_key_label;
		public Gtk.Entry close_other_windows_key_entry;
		public Gtk.Label fullscreen_key_label;
		public Gtk.Entry fullscreen_key_entry;
		public Gtk.Label display_hotkey_terminal_key_label;
		public Gtk.Entry display_hotkey_terminal_key_entry;
		public Gtk.Label show_remote_manage_key_label;
		public Gtk.Entry show_remote_manage_key_entry;
		
		public Gtk.Label cursor_style_label;
		public Widgets.CursorToggleButton cursor_style_button;
		
		public Widgets.CheckButton cursor_blink_checkbutton;
		public Widgets.CheckButton scroll_on_key_checkbutton;
		public Widgets.CheckButton scroll_on_out_checkbutton;
		
		public Gtk.SpinButton font_size_spinbutton;
		public Gtk.SpinButton scroll_line_spinbutton;
		
		AnimateTimer timer;
		double timer_start_value;
		double timer_end_value;
		
		ArrayList<string> font_names;
		ArrayList<string> window_state_list;

        public Preference(Gtk.Window window, Gtk.Widget widget) {
			theme_label = create_label();
			theme_combox = create_combox_text();
            opacity_label = create_label("Opacity:");
            opacity_progressbar = new Widgets.ProgressBar(opacity);
			font_label = create_label();
			font_combox = create_combox_text();
			window_label = create_label();
			window_combox = create_combox_text();
			
			copy_key_label = create_label();
			copy_key_entry = create_entry();
			paste_key_label = create_label();
			paste_key_entry = create_entry();
			search_key_label = create_label();
			search_key_entry = create_entry();
			zoom_in_key_label = create_label();
			zoom_in_key_entry = create_entry();
			zoom_out_key_label = create_label();
			zoom_out_key_entry = create_entry();
			zoom_reset_key_label = create_label();
			zoom_reset_key_entry = create_entry();
			select_all_key_label = create_label();
			select_all_key_entry = create_entry();
			new_workspace_key_label = create_label();
			new_workspace_key_entry = create_entry();
			close_workspace_key_label = create_label();
			close_workspace_key_entry = create_entry();
			previous_workspace_key_label = create_label();
			previous_workspace_key_entry = create_entry();
			next_workspace_key_label = create_label();
			next_workspace_key_entry = create_entry();
			split_vertically_key_label = create_label();
			split_vertically_key_entry = create_entry();
			split_horizontally_key_label = create_label();
			split_horizontally_key_entry = create_entry();
			select_up_window_key_label = create_label();
			select_up_window_key_entry = create_entry();
			select_down_window_key_label = create_label();
			select_down_window_key_entry = create_entry();
			select_left_window_key_label = create_label();
			select_left_window_key_entry = create_entry();
			select_right_window_key_label = create_label();
			select_right_window_key_entry = create_entry();
			close_window_key_label = create_label();
			close_window_key_entry = create_entry();
			close_other_windows_key_label = create_label();
			close_other_windows_key_entry = create_entry();
			fullscreen_key_label = create_label();
			fullscreen_key_entry = create_entry();
			display_hotkey_terminal_key_label = create_label();
			display_hotkey_terminal_key_entry = create_entry();
			show_remote_manage_key_label = create_label();
			show_remote_manage_key_entry = create_entry();
			
            cursor_style_label = create_label("Cursor style:");
			cursor_style_button = new Widgets.CursorToggleButton();
			cursor_blink_checkbutton = create_checkbutton();
			scroll_on_key_checkbutton = create_checkbutton();
			scroll_on_out_checkbutton = create_checkbutton();
			
			font_size_spinbutton = create_spinbutton(0, 100, 1);
			scroll_line_spinbutton = create_spinbutton(0, 100, 1);
			
            parent_window = (Widgets.Window) window;
            
            focus_widget = widget;
            
            set_transient_for(window);
            set_default_geometry(window_init_width, window_init_height);
            set_resizable(false);
            set_modal(true);
			set_type_hint(Gdk.WindowTypeHint.DIALOG);  // DIALOG hint will give right window effect
            
            Gdk.Window gdk_window = window.get_window();
            int x, y;
            gdk_window.get_root_origin(out x, out y);
            Gtk.Allocation window_alloc;
            window.get_allocation(out window_alloc);
            
            move(x + (window_alloc.width - window_init_width) / 2,
                 y + (window_alloc.height - window_init_height) / 3);
            
            var titlebar = new Titlebar();
            titlebar.close_button.button_release_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(titlebar, false, false, 0);
            
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            var preference_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            add_widget(preference_box);
            
            var slidebar = new PreferenceSlidebar();
			preference_box.pack_start(slidebar, false, false, 0);
            preference_box.set_size_request(slidebar_width, -1);
			
            scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            scrolledwindow.get_style_context().add_class("scrolledwindow");
            scrolledwindow.get_vscrollbar().get_style_context().add_class("preference_scrollbar");
            box.pack_start(scrolledwindow, true, true, 0);
            
            preference_box.pack_start(box, true, true, 0);
            var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            scrolledwindow.add(content_box);
			
            var basic_segement = get_first_segement("Basic");
            content_box.pack_start(basic_segement, false, false, 0);

            var theme_segement = get_second_segement("Theme");
            content_box.pack_start(theme_segement, false, false, 0);
            
            var theme_grid = new Gtk.Grid();
            content_box.pack_start(theme_grid, false, false, 0);
            
            create_theme_row(theme_label, theme_combox, "Theme:", theme_grid, parent_window.config.theme_names, "general", "theme");
            
            var opacity_grid = new Gtk.Grid();
            content_box.pack_start(opacity_grid, false, false, 0);
            
			double opacity = 0;
			try {
				opacity = parent_window.config.config_file.get_double("general", "opacity");
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
			
			opacity_progressbar.set_percent(opacity);
			opacity_progressbar.update.connect((w, percent) => {
					parent_window.config.config_file.set_double("general", "opacity", percent);
					parent_window.config.save();
					
					parent_window.config.update();
				});
			adjust_option_widgets(opacity_label, opacity_progressbar);
            grid_attach(opacity_grid, opacity_label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(opacity_grid, opacity_progressbar, opacity_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            var font_grid = new Gtk.Grid();
            content_box.pack_start(font_grid, false, false, 0);
            
			int num;
			string[] mono_fonts = (string[]) list_mono_fonts(out num);
			font_names = new ArrayList<string>();
			for (int i = 0; i < num; i++) {
				font_names.add(mono_fonts[i]);
			}
			
            create_combox_row(font_label, font_combox, "Font:", font_grid, font_names, "general", "font");
            
            create_follow_spinbutton_row(font_size_spinbutton, "Font size:", font_label, font_grid, "general", "font_size");
            
            var hotkey_segement = get_first_segement("Hotkey");
            content_box.pack_start(hotkey_segement, false, false, 0);
            
            var terminal_key_segement = get_second_segement("Terminal");
            content_box.pack_start(terminal_key_segement, false, false, 0);
            
            var terminal_key_grid = new Gtk.Grid();
            content_box.pack_start(terminal_key_grid, false, false, 0);
            
            create_key_row(copy_key_label, copy_key_entry, "Copy: ", terminal_key_grid, "keybind", "copy_clipboard");
            create_follow_key_row(paste_key_label, paste_key_entry, "Paste: ", copy_key_label, terminal_key_grid, "keybind", "paste_clipboard");
			create_follow_key_row(search_key_label, search_key_entry, "Search: ", paste_key_label, terminal_key_grid, "keybind", "search");
            create_follow_key_row(zoom_in_key_label, zoom_in_key_entry, "Zoom in: ", search_key_label, terminal_key_grid, "keybind", "zoom_in");
            create_follow_key_row(zoom_out_key_label, zoom_out_key_entry, "Zoom out: ", zoom_in_key_label, terminal_key_grid, "keybind", "zoom_out");
            create_follow_key_row(zoom_reset_key_label, zoom_reset_key_entry, "Default size: ", zoom_out_key_label, terminal_key_grid, "keybind", "revert_default_size");
            create_follow_key_row(select_all_key_label, select_all_key_entry, "Select all", zoom_reset_key_label, terminal_key_grid, "keybind", "select_all");
            
            var workspace_key_segement = get_second_segement("Workspace");
            content_box.pack_start(workspace_key_segement, false, false, 0);
            
            var workspace_key_grid = new Gtk.Grid();
            content_box.pack_start(workspace_key_grid, false, false, 0);
            
            create_key_row(new_workspace_key_label, new_workspace_key_entry, "New workspace: ", workspace_key_grid, "keybind", "new_workspace");
            create_follow_key_row(close_workspace_key_label, close_workspace_key_entry, "Close workspace: ", new_workspace_key_label, workspace_key_grid, "keybind", "close_workspace");
            create_follow_key_row(previous_workspace_key_label, previous_workspace_key_entry, "Previous workspace: ", close_workspace_key_label, workspace_key_grid, "keybind", "previous_workspace");
            create_follow_key_row(next_workspace_key_label, next_workspace_key_entry, "Next workspace: ", previous_workspace_key_label, workspace_key_grid, "keybind", "next_workspace");
            create_follow_key_row(split_vertically_key_label, split_vertically_key_entry, "Split vertically: ", next_workspace_key_label, workspace_key_grid, "keybind", "split_vertically");
            create_follow_key_row(split_horizontally_key_label, split_horizontally_key_entry, "Split horizontally: ", split_vertically_key_label, workspace_key_grid, "keybind", "split_horizontally");
            create_follow_key_row(select_up_window_key_label, select_up_window_key_entry, "Select up window: ", split_horizontally_key_label, workspace_key_grid, "keybind", "select_up_window");
            create_follow_key_row(select_down_window_key_label, select_down_window_key_entry, "Select down window: ", select_up_window_key_label, workspace_key_grid, "keybind", "select_down_window");
            create_follow_key_row(select_left_window_key_label, select_left_window_key_entry, "Select left window: ", select_down_window_key_label, workspace_key_grid, "keybind", "select_left_window");
            create_follow_key_row(select_right_window_key_label, select_right_window_key_entry, "Select right window: ", select_left_window_key_label, workspace_key_grid, "keybind", "select_right_window");
            create_follow_key_row(close_window_key_label, close_window_key_entry, "Close focus window: ", select_right_window_key_label, workspace_key_grid, "keybind", "close_window");
            create_follow_key_row(close_other_windows_key_label, close_other_windows_key_entry, "Close other window: ", close_window_key_label, workspace_key_grid, "keybind", "close_other_windows");
            
            var advanced_key_segement = get_second_segement("Advanced");
            content_box.pack_start(advanced_key_segement, false, false, 0);
            
            var advanced_key_grid = new Gtk.Grid();
            content_box.pack_start(advanced_key_grid, false, false, 0);
            
            create_key_row(fullscreen_key_label, fullscreen_key_entry, "Fullscreen: ", advanced_key_grid, "keybind", "toggle_fullscreen");
            create_follow_key_row(display_hotkey_terminal_key_label, display_hotkey_terminal_key_entry, "Display hotkey: ", fullscreen_key_label, advanced_key_grid, "keybind", "show_helper_window");
            create_follow_key_row(show_remote_manage_key_label, show_remote_manage_key_entry, "Remote manage: ", display_hotkey_terminal_key_label, advanced_key_grid, "keybind", "show_remote_panel");
            
            var advanced_segement = get_first_segement("Advanced");
            content_box.pack_start(advanced_segement, false, false, 0);
            
            var cursor_segement = get_second_segement("Cursor");
            content_box.pack_start(cursor_segement, false, false, 0);
            
            var cursor_grid = new Gtk.Grid();
            content_box.pack_start(cursor_grid, false, false, 0);
            
            
			try {
				cursor_style_button.set_cursor_state(parent_window.config.config_file.get_string("advanced", "cursor_shape"));
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
			cursor_style_button.change_cursor_state.connect((w, active_state) => {
					parent_window.config.config_file.set_string("advanced", "cursor_shape", active_state);
					parent_window.config.save();
					
					parent_window.config.update();
				});
			adjust_option_widgets(cursor_style_label, cursor_style_button);
            grid_attach(cursor_grid, cursor_style_label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(cursor_grid, cursor_style_button, cursor_style_label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            create_follow_check_row(cursor_blink_checkbutton, "cursor blink", cursor_style_label, cursor_grid, "advanced", "cursor_blink_mode");
            
            var scroll_segement = get_second_segement("Scroll");
            content_box.pack_start(scroll_segement, false, false, 0);
            
            var scroll_grid = new Gtk.Grid();
            content_box.pack_start(scroll_grid, false, false, 0);
            
            var scroll_on_key_box = create_check_row(scroll_on_key_checkbutton, "scroll on key", scroll_grid, "advanced", "scroll_on_key");
            var scroll_on_output_box = create_follow_check_row(scroll_on_out_checkbutton, "scroll on output", scroll_on_key_box, scroll_grid, "advanced", "scroll_on_output");
            
            create_follow_spinbutton_row(scroll_line_spinbutton, "Scroll line:", scroll_on_output_box, scroll_grid, "advanced", "scroll_line");
            
            var window_segement = get_second_segement("Window");
            content_box.pack_start(window_segement, false, false, 0);
            
            var window_grid = new Gtk.Grid();
            content_box.pack_start(window_grid, false, false, 0);
            
            window_state_list = new ArrayList<string>();
            window_state_list.add("window");
            window_state_list.add("maximize");
            window_state_list.add("fullscreen");
            create_combox_row(window_label, window_combox, "Window", window_grid, window_state_list, "advanced", "window_state");
            
            var about_segement = get_first_segement("About");
            content_box.pack_start(about_segement, false, false, 0);
            
            var about_widget = new AboutWidget();
            about_widget.margin_top = 10;
            content_box.pack_start(about_widget, false, false, 0);
            
            var reset_button = new Widgets.ImageButton("reset_button", "reset");
            reset_button.margin_start = 100;
            reset_button.margin_top = 10;
            reset_button.margin_bottom = 35;
			reset_button.button_release_event.connect((w, e) => {
					parent_window.config.init_config();
					parent_window.config.update();
			
					init_config();
					
					return false;
				});
            content_box.pack_start(reset_button, false, false, 0);
            
			timer = new AnimateTimer(AnimateTimer.ease_in_out, 400);
			timer.animate.connect(on_animate);
			slidebar.click_item.connect((w, item) => {
					if (item == "basic") {
						scroll_to_widget(scrolledwindow, box, basic_segement);
					} else if (item == "theme") {
						scroll_to_widget(scrolledwindow, box, theme_segement);
					} else if (item == "hotkey") {
						scroll_to_widget(scrolledwindow, box, hotkey_segement);
					} else if (item == "temrinal_key") {
						scroll_to_widget(scrolledwindow, box, terminal_key_segement);
					} else if (item == "workspace_key") {
						scroll_to_widget(scrolledwindow, box, workspace_key_segement);
					} else if (item == "advanced_key") {
						scroll_to_widget(scrolledwindow, box, advanced_key_segement);
					} else if (item == "advanced") {
						scroll_to_widget(scrolledwindow, box, advanced_segement);
					} else if (item == "cursor") {
						scroll_to_widget(scrolledwindow, box, cursor_segement);
					} else if (item == "scroll") {
						scroll_to_widget(scrolledwindow, box, scroll_segement);
					} else if (item == "window") {
						scroll_to_widget(scrolledwindow, box, window_segement);
					} else if (item == "about") {
						scroll_to_widget(scrolledwindow, box, about_segement);
					}
				});
            
            show_all();
        }
		
		public void init_config() {
			try {
				theme_combox.set_active(parent_window.config.theme_names.index_of(parent_window.config.config_file.get_value("general", "theme")));
				opacity_progressbar.set_percent(parent_window.config.config_file.get_double("general", "opacity"));
				font_combox.set_active(font_names.index_of(parent_window.config.config_file.get_value("general", "font")));
				window_combox.set_active(window_state_list.index_of(parent_window.config.config_file.get_value("advanced", "window_state")));
		    
				copy_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "copy_clipboard"));
				paste_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "paste_clipboard"));
				search_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "search"));
				zoom_in_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "zoom_in"));
				zoom_out_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "zoom_out"));
				zoom_reset_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "revert_default_size"));
				select_all_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "select_all"));
				new_workspace_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "new_workspace"));
				close_workspace_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "close_workspace"));
				previous_workspace_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "previous_workspace"));
				next_workspace_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "next_workspace"));
				split_vertically_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "split_vertically"));
				split_horizontally_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "split_horizontally"));
				select_up_window_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "select_up_window"));
				select_down_window_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "select_down_window"));
				select_left_window_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "select_left_window"));
				select_right_window_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "select_right_window"));
				close_window_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "close_window"));
				close_other_windows_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "close_other_windows"));
				fullscreen_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "toggle_fullscreen"));
				display_hotkey_terminal_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "show_helper_window"));
				show_remote_manage_key_entry.set_text(parent_window.config.config_file.get_string("keybind", "show_remote_panel"));
		    
				cursor_style_button.set_cursor_state(parent_window.config.config_file.get_string("advanced", "cursor_shape"));;
		    
				cursor_blink_checkbutton.set_active(parent_window.config.config_file.get_boolean("advanced", "cursor_blink_mode"));
				scroll_on_key_checkbutton.set_active(parent_window.config.config_file.get_boolean("advanced", "scroll_on_key"));
				scroll_on_out_checkbutton.set_active(parent_window.config.config_file.get_boolean("advanced", "scroll_on_output"));
		    
				font_size_spinbutton.set_value(parent_window.config.config_file.get_integer("general", "font_size"));
				scroll_line_spinbutton.set_value(parent_window.config.config_file.get_integer("advanced", "scroll_line"));
			} catch (GLib.KeyFileError e) {
				print(e.message);
			}
			
		}
		
		public void scroll_to_widget(ScrolledWindow scrolledwindow, Gtk.Box box, Gtk.Widget widget) {
			int widget_x, widget_y;
			box.translate_coordinates(widget, 0, 0, out widget_x, out widget_y);
			
			var adjust = scrolledwindow.get_vadjustment();
			timer_start_value= adjust.get_value();
			timer_end_value = Math.fabs(widget_y + 40);
			
			timer.reset();
		}
		
		public void on_animate(double progress) {
			var adjust = scrolledwindow.get_vadjustment();
			adjust.set_value(timer_start_value + (timer_end_value - timer_start_value) * progress);
			
			if (progress >= 1.0) {
				timer.stop();
			}
		}
		
		public Gtk.Widget get_first_segement(string name) {
            var segement = create_label();
            segement.set_markup("<span size='%i'>%s</span>".printf((int) (14 * Pango.SCALE), name));
            segement.set_xalign(0);
            
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start(segement, false, false, 0);
            
            var line = new Gtk.EventBox();
            line.margin_start = 2;
            line.draw.connect((w, cr) => {
                    Gtk.Allocation rect;
                    this.get_allocation(out rect);
            
                    cr.set_source_rgba(0, 0, 0, 0.1);
                    Draw.draw_rectangle(cr, 0, 12, rect.width, 1);
            
                    return true;
                });
            box.pack_start(line, true, true, 0);
            
            box.margin_top = 10;
            box.margin_bottom = 5;
            box.margin_start = 20;
            box.margin_end = 20;

            return (Gtk.Widget) box;
        }

        public Gtk.Widget get_second_segement(string name) {
            var segement = create_label();
            segement.set_markup("<span size='%i'>%s</span>".printf((int) (12 * Pango.SCALE), name));
            segement.set_xalign(0);
            segement.margin_top = 10;
            segement.margin_start = 30;
            segement.margin_bottom = 5;

            return (Gtk.Widget) segement;
        }
        
        public void create_key_row(Gtk.Label label, Gtk.Entry entry, string name, Gtk.Grid grid, string? group_name=null, string? key=null) {
			label.set_text(name);

			monitor_check_key(entry, group_name, key);
			
            adjust_option_widgets(label, entry);
            grid_attach(grid, label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(grid, entry, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
        
        public void create_follow_key_row(Gtk.Label label, Gtk.Entry entry, string name, Gtk.Label previous_label, Gtk.Grid grid, string? group_name=null, string? key=null) {
			label.set_text(name);
            
			monitor_check_key(entry, group_name, key);
			
            adjust_option_widgets(label, entry);
            grid_attach_next_to(grid, label, previous_label, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid_attach_next_to(grid, entry, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
		
		public void monitor_check_key(Gtk.Entry entry, string group_name, string key) {
			entry.placeholder_text = "Please input keystroke";
			entry.editable = false;
			entry.key_press_event.connect((w, e) => {
					string keyname = Keymap.get_keyevent_name(e);
					
					if (keyname == "Backspace") {
						entry.set_text("");
					} else if (keyname.has_prefix("F") || keyname.contains("+")) {
						entry.set_text(keyname);
					} else {
						return false;
					}
					
					parent_window.config.config_file.set_string(group_name, key, keyname);
					parent_window.config.save();
					
					parent_window.config.update();
					
					return false;
				});
			
			if (group_name != null && key != null) {
				try {
					entry.set_text(parent_window.config.config_file.get_string(group_name, key));
				} catch (GLib.KeyFileError e) {
					print(e.message);
				}
			}
		}
        
        public void create_theme_row(Gtk.Label label, Gtk.ComboBoxText combox, string name, Gtk.Grid grid, ArrayList<string>? values=null, string? group_name=null, string? key=null) {
			label.set_text(name);
			if (values != null) {
                foreach (string value in values) {
                    combox.append(value, value);
                }
                
                try {
                    combox.set_active(values.index_of(parent_window.config.config_file.get_value(group_name, key)));
                } catch (GLib.KeyFileError e) {
                    print("create_theme_row error: %s\n".printf(e.message));
                }
                
                combox.changed.connect((w) => {
						try {
							var old_theme = parent_window.config.config_file.get_string(group_name, key);
							var new_theme = values[combox.get_active()];
							if (new_theme != old_theme) {
								parent_window.config.config_file.set_string(group_name, key, values[combox.get_active()]);
								parent_window.config.set_theme(new_theme);
							
								parent_window.config.save();
							
								parent_window.config.update();
							}
						} catch (GLib.KeyFileError e) {
							print(e.message);
						}
                    });
            }
            adjust_option_widgets(label, combox);
            grid_attach(grid, label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(grid, combox, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}
		
        public void create_combox_row(Gtk.Label label, Gtk.ComboBoxText combox, string name, Gtk.Grid grid, ArrayList<string>? values=null, string? group_name=null, string? key=null) {
			label.set_text(name);
			if (values != null) {
                foreach (string value in values) {
                    combox.append(value, value);
                }
                
                try {
                    combox.set_active(values.index_of(parent_window.config.config_file.get_value(group_name, key)));
                } catch (GLib.KeyFileError e) {
                    print("create_combox_row error: %s\n".printf(e.message));
                }
                
                combox.changed.connect((w) => {
                        parent_window.config.config_file.set_string(group_name, key, values[combox.get_active()]);
                        parent_window.config.save();
						
						parent_window.config.update();
                    });
            }
            adjust_option_widgets(label, combox);
            grid_attach(grid, label, 0, 0, preference_name_width, grid_height);
            grid_attach_next_to(grid, combox, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
		}

        public void adjust_option_widgets(Gtk.Label name_widget, Gtk.Widget value_widget) {
            name_widget.set_xalign(0);
            name_widget.set_size_request(preference_name_width, grid_height);
            name_widget.margin_start = 40;
            name_widget.margin_top = 5;
            name_widget.margin_bottom = 5;
            
            value_widget.set_size_request(preference_widget_width, grid_height);
            value_widget.margin_top = 5;
            value_widget.margin_bottom = 5;
            value_widget.margin_end = 10;
        }
        
        public Gtk.Box create_check_row(Widgets.CheckButton checkbutton, string name, Gtk.Grid grid, string? group_name=null, string? key=null) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var label = create_label(name);
            adjust_option_checkbutton(label, checkbutton);

            read_check_value(checkbutton, group_name, key);
            
            box.pack_start(checkbutton, false, false, 0);
            box.pack_start(label, false, false, 0);
            grid_attach(grid, box, 0, 0, preference_name_width, grid_height);
            
            return box;
        }
        
        public Gtk.Box create_follow_check_row(Widgets.CheckButton checkbutton, string name, Gtk.Widget previous_widget, Gtk.Grid grid, string? group_name=null, string? key=null) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			var label = create_label(name);
            adjust_option_checkbutton(label, checkbutton);
            
            read_check_value(checkbutton, group_name, key);
            
            box.pack_start(checkbutton, false, false, 0);
            box.pack_start(label, false, false, 0);
            grid_attach_next_to(grid, box, previous_widget, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            
            return box;
        }
        
        public void read_check_value(Widgets.CheckButton checkbutton, string group_name, string key) {
            if (group_name != null && key != null) {
                try {
                    checkbutton.set_active(parent_window.config.config_file.get_boolean(group_name, key));
                } catch (GLib.KeyFileError e) {
                    print("create_follow_check_row error: %s\n".printf(e.message));
                }
                
                monitor_check_value(checkbutton, group_name, key);
            }
        }
        
        public Gtk.Label create_follow_spinbutton_row(Gtk.SpinButton spinbutton, string name, Gtk.Widget previous_widget, Gtk.Grid grid, string? group_name=null, string? key=null) {
            var label = create_label(name);
            adjust_option_widgets(label, spinbutton);
            
            read_spin_value(spinbutton, group_name, key);
            
            grid_attach_next_to(grid, label, previous_widget, Gtk.PositionType.BOTTOM, preference_name_width, grid_height);
            grid_attach_next_to(grid, spinbutton, label, Gtk.PositionType.RIGHT, preference_widget_width, grid_height);
            
            return label;
        }
        
        public void read_spin_value(Gtk.SpinButton spinbutton, string group_name, string key) {
            if (group_name != null && key != null) {
                try {
                    spinbutton.set_value(parent_window.config.config_file.get_integer(group_name, key));
                } catch (GLib.KeyFileError e) {
                    print("read_spin_value error: %s\n".printf(e.message));
                }
                
                monitor_spin_value(spinbutton, group_name, key);
            }
        }
        
        public void monitor_check_value(Widgets.CheckButton checkbutton, string group_name, string key) {
            checkbutton.toggled.connect((w) => {
                    var is_active = checkbutton.get_active();
                    
                    parent_window.config.config_file.set_boolean(group_name, key, is_active);
                    parent_window.config.save();
                    
                    parent_window.config.update();
                });
        }

        public void monitor_spin_value(Gtk.SpinButton spinbutton, string group_name, string key) {
            spinbutton.value_changed.connect((w) => {
                    var spin_value = spinbutton.get_value();
                    
                    parent_window.config.config_file.set_integer(group_name, key, (int) spin_value);
                    parent_window.config.save();
                    
                    parent_window.config.update();
                });
        }
        
        public void adjust_option_checkbutton(Gtk.Label label, Widgets.CheckButton checkbutton) {
            label.margin_top = 5;
            label.margin_bottom = 5;
            
            checkbutton.margin_start = 40;
            checkbutton.margin_end = 5;
            checkbutton.margin_top = 5;
            checkbutton.margin_bottom = 5;
        }
        
        public override void draw_window_below(Cairo.Context cr) {
            Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_start, window_frame_margin_top, window_rect.width, window_rect.height, 5);
        }
        
        public Gtk.Entry create_entry() {
            var entry = new Gtk.Entry();
            entry.get_style_context().add_class("preference_entry");
            
            return entry;
        }
        
        public Gtk.ComboBoxText create_combox_text() {
            var combox = new Gtk.ComboBoxText();
            combox.get_style_context().add_class("preference_comboboxtext");
            
            return combox;
        }
        
        public Gtk.SpinButton create_spinbutton(int min, int max, int step) {
            var spinbutton = new Gtk.SpinButton.with_range(min, max, step);
            spinbutton.get_style_context().add_class("preference_spinbutton");
            
            return spinbutton;
        }

        public Widgets.CheckButton create_checkbutton() {
            var checkbutton = new Widgets.CheckButton();
            
            return checkbutton;
        }
        
        public Gtk.Label create_label(string? text=null) {
            var label = new Gtk.Label(text);
            label.get_style_context().add_class("preference_label");
            
            return label;
        }
        
        public void grid_attach(Gtk.Grid grid, Gtk.Widget child, int left, int top, int width, int height) {
            child.margin_top = 5;
            child.margin_bottom = 5;
            grid.attach(child, left, top, width, height);
        }
        
        public void grid_attach_next_to(Gtk.Grid grid, Gtk.Widget child, Gtk.Widget sibling, Gtk.PositionType side, int width, int height) {
            child.margin_top = 5;
            child.margin_bottom = 5;
            grid.attach_next_to(child, sibling, side, width, height);
        }
    }
}