/*
 ** doit.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:09:23 2000 Matthieu Lucotte
 ** Last update Tue Oct  2 22:00:18 2001 Matthieu Lucotte
 */

#include "zssh.h"

/* copy input to the pty, test for escape key and
 * switch to local shell mode if it found
 */
void		doinput()
{
   int			cc;
   unsigned char	ibuf[BUFSIZ];
   
   signal(SIGINT, sigint_handler);
   signal(SIGWINCH, sigwinch_handler);
   while (1)
   {
      read_input(&cc, ibuf);
      if (escape_input(&cc, ibuf))
	 rz_mode();
      else
	 write(gl_master, ibuf, cc);
   }   
   error("Should not be reached","");  /* not reached */
}

/* copy output from the pty */
void			dooutput()
{
   int			cc;
   char			obuf[BUFSIZ];

#ifdef DEBUG
   printf("child_output: %i\n", (int) getpid());
#endif   
   signal(SIGTSTP, SIG_IGN);
   signal(SIGINT, SIG_IGN);
   close(0);
   close(gl_slave);
   while (1)
   {
      cc = read(gl_master,obuf,sizeof(obuf));
      if (cc <= 0)
	 continue;
      write(1,obuf,cc);
   }
   error("Should not be reached","");    /* not reached */
}

/* Launch the remote shell.
 * shav defaults to [ "ssh" "-e" "none"  ] (zssh)
 *               or [ "telnet" "-8" "-E" ] (ztelnet)
 */
void	doshell(ac,av,shav)
int	ac;
char	**av;
char	**shav;
{
  char	**argv;
   int	i,j;

#ifdef DEBUG
   printf("child_shell: %i\n", (int) getpid());
#endif      
   initslave();
   printf("\n");
   for (i = 0; shav[i]; i++)
     ;
   i += ac + 1;
   argv = smalloc(i * sizeof(char *));
   for (i = 0; shav[i]; i++)
      argv[i] = shav[i];
   for (j = 1; j < ac; j++)
      argv[i++] = av[j];
   argv[i] = 0;
#ifdef DEBUG
   printf("launching shell: ");
   for (i = 0; argv[i]; i++)
     printf("[%s] ", argv[i]);
   printf("\n");
#endif
   execvp(shav[0],argv);
   error("execvp %s\n",shav[0]);
   fail();
}
