all: main
main: ./lib/draw.vala \
      ./lib/keymap.vala \
      ./lib/utils.vala \
      ./widget/tabbar.vala \
      ./widget/terminal.vala \
      ./widget/workspace.vala \
      main.vala
	valac -o main \
	-X -w \
    --pkg=gtk+-3.0 \
    --pkg=vte-2.90 \
    --pkg=gee-1.0 \
    ./lib/draw.vala \
    ./lib/keymap.vala \
    ./lib/utils.vala \
    ./widget/tabbar.vala \
    ./widget/terminal.vala \
    ./widget/workspace.vala \
    main.vala
clean:
	rm -f main

