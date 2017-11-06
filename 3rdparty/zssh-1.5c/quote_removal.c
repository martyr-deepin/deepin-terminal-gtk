/*
 ** quote_removal.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:10:43 2000 Matthieu Lucotte
 ** Last update Sat Oct  6 23:53:06 2001 Matthieu Lucotte
 */

#include "zssh.h"

int		pc_remove_backslash(str,i)
char		*str;
int		*i;
{
   if (str[*i] != '\\')
      return (0);
   str_shift(str,*i,1);
   if (!str[*i])
      return (-1);
   (*i)++;
   return (1);
}

int		pc_remove_double_chr(str,i,chr)
char		*str;
int		*i;
char		chr;
{
   str_shift(str,*i,1);
   while (str[*i] && str[*i] != chr)
      if (pc_remove_backslash(str,i) <= 0)
	 (*i)++;
   if (!str[*i])
      return (-1);
   str_shift(str,*i,1);
   return (1);
}

void		pc_quote_removal(av,ac)
char		**av;
int		*ac;
{
   int		i;
   int		j;
   char		*str;
   
   for (i = 0;i < *ac;i++)
      if ((str = av[i]))
      {
	 if (!strcmp(str,"#"))
	 {
	    op_shift(av + i,*ac - i - 1);
	    *ac = i + 1;
	 }
	 else
	    for (j = 0;str[j];)
	       if (str[j] == '"' || str[j] == '\'')
		  pc_remove_double_chr(str, &j, str[j]);
	       else
		  if (pc_remove_backslash(str, &j) <= 0)
		     j++;
      }
}

