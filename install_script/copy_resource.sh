#!/bin/sh
PREFIX=/usr/

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
