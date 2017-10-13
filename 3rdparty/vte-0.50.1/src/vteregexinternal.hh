/*
 * Copyright © 2015 Christian Persch
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
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

enum class VteRegexPurpose {
        match,
        search
};

gboolean _vte_regex_has_purpose(VteRegex *regex,
                                VteRegexPurpose purpose);

gboolean _vte_regex_get_jited(VteRegex *regex);

guint32 _vte_regex_get_compile_flags (VteRegex *regex);

const pcre2_code_8 *_vte_regex_get_pcre (VteRegex *regex);

/* GRegex translation */
VteRegex *_vte_regex_new_gregex(VteRegexPurpose purpose,
                                GRegex *gregex);

guint32 _vte_regex_translate_gregex_match_flags(GRegexMatchFlags flags);
