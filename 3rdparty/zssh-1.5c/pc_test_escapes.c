/*
 ** pc_test_escapes.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:10:38 2000 Matthieu Lucotte
 ** Last update Thu Jun 29 19:10:39 2000 Matthieu Lucotte
 */

#include "zssh.h"

int		pc_test_escapes(str)
char		*str;
{
   int		i;
   int		j;
   
   for (i = 0;str[i];)
      if ((j = pc_escape_multi(str,&i,ESC_COMMON | ESC_PARENT)) < 0)
	 return (-1);
      else
	 if (!j)
	    i++;
   return (1);
}
