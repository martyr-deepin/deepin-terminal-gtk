# Deepin Terminal

This is default terminal emulation application for Linux Deepin.

Deepin terminal base on python-vte and with many patches for advanced features, such as, searching, opacity adjusting in real-time etc.

## Depends:

* python
* [deepin-ui](https://github.com/linuxdeepin/deepin-ui)
* [python-vte](https://github.com/linuxdeepin/python-vte)
* expect
* hicolor-icon-theme
* xdotool
* [python-deepin-gsettings](https://github.com/linuxdeepin/deepin-gsettings)

## Usage

`python ./src/main.py`

Below is keymap list for deepin-terminal:

| Function                 | Keymap                |
|--------------------------|-----------------------|
| Copy                     | **Ctrl** + **C**      |
| Paste                    | **Ctrl** + **V**      |
| Select word              | Double click          |
| Open URL                 | **Ctrl** + LeftButton |
| Split vertically         | **Ctrl** + **H**      |
| Split horizontally       | **Ctrl** + **h**      |
|                                                  |
| Close current window     | **Ctrl** + **W**      |
| Close other windows      | **Ctrl** + **Q**      |
| Scrol up                 | **Alt**  + **,**      |
| Scroll down              | **Alt**  + **.**      |
|                                                  |
| Focus up terminal        | **Alt**  + **k**      |
| Focus down terminal      | **Alt**  + **j**      |
| Focus left terminal      | **Alt**  + **h**      |
| Focus right terminal     | **Alt**  + **l**      |
|                                                  |
| Zoom out                 | **Ctrl** + **=**      |
| Zoom in                  | **Ctrl** + **-**      |
| Revert default size      | **Ctrl** + **0**      |
|                                                  |
| New workspace            | **Ctrl** + **/**      |
| Close workspace          | **Ctrl** + **:**      |
| Switch preview workspace | **Ctrl** + **,**      |
| Switch next workspace    | **Ctrl** + **.**      |
|                                                  |
| Search forward           | **Ctrl** + **'**      |
| Search backward          | **Ctrl** + **"**      |
|                                                  |
| Fullscreen               | **F11**               |
| Help                     | **Ctrl** + **?**      |
| Show remote login window | **Ctrl** + **9**      |
| Show sub-process window  | **Ctrl** + **8**      |

## Installation

`make && make install`

## Getting help

Any usage issues can ask for help via

* [Gitter](https://gitter.im/orgs/linuxdeepin/rooms)
* [IRC channel](https://webchat.freenode.net/?channels=deepin)
* [Forum](https://bbs.deepin.org)
* [WiKi](http://wiki.deepin.org/)

## Getting involved

We encourage you to report issues and contribute changes

* [Contirubtion guide for users](http://wiki.deepin.org/index.php?title=Contribution_Guidelines_for_Users)
* [Contribution guide for developers](http://wiki.deepin.org/index.php?title=Contribution_Guidelines_for_Developers).

## License

Deepin Terminal is licensed under [GPLv3](LICENSE).
