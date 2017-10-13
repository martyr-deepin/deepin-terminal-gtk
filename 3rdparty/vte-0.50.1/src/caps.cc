/*
 * Copyright (C) 2001,2002 Red Hat, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <config.h>
#include <stdlib.h>
#include <glib.h>
#include "caps.h"

#define ESC _VTE_CAP_ESC
#define CSI _VTE_CAP_CSI
#define ST  _VTE_CAP_ST
#define OSC _VTE_CAP_OSC
#define PM  _VTE_CAP_PM
#define APC _VTE_CAP_APC

#define ENQ "\005"
#define BEL "\007"
#define BS  "\010"
#define TAB "\011"
#define LF  "\012"
#define VT  "\013"
#define FF  "\014"
#define CR  "\015"
#define SO  "\016"
#define SI  "\017"
#define DEL "\177"

#define ENTRY(seq, name) seq "\0" name "\0"
#define COMMENT(c)

/* From some really old XTerm docs we had at the office, and an updated
 * version at Moy, Gildea, and Dickey. */
const char _vte_xterm_capability_strings[] =
        ENTRY(ENQ, "return-terminal-status")
        ENTRY(BEL, "bell")
        ENTRY(BS,  "backspace")
        ENTRY(TAB, "tab")
        ENTRY(LF,  "line-feed")
        ENTRY(VT,  "vertical-tab")
        ENTRY(FF,  "form-feed")
        ENTRY(CR,  "carriage-return")
        ENTRY(SO,  "shift-out")
        ENTRY(SI,  "shift-in")
        ENTRY(DEL, "nop")

        ENTRY(ESC " F", "7-bit-controls")
        ENTRY(ESC " G", "8-bit-controls")
        ENTRY(ESC " L", "ansi-conformance-level-1")
        ENTRY(ESC " M", "ansi-conformance-level-2")
        ENTRY(ESC " N", "ansi-conformance-level-3")
        ENTRY(ESC "#3", "double-height-top-half")
        ENTRY(ESC "#4", "double-height-bottom-half")
        ENTRY(ESC "#5", "single-width")
        ENTRY(ESC "#6", "double-width")
        ENTRY(ESC "#8", "screen-alignment-test")

        COMMENT(/* These are actually designate-other-coding-system from ECMA 35,)
                   COMMENT( * but we don't support the full repertoire.  Actually, we don't)
                   COMMENT( * know what the full repertoire looks like. */)
        ENTRY(ESC "%%@", "default-character-set")
        ENTRY(ESC "%%G", "utf-8-character-set")

        ENTRY(ESC "(0", "designate-g0-line-drawing")
        ENTRY(ESC "(A", "designate-g0-british")
        ENTRY(ESC "(B", "designate-g0-plain")
        ENTRY(ESC ")0", "designate-g1-line-drawing")
        ENTRY(ESC ")A", "designate-g1-british")
        ENTRY(ESC ")B", "designate-g1-plain")

        ENTRY(ESC "7", "save-cursor")
        ENTRY(ESC "8", "restore-cursor")
        ENTRY(ESC "=", "application-keypad")
        ENTRY(ESC ">", "normal-keypad")
        ENTRY(ESC "D", "index")
        ENTRY(ESC "E", "next-line")
        COMMENT(/* ENTRY(ESC "F", "cursor-lower-left") */)
        ENTRY(ESC "H", "tab-set")
        ENTRY(ESC "M", "reverse-index")
        COMMENT(/* ENTRY(ESC "N", "single-shift-g2") */)
        COMMENT(/* ENTRY(ESC "O", "single-shift-g3") */)
        ENTRY(ESC "P%s" ST, "device-control-string")
        ENTRY(ESC "V", "start-of-guarded-area")
        ENTRY(ESC "W", "end-of-guarded-area")
        ENTRY(ESC "X%s" ST, "start-of-string / end-of-string")
        ENTRY(ESC "Z", "return-terminal-id")
        ENTRY(ESC "c", "full-reset")
        ENTRY(ESC "l", "memory-lock")
        ENTRY(ESC "m", "memory-unlock")
        COMMENT(/* ENTRY(ESC "n", "invoke-g2-character-set") */)
        COMMENT(/* ENTRY(ESC "o", "invoke-g3-character-set") */)
        COMMENT(/* ENTRY(ESC "|", "invoke-g3-character-set-as-gr") */)
        COMMENT(/* ENTRY(ESC "}", "invoke-g2-character-set-as-gr") */)
        COMMENT(/* ENTRY(ESC "~", "invoke-g1-character-set-as-gr") */)

        COMMENT(/* APC stuff omitted. */)

        COMMENT(/* DCS stuff omitted. */)

        ENTRY(CSI "@", "insert-blank-characters")
        ENTRY(CSI "%d@", "insert-blank-characters")
        ENTRY(CSI "A", "cursor-up")
        ENTRY(CSI "%dA", "cursor-up")
        ENTRY(CSI "B", "cursor-down")
        ENTRY(CSI "%dB", "cursor-down")
        ENTRY(CSI "C", "cursor-forward")
        ENTRY(CSI "%dC", "cursor-forward")
        ENTRY(CSI "D", "cursor-backward")
        ENTRY(CSI "%dD", "cursor-backward")
        ENTRY(CSI "E", "cursor-next-line")
        ENTRY(CSI "%dE", "cursor-next-line")
        ENTRY(CSI "F", "cursor-preceding-line")
        ENTRY(CSI "%dF", "cursor-preceding-line")
        ENTRY(CSI "G", "cursor-character-absolute")
        ENTRY(CSI "%dG", "cursor-character-absolute")
        ENTRY(CSI "H", "cursor-position")
        ENTRY(CSI ";H", "cursor-position")
        ENTRY(CSI "%dH", "cursor-position")
        ENTRY(CSI "%d;H", "cursor-position")
        ENTRY(CSI ";%dH", "cursor-position-top-row")
        ENTRY(CSI "%d;%dH", "cursor-position")
        ENTRY(CSI "I", "cursor-forward-tabulation")
        ENTRY(CSI "%dI", "cursor-forward-tabulation")
        ENTRY(CSI "J", "erase-in-display")
        ENTRY(CSI "%mJ", "erase-in-display")
        ENTRY(CSI "?J", "selective-erase-in-display")
        ENTRY(CSI "?%mJ", "selective-erase-in-display")
        ENTRY(CSI "K", "erase-in-line")
        ENTRY(CSI "%mK", "erase-in-line")
        ENTRY(CSI "?K", "selective-erase-in-line")
        ENTRY(CSI "?%mK", "selective-erase-in-line")
        ENTRY(CSI "L", "insert-lines")
        ENTRY(CSI "%dL", "insert-lines")
        ENTRY(CSI "M", "delete-lines")
        ENTRY(CSI "%dM", "delete-lines")
        ENTRY(CSI "P", "delete-characters")
        ENTRY(CSI "%dP", "delete-characters")
        ENTRY(CSI "S", "scroll-up")
        ENTRY(CSI "%dS", "scroll-up")
        ENTRY(CSI "T", "scroll-down")
        ENTRY(CSI "%dT", "scroll-down")
        ENTRY(CSI "%d;%d;%d;%d;%dT", "initiate-hilite-mouse-tracking")
        ENTRY(CSI "X", "erase-characters")
        ENTRY(CSI "%dX", "erase-characters")
        ENTRY(CSI "Z", "cursor-back-tab")
        ENTRY(CSI "%dZ", "cursor-back-tab")

        ENTRY(CSI "`", "character-position-absolute")
        ENTRY(CSI "%d`", "character-position-absolute")
        ENTRY(CSI "b", "repeat")
        ENTRY(CSI "%db", "repeat")
        ENTRY(CSI "c", "send-primary-device-attributes")
        ENTRY(CSI "%dc", "send-primary-device-attributes")
        ENTRY(CSI ">c", "send-secondary-device-attributes")
        ENTRY(CSI ">%dc", "send-secondary-device-attributes")
        ENTRY(CSI "=c", "send-tertiary-device-attributes")
        ENTRY(CSI "=%dc", "send-tertiary-device-attributes")
        ENTRY(CSI "?%mc", "linux-console-cursor-attributes")
        ENTRY(CSI "d", "line-position-absolute")
        ENTRY(CSI "%dd", "line-position-absolute")
        ENTRY(CSI "f", "cursor-position")
        ENTRY(CSI ";f", "cursor-position")
        ENTRY(CSI "%df", "cursor-position")
        ENTRY(CSI "%d;f", "cursor-position")
        ENTRY(CSI ";%df", "cursor-position-top-row")
        ENTRY(CSI "%d;%df", "cursor-position")
        ENTRY(CSI "g", "tab-clear")
        ENTRY(CSI "%dg", "tab-clear")

        ENTRY(CSI "%mh", "set-mode")
        ENTRY(CSI "?%mh", "decset")

        ENTRY(CSI "%mi", "media-copy")
        ENTRY(CSI "?%mi", "dec-media-copy")

        ENTRY(CSI "%ml", "reset-mode")
        ENTRY(CSI "?%ml", "decreset")

        ENTRY(CSI "%mm", "character-attributes")

        ENTRY(CSI "%dn", "device-status-report")
        ENTRY(CSI "?%dn", "dec-device-status-report")
        ENTRY(CSI "!p", "soft-reset")
        ENTRY(CSI "%d;%d\"p", "set-conformance-level")
        ENTRY(CSI " q", "set-cursor-style")
        ENTRY(CSI "%d q", "set-cursor-style")
        ENTRY(CSI "%d\"q", "select-character-protection")

        ENTRY(CSI "r", "set-scrolling-region")
        ENTRY(CSI ";r", "set-scrolling-region")
        ENTRY(CSI ";%dr", "set-scrolling-region-from-start")
        ENTRY(CSI "%dr", "set-scrolling-region-to-end")
        ENTRY(CSI "%d;r", "set-scrolling-region-to-end")
        ENTRY(CSI "%d;%dr", "set-scrolling-region")

        ENTRY(CSI "?%mr", "restore-mode")
        ENTRY(CSI "s", "save-cursor")
        ENTRY(CSI "?%ms", "save-mode")
        ENTRY(CSI "u", "restore-cursor")

        ENTRY(CSI "%mt", "window-manipulation")

        ENTRY(CSI "%d;%d;%d;%dw", "enable-filter-rectangle")
        ENTRY(CSI "%dx", "request-terminal-parameters")
        ENTRY(CSI "%d;%d'z", "enable-locator-reporting")
        ENTRY(CSI "%m'{", "select-locator-events")
        ENTRY(CSI "%d'|", "request-locator-position")

        COMMENT(/* Set text parameters, BEL-terminated versions. */)
        ENTRY(OSC ";%s" BEL, "set-icon-and-window-title") COMMENT(/* undocumented default */)
        ENTRY(OSC "0;%s" BEL, "set-icon-and-window-title")
        ENTRY(OSC "1;%s" BEL, "set-icon-title")
        ENTRY(OSC "2;%s" BEL, "set-window-title")
        ENTRY(OSC "3;%s" BEL, "set-xproperty")
        ENTRY(OSC "4;%s" BEL, "change-color-bel")
        ENTRY(OSC "6;%s" BEL, "set-current-file-uri")
        ENTRY(OSC "7;%s" BEL, "set-current-directory-uri")
        ENTRY(OSC "8;%s;%s" BEL, "set-current-hyperlink")
        ENTRY(OSC "10;%s" BEL, "change-foreground-color-bel")
        ENTRY(OSC "11;%s" BEL, "change-background-color-bel")
        ENTRY(OSC "12;%s" BEL, "change-cursor-background-color-bel")
        ENTRY(OSC "13;%s" BEL, "change-mouse-cursor-foreground-color-bel")
        ENTRY(OSC "14;%s" BEL, "change-mouse-cursor-background-color-bel")
        ENTRY(OSC "15;%s" BEL, "change-tek-foreground-color-bel")
        ENTRY(OSC "16;%s" BEL, "change-tek-background-color-bel")
        ENTRY(OSC "17;%s" BEL, "change-highlight-background-color-bel")
        ENTRY(OSC "18;%s" BEL, "change-tek-cursor-color-bel")
        ENTRY(OSC "19;%s" BEL, "change-highlight-foreground-color-bel")
        ENTRY(OSC "46;%s" BEL, "change-logfile")
        ENTRY(OSC "50;#%d" BEL, "change-font-number")
        ENTRY(OSC "50;%s" BEL, "change-font-name")
        ENTRY(OSC "104" BEL, "reset-color")
        ENTRY(OSC "104;%m" BEL, "reset-color")
        ENTRY(OSC "110" BEL, "reset-foreground-color")
        ENTRY(OSC "111" BEL, "reset-background-color")
        ENTRY(OSC "112" BEL, "reset-cursor-background-color")
        ENTRY(OSC "113" BEL, "reset-mouse-cursor-foreground-color")
        ENTRY(OSC "114" BEL, "reset-mouse-cursor-background-color")
        ENTRY(OSC "115" BEL, "reset-tek-foreground-color")
        ENTRY(OSC "116" BEL, "reset-tek-background-color")
        ENTRY(OSC "117" BEL, "reset-highlight-background-color")
        ENTRY(OSC "118" BEL, "reset-tek-cursor-color")
        ENTRY(OSC "119" BEL, "reset-highlight-foreground-color")
        ENTRY(OSC "133;%s" BEL, "iterm2-133")
        ENTRY(OSC "777;%s" BEL, "urxvt-777")
        ENTRY(OSC "1337;%s" BEL, "iterm2-1337")

        COMMENT(/* Set text parameters, ST-terminated versions. */)
        ENTRY(OSC ";%s" ST, "set-icon-and-window-title") COMMENT(/* undocumented default */)
        ENTRY(OSC "0;%s" ST, "set-icon-and-window-title")
        ENTRY(OSC "1;%s" ST, "set-icon-title")
        ENTRY(OSC "2;%s" ST, "set-window-title")
        ENTRY(OSC "3;%s" ST, "set-xproperty")
        ENTRY(OSC "4;%s" ST, "change-color-st")
        ENTRY(OSC "6;%s" ST, "set-current-file-uri")
        ENTRY(OSC "7;%s" ST, "set-current-directory-uri")
        ENTRY(OSC "8;%s;%s" ST, "set-current-hyperlink")
        ENTRY(OSC "10;%s" ST, "change-foreground-color-st")
        ENTRY(OSC "11;%s" ST, "change-background-color-st")
        ENTRY(OSC "12;%s" ST, "change-cursor-background-color-st")
        ENTRY(OSC "13;%s" ST, "change-mouse-cursor-foreground-color-st")
        ENTRY(OSC "14;%s" ST, "change-mouse-cursor-background-color-st")
        ENTRY(OSC "15;%s" ST, "change-tek-foreground-color-st")
        ENTRY(OSC "16;%s" ST, "change-tek-background-color-st")
        ENTRY(OSC "17;%s" ST, "change-highlight-background-color-st")
        ENTRY(OSC "18;%s" ST, "change-tek-cursor-color-st")
        ENTRY(OSC "19;%s" ST, "change-highlight-foreground-color-st")
        ENTRY(OSC "46;%s" ST, "change-logfile")
        ENTRY(OSC "50;#%d" ST, "change-font-number")
        ENTRY(OSC "50;%s" ST, "change-font-name")
        ENTRY(OSC "104" ST, "reset-color")
        ENTRY(OSC "104;%m" ST, "reset-color")
        ENTRY(OSC "110" ST, "reset-foreground-color")
        ENTRY(OSC "111" ST, "reset-background-color")
        ENTRY(OSC "112" ST, "reset-cursor-background-color")
        ENTRY(OSC "113" ST, "reset-mouse-cursor-foreground-color")
        ENTRY(OSC "114" ST, "reset-mouse-cursor-background-color")
        ENTRY(OSC "115" ST, "reset-tek-foreground-color")
        ENTRY(OSC "116" ST, "reset-tek-background-color")
        ENTRY(OSC "117" ST, "reset-highlight-background-color")
        ENTRY(OSC "118" ST, "reset-tek-cursor-color")
        ENTRY(OSC "119" ST, "reset-highlight-foreground-color")
        ENTRY(OSC "133;%s" ST, "iterm2-133")
        ENTRY(OSC "777;%s" ST, "urxvt-777")
        ENTRY(OSC "1337;%s" ST, "iterm2-1337")

        COMMENT(/* These may be bogus, I can't find docs for them anywhere (#104154). */)
        ENTRY(OSC "21;%s" BEL, "set-text-property-21")
        ENTRY(OSC "2L;%s" BEL, "set-text-property-2L")
        ENTRY(OSC "21;%s" ST, "set-text-property-21")
        ENTRY(OSC "2L;%s" ST, "set-text-property-2L")

        "\0";

#undef ENTRY
#undef COMMENT
