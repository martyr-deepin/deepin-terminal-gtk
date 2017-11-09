/*
 ** globbing.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:09:55 2000 Matthieu Lucotte
 ** Last update Sun Oct  7 01:17:40 2001 Matthieu Lucotte
 */

#include "zssh.h"
#include <glob.h>

void	glob_args(ac,av)
int	*ac;
char	***av;
{
   int		i,j,flags;
   glob_t	glb;
   int		ac2;
   char		**av2;
   
   flags = 0;
#ifdef GLOB_BRACE
   flags |= GLOB_BRACE;
#endif
/*#ifdef GLOB_TILDE */
/*   flags |= GLOB_TILDE; */
/*#endif */
   av2 = smalloc(TAB_STEP * sizeof(char *));
   ac2 = 0; 
   for (i = 0; (*av)[i]; i++)
   {
      if (glob((*av)[i], flags, 0, &glb) != 0 || !glb.gl_pathc)
	 write_vector_word((*av)[i], &ac2, &av2);
      else
      {
	 for (j = 0; glb.gl_pathv[j]; j++)
	    write_vector_word(glb.gl_pathv[j], &ac2, &av2);
      }
      free((*av)[i]);
      globfree(&glb);
   }
   free(*av);
   av2[ac2++] = 0;
   *av = av2;
   *ac = ac2;
}

void	write_vector_word(str,argc,argv)
char	*str;
int	*argc;
char	***argv;
{
   (*argv)[(*argc)++] = strdup(str);
   if (!(*argc % TAB_STEP))
      pc_new_tab(argc,argv);
}
