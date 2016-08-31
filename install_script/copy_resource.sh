#!/bin/sh
install -d ${DESTDIR}${PREFIX}/bin
install -d ${DESTDIR}${PREFIX}/share/applications
install -d ${DESTDIR}${PREFIX}/share/deepin-terminal
install -d ${DESTDIR}${PREFIX}/share/icons
install -d ${DESTDIR}${PREFIX}/share/dman/deepin-terminal
cp -r image ${DESTDIR}${PREFIX}/share/deepin-terminal
cp -r theme ${DESTDIR}${PREFIX}/share/deepin-terminal
cp -r manual/* ${DESTDIR}${PREFIX}/share/dman/deepin-terminal
cp style.css ${DESTDIR}${PREFIX}/share/deepin-terminal
cp ssh_login.sh ${DESTDIR}${PREFIX}/share/deepin-terminal
cp deepin-terminal.desktop ${DESTDIR}${PREFIX}/share/applications
