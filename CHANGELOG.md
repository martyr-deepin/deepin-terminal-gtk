# Change Log
This is default terminal emulation application for Deepin

## [Unreleased]


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
