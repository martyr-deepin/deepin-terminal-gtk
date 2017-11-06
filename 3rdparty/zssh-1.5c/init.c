/*
 ** init.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:10:01 2000 Matthieu Lucotte
 ** Last update Sun Sep 21 23:36:59 2003 
 */

#include "zssh.h"
#include "version.h"


int			gl_master;		/* pty fd */
int			gl_slave;		/* tty fd */

int			gl_main_pid;
volatile sig_atomic_t	gl_child_output;	/* pid of child handling output from the pty */
volatile sig_atomic_t	gl_child_shell;		/* pid of shell (ssh) */
volatile sig_atomic_t	gl_child_rz;		/* pid of child forked for use in the local shell */

int			gl_local_shell_mode;

volatile sig_atomic_t	gl_interrupt;
volatile sig_atomic_t	gl_repeat;     /* repeat action forever */
int			gl_force;	/* don't ask user questions */

struct termios		gl_tt;	/* initial term */
struct termios		gl_rtt;	/* raw mode term */
struct termios		gl_tt2;	/* ssh mode term */
struct winsize		gl_win;

sigset_t		gl_sig_mask;

char			gl_escape; /* gl_escape = 'X' -> escape seq is ^X */
char			**gl_shav; /* remote shell argv, defaults to ssh -e none  */


void	init_gl(int ac, char **av)
{
   gl_master = gl_slave = 0;
   gl_main_pid = getpid();
   gl_child_shell = gl_child_output = 0;
   gl_child_rz = 0;
   gl_force = 0;
   sigemptyset(&gl_sig_mask);
   sigprocmask(SIG_SETMASK, &gl_sig_mask, 0);
   gl_local_shell_mode = 0;
   gl_interrupt = 0;
   gl_escape = '@';
   gl_shav = smalloc(4 * sizeof(char*));
   if (strstr(av[0],"ztelnet"))
   {
      gl_shav[0] = "telnet";
      gl_shav[1] = "-8";
      gl_shav[2] = "-E";
      gl_shav[3] = 0;
      
   }
   else
   {
      gl_shav[0] = "ssh";
      gl_shav[1] = "-e";
      gl_shav[2] = "none";
      gl_shav[3] = 0;
   }
   
   if (tcgetattr(0, &gl_tt) < 0)
      error(0, "tcgetattr");
   if (ioctl(0, TIOCGWINSZ, (char *)&gl_win) < 0)
      error(0, "ioctl TIOCGWINSZ");
   
   gl_rtt = gl_tt;
   my_cfmakeraw(&gl_rtt);   
   gl_tt2 = gl_rtt;
}

void	version(int exit_prog)
{
   printf("zssh version");
   printf(ZSSH_VERSION);
   printf("\nCopyright (C) 2001 Matthieu Lucotte <gounter@users.sourceforge.net>\n");
   printf("zssh comes with ABSOLUTELY NO WARRANTY. Use at your own risk.\n");
   printf("This is free software, and you are welcome to redistribute it\n");
   printf("under certain conditions.\n");
   printf("See the GNU General Public License for more details.\n");
   
   if (exit_prog)
      exit (0);
}

void	usage()
{
   printf("\
Usage: zssh    [zssh options] [--] [ssh options]\n\
       ztelnet [zssh options] [--] [telnet options]\n\
\n\
  Options:\n\
    -f                Do not ask user any question\n\
    --force            \n\
\n\
    -h                This help\n\
    --help            \n\
\n\
    -s  cmd           run cmd as remote shell instead of the\n\
    --shell cmd       default \"ssh -e none\" (zssh) \n\
                           or \"telnet -8 -E\" (ztelnet) \n\
                      ex: zssh -s \"rsh -x\" \n\
\n\
    -V                show version\n\
    --version         \n\
\n\
    -z ^X             set escape sequence to ^X\n\
    --zssh-escape ^X  \n\
\n\
  '--' may be used to separate zssh options from ssh ones \n\
  Other options are passed verbatim to ssh/telnet.\n\
  See also zssh/ssh/telnet man pages for more details\n\
");
   
   exit (1);
}

/* set escape key
 * str : "^X"
 * -> set gl_escape to X
 */
int	set_escape(char *str)
{
   if (!str || !str[0] || str[0] != '^')
   {
      printf("Invalid escape sequence\n");
      return -1;
   }
   gl_escape = str[1];
   if ('a' <= gl_escape && gl_escape <= 'z')
      gl_escape += 'A' - 'a';
   return 0;
}

/* Returns the key to press to generate the esc sequence
 * ^@ -> C-Space
 * ^X -> C-x
 */
char	*escape_help()
{
   static char	str[40];
   
   if (gl_escape == '@')
      sprintf(str,"C-Space");
   else
      sprintf(str,"C-%c", tolower(gl_escape));
   return (str);
}

void	command_line_options(argc,argv)
int	*argc;
char	***argv;
{
   int	ac = *argc;
   char	**av = *argv;
   int	i,j;
   int	shift;
   int	endzsshargs = 0;
   
   for (i = 1; i < ac && !endzsshargs; )
   {
      shift = 0;
      if (!strcmp(av[i], "--"))
      {
	 endzsshargs = 1;
	 shift = 1;
      }
      if ((!strcmp(av[i], "-h") || !strcmp(av[i], "--help")))
	 usage();
      if ((!strcmp(av[i], "-V") || !strcmp(av[i], "--version")))
	 version(1);
      if ((!strcmp(av[i], "-z") || !strcmp(av[i], "--zssh-escape")))
      {
	 if (i+1 == ac || strlen(av[i+1]) != 2 || set_escape(av[i+1]) < 0)
	    usage();
	 shift = 2;
      }
      if (!strcmp(av[i], "-s") || !strcmp(av[i], "--shell"))
      {
	 if (i+1 == ac)
	    usage();
	 free(gl_shav);
	 if (pc_test_escapes(av[i+1]) < 0)
	    error("%s: parse error\n", av[i+1]);
	 pc_split_words(av[i+1], &j, &gl_shav);
	 pc_quote_removal(gl_shav, &j);
	 shift = 2;
      }
      if (!strcmp(av[i], "-f") || !strcmp(av[i], "--force"))
      {
	 gl_force = 1;
	 shift = 1;
      }
      if (shift)
      {
	 ac -= shift;
	 for (j = i + shift; av[j]; j++)
	    av[j - shift] = av[j];
	 av[j - shift] = 0;
      }
      else
	 i++;
   }
   *argc = ac;
   *argv = av;
}


void			init(argc,argv)
int			*argc;
char			***argv;
{
   char			*str;

#ifdef HAVE_LIBREADLINE
   initialize_readline();
#endif
   init_gl(*argc,*argv);
   if ((str = getenv("ZSSHESCAPE")))
      if (set_escape(str) < 0)
	 printf("Warning: invalid ZSSHESCAPE variable value\n");
   
   command_line_options(argc,argv);

   getmaster();
   getslave();   
   
   /* set current tty to raw mode */
   tcsetattr(0, TCSAFLUSH, &gl_rtt);
   
   signal(SIGCHLD, sigchld_handler);
}



