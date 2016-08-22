#!/bin/sh
for lang in ../po/*
do
    mv ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal.po ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal_backup.po     
    msgmerge ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal_backup.po deepin-terminal.pot > ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal.po
    rm ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal_backup.po     
done    

