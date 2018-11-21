/*
 * Copyright © 2001,2002 Red Hat, Inc.
 * Copyright © 2014 Christian Persch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Test
{

[GtkTemplate (ui = "/org/gnome/vte/test/app/ui/search-popover.ui")]
class SearchPopover : Gtk.Popover
{
  public Vte.Terminal terminal { get; construct set; }

  [GtkChild] private Gtk.SearchEntry search_entry;
  [GtkChild] private Gtk.Button search_prev_button;
  [GtkChild] private Gtk.Button search_next_button;
  [GtkChild] private Gtk.Button close_button;
  [GtkChild] private Gtk.ToggleButton  match_case_checkbutton;
  [GtkChild] private Gtk.ToggleButton entire_word_checkbutton;
  [GtkChild] private Gtk.ToggleButton regex_checkbutton;
  [GtkChild] private Gtk.ToggleButton wrap_around_checkbutton;
  [GtkChild] private Gtk.Button reveal_button;
  [GtkChild] private Gtk.Revealer revealer;

  private bool regex_caseless = false;
  private string? regex_pattern = null;
  private bool has_regex = false;

  public SearchPopover(Vte.Terminal term,
                       Gtk.Widget relative_to)
  {
    Object(relative_to: relative_to, terminal: term);

    close_button.clicked.connect(() => { hide(); });
    reveal_button.bind_property("active", revealer, "reveal-child");

#if GTK_3_16
    search_entry.next_match.connect(() => { search(false); });
    search_entry.previous_match.connect(() => { search(true); });
#endif
    search_entry.search_changed.connect(() => { update_regex(); });

    search_next_button.clicked.connect(() => { search(false); });
    search_prev_button.clicked.connect(() => { search(true); });

    match_case_checkbutton.toggled.connect(() => { update_regex(); });
    entire_word_checkbutton.toggled.connect(() => { update_regex(); });
    regex_checkbutton.toggled.connect(() => { update_regex(); });

    wrap_around_checkbutton.toggled.connect(() => {
        terminal.search_set_wrap_around(wrap_around_checkbutton.active);
      });

    update_sensitivity();
  }

  private bool have_regex()
  {
	return has_regex;
  }

  private void update_sensitivity()
  {
    bool can_search = have_regex();

    search_prev_button.set_sensitive(can_search);
    search_next_button.set_sensitive(can_search);
  }

  private void update_regex()
  {
    string search_text;
    string pattern = null;
    bool caseless = false;
    GLib.Regex? gregex = null;
    Vte.Regex? regex = null;

    search_text = search_entry.get_text();
    caseless = !match_case_checkbutton.active;

    if (regex_checkbutton.active) {
      pattern = search_text;
    } else {
      pattern = GLib.Regex.escape_string(search_text);
    }

    if (entire_word_checkbutton.active)
      pattern = "\\b" + pattern + "\\b";

    if (caseless == regex_caseless &&
        pattern == regex_pattern)
      return;

    regex_pattern = null;
    regex_caseless = caseless;

    if (search_text.length != 0) {
      try {
        if (!App.Options.no_pcre) {
          uint32 flags;

          flags = 0x40080400u /* PCRE2_UTF | PCRE2_NO_UTF_CHECK | PCRE2_MULTILINE */;
          if (caseless)
            flags |= 0x00000008u; /* PCRE2_CASELESS */
          regex = new Vte.Regex.for_search(pattern, pattern.length, flags);

          try {
            regex.jit(0x00000001u /* PCRE2_JIT_COMPLETE */);
            regex.jit(0x00000002u /* PCRE2_JIT_PARTIAL_SOFT */);
          } catch (Error e) {
            if (e.code != -45 /* PCRE2_ERROR_JIT_BADOPTION */) /* JIT not supported */
              printerr("JITing regex \"%s\" failed: %s\n", pattern, e.message);
          }
        } else {
          GLib.RegexCompileFlags flags;

          flags = GLib.RegexCompileFlags.OPTIMIZE |
                  GLib.RegexCompileFlags.MULTILINE;
          if (caseless)
            flags |= GLib.RegexCompileFlags.CASELESS;

          gregex = new GLib.Regex(pattern, flags, 0);
        }

        regex_pattern = pattern;
        search_entry.set_tooltip_text(null);
      } catch (Error e) {
        regex = null;
        gregex = null;
        search_entry.set_tooltip_text(e.message);
      }
    } else {
      regex = null;
      gregex = null;
      search_entry.set_tooltip_text(null);
    }

    if (!App.Options.no_pcre) {
      has_regex = regex != null;
      terminal.search_set_regex(regex, 0);
    } else {
      has_regex = gregex != null;
      terminal.search_set_gregex(gregex, 0);
    }

    update_sensitivity();
  }

  private void search(bool backward)
  {
    if (!have_regex())
      return;

    if (backward)
      terminal.search_find_previous();
    else
      terminal.search_find_next();
  }

} /* class SearchPopover */

[GtkTemplate (ui = "/org/gnome/vte/test/app/ui/window.ui")]
class Window : Gtk.ApplicationWindow
{
  [GtkChild] private Gtk.Scrollbar scrollbar;
  [GtkChild] private Gtk.Box terminal_box;
  /* [GtkChild] private Gtk.Box notifications_box; */
  [GtkChild] private Gtk.Widget readonly_emblem;
  /* [GtkChild] private Gtk.Button copy_button; */
  /* [GtkChild] private Gtk.Button paste_button; */
  [GtkChild] private Gtk.ToggleButton find_button;
  [GtkChild] private Gtk.MenuButton gear_button;

  private Vte.Terminal terminal;
  private Gtk.Clipboard clipboard;
  private GLib.Pid child_pid;
  private SearchPopover search_popover;
  private uint launch_idle_id;

  private string[] builtin_dingus = {
    "(((gopher|news|telnet|nntp|file|http|ftp|https)://)|(www|ftp)[-A-Za-z0-9]*\\.)[-A-Za-z0-9\\.]+(:[0-9]*)?",
    "(((gopher|news|telnet|nntp|file|http|ftp|https)://)|(www|ftp)[-A-Za-z0-9]*\\.)[-A-Za-z0-9\\.]+(:[0-9]*)?/[-A-Za-z0-9_\\$\\.\\+\\!\\*\\(\\),;:@&=\\?/~\\#\\%]*[^]'\\.}>\\) ,\\\"]"
  };

  private const GLib.ActionEntry[] action_entries = {
    { "copy",        action_copy_cb,       "s" },
    { "copy-match",  action_copy_match_cb, "s" },
    { "paste",       action_paste_cb           },
    { "reset",       action_reset_cb,      "b" },
    { "find",        action_find_cb            },
    { "quit",        action_quit_cb            }
  };

  public Window(App app)
  {
    Object(application: app);

    /* Create terminal and connect scrollbar */
    terminal = new Vte.Terminal();
    var margin = App.Options.extra_margin;
    if (margin > 0) {
      terminal.margin_start =
        terminal.margin_end =
        terminal.margin_top =
        terminal.margin_bottom = margin;
    }

    scrollbar.set_adjustment(terminal.get_vadjustment());

    /* Create actions */
    add_action_entries (action_entries, this);

    /* Property actions */
    var action = new GLib.PropertyAction ("input-enabled", terminal, "input-enabled");
    add_action(action);
    action.notify["state"].connect((obj, pspec) => {
        GLib.Action a = (GLib.Action)obj;
        readonly_emblem.set_visible(!a.state.get_boolean());
      });

    /* Find */
    search_popover = new SearchPopover(terminal, find_button);
    search_popover.closed.connect(() => {
        if (find_button.active)
          find_button.set_active(false);
      });

    find_button.toggled.connect(() => {
        var active = find_button.active;
        if (search_popover.visible != active)
          search_popover.set_visible(active);
      });

    /* Gear menu */
    /* FIXME: figure out how to put this into the .ui file */
    var menu = new GLib.Menu();

    var section = new GLib.Menu();
    section.append("_Copy", "win.copy");
    section.append("_Paste", "win.paste");
    section.append("_Find…", "win.find");
    menu.append_section(null, section);

    section = new GLib.Menu();
    section.append("_Reset", "win.reset(false)");
    section.append("Reset and C_lear", "win.reset(true)");
    section.append("_Input enabled", "win.input-enabled");
    menu.append_section(null, section);

    section = new GLib.Menu();
    section.append("_Quit", "win.quit");
    menu.append_section(null, section);

    gear_button.set_menu_model(menu);

    /* set_resize_mode(Gtk.ResizeMode.IMMEDIATE); */

    clipboard = get_clipboard(Gdk.SELECTION_CLIPBOARD);
    clipboard.owner_change.connect(clipboard_owner_change_cb);

    title = "Terminal";

    /* Set ARGB visual */
    if (App.Options.transparency_percent != 0) {
      if (!App.Options.no_argb_visual) {
        var screen = get_screen();
        Gdk.Visual? visual = screen.get_rgba_visual();
        if (visual != null)
          set_visual(visual);
      }

      /* Without this transparency doesn't work; see bug #729884. */
      app_paintable = true;
    }

    /* Signals */
    terminal.popup_menu.connect(popup_menu_cb);
    terminal.button_press_event.connect(button_press_event_cb);
    terminal.char_size_changed.connect(char_size_changed_cb);
    terminal.child_exited.connect(child_exited_cb);
    terminal.decrease_font_size.connect(decrease_font_size_cb);
    terminal.deiconify_window.connect(deiconify_window_cb);
    terminal.icon_title_changed.connect(icon_title_changed_cb);
    terminal.iconify_window.connect(iconify_window_cb);
    terminal.increase_font_size.connect(increase_font_size_cb);
    terminal.lower_window.connect(lower_window_cb);
    terminal.maximize_window.connect(maximize_window_cb);
    terminal.move_window.connect(move_window_cb);
    terminal.raise_window.connect(raise_window_cb);
    terminal.realize.connect(realize_cb);
    terminal.refresh_window.connect(refresh_window_cb);
    terminal.resize_window.connect(resize_window_cb);
    terminal.restore_window.connect(restore_window_cb);
    terminal.selection_changed.connect(selection_changed_cb);
    terminal.window_title_changed.connect(window_title_changed_cb);
    if (App.Options.object_notifications)
      terminal.notify.connect(notify_cb);

    /* Settings */
    if (App.Options.no_double_buffer)
      terminal.set_double_buffered(false);

    if (App.Options.encoding != null) {
      try {
        terminal.set_encoding(App.Options.encoding);
      } catch (Error e) {
        printerr("Failed to set encoding: %s\n", e.message);
      }
    }

    if (App.Options.word_char_exceptions != null)
      terminal.set_word_char_exceptions(App.Options.word_char_exceptions);

    terminal.set_allow_hyperlink(!App.Options.no_hyperlink);
    terminal.set_audible_bell(App.Options.audible);
    terminal.set_cjk_ambiguous_width(App.Options.get_cjk_ambiguous_width());
    terminal.set_cursor_blink_mode(App.Options.get_cursor_blink_mode());
    terminal.set_cursor_shape(App.Options.get_cursor_shape());
    terminal.set_mouse_autohide(true);
    terminal.set_rewrap_on_resize(!App.Options.no_rewrap);
    terminal.set_scroll_on_output(false);
    terminal.set_scroll_on_keystroke(true);
    terminal.set_scrollback_lines(App.Options.scrollback_lines);

    /* Style */
    if (App.Options.font_string != null) {
      var desc = Pango.FontDescription.from_string(App.Options.font_string);
      terminal.set_font(desc);
    }

    terminal.set_colors(App.Options.get_color_fg(),
                        App.Options.get_color_bg(),
                        null);
    terminal.set_color_cursor(App.Options.get_color_cursor_background());
    terminal.set_color_cursor_foreground(App.Options.get_color_cursor_foreground());
    terminal.set_color_highlight(App.Options.get_color_hl_bg());
    terminal.set_color_highlight_foreground(App.Options.get_color_hl_fg());

    /* Dingus */
    if (!App.Options.no_builtin_dingus)
      add_dingus(builtin_dingus);
    if (App.Options.dingus != null)
      add_dingus(App.Options.dingus);

    /* Done! */
    terminal_box.pack_start(terminal);
    terminal.show();

    update_paste_sensitivity();
    update_copy_sensitivity();

    terminal.grab_focus();

    assert(!get_realized());
  }

  private void add_dingus(string[] dingus)
  {
    const Gdk.CursorType cursors[] = { Gdk.CursorType.GUMBY, Gdk.CursorType.HAND1 };

    for (int i = 0; i < dingus.length; ++i) {
      try {
        int tag;

        if (!App.Options.no_pcre) {
          Vte.Regex regex;

          regex = new Vte.Regex.for_match(dingus[i], dingus[i].length,
                                          0x40080408u /* PCRE2_UTF | PCRE2_NO_UTF_CHECK | PCRE2_CASELESS | PCRE2_MULTILINE */);
          try {
            regex.jit(0x00000001u /* PCRE2_JIT_COMPLETE */);
            regex.jit(0x00000002u /* PCRE2_JIT_PARTIAL_SOFT */);
          } catch (Error e) {
            if (e.code != -45 /* PCRE2_ERROR_JIT_BADOPTION */) /* JIT not supported */
              printerr("JITing regex \"%s\" failed: %s\n", dingus[i], e.message);
          }

          tag = terminal.match_add_regex(regex, 0);
        } else {
          GLib.Regex regex;

          regex = new GLib.Regex(dingus[i],
                                 GLib.RegexCompileFlags.OPTIMIZE |
                                 GLib.RegexCompileFlags.MULTILINE,
                                 0);
          tag = terminal.match_add_gregex(regex, 0);
        }

        terminal.match_set_cursor_type(tag, cursors[i % cursors.length]);
      } catch (Error e) {
        printerr("Failed to compile regex \"%s\": %s\n", dingus[i], e.message);
      }
    }
  }

  private void adjust_font_size(double factor)
  {
    var columns = terminal.get_column_count();
    var rows = terminal.get_row_count();

    terminal.set_font_scale(terminal.get_font_scale() * factor);

    update_geometry();
    resize_to_geometry((int)columns, (int)rows);
  }

  public void apply_geometry()
  {
    /* The terminal needs to be realized first, so that when parsing the
     * geometry, the right geometry hints are already in place.
     */
    terminal.realize();

    if (App.Options.geometry != null) {
      if (parse_geometry(App.Options.geometry)) {
        /* After parse_geometry(), we can get the default size in
         * width/height increments, i.e. in grid size.
         */
        int columns, rows;
        get_default_size(out columns, out rows);
        terminal.set_size(columns, rows);
        resize_to_geometry(columns, rows);
      } else
        printerr("Failed to parse geometry spec \"%s\"\n", App.Options.geometry);
    } else {
      /* In GTK+ 3.0, the default size of a window comes from its minimum
       * size not its natural size, so we need to set the right default size
       * explicitly */
      set_default_geometry((int)terminal.get_column_count(),
                           (int)terminal.get_row_count());
    }
  }

  private void launch_command(string command) throws Error
  {
    string[] argv;

    Shell.parse_argv(command, out argv);
    launch_idle_id = GLib.Idle.add(() => {
        try {
          terminal.spawn_sync(Vte.PtyFlags.DEFAULT,
                              App.Options.working_directory,
                              argv,
                              App.Options.environment,
                              GLib.SpawnFlags.SEARCH_PATH,
                              null, /* child setup */
                              out child_pid,
                              null /* cancellable */);
          print("Fork succeeded, PID %d\n", child_pid);
        } catch (Error e) {
          printerr("Failed to fork: %s\n", e.message);
        }
        launch_idle_id = 0;
        return false;
      });
  }

  private void launch_shell() throws Error
  {
    string? shell;

    shell = Vte.get_user_shell();
    if (shell == null || shell[0] == '\0')
      shell = Environment.get_variable("SHELL");
    if (shell == null || shell[0] == '\0')
      shell = "/bin/sh";

    launch_command(shell);
  }

  private void fork() throws Error
  {
    Vte.Pty pty;
    Posix.pid_t pid;

    pty = new Vte.Pty.sync(Vte.PtyFlags.DEFAULT, null);

    pid = Posix.fork();

    switch (pid) {
    case -1: /* error */
      printerr("Error forking: %m");
      break;
    case 0: /* child */ {
      pty.child_setup();

      for (int i = 0; ; i++) {
        switch (i % 3) {
        case 0:
        case 1:
          print("%d\n", i);
          break;
        case 2:
          printerr("%d\n", i);
          break;
        }
        Posix.sleep(1);
      }
    }
    default: /* parent */
      terminal.set_pty(pty);
      terminal.watch_child(pid);
      print("Child PID is %d (mine is %d).\n", (int)pid, (int)Posix.getpid());
      break;
    }
  }

  public void launch()
  {
    try {
      if (App.Options.command != null)
        launch_command(App.Options.command);
      else if (!App.Options.no_shell)
        launch_shell();
      else
        fork();
    } catch (Error e) {
      printerr("Error: %s\n", e.message);
    }
  }

  private void update_copy_sensitivity()
  {
    var action = lookup_action("copy") as GLib.SimpleAction;
    action.set_enabled(terminal.get_has_selection());
  }

  private void update_paste_sensitivity()
  {
    Gdk.Atom[] targets;
    bool can_paste;

    if (clipboard.wait_for_targets(out targets))
      can_paste = Gtk.targets_include_text(targets);
    else
      can_paste = false;

    var action = lookup_action("paste") as GLib.SimpleAction;
    action.set_enabled(can_paste);
  }

  private void update_geometry()
  {
    if (App.Options.no_geometry_hints)
      return;
    if (!terminal.get_realized())
      return;

    terminal.set_geometry_hints_for_window(this);
  }

  /* Callbacks */

  private void action_copy_cb(GLib.SimpleAction action, GLib.Variant? parameter)
  {
    size_t len;
    unowned string str = parameter.get_string(out len);
    
    terminal.copy_clipboard_format(str == "html" ? Vte.Format.HTML : Vte.Format.TEXT);
  }

  private void action_copy_match_cb(GLib.SimpleAction action, GLib.Variant? parameter)
  {
    size_t len;
    unowned string str = parameter.get_string(out len);
    clipboard.set_text(str, (int)len);
  }

  private void action_paste_cb()
  {
    terminal.paste_clipboard();
  }

  private void action_reset_cb(GLib.SimpleAction action, GLib.Variant? parameter)
  {
    bool clear;
    Gdk.ModifierType modifiers;

    if (parameter != null) {
      clear = parameter.get_boolean();
    } else if (Gtk.get_current_event_state(out modifiers))
      clear = (modifiers & Gdk.ModifierType.CONTROL_MASK) != 0;
    else
      clear = false;

    terminal.reset(true, clear);
  }

  private void action_find_cb()
  {
    find_button.set_active(true);
  }

  private void action_quit_cb()
  {
    destroy();
  }

  private bool popup_menu_cb()
  {
    return show_context_menu(0, Gtk.get_current_event_time(), null);
  }

  private bool button_press_event_cb(Gtk.Widget widget, Gdk.EventButton event)
  {
    if (event.button != 3)
      return false;

    return show_context_menu(event.button, event.time, event);
  }

  private bool show_context_menu(uint button, uint32 timestamp, Gdk.Event? event)
  {
    if (App.Options.no_context_menu)
      return false;

    var menu = new GLib.Menu();
    menu.append("_Copy", "win.copy::text");
    menu.append("Copy As _HTML", "win.copy::html");

#if VALA_0_24
    if (event != null) {
      var hyperlink = terminal.hyperlink_check_event(event);
      if (hyperlink != null)
        menu.append("Copy _Hyperlink", "win.copy-match::" + hyperlink);
      var match = terminal.match_check_event(event, null);
      if (match != null)
        menu.append("Copy _Match", "win.copy-match::" + match);
    }
#endif

    menu.append("_Paste", "win.paste");

    var popup = new Gtk.Menu.from_model(menu);
    popup.attach_to_widget(this, null);
    popup.popup(null, null, null, button, timestamp);
    if (button == 0)
      popup.select_first(true);

    return true;
  }

  private void char_size_changed_cb(Vte.Terminal terminal, uint width, uint height)
  {
    update_geometry();
  }

  private void child_exited_cb(Vte.Terminal terminal, int status)
  {
    printerr("Child exited with status %x\n", status);

    if (App.Options.output_filename != null) {
      try {
        var file = GLib.File.new_for_commandline_arg(App.Options.output_filename);
        var stream = file.replace(null, false, GLib.FileCreateFlags.NONE, null);
        terminal.write_contents_sync(stream, Vte.WriteFlags.DEFAULT, null);
      } catch (Error e) {
        printerr("Failed to write output to \"%s\": %s\n",
                 App.Options.output_filename, e.message);
      }
    }

    if (App.Options.keep)
      return;

    destroy();
  }

  private void clipboard_owner_change_cb(Gtk.Clipboard clipboard, Gdk.Event event)
  {
    update_paste_sensitivity();
  }

  private void decrease_font_size_cb(Vte.Terminal terminal)
  {
    adjust_font_size(1.0 / 1.2);
  }

  public void deiconify_window_cb(Vte.Terminal terminal)
  {
    deiconify();
  }

  private void icon_title_changed_cb(Vte.Terminal terminal)
  {
    get_window().set_icon_name(terminal.get_icon_title());
  }

  private void iconify_window_cb(Vte.Terminal terminal)
  {
    iconify();
  }

  private void increase_font_size_cb(Vte.Terminal terminal)
  {
    adjust_font_size(1.2);
  }

  private void lower_window_cb(Vte.Terminal terminal)
  {
    if (!get_realized())
      return;

    get_window().lower();
  }

  private void maximize_window_cb(Vte.Terminal terminal)
  {
    maximize();
  }

  private void move_window_cb(Vte.Terminal terminal, uint x, uint y)
  {
    move((int)x, (int)y);
  }

  private void notify_cb(Object object, ParamSpec pspec)
  {
    if (pspec.owner_type != typeof(Vte.Terminal))
      return;

    var value = GLib.Value(pspec.value_type);
    object.get_property(pspec.name, ref value);
    var str = value.strdup_contents();
    print("NOTIFY property \"%s\" value %s\n", pspec.name, str);
  }

  private void raise_window_cb(Vte.Terminal terminal)
  {
    if (!get_realized())
      return;

    get_window().raise();
  }

  private void realize_cb(Gtk.Widget widget)
  {
    update_geometry();
  }

  private void refresh_window_cb(Vte.Terminal terminal)
  {
    queue_draw();
  }

  private void resize_window_cb(Vte.Terminal terminal, uint columns, uint rows)
  {
    if (columns < 2 || rows < 2)
      return;

    terminal.set_size((int)columns, (int)rows);
    resize_to_geometry((int)columns, (int)rows);
  }

  private void restore_window_cb(Vte.Terminal terminal)
  {
    unmaximize();
  }

  private void selection_changed_cb(Vte.Terminal terminal)
  {
    update_copy_sensitivity();
  }

  private void window_title_changed_cb(Vte.Terminal terminal)
  {
    set_title(terminal.get_window_title());
  }

} /* class Window */

class App : Gtk.Application
{
  public App()
  {
    Object(application_id: "org.gnome.Vte.Test.App",
           flags: ApplicationFlags.NON_UNIQUE);

    var settings = Gtk.Settings.get_default();
    settings.gtk_enable_mnemonics = false;
    settings.gtk_enable_accels = false;
    /* Make gtk+ CSD not steal F10 from the terminal */
    settings.gtk_menu_bar_accel = null;
  }

  protected override void startup()
  {
    base.startup();

    for (uint i = 0; i < App.Options.n_windows.clamp(0, 16); i++)
      new Window(this);
  }

  protected override void activate()
  {
    foreach (Gtk.Window win in this.get_windows()) {
      if (!(win is Window))
        continue;

      var window = win as Window;
      window.apply_geometry();
      window.present();
      window.launch();
    }
  }

  public struct Options
  {
    public static bool audible = false;
    public static string? command = null;
    private static string? cjk_ambiguous_width_string = null;
    private static string? cursor_blink_mode_string = null;
    private static string? cursor_background_color_string = null;
    private static string? cursor_foreground_color_string = null;
    private static string? cursor_shape_string = null;
    public static string[]? dingus = null;
    public static bool debug = false;
    public static string? encoding = null;
    public static string[]? environment = null;
    public static int extra_margin = 0;
    public static string? font_string = null;
    public static string? geometry = null;
    private static string? hl_bg_color_string = null;
    private static string? hl_fg_color_string = null;
    public static string? icon_title = null;
    public static bool keep = false;
    public static bool no_argb_visual = false;
    public static bool no_builtin_dingus = false;
    public static bool no_context_menu = false;
    public static bool no_double_buffer = false;
    public static bool no_geometry_hints = false;
    public static bool no_hyperlink = false;
    public static bool no_pcre = false;
    public static bool no_rewrap = false;
    public static bool no_shell = false;
    public static bool object_notifications = false;
    public static string? output_filename = null;
    public static bool reverse = false;
    public static int scrollback_lines = 512;
    public static int transparency_percent = 0;
    public static bool version = false;
    public static int n_windows = 1;
    public static string? word_char_exceptions = null;
    public static string? working_directory = null;

    private static int parse_enum(Type type, string str)
    {
      int value = 0;
      EnumClass enum_klass = (EnumClass)type.class_ref();
      unowned EnumValue? enum_value = enum_klass.get_value_by_nick(str);
      if (enum_value != null)
        value = enum_value.value;
      else
        printerr("Failed to parse enum value \"%s\" as type \"%s\"\n",
                 str, type.qname().to_string());
      return value;
    }

    /*
    private static uint parse_flags(Type type, string str)
    {
      uint value = 0;
      var flags_klass = (FlagsClass)type.class_ref();
      string[]? flags = str.split(",|", -1);

      if (flags == null)
        return value;

      for (int i = 0; i < flags.length; i++) {
        unowned FlagsValue? flags_value = flags_klass.get_value_by_nick(flags[i]);
        if (flags_value != null)
          value |= flags_value.value;
        else
          printerr("Failed to parse flags value \"%s\" as type \"%s\"\n",
                   str, type.qname().to_string());
      }
      return value;
    }
    */

    public static int get_cjk_ambiguous_width()
    {
      if (cjk_ambiguous_width_string == null)
        return 1;
      if (cjk_ambiguous_width_string == "narrow")
        return 1;
      if (cjk_ambiguous_width_string == "wide")
        return 2;
      printerr("Failed to parse \"%s\" argument to --cjk-width. Allowed values are \"narrow\" or \"wide\".\n", cjk_ambiguous_width_string);
      return 1;
    }

    public static Gdk.RGBA get_color_bg()
    {
      var color = Gdk.RGBA();
      color.alpha = (double)(100 - transparency_percent.clamp(0, 100)) / 100.0;
      if (Options.reverse) {
        color.red = color.green = color.blue = 1.0;
      } else {
        color.red = color.green = color.blue = 0.0;
      }
      return color;
    }

    public static Gdk.RGBA get_color_fg()
    {
      var color = Gdk.RGBA();
      color.alpha = 1.0;
      if (Options.reverse) {
        color.red = color.green = color.blue = 0.0;
      } else {
        color.red = color.green = color.blue = 1.0;
      }
      return color;
    }

    private static Gdk.RGBA? get_color(string? str)
    {
      if (str == null)
        return null;
      var color = Gdk.RGBA();
      if (!color.parse(str)) {
        printerr("Failed to parse \"%s\" as color.\n", str);
        return null;
      }
      return color;
    }

    public static Gdk.RGBA? get_color_cursor_background()
    {
      return get_color(cursor_background_color_string);
    }

    public static Gdk.RGBA? get_color_cursor_foreground()
    {
      return get_color(cursor_foreground_color_string);
    }

    public static Gdk.RGBA? get_color_hl_bg()
    {
      return get_color(hl_bg_color_string);
    }

    public static Gdk.RGBA? get_color_hl_fg()
    {
      return get_color(hl_fg_color_string);
    }

    public static Vte.CursorBlinkMode get_cursor_blink_mode()
    {
      Vte.CursorBlinkMode value;
      if (cursor_blink_mode_string != null)
        value = (Vte.CursorBlinkMode)parse_enum(typeof(Vte.CursorBlinkMode),
                                                cursor_blink_mode_string);
      else
        value = Vte.CursorBlinkMode.SYSTEM;
      return value;
    }

    public static Vte.CursorShape get_cursor_shape()
    {
      Vte.CursorShape value;
      if (cursor_shape_string != null)
        value = (Vte.CursorShape)parse_enum(typeof(Vte.CursorShape),
                                            cursor_shape_string);
      else
        value = Vte.CursorShape.BLOCK;
      return value;
    }

    public static const OptionEntry[] entries = {
      { "audible-bell", 'a', 0, OptionArg.NONE, ref audible,
        "Use audible terminal bell", null },
      { "command", 'c', 0, OptionArg.STRING, ref command,
        "Execute a command in the terminal", null },
      { "cjk-width", 0, 0, OptionArg.STRING, ref cjk_ambiguous_width_string,
        "Specify the cjk ambiguous width to use for UTF-8 encoding", "NARROW|WIDE" },
      { "cursor-blink", 0, 0, OptionArg.STRING, ref cursor_blink_mode_string,
        "Cursor blink mode (system|on|off)", "MODE" },
      { "cursor-background-color", 0, 0, OptionArg.STRING, ref cursor_background_color_string,
        "Enable a colored cursor background", null },
      { "cursor-foreground-color", 0, 0, OptionArg.STRING, ref cursor_foreground_color_string,
        "Enable a colored cursor foreground", null },
      { "cursor-shape", 0, 0, OptionArg.STRING, ref cursor_shape_string,
        "Set cursor shape (block|underline|ibeam)", null },
      { "dingu", 'D', 0, OptionArg.STRING_ARRAY, ref dingus,
        "Add regex highlight", null },
      { "debug", 'd', 0,OptionArg.NONE, ref debug,
        "Enable various debugging checks", null },
      { "encoding", 0, 0, OptionArg.STRING, ref encoding,
        "Specify the terminal encoding to use", null },
      { "env", 0, 0, OptionArg.STRING_ARRAY, ref environment,
        "Add environment variable to the child\'s environment", "VAR=VALUE" },
      { "extra-margin", 0, 0, OptionArg.INT, ref extra_margin,
        "Add extra margin around the terminal widget", "MARGIN" },
      { "font", 'f', 0, OptionArg.STRING, ref font_string,
        "Specify a font to use", null },
      { "gregex", 0, 0, OptionArg.NONE, ref no_pcre,
        "Use GRegex instead of PCRE2", null },
      { "geometry", 'g', 0, OptionArg.STRING, ref geometry,
        "Set the size (in characters) and position", "GEOMETRY" },
      { "highlight-background-color", 0, 0, OptionArg.STRING, ref hl_bg_color_string,
        "Enable distinct highlight background color for selection", null },
      { "highlight-foreground-color", 0, 0, OptionArg.STRING, ref hl_fg_color_string,
        "Enable distinct highlight foreground color for selection", null },
      { "icon-title", 'i', 0, OptionArg.NONE, ref icon_title,
        "Enable the setting of the icon title", null },
      { "keep", 'k', 0, OptionArg.NONE, ref keep,
        "Live on after the command exits", null },
      { "no-argb-visual", 0, 0, OptionArg.NONE, ref no_argb_visual,
        "Don't use an ARGB visual", null },
      { "no-builtin-dingus", 0, 0, OptionArg.NONE, ref no_builtin_dingus,
        "Highlight URLs inside the terminal", null },
      { "no-context-menu", 0, 0, OptionArg.NONE, ref no_context_menu,
        "Disable context menu", null },
      { "no-double-buffer", '2', 0, OptionArg.NONE, ref no_double_buffer,
        "Disable double-buffering", null },
      { "no-geometry-hints", 'G', 0, OptionArg.NONE, ref no_geometry_hints,
        "Allow the terminal to be resized to any dimension, not constrained to fit to an integer multiple of characters", null },
      { "no-hyperlink", 'H', 0, OptionArg.NONE, ref no_hyperlink,
        "Disable hyperlinks", null },
      { "no-rewrap", 'R', 0, OptionArg.NONE, ref no_rewrap,
        "Disable rewrapping on resize", null },
      { "no-shell", 'S', 0, OptionArg.NONE, ref no_shell,
        "Disable spawning a shell inside the terminal", null },
      { "object-notifications", 'N', 0, OptionArg.NONE, ref object_notifications,
        "Print VteTerminal object notifications", null },
      { "output-file", 0, 0, OptionArg.FILENAME, ref output_filename,
        "Save terminal contents to file at exit", null },
      { "reverse", 0, 0, OptionArg.NONE, ref reverse,
        "Reverse foreground/background colors", null },
      { "scrollback-lines", 'n', 0, OptionArg.INT, ref scrollback_lines,
        "Specify the number of scrollback-lines", null },
      { "transparent", 'T', 0, OptionArg.INT, ref transparency_percent,
        "Enable the use of a transparent background", "0..100" },
      { "version", 0, 0, OptionArg.NONE, ref version,
        "Show version", null },
      { "windows", 0, 0, OptionArg.INT, ref n_windows,
        "Open multiple windows (default: 1)", "NUMBER" },
      { "word-char-exceptions", 0, 0, OptionArg.STRING, ref word_char_exceptions,
        "Specify the word char exceptions", "CHARS" },
      { "working-directory", 'w', 0, OptionArg.FILENAME, ref working_directory,
        "Specify the initial working directory of the terminal", null },
      { null }
    };
  }

  public static int main(string[] argv)
  {
    Intl.setlocale (LocaleCategory.ALL, "");

    if (Environment.get_variable("VTE_CJK_WIDTH") != null) {
      printerr("VTE_CJK_WIDTH is not supported anymore, use --cjk-width instead\n");
    }
    /* Not interested in silly debug spew, bug #749195 */
    if (Environment.get_variable("G_ENABLE_DIAGNOSTIC") == null) {
      Environment.set_variable("G_ENABLE_DIAGNOSTIC", "0", true);
    }
    Environment.set_prgname("vte-app");
    Environment.set_application_name("Terminal");

    try {
      var context = new OptionContext("— simple VTE test application");
      context.set_help_enabled(true);
      context.add_main_entries(Options.entries, null);
      context.add_group(Gtk.get_option_group(true));
      context.parse(ref argv);
    } catch (OptionError e) {
      printerr("Error parsing arguments: %s\n", e.message);
      return 1;
    }

    if (Options.version) {
      print("Simple VTE Test Application %s\n", Config.VERSION);
      return 0;
    }

    if (Options.debug)
      Gdk.Window.set_debug_updates(Options.debug);

    var app = new App();
    return app.run(null);
  }
} /* class App */

} /* namespace */
