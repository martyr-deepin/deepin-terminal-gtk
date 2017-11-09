/*
 ** openpty.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:10:25 2000 Matthieu Lucotte
 ** Last update Wed Sep 24 00:05:06 2003 
 */

#include "zssh.h"

#define GL_SLAVENAMELEN	50
static char	gl_slavename[GL_SLAVENAMELEN + 1] = {0};

#define NEEDED

/****************************************************************************/
#if defined(HAVE_OPENPTY) && defined(NEEDED)
/****************************************************************************/
#undef NEEDED
/* openpty exists in MacOS X */

#ifdef HAVE_UTIL_H
#include <util.h>
#endif

void	getmaster()
{
#ifdef DEBUG
   printf("Using openpty() for tty allocation\n");
#endif
   if (openpty(&gl_master, &gl_slave, gl_slavename, &gl_tt, &gl_win) < 0)
      error(0,"openpty");
}

void	getslave()
{
   testslave(gl_slavename);
}

/****************************************************************************/
#endif /* HAVE_OPENPTY */
/****************************************************************************/


/****************************************************************************/
#if defined(HAVE__GETPTY) && defined(NEEDED)
/****************************************************************************/
#undef NEEDED
/* _getpty(3) exists in SGI Irix 4.x, 5.x & 6.x -- it generates more
 pty's automagically when needed */

void	getmaster()
{
   char *name;
   
#ifdef DEBUG
   printf("Using _getpty() to allocate pty\n");
#endif
   name = _getpty(&gl_master, O_RDWR, 0620, 0);
   if (!name)
      error(0, "_getpty");
   strncpy(gl_slavename, name, GL_SLAVENAMELEN);
}

/* Open the slave side. */
void	getslave()
{
#ifdef DEBUG
   printf("Allocated tty: %s\n", gl_slavename);
#endif
   if ((gl_slave = open(gl_slavename, O_RDWR | O_NOCTTY)) < 0)
      error(0, "gl_slavename");
   
   testslave(gl_slavename);
   
   if (tcsetattr(gl_slave, TCSAFLUSH, &gl_tt) < 0)
      error(0, "tcsetattr slave");
   if (ioctl(gl_slave, TIOCSWINSZ, (char *)&gl_win) < 0)
      error(0, "ioctl TIOCSWINSZ slave");
}

/****************************************************************************/
#endif /* HAVE__GETPTY */
/****************************************************************************/




/****************************************************************************/
#if defined(HAVE_DEV_PTMX) && defined(NEEDED)
/****************************************************************************/
#undef NEEDED

/* System V.4 pty routines from W. Richard Stevens */

#ifdef HAVE_STROPTS_H
#include <stropts.h>
#endif /* HAVE_STROPTS_H */
#define DEV_CLONE       "/dev/ptmx"


void		getmaster()
{
   char		*ttyptr;
   
#ifdef DEBUG
   printf("Using SYSTEM V style tty allocation routine\n");
#endif
#ifdef HAVE_GETPT
   gl_master = getpt();
#else
   gl_master = open(DEV_CLONE, O_RDWR);
#endif /* HAVE_GETPT */
   if (gl_master < 0)
      error(0, DEV_CLONE);
   if (!(ttyptr = ptsname(gl_master)))
      error(0, "ptsname");
   strncpy(gl_slavename, ttyptr, GL_SLAVENAMELEN);
#ifdef HAVE_GRANTPT
   call_grantpt();
#endif /* HAVE_GRANTPT */
#ifdef HAVE_UNLOCKPT
   if ( unlockpt(gl_master) < 0 )  /* clear slave's lock flag  */
      error(0,"unlockpt");
#endif /* HAVE_UNLOCKPT */
}

/*
 * Open the slave half of a pseudo-terminal.
 */
void		getslave()
{
   if ( (gl_slave = open(gl_slavename, O_RDWR | O_NOCTTY)) < 0 )   /* open the slave */
      error(0, "open slave");
#ifdef DEBUG
   printf("Allocated tty: %s\n", gl_slavename);
#endif
   testslave(gl_slavename);
   
   
#ifdef HAVE_ISASTREAM
   if (isastream(gl_slave))
   {
#ifdef DEBUG
      printf("Now calling ioctls to push term emulation modules:\n");
      printf("  ioctl I_PUSH ptem\n");
      printf("  ioctl I_PUSH ldterm\n");
      printf("  ioctl I_PUSH ttcompat\n");
#endif
      if ( ioctl(gl_slave, I_PUSH, "ptem") < 0 )
	 error(0,"ioctl I_PUSH ptem");
      if ( ioctl(gl_slave, I_PUSH, "ldterm") < 0 )
	 error(0,"ioctl I_PUSH ldterm");
      /* Allow ttcompat to fail silently */
      ioctl(gl_slave, I_PUSH, "ttcompat");
   }
#endif /* HAVE_ISASTREAM */
   
   if (tcsetattr(gl_slave, TCSAFLUSH, &gl_tt) < 0)
      error(0, "tcsetattr slave");
   if (ioctl(gl_slave, TIOCSWINSZ, (char *)&gl_win) < 0)
      error(0, "ioctl TIOCSWINSZ slave");
}

/****************************************************************************/
#endif /* HAVE_DEV_PTMX */
/****************************************************************************/





/****************************************************************************/
#ifdef NEEDED
/****************************************************************************/

/* BSD style tty/pty allocation routines */

static char	gl_line[] = "/dev/ptyXX";

void	getmaster()
{
   char		*pty, *bank, *cp;
   struct stat	stb;
   int		ok;
   
#ifdef DEBUG
   printf("Using BSD style tty allocation routine\n");
#endif
   pty = &gl_line[strlen("/dev/ptyp")];
   for (bank = "pqrs"; *bank; bank++)
   {
      gl_line[strlen("/dev/pty")] = *bank;
      *pty = '0';
      if (stat(gl_line, &stb) < 0)
	 break;
      for (cp = "0123456789abcdef"; *cp; cp++)
      {
	 *pty = *cp;
	 gl_master = open(gl_line, O_RDWR);
	 if (gl_master >= 0)
	 {
	    strncpy(gl_slavename, gl_line, GL_SLAVENAMELEN);
	    gl_slavename[strlen("/dev/")] = 't';	    
#ifdef HAVE_GRANTPT
	    call_grantpt();
#endif /* HAVE_GRANTPT */
#ifdef HAVE_UNLOCKPT
	    if (unlockpt(gl_master) < 0)
	       error(0,"unlockpt");
#endif /* HAVE_UNLOCKPT */
	    
	    /* verify slave side is usable */
	    ok = access(gl_slavename, R_OK | W_OK) == 0;
	    if (ok)
	       return;
	    close(gl_master);
	 }
      }
   }
   error("out of pty's\n", "");
}


void	getslave()
{
   if ( (gl_slave = open(gl_slavename, O_RDWR | O_NOCTTY)) < 0)
      error(0, gl_slavename);
#ifdef DEBUG
   printf("Allocated tty: %s\n", gl_slavename);
#endif
   testslave(gl_slavename);
   if (tcsetattr(gl_slave, TCSAFLUSH, &gl_tt) < 0)
      error(0, "tcsetattr slave");
   if (ioctl(gl_slave, TIOCSWINSZ, (char *)&gl_win) < 0)
      error(0, "ioctl TIOCSWINSZ slave");
}

/****************************************************************************/
#endif /* BSD style ptys */
/****************************************************************************/

void	my_tcsetpgrp(int fd, int pgrpid)
{
   int ret;
   
#ifdef HAVE_TCSETPGRP
   ret = tcsetpgrp(fd, pgrpid);
#else
   ret = ioctl(fd, TIOCSPGRP, &pgrpid); 
#endif /* HAVE_TCSETPGRP */

   if (ret < 0)
      error(0, "my_tcsetpgrp");
}

/* set raw mode */
void	my_cfmakeraw(struct termios *pt)
{
   /* beginning of 'official' cfmakeraw function */
   pt->c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP
		    |INLCR|IGNCR|ICRNL|IXON);
   pt->c_oflag &= ~OPOST;
   pt->c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
   pt->c_cflag &= ~(CSIZE|PARENB);
   pt->c_cflag |= CS8;
   /* end of 'official' cfmakeraw function */
   
   pt->c_cc[VMIN] = 1;
   pt->c_cc[VTIME] = 0;
   /*   pt->c_oflag |= OPOST; */
   /*   pt->c_lflag &= ~ECHO; */
}


/* called by getslave()
 * test tty permissions and warn user if insecure
 */
void			testslave(char *ttyname)
{
   struct stat		st;
   struct passwd	*pwd;
   int			ask = 0;
   
   if (fstat(gl_slave, &st) < 0)
      error(0, "fstat tty");
   if (st.st_uid != getuid())
   { /* tty is not owned by the user, this can be a security issue so prompt the user */
      if ( (pwd = getpwuid(st.st_uid)) )	 
	 printf("*** %s: This tty is owned by someone else (%s) !\n", ttyname, pwd->pw_name);
      else
	 printf("*** %s: This tty is owned by someone else (uid %lu) !\n", ttyname, (long) st.st_uid);
      ask = 1;
   }
   if (st.st_mode & S_IWOTH)
      /* tty is world writeable: this can be abused but there is no serious security issue here
       * so just print a warning.   */
      printf("*** %s: this tty is world writeable !\n", ttyname);
   if (st.st_mode & S_IROTH) 
   {  /* tty is world readable: this is very insecure so prompt the user */
      printf("*** %s: this tty is world readable !\n", ttyname);
      ask = 1;
   }
   if (ask)
   {
      printf("*** This is a security issue\n");
      if (!ask_user("Do you want to continue anyway ?", 0, 1))
    	 error("aborting\n", "");
   }
}


/* init slave after call to getslave
 * make slave the controlling tty for current process
 */
void	initslave()
{
   close(gl_master);
   setsid();
   
   /* by now we should have dropped the controlling tty
    * make sure it is indeed the case
    */
   if (open("/dev/tty", O_RDWR) >= 0)
      error("Couldn't drop controlling tty\n","");
   
#ifdef TIOCSCTTY
   if (ioctl(gl_slave, TIOCSCTTY, 0) < 0)
      perror("ioctl(slave, TIOCSCTTY, 0)");   
#else    /* re-open the tty so that it becomes the controlling tty */
   close(gl_slave);
   if ( (gl_slave = open(gl_slavename, O_RDWR)) < 0 )  
      error(0, gl_slavename);
#endif /* TIOCSCTTY */
   
   if (dup2(gl_slave, 0) < 0)
      error(0, "dup2(slave, 0)");
   dup2(gl_slave, 1);
   dup2(gl_slave, 2);
   close(gl_slave);
}


#ifdef HAVE_GRANTPT
/* Call grantpt(). If it fails, prompt the user whether
 * to continue anyway despite the security issue.
 */
void	call_grantpt()
{
   static int	answered = 0;
   
   /* SIGCHLD should NOT be handled at this point otherwise it
    * may interfere with grantpt
    */
   signal(SIGCHLD, SIG_DFL);
   
   if (grantpt(gl_master) < 0 && !answered)
   {
      perror("grantpt");
      printf("*** Calling grantpt() failed. This can be a security issue\n"
	     "*** as another user may be able to spy on this session\n");
      if (!ask_user("Do you want to continue anyway ?", 0, 1))
	 error("aborting\n", "");
      answered = 1;
   }
}
#endif /* HAVE_GRANTPT */

