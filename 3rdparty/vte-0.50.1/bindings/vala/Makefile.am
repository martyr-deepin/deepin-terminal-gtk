if ENABLE_TEST_APPLICATION
bin_PROGRAMS = vte-@VTE_API_MAJOR_VERSION@.@VTE_API_MINOR_VERSION@
else
noinst_PROGRAMS = vte-@VTE_API_MAJOR_VERSION@.@VTE_API_MINOR_VERSION@
endif

CLEANFILES =
DISTCLEANFILES =
EXTRA_DIST =

# VAPI

VAPIGEN_VAPIS = vte-$(VTE_API_VERSION).vapi

vte-@VTE_API_VERSION@.vapi: $(top_builddir)/bindings/gir/Vte-$(VTE_API_VERSION).gir
vte_@VTE_API_VERSION_U@_vapi_DEPS = \
	glib-2.0 \
	gio-2.0 \
	pango \
	gdk-$(GTK_API_VERSION) \
	gtk+-$(GTK_API_VERSION) \
	$(NULL)
vte_@VTE_API_VERSION_U@_vapi_METADATADIRS = $(srcdir)
vte_@VTE_API_VERSION_U@_vapi_FILES = $(top_builddir)/bindings/gir/Vte-$(VTE_API_VERSION).gir

vapidir = $(datadir)/vala/vapi
nodist_vapi_DATA = $(VAPIGEN_VAPIS)

CLEANFILES += $(nodist_vapi_DATA)

# VALA Test application

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_SOURCES = \
	app.vala \
	config.vapi \
	$(builddir)/vte-$(VTE_API_VERSION).vapi \
	$(NULL)

nodist_vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_SOURCES = \
	appresources.c \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_VALAFLAGS = \
	--target-glib=2.38 \
	--pkg=posix \
	--pkg=gio-2.0 \
	--pkg=gtk+-$(GTK_API_VERSION) \
	--gresources app.gresource.xml \
	$(AM_VALAFLAGS)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_CPPFLAGS = \
	-I$(top_srcdir)/src \
	-I$(top_srcdir)/src/vte \
	-I$(top_builddir)/src/vte \
	$(AM_CPPFLAGS) \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_CFLAGS = \
	-Wno-unused-variable \
	-Wno-unused-but-set-variable \
	$(VTE_CFLAGS) \
	$(AM_CFLAGS) \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_LDFLAGS = \
	$(AM_LDFLAGS) \
	$(NULL)

vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_LDADD = \
	$(top_builddir)/src/libvte-$(VTE_API_VERSION).la \
	$(VTE_LIBS) \
	$(NULL)

if HAVE_VALA_0_31
vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_VALAFLAGS += --disable-since-check
endif

if HAVE_GTK_3_16
vte_@VTE_API_MAJOR_VERSION@_@VTE_API_MINOR_VERSION@_VALAFLAGS += -D GTK_3_16
endif

CLEANFILES += \
	app.c \
	appresources.c \
	$(NULL)

EXTRA_DIST += \
        app.gresource.xml \
	app.ui \
	search-popover.ui \
	$(NULL)

appresources.c: app.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(srcdir) $(srcdir)/app.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(srcdir) --generate --c-name app $<

.DELETE_ON_ERROR:

include $(VAPIGEN_MAKEFILE)
-include $(top_srcdir)/git.mk
