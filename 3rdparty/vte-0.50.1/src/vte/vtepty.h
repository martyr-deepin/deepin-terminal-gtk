/*
 * Copyright © 2009, 2010 Christian Persch
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

#ifndef __VTE_VTE_PTY_H__
#define __VTE_VTE_PTY_H__

#if !defined (__VTE_VTE_H_INSIDE__) && !defined (VTE_COMPILATION)
#error "Only <vte/vte.h> can be included directly."
#endif

#include <gio/gio.h>

#include "vteenums.h"
#include "vtemacros.h"

G_BEGIN_DECLS

#define VTE_SPAWN_NO_PARENT_ENVV (1 << 25)

_VTE_PUBLIC
GQuark vte_pty_error_quark (void);

/**
 * VTE_PTY_ERROR:
 *
 * Error domain for VTE PTY errors. Errors in this domain will be from the #VtePtyError
 * enumeration. See #GError for more information on error domains.
 */
#define VTE_PTY_ERROR (vte_pty_error_quark ())

/* VTE PTY object */

#define VTE_TYPE_PTY            (vte_pty_get_type())
#define VTE_PTY(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), VTE_TYPE_PTY, VtePty))
#define VTE_PTY_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass),  VTE_TYPE_PTY, VtePtyClass))
#define VTE_IS_PTY(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), VTE_TYPE_PTY))
#define VTE_IS_PTY_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass),  VTE_TYPE_PTY))
#define VTE_PTY_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj),  VTE_TYPE_PTY, VtePtyClass))

typedef struct _VtePty        VtePty;
typedef struct _VtePtyClass   VtePtyClass;

_VTE_PUBLIC
GType vte_pty_get_type (void);

_VTE_PUBLIC
VtePty *vte_pty_new_sync (VtePtyFlags flags,
                          GCancellable *cancellable,
                          GError **error);

_VTE_PUBLIC
VtePty *vte_pty_new_foreign_sync (int fd,
                                  GCancellable *cancellable,
                                  GError **error);

_VTE_PUBLIC
int vte_pty_get_fd (VtePty *pty) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
void vte_pty_child_setup (VtePty *pty) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
gboolean vte_pty_get_size (VtePty *pty,
                           int *rows,
                           int *columns,
                           GError **error) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
gboolean vte_pty_set_size (VtePty *pty,
                           int rows,
                           int columns,
                           GError **error) _VTE_GNUC_NONNULL(1);

_VTE_PUBLIC
gboolean vte_pty_set_utf8 (VtePty *pty,
                           gboolean utf8,
                           GError **error) _VTE_GNUC_NONNULL(1);

#if GLIB_CHECK_VERSION(2, 44, 0)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(VtePty, g_object_unref)
#endif

_VTE_PUBLIC
void vte_pty_spawn_async(VtePty *pty,
                         const char *working_directory,
                         char **argv,
                         char **envv,
                         GSpawnFlags spawn_flags,
                         GSpawnChildSetupFunc child_setup,
                         gpointer child_setup_data,
                         GDestroyNotify child_setup_data_destroy,
                         int timeout,
                         GCancellable *cancellable,
                         GAsyncReadyCallback callback,
                         gpointer user_data) _VTE_GNUC_NONNULL(1) _VTE_GNUC_NONNULL(3);

_VTE_PUBLIC
gboolean vte_pty_spawn_finish(VtePty *pty,
                              GAsyncResult *result,
                              GPid *child_pid /* out */,
                              GError **error) _VTE_GNUC_NONNULL(1) _VTE_GNUC_NONNULL(2);

G_END_DECLS

#endif /* __VTE_VTE_PTY_H__ */
