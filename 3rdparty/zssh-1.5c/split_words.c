/*
 ** split_words.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:11:06 2000 Matthieu Lucotte
 ** Last update Sat Oct  6 23:40:56 2001 Matthieu Lucotte
 */

#include "zssh.h"

void	pc_new_tab(argc,argv)
int	*argc;
char	***argv;
{
   char	**pt;
   
   pt = smalloc((*argc + TAB_STEP) * sizeof(char *));
   memcpy(pt, *argv, *argc * sizeof(char *));
   free(*argv);
   *argv = pt;
}


void	pc_mk_word(str,pos,argc,argv)
char	**str;
int	*pos;
int	*argc;
char	***argv;
{
   int	len;
   
   if ((len = *pos))
   {
      (*argv)[(*argc)++] = str_n_dup(*str,len);
      if (!(*argc % TAB_STEP))
	 pc_new_tab(argc,argv);
      *str += len;
      *pos = 0;
   }
   while (**str && mi_is_whitespace(**str))
      (*str)++; 
}

int		pc_ok_split(comm,pos,i)
char		*comm;
int		pos;
int		i;
{
   if ((!pos || mi_is_whitespace(comm[pos - 1])))
      return (1);
   return (0);
}

void	pc_split_words(comm,argc,argv)
char	*comm;
int	*argc;
char	***argv;
{
   int	pos;
   int	i;
   
   *argv = smalloc(TAB_STEP * sizeof(char *));
   *argc = 0;
   while (mi_is_whitespace(*comm))
      comm++;
   for (pos = 0;comm[pos];)
      if ((i = pc_escape_multi(comm,&pos,ESC_COMMON)) <= 0)
      {
	 if (mi_is_whitespace(comm[pos]))
	    pc_mk_word(&comm,&pos,argc,argv);
	 else
	    pos++;
      }
   pc_mk_word(&comm,&pos,argc,argv);
   (*argv)[(*argc)++] = 0;
}


