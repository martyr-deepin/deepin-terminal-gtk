#!/bin/sh
install -p -D -m 0755 main ${DESTDIR}${PREFIX}/share/deepin-terminal
ln -sf ${PREFIX}/share/deepin-terminal/main ${DESTDIR}${PREFIX}/bin/deepin-terminal
