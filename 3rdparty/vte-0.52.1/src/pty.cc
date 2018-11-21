/*
 * Copyright (C) 2001,2002 Red Hat, Inc.
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

/**
 * SECTION: vte-pty
 * @short_description: Functions for starting a new process on a new pseudo-terminal and for
 * manipulating pseudo-terminals
 *
 * The terminal widget uses these functions to start commands with new controlling
 * pseudo-terminals and to resize pseudo-terminals.
 */

#include <config.h>

#include <vte/vte.h>
#include "vtepty-private.h"
#include "vtetypes.hh"
#include "vtespawn.hh"

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#ifdef HAVE_SYS_TERMIOS_H
#include <sys/termios.h>
#endif
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#ifdef HAVE_SYS_SYSLIMITS_H
#include <sys/syslimits.h>
#endif
#include <signal.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef HAVE_TERMIOS_H
#include <termios.h>
#endif
#include <unistd.h>
#ifdef HAVE_UTIL_H
#include <util.h>
#endif
#ifdef HAVE_PTY_H
#include <pty.h>
#endif
#if defined(__sun) && defined(HAVE_STROPTS_H)
#include <stropts.h>
#endif
#include <glib.h>
#include <gio/gio.h>
#include "debug.h"

#include <glib/gi18n-lib.h>

/* NSIG isn't in POSIX, so if it doesn't exist use this here. See bug #759196 */
#ifndef NSIG
#define NSIG (8 * sizeof(sigset_t))
#endif

#define VTE_VERSION_NUMERIC ((VTE_MAJOR_VERSION) * 10000 + (VTE_MINOR_VERSION) * 100 + (VTE_MICRO_VERSION))

#if !GLIB_CHECK_VERSION(2, 42, 0)
#define G_PARAM_EXPLICIT_NOTIFY 0
#endif

#define I_(string) (g_intern_static_string(string))

typedef struct _VtePtyPrivate VtePtyPrivate;

typedef struct {
	GSpawnChildSetupFunc extra_child_setup;
	gpointer extra_child_setup_data;
} VtePtyChildSetupData;

/**
 * VtePty:
 */
struct _VtePty {
        GObject parent_instance;

        /* <private> */
        VtePtyPrivate *priv;
};

struct _VtePtyPrivate {
        VtePtyFlags flags;
        int pty_fd;

        VtePtyChildSetupData child_setup_data;

        guint utf8 : 1;
        guint foreign : 1;
};

struct _VtePtyClass {
        GObjectClass parent_class;
};

/**
 * vte_pty_child_setup:
 * @pty: a #VtePty
 *
 * FIXMEchpe
 */
void
vte_pty_child_setup (VtePty *pty)
{
        VtePtyPrivate *priv = pty->priv;
	VtePtyChildSetupData *data = &priv->child_setup_data;

        /* Unblock all signals */
        sigset_t set;
        sigemptyset(&set);
        if (pthread_sigmask(SIG_SETMASK, &set, nullptr) == -1) {
                _vte_debug_print(VTE_DEBUG_PTY, "Failed to unblock signals: %m");
                _exit(127);
        }

        /* Reset the handlers for all signals to their defaults.  The parent
         * (or one of the libraries it links to) may have changed one to be ignored. */
        for (int n = 1; n < NSIG; n++) {
                if (n == SIGSTOP || n == SIGKILL)
                        continue;

                signal(n, SIG_DFL);
        }

        auto masterfd = priv->pty_fd;
        if (masterfd == -1)
                _exit(127);

        if (grantpt(masterfd) != 0) {
                _vte_debug_print(VTE_DEBUG_PTY, "%s failed: %m", "grantpt");
                _exit(127);
        }

	if (unlockpt(masterfd) != 0) {
                _vte_debug_print(VTE_DEBUG_PTY, "%s failed: %m", "unlockpt");
                _exit(127);
        }

	char *name = ptsname(masterfd);
        if (name == nullptr) {
		_vte_debug_print(VTE_DEBUG_PTY, "%s failed: %m\n", "ptsname");
		_exit(127);
	}

        _vte_debug_print (VTE_DEBUG_PTY,
                          "Setting up child pty: master FD = %d name = %s\n",
                          masterfd, name);

        int fd = open(name, O_RDWR);
        if (fd == -1) {
                _vte_debug_print (VTE_DEBUG_PTY, "Failed to open PTY: %m\n");
                _exit(127);
        }

	/* Start a new session and become process-group leader. */
#if defined(HAVE_SETSID) && defined(HAVE_SETPGID)
	_vte_debug_print (VTE_DEBUG_PTY, "Starting new session\n");
	setsid();
	setpgid(0, 0);
#endif

#ifdef TIOCSCTTY
	/* TIOCSCTTY is defined?  Let's try that, too. */
	ioctl(fd, TIOCSCTTY, fd);
#endif

#if defined(__sun) && defined(HAVE_STROPTS_H)
	if (isastream (fd) == 1) {
		if ((ioctl(fd, I_FIND, "ptem") == 0) &&
				(ioctl(fd, I_PUSH, "ptem") == -1)) {
			_exit (127);
		}
		if ((ioctl(fd, I_FIND, "ldterm") == 0) &&
				(ioctl(fd, I_PUSH, "ldterm") == -1)) {
			_exit (127);
		}
		if ((ioctl(fd, I_FIND, "ttcompat") == 0) &&
				(ioctl(fd, I_PUSH, "ttcompat") == -1)) {
			perror ("ioctl (fd, I_PUSH, \"ttcompat\")");
			_exit (127);
		}
	}
#endif

	/* now setup child I/O through the tty */
	if (fd != STDIN_FILENO) {
		if (dup2(fd, STDIN_FILENO) != STDIN_FILENO){
			_exit (127);
		}
	}
	if (fd != STDOUT_FILENO) {
		if (dup2(fd, STDOUT_FILENO) != STDOUT_FILENO){
			_exit (127);
		}
	}
	if (fd != STDERR_FILENO) {
		if (dup2(fd, STDERR_FILENO) != STDERR_FILENO){
			_exit (127);
		}
	}

	/* Close the original FD, unless it's one of the stdio descriptors */
	if (fd != STDIN_FILENO &&
			fd != STDOUT_FILENO &&
			fd != STDERR_FILENO) {
		close(fd);
	}

        /* Now set the TERM environment variable */
        /* FIXME: Setting environment here seems to have no effect, the merged envp2 will override on exec.
         * By the way, we'd need to set the one from there, if any. */
        g_setenv("TERM", VTE_DEFAULT_TERM, TRUE);

        char version[7];
        g_snprintf (version, sizeof (version), "%u", VTE_VERSION_NUMERIC);
        g_setenv ("VTE_VERSION", version, TRUE);

	/* Finally call an extra child setup */
	if (data->extra_child_setup) {
		data->extra_child_setup (data->extra_child_setup_data);
	}
}

/* TODO: clean up the spawning
 * - replace current env rather than adding!
 */

/*
 * __vte_pty_merge_environ:
 * @envp: environment vector
 * @inherit: whether to use the parent environment
 *
 * Merges @envp to the parent environment, and returns a new environment vector.
 *
 * Returns: a newly allocated string array. Free using g_strfreev()
 */
static gchar **
__vte_pty_merge_environ (char **envp,
                         const char *directory,
                         gboolean inherit)
{
	GHashTable *table;
        GHashTableIter iter;
        char *name, *value;
	gchar **parent_environ;
	GPtrArray *array;
	gint i;

	table = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	if (inherit) {
		parent_environ = g_listenv ();
		for (i = 0; parent_environ[i] != NULL; i++) {
			g_hash_table_replace (table,
				              g_strdup (parent_environ[i]),
					      g_strdup (g_getenv (parent_environ[i])));
		}
		g_strfreev (parent_environ);
	}

        /* Make sure the one in envp overrides the default. */
        g_hash_table_replace (table, g_strdup ("TERM"), g_strdup (VTE_DEFAULT_TERM));

	if (envp != NULL) {
		for (i = 0; envp[i] != NULL; i++) {
			name = g_strdup (envp[i]);
			value = strchr (name, '=');
			if (value) {
				*value = '\0';
				value = g_strdup (value + 1);
			}
			g_hash_table_replace (table, name, value);
		}
	}

        g_hash_table_replace (table, g_strdup ("VTE_VERSION"), g_strdup_printf ("%u", VTE_VERSION_NUMERIC));

	/* Always set this ourself, not allowing replacing from envp */
	g_hash_table_replace(table, g_strdup("COLORTERM"), g_strdup("truecolor"));

        /* We need to put the working directory also in PWD, so that
         * e.g. bash starts in the right directory if @directory is a symlink.
         * See bug #502146 and #758452.
         */
        if (directory)
                g_hash_table_replace(table, g_strdup("PWD"), g_strdup(directory));

	array = g_ptr_array_sized_new (g_hash_table_size (table) + 1);
        g_hash_table_iter_init(&iter, table);
        while (g_hash_table_iter_next(&iter, (void**) &name, (void**) &value)) {
                g_ptr_array_add (array, g_strconcat (name, "=", value, nullptr));
        }
        g_assert(g_hash_table_size(table) == array->len);
	g_hash_table_destroy (table);
	g_ptr_array_add (array, NULL);

	return (gchar **) g_ptr_array_free (array, FALSE);
}

/*
 * __vte_pty_spawn:
 * @pty: a #VtePty
 * @directory: the name of a directory the command should start in, or %NULL
 *   to use the cwd
 * @argv: child's argument vector
 * @envv: a list of environment variables to be added to the environment before
 *   starting the process, or %NULL
 * @spawn_flags: flags from #GSpawnFlags
 * @child_setup: function to run in the child just before exec()
 * @child_setup_data: user data for @child_setup
 * @child_pid: a location to store the child PID, or %NULL
 * @timeout: a timeout value in ms, or %NULL
 * @cancellable: a #GCancellable, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Uses g_spawn_async() to spawn the command in @argv. The child's environment will
 * be the parent environment with the variables in @envv set afterwards.
 *
 * Enforces the vte_terminal_watch_child() requirements by adding
 * %G_SPAWN_DO_NOT_REAP_CHILD to @spawn_flags.
 *
 * Note that the %G_SPAWN_LEAVE_DESCRIPTORS_OPEN flag is not supported;
 * it will be cleared!
 *
 * If spawning the command in @working_directory fails because the child
 * is unable to chdir() to it, falls back trying to spawn the command
 * in the parent's working directory.
 *
 * Returns: %TRUE on success, or %FALSE on failure with @error filled in
 */
gboolean
__vte_pty_spawn (VtePty *pty,
                 const char *directory,
                 char **argv,
                 char **envv,
                 GSpawnFlags spawn_flags_,
                 GSpawnChildSetupFunc child_setup,
                 gpointer child_setup_data,
                 GPid *child_pid /* out */,
                 int timeout,
                 GCancellable *cancellable,
                 GError **error)
{
	VtePtyPrivate *priv = pty->priv;
        VtePtyChildSetupData *data = &priv->child_setup_data;
        guint spawn_flags = (guint) spawn_flags_;
	gboolean ret = TRUE;
        gboolean inherit_envv;
        char **envp2;
        gint i;
        GError *err = NULL;
        GPollFD pollfd;

        if (cancellable && !g_cancellable_make_pollfd(cancellable, &pollfd)) {
                vte::util::restore_errno errsv;
                g_set_error(error,
                            G_IO_ERROR,
                            g_io_error_from_errno(errsv),
                            "Failed to make cancellable pollfd: %s",
                            g_strerror(errsv));
                return FALSE;
        }

        spawn_flags |= G_SPAWN_DO_NOT_REAP_CHILD;

        /* FIXMEchpe: Enforce this until I've checked our code to make sure
         * it doesn't leak out internal FDs into the child this way.
         */
        spawn_flags &= ~G_SPAWN_LEAVE_DESCRIPTORS_OPEN;

        inherit_envv = (spawn_flags & VTE_SPAWN_NO_PARENT_ENVV) == 0;
        spawn_flags &= ~VTE_SPAWN_NO_PARENT_ENVV;

        /* add the given environment to the childs */
        envp2 = __vte_pty_merge_environ (envv, directory, inherit_envv);

        _VTE_DEBUG_IF (VTE_DEBUG_MISC) {
                g_printerr ("Spawning command:\n");
                for (i = 0; argv[i] != NULL; i++) {
                        g_printerr ("    argv[%d] = %s\n", i, argv[i]);
                }
                for (i = 0; envp2[i] != NULL; i++) {
                        g_printerr ("    env[%d] = %s\n", i, envp2[i]);
                }
                g_printerr ("    directory: %s\n",
                            directory ? directory : "(none)");
        }

	data->extra_child_setup = child_setup;
	data->extra_child_setup_data = child_setup_data;

        ret = vte_spawn_async_with_pipes_cancellable(directory,
                                                     argv, envp2,
                                                     (GSpawnFlags)spawn_flags,
                                                     (GSpawnChildSetupFunc)vte_pty_child_setup,
                                                     pty,
                                                     child_pid,
                                                     NULL, NULL, NULL,
                                                     timeout,
                                                     cancellable ? &pollfd : NULL,
                                                     &err);
        if (!ret &&
            directory != NULL &&
            g_error_matches(err, G_SPAWN_ERROR, G_SPAWN_ERROR_CHDIR)) {
                /* try spawning in our working directory */
                g_clear_error(&err);
                ret = vte_spawn_async_with_pipes_cancellable(NULL,
                                                             argv, envp2,
                                                             (GSpawnFlags)spawn_flags,
                                                             (GSpawnChildSetupFunc)vte_pty_child_setup,
                                                             pty,
                                                             child_pid,
                                                             NULL, NULL, NULL,
                                                             timeout,
                                                             cancellable ? &pollfd : NULL,
                                                             &err);
        }

        g_strfreev (envp2);

	data->extra_child_setup = NULL;
	data->extra_child_setup_data = NULL;

        if (cancellable)
                g_cancellable_release_fd(cancellable);

        if (ret)
                return TRUE;

        g_propagate_error (error, err);
        return FALSE;
}

/**
 * vte_pty_set_size:
 * @pty: a #VtePty
 * @rows: the desired number of rows
 * @columns: the desired number of columns
 * @error: (allow-none): return location to store a #GError, or %NULL
 *
 * Attempts to resize the pseudo terminal's window size.  If successful, the
 * OS kernel will send #SIGWINCH to the child process group.
 *
 * If setting the window size failed, @error will be set to a #GIOError.
 *
 * Returns: %TRUE on success, %FALSE on failure with @error filled in
 */
gboolean
vte_pty_set_size(VtePty *pty,
                 int rows,
                 int columns,
                 GError **error)
{
	struct winsize size;
        int master;
	int ret;

        g_return_val_if_fail(VTE_IS_PTY(pty), FALSE);

        master = vte_pty_get_fd(pty);

	memset(&size, 0, sizeof(size));
	size.ws_row = rows > 0 ? rows : 24;
	size.ws_col = columns > 0 ? columns : 80;
	_vte_debug_print(VTE_DEBUG_PTY,
			"Setting size on fd %d to (%d,%d).\n",
			master, columns, rows);
	ret = ioctl(master, TIOCSWINSZ, &size);
	if (ret != 0) {
                vte::util::restore_errno errsv;

                g_set_error(error, G_IO_ERROR,
                            g_io_error_from_errno(errsv),
                            "Failed to set window size: %s",
                            g_strerror(errsv));

		_vte_debug_print(VTE_DEBUG_PTY,
				"Failed to set size on %d: %s.\n",
				master, g_strerror(errsv));
                return FALSE;
	}

        return TRUE;
}

/**
 * vte_pty_get_size:
 * @pty: a #VtePty
 * @rows: (out) (allow-none): a location to store the number of rows, or %NULL
 * @columns: (out) (allow-none): a location to store the number of columns, or %NULL
 * @error: return location to store a #GError, or %NULL
 *
 * Reads the pseudo terminal's window size.
 *
 * If getting the window size failed, @error will be set to a #GIOError.
 *
 * Returns: %TRUE on success, %FALSE on failure with @error filled in
 */
gboolean
vte_pty_get_size(VtePty *pty,
                 int *rows,
                 int *columns,
                 GError **error)
{
	struct winsize size;
        int master;
	int ret;

        g_return_val_if_fail(VTE_IS_PTY(pty), FALSE);

        master = vte_pty_get_fd(pty);

	memset(&size, 0, sizeof(size));
	ret = ioctl(master, TIOCGWINSZ, &size);
	if (ret == 0) {
		if (columns != NULL) {
			*columns = size.ws_col;
		}
		if (rows != NULL) {
			*rows = size.ws_row;
		}
		_vte_debug_print(VTE_DEBUG_PTY,
				"Size on fd %d is (%d,%d).\n",
				master, size.ws_col, size.ws_row);
                return TRUE;
	} else {
                vte::util::restore_errno errsv;

                g_set_error(error, G_IO_ERROR,
                            g_io_error_from_errno(errsv),
                            "Failed to get window size: %s",
                            g_strerror(errsv));

		_vte_debug_print(VTE_DEBUG_PTY,
				"Failed to read size from fd %d: %s\n",
				master, g_strerror(errsv));
                return FALSE;
	}
}

static int
fd_set_cloexec(int fd)
{
        int flags = fcntl(fd, F_GETFD, 0);
        if (flags < 0)
                return flags;

        return fcntl(fd, F_SETFD, flags | FD_CLOEXEC);
}

static int
fd_set_nonblocking(int fd)
{
        int flags = fcntl(fd, F_GETFL, 0);
        if (flags < 0)
                return -1;
        if ((flags & O_NONBLOCK) != 0)
                return 0;
        return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

static int
fd_set_cpkt(int fd)
{
        /* tty_ioctl(4) -> every read() gives an extra byte at the beginning
         * notifying us of stop/start (^S/^Q) events. */
        int one = 1;
        return ioctl(fd, TIOCPKT, &one);
}

static int
fd_setup(int fd)
{
        if (fd_set_cloexec(fd) < 0) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "Setting CLOEXEC flag", g_strerror(errsv));
                return -1;
        }

        if (fd_set_nonblocking(fd) < 0) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "Setting O_NONBLOCK flag", g_strerror(errsv));
                return -1;
        }

        if (fd_set_cpkt(fd) < 0) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "ioctl(TIOCPKT)", g_strerror(errsv));
                return -1;
        }

        return 0;
}

/*
 * _vte_pty_open_posix:
 * @pty: a #VtePty
 * @error: a location to store a #GError, or %NULL
 *
 * Opens a new file descriptor to a new PTY master.
 *
 * Returns: the new PTY's master FD, or -1
 */
static int
_vte_pty_open_posix(void)
{
	/* Attempt to open the master. */
        vte::util::smart_fd fd;
        fd = posix_openpt(O_RDWR | O_NOCTTY | O_NONBLOCK | O_CLOEXEC);
#ifndef __linux__
        /* Other kernels may not support CLOEXEC or NONBLOCK above, so try to fall back */
        bool need_cloexec = false, need_nonblocking = false;
        if (fd == -1 && errno == EINVAL) {
                /* Try without NONBLOCK and apply the flag afterward */
                need_nonblocking = true;
                fd = posix_openpt(O_RDWR | O_NOCTTY | O_CLOEXEC);
                if (fd == -1 && errno == EINVAL) {
                        /* Try without CLOEXEC and apply the flag afterwards */
                        need_cloexec = true;
                        fd = posix_openpt(O_RDWR | O_NOCTTY);
                }
        }
#endif /* !linux */

        if (fd == -1) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "posix_openpt", g_strerror(errsv));
                return -1;
        }

#ifndef __linux__
        if (need_cloexec && fd_set_cloexec(fd) < 0) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "Setting CLOEXEC flag", g_strerror(errsv));
                return -1;
        }

        if (need_nonblocking && fd_set_nonblocking(fd) < 0) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "Setting NONBLOCK flag", g_strerror(errsv));
                return -1;
        }
#endif /* !linux */

        if (fd_set_cpkt(fd) < 0) {
                vte::util::restore_errno errsv;
                _vte_debug_print(VTE_DEBUG_PTY,
                                 "%s failed: %s", "ioctl(TIOCPKT)", g_strerror(errsv));
                return -1;
        }

	_vte_debug_print(VTE_DEBUG_PTY, "Allocated pty on fd %d.\n", (int)fd);

        return fd.steal();
}

static int
_vte_pty_open_foreign(int masterfd /* consumed */)
{
        vte::util::smart_fd fd(masterfd);
        if (fd == -1) {
                errno = EBADF;
                return -1;
        }

        if (fd_setup(fd) < 0)
                return -1;

        return fd.steal();
}

/**
 * vte_pty_set_utf8:
 * @pty: a #VtePty
 * @utf8: whether or not the pty is in UTF-8 mode
 * @error: (allow-none): return location to store a #GError, or %NULL
 *
 * Tells the kernel whether the terminal is UTF-8 or not, in case it can make
 * use of the info.  Linux 2.6.5 or so defines IUTF8 to make the line
 * discipline do multibyte backspace correctly.
 *
 * Returns: %TRUE on success, %FALSE on failure with @error filled in
 */
gboolean
vte_pty_set_utf8(VtePty *pty,
                 gboolean utf8,
                 GError **error)
{
#if defined(HAVE_TCSETATTR) && defined(IUTF8)
        VtePtyPrivate *priv;
	struct termios tio;
	tcflag_t saved_cflag;

        g_return_val_if_fail(VTE_IS_PTY(pty), FALSE);

        priv = pty->priv;
        g_return_val_if_fail (priv->pty_fd != -1, FALSE);

        if (tcgetattr(priv->pty_fd, &tio) == -1) {
                vte::util::restore_errno errsv;
                g_set_error(error, G_IO_ERROR, g_io_error_from_errno(errsv),
                            "%s failed: %s", "tcgetattr", g_strerror(errsv));
                return FALSE;
        }

        saved_cflag = tio.c_iflag;
        if (utf8) {
                tio.c_iflag |= IUTF8;
        } else {
              tio.c_iflag &= ~IUTF8;
        }

        /* Only set the flag if it changes */
        if (saved_cflag != tio.c_iflag &&
            tcsetattr(priv->pty_fd, TCSANOW, &tio) == -1) {
                vte::util::restore_errno errsv;
                g_set_error(error, G_IO_ERROR, g_io_error_from_errno(errsv),
                            "%s failed: %s", "tcgetattr", g_strerror(errsv));
                return FALSE;
	}
#endif

        return TRUE;
}

/**
 * vte_pty_close:
 * @pty: a #VtePty
 *
 * Since 0.42 this is a no-op.
 *
 * Deprecated: 0.42
 */
void
vte_pty_close (VtePty *pty)
{
}

/* VTE PTY class */

enum {
        PROP_0,
        PROP_FLAGS,
        PROP_FD,
};

/* GInitable impl */

static gboolean
vte_pty_initable_init (GInitable *initable,
                       GCancellable *cancellable,
                       GError **error)
{
        VtePty *pty = VTE_PTY (initable);
        VtePtyPrivate *priv = pty->priv;

        if (cancellable != NULL) {
                g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
                                    "Cancellable initialisation not supported");
                return FALSE;
        }

        if (priv->foreign) {
                priv->pty_fd = _vte_pty_open_foreign(priv->pty_fd);
        } else {
                priv->pty_fd = _vte_pty_open_posix();
        }

        if (priv->pty_fd == -1) {
                vte::util::restore_errno errsv;
                g_set_error(error, G_IO_ERROR, g_io_error_from_errno(errsv),
                            "Failed to open PTY: %s", g_strerror(errsv));
                return FALSE;
        }

        return TRUE;
}

static void
vte_pty_initable_iface_init (GInitableIface  *iface)
{
        iface->init = vte_pty_initable_init;
}

/* GObjectClass impl */

G_DEFINE_TYPE_WITH_CODE (VtePty, vte_pty, G_TYPE_OBJECT,
                         G_ADD_PRIVATE (VtePty)
                         G_IMPLEMENT_INTERFACE (G_TYPE_INITABLE, vte_pty_initable_iface_init))

static void
vte_pty_init (VtePty *pty)
{
        VtePtyPrivate *priv;

        priv = pty->priv = (VtePtyPrivate *)vte_pty_get_instance_private (pty);

        priv->flags = VTE_PTY_DEFAULT;
        priv->pty_fd = -1;
        priv->foreign = FALSE;
}

static void
vte_pty_finalize (GObject *object)
{
        VtePty *pty = VTE_PTY (object);
        VtePtyPrivate *priv = pty->priv;

        /* Close the master FD */
        if (priv->pty_fd != -1) {
                close(priv->pty_fd);
        }

        G_OBJECT_CLASS (vte_pty_parent_class)->finalize (object);
}

static void
vte_pty_get_property (GObject    *object,
                       guint       property_id,
                       GValue     *value,
                       GParamSpec *pspec)
{
        VtePty *pty = VTE_PTY (object);
        VtePtyPrivate *priv = pty->priv;

        switch (property_id) {
        case PROP_FLAGS:
                g_value_set_flags(value, priv->flags);
                break;

        case PROP_FD:
                g_value_set_int(value, vte_pty_get_fd(pty));
                break;

        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
        }
}

static void
vte_pty_set_property (GObject      *object,
                       guint         property_id,
                       const GValue *value,
                       GParamSpec   *pspec)
{
        VtePty *pty = VTE_PTY (object);
        VtePtyPrivate *priv = pty->priv;

        switch (property_id) {
        case PROP_FLAGS:
                priv->flags = (VtePtyFlags) g_value_get_flags(value);
                break;

        case PROP_FD:
                priv->pty_fd = g_value_get_int(value);
                priv->foreign = (priv->pty_fd != -1);
                break;

        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        }
}

static void
vte_pty_class_init (VtePtyClass *klass)
{
        GObjectClass *object_class = G_OBJECT_CLASS (klass);

        object_class->set_property = vte_pty_set_property;
        object_class->get_property = vte_pty_get_property;
        object_class->finalize     = vte_pty_finalize;

        /**
         * VtePty:flags:
         *
         * Flags.
         */
        g_object_class_install_property
                (object_class,
                 PROP_FLAGS,
                 g_param_spec_flags ("flags", NULL, NULL,
                                     VTE_TYPE_PTY_FLAGS,
                                     VTE_PTY_DEFAULT,
                                     (GParamFlags) (G_PARAM_READWRITE |
                                                    G_PARAM_CONSTRUCT_ONLY |
                                                    G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY)));

        /**
         * VtePty:fd:
         *
         * The file descriptor of the PTY master.
         */
        g_object_class_install_property
                (object_class,
                 PROP_FD,
                 g_param_spec_int ("fd", NULL, NULL,
                                   -1, G_MAXINT, -1,
                                   (GParamFlags) (G_PARAM_READWRITE |
                                                  G_PARAM_CONSTRUCT_ONLY |
                                                  G_PARAM_STATIC_STRINGS | G_PARAM_EXPLICIT_NOTIFY)));
}

/* public API */

/**
 * vte_pty_error_quark:
 *
 * Error domain for VTE PTY errors. Errors in this domain will be from the #VtePtyError
 * enumeration. See #GError for more information on error domains.
 *
 * Returns: the error domain for VTE PTY errors
 */
GQuark
vte_pty_error_quark(void)
{
  static GQuark quark = 0;

  if (G_UNLIKELY (quark == 0))
    quark = g_quark_from_static_string("vte-pty-error");

  return quark;
}

/**
 * vte_pty_new_sync: (constructor)
 * @flags: flags from #VtePtyFlags
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Allocates a new pseudo-terminal.
 *
 * You can later use fork() or the g_spawn_async() family of functions
 * to start a process on the PTY.
 *
 * If using fork(), you MUST call vte_pty_child_setup() in the child.
 *
 * If using g_spawn_async() and friends, you MUST either use
 * vte_pty_child_setup() directly as the child setup function, or call
 * vte_pty_child_setup() from your own child setup function supplied.
 *
 * When using vte_terminal_spawn_sync() with a custom child setup
 * function, vte_pty_child_setup() will be called before the supplied
 * function; you must not call it again.
 *
 * Also, you MUST pass the %G_SPAWN_DO_NOT_REAP_CHILD flag.
 *
 * Returns: (transfer full): a new #VtePty, or %NULL on error with @error filled in
 */
VtePty *
vte_pty_new_sync (VtePtyFlags flags,
                  GCancellable *cancellable,
                  GError **error)
{
        return (VtePty *) g_initable_new (VTE_TYPE_PTY,
                                          cancellable,
                                          error,
                                          "flags", flags,
                                          NULL);
}

/**
 * vte_pty_new_foreign_sync: (constructor)
 * @fd: (transfer full): a file descriptor to the PTY
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Creates a new #VtePty for the PTY master @fd.
 *
 * No entry will be made in the lastlog, utmp or wtmp system files.
 *
 * Note that the newly created #VtePty will take ownership of @fd
 * and close it on finalize.
 *
 * Returns: (transfer full): a new #VtePty for @fd, or %NULL on error with @error filled in
 */
VtePty *
vte_pty_new_foreign_sync (int fd,
                          GCancellable *cancellable,
                          GError **error)
{
        g_return_val_if_fail(fd >= 0, NULL);

        return (VtePty *) g_initable_new (VTE_TYPE_PTY,
                                          cancellable,
                                          error,
                                          "fd", fd,
                                          NULL);
}

/**
 * vte_pty_get_fd:
 * @pty: a #VtePty
 *
 * Returns: (transfer none): the file descriptor of the PTY master in @pty. The
 *   file descriptor belongs to @pty and must not be closed
 */
int
vte_pty_get_fd (VtePty *pty)
{
        VtePtyPrivate *priv;

        g_return_val_if_fail(VTE_IS_PTY(pty), -1);

        priv = pty->priv;
        g_return_val_if_fail(priv->pty_fd != -1, -1);

        return priv->pty_fd;
}

typedef struct {
        VtePty* m_pty;
        char* m_working_directory;
        char** m_argv;
        char** m_envv;
        GSpawnFlags m_spawn_flags;
        GSpawnChildSetupFunc m_child_setup;
        gpointer m_child_setup_data;
        GDestroyNotify m_child_setup_data_destroy;
        int m_timeout;
} AsyncSpawnData;

static AsyncSpawnData*
async_spawn_data_new (VtePty* pty,
                      char const* working_directory,
                      char** argv,
                      char** envv,
                      GSpawnFlags spawn_flags,
                      GSpawnChildSetupFunc child_setup,
                      gpointer child_setup_data,
                      GDestroyNotify child_setup_data_destroy,
                      int timeout)
{
        auto data = g_new(AsyncSpawnData, 1);

        data->m_pty = (VtePty*)g_object_ref(pty);
        data->m_working_directory = g_strdup(working_directory);
        data->m_argv = g_strdupv(argv);
        data->m_envv = envv ? g_strdupv(envv) : nullptr;
        data->m_spawn_flags = spawn_flags;
        data->m_child_setup = child_setup;
        data->m_child_setup_data = child_setup_data;
        data->m_child_setup_data_destroy = child_setup_data_destroy;
        data->m_timeout = timeout;

        return data;
}

static void
async_spawn_data_free(gpointer data_)
{
        AsyncSpawnData *data = reinterpret_cast<AsyncSpawnData*>(data_);

        g_free(data->m_working_directory);
        g_strfreev(data->m_argv);
        g_strfreev(data->m_envv);
        if (data->m_child_setup_data && data->m_child_setup_data_destroy)
                data->m_child_setup_data_destroy(data->m_child_setup_data);
        g_object_unref(data->m_pty);

        g_free(data);
}

static void
async_spawn_run_in_thread(GTask *task,
                          gpointer object,
                          gpointer data_,
                          GCancellable *cancellable)
{
        AsyncSpawnData *data = reinterpret_cast<AsyncSpawnData*>(data_);

        GPid pid;
        GError *error = NULL;
        if (__vte_pty_spawn(data->m_pty,
                            data->m_working_directory,
                            data->m_argv,
                            data->m_envv,
                            (GSpawnFlags)data->m_spawn_flags,
                            data->m_child_setup, data->m_child_setup_data,
                            &pid,
                            data->m_timeout,
                            cancellable,
                            &error))
                g_task_return_pointer(task, g_memdup(&pid, sizeof(pid)), g_free);
        else
                g_task_return_error(task, error);
}

/**
 * vte_pty_spawn_async:
 * @pty: a #VtePty
 * @working_directory: (allow-none): the name of a directory the command should start
 *   in, or %NULL to use the current working directory
 * @argv: (array zero-terminated=1) (element-type filename): child's argument vector
 * @envv: (allow-none) (array zero-terminated=1) (element-type filename): a list of environment
 *   variables to be added to the environment before starting the process, or %NULL
 * @spawn_flags: flags from #GSpawnFlags
 * @child_setup: (allow-none) (scope async): an extra child setup function to run in the child just before exec(), or %NULL
 * @child_setup_data: (closure child_setup): user data for @child_setup, or %NULL
 * @child_setup_data_destroy: (destroy child_setup_data): a #GDestroyNotify for @child_setup_data, or %NULL
 * @timeout: a timeout value in ms, or -1 to wait indefinitely
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 *
 * Starts the specified command under the pseudo-terminal @pty.
 * The @argv and @envv lists should be %NULL-terminated.
 * The "TERM" environment variable is automatically set to a default value,
 * but can be overridden from @envv.
 * @pty_flags controls logging the session to the specified system log files.
 *
 * Note that %G_SPAWN_DO_NOT_REAP_CHILD will always be added to @spawn_flags.
 *
 * Note that all open file descriptors will be closed in the child. If you want
 * to keep some file descriptor open for use in the child process, you need to
 * use a child setup function that unsets the FD_CLOEXEC flag on that file
 * descriptor.
 *
 * See vte_pty_new(), g_spawn_async() and vte_terminal_watch_child() for more information.
 *
 * Since: 0.48
 */
void
vte_pty_spawn_async(VtePty *pty,
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
                    gpointer user_data)
{
        g_return_if_fail(argv != nullptr);
        g_return_if_fail(!child_setup_data || child_setup);
        g_return_if_fail(!child_setup_data_destroy || child_setup_data);
        g_return_if_fail(cancellable == nullptr || G_IS_CANCELLABLE (cancellable));
        g_return_if_fail(callback);

        auto data = async_spawn_data_new(pty,
                                         working_directory, argv, envv,
                                         spawn_flags,
                                         child_setup, child_setup_data, child_setup_data_destroy,
                                         timeout);

        auto task = g_task_new(pty, cancellable, callback, user_data);
        g_task_set_source_tag(task, (void*)vte_pty_spawn_async);
        g_task_set_task_data(task, data, async_spawn_data_free);
        g_task_run_in_thread(task, async_spawn_run_in_thread);
        g_object_unref(task);
}

/**
 * vte_pty_spawn_finish:
 * @pty: a #VtePty
 * @result: a #GAsyncResult
 * @child_pid: (out) (allow-none) (transfer full): a location to store the child PID, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Returns: %TRUE on success, or %FALSE on error with @error filled in
 *
 * Since: 0.48
 */
gboolean
vte_pty_spawn_finish(VtePty *pty,
                     GAsyncResult *result,
                     GPid *child_pid /* out */,
                     GError **error)
{
        g_return_val_if_fail (VTE_IS_PTY (pty), FALSE);
        g_return_val_if_fail (G_IS_TASK (result), FALSE);
        g_return_val_if_fail(error == nullptr || *error == nullptr, FALSE);

        gpointer pidptr = g_task_propagate_pointer(G_TASK(result), error);
        if (pidptr == nullptr) {
                if (child_pid)
                        *child_pid = -1;
                return FALSE;
        }

        if (child_pid)
                *child_pid = *(GPid*)pidptr;
        if (error)
                *error = nullptr;

        g_free(pidptr);
        return TRUE;
}
