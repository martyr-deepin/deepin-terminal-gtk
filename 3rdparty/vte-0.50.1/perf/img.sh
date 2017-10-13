#!/usr/bin/env bash

# Image viewer for terminals that support true colors.
# Copyright (C) 2014  Egmont Koblinger
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

if [ $# != 1 -o "$1" = "--help" ]; then
  echo 'Usage: img.sh imagefile' >&2
  exit 1
elif [ -z $(type -p convert) ]; then
  echo 'Please install ImageMagick to run this script.' >&2
  exit 1
fi

# This is so that "upper" is still visible after exiting the while loop.
shopt -s lastpipe

COLUMNS=$(tput cols)

declare -a upper lower
upper=()
lower=()

convert -thumbnail ${COLUMNS}x -define txt:compliance=SVG "$1" txt:- |
while IFS=',:() ' read col row dummy red green blue rest; do
  if [ "$col" = "#" ]; then
    continue
  fi

  if [ $((row%2)) = 0 ]; then
    upper[$col]="$red;$green;$blue"
  else
    lower[$col]="$red;$green;$blue"
  fi

  # After reading every second image row, print them out.
  if [ $((row%2)) = 1 -a $col = $((COLUMNS-1)) ]; then
    i=0
    while [ $i -lt $COLUMNS ]; do
      echo -ne "\\e[38;2;${upper[$i]};48;2;${lower[$i]}m▀"
      i=$((i+1))
    done
    # \e[K is useful when you resize the terminal while this script is still running.
    echo -e "\\e[0m\e[K"
    upper=()
    d=()
  fi
done

# Print the last half line, if required.
if [ "${upper[0]}" != "" ]; then
  i=0
  while [ $i -lt $COLUMNS ]; do
    echo -ne "\\e[38;2;${upper[$i]}m▀"
    i=$((i+1))
  done
  echo -e "\\e[0m\e[K"
fi
