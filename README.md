# Deepin Terminal

This is default terminal emulation application for Deepin.

## Dependencies

In debian, use below command to install compile dependencies:

`sudo apt-get install valac cmake g++ intltool libgtk-3-dev libgee-0.8-dev libjson-glib-dev libsecret-1-dev libwnck-3-dev librsvg2-dev libreadline-dev libpcre2-dev gobject-introspection libgirepository1.0-dev gperf libxml2-utils`

In debian, use below command to install running dependencies:

`sudo apt-get install libatk1.0-0 libc6 libcairo-gobject2 libcairo2 libfontconfig1 libgdk-pixbuf2.0-0 libgee-0.8-2 libglib2.0-0 libgnutls30 libgtk-3-0 libice6 libjson-glib-1.0-0 libpango-1.0-0 libpangocairo-1.0-0 libpcre2-8-0 libreadline7 librsvg2-2 libsecret-1-0 libsm6 libstdc++6 libtinfo5 libwnck-3-0 libx11-6 libxext6 zlib1g lrzsz expect deepin-menu`

And you also need the [`deepin-menu`](https://github.com/linuxdeepin/deepin-menu) package.

## Installation

`mkdir build; cd build; cmake ..; make; ./deepin-terminal`

Tip: Use `cmake ../ -DUSE_VENDOR_LIB=off` if you don't want to use the vendor lib.

## Usage

Below is keymap list for deepin-terminal:

| Function					      | Shortcut                            |
|---------------------------------|---------------------------------------------------------|
| Copy                            | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd>       |
| Paste                           | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>v</kbd>       |
| Select word                     | Double <kbd>click</kbd>                                 |
| Open URL                        | <kbd>Ctrl</kbd> + <kbd>LeftButton</kbd>                 |
| Search                          | <kbd>Ctrl</kbd> + <kbd>Shfit</kbd> + <kbd>f</kbd>       |
| Zoom in                         | <kbd>Ctrl</kbd> + <kbd>=</kbd>                          |
| Zoom out                        | <kbd>Ctrl</kbd> + <kbd>-</kbd>                          |
| Default size                    | <kbd>Ctrl</kbd> + <kbd>0</kbd>                          |
| Select all                      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>a</kbd>       |
|                                                                                           |
| New workspace                   | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>t</kbd>       |
| Close workspace                 | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>w</kbd>       |
| Next workspace                  | <kbd>Ctrl</kbd> + <kbd>Tab</kbd>                        |
| Preview workspace               | <kbd>Ctrl</kbd> + <kbd>Shfit</kbd> + <kbd>Tab</kbd>     |
| Select workspace with number    | <kbd>Alt</kbd> + <kbd>number</kbd>                      |
| Resize workspace                | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Arrow Key</kbd> |
| Vertical split                  | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd>       |
| Horizontal split                | <kbd>Ctrl</kbd> + <kbd>Shfit</kbd> + <kbd>h</kbd>       |
| Select upper window             | <kbd>Alt</kbd>  + <kbd>k</kbd>                          |
| Select lower window             | <kbd>Alt</kbd>  + <kbd>j</kbd>                          |
| Select left window              | <kbd>Alt</kbd>  + <kbd>h</kbd>                          |
| Select right window             | <kbd>Alt</kbd>  + <kbd>l</kbd>                          |
| Close window                    | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>q</kbd>         |
| Close other windows             | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd>       |
| Create new theme window         | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>number</kbd>    |
|                                                                                           |
| Switch fullscreen               | <kbd>F11</kbd>                                          |
| Adjust background opacity       | <kbd>Ctrl</kbd> + <kbd>ScrollButton</kbd>               |
| Display shortcuts               | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>?</kbd>       |
| Custom commands                 | <kbd>Ctrl</kbd> + <kbd>\[</kbd>                         |
| Remote management               | <kbd>Ctrl</kbd> + <kbd>/</kbd>                          |

## Config file
Terminal's configure save at:
~/.config/deepin/deepin-terminal/config.conf

Remote servers' configure save at:
~/.config/deepin/deepin-terminal/server-config.conf

Customize command's configure save at:
~/.config/deepin/deepin-terminal/command-config.conf

## Advanced config
#### cursor_shape
Cursor shape type, can set with 'block', 'ibeam', 'underline', default is block type.

#### cursor_blink_mode
Whether blink cursor, the default is true, set with false will improve performance though decrease repaint times.

#### cursor_auto_hide
Whether auto hide cursor when don't type in terminal, this default option is false.

#### scroll_on_key
Scroll terminal when type something in terminal, this option the default is true.

#### scroll_on_output
Scroll terminal when have new output, this default option is false, please don't enable this option, it's nosing.

#### scroll_line
The line of terminal can scroll back, default is -1, mean save all history, don't stripe terminal output.

#### use_on_starting
The window status at start, can set with 'window', 'maximize' and 'fullscreen', default is 'window'.

#### blur_background
Whether blur terminal's background, blur feature provide by DDE's window manager -- deepin-wm, default set false for better performance.  

#### window_width
Window width when start, this option is record when you adjust window size.
Of course, you can set it manually.

#### window_height
Window height when start, this option is record when you adjust window size.
Of course, you can set it manually.

#### quake_window_height
The max height of quake terminal, set it with 1.0 can make quake window with any height you like.

#### quake_window_fullscreen
Whether make quake window use fullscreen mode, default is false.

#### remote_commands
Remote command list to help deepin-terminal detect current environment whether in remote server, default is zssh.
You can add new command in list, command separator use character ;
like remote_commands=zssh;new_command;another_command;

#### hide_quakewindow_after_lost_focus
Hide quake window after lost keyboard focus immediately, default is false to keep quake window even lost keyboard focus.
Anyway, feel free to turn this option if you more like quake window hide after lost keyboard focus.

#### show_quakewindow_tab
Whether show tabbar in quake terminal, the default is true. It's cool if you don't like tabbar in quake terminal.

#### follow_active_window
Create new terminal in active monitor when this option set as true, create new terminal with cursor place when this option set as false.

#### hide_quakewindow_when_active
Just hide quake window when cursor is active when this option is true, if cursor is inactive, press quake-terminal keystroke will focus quake window first, and hide quake-terminal when press quake-temrinal keystroke again.
This behaviour help user jump back to quake-terminal quickly.
It's feel free to turn off this feature if you just like to toggle quake-terminal when you press quake-terminal keystroke.

#### print_notify_after_script_finish
Press notify after you use terminal execute script finish, terminal won't exit until you press key, this feature useful to watch script execute result.
The default is true, feel free to turn off this option if you know script's result exactly.

#### run_as_login_shell
Run shell as login_shell, default is false.

#### show_highlight_frame
Show highlight frame when you focus on terminal window, notify user cursor place.
this default option is false, because it's too nosing to me.

#### copy_on_select
Copy select text to system clipboard directly if you turn on this option, i think many XShell users like this. ;) 
This optoin default is false, because it's linux style. ;)

#### bold_is_bright
Checks whether the SGR 1 attribute also switches to the bright counterpart of the first 8 palette colors, in addition to making them bold (legacy behavior) or if SGR 1 only enables bold and leaves the color intact.
Some people may miss the matrix look-n-feel with the default theme since this value used to be `true` by default, now it's `false` by default.

#### tabbar_at_the_bottom
Some tiling WM user may prefer let the tabbar at the window bottom, set `tabbar_at_the_bottom` to `true` will do this for ya, default is `false`.

#### audible_bell
Controls whether or not the terminal will beep when the child outputs the "bl" sequence. Default is `false`.

#### always_hide_resize_grip
When you are using deepin-terminal with not composited window manager, there will be a resize grip line at the bottom of the window for resizing the window. To disable the extra resize grip line, set `always_hide_resize_grip` to true.

## Customize themes
User can place its own theme file to `~/.config/deepin/deepin-terminal/themes` (create if path not exist), the theme file added to this location will available to use from the theme selection panel.

## Customize search engine
Deepin terminal build-in many search engine for engineer, such as Google, Bing, Baidu, GitHub, Stackover Flow, DuckDuckGo.
Anyway, if you want build your own search engine, just follow below command:
* Create config file ~/.config/deepin/deepin-terminal/search-engine-config.conf with below content:

```
[flickr]
name=Flickr
api=https://www.flickr.com/search/?text=%s

[googleimage]
name=Google Image
api=http://images.google.com/search?q=%s
```

* Content in [] is searchengine name, use by terminal for id search.

* name mean human name of search engine, you can name it to anything you like

* api mean search api for search engine, note, you need use %s replace search keyword, otherwise, deepin-terminal don't know how to concat search api url and search keyboard.

## Getting help

Any usage issues can ask for help via

* [Developer Center](https://github.com/linuxdeepin/developer-center/issues)
* [Gitter](https://gitter.im/orgs/linuxdeepin/rooms)
* [IRC channel](https://webchat.freenode.net/?channels=deepin)
* [Forum](https://bbs.deepin.org)
* [WiKi](https://wiki.deepin.org/)

## Getting involved

We encourage you to report issues and contribute changes

* [Contribution guide for developers](https://github.com/linuxdeepin/developer-center/wiki/Contribution-Guidelines-for-Developers-en). (English)
* [开发者代码贡献指南](https://github.com/linuxdeepin/developer-center/wiki/Contribution-Guidelines-for-Developers) (中文)

## License

Deepin Terminal is licensed under [GPLv3](LICENSE).
