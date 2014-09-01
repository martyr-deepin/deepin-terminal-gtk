PREFIX = /usr/local

all:
	cd tools; ./generate_mo.py; cd ..

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${PREFIX}/share/applications
	mkdir -p ${DESTDIR}${PREFIX}/share/deepin-terminal
	mkdir -p ${DESTDIR}${PREFIX}/share/icons/hicolor/48x48/apps
	cp -r src ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r skin ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r locale ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r app_theme ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r image ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp deepin-terminal.png ${DESTDIR}${PREFIX}/share/icons/hicolor/48x48/apps
	cp deepin-terminal.desktop ${DESTDIR}${PREFIX}/share/applications
	ln -sf ${PREFIX}/share/deepin-terminal/src/main.py ${DESTDIR}${PREFIX}/bin/deepin-terminal
