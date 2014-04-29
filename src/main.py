#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2011 ~ 2013 Deepin, Inc.
#               2011 ~ 2012 Wang Yong
# 
# Author:     Wang Yong <lazycat.manatee@gmail.com>
# Maintainer: Wang Yong <lazycat.manatee@gmail.com>
#             Yueqian Zhang <nohappiness@gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from collections import OrderedDict
from contextlib import contextmanager 
from deepin_utils.config import Config
from deepin_utils.core import unzip, is_int, merge_list
from deepin_utils.file import get_parent_dir
from deepin_utils.file import remove_path, touch_file
from deepin_utils.font import get_font_families
from deepin_utils.process import run_command, get_command_output_first_line
from dtk.ui.constant import WIDGET_POS_BOTTOM_LEFT, ALIGN_END, DEFAULT_FONT_SIZE
from dtk.ui.draw import draw_pixbuf, draw_text, draw_round_rectangle, draw_radial_ring, draw_vlinear
from dtk.ui.events import EventRegister
from dtk.ui.init_skin import init_skin
from dtk.ui.keymap import get_keyevent_name, get_key_name, is_no_key_press
from dtk.ui.label import Label
from dtk.ui.menu import Menu
from dtk.ui.constant import WIDGET_POS_CENTER
from dtk.ui.utils import (container_remove_all, get_match_parent, cairo_state, 
                          propagate_expose, is_left_button, is_right_button, 
                          is_in_rect, get_match_children, set_hover_cursor)
from dtk.ui.utils import place_center, get_widget_root_coordinate, get_screen_size
from dtk.ui.window import Window
from nls import _
from optparse import OptionParser
import cairo
import commands
import gc
import gobject
import gtk
import glib
import os
import pango
import sqlite3
import subprocess
import sys
import traceback
import urllib
import vte

PROJECT_NAME = "deepin-terminal"

app_theme = init_skin(
    PROJECT_NAME,
    "1.0",
    "07",
    os.path.join(get_parent_dir(__file__, 2), "skin"),
    os.path.join(get_parent_dir(__file__, 2), "app_theme")
)

from dtk.ui.application import Application
from dtk.ui.button import Button
from dtk.ui.button import ImageButton
from dtk.ui.button import SwitchButton
from dtk.ui.box import EventBox
from dtk.ui.color_selection import ColorButton
from dtk.ui.combo import ComboBox
from dtk.ui.dialog import DIALOG_MASK_GLASS_PAGE
from dtk.ui.dialog import DialogBox, ConfirmDialog
from dtk.ui.dialog import PreferenceDialog
from dtk.ui.draw import draw_hlinear
from dtk.ui.entry import Entry
from dtk.ui.entry import ShortcutKeyEntry, InputEntry, PasswordEntry
from dtk.ui.scalebar import HScalebar
from dtk.ui.scrolled_window import ScrolledWindow
from dtk.ui.skin_config import skin_config
from dtk.ui.spin import SpinBox
from dtk.ui.theme import ui_theme
from dtk.ui.treeview import TreeView, NodeItem, get_background_color, get_text_color
from dtk.ui.unique_service import UniqueService, is_exists
from dtk.ui.utils import color_hex_to_cairo, alpha_color_hex_to_cairo, cairo_disable_antialias
from tempfile import NamedTemporaryFile
import dbus

QUAKE_DBUS_NAME   = "com.deepin.terminal_quake"
QUAKE_OBJECT_NAME = "/com/deepin/terminal_quake"

UNIQUE_DBUS_NAME   = "com.deepin.terminal_unique"
UNIQUE_OBJECT_NAME = "/com/deepin/terminal_unique"

# Load customize rc style before any other.
PANED_HANDLE_SIZE = 2
gtk.rc_parse_string(
    """
    style 'my_style' {
        GtkPaned::handle-size = %s
        }

    widget '*' style 'my_style'
    """ % PANED_HANDLE_SIZE
)

global_event = EventRegister()
focus_terminal = None

STARTUP_MODE_ITEMS = [
    (_("Normal"), "normal"),
    (_("Maximize"), "maximize"),
    (_("Fullscreen"), "fullscreen")]

CURSOR_SHAPE_ITEMS =[(_("Block"), "block"),
                     (_("I-beam"), "ibeam"),
                     (_("Underline"), "underline")]

CURSOR_BLINK_MODE_ITEMS =[(_("System"), "system"),
                          (_("On"), "on"),
                          (_("Off"), "off")]
            
WORKSPACE_SNAPSHOT_HEIGHT = 160
WORKSPACE_SNAPSHOT_OFFSET_TOP = 10
WORKSPACE_SNAPSHOT_OFFSET_BOTTOM = 30
WORKSPACE_SNAPSHOT_OFFSET_X = 10

WORKSPACE_ADD_SIZE = 48
WORKSPACE_ADD_PADDING = 30
WORKSPACE_ADD_MIDDLE_SIZE = 8

CONFIRM_DIALOG_WIDTH = 450
CONFIRM_DIALOG_HEIGHT = 150
CONFIRM_WRAP_WIDTH = 350

DRAG_TEXT_URI = 1
DRAG_TEXT_PLAIN = 2

TABLE_ROW_SPACING = 8
TABLE_COLUMN_SPACING = 4
TABLE_PADDING_LEFT = 50
TABLE_PADDING_TOP = 30
TABLE_PADDING_BOTTOM = 30

HOTKEYS_WINDOW_MIN_WIDTH = 960
HOTKEYS_WINDOW_MIN_HEIGHT = 540

TRANSPARENT_OFFSET = 0.1
MIN_TRANSPARENT = 0.2

SEARCH_BAR_PADDING = 6

_HOME = os.path.expanduser('~')
XDG_CONFIG_HOME = os.environ.get('XDG_CONFIG_HOME') or \
            os.path.join(_HOME, '.config')

# NOTE:
# We just store remote information (include password) in sqlite database.
# please don't fill password if you care about safety problem.
LOGIN_DATABASE = os.path.join(XDG_CONFIG_HOME, PROJECT_NAME, ".config", "login.db")

BACKUP_FONT = "DejaVu Sans Mono"

GENERAL_CONFIG = [
    ("font", "文泉驿等宽微米黑"),
    ("font_size", "11"),
    ("color_scheme", "deepin"), 
    ("font_color", "#00FF00"),
    ("background_color", "#000000"),
    ("background_transparent", "0.8"),
    ]

KEYBIND_CONFIG = [
    ("copy_clipboard", "Ctrl + Shift + c"),
    ("paste_clipboard", "Ctrl + Shift + v"),
    ("split_vertically", "Ctrl + Shift + h"),
    ("split_horizontally", "Ctrl + h"),
    ("close_current_window", "Ctrl + Shift + w"),
    ("close_other_window", "Ctrl + Shift + q"),
    ("scroll_page_up", "Alt + ,"),
    ("scroll_page_down", "Alt + ."),
    ("focus_up_terminal", "Alt + k"),
    ("focus_down_terminal", "Alt + j"),
    ("focus_left_terminal", "Alt + h"),
    ("focus_right_terminal", "Alt + l"),
    ("zoom_out", "Ctrl + ="),
    ("zoom_in", "Ctrl + -"),
    ("revert_default_size", "Ctrl + 0"),
    ("new_workspace", "Ctrl + /"),
    ("close_current_workspace", "Ctrl + Shift + :"),
    ("switch_prev_workspace", "Ctrl + Shift + <"),
    ("switch_next_workspace", "Ctrl + Shift + >"),
    ("search_forward", "Ctrl + '"),
    ("search_backward", "Ctrl + \""),
    ("toggle_full_screen", "F11"),
    ("show_helper_window", "Ctrl + Shift + ?"),
    ("show_remote_login_window", "Ctrl + 9"),
    ("show_correlative_window", "Ctrl + 8"),
    ]

ADVANCED_CONFIG = [
    ("startup_mode", "normal"),
    ("startup_command", ""),
    ("startup_directory", ""),
    ("cursor_shape", "block"),
    ("cursor_blink_mode", "system"),
    ("ask_on_quit", "True"),
    ("scroll_on_key", "True"),
    ("scroll_on_output", "False"),
    ("copy_on_selection", "False"),
    ("open_file_on_hover", "False"),
    ]

DEFAULT_CONFIG = [
    ("general", GENERAL_CONFIG),
    ("keybind", KEYBIND_CONFIG),
    ("advanced", ADVANCED_CONFIG),
    ("save_state",
     [("window_width", "664"),
      ("window_height", "446"),
      ])
    ]

color_style = {
    "deepin" : (_("Deepin"), ["#00BB00", "#000000"]),
    "mocha" : (_("Mocha"), ["#BEB55B", "#3B3228"]),
    "green_screen" : (_("Green screen"), ["#00BB00", "#001100"]),
    "ocean" : (_("Ocean"), ["#A3BE8C", "#2B303B"]),
    "monokai" : (_("Monokai"), ["#A6E22E", "#272822"]),
    "solarized" : (_("Solarized"), ["#859900", "#002B36"]),
    "eighties" : (_("Eighties"), ["#99CC99", "#2D2D2D"]),
    "eighties" : (_("Eighties"), ["#99CC99", "#2D2D2D"]),
    "grey_on_black": (_("Grey on black"), ["#aaaaaa", "#000000"]),
    "black_on_yellow": (_("Black on yellow"), ["#000000", "#ffffdd"]),
    "black_on_white": (_("Black on white"), ["#000000", "#ffffff"]),
    "white_on_black": (_("White on black"), ["#ffffff", "#000000"]),
    "green_on_black": (_("Green on black"), ["#00ff00", "#000000"]),
    "custom" : (_("Custom"), ["#00FF00", "#000000"]),
    }

COMBO_BOX_WIDTH = 150

MATCH_URL = 1
MATCH_FILE = 2
MATCH_DIRECTORY = 3
MATCH_COMMAND = 4

MIN_FONT_SIZE = 8

def is_bool(string_value):
    if isinstance(string_value, bool):
        return string_value
    else:
        return string_value.lower() == "true"

def get_active_working_directory(toplevel_widget):
    '''
    Get active working directory with given toplevel widget.
    
    @param toplevel_widget: Toplevel widget, it's gtk.Window type.
    
    @return: Return working directory of focus terminal, return None if nothing to focus.
    '''
    focus_widget = toplevel_widget.get_focus()
    if focus_widget and isinstance(focus_widget, TerminalWrapper):
        return focus_widget.get_working_directory()
    else:
        return None
    
def do_copy_on_selection_toggle(terminal):
    terminal.copy_clipboard()

def kill_processes(process_ids):
    if len(process_ids) > 0:
        subprocess.Popen("kill %s" % ' '.join(process_ids), shell=True)
    
def get_terminal_child_pids(terminal):
    return filter(lambda pid: pid != '', commands.getoutput("pgrep -P %s" % terminal.process_id).split("\n"))

def get_terminals_child_pids(terminals):
    return merge_list(map(get_terminal_child_pids, terminals))

def create_confirm_dialog(dialog_title, dialog_content, confirm_callback, toplevel):
    dialog = ConfirmDialog(
        dialog_title,
        dialog_content,
        confirm_callback=confirm_callback,
        default_width=CONFIRM_DIALOG_WIDTH,
        default_height=CONFIRM_DIALOG_HEIGHT,
        text_wrap_width=CONFIRM_WRAP_WIDTH,
        )
    dialog.show_all()
    place_center(toplevel, dialog)
    
class Terminal(object):
    """
    Terminal class.
    """

    def __init__(self, 
                 quake_mode=False, 
                 working_directory=None,
                 cmdline_startup_command=None,
                 ):
        """
        Init Terminal class.
        """
        self.quake_mode = quake_mode
        self.working_directory = working_directory
        self.cmdline_startup_command = cmdline_startup_command
        
        if self.quake_mode:
            UniqueService(
                dbus.service.BusName(QUAKE_DBUS_NAME, bus=dbus.SessionBus()),
                QUAKE_DBUS_NAME, 
                QUAKE_OBJECT_NAME,
                self.quake,
            )
        
        terminal_has_running = is_exists(UNIQUE_DBUS_NAME, UNIQUE_OBJECT_NAME)
            
        self.application = Application(
            destroy_func=self.quit,
            always_at_center=not terminal_has_running
        )
        
        if not terminal_has_running:
            UniqueService(
                dbus.service.BusName(UNIQUE_DBUS_NAME, bus=dbus.SessionBus()),
                UNIQUE_DBUS_NAME, 
                UNIQUE_OBJECT_NAME,
            )
            
        default_window_width = 664
        default_window_height = 466
        window_width = int(get_config("save_state", "window_width", default_window_width))
        window_height = int(get_config("save_state", "window_height", default_window_height))
        window_min_width = 200
        window_min_height = 150
        self.application.window.set_default_size(window_width, window_height)
        self.application.window.set_geometry_hints(
            None,
            window_min_width,
            window_min_height,
            -1, -1, -1, -1, -1, -1, -1, -1
            )
        
        self.application.add_titlebar(
            app_name = _("Deepin Terminal"),
            name_size=11,
            title_size=11,
            button_mask=["menu", "max", "min", "close"],
            )
        self.application.titlebar.set_size_request(-1, 30)
        self.application.set_skin_preview(os.path.join(get_parent_dir(__file__, 2), "image", "preview.png"))
        skin_config.set_application_window_size(default_window_width, default_window_height)

        self.normal_padding = 2
        self.fullscreen_padding = 0
        self.terminal_align = gtk.Alignment()
        self.terminal_align.set(0, 0, 1, 1)
        self.terminal_align.set_padding(0, 0, self.normal_padding, self.normal_padding)
        self.terminal_box = gtk.VBox()
        self.terminal_align.add(self.terminal_box)
        
        self.statusbar = Statusbar()
        self.statusbar_box = gtk.HBox()
        
        self.application.main_box.pack_start(self.terminal_align)
        self.application.main_box.pack_start(self.statusbar_box, False, False)
        
        self.workspace_list = []
        self.first_workspace()
        
        self.application.window.show_window()
        
        self.workspace_switcher = WorkspaceSwitcher(
            self.get_workspaces,
        )
        self.workspace_switcher_y_offset = 0
        self.is_full_screen = False
        self.search_bar = SearchBar()
        self.helper_window = HelperWindow()
        self.remote_login = RemoteLogin()
        self.terminal_num_window = TerminalNumWindow()
        
        self.is_window_resize_by_user = False
        
        self.generate_keymap()
        
        self.general_settings = GeneralSettings()
        self.keybind_settings = KeybindSettings()
        self.advanced_settings = AdvancedSettings()
        
        self.preference_dialog = SettingDialog()
        self.preference_dialog.set_preference_items(
            [(_("General"), self.general_settings),
             (_("Hotkeys"), self.keybind_settings),
             (_("Advanced"), self.advanced_settings),
             ])
        self.application.titlebar.menu_button.connect("button-press-event", self.show_preference_menu)
        self.application.window.connect("destroy", lambda w: self.quit())
        self.application.window.connect("delete-event", self.delete_window)
        self.application.window.connect("button-press-event", self.button_press_terminal)
        self.application.window.connect("key-press-event", self.key_press_terminal)
        self.application.window.connect("key-release-event", self.key_release_terminal)
        self.application.window.connect("notify::is-active", self.window_is_active)
        self.application.window.connect("window-state-event", self.window_state_change)
        self.application.window.connect("window-resize", self.set_window_resize)
        
        self.draw_skin_padding = 2
        self.application.window.draw_skin = self.draw_terminal_skin
        
        global_event.register_event("close-workspace", self.close_workspace)
        global_event.register_event("close-terminal-workspace", lambda w: self.close_workspace(w, True))
        global_event.register_event("switch-to-workspace", self.switch_to_workspace)
        global_event.register_event("change-path", self.change_path)
        global_event.register_event("show-menu", self.show_menu)
        global_event.register_event("show-terminal-num-window", self.show_terminal_num_window)
        global_event.register_event("xdg-open", lambda command: run_command("xdg-open %s" % command))
        global_event.register_event("change-background-transparent", self.change_background_transparent)
        global_event.register_event("adjust-background-transparent", self.adjust_background_transparent)
        global_event.register_event("scroll-on-key-toggle", self.scroll_on_key_toggle)
        global_event.register_event("scroll-on-output-toggle", self.scroll_on_output_toggle)
        global_event.register_event("copy-on-selection-toggle", self.copy_on_selection_toggle)
        global_event.register_event("open-file-on-hover-toggle", self.open_file_on_hover_toggle)
        global_event.register_event("set-cursor-shape", self.set_cursor_shape)
        global_event.register_event("set-cursor-blink-mode", self.set_cursor_blink_mode)
        global_event.register_event("change-font", self.change_font)
        global_event.register_event("change-font-size", self.change_font_size)
        global_event.register_event("change-color-scheme", self.change_color_scheme)
        global_event.register_event("change-font-color", self.change_color_scheme)
        global_event.register_event("change-background-color", self.change_color_scheme)
        global_event.register_event("keybind-changed", self.keybind_change)
        global_event.register_event("ssh-login", self.ssh_login)
        global_event.register_event("new-workspace", self.new_workspace)
        global_event.register_event("quit", self.quit)
        
        if self.quake_mode:
            self.fullscreen()
            
    def show_statusbar(self):
        container_remove_all(self.statusbar_box)
        self.statusbar_box.add(self.statusbar)
        
        self.statusbar_box.show_all()
        
    def hide_statusbar(self):
        container_remove_all(self.statusbar_box)
            
    def draw_terminal_skin(self, cr, x, y, w, h):
        statusbar_height = self.statusbar.height
        cr.rectangle(x, y, w, h - statusbar_height)
        cr.rectangle(x, y + h - statusbar_height, self.draw_skin_padding, statusbar_height)
        cr.rectangle(x + w - self.draw_skin_padding, y + h - statusbar_height, self.draw_skin_padding, statusbar_height)
        cr.rectangle(x, y + h - self.draw_skin_padding, w, self.draw_skin_padding)
        cr.clip()
        
        super(Window, self.application.window).draw_skin(cr, x, y, w, h)
            
    def zoom_in_window(self):
        pass
    
    def zoom_out_window(self):
        pass
    
    def update_window_size(self):
        pass
        
    def button_press_terminal(self, widget, event):
        if self.workspace_switcher.get_visible():
            self.workspace_switcher.hide_switcher()
            
    def set_window_resize(self, widget):
        self.is_window_resize_by_user = True
            
    def save_window_size(self):        
        if self.is_window_resize_by_user:
            window_rect = self.application.window.get_allocation()
            (window_width, window_height) = window_rect.width, window_rect.height
            with save_config(setting_config):
                setting_config.config.set("save_state", "window_width", window_width)
                setting_config.config.set("save_state", "window_height", window_height)
            
    def _quit(self):
        if not self.quake_mode:
            self.save_window_size()
            
        gtk.main_quit()
            
    def delete_window(self, widget, event):
        self.quit()
        
        return True
        
    def quit(self):
        child_pids = get_terminals_child_pids(self.get_all_terminals())
        
        ask_on_quit = is_bool(get_config("advanced", "ask_on_quit"))
        
        if not ask_on_quit or len(child_pids) == 0:
            self._quit()
        elif len(child_pids) > 0:
            create_confirm_dialog(
                _("Quit terminal?"),
                _("Terminal still have running programs. Are you sure you want to quit?"),
                self._quit,
                self.application.window,
                )
            
    def window_state_change(self, widget, event):
        if focus_terminal:
            focus_terminal.grab_focus()
        
        glib.timeout_add(10, self.adjust_terminal_padding)
            
    def adjust_terminal_padding(self):        
        if self.application.window.allocation.width == gtk.gdk.screen_width():
            self.terminal_align.set_padding(0, 0, 0, 0)
            
            self.statusbar.set_padding(0, 0, 0, 0)
            self.statusbar.adjust_padding(0, 0, 0, 0)
            self.draw_skin_padding = 0
        else:
            if len(self.workspace_list) > 1:
                self.terminal_align.set_padding(0, 0, self.normal_padding, self.normal_padding)
            else:
                self.terminal_align.set_padding(0, self.normal_padding, self.normal_padding, self.normal_padding)
            
            self.statusbar.set_padding(0, self.normal_padding, self.normal_padding, self.normal_padding)
            self.statusbar.adjust_padding(0, self.normal_padding, self.normal_padding, self.normal_padding)
            self.draw_skin_padding = 2
                    
    def window_is_active(self, window, param):
        global focus_terminal
        
        # Focus terminal when window active.
        if window.props.is_active:
            if focus_terminal:
                focus_terminal.grab_focus()
        else:
            if self.terminal_num_window.get_visible():
                self.terminal_num_window.hide()
                
            if self.workspace_switcher.get_visible():
                self.workspace_switcher.hide()
        
    def quake(self):
        global focus_terminal
        
        if self.application.window.get_visible():
            if self.application.window.props.is_active:
                self.application.window.hide_all()
            else:
                self.application.window.present()
        else:
            self.application.window.show_all()
            self.fullscreen()
        
        if focus_terminal:
            focus_terminal.grab_focus()
        
    def ssh_login(self, user, server, password, port):
        active_terminal = self.application.window.get_focus()
        if active_terminal and isinstance(active_terminal, TerminalWrapper):
            with open(os.path.join(get_parent_dir(__file__), "ssh_login.sh")) as file:
                content = ''.join(file.readlines())
            content = content.replace("<<USER>>", user)
            content = content.replace("<<SERVER>>", server)
            content = content.replace("<<PASSWORD>>", password)
            content = content.replace("<<PORT>>", port)
            
            # create temporary expect script file, and the file will
            # be delete by itself
            with NamedTemporaryFile(delete=False) as tempfile:
                tempfile.write(content)
            active_terminal.feed_child("expect -f " + tempfile.name + "\n")
        
    def keybind_change(self, key_value, new_key):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.generate_keymap()
            
        self.generate_keymap()    
        self.search_bar.generate_keymap()
        
    def generate_keymap(self):
        get_keybind = lambda key_value: get_config("keybind", key_value)
        
        key_values = [
            "toggle_full_screen",
            "new_workspace",
            "search_forward",
            "show_helper_window",
            "show_remote_login_window",
            "focus_up_terminal",
            "focus_down_terminal",
            "focus_left_terminal",
            "focus_right_terminal",
            "switch_prev_workspace",
            "switch_next_workspace",
            "close_current_workspace",
            "close_other_window",
            ]
        
        self.keymap = {}
        
        for key_value in key_values:
            self.keymap[get_keybind(key_value)] = getattr(self, key_value)
            
        self.switch_prev_workspace_key = get_keybind("switch_prev_workspace")    
        self.switch_next_workspace_key = get_keybind("switch_next_workspace")    
        
    def show_remote_login_window(self):    
        self.remote_login.show_login(
            self.application.window,
            )
                
    def change_color_scheme(self, value):
        font_color = get_config("general", "font_color")
        background_color = get_config("general", "background_color")
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.change_color(font_color, background_color)
                terminal.background_update()
            
    def change_font(self, font):    
        font_size = get_config("general", "font_size")
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.change_font(font, font_size)

    def change_font_size(self, font_size):    
        font = get_config("general", "font")
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.change_font(font, font_size)
        
    def set_cursor_shape(self, cursor_shape):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.change_cursor_shape(cursor_shape)

    def set_cursor_blink_mode(self, cursor_blink_mode):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.change_cursor_blink_mode(cursor_blink_mode)
        
    def scroll_on_key_toggle(self, status):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.set_scroll_on_keystroke(status)

    def scroll_on_output_toggle(self, status):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.set_scroll_on_output(status)
        
    def copy_on_selection_toggle(self, status):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                if status:
                    terminal.connect("selection-changed", do_copy_on_selection_toggle)
                else:
                    try:
                        terminal.disconnect_by_func(do_copy_on_selection_toggle)
                    except:
                        pass
                
    def open_file_on_hover_toggle(self, status):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                if status:
                    terminal.add_file_match_tag()
                else:
                    terminal.remove_file_match_tag()
        
    def adjust_background_transparent(self, direction):
        if not direction in [gtk.gdk.SCROLL_UP, gtk.gdk.SCROLL_DOWN]:
            return
        
        transparent = get_config("general", "background_transparent")
        if direction == gtk.gdk.SCROLL_UP:
            transparent = min(float(transparent) + TRANSPARENT_OFFSET, 1.0)
        elif direction == gtk.gdk.SCROLL_DOWN:
            transparent = max(float(transparent) - TRANSPARENT_OFFSET, MIN_TRANSPARENT)
            
        with save_config(setting_config):    
            setting_config.config.set("general", "background_transparent", transparent)
        
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.set_transparent(float(transparent))
                
                # Use background_update to update opacity of terminal.
                terminal.background_update()
        
    def change_background_transparent(self, transparent):
        for workspace in self.workspace_list:
            for terminal in get_match_children(workspace, TerminalWrapper):
                terminal.set_transparent(float(transparent))
                
                # Use background_update to update opacity of terminal.
                terminal.background_update()
            
    def show_preference_menu(self, widget, event):
        menu_items = [
            (None, _("Preferences"), self.show_preference_dialog),
            (None, _("Set up SSH connection"), self.show_remote_login_window),
            (None, _("Display hotkeys"), self.show_helper_window),
            # (None, _("See what's new"), None),
            (None, _("Quit"), self.quit),
            ]
        menu = Menu(menu_items, True)
        menu.show(
            get_widget_root_coordinate(widget, WIDGET_POS_BOTTOM_LEFT),
            (widget.get_allocation().width, 0)
            )
        
    def show_preference_dialog(self):
        self.preference_dialog.show_all()
        
    def show_helper_window(self):
        self.helper_window.show_help(
            self.application.window,
            get_active_working_directory(self.application.window),
            )
        
    def show_terminal_num_window(self, x, y, width, height):
        terminals = get_match_children(self.application.window, TerminalWrapper)
        if len(terminals) > 1:
            workspace = self.terminal_box.get_children()[0]
            (workspace_x, workspace_y) = workspace.translate_coordinates(self.application.window, 0, 0)
            (shadow_with, shadow_height) = self.application.window.get_shadow_size()
            
            self.terminal_num_window.show_window(
                x, y, width, height,
                map(lambda (terminal_index, terminal): 
                    (terminal_index + 1, 
                     (terminal.allocation.x - shadow_with,
                      terminal.allocation.y - workspace_y)), enumerate(terminals[0:10])))
        
    def show_menu(self, terminal, has_selection, match_text, correlative_window_ids, (x_root, y_root)):
        # Build menu.
        menu_items = []
        if has_selection:
            menu_items.append((None, _("Copy"), terminal.copy_clipboard))
        else:
            if match_text:
                menu_items.append((None, _("Copy"), terminal.copy_text(match_text[0])))
            
        menu_items.append((None, _("Paste"), terminal.paste_clipboard))    
            
        if match_text:
            match_info = terminal.get_match_type(match_text)
            if match_info:
                (match_type, match_string) = match_info
                if match_type == MATCH_FILE:
                    menu_name = _("Open file")
                if match_type == MATCH_DIRECTORY:
                    menu_name = _("Open directory")
                elif match_type == MATCH_URL:
                    menu_name = _("Open URL")
                elif match_type == MATCH_COMMAND:
                    menu_name = _("Open manual")
                    
                menu_items.append((None, menu_name, lambda : terminal.open_match_string(match_type, match_string)))
                
        menu_items.append((None, _("Clear screen"), terminal.clear))
        menu_items.append((None, _("Open current directory"), lambda : terminal.open_match_string(MATCH_DIRECTORY, terminal.get_working_directory())))        
                
        if correlative_window_ids != None and correlative_window_ids != [""]:
            menu_items.append((
                    None,
                    _("Show correlative child window"), lambda : terminal.show_correlative_window(correlative_window_ids)))
            
        if self.is_full_screen:
            fullscreen_item_text = _("Exit fullscreen")
        else:
            fullscreen_item_text = _("Fullscreen")
            
        (focus_terminal, terminals) = self.get_all_terminal_infos()
        terminal_items = [
            None,
            (None, _("Split vertically"), lambda : terminal.parent_widget.split(TerminalGrid.SPLIT_VERTICALLY)),
            (None, _("Split horizontally"), lambda : terminal.parent_widget.split(TerminalGrid.SPLIT_HORIZONTALLY)),
            (None, _("Close current window"), terminal.close_current_window),
            ]
        if len(terminals) >= 1:
            terminal_items += [
                (None, _("Close other window"), self.close_other_window),
                ]
        
        if len(self.get_workspaces()) > 1:
            current_workspace = self.terminal_box.get_children()[0]
            
            workspace_items = [
                None,
                (None, _("New workspace"), self.new_workspace),
                (None, _("Switch workspace"), self.show_workspace),
                (None, "%s%s" % (_("Close workspace"), current_workspace.workspace_index), self.close_current_workspace),
                ]
        else:
            workspace_items = [
                None,
                (None, _("New workspace"), self.new_workspace),
                ]
            
        menu_items += terminal_items + workspace_items + [
            None,
            (None, fullscreen_item_text, self.toggle_full_screen),
            (None, _("Search"), self.search_forward),
            (None, _("Display hotkeys"), self.show_helper_window),
            None,
            (None, _("Preferences"), self.show_preference_dialog),
            ]
        
        menu = Menu(menu_items, True)
        
        # Show menu.
        menu.show((x_root, y_root))
        
    def get_all_terminal_infos(self):
        focus_terminal = self.application.window.get_focus()
        terminals = get_match_children(self.application.window, TerminalWrapper)
        terminals.remove(focus_terminal)
        return (focus_terminal, terminals)
        
    def close_other_window(self):
        (focus_terminal, terminals) = self.get_all_terminal_infos()
        for terminal in terminals:
            terminal.close_current_window()
        
    def focus_vertical_terminal(self, up=True):
        # Get all terminal information.
        (focus_terminal, terminals) = self.get_all_terminal_infos()
        rect = focus_terminal.allocation
        x, y, w, h = rect.x, rect.y, rect.width, rect.height
        
        # Find terminal intersects with focus one.
        def is_same_coordinate(t):
            if up:
                return t.allocation.y + t.allocation.height + PANED_HANDLE_SIZE == y
            else:
                return t.allocation.y == y + h + PANED_HANDLE_SIZE
            
        intersectant_terminals = filter(
            lambda t: 
            (is_same_coordinate(t) and
             t.allocation.x < x + w + PANED_HANDLE_SIZE and 
             t.allocation.x + t.allocation.width + PANED_HANDLE_SIZE > x),
            terminals)
        if len(intersectant_terminals) > 0:
            # Focus terminal if y coordinate is same.
            same_coordinate_terminals = filter(
                lambda t: 
                t.allocation.x == x,
                intersectant_terminals)
            if len(same_coordinate_terminals) > 0:
                same_coordinate_terminals[0].grab_focus()
            else:
                # Focus terminal if it's height than focus one.
                bigger_match_terminals = filter(
                    lambda t: 
                    (t.allocation.x < x and 
                     t.allocation.x + t.allocation.width >= x + w),
                    intersectant_terminals)
                if len(bigger_match_terminals) > 0:
                    bigger_match_terminals[0].grab_focus()
                else:
                    # Focus biggest intersectant area one.
                    intersectant_area_infos = map(
                        lambda t:
                            (t, 
                             (t.allocation.width + w - abs(t.allocation.x - x) - abs(t.allocation.x + t.allocation.width - x - w) / 2)),
                        intersectant_terminals)
                    biggest_intersectant_terminal = sorted(intersectant_area_infos, key=lambda (_, area): area, reverse=True)[0][0]
                    biggest_intersectant_terminal.grab_focus()
    
    def focus_horizontal_terminal(self, left=True):                
        # Get all terminal information.
        (focus_terminal, terminals) = self.get_all_terminal_infos()
        rect = focus_terminal.allocation
        x, y, w, h = rect.x, rect.y, rect.width, rect.height
        
        # Find terminal intersectant with focus one.
        def is_same_coordinate(t):
            if left:
                return t.allocation.x + t.allocation.width + PANED_HANDLE_SIZE == x
            else:
                return t.allocation.x == x + w + PANED_HANDLE_SIZE
            
        intersectant_terminals = filter(
            lambda t: 
            (is_same_coordinate(t) and
             t.allocation.y < y + h + PANED_HANDLE_SIZE and 
             t.allocation.y + t.allocation.height + PANED_HANDLE_SIZE > y),
            terminals)
        if len(intersectant_terminals) > 0:
            # Focus terminal if y coordinate is same.
            same_coordinate_terminals = filter(
                lambda t: 
                t.allocation.y == y,
                intersectant_terminals)
            if len(same_coordinate_terminals) > 0:
                same_coordinate_terminals[0].grab_focus()
            else:
                # Focus terminal if it's height than focus one.
                bigger_match_terminals = filter(
                    lambda t: 
                    (t.allocation.y < y and 
                     t.allocation.y + t.allocation.height >= y + h),
                    intersectant_terminals)
                if len(bigger_match_terminals) > 0:
                    bigger_match_terminals[0].grab_focus()
                else:
                    # Focus biggest intersectant area one.
                    intersectant_area_infos = map(
                        lambda t:
                            (t, 
                             (t.allocation.height + h - abs(t.allocation.y - y) - abs(t.allocation.y + t.allocation.height - y - h) / 2)),
                        intersectant_terminals)
                    biggest_intersectant_terminal = sorted(intersectant_area_infos, key=lambda (_, area): area, reverse=True)[0][0]
                    biggest_intersectant_terminal.grab_focus()
                    
    def focus_up_terminal(self):
        self.focus_vertical_terminal(True)
        
    def focus_down_terminal(self):
        self.focus_vertical_terminal(False)
    
    def focus_left_terminal(self):
        self.focus_horizontal_terminal(True)

    def focus_right_terminal(self):
        self.focus_horizontal_terminal(False)
        
    def get_all_terminals(self):
        return merge_list(map(lambda workspace: get_match_children(workspace, TerminalWrapper), self.workspace_list))
        
    def get_workspace_terminals(self, workspace):
        return get_match_children(workspace, TerminalWrapper)
        
    def get_workspaces(self):
        children = self.terminal_box.get_children()
        if len(children) == 1:
            child = children[0]
            if child and isinstance(child, Workspace):
                child.save_workspace_snapshot()
        
        return self.workspace_list
    
    def switch_to_workspace(self, workspace_index):
        workspace = self.workspace_list[workspace_index]
        current_workspace = self.terminal_box.get_children()[0]
        if workspace != current_workspace:
            current_workspace.save_focus_terminal()
            
            self.remove_current_workspace()
            self.terminal_box.add(workspace)
            self.terminal_box.show_all()
            
            workspace.restore_focus_terminal()
            
        self.update_workspace_indicator()
        
    def remove_current_workspace(self, save_snapshot=True):
        children = self.terminal_box.get_children()
        if len(children) == 1:
            child = children[0]
            if child and isinstance(child, Workspace):
                child.save_workspace_snapshot()
                self.terminal_box.remove(child)
        
    def first_workspace(self):
        self.new_workspace(self.working_directory, self.cmdline_startup_command)
        
    def update_workspace_indicator(self):
        self.statusbar.workspace_indicator.workspaces = map(lambda workspace: workspace.workspace_index, self.workspace_list)
        self.statusbar.workspace_indicator.current_workspace_index = self.terminal_box.get_children()[0].workspace_index
        
        if len(self.workspace_list) > 1:
            self.show_statusbar()
            
            if self.application.window.allocation.width == gtk.gdk.screen_width():
                self.terminal_align.set_padding(0, 0, 0, 0)
            else:
                self.terminal_align.set_padding(0, 0, self.normal_padding, self.normal_padding)
        else:
            self.hide_statusbar()
            
            if self.application.window.allocation.width == gtk.gdk.screen_width():
                self.terminal_align.set_padding(0, self.normal_padding, 0, 0)
            else:
                self.terminal_align.set_padding(0, self.normal_padding, self.normal_padding, self.normal_padding)
            
    def get_workspace_index(self):
        if len(self.workspace_list) == 0:
            return 1
        else:
            workspace_indexes = map(lambda w: w.workspace_index, self.workspace_list)
            max_index = max(workspace_indexes) + 1
            
            for workspace_index in range(1, max_index):
                if workspace_index not in workspace_indexes:
                    return workspace_index
                
            return max_index
        
    def new_workspace(self, working_directory=None, cmdline_startup_command=None):
        if working_directory == None or not(os.path.exists(working_directory)):
            working_directory = get_active_working_directory(self.application.window)
        
        workspace = Workspace(self.get_workspace_index())
        terminal_grid = TerminalGrid(
            working_directory=working_directory, 
            cmdline_startup_command=cmdline_startup_command,
            )
        workspace.add(terminal_grid)
        
        self.remove_current_workspace()
        self.terminal_box.add(workspace)
        self.terminal_box.show_all()
        
        self.workspace_list.append(workspace)
        self.workspace_list = sorted(self.workspace_list, key=lambda w: w.workspace_index)
        
        self.update_workspace_indicator()
        
    def _close_workspace(self, workspace, child_pids):
        workspace_index = self.workspace_list.index(workspace)            
        
        # Kill child processes in current workspace.
        kill_processes(child_pids)
            
        # Remove workspace from list.
        if workspace in self.workspace_list:
            self.workspace_list.remove(workspace)
            
        # Show previous workspace.
        if len(self.workspace_list) > 0:
            self.remove_current_workspace(False)
            self.terminal_box.add(self.workspace_list[workspace_index - 1])
            self.terminal_box.show_all()
            
        self.update_workspace_indicator()    
        
    def close_workspace(self, workspace, close_by_terminal=False):    
        if len(self.workspace_list) == 1:
            global_event.emit("quit")
        else:        
            child_pids = get_terminals_child_pids(self.get_workspace_terminals(workspace))
            ask_on_quit = is_bool(get_config("advanced", "ask_on_quit"))
            
            if not ask_on_quit or len(child_pids) == 0:
                self._close_workspace(workspace, child_pids)
            elif len(child_pids) > 0:
                if close_by_terminal:
                    dialog_title = _("Close window?")
                    dialog_content = _("Window still have running programs. Are you sure you want to close?")
                else:
                    dialog_title = _("Close workspace?")
                    dialog_content = _("Workspace still have running programs. Are you sure you want to close?")
                
                create_confirm_dialog(
                    dialog_title,
                    dialog_content,
                    lambda : self._close_workspace(workspace, child_pids),
                    self.application.window,
                    )
            
    def change_path(self, path):
        self.statusbar.path_indicator.path = path
        self.statusbar.queue_draw()
        
    def close_current_workspace(self):
        children = self.terminal_box.get_children()
        if len(children) > 0:
            self.close_workspace(children[0])
        else:
            print "IMPOSSIBLE: no workspace in terminal_box"
            
        self.update_workspace_indicator()
            
    def get_workspace_switcher_coordinate(self):
        (x, y, w, h) = self.terminal_box.allocation
        (root_x, root_y) = self.terminal_box.window.get_origin()
        return root_x + x,\
            root_y + y + h - WORKSPACE_SNAPSHOT_HEIGHT - self.workspace_switcher_y_offset,\
            w,\
            WORKSPACE_SNAPSHOT_HEIGHT
            
    def get_current_workspace_index(self):
        current_workspace = self.terminal_box.get_children()[0]
        return self.workspace_list.index(current_workspace)
    
    def show_workspace(self):
        if not self.workspace_switcher.get_visible():
            self.workspace_switcher.show_switcher(
                self.get_current_workspace_index(),
                self.get_workspace_switcher_coordinate()
                )
    
    def switch_next_workspace(self):
        self.show_workspace()
            
        self.workspace_switcher.switch_next()
    
    def switch_prev_workspace(self):
        self.show_workspace()
            
        self.workspace_switcher.switch_prev()
            
    def search_forward(self):
        (x, y, w, h) = self.terminal_box.allocation
        (root_x, root_y) = self.terminal_box.window.get_origin()
        self.search_bar.show_bar(
            (root_x + x + w, root_y + y + SEARCH_BAR_PADDING),
            self.application.window.get_focus(),
            )
        
    def key_press_terminal(self, widget, event):
        """
        Key event callback
        :param widget: which sends the event.
        :param event: what event.
        """
        if event.is_modifier:
            key_name = get_key_name(event.keyval)
            if key_name in ["Alt_L", "Alt_R"]:
                workspace = self.terminal_box.get_children()[0]
                (workspace_x, workspace_y) = workspace.translate_coordinates(self.application.window, 0, 0)
                (window_x, window_y) = self.application.window.window.get_origin()
                self.show_terminal_num_window(
                    window_x + workspace_x,
                    window_y + workspace_y,
                    workspace.allocation.width,
                    workspace.allocation.height,
                    )
                
                return False
                
        key_name = get_keyevent_name(event)
        
        alt_keys = key_name.split("Alt + ")
        is_switch_terminal_key = False
        if len(alt_keys) == 2:
            terminal_num_str = alt_keys[1]
            if is_int(terminal_num_str):
                terminal_num = int(terminal_num_str)
                if terminal_num in range(0, 10):
                    if terminal_num == 0:
                        terminal_num = 10
                    
                    terminals = get_match_children(self.application.window, TerminalWrapper)
                    if terminal_num - 1 < len(terminals):
                        terminals[terminal_num - 1].grab_focus()
                        is_switch_terminal_key = True
                    
                        return True
           
        if not is_switch_terminal_key:
            self.terminal_num_window.hide()
            
            if key_name in self.keymap:
                # Hide switcher first when key not is workspace switch key. 
                if key_name not in [self.switch_prev_workspace_key, self.switch_next_workspace_key]:
                    self.workspace_switcher.hide_switcher()
                    
                self.keymap[key_name]()
                
                return True
            else:
                return False
        
    def key_release_terminal(self, widget, event):
        if self.workspace_switcher.get_visible():
            if is_no_key_press(event):
                self.switch_to_workspace(self.workspace_switcher.workspace_index)
                self.workspace_switcher.hide_switcher()
                
        if self.terminal_num_window.get_visible():
            if is_no_key_press(event):
                self.terminal_num_window.hide_all()
                
    def toggle_full_screen(self):
        """
        Switch between full_screen and normal window.
        """
        if self.is_full_screen:
            self.unfullscreen()
        else:
            self.fullscreen()

    def fullscreen(self):
        self.application.window.fullscreen()
        self.application.hide_titlebar()
        self.terminal_align.set_padding(
            0,
            self.fullscreen_padding,
            self.fullscreen_padding,
            self.fullscreen_padding
        )
        
        self.is_full_screen = True
        
        self.draw_skin_padding = 0
    
    def unfullscreen(self):
        self.application.window.unfullscreen()
        self.application.show_titlebar()
        self.terminal_align.set_padding(0, 0, self.normal_padding, self.normal_padding)
        
        self.is_full_screen = False    
        
        self.draw_skin_padding = 2
            
    def exit_fullscreen(self):
        if self.is_full_screen:
            self.toggle_full_screen()
        
    def run(self):
        """
        Main function.
        """
        startup_mode = get_config("advanced", "startup_mode", "normal")
        if startup_mode == "maximize":
            self.application.window.maximize()
        elif startup_mode == "fullscreen":
            self.toggle_full_screen()
            
        gtk.main()    

class TerminalWrapper(vte.Terminal):
    """
    Wrapper class for vte.Terminal. Propagate keys. Make some customize as well.
    """

    def __init__(self, 
                 parent_widget=None, 
                 working_directory=None,
                 command=None,
                 press_q_quit=False,
                 cmdline_startup_command=None,
                 ):
        """
        Initial values.
        :param parent_widget: which grid this widget belongs to.
        """
        vte.Terminal.__init__(self)
        self.parent_widget = parent_widget
        self.press_q_quit = press_q_quit
        self.set_word_chars("-A-Za-z0-9,./?%&#:_")
        self.set_scrollback_lines(-1)
        self.set_match_tag()
        
        self.change_color(
            get_config("general", "font_color"),
            get_config("general", "background_color")
            )
        
        transparent = get_config("general", "background_transparent")
        self.set_transparent(float(transparent))
        
        scroll_on_key = is_bool(get_config("advanced", "scroll_on_key"))
        self.set_scroll_on_keystroke(scroll_on_key)
        
        scroll_on_output = is_bool(get_config("advanced", "scroll_on_output"))
        self.set_scroll_on_output(scroll_on_output)
        
        copy_on_selection = is_bool(get_config("advanced", "copy_on_selection"))
        if copy_on_selection:
            self.connect("selection-changed", do_copy_on_selection_toggle)

        open_file_on_hover = is_bool(get_config("advanced", "open_file_on_hover"))
        if open_file_on_hover:
            self.add_file_match_tag()
        else:
            self.remove_file_match_tag()
        
        cursor_shape = get_config("advanced", "cursor_shape")
        self.change_cursor_shape(cursor_shape)
        
        cursor_blink_mode = get_config("advanced", "cursor_blink_mode")
        self.change_cursor_blink_mode(cursor_blink_mode)

        font = get_config("general", "font")
        self.default_font_size = int(get_config("general", "font_size"))
        self.current_font_size = self.default_font_size
        self.change_font(font, self.current_font_size)
        
        startup_directory = get_config("advanced", "startup_directory")
        directory = commands.getoutput("echo %s" % startup_directory)
        if os.path.exists(directory):
            os.chdir(directory)
        elif working_directory:
            # Use os.chdir and not child_feed("cd %s\n" % working_directory), 
            # this will make terminal with 'clear' init value.
            # child_feed have cd information after terminal created.
            os.chdir(working_directory)
            
        if cmdline_startup_command and cmdline_startup_command != "":
            if len(cmdline_startup_command) == 1:
                self.process_id = self.fork_command(cmdline_startup_command[0], [])
            else:
                self.process_id = self.fork_command("/bin/sh", cmdline_startup_command)
        else:
            startup_command = get_config("advanced", "startup_command")
            if startup_command == "":
                fork_command = os.getenv("SHELL")
            else:
                fork_command = startup_command
                
            self.process_id = self.fork_command(fork_command)
            
        if command:
            self.feed_child(command)

        # Key and signals
        self.generate_keymap()
        
        self.drag_dest_set(
            gtk.DEST_DEFAULT_MOTION |
            gtk.DEST_DEFAULT_DROP,
            [("text/uri-list", 0, DRAG_TEXT_URI),
             ("text/plain", 0, DRAG_TEXT_PLAIN),
             ],
            gtk.gdk.ACTION_COPY)
        
        self.connect("realize", self.realize_callback)
        self.connect("child-exited", self.child_exited)
        self.connect("key-press-event", self.handle_key_press)
        self.connect("drag-data-received", self.on_drag_data_received)
        self.connect("window-title-changed", self.on_window_title_changed)
        self.connect("grab-focus", lambda w: self.change_path())
        self.connect("button-press-event", self.on_button_press)
        self.connect("scroll-event", self.on_scroll)
        
    def set_match_tag(self):
        userchars = "-A-Za-z0-9"
        passchars = "-A-Za-z0-9,?;.:/!%$^*&~\"#'"
        hostchars = "-A-Za-z0-9"
        pathchars = "-A-Za-z0-9_$.+!*(),;:@&=?/~#%'\""
        schemes   = "(news:|telnet:|nntp:|file:/|https?:|ftps?:|webcal:)"
        user      = "[" + userchars + "]+(:[" + passchars + "]+)?"
        urlpath   = "/[" + pathchars + "]*[^]'.}>) \t\r\n,\\\"]"
        lboundry = "\\<"
        rboundry = "\\>"
        self.url_match_tag = self.match_add(
            lboundry + schemes + 
            "//(" + user + "@)?[" + hostchars  +".]+(:[0-9]+)?(" + 
            urlpath + ")?" + rboundry + "/?")
        self.match_set_cursor_type(self.url_match_tag, gtk.gdk.HAND2)
        
        self.file_match_tag = self.match_add("[^\t\n ]+")
        
    def add_file_match_tag(self):
        self.match_set_cursor_type(self.file_match_tag, gtk.gdk.HAND2)
        
    def remove_file_match_tag(self):
        self.match_remove(self.file_match_tag)
        
    def generate_keymap(self):
        get_keybind = lambda key_value: get_config("keybind", key_value)
        
        key_values = [
            "split_vertically",
            "split_horizontally",
            "copy_clipboard",
            "paste_clipboard",
            "revert_default_size",
            "zoom_in",
            "zoom_out",
            "close_current_window",
            "scroll_page_up",
            "scroll_page_down",
            "show_correlative_window",
            ]
        
        self.keymap = {}
        
        for key_value in key_values:
            self.keymap[get_keybind(key_value)] = getattr(self, key_value)
            
        self.keymap["Menu"] = self.show_menu
            
        if self.press_q_quit:
            self.keymap["q"] = lambda : self.exit_callback(True)
            
    def show_menu(self):
        (event_x, event_y) = gtk.gdk.display_get_default().get_pointer()[1:3]
        global_event.emit(
            "show-menu", 
            self, 
            self.get_has_selection(),
            self.get_match_text_at_coordinate(event_x, event_y),
            self.get_correlative_window_ids(),
            (int(event_x), int(event_y)),
            )
            
    def get_correlative_window_ids(self):
        try:
            child_process_ids = get_terminal_child_pids(self)
            return merge_list(
                map(lambda child_process_id:
                    filter(is_int, commands.getoutput("xdotool search --all --pid %s --onlyvisible" % child_process_id).split("\n")),
                    child_process_ids
                    ))
        except Exception, e:
            print "function get_correlative_window_ids got error: %s" % (e)
            traceback.print_exc(file=sys.stdout)
            
            return None
            
    def show_correlative_window(self, window_ids=None):
        try:
            if window_ids:
                correlative_window_ids = window_ids
            else:
                correlative_window_ids = self.get_correlative_window_ids()
            for correlative_window_id in correlative_window_ids:
                if is_int(correlative_window_id):
                    subprocess.Popen("xdotool windowactivate %s" % correlative_window_id, shell=True)
        except Exception, e:
            print "function show_correlative_window got error: %s" % (e)
            traceback.print_exc(file=sys.stdout)
            
    def scroll_page_up(self):
        adj = self.get_adjustment()
        value = adj.get_value()
        lower = adj.get_lower()
        page_size = adj.get_page_size()
        
        adj.set_value(max(lower, value - page_size))
    
    def scroll_page_down(self):
        adj = self.get_adjustment()
        value = adj.get_value()
        upper = adj.get_upper()
        page_size = adj.get_page_size()
        
        adj.set_value(min(upper - page_size, value + page_size))
            
    def clear(self):
        self.feed_child("clear\n")
        
    def show_man_window(self, command):
        self.split_vertically(command="man %s\n" % command, press_q_quit=True)
            
    def split_vertically(self, command=None, press_q_quit=False):
        if self.parent_widget:
            self.parent_widget.split(TerminalGrid.SPLIT_VERTICALLY, command=command, press_q_quit=press_q_quit),
        
    def split_horizontally(self, command=None, press_q_quit=False):
        if self.parent_widget:
            self.parent_widget.split(TerminalGrid.SPLIT_HORIZONTALLY, command=command, press_q_quit=press_q_quit),
            
    def change_color(self, font_color, background_color):
        self.set_colors(
            gtk.gdk.color_parse(font_color),
            gtk.gdk.color_parse(background_color),
            [],
            )
        
    def change_font(self, font, font_size):
        self.set_font_from_string("%s %s" % (font, font_size))
        
    def change_cursor_shape(self, cursor_shape):
        if cursor_shape == "block":
            self.set_cursor_shape(vte.CURSOR_SHAPE_BLOCK)
        elif cursor_shape == "ibeam":
            self.set_cursor_shape(vte.CURSOR_SHAPE_IBEAM)
        elif cursor_shape == "underline":
            self.set_cursor_shape(vte.CURSOR_SHAPE_UNDERLINE)

    def change_cursor_blink_mode(self, cursor_blink_mode):
        if cursor_blink_mode == "system":
            self.set_cursor_blink_mode(vte.CURSOR_BLINK_SYSTEM)
        elif cursor_blink_mode == "on":
            self.set_cursor_blink_mode(vte.CURSOR_BLINK_ON)
        elif cursor_blink_mode == "off":
            self.set_cursor_blink_mode(vte.CURSOR_BLINK_OFF)

    def on_scroll(self, widget, event):
        if self.is_ctrl_press(event):
            global_event.emit("adjust-background-transparent", event.direction)
            
            # Avoid scroll page when adjust transparent.
            return True
        
    def set_transparent(self, transparent):
        self.set_opacity(int(transparent * 65535))
        
    def close_current_window(self):
        self.exit_callback()
        
    def get_match_text(self, event):
        return self.get_match_text_at_coordinate(
            int(event.x / self.get_char_width()),
            int(event.y / self.get_char_height()))
    
    def get_match_text_at_coordinate(self, event_x, event_y):
        return self.match_check(event_x, event_y)
    
    def filter_file_string(self, match_string):
        # ` and ' is not valid filename char, so replace operation is safe.
        return commands.getoutput("echo %s" % match_string.replace('\'', '').replace('`', ''))
    
    def get_match_type(self, match_text):
        if match_text:
            (match_string, match_tag) = match_text
            if match_tag == self.url_match_tag:
                return (MATCH_URL, match_string)
            elif match_tag == self.file_match_tag:
                match_file = False
                
                file_string = self.filter_file_string(match_string)
                
                if os.path.exists(file_string):
                    if os.path.isdir(file_string):
                        return (MATCH_DIRECTORY, file_string)
                    else:
                        return (MATCH_FILE, file_string)
                else:
                    working_directory = get_active_working_directory(self.get_toplevel())    
                    filepath = os.path.join(working_directory, file_string)
                    
                    if os.path.exists(filepath):
                        if os.path.isdir(filepath):
                            return (MATCH_DIRECTORY, filepath)
                        else:
                            return (MATCH_FILE, filepath)
                        
                if not match_file:        
                    man_path = get_command_output_first_line("man -w %s" % match_string, True).split("\n")[0]
                    if os.path.exists(man_path):
                        return (MATCH_COMMAND, match_string)
                    
        return None
    
    def open_match_string(self, match_type, match_string):
        if match_type in [MATCH_URL, MATCH_FILE, MATCH_DIRECTORY]:
            global_event.emit("xdg-open", match_string)
        elif match_type == MATCH_COMMAND:
            self.show_man_window(match_string)
        
    def is_ctrl_press(self, event):
        return event.state & gtk.gdk.CONTROL_MASK == gtk.gdk.CONTROL_MASK
            
    def on_button_press(self, widget, event):
        if is_left_button(event) and self.is_ctrl_press(event):
            (column, row) = self.get_cursor_position()
            match_text = self.get_match_text(event)
            if match_text:
                (match_type, match_string) = self.get_match_type(match_text)
                self.open_match_string(match_type, match_string)
        elif is_right_button(event):
            self.grab_focus()
            
            global_event.emit(
                "show-menu", 
                self, 
                self.get_has_selection(),
                self.get_match_text(event),
                self.get_correlative_window_ids(),
                (int(event.x_root), int(event.y_root)),
                )
        
    def get_first_row(self):
        return int(self.get_adjustment().get_lower())
    
    def get_last_row(self):
        return int(self.get_adjustment().get_upper()) - 1
    
    def move_to_begin(self):
        self.reset_cursor()
    
    def move_to_end(self):
        last_row = self.get_last_row()
        self.set_cursor_position(0, last_row)
        last_row_column_number = self.get_column_count() - 1
        last_row_content = self.get_text_range(last_row, 0, last_row, last_row_column_number, self.search_character)
        self.set_cursor_position(len(last_row_content.split("\n")[0]), last_row)
    
    def search_character(self, widget, col, row, junk):
        return(True) 

    def revert_default_size(self):
        font = get_config("general", "font")
        self.current_font_size = self.default_font_size
        self.change_font(font, self.current_font_size)
    
    def zoom_in(self):
        font = get_config("general", "font")
        self.current_font_size = max(MIN_FONT_SIZE, self.current_font_size - 1)
        self.change_font(font, self.current_font_size)
    
    def zoom_out(self):
        font = get_config("general", "font")
        self.current_font_size += 1
        self.change_font(font, self.current_font_size)
        
    def get_working_directory(self):
        try:
            return os.readlink("/proc/%s/cwd" % self.process_id)
        except Exception, e:
            # Return HOME directory if got error when read /proc/pid/cwd
            print "TerminalWrapper.get_working_directory got error: %s" % e
            return _HOME
        
    def change_path(self):
        global focus_terminal
        
        global_event.emit("change-path", self.get_working_directory())
        
        # Save focus terminal. 
        focus_terminal = self
        
    def on_window_title_changed(self, widget):
        if self.has_focus():
            self.change_path()
        
    def on_drag_data_received(self, widget, drag_context, x, y, selection, target_type, timestamp):
        if target_type == DRAG_TEXT_URI:
            paste_text = ' '.join(map(lambda uri: "'%s'" % urllib.unquote(uri.split("file://")[1]), selection.get_uris())) + ' '
        elif target_type == DRAG_TEXT_PLAIN:
            paste_text = selection.data
            
        self.feed_child(paste_text)    
        
        # Grab focus when drag release.
        self.get_toplevel().present()
        self.grab_focus()

    def stop_child_processes(self):
        kill_processes(get_terminal_child_pids(self))
        
    def child_exited(self, widget):
        self.exit_callback()
        
    def exit_callback(self, no_confirm_dialog=False):
        """
        Call parent_widget.child_exit_callback
        :param widget: self
        """
        if self.parent_widget:
            self.parent_widget.child_exit_callback(self.parent_widget, no_confirm_dialog)

    def realize_callback(self, widget):
        """
        Callback for realize-signal.
        :param widget: which widget sends the signal.
        """
        widget.grab_focus()

    def handle_key_press(self, widget, event):
        """
        Handle keys as c-v and c-h
        :param widget: which widget sends the key_event.
        :param event: what event is sent.
        """
        key_name = get_keyevent_name(event)

        if key_name in self.keymap:
            self.keymap[key_name]()

            return True
        else:
            return False
        
    def copy_text(self, text):
        gtk.Clipboard().set_text(text)

gobject.type_register(TerminalWrapper)


class TerminalGrid(gtk.VBox):
    """
    Container for terminals. Handle vsplit and hsplit keystrokes.
    """

    # Constant values
    SPLIT_VERTICALLY = 1
    SPLIT_HORIZONTALLY = 2

    def __init__(self, 
                 parent_widget=None, 
                 terminal=None,
                 working_directory=None,
                 command=None,
                 press_q_quit=False,
                 cmdline_startup_command=None,
                 ):
        """
        Initial values
        :param parent_widget: which TerminalGrid this widget belongs to.
        """
        gtk.VBox.__init__(self)

        # Keep a reference to parent
        self.parent_widget = parent_widget
        if terminal:
            self.terminal = terminal
            self.terminal.parent_widget = self
        else:
            self.terminal = TerminalWrapper(
                self, 
                working_directory=working_directory,
                command=command,
                press_q_quit=press_q_quit,
                cmdline_startup_command=cmdline_startup_command,
                )
            
        self.is_parent = False
        self.paned = None
        self.add(self.terminal)

    def split(self, split_policy, command=None, press_q_quit=False):
        """
        Split window.
        :param split_policy: used to determine vsplit or hsplit.
        """
        if split_policy not in [TerminalGrid.SPLIT_VERTICALLY, TerminalGrid.SPLIT_HORIZONTALLY]:
            raise (ValueError, "Unknown split policy!!")
        
        working_directory = get_active_working_directory(self.get_toplevel())    
            
        self.is_parent = True
        self.remove(self.terminal)
        width, height = self.get_child_requisition()
        if split_policy == TerminalGrid.SPLIT_VERTICALLY:
            self.paned = VPaned()
            self.paned.set_position(height/2)
        elif split_policy == TerminalGrid.SPLIT_HORIZONTALLY:
            self.paned = HPaned()
            self.paned.set_position(width/2)
            
        self.paned.pack1(TerminalGrid(self, self.terminal), True, True)
        self.paned.pack2(TerminalGrid(
                self, 
                working_directory=working_directory, 
                command=command,
                press_q_quit=press_q_quit), True, True)

        self.add(self.paned)
        self.show_all()

    def child_exit_callback(self, widget, no_confirm_dialog=False):
        """
        Recursively close the widget or remove paned.
        :param widget: which widget is exited.
        """
        if self.is_parent:
            # Called from one of the children, now check which children to remove.
            widgets = self.paned.get_children()
            container_remove_all(self.paned)
            self.remove(self.paned)
            self.paned = None
            widgets.remove(widget)
            widget = widgets[0]

            if widget.is_parent:
                # Another widget is a grid of terminals
                child_widgets = widget.paned.get_children()
                for w in child_widgets:
                    w.parent_widget = self
                widget.remove(widget.paned)
                self.paned = widget.paned
                self.add(self.paned)
            else:
                # Just two terminals
                widget.remove(widget.terminal)
                widget.terminal.parent_widget = self
                self.terminal = widget.terminal
                self.add(widget.terminal)
                self.is_parent = False
        else:
            if self.parent_widget:
                def remove_terminal():
                    self.terminal.stop_child_processes()
                    self.remove(self.terminal)
                    self.terminal = None
                    self.parent_widget.child_exit_callback(self)
                    
                child_pids = get_terminals_child_pids([self.terminal])
                ask_on_quit = is_bool(get_config("advanced", "ask_on_quit"))
                
                if no_confirm_dialog or not ask_on_quit or len(child_pids) == 0:
                    remove_terminal()
                else:
                    create_confirm_dialog(
                        _("Close window?"),
                        _("Window still have running programs. Are you sure you want to close?"),
                        remove_terminal,
                        self.get_toplevel(),
                        )
            else:
                workspace = get_match_parent(self, "Workspace")
                if workspace:
                    global_event.emit("close-terminal-workspace", workspace)

gobject.type_register(TerminalGrid)

class Workspace(gtk.VBox):
    """
    class docs
    """

    def __init__(self, workspace_index):
        """
        init docs
        """
        gtk.VBox.__init__(self)
        
        self.workspace_index = workspace_index
        self.snapshot_pixbuf = None
        self.focus_terminal = None
        
    def save_focus_terminal(self):
        self.focus_terminal = self.get_toplevel().get_focus()
    
    def restore_focus_terminal(self):
        if self.focus_terminal:
            self.focus_terminal.grab_focus()
            self.focus_terminal = None
        
    def save_workspace_snapshot(self):
        if self.window and self.window.get_colormap():
            rect = self.allocation
            x, y, width, height = rect.x, rect.y, rect.width, rect.height
            snapshot_pixbuf = gtk.gdk.Pixbuf(gtk.gdk.COLORSPACE_RGB, False, 8, width, height)
            snapshot_pixbuf.get_from_drawable(
                self.window,
                self.window.get_colormap(),
                x, y, 0, 0,
                width,
                height,
                )
            snapshot_height = WORKSPACE_SNAPSHOT_HEIGHT - WORKSPACE_SNAPSHOT_OFFSET_TOP - WORKSPACE_SNAPSHOT_OFFSET_BOTTOM
            snapshot_width = int(width * snapshot_height / height)
            self.snapshot_pixbuf = snapshot_pixbuf.scale_simple(
                snapshot_width,
                snapshot_height,
                gtk.gdk.INTERP_BILINEAR,
                )
            snapshot_pixbuf = None
            
            gc.collect()
        
gobject.type_register(Workspace)

class WorkspaceSwitcher(gtk.Window):
    """
    class docs
    """

    def __init__(self, get_workspaces):
        """
        init docs
        """
        gtk.Window.__init__(self, gtk.WINDOW_POPUP)
        self.get_workspaces = get_workspaces
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_skip_taskbar_hint(True)
        self.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_DIALOG)  # keep above
        
        self.width = 0
        self.height = 0
        self.close_button_size = 40
        
        self.workspace_index = 0
        
        self.workspace_snapshot_areas = []
        self.workspace_add_area = None
        
        self.in_workspace_snapshot_area = False
        self.in_workspace_close_area = False
        self.in_workspace_add_area = False
        
        self.background_offset_y = 0
        self.scale_value = 0
        
        self.connect("expose-event", self.expose_workspace_switcher)
        self.connect("motion-notify-event", self.motion_workspace_switcher)
        self.connect("leave-notify-event", self.leave_workspace_switcher)
        self.connect("button-press-event", self.button_press_workspace_switcher)
        
    def hide_switcher(self):
        self.workspace_index = 0
        
        self.hide_all()
        
    def switch_prev(self):
        workspace_num = len(self.get_workspaces())
        if self.workspace_index <= 0:
            self.workspace_index = workspace_num - 1
        else:
            self.workspace_index -= 1
        
        self.queue_draw()        
    
    def switch_next(self):
        workspace_num = len(self.get_workspaces())
        if self.workspace_index >= workspace_num - 1:
            self.workspace_index = 0
        else:
            self.workspace_index += 1
            
        self.queue_draw()    
        
    def show_switcher(self, current_workspace_index, (x, y, width, height)):
        self.move(x, y)
        self.resize(width, height)
        
        self.width = width
        self.height = height
        
        self.workspace_index = current_workspace_index
        
        # Put show_all code at last to avoid cut graphics after show.
        self.show_all()
        
    def expose_workspace_switcher(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        
        # Calcuate scale value.
        snapshot_add_width = WORKSPACE_ADD_SIZE + WORKSPACE_ADD_PADDING * 2
        snapshot_total_width = sum(map(lambda w: w.snapshot_pixbuf.get_width() + WORKSPACE_SNAPSHOT_OFFSET_X * 2, self.get_workspaces()))
        have_enough_space = snapshot_total_width + snapshot_add_width * 2 < rect.width
        if have_enough_space:
            scale_value = 1.0
            draw_x = (rect.width - snapshot_total_width) / 2
        else:
            scale_value = float(rect.width) / (snapshot_total_width + snapshot_add_width)
            draw_x = WORKSPACE_SNAPSHOT_OFFSET_X
        self.scale_value = scale_value    
            
        # Draw background.
        with cairo_state(cr):
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#000000", 0)))
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
            
            
        background_height = rect.height * scale_value
        background_offset_y = rect.height - background_height
        self.background_offset_y = rect.height - background_height
        cr.set_source_rgba(*alpha_color_hex_to_cairo(("#000000", 0.6)))
        cr.rectangle(rect.x, rect.y + background_offset_y, rect.width, background_height)
        cr.fill()
        
        # Draw background top frame.
        draw_hlinear(
            cr,
            rect.x,
            rect.y + background_offset_y,
            rect.width,
            1,
            
            [(0, ("#FFFFFF", 0.1)),
             (0.5, ("#FFFFFF", 0.2)),
             (1, ("#FFFFFF", 0.1)),
             ],
            )
        
        # Draw workspace snapshot.
        self.workspace_snapshot_areas = []    
        with cairo_state(cr):    
            cr.scale(scale_value, scale_value)
            for (index, workspace) in enumerate(self.get_workspaces()): 
                
                snapshot_width = workspace.snapshot_pixbuf.get_width()
                
                draw_y = rect.y + WORKSPACE_SNAPSHOT_OFFSET_TOP
                
                # Draw workspace select background.
                snapshot_area_x = draw_x - WORKSPACE_SNAPSHOT_OFFSET_X
                snapshot_area_y = rect.y
                snapshot_area_width = snapshot_width + WORKSPACE_SNAPSHOT_OFFSET_X * 2
                snapshot_area_height = rect.height
                
                if self.workspace_index == index:
                    cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.1)))
                    cr.rectangle(
                        snapshot_area_x,
                        snapshot_area_y + background_offset_y / scale_value,
                        snapshot_area_width,
                        snapshot_area_height,
                        )
                    cr.fill()
                    
                self.workspace_snapshot_areas.append(
                    ((index, workspace.workspace_index), (
                               scale_value * snapshot_area_x,
                               scale_value * (snapshot_area_y + background_offset_y / scale_value),
                               scale_value * snapshot_area_width,
                               scale_value * snapshot_area_height,
                               )))    
                
                # Draw workspace snapshot.
                draw_pixbuf(
                    cr,
                    workspace.snapshot_pixbuf,
                    draw_x,
                    draw_y + background_offset_y / scale_value,
                )
                
                # Draw workspace snapshot frame.
                with cairo_disable_antialias(cr):
                    cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.1)))
                    cr.rectangle(
                        draw_x,
                        draw_y + background_offset_y / scale_value,
                        workspace.snapshot_pixbuf.get_width(),
                        workspace.snapshot_pixbuf.get_height(),
                        )
                    cr.stroke()
                
                    
                draw_x += snapshot_width + WORKSPACE_SNAPSHOT_OFFSET_X * 2
            
        # Draw workspace name.
        text_size = 32
        for ((index, workspace_index), (draw_x, draw_y, draw_width, draw_height)) in self.workspace_snapshot_areas:
            draw_text(
                cr,
                "%s %s" % (_("Workspace"), workspace_index),
                int(draw_x),
                int(draw_y + draw_height - text_size * scale_value),
                int(draw_width),
                text_size * scale_value,
                text_color="#FFFFFF",
                alignment=pango.ALIGN_CENTER,
                )
            
        # Draw close button.
        for ((index, workspace_index), (draw_x, draw_y, draw_width, draw_height)) in self.workspace_snapshot_areas:
            rect_width = 20
            rect_height = 20
            padding_x = padding_y = 5
            button_x = draw_x
            button_y = draw_y + padding_y
            if self.workspace_index == index and self.in_workspace_snapshot_area:
                # Draw close button background.
                if self.in_workspace_close_area:
                    cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FF0000", 0.3)))
                else:
                    cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.2)))
                    
                draw_round_rectangle(
                    cr, 
                    button_x + draw_width - rect_width - padding_x,
                    button_y,
                    rect_width,
                    rect_height,
                    5,
                    )    
                cr.fill()
                
                # Draw close button foreground.
                if self.in_workspace_close_area:
                    cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.8)))
                else:
                    cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.3)))
                padding = 5
                cr.set_line_width(2)
                cr.move_to(
                    button_x + draw_width - self.close_button_size / 2 + padding - padding_x,
                    button_y + padding,
                    )
                cr.line_to(
                    button_x + draw_width - padding - padding_x,
                    button_y + self.close_button_size / 2 - padding,
                    )
                cr.stroke()
                cr.move_to(
                    button_x + draw_width - self.close_button_size / 2 + padding  - padding_x,
                    button_y + self.close_button_size / 2 - padding,
                    )
                cr.line_to(
                    button_x + draw_width - padding - padding_x,
                    button_y + padding,
                    )
                cr.stroke()
                
        # Draw workspace add button.
        with cairo_state(cr):        
            workspace_add_size = scale_value * WORKSPACE_ADD_SIZE    
            workspace_add_middle_size = scale_value * WORKSPACE_ADD_MIDDLE_SIZE
            workspace_add_padding = scale_value * WORKSPACE_ADD_PADDING
            workspace_add_x = rect.width - workspace_add_size - workspace_add_padding    
            workspace_add_area_height = scale_value * rect.height
            
            add_area_x = rect.width - (workspace_add_size + workspace_add_padding * 2)
            add_area_y = rect.y + background_offset_y
            add_area_width = workspace_add_area_height
            add_area_height = (workspace_add_size + workspace_add_padding * 2)
                
            self.workspace_add_area = (add_area_x, add_area_y, add_area_width, add_area_height)
            
            if self.in_workspace_add_area:
                cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.5)))
            else:
                cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.1)))
                
            cr.rectangle(
                workspace_add_x, 
                (add_area_y + (workspace_add_area_height - workspace_add_middle_size) / 2),
                workspace_add_size, 
                workspace_add_middle_size,
                )
            cr.fill()
            
            cr.rectangle(
                workspace_add_x + (workspace_add_size - workspace_add_middle_size) / 2,
                (add_area_y + (workspace_add_area_height - workspace_add_size) / 2),
                workspace_add_middle_size,
                (workspace_add_size - workspace_add_middle_size) / 2,
                )
            cr.fill()
            
            cr.rectangle(
                workspace_add_x + (workspace_add_size - workspace_add_middle_size) / 2,
                (add_area_y + (workspace_add_area_height + workspace_add_middle_size) / 2),
                workspace_add_middle_size,
                (workspace_add_size - workspace_add_middle_size) / 2,
                )
            cr.fill()
            
        return True
        
    def is_in_close_button_area(self, ex, ey, snapshot_area):
        (x, y, w, h) = snapshot_area
        return is_in_rect(
            (ex, ey),
            (x + w - self.close_button_size,
             y,
             self.close_button_size,
             self.close_button_size,
             ))
    
    def leave_workspace_switcher(self, widget, event):
        self.in_workspace_snapshot_area = False
        self.in_workspace_add_area = False
        self.in_workspace_close_area = False
        
        self.queue_draw()
    
    def motion_workspace_switcher(self, widget, event):
        self.in_workspace_snapshot_area = False
        self.in_workspace_close_area = False
        
        for ((index, workspace_index), snapshot_area) in self.workspace_snapshot_areas:
            if is_in_rect((event.x, event.y), snapshot_area):
                if self.is_in_close_button_area(event.x, event.y, snapshot_area):
                    self.in_workspace_close_area = True
                
                self.in_workspace_snapshot_area = True
                self.in_workspace_add_area = False
                self.workspace_index = index
                self.queue_draw()
                return False
            
        if is_in_rect((event.x, event.y), self.workspace_add_area):
            self.in_workspace_add_area = True
            self.queue_draw()
            return False
            
    def button_press_workspace_switcher(self, widget, event):        
        for ((index, workspace_index), snapshot_area) in self.workspace_snapshot_areas:
            if is_in_rect((event.x, event.y), snapshot_area):
                if self.is_in_close_button_area(event.x, event.y, snapshot_area):
                    self.in_workspace_close_area = True
                    global_event.emit("close-workspace", self.get_workspaces()[index])
                    self.queue_draw()
                else:
                    global_event.emit("switch-to-workspace", index)
                    self.hide_switcher()
                    
                return False
            
        if is_in_rect((event.x, event.y), self.workspace_add_area):
            global_event.emit("new-workspace")
            self.queue_draw()
            return False
        
        self.hide_switcher()
        
gobject.type_register(WorkspaceSwitcher)

class SearchBar(gtk.Window):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        gtk.Window.__init__(self, gtk.WINDOW_TOPLEVEL)
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_modal(True)
        self.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_DIALOG)
        self.set_skip_taskbar_hint(True)
        
        self.entry = Entry(
            text_color=ui_theme.get_color("entry_select_text"),
            cursor_color="#FFFFFF",
            font_size=11,
            )
        self.entry.entry_buffer.always_show_cursor = True
        self.entry_align = gtk.Alignment()
        self.entry_align.set(0.5, 0.5, 1, 1)
        self.entry_align.set_padding(0, 0, 10, 0)
        self.entry_align.add(self.entry)
        
        from dtk.ui.line import VSeparator
        lines = []
        for i in range(0, 3):
            lines.append(VSeparator(
                    [(0, ("#FFFFFF", 0.2)),
                     (1, ("#FFFFFF", 0.1)),
                     ],
                    padding_y=1))
        (self.split_line_a, self.split_line_b, self.split_line_c) = lines    
        
        self.prev_button = ImageButton(
            app_theme.get_pixbuf("search_prev_normal.png"),
            app_theme.get_pixbuf("search_prev_hover.png"),
            app_theme.get_pixbuf("search_prev_press.png"),
            )

        self.next_button = ImageButton(
            app_theme.get_pixbuf("search_next_normal.png"),
            app_theme.get_pixbuf("search_next_hover.png"),
            app_theme.get_pixbuf("search_next_press.png"),
            )

        self.close_button = ImageButton(
            app_theme.get_pixbuf("search_close_normal.png"),
            app_theme.get_pixbuf("search_close_hover.png"),
            app_theme.get_pixbuf("search_close_press.png"),
            )
                
        self.button_box = gtk.HBox()
        self.button_box.pack_start(self.split_line_a, False, False)
        self.button_box.pack_start(self.prev_button, False, False)
        self.button_box.pack_start(self.split_line_b, False, False)
        self.button_box.pack_start(self.next_button, False, False)
        self.button_box.pack_start(self.split_line_c, False, False)
        self.button_box.pack_start(self.close_button, False, False)
        
        self.button_align = gtk.Alignment()
        self.button_align.set(0, 0, 0, 0)
        self.button_align.set_padding(0, 0, 0, 0)
        self.button_align.add(self.button_box)
        
        self.box = gtk.HBox()
        self.box.pack_start(self.entry_align, True, True)
        self.box.pack_start(self.button_align, False, False)
        
        self.add(self.box)
        
        self.prev_button.connect("clicked", lambda w: self.search_backward())
        self.next_button.connect("clicked", lambda w: self.search_forward())
        self.close_button.connect("clicked", lambda w: self.hide_bar())
        
        self.search_regex = ""
        
        self.width = 320
        self.height = 37
        self.radius = 5
        self.right_padding = 5
        
        self.active_terminal = None
        
        self.set_geometry_hints(
            None,
            self.width, self.height,
            self.width, self.height,
            -1, -1, -1, -1, -1, -1
            )
        
        self.generate_keymap()
        
        self.connect("expose-event", self.expose_search_bar)
        self.connect("size-allocate", self.shape_search_bar)
        self.connect("key-press-event", self.key_press_search_bar)
        self.entry.connect("changed", self.search_terminal)
        
    def generate_keymap(self):
        get_keybind = lambda key_value: get_config("keybind", key_value)
        
        key_values = [
            "search_forward",
            "search_backward",
            ]
        
        self.keymap = {
            "Escape": self.hide_bar,
            "Return": self.search_forward,
            }
        
        for key_value in key_values:
            self.keymap[get_keybind(key_value)] = getattr(self, key_value)
            
    def search_terminal(self, entry, text):
        if self.active_terminal:
            self.search_regex = text
            self.active_terminal.search_set_gregex(text)
            self.active_terminal.search_set_wrap_around(True)
            self.active_terminal.search_find_next()
            
    def search_forward(self):
        if self.active_terminal:
            self.active_terminal.search_find_next()
        
    def search_backward(self):
        if self.active_terminal:
            self.active_terminal.search_find_previous()
            
    def show_bar(self, terminal_box_coordinate, active_terminal, init_text=None):
        (terminal_box_right_x, terminal_box_y) = terminal_box_coordinate
        self.move(
            terminal_box_right_x - self.width - self.right_padding,
            terminal_box_y
            )
        
        self.active_terminal = active_terminal
        
        if init_text:
            self.entry.set_text(init_text)
        else:
            self.entry.set_text("")
    
        self.show_all()    
    
    def hide_bar(self):
        if self.active_terminal:
            self.active_terminal.move_to_end()
            
        self.hide_all()
        
    def expose_search_bar(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        x, y, w, h = rect.x, rect.y, rect.width, rect.height
        
        # Draw background.
        with cairo_state(cr):
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#000000", 0.5)))
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
            
        # Draw frame.
        with cairo_state(cr):
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.15)))
            cr.set_operator(cairo.OPERATOR_OVER)
            draw_round_rectangle(cr, x, y, w, h, self.radius)
            cr.stroke()
            
        propagate_expose(widget, event)
            
        return True    
    
    def shape_search_bar(self, widget, rect):
        if widget.get_has_window() and rect.width > 0 and rect.height > 0:
            # Init.
            x, y, w, h = rect.x, rect.y, rect.width, rect.height
            bitmap = gtk.gdk.Pixmap(None, w, h, 1)
            cr = bitmap.cairo_create()
            
            # Clear the bitmap
            cr.set_source_rgb(0.0, 0.0, 0.0)
            cr.set_operator(cairo.OPERATOR_CLEAR)
            cr.paint()
            
            # Draw shape of search bar.
            cr.set_source_rgb(1.0, 1.0, 1.0)
            cr.set_operator(cairo.OPERATOR_OVER)
            draw_round_rectangle(cr, x, y, w, h, self.radius)
            cr.fill()
                
            # Shape with given mask.
            widget.shape_combine_mask(bitmap, 0, 0)
            
    def key_press_search_bar(self, widget, event):
        key_name = get_keyevent_name(event)
        if key_name in self.keymap:
            self.keymap[key_name]()
            
            return True
        else:
            return False

gobject.type_register(SearchBar)

class TerminalNumWindow(Window):
    def __init__(self):
        Window.__init__(self, 
                        shadow_visible=False,
                        window_type=gtk.WINDOW_POPUP,
                        expose_background_function=self.expose_terminal_num_window,
                        expose_frame_function=self.expose_frame_terminal_num_window,
                        )
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_DIALOG)
        self.set_skip_taskbar_hint(True)
        self.set_can_focus(False)
        self.terminal_infos = []
        
    def show_window(self, x, y, width, height, terminal_infos):
        self.terminal_infos = terminal_infos
        self.move(x, y)
        self.resize(width, height)
        
        self.show_all()
        
    def expose_terminal_num_window(self, widget, event):
        cr = widget.window.cairo_create()

        with cairo_state(cr):
            cr.set_source_rgba(1.0, 1.0, 1.0, 0)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
            
        size = 36
        offset_x = 10
        offset_y = 10
        radius = 6
        for (terminal_index, (terminal_x, terminal_y)) in self.terminal_infos:
            cr.set_source_rgba(0, 0, 0, 0.9)
            draw_round_rectangle(
                cr,
                terminal_x + offset_x,
                terminal_y + offset_y,
                size,
                size,
                radius,
                )
            cr.fill()
            
            cr.set_source_rgba(1, 1, 1, 0.5)
            draw_round_rectangle(
                cr,
                terminal_x + offset_x,
                terminal_y + offset_y,
                size,
                size,
                radius,
                )
            cr.stroke()
            
            if terminal_index == 10:
                terminal_num = "0"
            else:
                terminal_num = str(terminal_index)
            draw_text(
                cr,
                terminal_num,
                terminal_x + offset_x,
                terminal_y + offset_y,
                size,
                size,
                text_size=20,
                text_color="#FFFFFF",
                alignment=pango.ALIGN_CENTER,
                )
            
        return True    
    
    def expose_frame_terminal_num_window(self, widget, event):
        pass
    
gobject.type_register(TerminalNumWindow)    

class HelperWindow(Window):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        self.radius = 5
        self.frame_radius = 2
        
        Window.__init__(self, 
                        shadow_visible=True,
                        window_type=gtk.WINDOW_POPUP,
                        expose_background_function=self.expose_helper_window,
                        shape_frame_function=self.shape_frame_helper_window,
                        expose_frame_function=self.expose_frame_helper_window,
                        expose_shadow_function=self.expose_shadow_helper_window,
                        frame_radius=self.frame_radius,
                        )
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_modal(True)
        self.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_DIALOG)
        self.set_skip_taskbar_hint(True)
        
        self.key_label_color = ui_theme.get_color("label_select_text")
        self.key_label_size = 12
        
        self.keymap = {
            "Escape": self.hide_all
            }
        
        self.table_box = gtk.HBox()
        
        self.box = gtk.VBox()
        
        self.content_box = gtk.VBox()
        self.content_box_align = gtk.Alignment()
        self.content_box_align.set(0.5, 0.5, 1, 1)
        self.content_box_align.set_padding(60, 60, 30, 30)
        self.content_box_align.add(self.content_box)
        self.content_box.pack_start(self.table_box, False, False)
        
        self.box.pack_start(self.content_box_align, False, False)
        
        self.window_frame.add(self.box)
        
        self.connect("key-press-event", self.key_press_helper_window)
        self.connect("key-release-event", self.key_release_helper_window)
        self.connect("button-press-event", self.button_press_helper_window)
        
    def fill_table(self, table, infos, column_offset):
        for (index, (name, key)) in enumerate(infos):
            if key == None:
                title = "<b>%s</b>" % name
                title_size = self.key_label_size + 4
                title_ypadding = 10
                key_value = ""
            else:
                title = name
                title_size = self.key_label_size
                title_ypadding = 7
                key_value = key
                
            table.attach(
                Label(title, 
                      text_color=self.key_label_color,
                      text_size=title_size,
                      ),
                column_offset, column_offset + 1,
                index, index + 1,
                xoptions=gtk.FILL,
                ypadding=title_ypadding,
                xpadding=20,
                )
            table.attach(
                Label(key_value, 
                      text_color=self.key_label_color,
                      text_size=self.key_label_size,
                      ),
                column_offset + 1, column_offset + 2,
                index, index + 1,
                xpadding=20,
                )
        return table    
        
    def key_press_helper_window(self, widget, event):
        key_name = get_keyevent_name(event)
        if key_name in self.keymap:
            self.keymap[key_name]()
            
            return True
        else:
            return False
        
    def key_release_helper_window(self, widget, event):    
        if self.get_visible():
            if is_no_key_press(event):
                self.hide_all()
                
    def button_press_helper_window(self, widget, event):
        if self.get_visible():
            self.hide_all()
        
    def show_help(self, parent_window, working_directory):
        container_remove_all(self.table_box)    
        
        def get_keybind(key_value):
            try:
                return setting_config.config.config_parser.get("keybind", key_value)
            except:
                return key_value
        
        first_table_key = [
            (_("Terminal command"), None),
            (_("Copy"), "copy_clipboard"),
            (_("Paste"), "paste_clipboard"),
            (_("Scroll page up"), "scroll_page_up"),
            (_("Scroll page down"), "scroll_page_down"),
            (_("Search forward"), "search_forward"),
            (_("Search backward"), "search_backward"),
            (_("Select word"), _("Double click")),
            (_("Open"), _("Ctrl + Left click")),
            (_("Zoom out"), "zoom_out"),
            (_("Zoom in"), "zoom_in"),
            (_("Reset zoom"), "revert_default_size"),
            (_("Show correlative child window"), "show_correlative_window"),
            ]
        
        second_table_key = [
            (_("Workspace command"), None),
            (_("New workspace"), "new_workspace"),
            (_("Previous workspace"), "switch_prev_workspace"),
            (_("Next workspace"), "switch_next_workspace"),
            (_("Close workspace"), "close_current_workspace"),
            (_("Split vertically"), "split_vertically"),
            (_("Split horizontally"), "split_horizontally"),
            (_("Focus the terminal above"), "focus_up_terminal"),
            (_("Focus the terminal below"), "focus_down_terminal"),
            (_("Focus the temrinal left"), "focus_left_terminal"),
            (_("Focus the terminal right"), "focus_right_terminal"),
            (_("Close current window"), "close_current_window"),
            (_("Close other window"), "close_other_window"),
            ]
        
        third_table_key = [
            (_("Advanced command"), None),
            (_("Fullscreen"), "toggle_full_screen"),
            (_("Display hotkeys"), "show_helper_window"),
            (_("Set up SSH connection"), "show_remote_login_window"),
            ]
        
        self.table = gtk.Table(18, 6)
        
        self.fill_table(
            self.table,
            map(lambda (key_name, key_value): (key_name, get_keybind(key_value)), first_table_key),
            0,
            )
        
        self.fill_table(
            self.table,
            map(lambda (key_name, key_value): (key_name, get_keybind(key_value)), second_table_key),
            2,
            )

        self.fill_table(
            self.table,
            map(lambda (key_name, key_value): (key_name, get_keybind(key_value)), third_table_key) + [(_("Adjust opacity"), _("Ctrl + Wheel"))],
            4,
            )
        
        self.table_box.pack_start(self.table, True, True)
            
        parent_window_rect = parent_window.get_allocation()
        self.resize(
            max(parent_window_rect.width, HOTKEYS_WINDOW_MIN_WIDTH),
            max(parent_window_rect.height, HOTKEYS_WINDOW_MIN_HEIGHT),
            )
        
        self.show_all()
        
        (center_x, center_y) = get_widget_root_coordinate(parent_window, WIDGET_POS_CENTER)
        (screen_width, screen_height) = get_screen_size(self)
        self.move(
            min(screen_width - self.allocation.width, max(center_x - self.allocation.width / 2, 0)),
            min(screen_height - self.allocation.height, max(center_y - self.allocation.height / 2, 0))
            )
        
    def shape_frame_helper_window(self, widget, rect):
        if widget.window != None and widget.get_has_window() and rect.width > 0 and rect.height > 0:
            if self.window.get_state() & gtk.gdk.WINDOW_STATE_MAXIMIZED != gtk.gdk.WINDOW_STATE_MAXIMIZED:
                # Init.
                x, y, w, h = rect.x, rect.y, rect.width, rect.height
                bitmap = gtk.gdk.Pixmap(None, w, h, 1)
                cr = bitmap.cairo_create()
                
                # Clear the bitmap
                cr.set_source_rgb(0.0, 0.0, 0.0)
                cr.set_operator(cairo.OPERATOR_CLEAR)
                cr.paint()
                
                # Draw our shape into the bitmap using cairo.
                cr.set_source_rgb(1.0, 1.0, 1.0)
                cr.set_operator(cairo.OPERATOR_OVER)
                
                draw_round_rectangle(cr, x, y, w, h, self.radius)
                
                cr.fill()
                
                # Shape with given mask.
                widget.shape_combine_mask(bitmap, 0, 0)
    
    def expose_frame_helper_window(self, widget, event):
        pass
    
    def expose_shadow_helper_window(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        x, y, w, h = rect.x, rect.y, rect.width, rect.height
        r = self.shadow_radius
        p = self.shadow_radius - self.frame_radius
        color_window_shadow = ui_theme.get_shadow_color("window_shadow")
        
        color_infos = color_window_shadow.get_color_info()
        
        cr.set_operator(cairo.OPERATOR_OVER)
        
        with cairo_state(cr):
            # Draw four round.
            draw_radial_ring(cr, x + r, y + r, r, self.frame_radius, color_infos, "top-left")
            draw_radial_ring(cr, x + w - r, y + r, r, self.frame_radius, color_infos, "top-right")
            draw_radial_ring(cr, x + r, y + h - r, r, self.frame_radius, color_infos, "bottom-left")
            draw_radial_ring(cr, x + w - r, y + h - r, r, self.frame_radius, color_infos, "bottom-right")
        
        with cairo_state(cr):
            # Clip four side.
            cr.rectangle(x, y + r, p, h - r * 2)
            cr.rectangle(x + w - p, y + r, p, h - r * 2)
            cr.rectangle(x + r, y, w - r * 2, p)
            cr.rectangle(x + r, y + h - p, w - r * 2, p)
            cr.clip()
            
            # Draw four side.
            draw_vlinear(
                cr, 
                x + r, y, 
                w - r * 2, r, color_infos)
            draw_vlinear(
                cr, 
                x + r, y + h - r, 
                w - r * 2, r, color_infos, 0, False)
            draw_hlinear(
                cr, 
                x, y + r, 
                r, h - r * 2, color_infos)
            draw_hlinear(
                cr, 
                x + w - r, y + r, 
                r, h - r * 2, color_infos, 0, False)
        
    def expose_helper_window(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        
        with cairo_state(cr):
            cr.set_source_rgba(1.0, 1.0, 1.0, 0)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
            
        out_x = rect.x + self.shadow_padding
        out_y = rect.y + self.shadow_padding
        out_w = rect.width - self.shadow_padding * 2
        out_h = rect.height - self.shadow_padding * 2
        
        padding = 2
        inner_x = out_x + padding
        inner_y = out_y + padding
        inner_w = out_w - padding * 2
        inner_h = out_h - padding * 2
        inner_radius = self.radius
        
        with cairo_state(cr):
            draw_round_rectangle(cr, out_x, out_y, out_w, out_h, self.radius)
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#FFFFFF", 0.4)))
            cr.fill()
            
        with cairo_state(cr):
            cr.set_source_rgba(1.0, 1.0, 1.0, 0)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            draw_round_rectangle(cr, inner_x, inner_y, inner_w, inner_h, inner_radius)
            cr.fill()
            
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#000000", 0.8)))
            cr.set_operator(cairo.OPERATOR_OVER)
            draw_round_rectangle(cr, inner_x, inner_y, inner_w, inner_h, inner_radius)
            cr.fill()
            
        propagate_expose(widget, event)
            
        return True    
            
gobject.type_register(HelperWindow)

class GeneralSettings(gtk.VBox):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        gtk.VBox.__init__(self)
        
        font = get_config("general", "font")
        font_families = get_font_families(True)
        font_items = map(lambda i: (i, i), font_families)
        self.font_widget = ComboBox(font_items, droplist_height=200, fixed_width=COMBO_BOX_WIDTH)
        try:
            self.font_widget.set_select_index(font_families.index(font))
        except:
            self.font_widget.set_select_index(font_families.index(BACKUP_FONT))
        self.font_widget.connect("item-selected", self.change_font)
        
        font_size = get_config("general", "font_size")
        self.font_size_widget = SpinBox(lower=1, step=1)
        self.font_size_widget.set_value(int(font_size))
        self.font_size_widget.connect("value-changed", self.change_font_size)
        self.font_size_widget.value_entry.connect("changed", self.change_font_size)
        
        color_scheme = get_config("general", "color_scheme")
        self.color_items =map(lambda (color_scheme_value, (color_scheme_name, _)): (color_scheme_name, color_scheme_value), color_style.items())
        self.color_scheme_widget = ComboBox(self.color_items, fixed_width=COMBO_BOX_WIDTH)
        self.color_scheme_widget.set_select_index(
            map(lambda (color_scheme_value, color_infos): color_scheme_value, color_style.items()).index(color_scheme))
        self.color_scheme_widget.connect("item-selected", self.change_color_scheme)
        
        font_color = get_config("general", "font_color")
        self.font_color_widget = ColorButton(color=font_color)
        self.font_color_widget.connect("color-select", self.change_font_color)
        
        background_color = get_config("general", "background_color")
        self.background_color_widget = ColorButton(background_color)
        self.background_color_widget.connect("color-select", self.change_background_color)
        
        color_box = gtk.HBox()
        color_box_split = gtk.HBox()
        color_box_split.set_size_request(10, -1)
        color_box.pack_start(self.font_color_widget, False, False)
        color_box.pack_start(color_box_split, False, False)
        color_box.pack_start(self.background_color_widget, False, False)
        
        transparent = get_config("general", "background_transparent")
        self.background_transparent_widget = HScalebar(value_min=MIN_TRANSPARENT, value_max=1)
        self.background_transparent_widget.set_value(float(transparent))
        self.background_transparent_widget.connect("value-changed", self.save_background_transparent)
        
        self.table = gtk.Table(7, 2)
        self.table.set_row_spacings(TABLE_ROW_SPACING)
        self.table.set_col_spacing(0, TABLE_COLUMN_SPACING)
        table_items = [
            (_("Font: "), self.font_widget),
            (_("Font size: "), self.font_size_widget),
            (_("Color scheme: "), self.color_scheme_widget),
            ("", color_box),
            (_("Background transparency: "), self.background_transparent_widget),
            ]
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 1, 1)
        self.table_align.set_padding(TABLE_PADDING_TOP, TABLE_PADDING_BOTTOM, TABLE_PADDING_LEFT, 0)
        
        self.fill_table(self.table, table_items)
        self.table_align.add(self.table)
        self.add(self.table_align)
        
    def change_color_scheme(self, combo_box, option_name, option_value, index):
        with save_config(setting_config):    
            setting_config.config.set("general", "color_scheme", option_value)
        
        if option_value != "custom" and color_style.has_key(option_value):
            (_, [font_color, background_color]) = color_style[option_value]
            
            self.font_color_widget.set_color(font_color)
            self.background_color_widget.set_color(background_color)
            
            with save_config(setting_config):    
                setting_config.config.set("general", "font_color", font_color)
                setting_config.config.set("general", "background_color", background_color)
            
            global_event.emit("change-color-scheme", option_value)
    
    def change_font_color(self, color_button, font_color):
        self.color_scheme_widget.set_select_index(
            map(lambda (color_scheme_value, color_infos): color_scheme_value, color_style.items()).index("custom"))
        
        with save_config(setting_config):    
            setting_config.config.set("general", "color_scheme", "custom")
            setting_config.config.set("general", "font_color", font_color)
        
        global_event.emit("change-font-color", font_color)
    
    def change_background_color(self, color_button, background_color):
        self.color_scheme_widget.set_select_index(
            map(lambda (color_scheme_value, color_infos): color_scheme_value, color_style.items()).index("custom"))
        
        with save_config(setting_config):    
            setting_config.config.set("general", "color_scheme", "custom")
            setting_config.config.set("general", "background_color", background_color)
        
        global_event.emit("change-background-color", background_color)
        
    def change_font(self, combo_box, option_name, option_value, index):
        with save_config(setting_config):    
            setting_config.config.set("general", "font", option_value)
        
        global_event.emit("change-font", option_value)
    
    def change_font_size(self, spin, font_size):
        with save_config(setting_config):    
            setting_config.config.set("general", "font_size", font_size)
        
        global_event.emit("change-font-size", font_size)
        
    def save_background_transparent(self, scalebar, value):
        with save_config(setting_config):    
            setting_config.config.set("general", "background_transparent", value)
        
        global_event.emit("change-background-transparent", value)
        
    def fill_table(self, table, table_items):
        for (index, (setting_name, setting_widget)) in enumerate(table_items):
            table.attach(
                Label(setting_name, text_x_align=ALIGN_END),
                0, 1, 
                index, index + 1,
                )
            table.attach(
                setting_widget,
                1, 2, 
                index, index + 1,
                )
        
gobject.type_register(GeneralSettings)        

class KeybindSettings(ScrolledWindow):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        ScrolledWindow.__init__(self)
        self.box = gtk.VBox()
        
        self.entry_widget_dict = {}
        
        key_name_dict = OrderedDict(
            [("copy_clipboard", _("Copy")),
             ("paste_clipboard", _("Paste")),
             ("split_vertically", _("Split vertically")),
             ("split_horizontally", _("Split horizontally")),
             ("close_current_window", _("Close current window")),
             ("close_other_window", _("Close other window")),
             ("scroll_page_up", _("Scroll page up")),
             ("scroll_page_down", _("Scroll page down")),
             ("focus_up_terminal", _("Focus the terminal above")),
             ("focus_down_terminal", _("Focus the terminal below")),
             ("focus_left_terminal", _("Focus the temrinal left")),
             ("focus_right_terminal", _("Focus the terminal right")),
             ("zoom_in", _("Zoom in")),
             ("zoom_out", _("Zoom out")),
             ("revert_default_size", _("Reset zoom")),
             ("new_workspace", _("New workspace")),
             ("close_current_workspace", _("Close workspace")),
             ("switch_prev_workspace", _("Previous workspace")),
             ("switch_next_workspace", _("Next workspace")),
             ("search_forward", _("Search forward")),
             ("search_backward", _("Search backward")),
             ("toggle_full_screen", _("Fullscreen")),
             ("show_helper_window", _("Display hotkeys")),
             ("show_remote_login_window", _("Set up SSH connection")),
             ("show_correlative_window", _("Show correlative child window")),
             ])
        
        self.table = gtk.Table(len(key_name_dict), 2)
        self.table.set_row_spacings(TABLE_ROW_SPACING)
        self.table.set_col_spacing(0, TABLE_COLUMN_SPACING)
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 0, 0)
        self.table_align.set_padding(TABLE_PADDING_TOP, TABLE_PADDING_BOTTOM, TABLE_PADDING_LEFT, 0)
        
        self.fill_table(self.table, key_name_dict)
        self.table_align.add(self.table)
        self.box.pack_start(self.table_align)
        self.add_with_viewport(self.box)
        
        self.connect("hierarchy-changed", lambda w, t: self.get_vadjustment().set_value(0))
        self.connect("size-allocate", self.realize_callback)
        
    def realize_callback(self, widget, rect):
        self.box.set_size_request(483, -1)
        self.table_align.set_size_request(483, -1)
        
    def fill_table(self, table, key_name_dict):
        for (index, (key_value, key_name)) in enumerate(key_name_dict.items()):
            key_bind = get_config("keybind", key_value)
            table.attach(
                Label(key_name, text_x_align=ALIGN_END),
                0, 1, 
                index, index + 1,
                )
            self.entry_widget_dict[key_value] = KeybindEntry(key_value, key_bind)
            shortcutkey_entry = self.entry_widget_dict[key_value]
            shortcutkey_entry.set_size(170, 23)
            table.attach(
                shortcutkey_entry,
                1, 2, 
                index, index + 1,
                )
            
gobject.type_register(KeybindSettings)        

class KeybindEntry(ShortcutKeyEntry):
    '''
    class docs
    '''
	
    def __init__(self, key_value, key_bind):
        '''
        init docs
        '''
        ShortcutKeyEntry.__init__(self, key_bind, support_shift=True)
        self.key_value = key_value
        
        self.connect("shortcut-key-change", self.key_change)
        
    def key_change(self, entry, new_keybind):
        with save_config(setting_config):    
            setting_config.config.set("keybind", self.key_value, new_keybind)
        
        global_event.emit("keybind-changed", self.key_value, new_keybind)
        
gobject.type_register(KeybindEntry)        

class AdvancedSettings(gtk.VBox):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        gtk.VBox.__init__(self)

        startup_mode = get_config("advanced", "startup_mode")
        self.startup_widget = ComboBox(STARTUP_MODE_ITEMS, fixed_width=COMBO_BOX_WIDTH)
        self.startup_widget.connect("item-selected", self.save_startup_setting)
        self.startup_widget.set_select_index(unzip(STARTUP_MODE_ITEMS)[-1].index(startup_mode))
        
        startup_command = get_config("advanced", "startup_command")
        self.startup_command_widget = InputEntry(startup_command)
        self.startup_command_widget.set_size(100, 23)
        self.startup_command_widget.entry.connect("changed", self.startup_command_changed)
        
        startup_directory = get_config("advanced", "startup_directory")
        self.startup_directory_widget = InputEntry(startup_directory)
        self.startup_directory_widget.set_size(100, 23)
        self.startup_directory_widget.entry.connect("changed", self.startup_directory_changed)
        
        cursor_shape = get_config("advanced", "cursor_shape")
        self.cursor_shape_widget = ComboBox(CURSOR_SHAPE_ITEMS, fixed_width=COMBO_BOX_WIDTH)
        self.cursor_shape_widget.connect("item-selected", self.save_cursor_shape)
        self.cursor_shape_widget.set_select_index(unzip(CURSOR_SHAPE_ITEMS)[-1].index(cursor_shape))
        
        ask_on_quit = is_bool(get_config("advanced", "ask_on_quit"))
        self.ask_on_quit_widget = SwitchButton(ask_on_quit)
        self.ask_on_quit_widget.connect("toggled", self.ask_on_quit_toggle)
        
        cursor_blink_mode = get_config("advanced", "cursor_blink_mode")
        self.cursor_blink_mode_widget = ComboBox(CURSOR_BLINK_MODE_ITEMS, fixed_width=COMBO_BOX_WIDTH)
        self.cursor_blink_mode_widget.connect("item-selected", self.save_cursor_blink_mode)
        self.cursor_blink_mode_widget.set_select_index(unzip(CURSOR_BLINK_MODE_ITEMS)[-1].index(cursor_blink_mode))

        scroll_on_key = is_bool(get_config("advanced", "scroll_on_key"))
        self.scroll_on_key_widget = SwitchButton(scroll_on_key)
        self.scroll_on_key_widget.connect("toggled", self.scroll_on_key_toggle)
        
        scroll_on_output = is_bool(get_config("advanced", "scroll_on_output"))
        self.scroll_on_output_widget = SwitchButton(scroll_on_output)
        self.scroll_on_output_widget.connect("toggled", self.scroll_on_output_toggle)
        
        copy_on_selection = is_bool(get_config("advanced", "copy_on_selection"))
        self.copy_on_selection_widget = SwitchButton(copy_on_selection)
        self.copy_on_selection_widget.connect("toggled", self.copy_on_selection_toggle)

        open_file_on_hover = is_bool(get_config("advanced", "open_file_on_hover"))
        self.open_file_on_hover_widget = SwitchButton(open_file_on_hover)
        self.open_file_on_hover_widget.connect("toggled", self.open_file_on_hover_toggle)
        
        self.table = gtk.Table(7, 2)
        self.table.set_row_spacings(TABLE_ROW_SPACING)
        self.table.set_col_spacing(0, TABLE_COLUMN_SPACING)
        table_items = [
            (_("Cursor shape: "), self.cursor_shape_widget),
            (_("Cursor blink: "), self.cursor_blink_mode_widget),
            (_("Window state: "), self.startup_widget),
            (_("Startup command: "), self.startup_command_widget),
            (_("Startup directory: "), self.startup_directory_widget),
            (_("Ask on quit"), self.ask_on_quit_widget),
            (_("Scroll on keystroke: "), self.scroll_on_key_widget),
            (_("Scroll on output: "), self.scroll_on_output_widget),
            (_("Copy on selection: "), self.copy_on_selection_widget),
            (_("Open file on hover: "), self.open_file_on_hover_widget),
            ]
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 1, 1)
        self.table_align.set_padding(TABLE_PADDING_TOP, TABLE_PADDING_BOTTOM, TABLE_PADDING_LEFT, 0)
        
        self.fill_table(self.table, table_items)
        self.table_align.add(self.table)
        self.add(self.table_align)
        
    def save_startup_setting(self, combo_box, option_name, option_value, index):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "startup_mode", option_value)
                
    def save_cursor_shape(self, combo_box, option_name, option_value, index):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "cursor_shape", option_value)
        
        global_event.emit("set-cursor-shape", option_value)
        
    def save_cursor_blink_mode(self, combo_box, option_name, option_value, index):
        with save_config(setting_config):
            setting_config.config.set("advanced", "cursor_blink_mode", option_value)

        global_event.emit("set-cursor-blink-mode", option_value)

    def startup_command_changed(self, entry, startup_command):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "startup_command", startup_command)

    def startup_directory_changed(self, entry, startup_directory):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "startup_directory", startup_directory)
            
    def ask_on_quit_toggle(self, toggle_button):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "ask_on_quit", toggle_button.get_active())
        
    def scroll_on_key_toggle(self, toggle_button):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "scroll_on_key", toggle_button.get_active())
        
        global_event.emit("scroll-on-key-toggle", toggle_button.get_active())

    def scroll_on_output_toggle(self, toggle_button):
        with save_config(setting_config):    
            setting_config.config.set("advanced", "scroll_on_output", toggle_button.get_active())
        
        global_event.emit("scroll-on-output-toggle", toggle_button.get_active())
        
    def copy_on_selection_toggle(self, toggle_button):
        with save_config(setting_config):
            setting_config.config.set("advanced", "copy_on_selection", toggle_button.get_active())
        
        global_event.emit("copy-on-selection-toggle", toggle_button.get_active())
        
    def open_file_on_hover_toggle(self, toggle_button):
        with save_config(setting_config):
            setting_config.config.set("advanced", "open_file_on_hover", toggle_button.get_active())
        
        global_event.emit("open-file-on-hover-toggle", toggle_button.get_active())
        
    def fill_table(self, table, table_items):
        for (index, (setting_name, setting_widget)) in enumerate(table_items):
            table.attach(
                Label(setting_name, text_x_align=ALIGN_END),
                0, 1, 
                index, index + 1,
                )
            table.attach(
                setting_widget,
                1, 2, 
                index, index + 1,
                )
            
gobject.type_register(AdvancedSettings)        

class SettingConfig(gobject.GObject):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        gobject.GObject.__init__(self)
        self.config_path = os.path.join(XDG_CONFIG_HOME, PROJECT_NAME, "config")
        
        if not os.path.exists(self.config_path):
            self.config = Config(self.config_path, DEFAULT_CONFIG)
            self.config.write()
        else:
            self.config = Config(self.config_path)
            self.config.load()
            
gobject.type_register(SettingConfig)        

@contextmanager
def save_config(setting_config):
    # Load default config if config file is not exists.
    config_path = os.path.join(XDG_CONFIG_HOME, PROJECT_NAME, "config")
    if not os.path.exists(config_path):
        touch_file(config_path)
        setting_config.config.load_default()
    try:  
        # So setting change operations.
        yield  
    except Exception, e:  
        print 'function save_config got error: %s' % e  
        traceback.print_exc(file=sys.stdout)
    else:  
        # Save setting config last.
        setting_config.config.write()
        
def get_config(selection, option, default=None):
    try:
        return setting_config.config.config_parser.get(selection, option)
    except:
        try:
            if default:
                return default
            else:
                return dict(dict(DEFAULT_CONFIG)[selection])[option]
        except:
            raise "This is a buf of get_config(%s, %s, %s)" % (selection, option, default)
        
class EditRemoteLogin(DialogBox):
    '''
    class docs
    '''
	
    def __init__(self, name, save_remote_login, remote_info=None):
        '''
        init docs
        '''
        DialogBox.__init__(
            self, 
            name,
            280,
            200,
            mask_type=DIALOG_MASK_GLASS_PAGE,
            close_callback=self.hide_window,
            )
        self.save_remote_login = save_remote_login
        self.remote_info = remote_info
        
        self.box = gtk.VBox()
        
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 1, 1)
        self.table_align.set_padding(10, 10, 20, 20)
        
        self.save_button = Button(_("Save"))
        self.save_button.connect("clicked", lambda w: self.save_login_info())
        
        self.right_button_box.set_buttons([self.save_button])
        
        self.box.pack_start(self.table_align, True, True)
        
        self.body_box.add(self.box)
        
    def hide_window(self):
        self.hide_all()
        
        return True
        
    def save_login_info(self):
        self.save_remote_login(
            self.name_entry.get_text(),
            self.user_entry.get_text(),
            self.server_entry.get_text(),
            self.password_entry.entry.get_text(),
            self.port_box.value_entry.get_text(),
            )
        
        self.hide_all()
        
    def show_login(self, parent_window):
        container_remove_all(self.table_align)
        self.create_table()
        self.table_align.add(self.table)
        
        place_center(parent_window, self)
        self.show_all()
        
        self.name_entry.entry.grab_focus()
        
        self.unset_focus_chain()
        self.set_focus_chain(
            [self.name_entry.entry, self.user_entry.entry, self.server_entry.entry, self.password_entry.entry, self.save_button])

    def set_save_button(self, entry, str):
        if entry.get_text() and not self.save_button.get_sensitive():
            self.save_button.set_sensitive(True)
        if not entry.get_text() and self.save_button.get_sensitive():
            self.save_button.set_sensitive(False)

    def create_table(self):
        self.table = gtk.Table(4, 2)
        self.table.set_col_spacing(0, 10)
        names = [_("Name: "), _("Server: "), _("User: "), _("Password: "), _("Port: ")]
        
        if self.remote_info:
            (name, user, server, password, port) = self.remote_info
        else:
            name, user, server, password, port = "", "", "", "", 22
            self.save_button.set_sensitive(False)
        
        self.name_entry = InputEntry(name)
        self.name_entry.entry.connect("changed", self.set_save_button)
        self.user_entry = InputEntry(user)
        self.server_entry = InputEntry(server)
        self.password_entry = PasswordEntry(password)
        self.port_box = SpinBox(port, lower=1, step=1)
        
        for (index, name) in enumerate(names):
            label = Label(name)
            label.set_can_focus(False)
            self.table.attach(
                label,
                0, 1,
                index, index + 1,
                xoptions=gtk.FILL,
                )
            if name == _("Name: "):
                widget = self.name_entry
                widget.set_size(80, 23)
            elif name == _("Server: "):
                widget = self.server_entry
                widget.set_size(80, 23)
            elif name == _("User: "):
                widget = self.user_entry
                widget.set_size(80, 23)
            elif name == _("Password: "):
                widget = self.password_entry
                widget.set_size(80, 23)
            elif name == _("Port: "):
                widget = self.port_box
            
            self.table.attach(
                widget,
                1, 2,
                index, index + 1,
                )
            
gobject.type_register(EditRemoteLogin)        

class RemoteLogin(DialogBox):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        DialogBox.__init__(
            self,
            _("Remote login"),
            500,
            400,
            mask_type=DIALOG_MASK_GLASS_PAGE,
            close_callback=self.hide_window,
            )
        
        self.add_button = Button(_("Add"))
        self.connect_button = Button(_("Connection"))
        
        self.add_button.connect("clicked", lambda w: self.show_add_remote_login())
        self.connect_button.connect("clicked", lambda w: self.connect_remote_login())
        
        self.right_button_box.set_buttons([self.add_button, self.connect_button])
        
        self.treeview = TreeView()
        self.treeview.set_column_titles([_("Name"), _("Server")])
        self.treeview.connect("items-change", lambda t: self.save_login_info())
        self.treeview.connect("double-click-item", lambda treeview, item, column, offset_x, offset_y: self.connect_remote_login(item))
        self.body_box.add(self.treeview)
        
        self.read_login_info()
        
        self.add_remote_login = EditRemoteLogin(_("Add remote login"), self.save_remote_login)
        self.add_remote_login.set_transient_for(self)
        
        self.parent_window = None
        
        self.treeview.connect("right-press-items", self.right_press_items)
        
        self.connect("key-press-event", self.key_press_remote_login)
        
        self.keymap = {
            "Escape" : self.hide_window,
            }
        
    def key_press_remote_login(self, widget, event):
        key_name = get_keyevent_name(event)
        if key_name in self.keymap:
            self.keymap[key_name]()
            return True
        else:
            return False
        
    def read_login_info(self):
        if os.path.exists(LOGIN_DATABASE):
            connection = sqlite3.connect(LOGIN_DATABASE)
            cursor = connection.cursor()
            
            items = []
            cursor.execute('SELECT * FROM login')
            for (name, user, server, password, port) in cursor.fetchall():
                items.append(TextItem(name, user, server, password, port))
                
            self.treeview.add_items(items)    
        
    def save_login_info(self):
        items = self.treeview.get_items()
        item_infos = map(lambda item: (
                unicode(item.name),
                unicode(item.user),
                unicode(item.server),
                unicode(item.password),
                unicode(item.port),
                ), items)
        
        remove_path(LOGIN_DATABASE)
        touch_file(LOGIN_DATABASE)
        
        connection = sqlite3.connect(LOGIN_DATABASE)
        cursor = connection.cursor()
        
        cursor.execute('''CREATE TABLE login (name, user, server, password, port)''')
        cursor.executemany('''INSERT INTO login(name, user, server, password, port) VALUES(?, ?, ?, ?, ?)''', item_infos)
        
        connection.commit()
        connection.close()
        
    def save_item_remote_login(self, item, name, user, server, password, port):
        item.name = name
        item.user = user
        item.server = server
        item.password = password
        item.port = port
        
        if item.redraw_request_callback:
            item.redraw_request_callback(item)
            
    def update_remote_login(self, current_item):
        edit_remote_login = EditRemoteLogin(
            _("Edit remote login"),
            lambda name, user, server, password, port: self.save_item_remote_login(current_item, name, user, server, password, port),
            (current_item.name, current_item.user, current_item.server, current_item.password, int(current_item.port)),
            )
        edit_remote_login.set_transient_for(self)
        edit_remote_login.show_login(self.parent_window)
        
        self.save_login_info()
        
    def right_press_items(self, *args):
        (treeview, x, y, current_item, select_items) = args
        if current_item:
            menu_items = [
                (None, _("Edit"), lambda : self.update_remote_login(current_item)),
                (None, _("Delete"), treeview.delete_select_items),
                ]
            menu = Menu(menu_items, True)
            menu.show((x, y))
        
    def show_add_remote_login(self):
        self.add_remote_login.show_login(self.parent_window)
        
    def save_remote_login(self, name, user, server, password, port):
        item = TextItem(name, user, server, password, port)
        self.treeview.add_items([item])
        self.treeview.select_items([item])
        
        self.save_login_info()
        
    def connect_remote_login(self, text_item=None):
        if len(self.treeview.select_rows) == 1:
            if not text_item:
                text_item = self.treeview.visible_items[self.treeview.select_rows[0]]
            global_event.emit("ssh-login", text_item.user, text_item.server, text_item.password, text_item.port)
            
            self.hide_all()
        
    def show_login(self, parent_window):
        self.parent_window = parent_window
        
        self.show_all()
        place_center(parent_window, self)
        
    def hide_window(self):
        self.hide_all()
        
        return True
    
gobject.type_register(RemoteLogin)    
    
class TextItem(NodeItem):
    '''
    TextItem class.
    '''
	
    def __init__(self, name, user, server, password, port, column_index=0):
        '''
        Initialize TextItem class.
        '''
        NodeItem.__init__(self)
        self.name = name
        self.user = user
        self.server = server
        self.password = password
        self.port = str(port)
        self.column_index = column_index
        self.column_offset = 10
        self.text_size = DEFAULT_FONT_SIZE
        self.text_padding = 10
        self.alignment = pango.ALIGN_CENTER
        self.height = 24
        
    def get_height(self):
        return self.height
        
    def get_column_widths(self):
        return [100, 300]
        
    def get_column_renders(self):
        return [
            lambda cr, rect: self.render_text(cr, rect, self.name),
            lambda cr, rect: self.render_text(cr, rect, self.server),
            ]
        
    def render_text(self, cr, rect, text):
        # Draw select background.
        background_color = get_background_color(self.is_highlight, self.is_select, self.is_hover)
        if background_color:
            cr.set_source_rgb(*color_hex_to_cairo(ui_theme.get_color(background_color).get_color()))    
            cr.rectangle(rect.x, rect.y, rect.width, rect.height)
            cr.fill()
        
        # Draw text.
        text_color = get_text_color(self.is_select)
        draw_text(cr, 
                  text,
                  rect.x + self.text_padding + self.column_offset * self.column_index,
                  rect.y,
                  rect.width,
                  rect.height,
                  text_color=text_color,
                  text_size=self.text_size,
                  alignment=self.alignment,
                  )
        
gobject.type_register(TextItem)

setting_config = SettingConfig()

class Paned(gtk.Paned):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        gtk.Paned.__init__(self)
        
    def do_expose_event(self, event):
        gtk.Container.do_expose_event(self, event)
        self.draw_mask(event)
        
        return False
    
    def draw_mask(self, event):
        handle = self.get_handle_window()
        cr = handle.cairo_create()
        (width, height) = handle.get_size()
        if self.get_orientation() == gtk.ORIENTATION_HORIZONTAL:
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#111111", 0.8)))
            cr.rectangle(0, 0, 1, height)
            cr.fill()
            
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#333333", 0.5)))
            cr.rectangle(1, 0, 1, height)
            cr.fill()
        else:
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#111111", 0.8)))
            cr.rectangle(0, 0, width, 1)
            cr.fill()
        
            cr.set_source_rgba(*alpha_color_hex_to_cairo(("#333333", 0.5)))
            cr.rectangle(0, 1, width, 1)
            cr.fill()
            
gobject.type_register(Paned)        

class HPaned(Paned):
    def __init__(self, ):
        Paned.__init__(self)
        self.set_orientation(gtk.ORIENTATION_HORIZONTAL)

gobject.type_register(HPaned)

class VPaned(Paned):
    def __init__(self):
        Paned.__init__(self)
        self.set_orientation(gtk.ORIENTATION_VERTICAL)
        
gobject.type_register(VPaned)

class SettingDialog(PreferenceDialog):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        PreferenceDialog.__init__(self, 626, 390)
        
        restore_default_button = Button(_("Reset"))
        restore_default_button.connect("clicked", lambda w: self.restore_default())
        
        close_button = Button(_("Close"))
        close_button.connect("clicked", lambda w: self.hide_all())
        
        container_remove_all(self.right_button_box.button_box)
        self.right_button_box.set_buttons([restore_default_button, close_button])
        
    def restore_default(self):
        page_widget = self.right_box.get_children()[0]
        if isinstance(page_widget, GeneralSettings):
            config_dict = dict(GENERAL_CONFIG)        
            with save_config(setting_config):
                for (config_key, config_value) in GENERAL_CONFIG:
                    setting_config.config.set("general", config_key, config_value)
                    
            (_, [font_color, background_color]) = color_style[config_dict["color_scheme"]]
                    
            font = config_dict["font"]
            global_event.emit("change-font", font)
            font_families = get_font_families()
            try:
                page_widget.font_widget.set_select_index(font_families.index(font))
            except:
                page_widget.font_widget.set_select_index(font_families.index(BACKUP_FONT))
            
            font_size = int(config_dict["font_size"])
            global_event.emit("change-font-size", font_size)
            page_widget.font_size_widget.set_value(font_size)
            
            color_scheme = config_dict["color_scheme"]
            global_event.emit("change-color-scheme", color_scheme)
            page_widget.color_scheme_widget.set_select_index(
                map(lambda (color_scheme_value, color_infos): color_scheme_value, color_style.items()).index(color_scheme))
            
            global_event.emit("change-font-color", font_color)
            page_widget.font_color_widget.set_color(font_color)
            
            global_event.emit("change-background-color", background_color)
            page_widget.background_color_widget.set_color(background_color)
            
            background_transparent = float(config_dict["background_transparent"])
            global_event.emit("change-background-transparent", background_transparent)
            page_widget.background_transparent_widget.set_value(background_transparent)
            
        elif isinstance(page_widget, KeybindSettings):
            with save_config(setting_config):
                for (config_key, config_value) in KEYBIND_CONFIG:
                    page_widget.entry_widget_dict[config_key].set_shortcut_key(config_value)
                    
        elif isinstance(page_widget, AdvancedSettings):
            with save_config(setting_config):
                for (config_key, config_value) in ADVANCED_CONFIG:
                    setting_config.config.set("advanced", config_key, config_value)
                    
            config_dict = dict(ADVANCED_CONFIG)        
            
            startup_mode = config_dict["startup_mode"]
            page_widget.startup_widget.set_select_index(unzip(STARTUP_MODE_ITEMS)[-1].index(startup_mode))
            
            startup_command = config_dict["startup_command"]
            page_widget.startup_command_widget.set_text(startup_command)

            startup_directory = config_dict["startup_directory"]
            page_widget.startup_directory_widget.set_text(startup_directory)
            
            cursor_shape = config_dict["cursor_shape"]
            page_widget.cursor_shape_widget.set_select_index(unzip(CURSOR_SHAPE_ITEMS)[-1].index(cursor_shape))
            global_event.emit("set-cursor-shape", cursor_shape)
            
            ask_on_quit = is_bool(config_dict["ask_on_quit"])
            page_widget.ask_on_quit_widget.set_active(ask_on_quit)
            
            cursor_blink_mode = config_dict["cursor_blink_mode"]
            page_widget.cursor_blink_mode_widget.set_select_index(
                unzip(CURSOR_BLINK_MODE_ITEMS)[-1].index(cursor_blink_mode))
            global_event.emit("set-cursor-blink-mode", cursor_blink_mode)
            
            scroll_on_key = is_bool(config_dict["scroll_on_key"])
            page_widget.scroll_on_key_widget.set_active(scroll_on_key)
            global_event.emit("scroll-on-key-toggle", scroll_on_key)
            
            scroll_on_output = is_bool(config_dict["scroll_on_output"])
            page_widget.scroll_on_output_widget.set_active(scroll_on_output)
            global_event.emit("scroll-on-output-toggle", scroll_on_output)

            copy_on_selection = is_bool(config_dict["copy_on_selection"])
            page_widget.copy_on_selection_widget.set_active(copy_on_selection)
            global_event.emit("copy-on-selection-toggle", copy_on_selection)

            open_file_on_hover = is_bool(config_dict["open_file_on_hover"])
            page_widget.open_file_on_hover_widget.set_active(open_file_on_hover)
            global_event.emit("open-file-on-hover-toggle", open_file_on_hover)

gobject.type_register(SettingDialog)        

class Statusbar(gtk.Alignment):
    def __init__(self):
        gtk.Alignment.__init__(self)
        self.height = 24
        self.set(0.5, 0.5, 1, 1)
        self.set_padding(0, 2, 2, 2)
        self.set_size_request(-1, self.height)
        self.box = EventBox()        
        self.indicator_box = gtk.HBox()
        
        self.workspace_indicator = WorkspaceIndicator()
        self.path_indicator = PathIndicator()
        
        self.indicator_box.pack_start(self.workspace_indicator, True, True)
        self.indicator_box.pack_start(self.path_indicator, False, False)
        self.box.add(self.indicator_box)
        self.add(self.box)
        
        self.padding_top = 0
        self.padding_bottom = 2
        self.padding_left = 2
        self.padding_right = 2
        
        self.connect("expose-event", self.expose_statusbar)
        
    def adjust_padding(self, padding_top, padding_bottom, padding_left, padding_right):
        self.padding_top = padding_top
        self.padding_bottom = padding_bottom
        self.padding_left = padding_left
        self.padding_right = padding_right
        
        self.queue_draw()
        
    def expose_statusbar(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        x, y, w, h = rect.x, rect.y, rect.width, rect.height

        background_color = get_config("general", "background_color")
        transparent = get_config("general", "background_transparent")
        (r, g, b) = color_hex_to_cairo(background_color)
        cr.set_source_rgba(r, g, b, min(float(transparent) + 0.1, 1))
        cr.rectangle(
            x + self.padding_left, 
            y + self.padding_top, 
            w - self.padding_left - self.padding_right, 
            h - self.padding_top - self.padding_bottom,
            )
        cr.fill()
        
        propagate_expose(widget, event)
        
        return True
        
gobject.type_register(Statusbar)        

class WorkspaceIndicator(gtk.Alignment):

    def __init__(self):
        gtk.Alignment.__init__(self)
        self.set(0, 0, 1, 1)
        
        self.offset_x = 1
        self.offset_y = 1
        self.padding_x = 2
        self.width = 30
        self.height = 20
        self.radius = 0
        
        self.current_workspace_index = 1
        self.workspaces = [1]
        self.set_size_request(-1, self.height)
        
        self.eventbox = EventBox()
        self.add(self.eventbox)
        
        self.eventbox.connect("expose-event", self.expose_workspace_indicator)
        self.eventbox.connect("button-press-event", self.button_press_indicator)        
        
    def get_workspace_rect(self, index):
        rect = self.eventbox.allocation
        
        return (
            rect.x + self.padding_x + index * (self.width + self.offset_x),
            rect.y + self.offset_y,
            self.width,
            self.height,
            )
        
    def button_press_indicator(self, widget, event):
        if len(self.workspaces) > 1:
            
            for (index, workspace_index) in enumerate(self.workspaces):
                (x, y, w, h) = self.get_workspace_rect(index)
                
                if x < event.x < x + w:
                    global_event.emit("switch-to-workspace", index)

    def expose_workspace_indicator(self, widget, event):
        if len(self.workspaces) > 1:
            cr = widget.window.cairo_create()
            
            (r, g, b) = color_hex_to_cairo(get_config("general", "font_color"))
            for (index, workspace_index) in enumerate(self.workspaces):
                if workspace_index == self.current_workspace_index:
                    cr.set_source_rgba(r, g, b, 0.5)
                else:
                    if get_config("general", "background_color") == "#ffffff":
                        cr.set_source_rgba(0, 0, 0, 0.3)
                    else:
                        cr.set_source_rgba(1, 1, 1, 0.05)
                    
                (x, y, w, h) = self.get_workspace_rect(index)
                draw_round_rectangle(cr, x, y, w, h, self.radius)
                cr.fill()
                
                draw_text(
                    cr,
                    str(workspace_index),
                    x, y, w, h,
                    text_color="#DDDDDD",
                    alignment=pango.ALIGN_CENTER,
                    )

class PathIndicator(gtk.Alignment):
    
    def __init__(self):
        gtk.Alignment.__init__(self)
        self.set_size_request(200, -1)
        
        self.set(0.5, 0.5, 1, 1)
        self.set_padding(0, 0, 0, 2)
        self.path = ""
        
        self.eventbox = EventBox()
        self.add(self.eventbox)
        
        self.eventbox.connect("expose-event", self.expose_path_indicator)
        self.eventbox.connect("button-press-event", self.button_press_path_indicator)
        
        set_hover_cursor(self.eventbox, gtk.gdk.HAND2)
        
    def button_press_path_indicator(self, widget, event):
        subprocess.Popen("xdg-open '%s'" % self.path, shell=True)
        
    def expose_path_indicator(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        
        offset_y = 0
        draw_text(
            cr,
            self.path,
            rect.x, 
            rect.y + offset_y,
            rect.width,
            rect.height,
            alignment=pango.ALIGN_RIGHT,
            text_color="#666666"
            )

def execute_cb(option, opt, value, lparser):
    assert value is None
    value = []
    while lparser.rargs:
        arg = lparser.rargs[0]
        value.append(arg)
        del(lparser.rargs[0])
    setattr(lparser.values, option.dest, value)
    
if __name__ == "__main__":
    parser = OptionParser(usage="Usage: deepin-terminal [options] [arg]", version="deepin-terminal v1.0")
    parser.add_option("--working-directory", dest="working_directory", help=_("working directory"), metavar="FILE")
    parser.add_option("--quake-mode", action="store_true", dest="quake_mode", help=_("run with quake mode"))
    parser.add_option("-e", action="callback", callback=execute_cb, dest="startup_command", help=_("startup terminal with given command"))
    parser.get_option('-h').help = _("show this help message and exit")
    parser.get_option('--version').help = _("show program's version number and exit")
    
    (opts, args) = parser.parse_args()
    
    if (not opts.quake_mode) or (not is_exists(QUAKE_DBUS_NAME, QUAKE_OBJECT_NAME)):
        Terminal(opts.quake_mode, opts.working_directory, opts.startup_command).run()
    
