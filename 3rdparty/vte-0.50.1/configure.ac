m4_define([version_major],0)
m4_define([version_minor],50)
m4_define([version_micro],1)
m4_define([version_triplet],version_major.version_minor.version_micro)

AC_PREREQ([2.63])
AC_INIT([vte],
        [version_triplet],
        [http://bugzilla.gnome.org/enter_bug.cgi?product=vte],
        [vte])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([src/vteapp.c])
AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.9 foreign no-dist-gzip dist-bzip2 -Wno-portability])

m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

if test -z "$enable_maintainer_mode"; then
  enable_maintainer_mode=yes
fi
AM_MAINTAINER_MODE([enable])

################################################################################
# GTK+
################################################################################

AC_MSG_CHECKING([which gtk+ version to compile against])
AC_ARG_WITH([gtk],
  [AS_HELP_STRING([--with-gtk=3.0|3.90],[which gtk+ version to compile against (default: 3.0)])],
  [case "$with_gtk" in
     3.0) ;;
     3.9[02468]) ;;
     2.0) AC_MSG_ERROR([unsupported gtk version $with_gtk specified]) ;;
     *) AC_MSG_ERROR([invalid gtk version $with_gtk specified]) ;;
   esac],
  [with_gtk=3.0])
AC_MSG_RESULT([$with_gtk])

case "$with_gtk" in
  3.0) GTK_API_VERSION=3.0
       GTK_API_MAJOR_VERSION=3
       GTK_API_MINOR_VERSION=0
       GTK_REQUIRED=3.8.0
       GTK_MIN_REQUIRED=3.8
       GTK_MAX_ALLOWED=3.20
       VTE_API_MAJOR_VERSION=2
       VTE_API_MINOR_VERSION=91
       GLADE_API_VERSION=2.0
       ;;
  3.9[02468]) GTK_API_VERSION=4.0
              GTK_API_MAJOR_VERSION=4
              GTK_API_MINOR_VERSION=0
              GTK_REQUIRED=3.89.0
              GTK_MIN_REQUIRED=3.8
              GTK_MAX_ALLOWED=3.20
              VTE_API_MAJOR_VERSION=3
              VTE_API_MINOR_VERSION=91
              # GLADE_API_VERSION=4.0 ?
              # remove the following when they're ready
              enable_glade_catalogue=no
              enable_introspection=no
              enable_vala=no
              enable_test_application=no
             ;;
esac

VTE_API_VERSION=$VTE_API_MAJOR_VERSION.$VTE_API_MINOR_VERSION

AC_SUBST([VTE_API_VERSION])
AC_SUBST([VTE_API_VERSION_U],[AS_TR_SH([$VTE_API_VERSION])])
AC_SUBST([VTE_API_MAJOR_VERSION])
AC_SUBST([VTE_API_MINOR_VERSION])
AC_SUBST([GTK_API_VERSION])
AC_SUBST([GTK_API_MAJOR_VERSION])
AC_SUBST([GTK_API_MINOR_VERSION])

################################################################################
# Libtool versioning
################################################################################
m4_define([lt_revision], m4_if(m4_eval(version_minor%2),1,0,version_micro))
m4_define([lt_age], m4_eval(version_minor*100+version_micro-lt_revision))
m4_define([lt_current], m4_eval(version_major+lt_age))
m4_define([lt_triplet],lt_current:lt_revision:lt_age)

LT_VERSION_INFO="lt_triplet()"
AC_SUBST([LT_VERSION_INFO])

################################################################################

# Check for programs
PKG_PROG_PKG_CONFIG
AC_PROG_CC
AC_PROG_CXX
AC_USE_SYSTEM_EXTENSIONS
AC_HEADER_STDC
AM_PROG_CC_C_O
AC_PROG_SED

AX_CXX_COMPILE_STDCXX([11])

AC_SYS_LARGEFILE

# Initialize libtool
LT_PREREQ([2.2])
LT_INIT
LT_LANG([C])
LT_LANG([C++])

AM_CONDITIONAL([HAVE_GCC],[test "$GCC" = "yes"])
AM_CONDITIONAL([HAVE_GXX],[test "$GXX" = "yes"])

################################################################################
# Enable debugging messages and additional run-time checks.
################################################################################

AC_ARG_ENABLE([debug],
              [AS_HELP_STRING([--enable-debug],
                              [enable extra debugging checks and logging messages])],
              [],[enable_debug=no])
if test "x$enable_debug" = "xyes" ; then
        AC_MSG_RESULT([enabling debug checks and messages])
        AC_DEFINE(VTE_DEBUG,1,[Enable debugging messages.])
fi

################################################################################
# i18n
################################################################################

IT_PROG_INTLTOOL([0.35.0])

GETTEXT_PACKAGE=vte-$VTE_API_VERSION
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",
                   [Package translatable messages domain name.])
AM_GLIB_GNU_GETTEXT
AC_CHECK_DECLS(bind_textdomain_codeset,,,[#include "libintl.h"])

################################################################################
# Compilation
################################################################################

m4_define([compiler_flags_common],[ dnl
  -pipe dnl
  -Wall dnl
  -Wcast-align dnl
  -Wendif-labels dnl
  -Werror=declaration-after-statement dnl
  "-Werror=format=2 -Werror=format-nonliteral -Werror=format-security" dnl
  -Werror=implicit-function-declaration dnl
  -Werror=init-self dnl
  -Werror=missing-include-dirs dnl
  -Werror=missing-prototypes dnl
  -Werror=pointer-arith dnl
  -Wextra dnl
  -Wfloat-equal dnl
  -Wlogical-op dnl
  -Wmisleading-indentation dnl
  -Wmissing-declarations dnl
  -Wmissing-include-dirs dnl
  -Wmissing-format-attribute dnl
  -Wmissing-noreturn dnl
  -Wno-missing-field-initializers dnl
  -Wno-switch-enum dnl
  -Wno-unused-parameter dnl
  -Wno-packed dnl
  -Wshadow dnl
  -Wsign-compare dnl
  -Wstrict-aliasing=2 dnl
  -Wundef dnl
  -Wuninitialized dnl
  -Wunsafe-loop-optimizations dnl
  -Wwrite-strings dnl
  -fno-common dnl
  -fdiagnostics-show-option dnl
  -fno-strict-aliasing dnl
  -fstack-protector dnl
  -fstack-protector-strong dnl
  -fno-semantic-interposition dnl
  -Wno-deprecated-declarations dnl
])

m4_define([compiler_flags_only_c],[ dnl
  -Waggregate-return dnl
  -Wimplicit dnl
  -Wnested-externs dnl
  -Wold-style-definition dnl
  -Wstrict-prototypes dnl
])

m4_define([compiler_flags_only_cxx],[ dnl
  -Wstrict-null-sentinel dnl
  -fno-rtti dnl
  -fno-exceptions dnl
  -fvisibility=hidden dnl
  -fvisibility-inlines-hidden dnl
])

CC_CHECK_FLAGS_APPEND([AM_CFLAGS],[CFLAGS],[compiler_flags_common compiler_flags_only_c])

AC_LANG_PUSH([C++])
CC_CHECK_FLAGS_APPEND([AM_CXXFLAGS],[CXXFLAGS],[compiler_flags_common compiler_flags_only_cxx])
AC_LANG_POP([C++])

if test "$cc_cv_cxx_CXXFLAGS__fvisibility_hidden" != "yes"; then
  AC_MSG_ERROR([$CXX doesn't support required flag -fvisibility=hidden])
fi

##########################################################
# Check for -Bsymbolic-functions linker flag used to avoid
# intra-library PLT jumps, if available.
##########################################################

AC_ARG_ENABLE([Bsymbolic],
  [AS_HELP_STRING([--disable-Bsymbolic],
                  [disable linking with -Bsymbolic])],
  [],[enable_Bsymbolic=yes])

VTE_LDFLAGS=
if test "$enable_Bsymbolic" != "no"; then
  CC_CHECK_LDFLAGS(["-Wl,-Bsymbolic-functions"],
    [VTE_LDFLAGS="$VTE_LDFLAGS -Wl,-Bsymbolic-functions"],
    [if test "$enable_Bsymbolic" = "auto"; then
       AC_MSG_WARN([-Bsymbolic not supported by ld; disabling])
       enable_Bsymbolic=no
     else
       AC_MSG_ERROR([-Bsymbolic requested but not supported by ld. Use --disable-Bsymbolic to disable])
     fi])

  AC_LANG_PUSH([C++])
  CC_CHECK_LDFLAGS(["-Wl,-Bsymbolic-functions"],
    [VTE_CXXLDFLAGS="$VTE_CXXLDFLAGS -Wl,-Bsymbolic-functions"],
    [if test "$enable_Bsymbolic" = "auto"; then
       AC_MSG_WARN([-Bsymbolic not supported by cxx ld; disabling])
       enable_Bsymbolic=no
     else
       AC_MSG_ERROR([-Bsymbolic requested but not supported by cxx ld. Use --disable-Bsymbolic to disable])
     fi])
  AC_LANG_POP([C++])
fi

AC_SUBST([VTE_LDFLAGS])
AC_SUBST([VTE_CXXLDFLAGS])

################################################################################
# Core
################################################################################

GLIB_REQUIRED=2.40.0
GIO_REQUIRED=2.40.0
PANGO_REQUIRED=1.22.0
GNUTLS_REQUIRED=3.2.7
PCRE2_REQUIRED=10.21

# GNUTLS

AC_MSG_CHECKING([whether gnutls support is requested])
AC_ARG_WITH([gnutls],
  [AS_HELP_STRING([--without-gnutls],[Disable gnutls support])],
  [],[with_gnutls=yes])
AC_MSG_RESULT([$with_gnutls])

GNUTLS_PKGS=
if test "$with_gnutls" = "yes"; then
  GNUTLS_PKGS="gnutls >= $GNUTLS_REQUIRED"

  AC_DEFINE([WITH_GNUTLS],[1],[Define to 1 to enable gnutls support])
fi

AM_CONDITIONAL([WITH_GNUTLS],[test "$with_gnutls" = "yes"])

# GLIB tools

AC_PATH_PROG([GLIB_GENMARSHAL],[glib-genmarshal])
AC_PATH_PROG([GLIB_MKENUMS],[glib-mkenums])

VTE_DEFAULT_TERM=xterm-256color
AC_DEFINE_UNQUOTED(VTE_DEFAULT_TERM,"$VTE_DEFAULT_TERM",[The default value $TERM is set to.])

# Check for headers.
AC_CHECK_HEADERS([sys/select.h sys/syslimits.h sys/termios.h sys/wait.h stropts.h termios.h util.h wchar.h pty.h])
AC_HEADER_TIOCGWINSZ

# Check for how to open a new PTY. We support posix_openpt and BSDs openpty

AC_CHECK_FUNCS([posix_openpt grantpt unlockpt ptsname],[],
  [AC_MSG_ERROR([no support for Unix98 PTY found])])

# Misc PTY handling functions
AC_CHECK_FUNCS([cfmakeraw fork setsid setpgid getpgid tcgetattr tcsetattr])

# Misc I/O routines.
AC_CHECK_FUNCS([pread pwrite])
AC_CHECK_FUNCS([explicit_bzero])

# for vtespawn
AC_CHECK_HEADERS([sys/resource.h])
AC_CHECK_FUNCS([fdwalk])

# Math functions
AC_CHECK_FUNC(floor,,AC_CHECK_LIB(m,floor,LIBS=["$LIBS -lm"]))
AC_CHECK_FUNCS([ceil floor round])

# Search for the required modules.

VTE_PKGS="glib-2.0 >= $GLIB_REQUIRED gobject-2.0 pango >= $PANGO_REQUIRED gtk+-$GTK_API_VERSION >= $GTK_REQUIRED gobject-2.0 gio-2.0 gio-unix-2.0 zlib libpcre2-8 >= $PCRE2_REQUIRED $GNUTLS_PKGS"
PKG_CHECK_MODULES([VTE],[$VTE_PKGS])
AC_SUBST([VTE_PKGS])

PKG_CHECK_MODULES([GLIB],[glib-2.0 >= $GLIB_REQUIRED])
PKG_CHECK_MODULES([GOBJECT],[gobject-2.0])
PKG_CHECK_MODULES([GTK],[gtk+-$GTK_API_VERSION >= $GTK_REQUIRED])

wcs_funcs_includes="
#ifdef HAVE_STRING_H
# if !STDC_HEADERS && HAVE_MEMORY_H
#  include <memory.h>
# endif
# include <string.h>
#else
# ifdef HAVE_STRINGS_H
#  include <strings.h>
# endif
#endif
#ifdef HAVE_WCHAR_H
# include <wchar.h>
#endif
"

AC_CHECK_TYPES(wint_t, AC_DEFINE(HAVE_WINT_T, , [Defined when the wint_t type is supported]), ,$wcs_funcs_includes)

################################################################################
# Glade catalogue
################################################################################

AC_MSG_CHECKING([whether to install the glade catalogue])
AC_ARG_ENABLE([glade-catalogue],
  [AS_HELP_STRING([--disable-glade],[Disable installing the glade catalogue])],
  [],[enable_glade_catalogue=no])
AC_MSG_RESULT([$enable_glade_catalogue])

if test "$enable_glade_catalogue" = "yes"; then
  GLADE_CATALOGUE_DIR="$($PKG_CONFIG --variable=catalogdir gladeui-$GLADE_API_VERSION)"
  GLADE_ICON_DIR="$($PKG_CONFIG --variable=pixmapdir gladeui-$GLADE_API_VERSION)"
  GLADE_MODULE_DIR="$($PKG_CONFIG --variable=moduledir gladeui-$GLADE_API_VERSION)"

  if test -z "$GLADE_CATALOGUE_DIR" -o -z "$GLADE_MODULE_DIR"; then
    AC_MSG_ERROR([gladeui-$GLADE_API_VERSION not found])
  fi

  AC_SUBST([GLADE_CATALOGUE_DIR])
  AC_SUBST([GLADE_ICON_DIR])
  AC_SUBST([GLADE_MODULE_DIR])
fi
  
AM_CONDITIONAL([ENABLE_GLADE_CATALOGUE],[test "$enable_glade_catalogue" = "yes"])

# ********
# Bindings
# ********

# No automagic please!
if test -z "$enable_introspection"; then
  enable_introspection=yes
fi

m4_ifdef([GOBJECT_INTROSPECTION_CHECK],
  [GOBJECT_INTROSPECTION_CHECK([0.9.0])],
  [if test "$enable_introspection" = "yes"; then
    AC_MSG_ERROR([[Introspection requested but M4 macros not installed. Try --disable-introspection]])
   fi
   AM_CONDITIONAL([HAVE_INTROSPECTION],[false])])

# No automagic please!
if test -z "$enable_vala"; then
  enable_vala=yes
fi

m4_ifdef([VAPIGEN_CHECK],
  [VAPIGEN_CHECK([0.24])],
  [if test "$enable_vala" = "yes"; then
     AC_MSG_ERROR([[Vala requested but M4 macros not installed. Try --disable-vala]])
   fi
   AM_CONDITIONAL([ENABLE_VAPIGEN],[false])])

# ****************
# Test Application
# ****************

AC_MSG_CHECKING([whether to install the vala test application])
AC_ARG_ENABLE([test-application],
        [AS_HELP_STRING([--disable-test-application],[Disable installing the vala test application])],
        [],[enable_test_application=$enable_vala])
AC_MSG_RESULT([$enable_test_application])

AM_PROG_VALAC([0.24.0],[],[
  if test "$enable_vala" != "no"; then
    AC_MSG_ERROR([Vala requested but vala compiler >= 0.24.0 not found])
  fi])

PKG_CHECK_MODULES([GTK_3_16],[gtk+-$GTK_API_VERSION >= 3.16],[have_gtk_3_16=yes],[have_gtk_3_16=no])
AM_PROG_VALAC([0.31.1],[have_vala_0_31=yes],[have_vala_0_31=no])

AM_CONDITIONAL([ENABLE_TEST_APPLICATION],[test "$enable_test_application" = "yes"])
AM_CONDITIONAL([HAVE_GTK_3_16],[test "$have_gtk_3_16" = "yes"])
AM_CONDITIONAL([HAVE_VALA_0_31],[test "$have_vala_0_31" = "yes"])

# ***************
# Auxiliary tools
# ***************

AC_ARG_VAR([GLIB_COMPILE_RESOURCES],[the glib-compile-resources programme])
if test -z "$GLIB_COMPILE_RESOURCES"; then
  AC_PATH_PROG([GLIB_COMPILE_RESOURCES],[glib-compile-resources],[])
  if test -z "$GLIB_COMPILE_RESOURCES"; then
    AC_MSG_ERROR([glib-compile-resources not found])
  fi
fi

AC_ARG_VAR([GPERF],[the gperf programme])
if test -z "$GPERF"; then
  AC_PATH_PROG([GPERF],[gperf],[])
  if test -z "$GPERF"; then
    AC_MSG_ERROR([gperf not found])
  fi
fi

AC_ARG_VAR([XMLLINT],[the xmllint programme])
if test -z "$XMLLINT"; then
  AC_PATH_PROG([XMLLINT],[xmllint],[])
  if test -z "$XMLLINT"; then
    AC_MSG_ERROR([xmllint not found])
  fi
fi

################################################################################

GTK_DOC_CHECK([1.13],[--flavour no-tmpl])

AC_SUBST([GLIB_PREFIX],[$($PKG_CONFIG --variable=prefix glib-2.0)])
AC_SUBST([GTK_PREFIX],[$($PKG_CONFIG --variable=prefix gtk+-$GTK_API_VERSION)])

################################################################################

AC_SUBST([VTE_MAJOR_VERSION],[version_major])
AC_SUBST([VTE_MINOR_VERSION],[version_minor])
AC_SUBST([VTE_MICRO_VERSION],[version_micro])

AC_SUBST([AM_CPPFLAGS])
AC_SUBST([AM_CFLAGS])
AC_SUBST([AM_CXXFLAGS])
AC_SUBST([AM_LDFLAGS])

################################################################################

AC_CONFIG_FILES([
Makefile
src/Makefile
src/vte.gresource.xml
src/vte/vteversion.h
bindings/Makefile
bindings/gir/Makefile
bindings/vala/Makefile
perf/Makefile
po/Makefile.in
doc/Makefile
doc/openi18n/Makefile
doc/reference/Makefile
doc/reference/version.xml
glade/Makefile
])

AC_CONFIG_FILES([vte-${VTE_API_VERSION}.pc:vte.pc.in],[VTE_API_VERSION=${VTE_API_VERSION}])
AC_CONFIG_FILES([glade/vte-${VTE_API_VERSION}.xml.in:glade/vte.xml.in.in],[VTE_API_VERSION=${VTE_API_VERSION}])

AC_OUTPUT

#####################
# Print configuration
#####################
cat <<EOF | tee -a config.log

## -------------- ##
## Configuration. ##
## -------------- ##

Configuration for libvte $VERSION for gtk+-$GTK_API_VERSION
	GNUTLS: $with_gnutls
	Installing Glade catalogue: $enable_glade_catalogue
	Debugging: $enable_debug
	Introspection: $enable_introspection
        Vala bindings: $enable_vala
        Test application: $enable_test_application
EOF
