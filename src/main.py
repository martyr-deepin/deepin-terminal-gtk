#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2011 ~ 2012 Deepin, Inc.
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

from dtk.ui.init_skin import init_skin
from deepin_utils.file import get_parent_dir
from deepin_utils.process import run_command
from dtk.ui.utils import container_remove_all, get_match_parent, cairo_state, propagate_expose, is_left_button, is_right_button
from deepin_utils.core import unzip
from deepin_utils.font import get_font_families
from dtk.ui.draw import draw_pixbuf, draw_text
from dtk.ui.utils import place_center, get_widget_root_coordinate
from dtk.ui.constant import WIDGET_POS_BOTTOM_LEFT, ALIGN_END, DEFAULT_FONT_SIZE
from dtk.ui.label import Label
from dtk.ui.menu import Menu
from dtk.ui.window import Window
import pango
import os
import gtk
import gobject
import vte
import cairo
from dtk.ui.keymap import get_keyevent_name, is_no_key_press, has_ctrl_mask
from dtk.ui.events import EventRegister
import gc
import urllib
from math import pi
from deepin_utils.config import Config
from collections import OrderedDict

PROJECT_NAME = "deepin-terminal"

app_theme = init_skin(
    PROJECT_NAME,
    "1.0",
    "colourless_glass",
    os.path.join(get_parent_dir(__file__, 2), "skin"),
    os.path.join(get_parent_dir(__file__, 2), "app_theme")
)
from dtk.ui.application import Application
from dtk.ui.entry import Entry
from dtk.ui.titlebar import Titlebar
from dtk.ui.button import SwitchButton
from dtk.ui.dialog import PreferenceDialog
from dtk.ui.combo import ComboBox
from dtk.ui.spin import SpinBox
from dtk.ui.color_selection import ColorButton
from dtk.ui.scalebar import HScalebar
from dtk.ui.entry import ShortcutKeyEntry, InputEntry, PasswordEntry
from dtk.ui.scrolled_window import ScrolledWindow
from dtk.ui.button import Button
from dtk.ui.dialog import DialogBox
from dtk.ui.dialog import DIALOG_MASK_GLASS_PAGE
from dtk.ui.treeview import TreeView, NodeItem, get_background_color, get_text_color
from dtk.ui.utils import color_hex_to_cairo
from dtk.ui.theme import ui_theme

from deepin_utils.file import remove_path, touch_file
import sqlite3
        
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

WORKSPACE_SNAPSHOT_HEIGHT = 160
WORKSPACE_SNAPSHOT_OFFSET_TOP = 10
WORKSPACE_SNAPSHOT_OFFSET_BOTTOM = 30
WORKSPACE_SNAPSHOT_OFFSET_X = 10

workspace_index = 1

DRAG_TEXT_URI = 1
DRAG_TEXT_PLAIN = 2

TABLE_ROW_SPACING = 8
TABLE_COLUMN_SPACING = 4
TABLE_PADDING_LEFT = 50
TABLE_PADDING_TOP = 50
TABLE_PADDING_BOTTOM = 50

TRANSPARENT_OFFSET = 0.1

_HOME = os.path.expanduser('~')
XDG_CONFIG_HOME = os.environ.get('XDG_CONFIG_HOME') or \
            os.path.join(_HOME, '.config')

# NOTE:
# We just store remote informations (include password) in sqlite database.
# please don't fill password if you care about safe problem.
LOGIN_DATABASE = os.path.join(XDG_CONFIG_HOME, PROJECT_NAME, ".config", "login.db")

DEFAULT_CONFIG = [
    ("general", 
     [("font", "XHei Mono.Ubuntu"),
      ("font_size", "10"),
      ("color_precept", "deepin"), 
      ("font_color", "#00FF00"),
      ("background_color", "#000000"),
      ("background_transparent", "0.8"),
      ]),
    ("keybind", 
     [("copy_clipboard", "Ctrl + C"),
      ("paste_clipboard", "Ctrl + V"),
      ("split_vertical", "Ctrl + v"),
      ("split_horizontal", "Ctrl + h"),
      ("close_terminal", "Ctrl + d"),
      ("focus_up_terminal", "Alt + Up"),
      ("focus_down_terminal", "Alt + Down"),
      ("focus_left_terminal", "Alt + Left"),
      ("focus_right_terminal", "Alt + Right"),
      ("zoom_in", "Ctrl + ="),
      ("zoom_out", "Ctrl + -"),
      ("revert_default_size", "Ctrl + 0"),
      ("new_workspace", "Ctrl + /"),
      ("close_current_workspace", "Ctrl + ;"),
      ("switch_prev_workspace", "Ctrl + ,"),
      ("switch_next_workspace", "Ctrl + ."),
      ("search_forward", "Ctrl + '"),
      ("search_backward", "Ctrl + \""),
      ("toggle_full_screen", "F11"),
      ("show_helper_window", "Ctrl + ?"),            
      ("show_remote_login_window", "Ctrl + ["),            
      ]),
    ("advanced", 
     [("startup_mode", "normal"),
      ("startup_command", "bash"),
      ("startup_directory", ""),
      ("cursor_shape", "block"),
      ("scroll_on_key", "True"),
      ("scroll_on_output", "False"),
      ]),
    ]

color_style = {"deepin" : ("深度", ["#00FF00", "#000000"]),
               "grey_on_black": ("黑底灰字", ["#aaaaaa", "#000000"]),
               "black_on_yellow": ("黄底黑字", ["#000000", "#ffffdd"]),
               "black_on_white": ("白底黑字", ["#000000", "#ffffff"]),
               "white_on_black": ("黑底白字", ["#ffffff", "#000000"]),
               "green_on_black": ("黑底绿字", ["#00ff00", "#000000"]),
               "customize" : ("自定义", ["#00FF00", "#000000"]),
               }

COMBO_BOX_WIDTH = 150

def get_active_working_directory(toplevel_widget):
    focus_widget = toplevel_widget.get_focus()
    if focus_widget and isinstance(focus_widget, TerminalWrapper):
        return focus_widget.get_working_directory()
    else:
        return None
    
import itertools    
    
def merge_list(a):
    return list(itertools.chain.from_iterable(a))

def get_match_children(widget, child_type):
    child_list = widget.get_children()
    if child_list:
        match_widget_list = filter(lambda w: isinstance(w, child_type), child_list)
        match_children = (merge_list(map(
                    lambda w: get_match_children(w, child_type), 
                    filter(
                        lambda w: isinstance(w, gtk.Container), 
                        child_list))))
        return match_widget_list + match_children
    else:
        return []
        
class Terminal(object):
    """
    Main class to run.
    """

    def __init__(self):
        """
        Init docs
        """
        self.application = Application()
        self.application.set_default_size(664, 466)
        self.application.add_titlebar(
            app_name = "Deepin Terminal",
            )

        self.normal_padding = 2
        self.fullscreen_padding = 0
        self.terminal_align = gtk.Alignment()
        self.terminal_align.set(0, 0, 1, 1)
        self.terminal_align.set_padding(0, self.normal_padding, self.normal_padding, self.normal_padding)
        self.terminal_box = gtk.VBox()
        self.workspace_list = []
        self.workspace_switcher = WorkspaceSwitcher(
            self.get_workspaces,
            self.switch_to_workspace
        )
        self.workspace_switcher_y_offset = 10
        
        self.search_bar = SearchBar()
        
        self.helper_window = HelperWindow()
        
        self.remote_login = RemoteLogin()
        
        self.terminal_align.add(self.terminal_box)
        self.application.main_box.pack_start(self.terminal_align)
        
        self.is_full_screen = False
        
        self.generate_keymap()
        
        self.application.window.connect("key-press-event", self.key_press_terminal)
        self.application.window.connect("key-release-event", self.key_release_terminal)
        
        self.new_workspace()
        
        self.general_settings = GeneralSettings()
        self.keybind_settings = KeybindSettings()
        self.advanced_settings = AdvancedSettings()
        
        self.preference_dialog = PreferenceDialog(575, 390)
        self.preference_dialog.set_preference_items(
            [("常规设置", self.general_settings),
             ("热键设置", self.keybind_settings),
             ("高级设置", self.advanced_settings),
             ])
        self.application.titlebar.menu_button.connect("button-press-event", self.show_preference_menu)
        
        global_event.register_event("close-workspace", self.close_workspace)
        global_event.register_event("change-window-title", self.change_window_title)
        global_event.register_event("show-menu", self.show_menu)
        global_event.register_event("xdg-open", lambda command: run_command("xdg-open %s" % command))
        global_event.register_event("change-background-transparent", self.change_background_transparent)
        global_event.register_event("adjust-background-transparent", self.adjust_background_transparent)
        global_event.register_event("scroll-on-key-toggle", self.scroll_on_key_toggle)
        global_event.register_event("scroll-on-output-toggle", self.scroll_on_output_toggle)
        global_event.register_event("set-cursor-shape", self.set_cursor_shape)
        global_event.register_event("change-font", self.change_font)
        global_event.register_event("change-font-size", self.change_font_size)
        global_event.register_event("change-color-precept", self.change_color_precept)
        global_event.register_event("change-font-color", self.change_color_precept)
        global_event.register_event("change-background-color", self.change_color_precept)
        global_event.register_event("keybind-changed", self.keybind_change)
        global_event.register_event("ssh-login", self.ssh_login)
        
    def ssh_login(self, user, server, password, port):
        active_terminal = self.application.window.get_focus()
        if active_terminal and isinstance(active_terminal, TerminalWrapper):
            active_terminal.feed_child(
                "./ssh_login.sh %s %s %s %s\n" % (user, server, password, port))
        
    def keybind_change(self, key_value, new_key):
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.generate_keymap()
            
        self.generate_keymap()    
        self.search_bar.generate_keymap()
        
    def generate_keymap(self):
        get_keybind = lambda key_value: setting_config.config.get("keybind", key_value)
        
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
            ]
        
        self.keymap = {
            "Alt + k": self.focus_up_terminal,
            "Alt + j": self.focus_down_terminal,
            "Alt + h": self.focus_left_terminal,
            "Alt + l": self.focus_right_terminal,
            }
        
        for key_value in key_values:
            self.keymap[get_keybind(key_value)] = getattr(self, key_value)
            
        self.switch_prev_workspace_key = get_keybind("switch_prev_workspace")    
        self.switch_next_workspace_key = get_keybind("switch_next_workspace")    
        
    def show_remote_login_window(self):    
        self.remote_login.show_login(
            self.application.window,
            )
                
    def change_color_precept(self, value):
        font_color = setting_config.config.get("general", "font_color")
        background_color = setting_config.config.get("general", "background_color")
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.change_color(font_color, background_color)
            terminal.background_update()
        
    def change_font(self, font):    
        font_size = setting_config.config.get("general", "font_size")
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.change_font(font, font_size)

    def change_font_size(self, font_size):    
        font = setting_config.config.get("general", "font")
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.change_font(font, font_size)
        
    def set_cursor_shape(self, cursor_shape):
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.change_cursor_shape(cursor_shape)
        
    def scroll_on_key_toggle(self, status):
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.set_scroll_on_keystroke(status)

    def scroll_on_output_toggle(self, status):
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.set_scroll_on_output(status)
        
    def adjust_background_transparent(self, direction):
        if not direction in [gtk.gdk.SCROLL_UP, gtk.gdk.SCROLL_DOWN]:
            return
        
        transparent = setting_config.config.get("general", "background_transparent")
        if direction == gtk.gdk.SCROLL_UP:
            transparent = min(float(transparent) + TRANSPARENT_OFFSET, 1.0)
        elif direction == gtk.gdk.SCROLL_DOWN:
            transparent = max(float(transparent) - TRANSPARENT_OFFSET, 0.0)
            
        setting_config.config.set("general", "background_transparent", transparent)
        setting_config.config.write()
        
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.set_transparent(float(transparent))
            
            # Use background_update to update opacity of terminal.
            terminal.background_update()
        
    def change_background_transparent(self, transparent):
        for terminal in get_match_children(self.application.window, TerminalWrapper):
            terminal.set_transparent(float(transparent))
            
            # Use background_update to update opacity of terminal.
            terminal.background_update()
            
    def show_preference_menu(self, widget, event):
        menu_items = [
            (None, "查看新特性", None),
            (None, "选项设置", self.show_preference_dialog),
            (None, "退出", gtk.main_quit),
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
        
    def show_menu(self, terminal, has_selection, match_text, (x_root, y_root)):
        # Build menu.
        menu_items = []
        if has_selection:
            menu_items.append((None, "拷贝", terminal.copy_clipboard))
            
        menu_items.append((None, "粘贴", terminal.paste_clipboard))    
            
        if match_text:
            menu_items.append((None, "打开地址", lambda : global_event.emit("xdg-open", match_text[0])))
            
        if self.is_full_screen:
            fullscreen_item_text = "退出全屏"
        else:
            fullscreen_item_text = "全屏"
            
        terminal_items = [
            None,
            (None, "垂直分屏", lambda : terminal.parent_widget.split(TerminalGrid.SPLIT_VERTICAL)),
            (None, "水平分屏", lambda : terminal.parent_widget.split(TerminalGrid.SPLIT_HORIZONTAL)),
            (None, "关闭终端", terminal.close_terminal),
            ]
        
        if len(self.get_workspaces()) > 1:
            current_workspace = self.terminal_box.get_children()[0]
            workspace_menu_items = map(
                lambda w: (None, "工作区%s" % w.workspace_index, lambda : self.switch_to_workspace(w)), 
                filter(lambda w: w.workspace_index != current_workspace.workspace_index, self.get_workspaces())
                )
            workspace_menu = Menu(workspace_menu_items)
            
            workspace_items = [
                None,
                (None, "新建工作区", self.new_workspace),
                (None, "切换工作区", workspace_menu),
                (None, "关闭工作区%s" % current_workspace.workspace_index, self.close_current_workspace),
                ]
        else:
            workspace_items = [
                None,
                (None, "新建工作区", self.new_workspace),
                ]
            
        menu_items += terminal_items + workspace_items + [
            None,
            (None, fullscreen_item_text, self.toggle_full_screen),
            (None, "搜索", self.search_forward),
            (None, "显示快捷键", None),
            None,
            (None, "配置选项", self.show_preference_dialog),
            ]
        
        menu = Menu(menu_items, True)
        
        # Show menu.
        menu.show((x_root, y_root))
        
    def get_all_terminal_infos(self):
        focus_terminal = self.application.window.get_focus()
        terminals = get_match_children(self.application.window, TerminalWrapper)
        terminals.remove(focus_terminal)
        return (focus_terminal, terminals)
        
    def focus_vertical_terminal(self, up=True):
        # Get all terminal infomation.
        (focus_terminal, terminals) = self.get_all_terminal_infos()
        rect = focus_terminal.allocation
        x, y, w, h = rect.x, rect.y, rect.width, rect.height
        
        # Find terminal intersectant with focus one.
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
                print "Same coordinate"
                same_coordinate_terminals[0].grab_focus()
            else:
                # Focus terminal if it's heigh than focus one.
                bigger_match_terminals = filter(
                    lambda t: 
                    (t.allocation.x < x and 
                     t.allocation.x + t.allocation.width >= x + w),
                    intersectant_terminals)
                if len(bigger_match_terminals) > 0:
                    print "Bigger"
                    bigger_match_terminals[0].grab_focus()
                else:
                    # Focus bigest intersectant area one.
                    intersectant_area_infos = map(
                        lambda t:
                            (t, 
                             (t.allocation.width + w - abs(t.allocation.x - x) - abs(t.allocation.x + t.allocation.width - x - w) / 2)),
                        intersectant_terminals)
                    bigest_intersectant_terminal = sorted(intersectant_area_infos, key=lambda (_, area): area, reverse=True)[0][0]
                    print "Bigest"
                    bigest_intersectant_terminal.grab_focus()
    
    def focus_horizontal_terminal(self, left=True):                
        # Get all terminal infomation.
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
                print "Same coordinate"
                same_coordinate_terminals[0].grab_focus()
            else:
                # Focus terminal if it's heigh than focus one.
                bigger_match_terminals = filter(
                    lambda t: 
                    (t.allocation.y < y and 
                     t.allocation.y + t.allocation.height >= y + h),
                    intersectant_terminals)
                if len(bigger_match_terminals) > 0:
                    print "Bigger"
                    bigger_match_terminals[0].grab_focus()
                else:
                    # Focus bigest intersectant area one.
                    intersectant_area_infos = map(
                        lambda t:
                            (t, 
                             (t.allocation.height + h - abs(t.allocation.y - y) - abs(t.allocation.y + t.allocation.height - y - h) / 2)),
                        intersectant_terminals)
                    bigest_intersectant_terminal = sorted(intersectant_area_infos, key=lambda (_, area): area, reverse=True)[0][0]
                    print "Bigest"
                    bigest_intersectant_terminal.grab_focus()
                    
    def focus_up_terminal(self):
        self.focus_vertical_terminal(True)
        
    def focus_down_terminal(self):
        self.focus_vertical_terminal(False)
    
    def focus_left_terminal(self):
        self.focus_horizontal_terminal(True)

    def focus_right_terminal(self):
        self.focus_horizontal_terminal(False)
        
    def get_workspaces(self):
        children = self.terminal_box.get_children()
        if len(children) == 1:
            child = children[0]
            if child and isinstance(child, Workspace):
                child.save_workspace_snapshot()
        
        return self.workspace_list
    
    def switch_to_workspace(self, workspace):
        current_workspace = self.terminal_box.get_children()[0]
        if workspace != current_workspace:
            self.remove_current_workspace()
            self.terminal_box.add(workspace)
            self.terminal_box.show_all()
        
    def remove_current_workspace(self, save_snapshot=True):
        children = self.terminal_box.get_children()
        if len(children) == 1:
            child = children[0]
            if child and isinstance(child, Workspace):
                child.save_workspace_snapshot()
                self.terminal_box.remove(child)
        
    def new_workspace(self):
        working_directory = get_active_working_directory(self.application.window)
        
        workspace = Workspace()
        terminal_grid = TerminalGrid(working_directory=working_directory)
        workspace.add(terminal_grid)
        
        self.remove_current_workspace()
        self.terminal_box.add(workspace)
        self.terminal_box.show_all()
        
        self.workspace_list.append(workspace)
        
    def close_workspace(self, workspace):    
        workspace_index = self.workspace_list.index(workspace)            
        
        # Remove workspace from list.
        if workspace in self.workspace_list:
            self.workspace_list.remove(workspace)
            
        # Show previous workspace.
        if len(self.workspace_list) > 0:
            self.remove_current_workspace(False)
            self.terminal_box.add(self.workspace_list[workspace_index - 1])
            self.terminal_box.show_all()
        # Exit if no workspace exit.
        else:
            print "Quit"
            gtk.main_quit()
            
    def change_window_title(self, window_title):
        self.application.titlebar.change_title(window_title)
        
    def close_current_workspace(self):
        children = self.terminal_box.get_children()
        if len(children) > 0:
            self.close_workspace(children[0])
        else:
            print "IMPOSSIBLE: no workspace in terminal_box"
            
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
    
    def switch_next_workspace(self):
        if self.workspace_switcher.get_visible():
            self.workspace_switcher.switch_next()
        else:
            self.workspace_switcher.show_switcher(
                self.get_current_workspace_index(),
                self.get_workspace_switcher_coordinate()
                )
    
    def switch_prev_workspace(self):
        if self.workspace_switcher.get_visible():
            self.workspace_switcher.switch_prev()
        else:
            self.workspace_switcher.show_switcher(
                self.get_current_workspace_index(),
                self.get_workspace_switcher_coordinate()
                )
            
    def search_forward(self):
        (x, y, w, h) = self.terminal_box.allocation
        (root_x, root_y) = self.terminal_box.window.get_origin()
        self.search_bar.show_bar(
            (root_x + x + w, root_y + y),
            self.application.window.get_focus(),
            )
        
    def key_press_terminal(self, widget, event):
        """
        Key event callback
        :param widget: which sends the event.
        :param event: what event.
        """
        key_name = get_keyevent_name(event)
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
                self.switch_to_workspace(self.workspace_list[self.workspace_switcher.workspace_index])
                self.workspace_switcher.hide_switcher()
                
    def toggle_full_screen(self):
        """
        Switch between full_screen and normal window.
        """
        if self.is_full_screen:
            self.application.window.unfullscreen()
            self.application.show_titlebar()
            self.terminal_align.set_padding(0, self.normal_padding, self.normal_padding, self.normal_padding)
        else:
            self.application.window.fullscreen()
            self.application.hide_titlebar()
            self.terminal_align.set_padding(
                0,
                self.fullscreen_padding,
                self.fullscreen_padding,
                self.fullscreen_padding
            )

        self.is_full_screen = not self.is_full_screen

    def exit_fullscreen(self):
        if self.is_full_screen:
            self.toggle_full_screen()
        
    def run(self):
        """
        Main function.
        """
        startup_mode = setting_config.config.get("advanced", "startup_mode", "normal")
        if startup_mode == "maximize":
            self.application.window.maximize()
        elif startup_mode == "fullscreen":
            self.toggle_full_screen()
            
        self.application.run()

class TerminalWrapper(vte.Terminal):
    """
    Wrapper class for vte.Terminal. Propagate keys. Make some customize as well.
    """

    def __init__(self, 
                 parent_widget, 
                 working_directory=None,
                 ):
        """
        Inital values.
        :param parent_widget: which grid this widget belongs to.
        """
        # TODO: Transmit a config object, so we could set attributs of vte.
        # vte init
        vte.Terminal.__init__(self)
        self.parent_widget = parent_widget
        self.set_word_chars("-A-Za-z0-9,./?%&#:_")
        
        self.change_color(
            setting_config.config.get("general", "font_color"),
            setting_config.config.get("general", "background_color")
            )
        
        transparent = setting_config.config.get("general", "background_transparent")
        self.set_transparent(float(transparent))
        
        scroll_on_key = setting_config.config.get("advanced", "scroll_on_key")
        self.set_scroll_on_keystroke(scroll_on_key == "True")
        
        scroll_on_output = setting_config.config.get("advanced", "scroll_on_output")
        self.set_scroll_on_output(scroll_on_output == "True")
        
        cursor_shape = setting_config.config.get("advanced", "cursor_shape")
        self.change_cursor_shape(cursor_shape)
        
        self.default_font = setting_config.config.get("general", "font")
        self.default_font_size = int(setting_config.config.get("general", "font_size"))
        self.current_font_size = self.default_font_size
        self.change_font(self.default_font, self.current_font_size)
        
        startup_directory = setting_config.config.get("advanced", "startup_directory")
        if startup_directory != "":
            os.chdir(startup_directory)
        elif working_directory:
            # Use os.chdir and not child_feed("cd %s\n" % working_directory), 
            # this will make terminal with 'clear' init value.
            # child_feed have cd information after terminal created.
            os.chdir(working_directory)
            
        startup_command = setting_config.config.get("advanced", "startup_command")    
        self.process_id = self.fork_command(startup_command)
        self.cwd_path = '/proc/%s/cwd' % self.process_id

        # Key and signals
        self.generate_keymap()
        
        self.connect("realize", self.realize_callback)
        self.connect("child-exited", lambda w: self.exit_callback())
        self.connect("key-press-event", self.handle_keys)
        
        self.drag_dest_set(
            gtk.DEST_DEFAULT_MOTION |
            gtk.DEST_DEFAULT_DROP,
            [("text/uri-list", 0, DRAG_TEXT_URI),
             ("text/plain", 0, DRAG_TEXT_PLAIN),
             ],
            gtk.gdk.ACTION_COPY)
        
        userchars = "-A-Za-z0-9"
        passchars = "-A-Za-z0-9,?;.:/!%$^*&~\"#'"
        hostchars = "-A-Za-z0-9"
        pathchars = "-A-Za-z0-9_$.+!*(),;:@&=?/~#%'\""
        schemes   = "(news:|telnet:|nntp:|file:/|https?:|ftps?:|webcal:)"
        user      = "[" + userchars + "]+(:[" + passchars + "]+)?"
        urlpath   = "/[" + pathchars + "]*[^]'.}>) \t\r\n,\\\"]"
        lboundry = "\\<"
        rboundry = "\\>"
        self.match_tag = self.match_add(
            lboundry + schemes + 
            "//(" + user + "@)?[" + hostchars  +".]+(:[0-9]+)?(" + 
            urlpath + ")?" + rboundry + "/?")
        self.match_set_cursor_type(self.match_tag, gtk.gdk.HAND2)
        
        self.press_ctrl = False

        self.connect("drag-data-received", self.on_drag_data_received)
        self.connect("window-title-changed", self.on_window_title_changed)
        self.connect("grab-focus", lambda w: self.change_window_title())
        self.connect("button-press-event", self.on_button_press)
        self.connect("key-press-event", self.on_key_press)
        self.connect("key-release-event", self.on_key_release)
        self.connect("scroll-event", self.on_scroll)
        
    def generate_keymap(self):
        get_keybind = lambda key_value: setting_config.config.get("keybind", key_value)
        
        key_values = [
            "split_vertical",
            "split_horizontal",
            "copy_clipboard",
            "paste_clipboard",
            "revert_default_size",
            "zoom_in",
            "zoom_out",
            "close_terminal",
            ]
        
        self.keymap = {}
        
        for key_value in key_values:
            self.keymap[get_keybind(key_value)] = getattr(self, key_value)
            
    def split_vertical(self):
        self.parent_widget.split(TerminalGrid.SPLIT_VERTICAL),
        
    def split_horizontal(self):
        self.parent_widget.split(TerminalGrid.SPLIT_HORIZONTAL),
            
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
        
    def on_scroll(self, widget, event):
        if self.press_ctrl:
            global_event.emit("adjust-background-transparent", event.direction)
        
    def set_transparent(self, transparent):
        self.set_opacity(int(transparent * 65535))
        
    def close_terminal(self):
        self.exit_callback()
        
    def get_match_text(self, event):
        return self.match_check(
            int(event.x / self.get_char_width()),
            int(event.y / self.get_char_height()))
        
    def on_key_press(self, widget, event):
        if has_ctrl_mask(event):
            self.press_ctrl = True
            
    def on_key_release(self, widget, event):
        self.press_ctrl = False
            
    def on_button_press(self, widget, event):
        if is_left_button(event) and self.press_ctrl:
            (column, row) = self.get_cursor_position()
            match_string = self.get_match_text(event)
            if match_string:
                global_event.emit("xdg-open", match_string[0])
        elif is_right_button(event):
            global_event.emit(
                "show-menu", 
                self, 
                self.get_has_selection(),
                self.get_match_text(event),
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
        self.current_font_size = self.default_font_size
        self.change_font(self.default_font, self.current_font_size)
    
    def zoom_in(self):
        self.current_font_size = max(1, self.current_font_size - 1)
        self.change_font(self.default_font, self.current_font_size)
    
    def zoom_out(self):
        self.current_font_size += 1
        self.change_font(self.default_font, self.current_font_size)
        
    def get_working_directory(self):
        return os.readlink(self.cwd_path)
        
    def change_window_title(self):
        global_event.emit("change-window-title", self.get_working_directory())
        
    def on_window_title_changed(self, widget):
        if self.has_focus():
            self.change_window_title()
        
    def on_drag_data_received(self, widget, drag_context, x, y, selection, target_type, timestamp):
        if target_type == DRAG_TEXT_URI:
            paste_text = urllib.unquote(selection.get_uris()[0].split("file://")[1])            
        elif target_type == DRAG_TEXT_PLAIN:
            paste_text = selection.data
            
        self.feed_child(paste_text)    

    def exit_callback(self):
        """
        Call parent_widget.child_exit_callback
        :param widget: self
        """
        self.parent_widget.child_exit_callback(self.parent_widget)

    def realize_callback(self, widget):
        """
        Callback for realize-signal.
        :param widget: which widget sends the signal.
        """
        widget.grab_focus()

    def handle_keys(self, widget, event):
        """
        Handle keys as c-v and c-h
        :param widget: which widget sends the key_event.
        :param event: what event is sent.
        """
        key_name = get_keyevent_name(event)
        if key_name in self.keymap:
            self.keymap[key_name]()
            # True to stop event from propagating.
            return True
        else:
            return False

gobject.type_register(TerminalWrapper)


class TerminalGrid(gtk.VBox):
    """
    Container for terminals. Handle vsplit and hsplit keystrokes.
    """

    # Constant values
    SPLIT_VERTICAL = 1
    SPLIT_HORIZONTAL = 2

    def __init__(self, 
                 parent_widget=None, 
                 terminal=None,
                 working_directory=None,
                 ):
        """
        Initial values
        :param parent_widget: which TerminalGrid this widget belongs to.
        """
        # TODO: Transmit a config object.
        gtk.VBox.__init__(self)

        # Keep a reference to parent
        self.parent_widget = parent_widget
        if terminal:
            self.terminal = terminal
            self.terminal.parent_widget = self
        else:
            self.terminal = TerminalWrapper(self, working_directory=working_directory)

        self.is_parent = False
        self.paned = None
        self.add(self.terminal)

    def split(self, split_policy):
        """
        Split window.
        :param split_policy: used to determine vsplit or hsplit.
        """
        if split_policy not in [TerminalGrid.SPLIT_VERTICAL, TerminalGrid.SPLIT_HORIZONTAL]:
            raise (ValueError, "Unknown split policy!!")
        
        working_directory = get_active_working_directory(self.get_toplevel())    
            
        self.is_parent = True
        self.remove(self.terminal)
        width, height = self.get_child_requisition()
        if split_policy == TerminalGrid.SPLIT_VERTICAL:
            self.paned = gtk.VPaned()
            self.paned.set_position(height/2)
        elif split_policy == TerminalGrid.SPLIT_HORIZONTAL:
            self.paned = gtk.HPaned()
            self.paned.set_position(width/2)
            
        self.paned.pack1(TerminalGrid(self, self.terminal), True, True)
        self.paned.pack2(TerminalGrid(self, working_directory=working_directory), True, True)

        self.add(self.paned)
        self.show_all()

    def child_exit_callback(self, widget):
        """
        Recusively close the widget or remove paned.
        :param widget: which widget is exited.
        """
        # TODO: Add a remove_child method to delete reference and return deleted child.
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
                self.remove(self.terminal)
                self.terminal = None
                self.parent_widget.child_exit_callback(self)
            else:
                workspace = get_match_parent(self, "Workspace")
                if workspace:
                    global_event.emit("close-workspace", workspace)

gobject.type_register(TerminalGrid)


class Workspace(gtk.VBox):
    """
    class docs
    """

    def __init__(self):
        """
        init docs
        """
        global workspace_index
        gtk.VBox.__init__(self)
        
        self.workspace_index = workspace_index
        workspace_index += 1
        self.snapshot_pixbuf = None
        
    def save_workspace_snapshot(self):
        if self.window and self.window.get_colormap():
            rect = self.allocation
            x, y, width, height = rect.x, rect.y, rect.width, rect.height
            self.snapshot_pixbuf = gtk.gdk.Pixbuf(gtk.gdk.COLORSPACE_RGB, False, 8, width, height)
            self.snapshot_pixbuf.get_from_drawable(
                self.window,
                self.window.get_colormap(),
                x, y, 0, 0,
                width,
                height,
                )
            snapshot_height = WORKSPACE_SNAPSHOT_HEIGHT - WORKSPACE_SNAPSHOT_OFFSET_TOP - WORKSPACE_SNAPSHOT_OFFSET_BOTTOM
            snapshot_width = int(width * snapshot_height / height)
            self.snapshot_pixbuf = self.snapshot_pixbuf.scale_simple(
                snapshot_width,
                snapshot_height,
                gtk.gdk.INTERP_BILINEAR,
                )
            
            gc.collect()
        
gobject.type_register(Workspace)


class WorkspaceSwitcher(gtk.Window):
    """
    class docs
    """

    def __init__(self, get_workspaces, switch_to_workspace):
        """
        init docs
        """
        gtk.Window.__init__(self, gtk.WINDOW_POPUP)
        self.get_workspaces = get_workspaces
        self.switch_to_workspace = switch_to_workspace
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_skip_taskbar_hint(True)
        self.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_DIALOG)  # keep above
        
        self.width = 0
        self.height = 0
        
        self.workspace_index = 0
        
        self.connect("expose-event", self.expose_workspace_switcher)
        
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
        
        with cairo_state(cr):
            # Draw background.
            cr.set_source_rgba(1.0, 0.5, 1.0, 0.5)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
        
        # Draw workspace snapshot.
        text_size = 32
        text_offset_y = 0
            
        snapshot_total_width = sum(map(lambda w: w.snapshot_pixbuf.get_width() + WORKSPACE_SNAPSHOT_OFFSET_X * 2, self.get_workspaces()))
        if snapshot_total_width < rect.width:
            scale_value = 1.0
            draw_x = (rect.width - snapshot_total_width) / 2
        else:
            scale_value = float(rect.width) / snapshot_total_width
            draw_x = WORKSPACE_SNAPSHOT_OFFSET_X
            
        cr.scale(scale_value, scale_value)
        for (workspace_index, workspace) in enumerate(self.get_workspaces()): 
            
            snapshot_width = workspace.snapshot_pixbuf.get_width()
            snapshot_height = workspace.snapshot_pixbuf.get_height()
            
            draw_y = rect.y + WORKSPACE_SNAPSHOT_OFFSET_TOP
            
            # Draw workspace select background.
            if self.workspace_index == workspace_index:
                cr.set_source_rgba(1, 0.5, 1, 0.8)
                cr.rectangle(
                    draw_x - WORKSPACE_SNAPSHOT_OFFSET_X, 
                    rect.y,
                    snapshot_width + WORKSPACE_SNAPSHOT_OFFSET_X * 2, 
                    rect.height)
                cr.fill()
            
            # Draw workspace snapshot.
            draw_pixbuf(
                cr,
                workspace.snapshot_pixbuf,
                draw_x,
                draw_y,
            )
            
            # Draw workspace name.
            draw_text(
                cr,
                "工作区 %s" % workspace.workspace_index,
                draw_x,
                draw_y + snapshot_height + text_offset_y,
                snapshot_width,
                text_size,
                text_color="#FFFFFF",
                alignment=pango.ALIGN_CENTER,
                )
            
            draw_x += snapshot_width + WORKSPACE_SNAPSHOT_OFFSET_X * 2
        
        return True
        
gobject.type_register(WorkspaceSwitcher)

class SearchBar(gtk.Window):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        gtk.Window.__init__(self, gtk.WINDOW_POPUP)
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_modal(True)
        
        self.entry = Entry()
        self.entry.entry_buffer.always_show_cursor = True
        self.entry_align = gtk.Alignment()
        self.entry_align.set(0.5, 0.5, 1, 1)
        self.entry_align.set_padding(2, 2, 10, 10)
        self.entry_align.add(self.entry)
        self.add(self.entry_align)
        
        self.search_regex = ""
        
        self.width = 300
        self.height = 26
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
        get_keybind = lambda key_value: setting_config.config.get("keybind", key_value)
        
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
        
        with cairo_state(cr):
            # Draw background.
            cr.set_source_rgba(1.0, 1.0, 1.0, 0.8)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
            
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

            cr.move_to(x, y)
            cr.line_to(x + w, y)
            cr.arc(x + w - self.radius, y + h - self.radius, self.radius, 0, pi / 2)
            cr.line_to(x + self.radius, y + h)
            cr.arc(x + self.radius, y + h - self.radius, self.radius, pi / 2, pi)
            cr.line_to(x, y)
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

class HelperWindow(Window):
    '''
    class docs
    '''
	
    def __init__(self):
        '''
        init docs
        '''
        Window.__init__(self, 
                        window_type=gtk.WINDOW_POPUP,
                        expose_background_function=self.expose_helper_window,
                        )
        self.set_decorated(False)
        self.add_events(gtk.gdk.ALL_EVENTS_MASK)
        self.set_colormap(gtk.gdk.Screen().get_rgba_colormap())
        self.set_modal(True)
        
        self.width = 480
        self.height = 400
        
        self.set_geometry_hints(
            None,
            self.width, self.height,
            self.width, self.height,
            -1, -1, -1, -1, -1, -1
            )
        
        self.keymap = {
            "Escape": self.hide_all
            }
        
        self.titlebar = Titlebar(button_mask=["close"])
        self.titlebar.close_button.connect("clicked", lambda w: self.hide_all())
        
        self.table_box = gtk.HBox()
        
        self.box = gtk.VBox()
        
        self.content_box = gtk.VBox()
        self.content_box_align = gtk.Alignment()
        self.content_box_align.set(0.5, 0.5, 1, 1)
        self.content_box_align.set_padding(10, 10, 40, 10)
        self.content_box_align.add(self.content_box)
        self.content_box.pack_start(self.table_box, True, True)
        
        self.box.pack_start(self.titlebar, False, False)
        self.box.pack_start(self.content_box_align, True, True)
        
        self.window_frame.add(self.box)
        
        self.connect("key-press-event", self.key_press_helper_window)
        
    def create_table(self, infos):
        table = gtk.Table(9, 2)
        for (index, (name, key)) in enumerate(infos):
            table.attach(
                Label(name),
                0, 1,
                index, index + 1,
                xoptions=gtk.FILL,
                )
            table.attach(
                Label(key),
                1, 2,
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
        
    def show_help(self, parent_window, working_directory):
        if working_directory != None:
            self.titlebar.change_name(working_directory)
            
        container_remove_all(self.table_box)    
        
        get_keybind = lambda key_value: setting_config.config.get("keybind", key_value)
        
        first_table_key = [
            ("拷贝", "copy_clipboard"),
            ("粘贴", "paste_clipboard"),
            ("垂直分屏", "split_vertical"),
            ("水平分屏", "split_horizontal"),
            ("关闭终端", "close_terminal"),
            ("选择上面的终端", "focus_up_terminal"),
            ("选择下面的终端", "focus_down_terminal"),
            ("选择左面的终端", "focus_left_terminal"),
            ("选择右面的终端", "focus_right_terminal"),
            ]
        
        no_customize_key = [          
            ("选词", "左键双击"),
            ("打开地址", "Ctrl + 左键"),
            ]
        
        self.first_table = self.create_table(
            map(lambda (key_name, key_value): (key_name, get_keybind(key_value)), first_table_key) + no_customize_key,
            )
        
        second_table_key = [
            ("放大字体", "zoom_in"),
            ("缩小字体", "zoom_out"),
            ("默认大小", "revert_default_size"),
            ("新建工作区", "new_workspace"),
            ("关闭工作区", "close_current_workspace"),
            ("上一个工作区", "switch_prev_workspace"),
            ("下一个工作区", "switch_next_workspace"),
            ("先前搜索", "search_forward"),
            ("先后搜索", "search_backward"),
            ("全屏", "toggle_full_screen"),
            ("显示快捷键", "show_helper_window"),
            ("建立远程连接", "show_remote_login_window"),
            ]
        
        self.second_table = self.create_table(
            map(lambda (key_name, key_value): (key_name, get_keybind(key_value)), second_table_key)
            )
        self.table_box.pack_start(self.first_table, True, True)
        self.table_box.pack_start(self.second_table, True, True)
            
        self.show_all()
        place_center(parent_window, self)
        
    def expose_helper_window(self, widget, event):
        cr = widget.window.cairo_create()
        rect = widget.allocation
        
        with cairo_state(cr):
            cr.set_source_rgba(1.0, 1.0, 1.0, 0)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.paint()
            
        x = rect.x + self.shadow_padding
        y = rect.y + self.shadow_padding
        w = rect.width - self.shadow_padding * 2
        h = rect.height - self.shadow_padding * 2
        with cairo_state(cr):
            cr.rectangle(x + 2, y, w - 4, 1)
            cr.rectangle(x + 1, y + 1, w - 2, 1)
            cr.rectangle(x, y + 2, w, h - 4)
            cr.rectangle(x + 2, y + h - 1, w - 4, 1)
            cr.rectangle(x + 1, y + h - 2, w - 2, 1)
                    
            cr.clip()
            
            cr.rectangle(x, y, w, h)
            cr.set_source_rgba(1.0, 1.0, 1.0, 0.8)
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
        
        font = setting_config.config.get("general", "font")
        font_families = get_font_families()
        font_items = map(lambda i: (i, i), font_families)
        font_widget = ComboBox(font_items, droplist_height=200, fixed_width=COMBO_BOX_WIDTH)
        font_widget.set_select_index(font_families.index(font))
        font_widget.connect("item-selected", self.change_font)
        
        font_size = setting_config.config.get("general", "font_size")
        font_size_widget = SpinBox(lower=1, step=1)
        font_size_widget.set_value(int(font_size))
        font_size_widget.connect("value-changed", self.change_font_size)
        
        color_precept = setting_config.config.get("general", "color_precept")
        self.color_items =map(lambda (color_precept_value, (color_precept_name, _)): (color_precept_name, color_precept_value), color_style.items())
        self.color_precept_widget = ComboBox(self.color_items, fixed_width=COMBO_BOX_WIDTH)
        self.color_precept_widget.set_select_index(
            map(lambda (color_precept_value, color_infos): color_precept_value, color_style.items()).index(color_precept))
        self.color_precept_widget.connect("item-selected", self.change_color_precept)
        
        font_color = setting_config.config.get("general", "font_color")
        self.font_color_widget = ColorButton(color=font_color)
        self.font_color_widget.connect("color-select", self.change_font_color)
        
        background_color = setting_config.config.get("general", "background_color")
        self.background_color_widget = ColorButton(background_color)
        self.background_color_widget.connect("color-select", self.change_background_color)
        
        color_box = gtk.HBox()
        color_box_split = gtk.HBox()
        color_box_split.set_size_request(10, -1)
        color_box.pack_start(self.font_color_widget, False, False)
        color_box.pack_start(color_box_split, False, False)
        color_box.pack_start(self.background_color_widget, False, False)
        
        transparent = setting_config.config.get("general", "background_transparent")
        background_transparent_widget = HScalebar(value_min=0, value_max=1)
        background_transparent_widget.set_value(float(transparent))
        background_transparent_widget.connect("value-changed", self.save_background_transparent)
        
        self.table = gtk.Table(7, 2)
        self.table.set_row_spacings(TABLE_ROW_SPACING)
        self.table.set_col_spacing(0, TABLE_COLUMN_SPACING)
        table_items = [
            ("字体: ", font_widget),
            ("字体大小: ", font_size_widget),
            ("颜色方案: ", self.color_precept_widget),
            ("", color_box),
            ("背景透明: ", background_transparent_widget),
            ]
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 1, 1)
        self.table_align.set_padding(TABLE_PADDING_TOP, TABLE_PADDING_BOTTOM, TABLE_PADDING_LEFT, 0)
        
        self.fill_table(self.table, table_items)
        self.table_align.add(self.table)
        self.add(self.table_align)
        
    def change_color_precept(self, combo_box, option_name, option_value, index):
        setting_config.config.set("general", "color_precept", option_value)
        setting_config.config.write()
        
        if option_value != "customize" and color_style.has_key(option_value):
            (_, [font_color, background_color]) = color_style[option_value]
            
            self.font_color_widget.set_color(font_color)
            self.background_color_widget.set_color(background_color)
            
            setting_config.config.set("general", "font_color", font_color)
            setting_config.config.set("general", "background_color", background_color)
            setting_config.config.write()
            
            global_event.emit("change-color-precept", option_value)
    
    def change_font_color(self, color_button, font_color):
        self.color_precept_widget.set_select_index(
            map(lambda (color_precept_value, color_infos): color_precept_value, color_style.items()).index("customize"))
        
        setting_config.config.set("general", "color_precept", "customize")
        setting_config.config.set("general", "font_color", font_color)
        setting_config.config.write()
        
        global_event.emit("change-font-color", font_color)
    
    def change_background_color(self, color_button, background_color):
        self.color_precept_widget.set_select_index(
            map(lambda (color_precept_value, color_infos): color_precept_value, color_style.items()).index("customize"))
        
        setting_config.config.set("general", "color_precept", "customize")
        setting_config.config.set("general", "background_color", background_color)
        setting_config.config.write()
        
        global_event.emit("change-background-color", background_color)
        
    def change_font(self, combo_box, option_name, option_value, index):
        setting_config.config.set("general", "font", option_value)
        setting_config.config.write()
        
        global_event.emit("change-font", option_value)
    
    def change_font_size(self, spin, font_size):
        setting_config.config.set("general", "font_size", font_size)
        setting_config.config.write()
        
        global_event.emit("change-font-size", font_size)
        
    def save_background_transparent(self, scalebar, value):
        setting_config.config.set("general", "background_transparent", value)
        setting_config.config.write()
        
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
        
        key_name_dict = OrderedDict(
            [("copy_clipboard", "拷贝"),
             ("paste_clipboard", "粘贴"),
             ("split_vertical", "垂直分屏"),
             ("split_horizontal", "水平分屏"),
             ("close_terminal", "关闭终端"),
             ("focus_up_terminal", "选择上面的终端"),
             ("focus_down_terminal", "选择下面的终端"),
             ("focus_left_terminal", "选择左面的终端"),
             ("focus_right_terminal", "选择右面的终端"),
             ("zoom_in", "放大字体"),
             ("zoom_out", "缩小字体"),
             ("revert_default_size", "默认大小"),
             ("new_workspace", "新建工作区"),
             ("close_current_workspace", "关闭工作区"),
             ("switch_prev_workspace", "上一个工作区"),
             ("switch_next_workspace", "下一个工作区"),
             ("search_forward", "先前搜索"),
             ("search_backward", "先后搜索"),
             ("toggle_full_screen", "全屏"),
             ("show_helper_window", "显示快捷键"),
             ])
        
        self.table = gtk.Table(len(key_name_dict), 2)
        self.table.set_row_spacings(TABLE_ROW_SPACING)
        self.table.set_col_spacing(0, TABLE_COLUMN_SPACING)
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 1, 1)
        self.table_align.set_padding(TABLE_PADDING_TOP, TABLE_PADDING_BOTTOM, TABLE_PADDING_LEFT, 0)
        
        self.fill_table(self.table, key_name_dict)
        self.table_align.add(self.table)
        self.box.add(self.table_align)
        self.add_with_viewport(self.box)
        
        self.connect("hierarchy-changed", lambda w, t: self.get_vadjustment().set_value(0))
        
    def fill_table(self, table, key_name_dict):
        for (index, (key_value, key_name)) in enumerate(key_name_dict.items()):
            key_bind = setting_config.config.get("keybind", key_value)
            table.attach(
                Label(key_name, text_x_align=ALIGN_END),
                0, 1, 
                index, index + 1,
                )
            shortcutkey_entry = KeybindEntry(key_value, key_bind)
            shortcutkey_entry.set_size(170, 23)
            shortcutkey_entry_align = gtk.Alignment()
            shortcutkey_entry_align.set_padding(0, 0, 0, 122)
            shortcutkey_entry_align.add(shortcutkey_entry)
            table.attach(
                shortcutkey_entry_align,
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
        setting_config.config.set("keybind", self.key_value, new_keybind)
        setting_config.config.write()
        
        global_event.emit("keybind-changed", self.key_value, new_keybind)
        
        print self.key_value, new_keybind
        
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

        startup_mode = setting_config.config.get("advanced", "startup_mode")
        startup_mode_items = [("正常", "normal"),
                              ("最大化", "maximize"),
                              ("全屏", "fullscreen")]
        startup_widget = ComboBox(startup_mode_items, fixed_width=COMBO_BOX_WIDTH)
        startup_widget.connect("item-selected", self.save_startup_setting)
        startup_widget.set_select_index(unzip(startup_mode_items)[-1].index(startup_mode))
        
        startup_command = setting_config.config.get("advanced", "startup_command")
        startup_command_widget = InputEntry(startup_command)
        startup_command_widget.set_size(100, 23)
        startup_command_widget.entry.connect("changed", self.startup_command_changed)
        
        startup_directory = setting_config.config.get("advanced", "startup_directory")
        startup_directory_widget = InputEntry(startup_directory)
        startup_directory_widget.set_size(100, 23)
        startup_directory_widget.entry.connect("changed", self.startup_directory_changed)
        
        cursor_shape = setting_config.config.get("advanced", "cursor_shape")
        cursor_shape_items =[("块状", "block"),
                             ("竖条", "ibeam"),
                             ("下划线", "underline")]
        cursor_shape_widget = ComboBox(cursor_shape_items, fixed_width=COMBO_BOX_WIDTH)
        cursor_shape_widget.connect("item-selected", self.save_cursor_shape)
        cursor_shape_widget.set_select_index(unzip(cursor_shape_items)[-1].index(cursor_shape))
        
        scroll_on_key = setting_config.config.get("advanced", "scroll_on_key")
        scroll_on_key_widget = SwitchButton(scroll_on_key == "True")
        scroll_on_key_widget.connect("toggled", self.scroll_on_key_toggle)
        
        scroll_on_output = setting_config.config.get("advanced", "scroll_on_output")
        scroll_on_output_widget = SwitchButton(scroll_on_output == "True")
        scroll_on_output_widget.connect("toggled", self.scroll_on_output_toggle)
        
        self.table = gtk.Table(7, 2)
        self.table.set_row_spacings(TABLE_ROW_SPACING)
        self.table.set_col_spacing(0, TABLE_COLUMN_SPACING)
        table_items = [
            ("启动方式: ", startup_widget),
            ("启动命令: ", startup_command_widget),
            ("启动目录: ", startup_directory_widget),
            ("光标形状: ", cursor_shape_widget),
            ("按键时滚动: ", scroll_on_key_widget),
            ("输出时滚动: ", scroll_on_output_widget),
            ]
        self.table_align = gtk.Alignment()
        self.table_align.set(0, 0, 1, 1)
        self.table_align.set_padding(TABLE_PADDING_TOP, TABLE_PADDING_BOTTOM, TABLE_PADDING_LEFT, 0)
        
        self.fill_table(self.table, table_items)
        self.table_align.add(self.table)
        self.add(self.table_align)
        
    def save_startup_setting(self, combo_box, option_name, option_value, index):
        setting_config.config.set("advanced", "startup_mode", option_value)
        setting_config.config.write()
                
    def save_cursor_shape(self, combo_box, option_name, option_value, index):
        setting_config.config.set("advanced", "cursor_shape", option_value)
        setting_config.config.write()
        
        global_event.emit("set-cursor-shape", option_value)
        
    def startup_command_changed(self, entry, startup_command):
        setting_config.config.set("advanced", "startup_command", startup_command)
        setting_config.config.write()

    def startup_directory_changed(self, entry, startup_directory):
        setting_config.config.set("advanced", "startup_directory", startup_directory)
        setting_config.config.write()
        
    def scroll_on_key_toggle(self, toggle_button):
        setting_config.config.set("advanced", "scroll_on_key", toggle_button.get_active())
        setting_config.config.write()
        
        global_event.emit("scroll-on-key-toggle", toggle_button.get_active())

    def scroll_on_output_toggle(self, toggle_button):
        setting_config.config.set("advanced", "scroll_on_output", toggle_button.get_active())
        setting_config.config.write()
        
        global_event.emit("scroll-on-output-toggle", toggle_button.get_active())
        
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
        
        self.save_button = Button("保存")
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
            self.port_box.get_value(),
            )
        
        self.hide_all()
        
    def show_login(self, parent_window):
        container_remove_all(self.table_align)
        self.create_table()
        self.table_align.add(self.table)
        
        self.show_all()
        place_center(parent_window, self)
        
        self.name_entry.entry.grab_focus()
        
        self.unset_focus_chain()
        self.set_focus_chain(
            [self.name_entry.entry, self.user_entry.entry, self.server_entry.entry, self.password_entry.entry, self.save_button])
        
    def create_table(self):
        self.table = gtk.Table(4, 2)
        self.table.set_col_spacing(0, 10)
        names = ["Name: ", "User: ", "Server: ", "Password: ", "Port: "]
        
        if self.remote_info:
            (name, user, server, password, port) = self.remote_info
        else:
            name, user, server, password, port = "", "", "", "", 22
        
        self.name_entry = InputEntry(name)
        self.user_entry = InputEntry(user)
        self.server_entry = InputEntry(server)
        self.password_entry = PasswordEntry(password)
        self.port_box = SpinBox(port, lower=1, step=1)
        
        for (index, name) in enumerate(names):
            self.table.attach(
                Label(name),
                0, 1,
                index, index + 1,
                xoptions=gtk.FILL,
                )
            if name == "Name: ":
                widget = self.name_entry
                widget.set_size(80, 23)
            elif name == "User: ":
                widget = self.user_entry
                widget.set_size(80, 23)
            elif name == "Server: ":
                widget = self.server_entry
                widget.set_size(80, 23)
            elif name == "Password: ":
                widget = self.password_entry
                widget.set_size(80, 23)
            elif name == "Port: ":
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
            "远程登陆",
            500,
            400,
            mask_type=DIALOG_MASK_GLASS_PAGE,
            close_callback=self.hide_window,
            )
        
        self.add_button = Button("添加")
        self.connect_button = Button("连接")
        
        self.add_button.connect("clicked", lambda w: self.show_add_remote_login())
        self.connect_button.connect("clicked", lambda w: self.connect_remote_login())
        
        self.right_button_box.set_buttons([self.add_button, self.connect_button])
        
        self.treeview = TreeView()
        self.treeview.set_column_titles(["名字", "服务器"])
        self.treeview.connect("items-change", lambda t: self.save_login_info())
        self.body_box.add(self.treeview)
        
        self.read_login_info()
        
        self.add_remote_login = EditRemoteLogin("添加远程登陆", self.save_remote_login)
        
        self.parent_window = None
        
        self.treeview.connect("right-press-items", self.right_press_items)
        
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
            "编辑远程连接",
            lambda name, user, server, password, port: self.save_item_remote_login(current_item, name, user, server, password, port),
            (current_item.name, current_item.user, current_item.server, current_item.password, current_item.port),
            )
        edit_remote_login.show_login(self.parent_window)
        
        self.save_login_info()
        
    def right_press_items(self, *args):
        (treeview, x, y, current_item, select_items) = args
        if current_item:
            menu_items = [
                (None, "编辑", lambda : self.update_remote_login(current_item)),
                (None, "删除", treeview.delete_select_items),
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
        
    def connect_remote_login(self):
        if len(self.treeview.select_rows) == 1:
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

if __name__ == "__main__":
    Terminal().run()
