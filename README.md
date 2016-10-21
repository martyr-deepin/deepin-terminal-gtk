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
|---------------------------------|-------------------------------------|
| Copy                            | **Ctrl** + **Shift** + **c**        |
| Paste                           | **Ctrl** + **Shift** + **v**        |
| Select word                     | **Double click**                    |
| Open URL                        | **Ctrl** + **LeftButton**           |
| Search                          | **Ctrl** + **Shfit** + **f**        |
| Zoom in                         | **Ctrl** + **=**                    |
| Zoom out                        | **Ctrl** + **-**                    |
| Default size                    | **Ctrl** + **0**                    |
| Select all                      | **Ctrl** + **Shift** + **a**        |
|                                                                       |
| New workspace                   | **Ctrl** + **Shift** + **t**        |
| Close workspace                 | **Ctrl** + **Shift** + **w**        |
| Next workspace                  | **Ctrl** + **Tab**                  |
| Preview workspace               | **Ctrl** + **Shfit** + **Tab**      |
| Select workspace with number    | **Alt** + **number**                |
| Vertical split                  | **Ctrl** + **Shift** + **j**        |
| Horizontal split                | **Ctrl** + **Shfit** + **h**        |
| Select upper window             | **Alt**  + **k**                    |
| Select lower window             | **Alt**  + **j**                    |
| Select left window              | **Alt**  + **h**                    |
| Select right window             | **Alt**  + **l**                    |
| Close window                    | **Ctrl** + **Alt** + **q**          |
| Close other windows             | **Ctrl** + **Shift** + **q**        |
|                                                                       |
| Switch fullscreen               | **F11**                             |
| Adjust background opacity       | **Ctrl** + **ScrollButton**         |
| Display shortcuts               | **Ctrl** + **Shift** + **?**        |
| Custom commands                 | **Ctrl** + **[**                    |
| Remote management               | **Ctrl** + **/**                    |

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
