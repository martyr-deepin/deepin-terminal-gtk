NULL =

ACLOCAL_AMFLAGS = -I m4

SUBDIRS = src bindings po doc perf

EXTRA_DIST = \
	HACKING \
	autogen.sh \
	ChangeLog.pre-git \
	$(NULL)

DISTCLEANFILES =

if ENABLE_GLADE_CATALOGUE
SUBDIRS += glade
endif

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = vte-$(VTE_API_VERSION).pc

DISTCHECK_CONFIGURE_FLAGS = \
	--enable-gtk-doc \
	--enable-introspection \
	--disable-vala \
	--disable-test-application \
	--disable-silent-rules \
	--with-gtk=$(GTK_API_VERSION)

MAINTAINERCLEANFILES = \
	$(GITIGNORE_MAINTAINERCLEANFILES_TOPLEVEL) \
	$(GITIGNORE_MAINTAINERCLEANFILES_MAKEFILE_IN) \
	$(GITIGNORE_MAINTAINERCLEANFILES_M4_LIBTOOL) \
	$(NULL)

# Build ChangeLog from GIT  history
ChangeLog:
	$(AM_V_GEN) if test -d $(top_srcdir)/.git; then \
		GIT_DIR="$(top_srcdir)/.git" git log --stat > $@; \
	fi

dist: ChangeLog

.PHONY: ChangeLog

-include $(top_srcdir)/git.mk
