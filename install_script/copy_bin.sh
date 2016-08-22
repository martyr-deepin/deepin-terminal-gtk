#!/bin/sh
PREFIX=/usr/local

cp -fr main ${DESTDIR}${PREFIX}/share/deepin-terminal
ln -sf ${PREFIX}/share/deepin-terminal/main ${DESTDIR}${PREFIX}/bin/deepin-terminal
