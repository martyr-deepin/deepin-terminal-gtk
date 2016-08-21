PREFIX=/usr/local
all: main
main: ./project_path.c \
      ./lib/draw.vala \
      ./lib/menu.vala \
      ./lib/keymap.vala \
      ./lib/utils.vala \
      ./lib/xutils.vala \
      ./lib/constant.vala \
      ./lib/config.vala \
      ./lib/animate_timer.vala \
      ./lib/font.c \
      ./widget/tabbar.vala \
      ./widget/appbar.vala \
      ./widget/titlebar.vala \
      ./widget/checkbutton.vala \
      ./widget/textbutton.vala \
      ./widget/password_button.vala \
      ./widget/add_server_button.vala \
      ./widget/server_button.vala \
      ./widget/server_group_button.vala \
      ./widget/search_entry.vala \
      ./widget/switcher.vala \
      ./widget/terminal.vala \
      ./widget/progressbar.vala \
      ./widget/workspace.vala \
      ./widget/workspace_manager.vala \
      ./widget/image_button.vala \
      ./widget/cursor_toggle_button.vala \
      ./widget/dialog.vala \
      ./widget/dialog_button.vala \
      ./widget/window.vala \
      ./widget/window_event_area.vala \
      ./widget/config_window.vala \
      ./widget/quake_window.vala \
      ./widget/confirm_dialog.vala \
      ./widget/search_box.vala \
      ./widget/remote_panel.vala \
      ./widget/remote_server.vala \
      ./widget/about_dialog.vala \
      ./widget/about_widget.vala \
      ./widget/preference.vala \
      ./widget/preference_slidebar.vala \
      main.vala
	valac -o main \
	-X -w \
	-X -lm \
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
    ./project_path.c \
    ./lib/draw.vala \
    ./lib/menu.vala \
    ./lib/keymap.vala \
    ./lib/utils.vala \
    ./lib/xutils.vala \
    ./lib/constant.vala \
    ./lib/config.vala \
    ./lib/animate_timer.vala \
    ./lib/font.c \
    ./widget/tabbar.vala \
    ./widget/appbar.vala \
    ./widget/titlebar.vala \
    ./widget/checkbutton.vala \
    ./widget/textbutton.vala \
    ./widget/password_button.vala \
    ./widget/add_server_button.vala \
    ./widget/server_button.vala \
    ./widget/server_group_button.vala \
    ./widget/search_entry.vala \
    ./widget/switcher.vala \
    ./widget/terminal.vala \
    ./widget/progressbar.vala \
    ./widget/workspace.vala \
    ./widget/workspace_manager.vala \
    ./widget/image_button.vala \
    ./widget/cursor_toggle_button.vala \
    ./widget/dialog.vala \
    ./widget/dialog_button.vala \
    ./widget/window.vala \
    ./widget/window_event_area.vala \
    ./widget/config_window.vala \
    ./widget/quake_window.vala \
    ./widget/confirm_dialog.vala \
    ./widget/search_box.vala \
    ./widget/remote_panel.vala \
    ./widget/remote_server.vala \
    ./widget/about_dialog.vala \
    ./widget/about_widget.vala \
    ./widget/preference.vala \
    ./widget/preference_slidebar.vala \
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
	cp deepin-terminal.desktop ${DESTDIR}${PREFIX}/share/applications
	cp -r main ${DESTDIR}${PREFIX}/share/deepin-terminal
	ln -sf ${PREFIX}/share/deepin-terminal/main ${DESTDIR}${PREFIX}/bin/deepin-terminal

clean:
	rm -f main

