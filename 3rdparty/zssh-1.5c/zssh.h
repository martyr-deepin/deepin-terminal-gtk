/*
 ** zssh.h for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:11:37 2000 Matthieu Lucotte
 ** Last update Mon Sep  1 23:13:12 2003 
 */

/* -------------REMOTE-------------                  ----------------------------LOCAL---------------------------
 *                                                                          **************
 *                                                                         ** zssh input **  <-  
 *  ********             ********                     *******            /  **************      \
 * ** bash ** <tty=pty> ** sshd ** <==ssh_channel==> ** ssh ** <tty=pty>                         <initial_tty=... 
 *  ********             ********                     *******            \     ***************  /
 *                                                                         -> ** zssh output **
 *                                                                             ***************
 *
 * in file transfer mode the output process is stopped, and the input process forks
 * and connects whatever new process is needed
 * 
 * Processs genealogy: 
 *            zssh_input
 *          /       |    \
 *   zssh_output   ssh    rz
 *
 */

#ifndef   __ZSSH_H__
#define   __ZSSH_H__

/* for getpt and ptsname in stdlib.h */
#define _GNU_SOURCE

#include "config.h"

#ifdef STDC_HEADERS
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <grp.h>
#include <utmp.h>
#include <signal.h>
#include <ctype.h>

/*#include <term.h> alpha */

#include <sys/types.h>
#include <sys/stat.h>
#endif /* STDC_HEADERS */



#ifdef HAVE_TERMIOS_H
#include <termios.h>
#else
#include <termio.h>
#endif /*HAVE_TERMIOS_H*/

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif /*HAVE_SYS_WAIT_H*/

#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif /*HAVE_SYS_PARAM_H*/

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif /*HAVE_FCNTL_H*/

#ifdef HAVE_PATHS_H
#include <paths.h>
#endif /*HAVE_PATHS_H*/

#ifdef HAVE_SYS_IOCTL_H
#include <sys/ioctl.h>
#endif /*HAVE_SYS_IOCTL_H*/

#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif /*HAVE_SYS_TIME_H*/

#if 0
  #ifdef HAVE_SYS_TERMIOS_H
  #include <sys/termios.h>
  #else
  #include <sys/termio.h>
  #endif /*HAVE_TERMIO_H*/
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif /*HAVE_UNISTD_H*/

#ifdef HAVE_ERR_H
#include <err.h> /*Net*/
#endif /*HAVE_ERR_H*/

#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h> /*Net*/
#endif /*HAVE_SYS_CDEFS_H*/


#ifdef _SUNOS_VTOC_8
#define SOLARIS
#endif


#ifndef WAIT_ANY
#define WAIT_ANY (-1)
#endif

#ifndef SECSPERMIN
#define SECSPERMIN	(60)
#endif

/*Actions leaving the user in the file xmission mode */
#define	C_SHELL		1
#define	C_HELP		2
#define	C_CD		3
#define C_REPEAT	4
#define C_ESCAPE	5
#define	C_VERSION      	6
#define	C_SUSPEND      	7
#define	C_DISCONNECT    8

/*Actions exiting xmission mode after completiion */
#define C_RZ		100
#define C_SZ		101
#define C_HOOK		102
#define C_EXIT		103


#define min(a,b)	((a) < (b) ? (a) : (b))

typedef struct
{
   char		*name;
   int		n;
   void		(*f)(char **av, int master);
}		t_act_tab;
extern t_act_tab		cmdtab[];


extern int			gl_master;		/* pty fd */
extern int			gl_slave;		/* tty fd */

extern int			gl_main_pid;
extern volatile sig_atomic_t	gl_child_output;	/* pid of child handling output from the pty */
extern volatile sig_atomic_t	gl_child_shell;		/* pid of shell (ssh) */
extern volatile sig_atomic_t	gl_child_rz;		/* pid of child forked for use in the local shell */

extern int			gl_local_shell_mode;

extern volatile sig_atomic_t	gl_interrupt;
extern volatile sig_atomic_t	gl_repeat;     /* repeat action forever */
extern int			gl_force;	/* don't ask user questions */

extern struct termios		gl_tt;	/* initial term */
extern struct termios		gl_rtt;	/* raw mode term */
extern struct termios		gl_tt2;	/* ssh mode term */
extern struct winsize		gl_win;

extern sigset_t			gl_sig_mask;

extern char			gl_escape; /* gl_escape = 'X' -> escape seq is ^X */
extern char			**gl_shav; /* remote shell argv, defaults to ssh -e none  */

#include "parse.h"

int	grantpt(int);
int	unlockpt(int);
#include "fun.h"

#endif /* __ZSSH_H__ */
