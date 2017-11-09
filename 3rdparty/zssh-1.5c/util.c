/*
 ** util.c
 ** 
 ** Made by (Matthieu Lucotte)
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Tue Oct  2 20:28:27 2001 Matthieu Lucotte
 ** Last update Mon Sep  1 23:01:34 2003 
 */

#include "zssh.h"


/* shift position i by n chars
 * Ex : str_shift("1234567",2,3) -> "1267"
 *                   |||
 */
void	str_shift(str,i,n)
char	*str;
int	i;
int	n;
{
   int	j;
   
   for (j = i;str[j + n];j++)
      str[j] = str[j + n];
   str[j] = str[j + n];
}


char	*str_n_dup(str,n)
char	*str;
int	n;
{
   char	*pt;
   int	i;
   int	len;
   
   len = min(strlen(str),n);
   pt = smalloc(len + 1);
   for (i = 0;i < len;i++)
      pt[i] = str[i];
   pt[len] = 0;
   return (pt);
}


char    *str_cat(str1,str2)
char    *str1;
char    *str2;
{
   int  i;
   int  len1;
   int  len2;
   char *str_res;
   
   len1 = strlen(str1);
   len2 = strlen(str2);
   if ((str_res = smalloc(len1 + len2 + 1)) == 0)
      return (0);
   for (i = 0;i < len1;i++)
      str_res[i] = str1[i];
   for (i = 0;i <= len2;i++)
      str_res[len1 + i] = str2[i];
   return (str_res);
}


void    str_sub_repl(str,sub_beg,sub_len,sub_repl)
char    **str;
int     sub_beg;
int     sub_len;
char    *sub_repl;
{  
   char *s1;
   char *s2;
   
   s1 = s2 = str_n_dup(*str,sub_beg);
   s1 = str_cat(s1,sub_repl);
   free(s2);
   s2 = s1;
   s1 = str_cat(s1,*str + sub_beg + sub_len);
   free(s2);
   free(*str);
   *str = s1;
}



void		*smalloc(n)
unsigned int	n;
{
   void		*pt;
   
   if ((pt = malloc(n)) != 0)
      return (pt);
   error(0, "malloc");
   exit (1);
}


/*int	sfork() */
/*{ */
/*   int  pid; */
/*    */
/*   pid = fork(); */
/*   if (pid == -1) */
/*      error(0,"fork"); */
/*   return (pid); */
/*} */

/* sfork(): Exits if unable to fork
 * if pid_child is non zero, also avoids race condition that would occur
 * if the child's pid must be known by the parent *before* the child dies.
 */
int	sfork(volatile int *pid_child)
{
   sigset_t	mask;
   sigset_t	old_mask;
   int		pid;
   
   sigprocmask(SIG_SETMASK, 0, &old_mask);	/* save mask */
   sigprocmask(SIG_SETMASK, 0, &mask);
   sigaddset(&mask, SIGCHLD);
   sigprocmask(SIG_SETMASK, &mask, 0);		/* block SIGCHLD */
   pid = fork();
   if (pid == -1)
      error(0, "fork");
   if (pid)		/* parent process */
      if (pid_child)	
	 *pid_child = pid;
   sigprocmask(SIG_SETMASK, &old_mask, 0);	/* restore old mask */
   return (pid);
}

