/*
 ** misc.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:10:19 2000 Matthieu Lucotte
 ** Last update Thu Oct 11 20:36:21 2001 Matthieu Lucotte
 */

#include "zssh.h"


char            *chr2str(chr)
char            chr;
{
   char         *pt;

   pt = smalloc(2 * sizeof(char));
   *pt = chr;
   pt[1] = 0;
   return (pt);
}


char    whitespaces[] =
{
' ',
'\t',
'\n',
0
};


int     mi_is_whitespace(chr)
char    chr;
{
   int  j;
   
   for (j = 0;whitespaces[j];j++)
      if (chr == whitespaces[j])
         return (1);
   return (0);
}

/* exit from program */
void		error(s1,s2)
char		*s1;
char		*s2;
{
   if (!s1)
      perror(s2);
   else
      fprintf(stderr, s1, s2);
   if (getpid() == gl_main_pid)
      done(-1);
   exit (-1);
}

/* just displays an error message */
int		error_msg(s1,s2)
char		*s1;
char		*s2;
{
   if (!s1)
      perror(s2);
   else
      fprintf(stderr, s1, s2);
   return (-1);
}


void	op_shift(argv,n)
char	**argv;
int	n;
{
   int	i;
   
   for (i = 0;i < n;i++)
      if (argv[i])
      {
	 free(argv[i]);
	 argv[i] = 0;
      }
   for (i = n;argv[i];i++)
      argv[i - n] = argv[i];
   argv[i - n] = 0;
}


void	flush(fd)
int	fd;
{
   int	i, mode, tot = 0;
   char	buff[4096];
   
   mode = fcntl(fd,F_GETFL,0);
   fcntl(fd,F_SETFL,mode | O_NONBLOCK);
   do
   {
      tot += i = read(fd,buff,4096);
      usleep(50);
   }
   while (i > 0);
   fcntl(fd,F_SETFL,mode);
#ifdef DEBUG
   printf("flushed fd#%i: %i\n",fd,tot);
#endif
}

/* ask the user a question, answer should be y, Y, n, or N
 * or nothing in which case def_ans is returned
 */
int	ask_user(char *question, int def_ans, int forced_ans)
{
   char	*str;
   char	buf[50];
   int	res = def_ans;

   if (gl_force)
      return (forced_ans);
   if (def_ans)
      str = "[Y/n]";
   else
      str = "[y/N]";
   while (1)
   {
      printf("%s %s: ", question, str);
      fflush(stdout);
      while (read(0, buf, 49) <= 0)
	 ;
      if (buf[0] == '\n')
	 break;
      if (buf[0] == 'y' || buf[0] == 'Y')
      {
	 res = 1;
	 break;
      }
      if (buf[0] == 'n' || buf[0] == 'N')
      {
	 res = 0;
	 break;
      }
   }
   return (res);
}

