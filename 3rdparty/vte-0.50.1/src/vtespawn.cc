/* gspawn.c - Process launching
 *
 *  Copyright 2000 Red Hat, Inc.
 *  g_execvpe implementation based on GNU libc execvp:
 *   Copyright 1991, 92, 95, 96, 97, 98, 99 Free Software Foundation, Inc.
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

#include "config.h"

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>   /* for fdwalk */
#include <dirent.h>

#ifdef HAVE_SYS_RESOURCE_H
#include <sys/resource.h>
#endif /* HAVE_SYS_RESOURCE_H */

#include <glib/gstdio.h>
#include <glib-unix.h>

#include "vtespawn.hh"
#include "reaper.hh"

#define VTE_SPAWN_ERROR_TIMED_OUT (G_SPAWN_ERROR_FAILED + 1000)
#define VTE_SPAWN_ERROR_CANCELLED (G_SPAWN_ERROR_FAILED + 1001)

#define _(s) g_dgettext("glib20", s)

/*
 * SECTION:spawn
 * @Short_description: process launching
 * @Title: Spawning Processes
 *
 * GLib supports spawning of processes with an API that is more
 * convenient than the bare UNIX fork() and exec().
 *
 * The vte_spawn family of functions has synchronous (vte_spawn_sync())
 * and asynchronous variants (vte_spawn_async(), vte_spawn_async_with_pipes(),
 * vte_spawn_async_cancellable(), vte_spawn_async_with_pipes_cancellable),
 * as well as convenience variants that take a complete shell-like
 * commandline (vte_spawn_command_line_sync(), vte_spawn_command_line_async()).
 *
 * See #GSubprocess in GIO for a higher-level API that provides
 * stream interfaces for communication with child processes.
 */

static gint g_execute (const gchar  *file,
                       gchar **argv,
                       gchar **envp,
                       gboolean search_path,
                       gboolean search_path_from_envp);

static gboolean fork_exec_with_pipes (gboolean              intermediate_child,
                                      const gchar          *working_directory,
                                      gchar               **argv,
                                      gchar               **envp,
                                      gboolean              close_descriptors,
                                      gboolean              search_path,
                                      gboolean              search_path_from_envp,
                                      gboolean              stdout_to_null,
                                      gboolean              stderr_to_null,
                                      gboolean              child_inherits_stdin,
                                      gboolean              file_and_argv_zero,
                                      gboolean              cloexec_pipes,
                                      GSpawnChildSetupFunc  child_setup,
                                      gpointer              user_data,
                                      GPid                 *child_pid,
                                      gint                 *standard_input,
                                      gint                 *standard_output,
                                      gint                 *standard_error,
                                      gint                  timeout,
                                      GPollFD              *pollfd,
                                      GError              **error);

/*
 * vte_spawn_async_cancellable:
 * @working_directory: (type filename) (allow-none): child's current working directory, or %NULL to inherit parent's
 * @argv: (array zero-terminated=1): child's argument vector
 * @envp: (array zero-terminated=1) (allow-none): child's environment, or %NULL to inherit parent's
 * @flags: flags from #GSpawnFlags
 * @child_setup: (scope async) (allow-none): function to run in the child just before exec()
 * @user_data: (closure): user data for @child_setup
 * @child_pid: (out) (allow-none): return location for child process reference, or %NULL
 * @timeout: a timeout value in ms, or -1 to wait indefinitely
 * @pollfd: (allow-none): a #GPollFD, or %NULL
 * @error: return location for error
 * 
 * See vte_spawn_async_with_pipes_cancellable() for a full description; this function
 * simply calls the vte_spawn_async_with_pipes_cancellable() without any pipes.
 *
 * You should call vte_spawn_close_pid() on the returned child process
 * reference when you don't need it any more.
 * 
 * Note that the returned @child_pid on Windows is a handle to the child
 * process and not its identifier. Process handles and process identifiers
 * are different concepts on Windows.
 *
 * Returns: %TRUE on success, %FALSE if error is set
 *
 * Since: 2.52
 **/
gboolean
vte_spawn_async_cancellable (const gchar          *working_directory,
                             gchar               **argv,
                             gchar               **envp,
                             GSpawnFlags           flags,
                             GSpawnChildSetupFunc  child_setup,
                             gpointer              user_data,
                             GPid                 *child_pid,
                             gint                  timeout,
                             GPollFD              *pollfd,
                             GError              **error)
{
  return vte_spawn_async_with_pipes_cancellable (working_directory,
                                               argv, envp,
                                               flags,
                                               child_setup,
                                               user_data,
                                               child_pid,
                                               NULL, NULL, NULL,
                                               timeout, pollfd,
                                               error);
}

/* Avoids a danger in threaded situations (calling close()
 * on a file descriptor twice, and another thread has
 * re-opened it since the first close)
 */
static void
close_and_invalidate (gint *fd)
{
  if (*fd < 0)
    return;
  else
    {
      (void) g_close (*fd, NULL);
      *fd = -1;
    }
}

/*
 * vte_spawn_async_with_pipes_cancellable:
 * @working_directory: (type filename) (allow-none): child's current working directory, or %NULL to inherit parent's, in the GLib file name encoding
 * @argv: (array zero-terminated=1): child's argument vector, in the GLib file name encoding
 * @envp: (array zero-terminated=1) (allow-none): child's environment, or %NULL to inherit parent's, in the GLib file name encoding
 * @flags: flags from #GSpawnFlags
 * @child_setup: (scope async) (allow-none): function to run in the child just before exec()
 * @user_data: (closure): user data for @child_setup
 * @child_pid: (out) (allow-none): return location for child process ID, or %NULL
 * @standard_input: (out) (allow-none): return location for file descriptor to write to child's stdin, or %NULL
 * @standard_output: (out) (allow-none): return location for file descriptor to read child's stdout, or %NULL
 * @standard_error: (out) (allow-none): return location for file descriptor to read child's stderr, or %NULL
 * @timeout: a timeout value in ms, or -1 to wait indefinitely
 * @pollfd: (allow-none): a #GPollFD, or %NULL
 * @error: return location for error
 *
 * Like vte_spawn_async_with_pipes(), but allows the spawning to be
 * aborted.
 *
 * If @timeout is not -1, then the spawning will be aborted if
 * the timeout is exceeded before spawning has completed.
 *
 * If @pollfd is not %NULL, then the spawning will be aborted if
 * the @pollfd.fd becomes readable. Usually, you want to create
 * this parameter with g_cancellable_make_pollfd().
 *
 * Returns: %TRUE on success, %FALSE if an error occurred or the
 *  spawning was aborted
 *
 * Since: 2.52
 */
gboolean
vte_spawn_async_with_pipes_cancellable (const gchar          *working_directory,
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
                                        GError              **error)
{
  g_return_val_if_fail (argv != NULL, FALSE);
  g_return_val_if_fail (standard_output == NULL ||
                        !(flags & G_SPAWN_STDOUT_TO_DEV_NULL), FALSE);
  g_return_val_if_fail (standard_error == NULL ||
                        !(flags & G_SPAWN_STDERR_TO_DEV_NULL), FALSE);
  /* can't inherit stdin if we have an input pipe. */
  g_return_val_if_fail (standard_input == NULL ||
                        !(flags & G_SPAWN_CHILD_INHERITS_STDIN), FALSE);
  
  return fork_exec_with_pipes (!(flags & G_SPAWN_DO_NOT_REAP_CHILD),
                               working_directory,
                               argv,
                               envp,
                               !(flags & G_SPAWN_LEAVE_DESCRIPTORS_OPEN),
                               (flags & G_SPAWN_SEARCH_PATH) != 0,
                               (flags & G_SPAWN_SEARCH_PATH_FROM_ENVP) != 0,
                               (flags & G_SPAWN_STDOUT_TO_DEV_NULL) != 0,
                               (flags & G_SPAWN_STDERR_TO_DEV_NULL) != 0,
                               (flags & G_SPAWN_CHILD_INHERITS_STDIN) != 0,
                               (flags & G_SPAWN_FILE_AND_ARGV_ZERO) != 0,
                               (flags & G_SPAWN_CLOEXEC_PIPES) != 0,
                               child_setup,
                               user_data,
                               child_pid,
                               standard_input,
                               standard_output,
                               standard_error,
                               timeout,
                               pollfd,
                               error);
}

static gint
exec_err_to_g_error (gint en)
{
  switch (en)
    {
#ifdef EACCES
    case EACCES:
      return G_SPAWN_ERROR_ACCES;
      break;
#endif

#ifdef EPERM
    case EPERM:
      return G_SPAWN_ERROR_PERM;
      break;
#endif

#ifdef E2BIG
    case E2BIG:
      return G_SPAWN_ERROR_TOO_BIG;
      break;
#endif

#ifdef ENOEXEC
    case ENOEXEC:
      return G_SPAWN_ERROR_NOEXEC;
      break;
#endif

#ifdef ENAMETOOLONG
    case ENAMETOOLONG:
      return G_SPAWN_ERROR_NAMETOOLONG;
      break;
#endif

#ifdef ENOENT
    case ENOENT:
      return G_SPAWN_ERROR_NOENT;
      break;
#endif

#ifdef ENOMEM
    case ENOMEM:
      return G_SPAWN_ERROR_NOMEM;
      break;
#endif

#ifdef ENOTDIR
    case ENOTDIR:
      return G_SPAWN_ERROR_NOTDIR;
      break;
#endif

#ifdef ELOOP
    case ELOOP:
      return G_SPAWN_ERROR_LOOP;
      break;
#endif
      
#ifdef ETXTBUSY
    case ETXTBUSY:
      return G_SPAWN_ERROR_TXTBUSY;
      break;
#endif

#ifdef EIO
    case EIO:
      return G_SPAWN_ERROR_IO;
      break;
#endif

#ifdef ENFILE
    case ENFILE:
      return G_SPAWN_ERROR_NFILE;
      break;
#endif

#ifdef EMFILE
    case EMFILE:
      return G_SPAWN_ERROR_MFILE;
      break;
#endif

#ifdef EINVAL
    case EINVAL:
      return G_SPAWN_ERROR_INVAL;
      break;
#endif

#ifdef EISDIR
    case EISDIR:
      return G_SPAWN_ERROR_ISDIR;
      break;
#endif

#ifdef ELIBBAD
    case ELIBBAD:
      return G_SPAWN_ERROR_LIBBAD;
      break;
#endif
      
    default:
      return G_SPAWN_ERROR_FAILED;
      break;
    }
}

static gssize
write_all (gint fd, gconstpointer vbuf, gsize to_write)
{
  gchar *buf = (gchar *) vbuf;
  
  while (to_write > 0)
    {
      gssize count = write (fd, buf, to_write);
      if (count < 0)
        {
          if (errno != EINTR)
            return FALSE;
        }
      else
        {
          to_write -= count;
          buf += count;
        }
    }
  
  return TRUE;
}

G_GNUC_NORETURN
static void
write_err_and_exit (gint fd, gint msg)
{
  gint en = errno;
  
  write_all (fd, &msg, sizeof(msg));
  write_all (fd, &en, sizeof(en));
  
  _exit (1);
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
set_cloexec (void *data, gint fd)
{
  if (fd >= GPOINTER_TO_INT (data))
    fd_set_cloexec (fd);

  return 0;
}

#ifndef HAVE_FDWALK
static int
fdwalk (int (*cb)(void *data, int fd), void *data)
{
  gint open_max;
  gint fd;
  gint res = 0;
  
#ifdef HAVE_SYS_RESOURCE_H
  struct rlimit rl;
#endif

#ifdef __linux__  
  DIR *d;

  if ((d = opendir("/proc/self/fd"))) {
      struct dirent *de;

      while ((de = readdir(d))) {
          glong l;
          gchar *e = NULL;

          if (de->d_name[0] == '.')
              continue;
            
          errno = 0;
          l = strtol(de->d_name, &e, 10);
          if (errno != 0 || !e || *e)
              continue;

          fd = (gint) l;

          if ((glong) fd != l)
              continue;

          if (fd == dirfd(d))
              continue;

          if ((res = cb (data, fd)) != 0)
              break;
        }
      
      closedir(d);
      return res;
  }

  /* If /proc is not mounted or not accessible we fall back to the old
   * rlimit trick */

#endif
  
#ifdef HAVE_SYS_RESOURCE_H
      
  if (getrlimit(RLIMIT_NOFILE, &rl) == 0 && rl.rlim_max != RLIM_INFINITY)
      open_max = rl.rlim_max;
  else
#endif
      open_max = sysconf (_SC_OPEN_MAX);

  for (fd = 0; fd < open_max; fd++)
      if ((res = cb (data, fd)) != 0)
          break;

  return res;
}
#endif

static gint
sane_dup2 (gint fd1, gint fd2)
{
  gint ret;

 retry:
  ret = dup2 (fd1, fd2);
  if (ret < 0 && errno == EINTR)
    goto retry;

  return ret;
}

static gint
sane_open (const char *path, gint mode)
{
  gint ret;

 retry:
  ret = open (path, mode);
  if (ret < 0 && errno == EINTR)
    goto retry;

  return ret;
}

enum
{
  CHILD_CHDIR_FAILED,
  CHILD_EXEC_FAILED,
  CHILD_DUP2_FAILED,
  CHILD_FORK_FAILED
};

static void
do_exec (gint                  child_err_report_fd,
         gint                  stdin_fd,
         gint                  stdout_fd,
         gint                  stderr_fd,
         const gchar          *working_directory,
         gchar               **argv,
         gchar               **envp,
         gboolean              close_descriptors,
         gboolean              search_path,
         gboolean              search_path_from_envp,
         gboolean              stdout_to_null,
         gboolean              stderr_to_null,
         gboolean              child_inherits_stdin,
         gboolean              file_and_argv_zero,
         GSpawnChildSetupFunc  child_setup,
         gpointer              user_data)
{
  if (working_directory && chdir (working_directory) < 0)
    write_err_and_exit (child_err_report_fd,
                        CHILD_CHDIR_FAILED);

  /* Close all file descriptors but stdin stdout and stderr as
   * soon as we exec. Note that this includes
   * child_err_report_fd, which keeps the parent from blocking
   * forever on the other end of that pipe.
   */
  if (close_descriptors)
    {
      fdwalk (set_cloexec, GINT_TO_POINTER(3));
    }
  else
    {
      /* We need to do child_err_report_fd anyway */
      set_cloexec (GINT_TO_POINTER(0), child_err_report_fd);
    }
  
  /* Redirect pipes as required */
  
  if (stdin_fd >= 0)
    {
      /* dup2 can't actually fail here I don't think */
          
      if (sane_dup2 (stdin_fd, 0) < 0)
        write_err_and_exit (child_err_report_fd,
                            CHILD_DUP2_FAILED);

      /* ignore this if it doesn't work */
      close_and_invalidate (&stdin_fd);
    }
  else if (!child_inherits_stdin)
    {
      /* Keep process from blocking on a read of stdin */
      gint read_null = open ("/dev/null", O_RDONLY);
      g_assert (read_null != -1);
      sane_dup2 (read_null, 0);
      close_and_invalidate (&read_null);
    }

  if (stdout_fd >= 0)
    {
      /* dup2 can't actually fail here I don't think */
          
      if (sane_dup2 (stdout_fd, 1) < 0)
        write_err_and_exit (child_err_report_fd,
                            CHILD_DUP2_FAILED);

      /* ignore this if it doesn't work */
      close_and_invalidate (&stdout_fd);
    }
  else if (stdout_to_null)
    {
      gint write_null = sane_open ("/dev/null", O_WRONLY);
      g_assert (write_null != -1);
      sane_dup2 (write_null, 1);
      close_and_invalidate (&write_null);
    }

  if (stderr_fd >= 0)
    {
      /* dup2 can't actually fail here I don't think */
          
      if (sane_dup2 (stderr_fd, 2) < 0)
        write_err_and_exit (child_err_report_fd,
                            CHILD_DUP2_FAILED);

      /* ignore this if it doesn't work */
      close_and_invalidate (&stderr_fd);
    }
  else if (stderr_to_null)
    {
      gint write_null = sane_open ("/dev/null", O_WRONLY);
      sane_dup2 (write_null, 2);
      close_and_invalidate (&write_null);
    }
  
  /* Call user function just before we exec */
  if (child_setup)
    {
      (* child_setup) (user_data);
    }

  g_execute (argv[0],
             file_and_argv_zero ? argv + 1 : argv,
             envp, search_path, search_path_from_envp);

  /* Exec failed */
  write_err_and_exit (child_err_report_fd,
                      CHILD_EXEC_FAILED);
}

static gboolean
read_ints (int      fd,
           gint*    buf,
           gint     n_ints_in_buf,    
           gint    *n_ints_read,
           gint     timeout,
           GPollFD *cancellable_pollfd,
           GError **error)
{
  gsize bytes = 0;
  GPollFD pollfds[2];
  guint n_pollfds;
  gint64 start_time = 0;

  if (timeout >= 0 || cancellable_pollfd != NULL)
    {
      if (fd_set_nonblocking(fd) < 0)
        {
          int errsv = errno;
          g_set_error (error, G_SPAWN_ERROR, G_SPAWN_ERROR_FAILED,
                       _("Failed to set pipe nonblocking: %s"), g_strerror (errsv));
          return FALSE;
        }

      pollfds[0].fd = fd;
      pollfds[0].events = G_IO_IN | G_IO_HUP | G_IO_ERR;
      n_pollfds = 1;

      if (cancellable_pollfd != NULL)
        {
          pollfds[1] = *cancellable_pollfd;
          n_pollfds = 2;
        }
    }
  else
    n_pollfds = 0;

  if (timeout >= 0)
    start_time = g_get_monotonic_time ();

  while (TRUE)
    {
      gssize chunk;    

      if (bytes >= sizeof(gint)*2)
        break; /* give up, who knows what happened, should not be
                * possible.
                */
          
    again:
      if (n_pollfds != 0)
        {
          int r;

          pollfds[0].revents = pollfds[1].revents = 0;

          r = g_poll (pollfds, n_pollfds, timeout);

          /* Update timeout */
          if (timeout >= 0)
            {
              timeout -= (g_get_monotonic_time () - start_time) / 1000;
              if (timeout < 0)
                timeout = 0;
            }

          if (r < 0 && errno == EINTR)
            goto again;
          if (r < 0)
            {
              int errsv = errno;
              g_set_error (error, G_SPAWN_ERROR, G_SPAWN_ERROR_FAILED,
                           _("poll error: %s"), g_strerror (errsv));
              return FALSE;
            }
          if (r == 0)
            {
              g_set_error_literal (error, G_SPAWN_ERROR, VTE_SPAWN_ERROR_TIMED_OUT,
                                   _("Operation timed out"));
              return FALSE;
            }

          /* If the passed-in poll FD becomes readable, that's the signal
           * to cancel the operation. We do NOT actually read from its FD!
           */
          if (n_pollfds == 2 && pollfds[1].revents)
            {
              g_set_error_literal (error, G_SPAWN_ERROR, VTE_SPAWN_ERROR_CANCELLED,
                                   _("Operation was cancelled"));
              return FALSE;
            }

          /* Now we know we can try to read from the child */
        }

      chunk = read (fd,
                    ((gchar*)buf) + bytes,
                    sizeof(gint) * n_ints_in_buf - bytes);
      if (chunk < 0 && errno == EINTR)
        goto again;
          
      if (chunk < 0)
        {
          int errsv = errno;

          /* Some weird shit happened, bail out */
          g_set_error (error,
                       G_SPAWN_ERROR,
                       G_SPAWN_ERROR_FAILED,
                       _("Failed to read from child pipe (%s)"),
                       g_strerror (errsv));

          return FALSE;
        }
      else if (chunk == 0)
        break; /* EOF */
      else /* chunk > 0 */
	bytes += chunk;
    }

  *n_ints_read = (gint)(bytes / sizeof(gint));

  return TRUE;
}

static gboolean
fork_exec_with_pipes (gboolean              intermediate_child,
                      const gchar          *working_directory,
                      gchar               **argv,
                      gchar               **envp,
                      gboolean              close_descriptors,
                      gboolean              search_path,
                      gboolean              search_path_from_envp,
                      gboolean              stdout_to_null,
                      gboolean              stderr_to_null,
                      gboolean              child_inherits_stdin,
                      gboolean              file_and_argv_zero,
                      gboolean              cloexec_pipes,
                      GSpawnChildSetupFunc  child_setup,
                      gpointer              user_data,
                      GPid                 *child_pid,
                      gint                 *standard_input,
                      gint                 *standard_output,
                      gint                 *standard_error,
                      gint                  timeout,
                      GPollFD              *pollfd,
                      GError              **error)     
{
  GPid pid = -1;
  gint stdin_pipe[2] = { -1, -1 };
  gint stdout_pipe[2] = { -1, -1 };
  gint stderr_pipe[2] = { -1, -1 };
  gint child_err_report_pipe[2] = { -1, -1 };
  gint child_pid_report_pipe[2] = { -1, -1 };
  guint pipe_flags = cloexec_pipes ? FD_CLOEXEC : 0;

  g_assert(!intermediate_child);

  if (!g_unix_open_pipe (child_err_report_pipe, pipe_flags, error))
    return FALSE;

  if (standard_input && !g_unix_open_pipe (stdin_pipe, pipe_flags, error))
    goto cleanup_and_fail;
  
  if (standard_output && !g_unix_open_pipe (stdout_pipe, pipe_flags, error))
    goto cleanup_and_fail;

  if (standard_error && !g_unix_open_pipe (stderr_pipe, FD_CLOEXEC, error))
    goto cleanup_and_fail;

  pid = fork ();

  if (pid < 0)
    {
      int errsv = errno;

      g_set_error (error,
                   G_SPAWN_ERROR,
                   G_SPAWN_ERROR_FORK,
                   _("Failed to fork (%s)"),
                   g_strerror (errsv));

      goto cleanup_and_fail;
    }
  else if (pid == 0)
    {
      /* Immediate child. This may or may not be the child that
       * actually execs the new process.
       */

      /* Reset some signal handlers that we may use */
      signal (SIGCHLD, SIG_DFL);
      signal (SIGINT, SIG_DFL);
      signal (SIGTERM, SIG_DFL);
      signal (SIGHUP, SIG_DFL);
      
      /* Be sure we crash if the parent exits
       * and we write to the err_report_pipe
       */
      signal (SIGPIPE, SIG_DFL);

      /* Close the parent's end of the pipes;
       * not needed in the close_descriptors case,
       * though
       */
      close_and_invalidate (&child_err_report_pipe[0]);
      close_and_invalidate (&child_pid_report_pipe[0]);
      close_and_invalidate (&stdin_pipe[1]);
      close_and_invalidate (&stdout_pipe[0]);
      close_and_invalidate (&stderr_pipe[0]);
      
      do_exec (child_err_report_pipe[1],
               stdin_pipe[0],
               stdout_pipe[1],
               stderr_pipe[1],
               working_directory,
               argv,
               envp,
               close_descriptors,
               search_path,
               search_path_from_envp,
               stdout_to_null,
               stderr_to_null,
               child_inherits_stdin,
               file_and_argv_zero,
               child_setup,
               user_data);
    }
  else
    {
      /* Parent */
      
      gint buf[2];
      gint n_ints = 0;    

      /* Close the uncared-about ends of the pipes */
      close_and_invalidate (&child_err_report_pipe[1]);
      close_and_invalidate (&child_pid_report_pipe[1]);
      close_and_invalidate (&stdin_pipe[0]);
      close_and_invalidate (&stdout_pipe[1]);
      close_and_invalidate (&stderr_pipe[1]);

      if (!read_ints (child_err_report_pipe[0],
                      buf, 2, &n_ints,
                      timeout, pollfd,
                      error))
        goto cleanup_and_fail;
        
      if (n_ints >= 2)
        {
          /* Error from the child. */

          switch (buf[0])
            {
            case CHILD_CHDIR_FAILED:
              g_set_error (error,
                           G_SPAWN_ERROR,
                           G_SPAWN_ERROR_CHDIR,
                           _("Failed to change to directory “%s” (%s)"),
                           working_directory,
                           g_strerror (buf[1]));

              break;
              
            case CHILD_EXEC_FAILED:
              g_set_error (error,
                           G_SPAWN_ERROR,
                           exec_err_to_g_error (buf[1]),
                           _("Failed to execute child process “%s” (%s)"),
                           argv[0],
                           g_strerror (buf[1]));

              break;
              
            case CHILD_DUP2_FAILED:
              g_set_error (error,
                           G_SPAWN_ERROR,
                           G_SPAWN_ERROR_FAILED,
                           _("Failed to redirect output or input of child process (%s)"),
                           g_strerror (buf[1]));

              break;

            case CHILD_FORK_FAILED:
              g_set_error (error,
                           G_SPAWN_ERROR,
                           G_SPAWN_ERROR_FORK,
                           _("Failed to fork child process (%s)"),
                           g_strerror (buf[1]));
              break;
              
            default:
              g_set_error (error,
                           G_SPAWN_ERROR,
                           G_SPAWN_ERROR_FAILED,
                           _("Unknown error executing child process “%s”"),
                           argv[0]);
              break;
            }

          goto cleanup_and_fail;
        }

      /* Success against all odds! return the information */
      close_and_invalidate (&child_err_report_pipe[0]);
      close_and_invalidate (&child_pid_report_pipe[0]);
 
      if (child_pid)
        *child_pid = pid;

      if (standard_input)
        *standard_input = stdin_pipe[1];
      if (standard_output)
        *standard_output = stdout_pipe[0];
      if (standard_error)
        *standard_error = stderr_pipe[0];
      
      return TRUE;
    }

 cleanup_and_fail:

  /* There was an error from the Child, reap the child to avoid it being
     a zombie.
   */

  if (pid > 0)
    {
      vte_reaper_add_child(pid);
     }

  close_and_invalidate (&child_err_report_pipe[0]);
  close_and_invalidate (&child_err_report_pipe[1]);
  close_and_invalidate (&child_pid_report_pipe[0]);
  close_and_invalidate (&child_pid_report_pipe[1]);
  close_and_invalidate (&stdin_pipe[0]);
  close_and_invalidate (&stdin_pipe[1]);
  close_and_invalidate (&stdout_pipe[0]);
  close_and_invalidate (&stdout_pipe[1]);
  close_and_invalidate (&stderr_pipe[0]);
  close_and_invalidate (&stderr_pipe[1]);

  return FALSE;
}

/* Based on execvp from GNU C Library */

static void
script_execute (const gchar *file,
                gchar      **argv,
                gchar      **envp)
{
  /* Count the arguments.  */
  int argc = 0;
  while (argv[argc])
    ++argc;
  
  /* Construct an argument list for the shell.  */
  {
    gchar **new_argv;

    new_argv = g_new0 (gchar*, argc + 2); /* /bin/sh and NULL */
    
    new_argv[0] = (char *) "/bin/sh";
    new_argv[1] = (char *) file;
    while (argc > 0)
      {
	new_argv[argc + 1] = argv[argc];
	--argc;
      }

    /* Execute the shell. */
    if (envp)
      execve (new_argv[0], new_argv, envp);
    else
      execv (new_argv[0], new_argv);
    
    g_free (new_argv);
  }
}

static gchar*
my_strchrnul (const gchar *str, gchar c)
{
  gchar *p = (gchar*) str;
  while (*p && (*p != c))
    ++p;

  return p;
}

static gint
g_execute (const gchar *file,
           gchar      **argv,
           gchar      **envp,
           gboolean     search_path,
           gboolean     search_path_from_envp)
{
  if (*file == '\0')
    {
      /* We check the simple case first. */
      errno = ENOENT;
      return -1;
    }

  if (!(search_path || search_path_from_envp) || strchr (file, '/') != NULL)
    {
      /* Don't search when it contains a slash. */
      if (envp)
        execve (file, argv, envp);
      else
        execv (file, argv);
      
      if (errno == ENOEXEC)
	script_execute (file, argv, envp);
    }
  else
    {
      gboolean got_eacces = 0;
      const gchar *path, *p;
      gchar *name, *freeme;
      gsize len;
      gsize pathlen;

      path = NULL;
      if (search_path_from_envp)
        path = g_environ_getenv (envp, "PATH");
      if (search_path && path == NULL)
        path = g_getenv ("PATH");

      if (path == NULL)
	{
	  /* There is no 'PATH' in the environment.  The default
	   * search path in libc is the current directory followed by
	   * the path 'confstr' returns for '_CS_PATH'.
           */

          /* In GLib we put . last, for security, and don't use the
           * unportable confstr(); UNIX98 does not actually specify
           * what to search if PATH is unset. POSIX may, dunno.
           */
          
          path = "/bin:/usr/bin:.";
	}

      len = strlen (file) + 1;
      pathlen = strlen (path);
      freeme = name = (char*)g_malloc (pathlen + len + 1);
      
      /* Copy the file name at the top, including '\0'  */
      memcpy (name + pathlen + 1, file, len);
      name = name + pathlen;
      /* And add the slash before the filename  */
      *name = '/';

      p = path;
      do
	{
	  char *startp;

	  path = p;
	  p = my_strchrnul (path, ':');

	  if (p == path)
	    /* Two adjacent colons, or a colon at the beginning or the end
             * of 'PATH' means to search the current directory.
             */
	    startp = name + 1;
	  else
            startp = (char*)memcpy (name - (p - path), path, p - path);

	  /* Try to execute this name.  If it works, execv will not return.  */
          if (envp)
            execve (startp, argv, envp);
          else
            execv (startp, argv);
          
	  if (errno == ENOEXEC)
	    script_execute (startp, argv, envp);

	  switch (errno)
	    {
	    case EACCES:
	      /* Record the we got a 'Permission denied' error.  If we end
               * up finding no executable we can use, we want to diagnose
               * that we did find one but were denied access.
               */
	      got_eacces = TRUE;

              /* FALL THRU */
              
	    case ENOENT:
#ifdef ESTALE
	    case ESTALE:
#endif
#ifdef ENOTDIR
	    case ENOTDIR:
#endif
	      /* Those errors indicate the file is missing or not executable
               * by us, in which case we want to just try the next path
               * directory.
               */
	      break;

	    case ENODEV:
	    case ETIMEDOUT:
	      /* Some strange filesystems like AFS return even
	       * stranger error numbers.  They cannot reasonably mean anything
	       * else so ignore those, too.
	       */
	      break;

	    default:
	      /* Some other error means we found an executable file, but
               * something went wrong executing it; return the error to our
               * caller.
               */
              g_free (freeme);
	      return -1;
	    }
	}
      while (*p++ != '\0');

      /* We tried every element and none of them worked.  */
      if (got_eacces)
	/* At least one failure was due to permissions, so report that
         * error.
         */
        errno = EACCES;

      g_free (freeme);
    }

  /* Return the error from the last attempt (probably ENOENT).  */
  return -1;
}
