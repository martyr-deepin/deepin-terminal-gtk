#!/bin/sh
for lang in po/*
do
    mkdir -p ${DESTDIR}${PREFIX}/share/locale/$(basename ${lang})/LC_MESSAGES/
    rm -f ${DESTDIR}${PREFIX}/share/locale/$(basename ${lang})/LC_MESSAGES/deepin-terminal.mo
	msgfmt --output ${DESTDIR}${PREFIX}/share/locale/$(basename ${lang})/LC_MESSAGES/deepin-terminal.mo po/$(basename ${lang})/LC_MESSAGES/deepin-terminal.po
done	
	
