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

#ifndef __VTE_VTE_REGEX_H__
#define __VTE_VTE_REGEX_H__

#if !defined (__VTE_VTE_H_INSIDE__) && !defined (VTE_COMPILATION)
#error "Only <vte/vte.h> can be included directly."
#endif

#include <glib.h>
#include <glib-object.h>

#include "vtemacros.h"

G_BEGIN_DECLS

typedef struct _VteRegex VteRegex;

#define VTE_TYPE_REGEX (vte_regex_get_type())

_VTE_PUBLIC
GType vte_regex_get_type (void);

#define VTE_REGEX_ERROR (vte_regex_error_quark())

_VTE_PUBLIC
GQuark vte_regex_error_quark (void);

/* This is PCRE2_NO_UTF_CHECK | PCRE2_UTF | PCRE2_NEVER_BACKSLASH_C */
#define VTE_REGEX_FLAGS_DEFAULT (0x00080000u | 0x40000000u | 0x00100000u)

_VTE_PUBLIC
VteRegex *vte_regex_ref      (VteRegex *regex) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
VteRegex *vte_regex_unref    (VteRegex *regex) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
VteRegex *vte_regex_new_for_match (const char *pattern,
                                   gssize      pattern_length,
                                   guint32     flags,
                                   GError    **error) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
VteRegex *vte_regex_new_for_search (const char *pattern,
                                    gssize      pattern_length,
                                    guint32     flags,
                                    GError    **error) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
gboolean  vte_regex_jit     (VteRegex *regex,
                             guint32   flags,
                             GError  **error) _VTE_GNUC_NONNULL(1);

#if GLIB_CHECK_VERSION(2, 44, 0)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(VteRegex, vte_regex_unref)
#endif

G_END_DECLS

#endif /* __VTE_VTE_REGEX_H__ */
