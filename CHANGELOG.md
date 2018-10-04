## [3.0.6] - 2018-10-04
* fix: github issue #73

## [3.0.5] - 2018-09-17
* fix: missing verison info when building the deb

## [3.0.4] - 2018-09-07
* fix: unregister menu before recreate menu
* refactor: match more mono fonts

## [3.0.3] - 2018-08-19
* feat: support customized version string

## [3.0.2] - 2018-08-19
* generate version information from git
* fix: support set tab title use OSC escape sequence

<a name="3.0.1"></a>
### 3.0.1 (2018-07-20)


#### Bug Fixes

*   Adapt lintian ([748a876a](https://github.com/linuxdeepin/deepin-terminal/commit/748a876a40725005ce8e415793b343d04de2fc03))
*   add TEST_BUILD configure condition ([7d757089](https://github.com/linuxdeepin/deepin-terminal/commit/7d75708997ea45f6424d80566edd67812c7fed05))



# Change Log
This is default terminal emulation application for Deepin

## [Unreleased]

## [3.0.0] - 2018-05-14
* Add customize search engine to right menu.
* Like XShell, if user set config option 'copy_on_select' to true, terminal will copy select text to system clipboard when text is selected.
* Add github, stackoverflow, duckduckgo in default search engine.
* Add git ssh link support: mouse hover git link to copy it.
* Open current directory in file manager.
* Slow down the opacity adjust speed.
* Use DBus instead dman to start Deepin Manual, Deepin Manual just will run in flatpak runtime in the future.
* Search improvements, allow to search with enter key and previous/next buttons even after initial search panel opening, improved by avently, thanks.
* Search improvements, disabled live search, improved by avently, thanks.
* Refactory CMakeLists.txt, improved by avently, thanks.
* Add WenQuanYi in mono font whitelist, WenQuanYi's attribute is incomplete, not include spacing attribue.
* Just reset terminal when exit code match samba error code, other non-zero code (such as Ctrl + C etc) don't trigger reset terminal.
* Refactory code: move prevent event code to Widgets.SpinButton.
* Prevent scrolling event of Gtk.ComboBoxText and Gtk.SpinButton.
* Add empathy theme.
* Fixed spell of README.md, thanks wtz.
* Add miss dependences in README.md.
* Add advanced options in README.md.
* Update copyright year.
* Update translations.

## [2.9.2] - 2017-12-01
- Fixed blur background not work for 4k screen.

## [2.9.1] - 2017-11-27
- Add option 'show_highlight_frame', default set to false, it's nosie to display highlight frame everytime i select terminal window.
- Adjust about dialog font size.
- Adjust progressbar draw coordinate.

## [2.9] - 2017-11-27
- Upload file to remote server when drag file to remote terminal.
- Split terminal to login server if current terminal has login.
- Set 'NO_AT_BRIDGE' environment variable with 1 to dislable accessibility dbus warning.
- Display highlight frame when select different terminal window.
- Fixed preference dialog widget width problem when use German.
- Adjust slider button text width to make it can display ip address completely.
- Add "blur background" option in preference dialog.
- Update translations.

## [2.8] - 2017-11-23
- Drag file to remote server if terminal is login.

## [2.7.7] - 2017-11-22
- Downgrade zssh version
- Change get_ssh_script_path path to follow debian policy.
- Adjust preference dialog font attribute.

## [2.7.6] - 2017-11-09
- Buildin zssh in deepin-terminal, don't need depend zssh in linux distribution
- Fixed search text color is not correctly when terminal use light theme
- Add baidu and bing search engine in right menu

## [2.7.5] - 2017-11-06
- Synchronous translations

## [2.7] - 2017-09-11
- Add 'load_theme' option to make new terminal load theme that provide by user
- Add "New theme terminal" feature: press Ctrl + Alt + num to create new theme terminal
- Update pot file with new feature: load_theme option and new theme terminal window

## [2.6] - 2017-09-05
- Update manual content to deepin-terminal 26
- Update transifex translations
- Find a safe way to make server title will change along with server login status
- Add deepin-menu in debian dependence
- Add advanced option 'print_notify_after_script_finish', terminal will quit immediately once command execute finish when this option set as true, default is false
- Add option 'cursor auto hide', terminal cursor will autohide when type text in terminal when this option set as true, default is false
- Add rename dialog in right-click menu, to make user customize terminal title, this feature can tricked by press F2
- Set tab title with server name instead server path when login in server
