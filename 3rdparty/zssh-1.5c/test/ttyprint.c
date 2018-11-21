/* Does roughly a 'cat < local_tty_test.reference_output'
 * except with tty in raw mode
 */

#include "zssh.h"

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


/* not used */
int			gl_master;		/* pty fd */
int			gl_slave;		/* tty fd */
struct winsize		gl_win;

int	ask_user(char *question, int def_ans, int forced_ans)
{
   return (forced_ans);
}


struct termios gl_tt;	/* initial term */
struct termios gl_rtt;	/* raw mode term */
struct termios gl_tt2;	/* ssh mode term */

void
my_init()
{
  if (tcgetattr(0, &gl_tt) < 0)
     error(0, "tcgetattr");
  
  gl_rtt = gl_tt;
  my_cfmakeraw(&gl_rtt);   
  gl_tt2 = gl_rtt;

  fflush(stdout);
  tcsetattr(0, TCSANOW, &gl_rtt);
}


int
main(int ac, char **av)
{
  char buff[30];
  int i, fd;

  /* set tty in raw mode */
  my_init();

  /* dump stdin to file */
  fd = open("local_tty_test.reference_output", O_RDONLY);
  if (fd == -1)
     error(0, "local_tty_test.reference_output");
  while ((i = read(fd, buff, 1)) > 0)
    {
      if (i == 1)
	write(1, buff, 1);
    }
  close(fd);

  /* switch tty back to sane state */
  tcsetattr(0, TCSANOW, &gl_tt);
  return 0;
}


