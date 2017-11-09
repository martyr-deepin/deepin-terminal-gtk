/*
 ** readline.c
 ** 
 ** Made by (Matthieu Lucotte)
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Sat Oct  6 16:45:52 2001 Matthieu Lucotte
 ** Last update Sat Oct  6 16:58:54 2001 Matthieu Lucotte
 */

#include <stdlib.h>
#include <stdio.h>

char	*readline(char *prompt)
{
   char	*line;
   int	i;
   
   printf("%s", prompt);
   fflush(stdout);
   line = malloc(100 * sizeof(char));
   fgets(line, 100 * sizeof(char), stdin);
   for (i = 0; line[i]; i++)
      if (line[i] == '\n')
	 line[i] = 0;
   return (line);
}

void	add_history(char *str)
{
   
}
