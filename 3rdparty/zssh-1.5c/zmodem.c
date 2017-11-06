/*
 ** zmodem.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:11:24 2000 Matthieu Lucotte
 ** Last update Mon Sep  1 23:02:15 2003 
 */

#include "zssh.h"
#include <readline/readline.h>
#include <readline/history.h>

/* prompt one line of input using readline */
char	*zprompt()
{
   static char		*prompt = 0;
   char			*tmp;
   char			*line;
   
   if (!prompt)
   {
      prompt = "zssh > ";
      if ((tmp = getenv("HOSTNAME")))
      {
	 tmp = str_cat("zssh@", tmp);
	 prompt = str_cat(tmp, " > ");
	 free(tmp);
      }
   }
   tcdrain(1);
   tcdrain(0);
   line = readline(prompt);
   if (!line)
      line = strdup("exit\n");
   else
      if (line[0])	/* line != "" */
	 add_history(line);
#ifdef DEBUG
   printf("read: >%s<\n",line);
#endif
   return (line);
}

/* parse a line applying some shell expansions */
int	zparse(str,av,ac)
char	**str;
char	***av;
int	*ac;
{
   if (pc_test_escapes(*str) < 0)
      return (-1);
   if (pc_tilde_expansion(str) < 0)
      return (-1);
   pc_split_words(*str, ac, av);
   if (*ac == 1)
      return (-1);
   pc_quote_removal(*av, ac);
   glob_args(ac, av);
#ifdef DEBUG
   {
      int	i;
      
      for (i = 0; (*av)[i]; i++)
	 printf("arg %i >%s<\n", i, (*av)[i]);
   }
#endif
   return (0);
}


int	zrun(char **av)
{
   int	i,j;
   
   gl_repeat = 0;
   j = 1;
   do
   {
      i = zaction(av, gl_master, gl_slave);
      if (i >= 100)
	 break;
      if (gl_repeat && j)
      {
	 free(av[0]);
	 av++;
      }
      j = 0;
   }
   while (gl_repeat);
   return (i);
}


t_act_tab	cmdtab[] =
{
{"?",		C_HELP,		zact_help},
{"cd",		C_CD,		zact_cd},
{"disconnect",	C_DISCONNECT,	zact_disconnect}, 
{"escape",	C_ESCAPE,      	zact_escape}, 
{"exit",	C_EXIT,		zact_exit},
{"help",	C_HELP,		zact_help},
{"hook",	C_HOOK,		zact_hook},
{"quit",	C_EXIT,		zact_exit}, 
{"repeat",	C_REPEAT,	zact_repeat}, 
{"rz",		C_RZ,		zact_hook_sub}, 
{"suspend",	C_SUSPEND,      zact_suspend},
{"sz",		C_SZ,		zact_hook_sub},  
{"version",	C_VERSION,     	zact_version},
 
{0,		C_SHELL,	zact_shell}
};


int	zaction(av,master,slave)
char	**av;
int	master;
int	slave;
{
   t_act_tab	*pt;
   char	c = 24; /* "^X" */
   int	i = 1;
   
   for (pt = cmdtab; pt->name && strcmp(pt->name, av[0]); pt++)
      ;
   gl_child_rz = 0;
   pt->f(av,master);
   while (gl_child_rz)
      sigsuspend(&gl_sig_mask);
   gl_child_rz = 0;
   if (gl_interrupt)
   {
      printf("\nInterrupted !\n");
      gl_interrupt = 0;
      tcflush(master, TCIOFLUSH);
      tcflush(slave, TCIOFLUSH);
      for (i = 0;i < 99;i++)
      {
	 write(master, &c, 1);
	 tcdrain(master);
      }
      flush(master);
      flush(slave);
      flush(master);
   }
   
/*   tcflush(gl_slave, TCIOFLUSH); */
/*   tcflush(gl_master, TCIOFLUSH); */
/*   kill(gl_child_output, SIGCONT); */
   tcsetattr(gl_slave, TCSANOW, &gl_tt2);
   tcsetattr(0, TCSANOW, &gl_tt);
/*   tcsetattr(gl_slave, TCSAFLUSH, &gl_tt2); */
/*   tcsetattr(0, TCSAFLUSH, &gl_tt); */
   return (pt->n);
}
