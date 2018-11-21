/*
 ** parse.h for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:10:32 2000 Matthieu Lucotte
 ** Last update Thu Jun 29 19:10:33 2000 Matthieu Lucotte
 */

#ifndef   __ESCAPE_H__
#define   __ESCAPE_H__

#define TAB_STEP        512


typedef struct
{
   char		*str;
   long		(*f)(long, long);
   int		prio;
}		t_arith_op;


#include <pwd.h>

typedef struct
{
   char		*user;
   char		*dir;
}		t_tilde_ent;

#define TILDE_TAB_STEP		100
#define TILDE_SEARCH_STEP	10

typedef struct
{
   t_tilde_ent	*tilde_tab;
   int		tilde_tab_size;
}		t_pc_env;

#define ESC_DQUOTES	1
#define ESC_SQUOTES	2
#define ESC_BCKSLASH	4
#define ESC_PARENT	8
#define ESC_DOLLAR_PAR	16
#define ESC_DOLLAR_BRA	32
#define ESC_BQUOTES	64
#define ESC_COMMON	(ESC_DQUOTES | ESC_SQUOTES | ESC_BCKSLASH)
#define ESC_SPLIT	(ESC_DQUOTES | ESC_SQUOTES | ESC_BQUOTES | \
			 ESC_BCKSLASH | ESC_DOLLAR_PAR | ESC_DOLLAR_BRA)


typedef struct
{
   int		flag;
   int		(*f)(char *str, int *i, char c1, char c2);
   char		c1;
   char		c2;
}		t_escape;

#endif /* __ESCAPE_H__ */
