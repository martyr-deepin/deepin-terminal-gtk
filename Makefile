PREFIX=/usr/local
all: main
main: ./lib/animation.vala \
      ./lib/config.vala \
      ./lib/constant.vala \
      ./lib/draw.vala \
      ./lib/font.c \
      ./lib/keymap.vala \
      ./lib/menu.vala \
      ./lib/utils.vala \
      ./lib/xutils.vala \
      ./project_path.c \
      ./widget/about_dialog.vala \
      ./widget/about_widget.vala \
      ./widget/add_server_button.vala \
      ./widget/appbar.vala \
      ./widget/check_button.vala \
      ./widget/config_window.vala \
      ./widget/confirm_dialog.vala \
      ./widget/cursor_toggle_button.vala \
      ./widget/dialog.vala \
      ./widget/dialog_button.vala \
      ./widget/image_button.vala \
      ./widget/password_button.vala \
      ./widget/preference.vala \
      ./widget/preference_slidebar.vala \
      ./widget/progressbar.vala \
      ./widget/quake_window.vala \
      ./widget/remote_panel.vala \
      ./widget/remote_server_dialog.vala \
      ./widget/search_panel.vala \
      ./widget/search_entry.vala \
      ./widget/server_button.vala \
      ./widget/server_group_button.vala \
      ./widget/switcher.vala \
      ./widget/tabbar.vala \
      ./widget/terminal.vala \
      ./widget/text_button.vala \
      ./widget/titlebar.vala \
      ./widget/window.vala \
      ./widget/window_event_area.vala \
      ./widget/workspace.vala \
      ./widget/workspace_manager.vala \
      main.vala
	valac -o main \
	-X -w \
	-X -lm \
	-X -DGETTEXT_PACKAGE="deepin-terminal" \
	--Xcc=-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
    --pkg=gtk+-3.0 \
    --pkg=vte-2.91 \
    --pkg=gee-0.8 \
    --pkg=json-glib-1.0 \
    --pkg=gio-2.0 \
    --pkg=libwnck-3.0 \
    --pkg=posix \
    --pkg=gdk-x11-3.0 \
    --pkg=xcb \
    --pkg=libsecret-1 \
    --pkg=fontconfig \
    --vapidir=./vapi \
    ./lib/animation.vala \
    ./lib/config.vala \
    ./lib/constant.vala \
    ./lib/draw.vala \
    ./lib/font.c \
    ./lib/keymap.vala \
    ./lib/menu.vala \
    ./lib/utils.vala \
    ./lib/xutils.vala \
    ./project_path.c \
    ./widget/about_dialog.vala \
    ./widget/about_widget.vala \
    ./widget/add_server_button.vala \
    ./widget/appbar.vala \
    ./widget/check_button.vala \
    ./widget/config_window.vala \
    ./widget/confirm_dialog.vala \
    ./widget/cursor_toggle_button.vala \
    ./widget/dialog.vala \
    ./widget/dialog_button.vala \
    ./widget/image_button.vala \
    ./widget/password_button.vala \
    ./widget/preference.vala \
    ./widget/preference_slidebar.vala \
    ./widget/progressbar.vala \
    ./widget/quake_window.vala \
    ./widget/remote_panel.vala \
    ./widget/remote_server_dialog.vala \
    ./widget/search_panel.vala \
    ./widget/search_entry.vala \
    ./widget/server_button.vala \
    ./widget/server_group_button.vala \
    ./widget/switcher.vala \
    ./widget/tabbar.vala \
    ./widget/terminal.vala \
    ./widget/text_button.vala \
    ./widget/titlebar.vala \
    ./widget/window.vala \
    ./widget/window_event_area.vala \
    ./widget/workspace.vala \
    ./widget/workspace_manager.vala \
    main.vala

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${PREFIX}/share/applications
	mkdir -p ${DESTDIR}${PREFIX}/share/deepin-terminal
	mkdir -p ${DESTDIR}${PREFIX}/share/icons
	mkdir -p ${DESTDIR}${PREFIX}/share/dman/deepin-terminal
	cp -r image ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r theme ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp style.css ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp ssh_login.sh ${DESTDIR}${PREFIX}/share/deepin-terminal
	msgfmt --output ${DESTDIR}${PREFIX}/share/locale/zh_CN/LC_MESSAGES/deepin-terminal.mo po/zh_CN/LC_MESSAGES/deepin-terminal.po
	cp deepin-terminal.desktop ${DESTDIR}${PREFIX}/share/applications
	cp -fr main ${DESTDIR}${PREFIX}/share/deepin-terminal
	ln -sf ${PREFIX}/share/deepin-terminal/main ${DESTDIR}${PREFIX}/bin/deepin-terminal

clean:
	rm -f main

