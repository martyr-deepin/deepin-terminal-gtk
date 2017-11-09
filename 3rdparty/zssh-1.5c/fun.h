
/* completion.c */
void initialize_readline(void);
char **zssh_completion(char *text, int start, int end);
char *command_generator(const char *text, int state);
char *tilde_generator(char *text, int state);
char *fake_generator(const char *text, int state);

/* doit.c */
void doinput(void);
void dooutput(void);
void doshell(int ac, char **av, char **shav);

/* escape.c */
int pc_escape_double_chr(char *str, int *i, char chr, char c2);
int pc_escape_par(char *str, int *i, char c1, char c2);
int pc_escape_backslash(char *str, int *i, char c1, char c2);
int pc_escape_dollar_par(char *str, int *i, char c1, char c2);

/* escape_multi.c */
int pc_escape_multi(char *str, int *i, int flags);

/* globbing.c */
void glob_args(int *ac, char ***av);
void write_vector_word(char *str, int *argc, char ***argv);

/* init.c */
void init_gl(int ac, char **av);
void version(int exit_prog);
void usage(void);
int set_escape(char *str);
char *escape_help(void);
void command_line_options(int *argc, char ***argv);
void init(int *argc, char ***argv);

/* main.c */
int main(int argc, char **argv);
int escape_input(int *cc, unsigned char *ibuf);
int escape_input(int *cc, unsigned char *ibuf);
void read_input(int *cc, unsigned char *ibuf);
void rz_mode(void);
void fail(void);
void done(int ret);

/* misc.c */
char *chr2str(char chr);
int mi_is_whitespace(char chr);
void error(char *s1, char *s2);
int error_msg(char *s1, char *s2);
void op_shift(char **argv, int n);
void flush(int fd);
int ask_user(char *question, int def_ans, int forced_ans);

/* openpty.c */
void getmaster(void);
void getslave(void);
void getmaster(void);
void getslave(void);
void getmaster(void);
void getslave(void);
void getmaster(void);
void getslave(void);
void my_tcsetpgrp(int fd, int pgrpid);
void my_cfmakeraw(struct termios *pt);
void testslave(char *ttyname);
void initslave(void);
void call_grantpt(void);

/* pc_test_escapes.c */
int pc_test_escapes(char *str);

/* quote_removal.c */
int pc_remove_backslash(char *str, int *i);
int pc_remove_double_chr(char *str, int *i, char chr);
void pc_quote_removal(char **av, int *ac);

/* signal.c */
void print_process_status(int pid, int s);
RETSIGTYPE sigchld_handler(int sig);
RETSIGTYPE sigint_handler(int sig);
RETSIGTYPE sigwinch_handler(int sig);

/* split_words.c */
void pc_new_tab(int *argc, char ***argv);
void pc_mk_word(char **str, int *pos, int *argc, char ***argv);
int pc_ok_split(char *comm, int pos, int i);
void pc_split_words(char *comm, int *argc, char ***argv);

/* tilde_expansion.c */
char *pc_get_tilde_expansion(char *pattern);
int pc_tilde_expansion(char **str);

/* util.c */
void str_shift(char *str, int i, int n);
char *str_n_dup(char *str, int n);
char *str_cat(char *str1, char *str2);
void str_sub_repl(char **str, int sub_beg, int sub_len, char *sub_repl);
void *smalloc(unsigned int n);
int sfork(volatile int *pid_child);

/* zmodem.c */
char *zprompt(void);
int zparse(char **str, char ***av, int *ac);
int zrun(char **av);
int zaction(char **av, int master, int slave);

/* zmodem_act.c */
void zact_shell(char **av, int master);
void zact_help(char **av, int master);
void zact_version(char **av, int master);
void zact_cd(char **av, int master);
void zact_suspend(char **av, int master);
void zact_disconnect(char **av, int master);
void zact_repeat(char **av, int master);
void zact_hook_sub(char **av, int master);
void zact_hook(char **av, int master);
void zact_escape(char **av, int master);
void zact_exit(char **av, int master);
