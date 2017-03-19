# Deepin Terminal

This is default terminal emulation application for Deepin.

## Dependencies

In debian, use below command to install compile dependencies:

`sudo apt-get install valac libgtk-3-dev libgee-0.8-dev libvte-2.91-dev libjson-glib-dev libsecret-1-dev libwnck-3-dev`

In debian, use below command to install running dependencies:

`sudo apt-get install libatk1.0-0 libc6 libcairo-gobject2 libcairo2 libfontconfig1 libfreetype6 libgdk-pixbuf2.0-0 libgee-0.8-2 libglib2.0-0 libgnutls30 libgtk-3-0 libjson-glib-1.0-0 libpango-1.0-0 libpangocairo-1.0-0 libsecret-1-0 libvte-2.91-0 libwnck-3-0 libx11-6 libxcb1 zlib1g zssh lrzsz`

And you also need `deepin-menu` from [http://mirrors.deepin.com/deepin/pool/main/d/deepin-menu/](http://mirrors.deepin.com/deepin/pool/main/d/deepin-menu/) .

## Installation

`mkdir build; cd build; cmake ..; make; ./deepin-terminal`

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
| Vertical split                  | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd>       |
| Horizontal split                | <kbd>Ctrl</kbd> + <kbd>Shfit</kbd> + <kbd>h</kbd>       |
| Select upper window             | <kbd>Alt</kbd>  + <kbd>k</kbd>                          |
| Select lower window             | <kbd>Alt</kbd>  + <kbd>j</kbd>                          |
| Select left window              | <kbd>Alt</kbd>  + <kbd>h</kbd>                          |
| Select right window             | <kbd>Alt</kbd>  + <kbd>l</kbd>                          |
| Close window                    | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>q</kbd>         |
| Close other windows             | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd>       |
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

## Getting help

Any usage issues can ask for help via

* [Gitter](https://gitter.im/orgs/linuxdeepin/rooms)
* [IRC channel](https://webchat.freenode.net/?channels=deepin)
* [Forum](https://bbs.deepin.org)
* [WiKi](http://wiki.deepin.org/)

## Getting involved

We encourage you to report issues and contribute changes

* [Contribution guide for users](http://wiki.deepin.org/index.php?title=Contribution_Guidelines_for_Users)
* [Contribution guide for developers](http://wiki.deepin.org/index.php?title=Contribution_Guidelines_for_Developers).

## License

Deepin Terminal is licensed under [GPLv3](LICENSE).
