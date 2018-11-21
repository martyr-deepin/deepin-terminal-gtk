CLEANFILES =
DISTCLEANFILES =
EXTRA_DIST =

INTROSPECTION_GIRS = Vte-$(VTE_API_VERSION).gir
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(srcdir) --warn-all
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

Vte-@VTE_API_VERSION@.gir: $(top_builddir)/src/libvte-$(VTE_API_VERSION).la
Vte_@VTE_API_VERSION_U@_gir_INCLUDES = Pango-1.0 Gdk-$(GTK_API_VERSION) Gtk-$(GTK_API_VERSION)
Vte_@VTE_API_VERSION_U@_gir_CFLAGS = $(VTE_CFLAGS) -DVTE_COMPILATION -I$(top_builddir)/src/vte -I$(top_srcdir)/src/vte
Vte_@VTE_API_VERSION_U@_gir_LIBS = $(top_builddir)/src/libvte-$(VTE_API_VERSION).la
Vte_@VTE_API_VERSION_U@_gir_EXPORT_PACKAGES = vte-$(VTE_API_VERSION)
Vte_@VTE_API_VERSION_U@_gir_SCANNERFLAGS = --c-include "vte/vte.h"
Vte_@VTE_API_VERSION_U@_gir_FILES = \
	$(wildcard $(top_srcdir)/src/vte/*.h) \
	$(wildcard $(top_builddir)/src/vte/*.h) \
	$(top_srcdir)/src/pty.cc \
	$(top_srcdir)/src/vtegtk.cc \
	$(top_builddir)/src/vtetypebuiltins.cc \
	$(NULL)

girdir = $(datadir)/gir-1.0
nodist_gir_DATA = $(INTROSPECTION_GIRS)

typelibdir = $(libdir)/girepository-1.0
nodist_typelib_DATA = $(INTROSPECTION_GIRS:.gir=.typelib)

CLEANFILES += $(nodist_gir_DATA) $(nodist_typelib_DATA)

.DELETE_ON_ERROR:

include $(INTROSPECTION_MAKEFILE)
-include $(top_srcdir)/git.mk
