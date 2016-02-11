all: main
main: ./project_path.c \
      ./lib/draw.vala \
      ./lib/keymap.vala \
      ./lib/utils.vala \
      ./widget/tabbar.vala \
      ./widget/appbar.vala \
      ./widget/titlebar.vala \
      ./widget/terminal.vala \
      ./widget/workspace.vala \
      ./widget/workspace_manager.vala \
      ./widget/image_button.vala \
      ./widget/text_button.vala \
      ./widget/event_box.vala \
      ./widget/window.vala \
      ./widget/confirm_dialog.vala \
      ./widget/history_dialog.vala \
      ./widget/listview.vala \
      main.vala
	valac -o main \
	-X -w \
	-X -lm \
    --pkg=gtk+-3.0 \
    --pkg=vte-2.91 \
    --pkg=gee-1.0 \
    --pkg=posix \
    ./project_path.c \
    ./lib/draw.vala \
    ./lib/keymap.vala \
    ./lib/utils.vala \
    ./widget/tabbar.vala \
    ./widget/appbar.vala \
    ./widget/titlebar.vala \
    ./widget/terminal.vala \
    ./widget/workspace.vala \
    ./widget/workspace_manager.vala \
    ./widget/image_button.vala \
    ./widget/text_button.vala \
    ./widget/event_box.vala \
    ./widget/window.vala \
    ./widget/confirm_dialog.vala \
    ./widget/history_dialog.vala \
    ./widget/listview.vala \
    main.vala
clean:
	rm -f main

