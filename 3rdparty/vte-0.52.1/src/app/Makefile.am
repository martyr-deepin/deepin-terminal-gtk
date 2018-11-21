bin_PROGRAMS = vte-@VTE_API_MAJOR_VERSION@.@VTE_API_MINOR_VERSION@

CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST =

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_SOURCES = \
	app.cc \
	$(NULL)

nodist_vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_SOURCES = \
	resources.cc \
	$(NULL)

BUILT_SOURCES = $(nodist_vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_SOURCES)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_CPPFLAGS = \
	-DG_LOG_DOMAIN=\"Vte\" \
	-DLOCALEDIR='"$(localedir)"' \
	-I$(top_srcdir)/src \
	-I$(top_srcdir)/src/vte \
	-I$(top_builddir)/src/vte \
	$(AM_CPPFLAGS) \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_CXXFLAGS = \
	$(APP_CFLAGS) \
	$(WARN_CXXFLAGS) \
	$(AM_CXXFLAGS) \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_LDFLAGS = \
	$(AM_LDFLAGS) \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_LDADD = \
	$(top_builddir)/src/libvte-$(VTE_API_VERSION).la \
	$(APP_LIBS) \
	$(NULL)

CLEANFILES += \
	resources.cc \
	$(NULL)

EXTRA_DIST += \
	app.gresource.xml \
	appmenu.ui \
	search-popover.ui \
	window.ui \
	$(NULL)

resources.cc: app.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(srcdir) $(srcdir)/app.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(srcdir) --generate-source --c-name app $<

.DELETE_ON_ERROR:

-include $(top_srcdir)/git.mk
