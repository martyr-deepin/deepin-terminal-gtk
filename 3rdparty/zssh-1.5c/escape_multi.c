/*
 ** escape_multi.c for zssh
 ** 
 ** Made by Matthieu Lucotte
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Thu Jun 29 19:09:46 2000 Matthieu Lucotte
 ** Last update Sun Aug 26 03:47:40 2001 Matthieu Lucotte
 */

#include "zssh.h"

t_escape	escape_tab[] =
{
{ESC_DQUOTES,	pc_escape_double_chr,	'"',	0},
{ESC_SQUOTES,	pc_escape_double_chr,	'\'',	0},
{ESC_BQUOTES,	pc_escape_double_chr,	'`',	0},
{ESC_PARENT,	pc_escape_par,		'(',	')'},
{ESC_BCKSLASH,	pc_escape_backslash,	0,	0},
{ESC_DOLLAR_PAR,pc_escape_dollar_par,	'(',	')'},
{ESC_DOLLAR_BRA,pc_escape_dollar_par,	'[',	']'},
{0,		0,			0,	0} 
};

int		pc_escape_multi(str,i,flags)
char		*str;
int		*i;
int		flags;
{
   int		j;
   int		k;
   t_escape	*pt;
   
   k = 0;
   for (pt = escape_tab;pt->flag;pt++)
   {
      j = 0;
      if (flags & pt->flag && (j = pt->f(str,i,pt->c1,pt->c2)) < 0)
	 return (-1);
      k += j;
   }
   return (k);
}

