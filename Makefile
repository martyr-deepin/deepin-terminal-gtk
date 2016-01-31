all: main
main: ./lib/draw.vala \
      ./lib/keymap.vala \
      ./lib/utils.vala \
      ./widget/tabbar.vala \
      ./widget/titlebar.vala \
      ./widget/terminal.vala \
      ./widget/workspace.vala \
      ./widget/workspace_manager.vala \
      ./widget/image_button.vala \
      main.vala
	valac -o main \
	-X -w \
    --pkg=gtk+-3.0 \
    --pkg=vte-2.91 \
    --pkg=gee-1.0 \
    ./lib/draw.vala \
    ./lib/keymap.vala \
    ./lib/utils.vala \
    ./widget/tabbar.vala \
    ./widget/titlebar.vala \
    ./widget/terminal.vala \
    ./widget/workspace.vala \
    ./widget/workspace_manager.vala \
    ./widget/image_button.vala \
    main.vala
clean:
	rm -f main

