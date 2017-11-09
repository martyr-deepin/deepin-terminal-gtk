
/* opens a new pty/tty and write stuff to it
 */

#include "zssh.h"

int			gl_master;		/* pty fd */
int			gl_slave;		/* tty fd */
struct winsize		gl_win;


struct termios		gl_tt;	/* initial term */
struct termios		gl_rtt;	/* raw mode term */

/* exit from program */
void
error(s1,s2)
     char*s1;
     char*s2;
{
  if (!s1)
    perror(s2);
  else
    fprintf(stderr, s1, s2);
  exit (-1);
}

int	ask_user(char *question, int def_ans, int forced_ans)
{
   return (forced_ans);
}

void
my_init()
{
   if (tcgetattr(0, &gl_tt) < 0)
      error(0, "tcgetattr");
   if (ioctl(0, TIOCGWINSZ, (char *)&gl_win) < 0)
      error(0, "ioctl TIOCGWINSZ");
   
   gl_rtt = gl_tt;
   my_cfmakeraw(&gl_rtt);

   getmaster();
   getslave();

   /* set raw mode */
   tcsetattr(gl_slave, TCSANOW, &gl_rtt);
}

/* print all 256 ascii characters on stdout */
void
char_test()
{
   int i;

   for (i = 0; i < 256; i++)
      printf("testing char %i: '%c'\n", i, i);
}

/* cat stuff to stdout, reading from fd */
void my_cat(int fd)
{
   int i;
   char buff[20];
   
   while ((i = read(fd, buff, 1)) >= 0)
   {
      if (i == 1)
	 write(1, buff, 1);
   }
   printf("read() failed, exiting\n");
}

void
sigusr1_handler(int sig)
{
   exit(0);
}

void
doit(int input, int output)
{
   int parent_pid = getpid();

   signal(SIGUSR1, sigusr1_handler);
   
   if (!fork())
   { /* child: write */
      dup2(output, 1);
      close(output);
      close(input);
      char_test();

      sleep(1);
      kill(parent_pid, SIGUSR1);
   }
   else
   { /* parent: read  */
      /* don't close output, let the child kill us instead otherwise
       * it doesn't work in the pty->tty case
       */ 
      my_cat(input);
   }   
}

void usage()
{
   printf("usage: local_tty_test tty|pty\n");
   exit(1);
}

int
main(int ac, char **av)
{
   my_init();   
   
   fflush(stdout);

   if (ac != 2)
      usage();
   if (!strcmp(av[1], "tty"))      
      doit(gl_master, gl_slave);  /* write to the tty, read from pty */
   else if (!strcmp(av[1], "pty"))      
      doit(gl_slave, gl_master);  /* write to the pty, read from tty */
   else
      usage();   
   return 0;   
}

