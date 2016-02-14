#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2013 Deepin Technology Co., Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

import gettext
import os

def get_parent_dir(filepath, level=1):
    '''Get parent dir.'''
    parent_dir = os.path.realpath(filepath)

    while(level > 0):
        parent_dir = os.path.dirname(parent_dir)
        level -= 1

    return parent_dir

LOCALE_DIR=os.path.join(get_parent_dir(__file__, 2), "locale", "mo")
if not os.path.exists(LOCALE_DIR):
    LOCALE_DIR="/usr/share/locale"

_ = None
try:
    _ = gettext.translation("deepin-terminal", LOCALE_DIR).gettext
except Exception, e:
    _ = lambda i : i
