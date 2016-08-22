#!/bin/sh
for lang in ../po/*
do
    msginit --no-translator -i deepin-terminal.pot -l $(basename ${lang}).UTF-8 -o ../po/$(basename ${lang})/LC_MESSAGES/deepin-terminal.po
done    
