#!/bin/sh
for lang in ../po/*
do
    mv ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal-gtk.po ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal-gtk_backup.po     
    msgmerge ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal-gtk_backup.po deepin-terminal-gtk.pot > ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal-gtk.po
    rm ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal-gtk_backup.po     
done    

