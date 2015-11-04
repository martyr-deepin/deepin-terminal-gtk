PREFIX = /usr/local

all:
	cd tools; ./generate_mo.py; cd ..

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${PREFIX}/share/applications
	mkdir -p ${DESTDIR}${PREFIX}/share/deepin-terminal
	mkdir -p ${DESTDIR}${PREFIX}/share/icons
	mkdir -p ${DESTDIR}${PREFIX}/share/dman/deepin-terminal
	cp -r src ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r skin ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r locale/mo ${DESTDIR}${PREFIX}/share/locale
	cp -r app_theme ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r image ${DESTDIR}${PREFIX}/share/deepin-terminal
	cp -r image/hicolor ${DESTDIR}${PREFIX}/share/icons
	cp -r doc/* ${DESTDIR}${PREFIX}/share/dman/deepin-terminal
	cp deepin-terminal.desktop ${DESTDIR}${PREFIX}/share/applications
	ln -sf ${PREFIX}/share/deepin-terminal/src/main.py ${DESTDIR}${PREFIX}/bin/deepin-terminal
