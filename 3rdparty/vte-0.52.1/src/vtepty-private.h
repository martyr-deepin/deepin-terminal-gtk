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

G_BEGIN_DECLS

gboolean __vte_pty_spawn (VtePty *pty,
                          const char *working_directory,
                          char **argv,
                          char **envv,
                          GSpawnFlags spawn_flags,
                          GSpawnChildSetupFunc child_setup,
                          gpointer child_setup_data,
                          GPid *child_pid /* out */,
                          int timeout,
                          GCancellable *cancellable,
                          GError **error);

G_END_DECLS
