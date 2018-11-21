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

#define PCRE2_CODE_UNIT_WIDTH 0
#include <pcre2.h>

/* Assert compatibility of PCRE2 and GLib types */
G_STATIC_ASSERT(sizeof(PCRE2_UCHAR8) == sizeof (guint8));
G_STATIC_ASSERT(sizeof(PCRE2_SIZE) == sizeof (gsize));
G_STATIC_ASSERT(PCRE2_UNSET == (gsize)-1);
G_STATIC_ASSERT(PCRE2_ZERO_TERMINATED == (gsize)-1);
