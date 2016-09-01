# Deepin Terminal

This is default terminal emulation application for Deepin.

## Dependencies

* vala
* vte-2.91
* gtk+-3.0

In debian, use below command to install dependencies:

`sudo apt-get install valac libgtk-3-dev libgee-0.8-dev libvte-2.91-dev libjson-glib-dev libsecret-1-dev libwnck-3-dev`

## Usage

Below is keymap list for deepin-terminal:

| Function					      | Keymap                              |
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
| Remote management               | **Ctrl** + **/**                    |

## Installation

`make && ./main`

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
