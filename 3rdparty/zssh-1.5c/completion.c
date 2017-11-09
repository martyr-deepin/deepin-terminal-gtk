/*
 ** completion.c
 ** 
 ** Made by (Matthieu Lucotte)
 ** Login   <gounter@users.sourceforge.net>
 ** 
 ** Started on  Sun Oct  7 01:43:23 2001 Matthieu Lucotte
 ** Last update Mon Sep  1 22:57:07 2003 
 */

#include "zssh.h"
#include <readline/readline.h>
#include <readline/history.h>

#ifdef HAVE_LIBREADLINE

/* for readline < 4.2 we have to use username_completion_function
 *                4.2 we have to use rl_username_completion_function
 * and so on ...
 */
#ifdef HAVE_READLINE_4_2_OR_GREATER
#define RL_USERNAME_COMPLETION_FUNCTION	rl_username_completion_function
#define RL_FILENAME_COMPLETION_FUNCTION	rl_filename_completion_function
#define RL_COMPLETION_MATCHES		rl_completion_matches

#else /* readline < 4.2 */

#define RL_USERNAME_COMPLETION_FUNCTION username_completion_function
#define RL_FILENAME_COMPLETION_FUNCTION filename_completion_function
#define RL_COMPLETION_MATCHES		completion_matches
#endif


/* **************************************************************** */
/*                                                                  */
/*                  Interface to Readline Completion                */
/*                                                                  */
/* **************************************************************** */


/* Tell the GNU Readline library how to complete.  We want to try to complete
 on command names if this is the first word in the line, or on filenames
 if not. */
void	initialize_readline()
{
#ifdef DEBUG
   printf("Using readline library version: %s\n", rl_library_version);
#endif
   /* Allow conditional parsing of the ~/.inputrc file. */
   rl_readline_name = "zssh";
   
   /* inhibit default filename completion
    so that if zssh_completion() fails nothing is completed */
   rl_completion_entry_function = fake_generator;
   /* Tell the completer that we want a crack first. */
   rl_attempted_completion_function = (CPPFunction *) zssh_completion;
   
}

/* Attempt to complete on the contents of TEXT.  START and END bound the
 region of rl_line_buffer that contains the word to complete.  TEXT is
 the word to complete.  We can use the entire contents of rl_line_buffer
 in case we want to do some simple parsing.  Return the array of matches,
 or NULL if there aren't any. */
char		**zssh_completion(text, start, end)
char		*text;
int		start;
int		end;
{
   char		**matches;
   
   matches = (char **)NULL;
/*   printf("text: >%s<\n", text); */
   
   /* If this word is at the start of the line, then it is a command
    to complete.  Otherwise it is the name of a file in the current
    directory. */
   if (!start)
      matches = RL_COMPLETION_MATCHES(text, command_generator);
   else if (text[0] == '~' && !strchr(text, '/'))
      matches = RL_COMPLETION_MATCHES(text, RL_USERNAME_COMPLETION_FUNCTION);
/*    matches = completion_matches(text, tilde_generator); */
   else
      matches = RL_COMPLETION_MATCHES(text, RL_FILENAME_COMPLETION_FUNCTION);
   
   return (matches);
}

/* Generator function for command completion.  STATE lets us know whether
 to start from scratch; without any state (i.e. STATE == 0), then we
 start at the top of the list. */
char		*command_generator(text, state)
const char	*text;
int		state;
{
   static int	list_index, len;
   char		*name;
   
   /* If this is a new word to complete, initialize now.  This includes
    saving the length of TEXT for efficiency, and initializing the index
    variable to 0. */
   if (!state)
   {
      list_index = 0;
      len = strlen (text);
   }
   
   /* Return the next name which partially matches from the command list. */
   while ((name = cmdtab[list_index].name))
   {
      list_index++;
      
      if (strncmp(name, text, len) == 0)
	 return (strdup(name));
   }
   
   /* If no names matched, then return NULL. */
   return ((char *)NULL);
}


/* Generator function for tilde completion.  STATE lets us know whether
 to start from scratch; without any state (i.e. STATE == 0), then we
 start at the top of the list. */
#if 0
char			*tilde_generator(text, state)
char			*text;
int			state;
{
   struct passwd	*pwd;
   static int		len;
   
   /* If this is a new word to complete, initialize now.  This includes
    * saving the length of TEXT for efficiency, and initializing the index
    * variable to 0.
    */
   if (!state)
   {
      pwd = getpwent();
      setpwent();
      len = strlen(text + 1);
   }
   
   rl_filename_completion_desired = 1;
   /* Return the next homedir which partially matches. */
   while ((pwd = getpwent()))
   {
      if (strncmp(pwd->pw_name, text + 1, len) == 0)
	 return (str_cat("~", pwd->pw_name));
   }
   
   /* If no names matched, then return NULL. */
   return ((char *)NULL);
}
#endif /* 0 */

char			*fake_generator(text, state)
const char		*text;
int			state;
{
   return (0);
}

#endif /* HAVE_LIBREADLINE */
