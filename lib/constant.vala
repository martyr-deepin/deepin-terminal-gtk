/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2016 Deepin, Inc.
 *               2011 ~ 2016 Wang Yong
 *
 * Author:     Wang Yong <wangyong@deepin.com>
 * Maintainer: Wang Yong <wangyong@deepin.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */ 

public class Constant {
    public static double TERMINAL_MIN_OPACITY = 0.2;
    public static int ACTIVE_TAB_UNDERLINE_HEIGHT = 2;
    public static int CLOSE_BUTTON_MARGIN_RIGHT = 3;
    public static int CLOSE_BUTTON_MARGIN_TOP = 3;
    public static int CLOSE_BUTTON_WIDTH = 27;
    public static int FONT_MAX_SIZE = 50;
    public static int FONT_MIN_SIZE = 5;
    public static int MAX_SCROLL_LINES = 1000;
    public static int PREFERENCE_SLIDEBAR_WIDTH = 160;
    public static int REMOTE_PANEL_SEARCHBAR_HEIGHT = 36;
    public static int RESPONSE_RADIUS = 8;
    public static int SLIDER_WIDTH = 280;
    public static int TITLEBAR_HEIGHT = 40;

    public static string USERCHARS = "-[:alnum:]";
    public static string USERCHARS_CLASS = "[" + USERCHARS + "]";
    public static string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
    public static string HOSTCHARS_CLASS = "[-[:alnum:]]";
    public static string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
    public static string PORT = "(?:\\:[[:digit:]]{1,5})?";
    public static string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
    public static string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
    public static string SCHEME = """(?:news:|telnet:|nntp:|file:\/|https?:|ftps?:|sftp:|webcal:
                                 |irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:
                                 |git\+ssh:|bzr:|bzr\+ssh:|svn:|svn\+ssh:|hg:|mailto:|magnet:)""";

    public static string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
    public static string URLPATH = "(?:(/" + PATHCHARS_CLASS + "+(?:[(]" + PATHCHARS_CLASS + "*[)])*" + PATHCHARS_CLASS + "*)*" + PATHTERM_CLASS + ")?";
    public static string[] REGEX_STRINGS = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+"
        };
}                         
