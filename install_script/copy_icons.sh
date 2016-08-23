#!/bin/sh
install -d ${DESTDIR}${PREFIX}/share/icons/hicolor/32x32/apps
cp hicolor/32x32/deepin-terminal.png ${DESTDIR}${PREFIX}/share/icons/hicolor/32x32/apps
install -d ${DESTDIR}${PREFIX}/share/icons/hicolor/48x48/apps
cp hicolor/48x48/deepin-terminal.png ${DESTDIR}${PREFIX}/share/icons/hicolor/48x48/apps
install -d ${DESTDIR}${PREFIX}/share/icons/hicolor/96x96/apps
cp hicolor/96x96/deepin-terminal.png ${DESTDIR}${PREFIX}/share/icons/hicolor/96x96/apps
install -d ${DESTDIR}${PREFIX}/share/icons/hicolor/128x128/apps
cp hicolor/128x128/deepin-terminal.png ${DESTDIR}${PREFIX}/share/icons/hicolor/128x128/apps
install -d ${DESTDIR}${PREFIX}/share/icons/hicolor/scalable/apps
cp hicolor/deepin-terminal.svg ${DESTDIR}${PREFIX}/share/icons/hicolor/scalable/apps
