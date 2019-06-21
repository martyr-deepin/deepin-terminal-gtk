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
using Menu;
using Utils;
using Vte;
using Widgets;

namespace Widgets {
    public class Term : Gtk.Overlay {
        enum DropTargets {
            URILIST,
            STRING,
            TEXT
        }

        private bool enter_sz_command = false;
        private string save_file_directory = "";
        public ArrayList<int> command_execute_y_coordinates;
        public GLib.Pid child_pid;
        public Gdk.RGBA background_color = Gdk.RGBA();
        public Gdk.RGBA foreground_color = Gdk.RGBA();
        public Gtk.Scrollbar scrollbar;
        public Menu.Menu menu;
        public Terminal term;
        public WorkspaceManager workspace_manager;
        public bool child_has_exit = false;
        public bool has_print_exit_notify = false;
        public bool has_select_all = false;
        public bool is_first_term;
        public bool is_press_scrollbar = false;
        public bool login_remote_server = false;
        public bool press_anything = false;
        public double zoom_factor = 1.0;
        public int font_size = 0;
        public int hide_scrollbar_offset = 20;
        public int show_scrollbar_offset = 15;
        public string current_dir = "";
        public string current_title = "";
        public string expect_file_path = "";
        public string? customize_title;
        public string? remote_server_title;
        public string? uri_at_right_press;
        public string? server_info;
        public uint launch_idle_id;
        public uint? hide_scrollbar_timeout_source_id = null;

        public static string USERCHARS = "-[:alnum:]";
        public static string USERCHARS_CLASS = "[" + USERCHARS + "]";
        public static string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
        public static string HOSTCHARS_CLASS = "[-[:alnum:]]";
        public static string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
        public static string PORT = "(?:\\:[[:digit:]]{1,5})?";
        public static string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
        public static string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
        public static string SCHEME = """(?:news:|telnet:|nntp:|file:\/|https?:|ftps?:|sftp:|webcal:|irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:|git\+ssh:|bzr:|bzr\+ssh:|svn:|svn\+ssh:|hg:|mailto:|magnet:)""";
        public static string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
        public static string URLPATH = "(?:(/" + PATHCHARS_CLASS + "+(?:[(]" + PATHCHARS_CLASS + "*[)])*" + PATHCHARS_CLASS + "*)*" + PATHTERM_CLASS + ")?";
        public static string[] REGEX_STRINGS = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+",
            "git\\@" + HOST + ":" + HOST + URLPATH,
        };

        public KeyFile search_engine_config_file;
        public string search_engine_config_file_path = Utils.get_config_file_path("search-engine-config.conf");

        public signal void change_title(string dir);
        public signal void exit();
        public signal void highlight_tab();
        public signal void exit_with_bad_code(int exit_status);

        public Term(bool first_term, string? work_directory, WorkspaceManager manager) {
            Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");

            workspace_manager = manager;
            is_first_term = first_term;
            command_execute_y_coordinates = new ArrayList<int>();

            term = new Terminal();

            search_engine_config_file = new KeyFile();

            term.child_exited.connect((t, exit_status)=> {
                    print("Terminal exit with code: %i\n", exit_status);

                    // Just reset terminal when exit code match EXIT_CODE_BAD_SMABA (139).
                    if (exit_status == Constant.EXIT_CODE_BAD_SMABA) {
                        exit_with_bad_code(exit_status);
                    } else {
                        child_has_exit = true;

                        // Since vte@0276859 (v0.53.92), the vte terminal always emit the `child-exited` signal
                        if (term.get_toplevel().get_type().is_a(typeof(ConfigWindow))) {
                            ConfigWindow window = (ConfigWindow) term.get_toplevel();

                            try {
                                if (window.config.config_file.get_boolean("advanced", "print_notify_after_script_finish") && is_launch_command() && workspace_manager.is_first_term(this)) {
                                    // Print exit notify if command execute finish.
                                    print_exit_notify();
                                } else {
                                    // Just exit terminal if `child_exited' signal emit by shell.
                                    exit();
                                }
                            } catch (Error e) {
                                print("child_exited: %s\n", e.message);
                            }
                        }
                    }
                });
            term.destroy.connect((t) => {
                    kill_fg();
                });
            term.realize.connect((t) => {
                    setup_from_config();

                    focus_term();
                });
            term.window_title_changed.connect((t) => {
                    update_terminal_title();

                    // Command finish will trigger 'window-title-changed' signal emit.
                    // we will notify user if background terminal command finish.
                    if (!term.get_toplevel().get_type().is_a(typeof(ConfigWindow))) {
                        if (press_anything) {
                            highlight_tab();
                        }
                    }
                });
            term.key_press_event.connect(on_key_press);
            term.scroll_event.connect(on_scroll);
            term.button_press_event.connect((event) => {
                    has_select_all = false;

                    string? uri = term.match_check_event(event, null);

                    switch (event.button) {
                    case Gdk.BUTTON_PRIMARY:
                        // Grab focus terminal first.
                        focus_term();

                        int modifiers = Gtk.accelerator_get_default_mod_mask();
                        if ((event.state & modifiers) == Gdk.ModifierType.CONTROL_MASK && uri != null) {
                            try {
                                Gtk.show_uri(null, (!) uri, Gtk.get_current_event_time());

                                return true;
                            } catch (GLib.Error error) {
                                try {
                                    uri = "http://%s".printf(uri);
                                    Gtk.show_uri(null, (!) uri, Gtk.get_current_event_time());
                                } catch (GLib.Error error) {
                                    warning("Could Not Open link");
                                }
                            }
                        }

                        return false;
                    case Gdk.BUTTON_SECONDARY:
                        // Grab focus terminal first.
                        focus_term();

                        uri_at_right_press = term.match_check_event(event, null);
                        show_menu((int) event.x_root, (int) event.y_root);

                        return false;
                    }

                    return false;
                });
            term.button_release_event.connect((event) => {
                    try {
                        Widgets.ConfigWindow window = (Widgets.ConfigWindow) term.get_toplevel();

                        // Like XShell, if user set config option 'copy_on_select' to true, terminal will copy select text to system clipboard when text is selected.
                        if (window.config.config_file.get_boolean("advanced", "copy_on_select") && term.get_has_selection()) {
                            term.copy_clipboard();
                        }
                    } catch (Error e) {
                        print("term button_release_event: %s\n", e.message);
                    }

                    return false;
                });

            /* target entries specify what kind of data the terminal widget accepts */
            Gtk.TargetEntry uri_entry = { "text/uri-list", Gtk.TargetFlags.OTHER_APP, DropTargets.URILIST };
            Gtk.TargetEntry string_entry = { "STRING", Gtk.TargetFlags.OTHER_APP, DropTargets.STRING };
            Gtk.TargetEntry text_entry = { "text/plain", Gtk.TargetFlags.OTHER_APP, DropTargets.TEXT };

            Gtk.TargetEntry[] targets = { };
            targets += uri_entry;
            targets += string_entry;
            targets += text_entry;

            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
            this.drag_data_received.connect(drag_received);

            /* Make Links Clickable */
            this.clickable(REGEX_STRINGS);

            // NOTE: if terminal start with option '-e', use functional 'launch_command' and don't use function 'launch_shell'.
            // terminal will crash if we launch_command after launch_shell.
            if (is_launch_command() && workspace_manager.is_first_term(this)) {
                launch_command(Application.commands, work_directory);
            } else {
                launch_shell(work_directory);
            }

            add(term);

            // Create overlay scrollbar.
            // NOTE: Why not use vte in Gtk.ScrolledWindow?
            // Because VTE implement Gtk.Scrollable that conflict with Gtk.ScrolledWindow.
            // Terminal process will *CRASH* if use Gtk.ScrolledWindow when vte have huge output scroll.
            scrollbar = new Gtk.Scrollbar(Gtk.Orientation.VERTICAL, term.get_vadjustment());
            scrollbar.set_halign(Gtk.Align.END);
            scrollbar.set_child_visible(false);

            scrollbar.button_press_event.connect((w, e) => {
                    is_press_scrollbar = true;

                    return false;
                });
            scrollbar.button_release_event.connect((w, e) => {
                    is_press_scrollbar = false;

                    return false;
                });
            scrollbar.value_changed.connect(() => {
                    // Try to show scrollbar when scroll value changed.
                    // Don't show scrollbar if scrollbar's height equal to terminal height (such as run aptitude).
                    var adj = scrollbar.get_adjustment();
                    if (adj.get_upper() == adj.get_lower() + adj.get_page_size()) {
                        scrollbar.set_child_visible(false);
                    } else {
                        // Try to run hide scrollbar timer after show scrollbar.
                        scrollbar.set_child_visible(true);

                        try_hide_scrollbar();
                    }
                });
            term.motion_notify_event.connect((w, e) => {
                    Gtk.Allocation rect;
                    w.get_allocation(out rect);

                    if (e.x < rect.width - hide_scrollbar_offset) {
                        try_hide_scrollbar();
                    } else if (e.x > rect.width - show_scrollbar_offset) {
                        var adj = scrollbar.get_adjustment();
                        if (adj.get_upper() != adj.get_lower() + adj.get_page_size()) {
                            scrollbar.set_child_visible(true);
                        }
                    }

                    return false;
                });

            add_overlay(scrollbar);
        }

        public void try_hide_scrollbar() {
            if (hide_scrollbar_timeout_source_id != null) {
                GLib.Source.remove(hide_scrollbar_timeout_source_id);
                hide_scrollbar_timeout_source_id = null;
            }

            if (hide_scrollbar_timeout_source_id == null) {
                hide_scrollbar_timeout_source_id = GLib.Timeout.add(3000, () => {
                        // Don't hide scrollbar is user is pressing button.
                        if (!is_press_scrollbar) {
                            scrollbar.set_child_visible(false);
                        }

                        hide_scrollbar_timeout_source_id = null;

                        return false;
                    });
            }
        }

        public bool is_in_remote_server() {
            bool in_remote_server = false;
            int foreground_pid;
            var has_foreground_process = try_get_foreground_pid(out foreground_pid);
            if (has_foreground_process) {
                try {
                    Widgets.ConfigWindow window = (Widgets.ConfigWindow) term.get_toplevel();

                    string command = get_proc_file_content("/proc/%i/comm".printf(foreground_pid)).strip();
                    string remote_commands = window.config.config_file.get_string("advanced", "remote_commands");
                    if (command in remote_commands.split(";")) {
                        in_remote_server = true;
                    } else if (command == "expect") {
                        string[] cmdline = get_proc_file_content("/proc/%i/cmdline".printf(foreground_pid)).strip().split(" ");
                        if (cmdline.length == 3 && cmdline[1] == "-f" && cmdline[2] == expect_file_path) {
                            in_remote_server = true;
                        }
                    }
                } catch (Error e) {
                    print("is_in_remote_server: %s\n", e.message);
                }
            }

            return in_remote_server;
        }

        public void show_menu(int x, int y) {
            bool in_quake_window = this.get_toplevel().get_type().is_a(typeof(Widgets.QuakeWindow));

            // Set variable 'show_quake_menu' to true if terminal's window is quake window.
            // Avoid quake window hide when config option 'hide_quakewindow_after_lost_focus' is turn on.
            if (in_quake_window) {
                Widgets.ConfigWindow window = (Widgets.ConfigWindow) term.get_toplevel();
                window.show_quake_menu = true;
            }

            bool display_first_spliter = false;

            var menu_content = new GLib.List<Menu.MenuItem>();
            if (term.get_has_selection()) {
                menu_content.append(new Menu.MenuItem("copy", _("Copy")));

                display_first_spliter = true;
            } else if (uri_at_right_press != null) {
                menu_content.append(new Menu.MenuItem("open", _("Open link")));
                menu_content.append(new Menu.MenuItem("copy", _("Copy link")));

                display_first_spliter = true;
            }

            if (clipboard_has_context()) {
                menu_content.append(new Menu.MenuItem("paste", _("Paste")));

                display_first_spliter = true;
            }
            if (term.get_has_selection()) {
                var selection_file = get_selection_file();
                if (selection_file != null) {
                    menu_content.append(new Menu.MenuItem("open", _("Open")));
                }

                display_first_spliter = true;
            }
            if (get_cwd() != "") {
                var dir_file = GLib.File.new_for_path(current_dir);
                if (dir_file.query_exists()) {
                    menu_content.append(new Menu.MenuItem("open_in_filemanager", _("Open in file manager")));
                }

                display_first_spliter = true;
            }

            if (display_first_spliter) {
                menu_content.append(new Menu.MenuItem("", ""));
            }

            menu_content.append(new Menu.MenuItem("horizontal_split", _("Horizontal split")));
            menu_content.append(new Menu.MenuItem("vertical_split", _("Vertical split")));
            menu_content.append(new Menu.MenuItem("close_window", _("Close window")));
            if (workspace_manager.focus_workspace.term_list.size > 1) {
                menu_content.append(new Menu.MenuItem("close_other_windows", _("Close other windows")));
            }
            menu_content.append(new Menu.MenuItem("", ""));

            menu_content.append(new Menu.MenuItem("new_workspace", _("New workspace")));
            menu_content.append(new Menu.MenuItem("", ""));

            if (!in_quake_window) {
                var window = ((Widgets.Window) get_toplevel());
                if (window.window_is_fullscreen()) {
                    menu_content.append(new Menu.MenuItem("quit_fullscreen", _("Exit fullscreen")));
                } else {
                    menu_content.append(new Menu.MenuItem("fullscreen", _("Fullscreen")));
                }
            }

            menu_content.append(new Menu.MenuItem("find", _("Find")));
            menu_content.append(new Menu.MenuItem("", ""));
            if (term.get_has_selection()) {
                Menu.MenuItem online_search  = new Menu.MenuItem("search", _("Search"));

                online_search.add_submenu_item(new Menu.MenuItem("google", "Google"));
                online_search.add_submenu_item(new Menu.MenuItem("bing", "Bing"));

                string? lang = Environment.get_variable("LANG");
                if (lang != null && lang == "zh_CN.UTF-8") {
                    online_search.add_submenu_item(new Menu.MenuItem("baidu", "Baidu"));
                }

                online_search.add_submenu_item(new Menu.MenuItem("github", "Github"));
                online_search.add_submenu_item(new Menu.MenuItem("stackoverflow", "Stack Overflow"));
                online_search.add_submenu_item(new Menu.MenuItem("duckduckgo", "DuckDuckGo"));

                var file = File.new_for_path(search_engine_config_file_path);
                if (file.query_exists()) {
                    try {
                        search_engine_config_file.load_from_file(search_engine_config_file_path, KeyFileFlags.NONE);

                        foreach (unowned string option in search_engine_config_file.get_groups()) {
                            string search_engine_name = search_engine_config_file.get_value(option, "name");
                            string search_engine_api = search_engine_config_file.get_value(option, "api");

                            if (search_engine_name != "" && search_engine_api != "") {
                                online_search.add_submenu_item(new Menu.MenuItem(option, search_engine_name));
                            }
                        }
                    } catch (Error e) {
                        if (!FileUtils.test(search_engine_config_file_path, FileTest.EXISTS)) {
                            print("Config: %s\n", e.message);
                        }
                    }
                }

                menu_content.append(online_search);
            }
            menu_content.append(new Menu.MenuItem("", ""));
            
            menu_content.append(new Menu.MenuItem("switch_theme", _("Switch theme")));
            menu_content.append(new Menu.MenuItem("rename_title", _("Rename title")));
            menu_content.append(new Menu.MenuItem("encoding", _("Encoding")));
            menu_content.append(new Menu.MenuItem("custom_commands", _("Custom commands")));
            menu_content.append(new Menu.MenuItem("remote_manage", _("Remote management")));
            if (is_in_remote_server()) {
                menu_content.append(new Menu.MenuItem("", ""));
                menu_content.append(new Menu.MenuItem("upload_file", _("Upload file")));
                menu_content.append(new Menu.MenuItem("download_file", _("Download file")));
            }

            menu_content.append(new Menu.MenuItem("", ""));
            menu_content.append(new Menu.MenuItem("preference", _("Settings")));

            menu = new Menu.Menu(x, y, menu_content);
            menu.click_item.connect(handle_menu_item_click);
            menu.destroy.connect(handle_menu_destroy);

        }

        public void handle_menu_item_click(string item_id) {
            if (workspace_manager.get_type().is_a(typeof(WorkspaceManager))) {
                switch(item_id) {
                case "paste":
                    term.paste_clipboard();
                    break;
                case "copy":
                    if (term.get_has_selection()) {
                        term.copy_clipboard();
                    } else if (uri_at_right_press != null) {
                        var display = ((Gtk.Window) this.get_toplevel()).get_display();
                        Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD).set_text(uri_at_right_press, uri_at_right_press.length);
                        Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_PRIMARY).set_text(uri_at_right_press, uri_at_right_press.length);

                    }
                    break;
                case "open":
                    if (term.get_has_selection()) {
                        open_selection_file();
                    } else if (uri_at_right_press != null) {
                        try { 
                            Gtk.show_uri(null, (!) uri_at_right_press, Gtk.get_current_event_time()); 
                        } catch (GLib.Error error) { 
                            try { 
                                var uri = "http://%s".printf(uri_at_right_press); 
                                Gtk.show_uri(null, (!) uri, Gtk.get_current_event_time()); 
                            } catch (GLib.Error error) { 
                                warning("Could Not Open link"); 
                            } 
                        } 
                    }
                    break;
                case "open_in_filemanager":
                    open_current_dir_in_file_manager();
                    break;
                case "fullscreen":
                    var window = ((Widgets.Window) get_toplevel());
                    window.toggle_fullscreen();
                    break;
                case "quit_fullscreen":
                    var window = ((Widgets.Window) get_toplevel());
                    window.toggle_fullscreen();
                    break;
                case "find":
                    workspace_manager.focus_workspace.search(get_selection_text());
                    break;
                case "horizontal_split":
                    workspace_manager.focus_workspace.split_horizontal();
                    break;
                case "vertical_split":
                    workspace_manager.focus_workspace.split_vertical();
                    break;
                case "close_window":
                    workspace_manager.focus_workspace.close_focus_term();
                    break;
                case "close_other_windows":
                    workspace_manager.focus_workspace.close_other_terms();
                    break;
                case "new_workspace":
                    workspace_manager.new_workspace_with_current_directory();
                    break;
                case "custom_commands":
                    workspace_manager.focus_workspace.show_command_panel(workspace_manager.focus_workspace);
                    break;
                case "remote_manage":
                    workspace_manager.focus_workspace.show_remote_panel(workspace_manager.focus_workspace);
                    break;
                case "switch_theme":
                    workspace_manager.focus_workspace.show_theme_panel(workspace_manager.focus_workspace);
                    break;
                case "upload_file":
                    upload_file();
                    break;
                case "download_file":
                    download_file();
                    break;
                case "rename_title":
                    rename_title();
                    break;
                case "encoding":
                    workspace_manager.focus_workspace.show_encoding_panel(workspace_manager.focus_workspace);
                    break;
                case "preference":
                    var preference = new Widgets.Preference((Widgets.ConfigWindow) this.get_toplevel(), ((Gtk.Window) this.get_toplevel()).get_focus());
                    preference.transient_for_window((Widgets.ConfigWindow) this.get_toplevel());
                    break;
                default:
                    if (item_id == "google") {
                        search_text_in_search_engine(get_selection_text(), "http://google.com/search?q=%s");
                    } else if (item_id == "bing") {
                        search_text_in_search_engine(get_selection_text(), "http://cn.bing.com/search?q=%s");
                    } else if (item_id == "baidu") {
                        search_text_in_search_engine(get_selection_text(), "https://www.baidu.com/s?wd=%s");
                    } else if (item_id == "github") {
                        search_text_in_search_engine(get_selection_text(), "https://github.com/search?q=%s");
                    } else if (item_id == "stackoverflow") {
                        search_text_in_search_engine(get_selection_text(), "https://stackoverflow.com/search?q=%s");
                    } else if (item_id == "duckduckgo") {
                        search_text_in_search_engine(get_selection_text(), "https://duckduckgo.com/?q=%s");
                    } else {
                        foreach (unowned string option in search_engine_config_file.get_groups()) {
                            if (item_id == option) {
                                try {
                                    string search_engine_api = search_engine_config_file.get_value(option, "api");
                                    search_text_in_search_engine(get_selection_text(), search_engine_api);
                                } catch (Error e) {
                                    if (!FileUtils.test(search_engine_config_file_path, FileTest.EXISTS)) {
                                        print("Config: %s\n", e.message);
                                    }
                                }

                                break;
                            }
                        }
                    }

                    break;
                }
            } else {
                print("handle_menu_item_click: impossible here!\n");
            }

        }


        public void upload_file () {
            Gtk.FileChooserAction action = Gtk.FileChooserAction.OPEN;
            var chooser = new Gtk.FileChooserDialog(_("Select file to upload"),
                                                    get_toplevel() as Gtk.Window, action);
            chooser.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
            chooser.set_select_multiple(true);
            chooser.add_button(_("Upload"), Gtk.ResponseType.ACCEPT);

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                var file_list = chooser.get_files();

                press_ctrl_at();
                GLib.Timeout.add(500, () => {
                        string upload_command = "sz ";
                        foreach (File file in file_list) {
                            upload_command = upload_command + "'" + file.get_path() + "' ";
                        }
                        upload_command = upload_command + "\n";

                        this.term.feed_child(upload_command.to_utf8());

                        return false;
                    });

            }

            chooser.destroy();
        }

        public void download_file() {
            Gtk.FileChooserAction action = Gtk.FileChooserAction.SELECT_FOLDER;
            var chooser = new Gtk.FileChooserDialog(_("Select directory to save the file"), 
                                                    get_toplevel() as Gtk.Window, action);
            chooser.add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
            chooser.add_button(_("Select"), Gtk.ResponseType.ACCEPT);

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                save_file_directory = chooser.get_filename();

                press_ctrl_a();

                GLib.Timeout.add(100, () => {
                        press_ctrl_k();

                        GLib.Timeout.add(100, () => {
                                // NOTE: Use quote around $file to avoid escape filepath.
                                string command = "read -e -a files -p \"%s: \"; sz \"${files[@]}\"\n".printf(_("Type path to download file"));
                                this.term.feed_child(command.to_utf8());

                                enter_sz_command = true;

                                return false;
                            });

                        return false;
                    });
            }

            chooser.destroy();
        }

        public void rename_title() {
            Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();

            var rename_dialog = new Widgets.RenameDialog(
                _("Rename title"),
                current_title,
                _("Cancel"),
                _("Rename")
                );
            rename_dialog.transient_for_window(parent_window);
            rename_dialog.rename.connect((w, new_title) => {
                    if (new_title.strip() == "") {
                        customize_title = null;
                    } else {
                        customize_title = new_title.strip();
                    }

                    update_terminal_title();
                });
        }

        public void execute_download() {
            // Sleep 1 second to wait sz command execute.
            GLib.Timeout.add(1000, () => {
                    // Switch to zssh local directory.
                    press_ctrl_at();

                    // Sleep 100 millseconds to wait zssh switch local directory.
                    GLib.Timeout.add(100, () => {
                            // Switch directory in zssh.
                            string switch_command = "cd %s\n".printf(save_file_directory);
                            this.term.feed_child(switch_command.to_utf8());

                            // Do rz command to download file.
                            GLib.Timeout.add(100, () => {
                                    string download_command = "rz\n";
                                    this.term.feed_child(download_command.to_utf8());

                                    // Press enter automatically.
                                    GLib.Timeout.add(100, () => {
                                            string enter_command = "\n";
                                            this.term.feed_child(enter_command.to_utf8());

                                            return false;
                                        });

                                    return false;
                                });
                            return false;
                        });

                    return false;
                });
        }

        public void press_ctrl_at() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 64;
            event->state = (Gdk.ModifierType) 33554437;
            event->hardware_keycode = (uint16) 11;
            ((Gdk.Event*) event)->put();
        }

        public void press_ctrl_k() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 75;
            event->state = (Gdk.ModifierType) 33554437;
            event->hardware_keycode = (uint16) 45;
            ((Gdk.Event*) event)->put();
        }

        public void press_ctrl_a() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 97;
            event->state = (Gdk.ModifierType) 33554436;
            event->hardware_keycode = (uint16) 38;
            ((Gdk.Event*) event)->put();
        }

        public void press_ctrl_e() {
            Gdk.EventKey* event;
            event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            var window = term.get_window();
            event->window = window;
            event->keyval = 69;
            event->state = (Gdk.ModifierType) 33554437;
            event->hardware_keycode = (uint16) 26;
            ((Gdk.Event*) event)->put();
        }

        public void handle_menu_destroy() {
            menu = null;
        }

        public void focus_term() {
            term.grab_focus();
            update_terminal_title();
        }

        public void update_terminal_title() {
            // Clean remote_server_title if logout from remote server.
            int foreground_pid;
            var has_foreground_process = try_get_foreground_pid(out foreground_pid);

            if (has_foreground_process) {
                var command = Utils.get_process_cmdline(foreground_pid);
                if (command.index_of("expect -f /tmp/deepin-terminal-") == 0 && !login_remote_server) {
                    login_remote_server = true;
                }
            } else if (login_remote_server) {
                login_remote_server = false;

                if (remote_server_title != null) {
                    remote_server_title = null;
                }
            }

            string title;
            // Always use customize title if customize_title is not null.
            if (customize_title != null) {
                title = customize_title;
            }
            // Use remote server name if user not customize name and when remote_server_title is not null.
            else if (remote_server_title != null) {
                title = remote_server_title;
            }
            else {
                string? vte_window_title = term.get_window_title();
                // Use vte window title if vte_window_title is not null.
                if (vte_window_title != null) {
                    title = vte_window_title;
                } else {
                    string? dir_basename = GLib.Path.get_basename(get_cwd());
                    if (dir_basename != null) {
                        title = dir_basename;
                        current_title = dir_basename;
                    } else {
                        title = _("deepin");
                    }
                }
            }
            // Change the title.
            change_title(title);
            current_title = title;
        }

        public string get_cwd() {
            if (this.term.get_pty() != null) {
                int pty_fd = this.term.get_pty().fd;
                int fpid = Posix.tcgetpgrp(pty_fd);
                if (fpid > 0) {
                    try {
                        current_dir = FileUtils.read_link("/proc/%d/cwd".printf(fpid));
                    } catch (Error e) {
                        stderr.printf("Parse cwd of %d failed: %s\n", fpid, e.message);
                    }
                }
            }
            return current_dir;
        }

        public bool on_scroll(Gtk.Widget widget, Gdk.EventScroll scroll_event) {
            if ((scroll_event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                try {
                    Widgets.ConfigWindow window = (Widgets.ConfigWindow) term.get_toplevel();

                    double old_opacity = window.config.config_file.get_double("general", "opacity");
                    double new_opacity = old_opacity;

                    if (scroll_event.delta_y < 0) {
                        new_opacity = double.min(double.max(old_opacity + 0.01, Constant.TERMINAL_MIN_OPACITY), 1);
                    } else if (scroll_event.delta_y > 0) {
                        new_opacity = double.min(double.max(old_opacity - 0.01, Constant.TERMINAL_MIN_OPACITY), 1);
                    }

                    if (new_opacity != old_opacity) {
                        window.config.load_config();
                        window.config.config_file.set_double("general", "opacity", new_opacity);
                        window.config.save();

                        window.config.update();
                    }

                    return true;
                } catch (GLib.KeyFileError e) {
                    print("Terminal on_scroll: %s\n", e.message);
                }
            }

            return false;
        }

        private bool on_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            // Exit terminal if got `child_exited' signal by command execute finish.
            if (child_has_exit && is_launch_command() && workspace_manager.is_first_term(this)) {
                string keyname = Keymap.get_keyevent_name(key_event);
                if (keyname == "Enter") {
                    // Exit key press callback if current terminal has exit.
                    exit();

                    return true;
                }
            }

            // This variable use for highlight_tab.
            press_anything = true;

            try {
                string keyname = Keymap.get_keyevent_name(key_event);

                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();

                if (keyname == "Menu") {
                    int pointer_x, pointer_y;
                    Utils.get_pointer_position(out pointer_x, out pointer_y);

                    int window_width, window_height;
                    ((ConfigWindow) get_toplevel()).get_size(out window_width, out window_height);

                    int window_x, window_y;
                    ((ConfigWindow) get_toplevel()).get_window().get_origin(out window_x, out window_y);

                    if (pointer_x < window_x || pointer_x > window_x + window_width) {
                        pointer_x = window_x + window_width / 2;
                    }

                    if (pointer_y < window_y || pointer_y > window_y + window_height) {
                        pointer_y = window_y + window_height / 2;
                    }

                    show_menu(pointer_x, pointer_y);

                    return true;
                }

                var copy_key = parent_window.config.config_file.get_string("shortcut", "copy");
                if (copy_key != "" && keyname == copy_key) {
                    term.copy_clipboard();
                    return true;
                }

                var paste_key = parent_window.config.config_file.get_string("shortcut", "paste");
                if (paste_key != "" && keyname == paste_key) {
                    term.paste_clipboard();
                    return true;
                }

                var open_key = parent_window.config.config_file.get_string("shortcut", "open");
                if (open_key != "" && keyname == open_key) {
                    open_selection_file();
                    return true;
                }

                var zoom_in_key = parent_window.config.config_file.get_string("shortcut", "zoom_in");
                if (zoom_in_key != "" && keyname == zoom_in_key) {
                    increment_size();
                    return true;
                }

                var zoom_out_key = parent_window.config.config_file.get_string("shortcut", "zoom_out");
                if (zoom_out_key != "" && keyname == zoom_out_key) {
                    decrement_size();
                    return true;
                }

                var zoom_reset_key = parent_window.config.config_file.get_string("shortcut", "default_size");
                if (zoom_reset_key != "" && keyname == zoom_reset_key) {
                    set_default_font_size();
                    return true;
                }

                var jump_to_next_command_key = parent_window.config.config_file.get_string("shortcut", "jump_to_next_command");
                if (jump_to_next_command_key != "" && keyname == jump_to_next_command_key) {
                    jump_to_next_command();
                    return true;
                }

                var jump_to_previous_command_key = parent_window.config.config_file.get_string("shortcut", "jump_to_previous_command");
                if (jump_to_previous_command_key != "" && keyname == jump_to_previous_command_key) {
                    jump_to_previous_command();
                    return true;
                }

                if (keyname == "Enter" || keyname == "Ctrl + m") {
                    if (enter_sz_command) {
                        execute_download();
                        enter_sz_command = false;
                    } else {
                        // If user press enter or 'ctrl + m' and not foreground(command-line) process exit.
                        // We consider user execute command.
                        if (!has_foreground_process()) {
                            var y_coordinate = (int) scrollbar.get_adjustment().get_value();
                            if (command_execute_y_coordinates.size == 0 || y_coordinate != command_execute_y_coordinates[command_execute_y_coordinates.size - 1]) {
                                command_execute_y_coordinates.add(y_coordinate);
                            }
                        }
                    }
                }

                if (keyname == "Ctrl + c" || keyname == "Ctrl + d") {
                    enter_sz_command = false;

                    return false;
                }

                // Avoid key single character do command shorcut scan.
                if (keyname.length > 1 && keyname != "Enter") {
                    string command_config_file_path = Utils.get_config_file_path("command-config.conf");
                    var file = File.new_for_path(command_config_file_path);
                    if (file.query_exists()) {
                        try {
                            KeyFile command_config_file = new KeyFile();
                            command_config_file.load_from_file(command_config_file_path, KeyFileFlags.NONE);

                            foreach (unowned string option in command_config_file.get_groups ()) {
                                if (keyname == command_config_file.get_value(option, "Shortcut")) {
                                    var command_string = "%s\n".printf(command_config_file.get_value(option, "Command"));
                                    term.feed_child(command_string.to_utf8());

                                    return true;
                                }
                            }
                        } catch (Error e) {
                            if (!FileUtils.test(command_config_file_path, FileTest.EXISTS)) {
                                print("Config: %s\n", e.message);
                            }
                        }
                    }
                }

                return false;
            } catch (GLib.KeyFileError e) {
                print("Terminal on_key_press: %s\n", e.message);

                return false;
            }
        }

        public void update_font_info() {
            try {
                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();
                var font = parent_window.config.config_file.get_string("general", "font");
                Pango.FontDescription current_font = new Pango.FontDescription();
                current_font.set_family(font);
                current_font.set_size((int) (font_size * zoom_factor));
                term.set_font(current_font);
            } catch (GLib.KeyFileError e) {
                print("Terminal update_font_info: %s\n", e.message);
            }
        }

        public void increment_size () {
            if (zoom_factor < 3) {
                zoom_factor += 0.1;

                update_font_info();
            }
        }

        public void decrement_size () {
            if (zoom_factor > 0.8) {
                zoom_factor -= 0.1;

                update_font_info();
            }
        }

        public void set_default_font_size () {
            zoom_factor = 1.0;
            update_font_info();
        }

        public void jump_to_next_command() {
            bool jump_once = false;

            var y_coordinate = (int) scrollbar.get_adjustment().get_value();
            foreach (int command_y_coordiante in command_execute_y_coordinates) {
                if (y_coordinate < command_y_coordiante) {
                    jump_once = true;
                    scrollbar.get_adjustment().set_value(command_y_coordiante);
                    break;
                }
            }

            // Jump to bottom if no next position to jump.
            if (!jump_once) {
                scrollbar.get_adjustment().set_value(scrollbar.get_adjustment().get_upper());
            }
        }

        public void jump_to_previous_command() {
            var y_coordinate = (int) scrollbar.get_adjustment().get_value();
            for (int count = 0; count < command_execute_y_coordinates.size; count++) {
                if (y_coordinate > command_execute_y_coordinates[command_execute_y_coordinates.size - 1 - count]) {
                    scrollbar.get_adjustment().set_value(command_execute_y_coordinates[command_execute_y_coordinates.size - 1 - count]);
                    break;
                }
            }
        }

        public void drag_received (Gdk.DragContext context, int x, int y,
                                   Gtk.SelectionData selection_data, uint target_type, uint time_) {
            term.grab_focus();

            switch (target_type) {
            case DropTargets.URILIST:
                var uris = selection_data.get_uris();

                string path;
                File file;

                // Drag file to remote server if terminal is login.
                if (login_remote_server) {
                    for (var i = 0; i < uris.length; i++) {
                        file = File.new_for_uri(uris[i]);
                        if ((path = file.get_path()) != null) {
                            uris[i] = Shell.quote(path);
                        }
                    }

                    press_ctrl_at();
                    GLib.Timeout.add(500, () => {
                            string upload_command = "sz ";
                            foreach (string file_path in uris) {
                                upload_command = upload_command + "'" + file_path + "' ";
                            }
                            upload_command = upload_command + "\n";

                            this.term.feed_child(upload_command.to_utf8());

                            return false;
                        });
                }
                // Just copy file path if terminal at local.
                else {
                    for (var i = 0; i < uris.length; i++) {
                        file = File.new_for_uri(uris[i]);
                        if ((path = file.get_path()) != null) {
                            uris[i] = Shell.quote(path) + " ";
                        }
                    }

                    string uris_s = string.joinv("", uris);
                    this.term.feed_child(uris_s.to_utf8());
                }

                break;
            case DropTargets.STRING:
            case DropTargets.TEXT:
                var data = selection_data.get_text ();

                if (data != null) {
                    this.term.feed_child(data.to_utf8());
                }

                break;
            }
        }

        private void clickable (string[] str) {
            foreach (string exp in str) {
                try {
                    var regex = new GLib.Regex(exp,
                                               GLib.RegexCompileFlags.OPTIMIZE |
                                               GLib.RegexCompileFlags.MULTILINE,
                                               0);
                    int id = term.match_add_gregex(regex, 0);

                    term.match_set_cursor_type(id, Gdk.CursorType.HAND2);
                } catch (GLib.RegexError error) {
                    warning (error.message);
                }
            }
        }

        public void launch_shell(string? dir) {
            string directory;
            if (dir == null) {
                directory = GLib.Environment.get_current_dir();
            } else {
                directory = dir;
            }

            string? shell;

            shell = Vte.get_user_shell();
            if (shell == null || shell[0] == '\0') {
                shell = Environment.get_variable("SHELL");
            }
            if (shell == null || shell[0] == '\0') {
                shell = "/bin/sh";
            }

            string[] argv;

            try {
                Shell.parse_argv(shell, out argv);
            } catch (ShellError e) {
                if (!(e is ShellError.EMPTY_STRING)) {
                    warning("Terminal launch_shell: %s\n", e.message);
                }
            }

            // Init spawn/pty/argv argument with option 'run_as_login_shell'.
            PtyFlags pty_flags = PtyFlags.DEFAULT;
            GLib.SpawnFlags spawn_flags =  0;

            try {
                // Because terminal haven't realize finish when call 'launch_shell'.
                // So we don't use ConfigWindow to get config value, new Config object to get config value.
                Config.Config config = new Config.Config();
                bool run_as_login_shell = config.config_file.get_boolean("advanced", "run_as_login_shell");

                if (run_as_login_shell) {
                    pty_flags |= PtyFlags.NO_LASTLOG;
                    spawn_flags |= GLib.SpawnFlags.FILE_AND_ARGV_ZERO;
                    argv += "-%s".printf(GLib.Path.get_basename(shell));
                } else {
                    spawn_flags |= GLib.SpawnFlags.SEARCH_PATH;
                }
            } catch (GLib.KeyFileError e) {
                print("terminal launch_shell: %s\n", e.message);
            }

            launch_idle_id = GLib.Idle.add(() => {
                    try {
                        term.spawn_sync(pty_flags,
                                        directory,
                                        argv,
                                        null,
                                        spawn_flags,
                                        null, /* child setup */
                                        out child_pid,
                                        null /* cancellable */);

                        GLib.Timeout.add(200, () => {
                                update_terminal_title();

                                return false;
                            });
                    } catch (Error e) {
                        warning("Terminal launch_idle_id: %s\n", e.message);
                    }

                    launch_idle_id = 0;
                    return false;
                });
        }

        public bool is_launch_command() {
            return Application.commands.size > 0;
        }

        public void print_exit_notify() {
            if (!has_print_exit_notify) {
                GLib.Timeout.add(200, () => {
                        try {
                            term.spawn_sync(Vte.PtyFlags.DEFAULT,
                                            null,
                    {"echo", _("\nCommand has been completed, press ENTER to exit the terminal.")},
                                            null,
                                            GLib.SpawnFlags.SEARCH_PATH,
                                            null, /* child setup */
                                            null,
                                            null /* cancellable */);
                        } catch (Error e) {
                            warning("Terminal print_exit_notify: %s\n", e.message);
                        }

                        return false;
                    });

                has_print_exit_notify = true;
            }
        }

        public void launch_command(ArrayList<string> commands, string? dir) {
            string[] argv = {};
            foreach (string arg in commands) {
                argv += arg;
            }

            // Set tab name when launch command.
            GLib.Timeout.add(200, () => {
                    if (workspace_manager.tabbar.tab_name_map.get(workspace_manager.workspace_index) == "") {
                        workspace_manager.tabbar.rename_tab(workspace_manager.workspace_index, _("deepin"));
                    }

                    return false;
                });

            launch_idle_id = GLib.Idle.add(() => {
                    try {
                        term.spawn_sync(Vte.PtyFlags.DEFAULT,
                                        dir,
                                        argv,
                                        null,
                                        GLib.SpawnFlags.SEARCH_PATH,
                                        null, /* child setup */
                                        out child_pid,
                                        null /* cancellable */);
                    } catch (Error e) {
                        warning("Terminal launch_idle_id: %s\n", e.message);
                    }

                    launch_idle_id = 0;
                    return false;
                });
        }

        public bool try_get_foreground_pid (out int pid) {
            if (this.term.get_pty() == null) {
                pid = -1;
                return false;
            } else {
                int pty_fd = this.term.get_pty().fd;
                int fgpid = Posix.tcgetpgrp(pty_fd);

                if (fgpid != this.child_pid && fgpid > 0) {
                    pid = (int) fgpid;
                    return true;
                } else {
                    pid = -1;
                    return false;
                }
            }
        }

        public bool has_foreground_process () {
            return try_get_foreground_pid(null);
        }

        public void kill_fg() {
            int fg_pid;
            if (this.try_get_foreground_pid(out fg_pid)) {
                Posix.kill(fg_pid, Posix.SIGKILL);
            }
        }

        public void toggle_select_all() {
            if (has_select_all) {
                term.unselect_all();
            } else {
                term.select_all();
            }

            has_select_all = !has_select_all;
        }

        public void setup_from_config() {
            try {
                Widgets.ConfigWindow parent_window = (Widgets.ConfigWindow) term.get_toplevel();

                var is_cursor_blink = parent_window.config.config_file.get_boolean("advanced", "cursor_blink_mode");
                if (is_cursor_blink) {
                    term.set_cursor_blink_mode(Vte.CursorBlinkMode.ON);
                } else {
                    term.set_cursor_blink_mode(Vte.CursorBlinkMode.OFF);
                }

                term.set_bold_is_bright(parent_window.config.config_file.get_boolean("advanced", "bold_is_bright"));
                term.set_audible_bell(parent_window.config.config_file.get_boolean("advanced", "audible_bell"));
                term.set_mouse_autohide(parent_window.config.config_file.get_boolean("advanced", "cursor_auto_hide"));

                var scroll_lines = parent_window.config.config_file.get_integer("advanced", "scroll_line");
                term.set_scrollback_lines(scroll_lines);

                var cursor_shape = parent_window.config.config_file.get_string("advanced", "cursor_shape");
                if (cursor_shape == "block") {
                    term.set_cursor_shape(Vte.CursorShape.BLOCK);
                } else if (cursor_shape == "ibeam") {
                    term.set_cursor_shape(Vte.CursorShape.IBEAM);
                } else if (cursor_shape == "underline") {
                    term.set_cursor_shape(Vte.CursorShape.UNDERLINE);
                }

                background_color = Utils.hex_to_rgba(
                    parent_window.config.config_file.get_string("theme", "background"),
                    parent_window.config.config_file.get_double("general", "opacity"));
                foreground_color = Utils.hex_to_rgba(parent_window.config.config_file.get_string("theme", "foreground"));
                var palette = new Gdk.RGBA[16];
                for (int i = 0; i < 16; i++) {
                    Gdk.RGBA new_color= Utils.hex_to_rgba(parent_window.config.config_file.get_string("theme", "color_%i".printf(i + 1)));

                    palette[i] = new_color;
                }
                term.set_colors(foreground_color, background_color, palette);

                term.set_scroll_on_output(parent_window.config.config_file.get_boolean("advanced", "scroll_on_output"));
                term.set_scroll_on_keystroke(parent_window.config.config_file.get_boolean("advanced", "scroll_on_key"));

                if (parent_window.config.config_file.get_string("theme", "style") == "light") {
                    scrollbar.get_style_context().remove_class("light_scrollbar");
                    scrollbar.get_style_context().remove_class("dark_scrollbar");

                    scrollbar.get_style_context().add_class("light_scrollbar");
                } else {
                    scrollbar.get_style_context().remove_class("light_scrollbar");
                    scrollbar.get_style_context().remove_class("dark_scrollbar");

                    scrollbar.get_style_context().add_class("dark_scrollbar");
                }

                var config_size = parent_window.config.config_file.get_integer("general", "font_size");
                font_size = config_size * Pango.SCALE;
                update_font_info();
            } catch (GLib.KeyFileError e) {
                stdout.printf(e.message);
            }
        }

        public bool clipboard_has_context() {
            var clipboard_text = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD).wait_for_text();
            return clipboard_text != null && clipboard_text.strip() != "";
        }

        public string? get_selection_file() {
            string? clipboard_text = get_selection_text();
            if (clipboard_text != "") {
                //TODO: support "~"
                var clipboard_file_path = clipboard_text;
                if (FileUtils.test(clipboard_file_path, FileTest.EXISTS)) {
                    return clipboard_file_path;
                }
                clipboard_file_path = GLib.Path.build_path(Path.DIR_SEPARATOR_S, current_dir, clipboard_text);
                if (FileUtils.test(clipboard_file_path, FileTest.EXISTS)) {
                    return clipboard_file_path;
                } else {
                    return null;
                }
            } else {
                return null;
            }
        }

        public string get_selection_text() {
            if (term.get_has_selection()) {
                // FIXME: vte developer private function 'get_selected_text', so i can't get selected text from api.
                // So i get selected text from clipboard that i need save clipboard context before i test selection context.
                var clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
                var current_clipboard_text = clipboard.wait_for_text();

                term.copy_clipboard();
                var clipboard_text = clipboard.wait_for_text();

                // FIXME: vte developer private function 'get_selected_text', so i can't get selected text from api.
                // So i get selected text from clipboard that i need restore clipboard context before i test selection context.
                if (current_clipboard_text != null) {
                    var display = Gdk.Display.get_default();
                    Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD).set_text(current_clipboard_text, current_clipboard_text.length);
                }
                if (clipboard_text != null) {
                    return clipboard_text.strip();
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        public void search_text_in_search_engine(string search_text, string search_engline_api) {
            try {
                GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline(
                    "xdg-open '%s'".printf(search_engline_api).printf(search_text),
                    null, GLib.AppInfoCreateFlags.NONE);
                appinfo.launch(null, null);
            } catch (GLib.Error e) {
                print("Terminal search_in_search_engine: %s\n", e.message);
            }
        }

        public void open_selection_file() {
            var selection_file = get_selection_file();
            if (selection_file != null) {
                try {
                    GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("xdg-open '%s'".printf(selection_file), null, GLib.AppInfoCreateFlags.NONE);
                    appinfo.launch(null, null);
                } catch (GLib.Error e) {
                    print("Terminal open_selection_file: %s\n", e.message);
                }
            }
        }

        public void open_current_dir_in_file_manager() {
            try {
                GLib.AppInfo appinfo = GLib.AppInfo.create_from_commandline("xdg-open '%s'".printf(current_dir), null, GLib.AppInfoCreateFlags.NONE);
                appinfo.launch(null, null);
            } catch (GLib.Error e) {
                print("Terminal open_current_dir_in_file_manager: %s\n", e.message);
            }
        }

        public void login_server(string info) {
            // Record server info.
            server_info = info;

            // Load config.
            KeyFile config_file = new KeyFile();
            string config_file_path = Utils.get_config_file_path("server-config.conf");

            var gio_file = File.new_for_path(config_file_path);
            if (!gio_file.query_exists()) {
                Utils.touch_dir(Utils.get_config_dir());
                Utils.create_file(config_file_path);
            } else {
                try {
                    config_file.load_from_file(config_file_path, KeyFileFlags.NONE);
                } catch (Error e) {
                    if (!FileUtils.test(config_file_path, FileTest.EXISTS)) {
                        print("Config: %s\n", e.message);
                    }
                }
            }

            try {
                // Build ssh temp file.
                var file = File.new_for_path(Utils.get_ssh_script_path());

                if (!file.query_exists ()) {
                    stderr.printf("File '%s' doesn't exist.\n", file.get_path());
                }

                var dis = new DataInputStream(file.read());
                string line;
                string ssh_script_content = "";
                while ((line = dis.read_line(null)) != null) {
                    ssh_script_content = ssh_script_content.concat("%s\n".printf(line));
                }

                string[] server_infos = server_info.split("@");

                string password = "";
                if (server_info.length > 2) {
                    password = Utils.lookup_password(server_infos[0], server_infos[1], server_infos[2]);
                } else {
                    password = Utils.lookup_password(server_infos[0], server_infos[1]);
                }

                ssh_script_content = ssh_script_content.replace("<<USER>>", server_infos[0]);
                ssh_script_content = ssh_script_content.replace("<<SERVER>>", server_infos[1]);
                if (server_infos.length > 2) {
                    ssh_script_content = ssh_script_content.replace("<<PORT>>", server_infos[2]);
                } else {
                    ssh_script_content = ssh_script_content.replace("<<PORT>>", config_file.get_value(server_info, "Port"));
                }

                bool use_private_key = true;
                string private_key_file = "";
                try {
                    private_key_file = config_file.get_value(server_info, "PrivateKey");
                    use_private_key = FileUtils.test(private_key_file, FileTest.EXISTS);
                } catch (GLib.KeyFileError e) {
                    use_private_key = false;
                }

                if (use_private_key) {
                    ssh_script_content = ssh_script_content.replace("<<PRIVATE_KEY>>", " -i %s".printf(private_key_file));
                    ssh_script_content = ssh_script_content.replace("<<PASSWORD>>", "");
                    ssh_script_content = ssh_script_content.replace("<<AUTHENTICATION>>", "yes");
                } else {
                    ssh_script_content = ssh_script_content.replace("<<PRIVATE_KEY>>", "");
                    string escaped_password = new GLib.Regex("([\"$\\\\])").replace(password, -1, 0, "\\\\\\1");
                    ssh_script_content = ssh_script_content.replace("<<PASSWORD>>", escaped_password);
                    ssh_script_content = ssh_script_content.replace("<<AUTHENTICATION>>", "no");
                }

                var path = config_file.get_string(server_info, "Path");
                var command = config_file.get_string(server_info, "Command");

                string remote_command = "echo %s &&".printf(_("Welcome to Deepin Terminal, please make sure that rz and sz commands have been installed in the server before right clicking to upload and download files."));
                if (path.strip() != "") {
                    remote_command += "cd %s && ".printf(path);
                }
                if (command.strip() != "") {
                    remote_command += "%s && ".printf(command);
                }

                ssh_script_content = ssh_script_content.replace("<<REMOTE_COMMAND>>", remote_command);

                // Create temporary expect script file, and the file will
                // be delete by itself.
                FileIOStream iostream;
                var tmpfile = File.new_tmp("deepin-terminal-XXXXXX", out iostream);
                OutputStream ostream = iostream.output_stream;
                DataOutputStream dos = new DataOutputStream(ostream);
                dos.put_string(ssh_script_content);

                // Enable for debug.
                // print("%s\n", ssh_script_content);

                // Set term server info.
                term.set_encoding(config_file.get_value(server_info, "Encode"));

                remote_server_title = config_file.get_value(server_info, "Name");

                var backspace_binding = config_file.get_value(server_info, "Backspace");
                if (backspace_binding == "auto") {
                    term.set_backspace_binding(Vte.EraseBinding.AUTO);
                } else if (backspace_binding == "escape-sequence") {
                    term.set_backspace_binding(Vte.EraseBinding.DELETE_SEQUENCE);
                } else if (backspace_binding == "ascii-del") {
                    term.set_backspace_binding(Vte.EraseBinding.ASCII_DELETE);
                } else if (backspace_binding == "control-h") {
                    term.set_backspace_binding(Vte.EraseBinding.ASCII_BACKSPACE);
                } else if (backspace_binding == "tty") {
                    term.set_backspace_binding(Vte.EraseBinding.TTY);
                }

                var del_binding = config_file.get_value(server_info, "Del");
                if (del_binding == "auto") {
                    term.set_delete_binding(Vte.EraseBinding.AUTO);
                } else if (del_binding == "escape-sequence") {
                    term.set_delete_binding(Vte.EraseBinding.DELETE_SEQUENCE);
                } else if (del_binding == "ascii-del") {
                    term.set_delete_binding(Vte.EraseBinding.ASCII_DELETE);
                } else if (del_binding == "control-h") {
                    term.set_delete_binding(Vte.EraseBinding.ASCII_BACKSPACE);
                } else if (del_binding == "tty") {
                    term.set_delete_binding(Vte.EraseBinding.TTY);
                }

                if (term != null) {
                    string login_command = "expect -f " + tmpfile.get_path() + "\n";
                    expect_file_path = tmpfile.get_path();
                    term.feed_child(login_command.to_utf8());
                }
            } catch (Error e) {
                stderr.printf("login_server: %s\n", e.message);
            }
        }
    }
}
