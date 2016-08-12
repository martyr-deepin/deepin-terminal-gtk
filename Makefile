all: main
main: ./project_path.c \
      ./lib/draw.vala \
      ./lib/menu.vala \
      ./lib/keymap.vala \
      ./lib/utils.vala \
      ./lib/config.vala \
      ./lib/animate_timer.vala \
      ./lib/font.c \
      ./widget/tabbar.vala \
      ./widget/appbar.vala \
      ./widget/titlebar.vala \
      ./widget/checkbutton.vala \
      ./widget/hotkey_preview.vala \
      ./widget/terminal.vala \
      ./widget/progressbar.vala \
      ./widget/workspace.vala \
      ./widget/workspace_manager.vala \
      ./widget/image_button.vala \
      ./widget/cursor_toggle_button.vala \
      ./widget/temp_text_button.vala \
      ./widget/dialog_button.vala \
      ./widget/event_box.vala \
      ./widget/window.vala \
      ./widget/window_event_area.vala \
      ./widget/base_window.vala \
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
    --pkg=gtk+-3.0 \
    --pkg=vte-2.91 \
    --pkg=gee-1.0 \
    --pkg=json-glib-1.0 \
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
    ./lib/config.vala \
    ./lib/animate_timer.vala \
    ./lib/font.c \
    ./widget/tabbar.vala \
    ./widget/appbar.vala \
    ./widget/titlebar.vala \
    ./widget/checkbutton.vala \
    ./widget/hotkey_preview.vala \
    ./widget/terminal.vala \
    ./widget/progressbar.vala \
    ./widget/workspace.vala \
    ./widget/workspace_manager.vala \
    ./widget/image_button.vala \
    ./widget/cursor_toggle_button.vala \
    ./widget/temp_text_button.vala \
    ./widget/dialog_button.vala \
    ./widget/event_box.vala \
    ./widget/window.vala \
    ./widget/window_event_area.vala \
    ./widget/base_window.vala \
    ./widget/confirm_dialog.vala \
    ./widget/search_box.vala \
    ./widget/remote_panel.vala \
    ./widget/remote_server.vala \
    ./widget/about_dialog.vala \
    ./widget/about_widget.vala \
    ./widget/preference.vala \
    ./widget/preference_slidebar.vala \
    main.vala
clean:
	rm -f main

