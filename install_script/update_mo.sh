#!/bin/sh
PREFIX=/usr/local

for lang in po/*
do
    mkdir -p ${DESTDIR}${PREFIX}/share/locale/$(basename ${lang})/LC_MESSAGES/
	msgfmt --output ${DESTDIR}${PREFIX}/share/locale/$(basename ${lang})/LC_MESSAGES/deepin-terminal.mo po/$(basename ${lang})/LC_MESSAGES/deepin-terminal.po
done	
	
