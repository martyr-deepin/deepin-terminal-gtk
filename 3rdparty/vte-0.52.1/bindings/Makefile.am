SUBDIRS =

if HAVE_INTROSPECTION
SUBDIRS += gir
endif

if ENABLE_VAPIGEN
SUBDIRS += vala
endif

.DELETE_ON_ERROR:

-include $(top_srcdir)/git.mk
