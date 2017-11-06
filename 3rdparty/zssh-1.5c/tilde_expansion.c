/*
 ** tilde_expansion.c
 ** 
 ** Made by (Matthieu Lucotte)
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Sun Oct  7 01:04:37 2001 Matthieu Lucotte
 ** Last update Sun Oct  7 01:25:03 2001 Matthieu Lucotte
 */

#include "zssh.h"

char                    *pc_get_tilde_expansion(pattern)
char                    *pattern;
{
   char                 *str;
   struct passwd        *pass;
   
   if (!*pattern)
   {
      if ((str = getenv("HOME")))
         return (str);
      else
         return (getpwuid(getuid())->pw_dir);
   }
   pass = getpwnam(pattern);
   if (!pass)
      return (0);
   return (pass->pw_dir);
}

int             pc_tilde_expansion(str)
char            **str;
{
   int          i;
   int          j;
   char         *pattern;
   char         *tmp;
   
   for (i = 0; (*str)[i]; )
      if ((j = pc_escape_multi(*str, &i, ESC_COMMON)) < 0)
         return (-1);
      else
         if (!j)
	 {
            if ((*str)[i] == '~')
            {
               for (j = 1; isalnum((*str)[i + j]); )
                  j++;
               pattern = str_n_dup(*str + i++ + 1,j - 1);
               if ((tmp = pc_get_tilde_expansion(pattern)))
               {
                  str_sub_repl(str, --i, j, tmp);
                  i += strlen(tmp);
               }
               free(pattern);
            }
            else
               i++;
	 }
   return (0);
}
