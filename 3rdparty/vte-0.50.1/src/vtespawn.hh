/* gspawn.h - Process launching
 *
 *  Copyright 2000 Red Hat, Inc.
 *
 * GLib is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * GLib is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with GLib; see the file COPYING.LIB.  If not, write
 * to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#pragma once

#include <glib.h>

gboolean vte_spawn_async_cancellable (const gchar          *working_directory,
                                      gchar               **argv,
                                      gchar               **envp,
                                      GSpawnFlags           flags,
                                      GSpawnChildSetupFunc  child_setup,
                                      gpointer              user_data,
                                      GPid                 *child_pid,
                                      gint                  timeout,
                                      GPollFD              *pollfd,
                                      GError              **error);

gboolean vte_spawn_async_with_pipes_cancellable (const gchar          *working_directory,
                                                 gchar               **argv,
                                                 gchar               **envp,
                                                 GSpawnFlags           flags,
                                                 GSpawnChildSetupFunc  child_setup,
                                                 gpointer              user_data,
                                                 GPid                 *child_pid,
                                                 gint                 *standard_input,
                                                 gint                 *standard_output,
                                                 gint                 *standard_error,
                                                 gint                  timeout,
                                                 GPollFD              *pollfd,
                                                 GError              **error);
