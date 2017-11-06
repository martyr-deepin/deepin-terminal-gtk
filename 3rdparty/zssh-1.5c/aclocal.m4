
dnl stolen and modified from readline, wich itself seems to have taken it from bash
AC_DEFUN(BASH_CHECK_LIB_TERMCAP,
[
if test "X$bash_cv_termcap_lib" = "X"; then
_bash_needmsg=yes
else
AC_MSG_CHECKING(which library has the termcap functions)
_bash_needmsg=
fi
AC_CACHE_VAL(bash_cv_termcap_lib,
[AC_CHECK_LIB(termcap, tgetent, bash_cv_termcap_lib=libtermcap,
    [AC_CHECK_LIB(curses, tgetent, bash_cv_termcap_lib=libcurses,
        [AC_CHECK_LIB(ncurses, tgetent, bash_cv_termcap_lib=libncurses,
            bash_cv_termcap_lib=libtermcap)])])])
if test "X$_bash_needmsg" = "Xyes"; then
AC_MSG_CHECKING(which library has the termcap functions)
fi
AC_MSG_RESULT(using $bash_cv_termcap_lib)
dnl if test $bash_cv_termcap_lib = gnutermcap && test -z "$prefer_curses"; then
dnl LDFLAGS="$LDFLAGS -L./lib/termcap"
dnl TERMCAP_LIB="./lib/termcap/libtermcap.a"
dnl TERMCAP_DEP="./lib/termcap/libtermcap.a"
dnl elif test $bash_cv_termcap_lib = libtermcap && test -z "$prefer_curses"; then
if test $bash_cv_termcap_lib = libtermcap && test -z "$prefer_curses"; then
TERMCAP_LIB=-ltermcap
TERMCAP_DEP=
elif test $bash_cv_termcap_lib = libncurses; then
TERMCAP_LIB=-lncurses
TERMCAP_DEP=
else
TERMCAP_LIB=-lcurses
TERMCAP_DEP=
fi
])

