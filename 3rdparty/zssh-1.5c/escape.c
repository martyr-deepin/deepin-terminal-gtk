/*
 ** escape.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:09:39 2000 Matthieu Lucotte
 ** Last update Sun Sep 30 21:12:31 2001 Matthieu Lucotte
 */

#include "zssh.h"

int		pc_escape_double_chr(str,i,chr,c2)
char		*str;
int		*i;
char		chr;
char		c2;
{
   int		j;
   
   if (str[*i] != chr)
      return (0);
   for ((*i)++;str[*i] && str[*i] != chr;)
      if ((j = pc_escape_backslash(str,i,0,0)) < 0)
	 return (-1);
      else
	 if (!j)
	    (*i)++;
   if (!str[*i])
      return (error_msg("Unmatched %s\n",chr2str(chr)));
   (*i)++;
   return (1);
}

int		pc_escape_par(str,i,c1,c2)
char		*str;
int		*i;
char		c1;
char		c2;
{
   int		n;
   int		j;
   
   if (str[*i] != c1)
      return (0);
   n = 1;
   for ((*i)++;str[*i];)
      if ((j = pc_escape_multi(str,i,ESC_COMMON)) < 0)
	 return (-1);
      else
	 if (!j)
	 {
	    if (str[*i] == c1)
	       n++;
	    if (str[*i] == c2)
	       n--;
	    if (!n)
	       break;
	    (*i)++;
	 }
   if (!str[*i])
      return (error_msg("Unmatched (\n",""));
   (*i)++;
   return (1);
}


int		pc_escape_backslash(str,i,c1,c2)
char		*str;
int		*i;
char		c1;
char		c2;
{
   if (str[*i] != '\\')
      return (0);
   (*i)++;
   if (!str[*i])
      return (error_msg("Premature end of line\n",""));
   (*i)++;
   return (1);
}



int		pc_escape_dollar_par(str,i,c1,c2)
char		*str;
int		*i;
char		c1;
char		c2;
{
   int		n;
   int		j;
   
   if (str[*i] != '$' || str[*i + 1] != c1)
      return (0);
   for (n = 1, *i += 2;str[*i];)
      if ((j = pc_escape_multi(str,i,ESC_COMMON | ESC_PARENT)) < 0)
	 return (-1);
      else
	 if (!j)
	 {
	    if (str[*i] == '$' && str[*i + 1] == c1)
	    {
	       (*i)++;
	       n++;
	    }
	    if (str[*i] == c2)
	       n--;
	    if (!n)
	       break;
	    (*i)++;
	 }
   if (!str[*i])
      return (error_msg("Unmatched $(\n",""));
   (*i)++;
   return (1);
}
