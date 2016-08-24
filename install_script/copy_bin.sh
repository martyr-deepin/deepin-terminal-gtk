#!/bin/sh
install -p -D -m 0755 main ${DESTDIR}${PREFIX}/share/deepin-terminal
install -p -D -m 0755 deepin-terminal ${DESTDIR}${PREFIX}/share/deepin-terminal
ln -sf ${PREFIX}/share/deepin-terminal/deepin-terminal ${DESTDIR}${PREFIX}/bin/deepin-terminal
