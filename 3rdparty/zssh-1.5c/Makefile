# Generated automatically from Makefile.in by configure.
# 
# Makefile.in for zssh
# 
# Made by Matthieu Lucotte
# Login   <gounter@users.sourceforge.net>
# 
# Started on  Thu Jun 29 19:04:08 2000 Matthieu Lucotte
# Last update Mon Sep 22 22:18:54 2003 
# 

#System specific vars

prefix		= /usr/local
exec_prefix	= ${prefix}

MAKE		=  make
INSTALL		=  /usr/bin/install -c
TAR		=  tar
AR		=  ar
RANLIB		=  ranlib
CC		=  gcc
CFLAGS		=  -g -O2 -Wall -DHAVE_CONFIG_H  -Ifake_readline
CPPFLAGS	=   -O2
LIBS		=     fake_readline/libreadline.a 
LDFLAGS 	=  
EXTRA_DEPS	=   fake_readline

#uncomment this for debug infos
#CFLAGS += -DDEBUG

# old stuff. safely ignore.
#
# uncomment this if your keyboard doesn't send combined key codes packed
# The ALT-1 key will not be detected in this case, unless DUMB_KEYBOARD
# is defined
#CFLAGS += -DDUMB_KEYBOARD


#End of system specific vars


NAME		= zssh
VERSION		= $(shell cat VERSION)
PRGS		= zssh ztelnet
MANS		= $(PRGS:=.1)
# Files to be installed
FILES		= $(PRGS) $(MANS)
SRC		= completion.c doit.c escape.c escape_multi.c globbing.c init.c main.c misc.c openpty.c pc_test_escapes.c quote_removal.c signal.c split_words.c tilde_expansion.c util.c zmodem.c zmodem_act.c
OBJS		= $(SRC:.c=.o)
INCL		= config.h parse.h zssh.h

# archive and packaging stuff

# only used if you do a 'make rpm'
RPMDIR		= /usr/src/redhat
# where to write archives
BACKDIR		= ${HOME}/backup
# name of symlink to BACKDIR
BACKLINK	= backup
# archives are chown-ed to BACKOWNER:BACKGROUP
BACKOWNER	= 500
BACKGROUP	= $(BACKOWNER)
TGZ		= $(NAME)-$(VERSION).tgz
RPMSPEC		= $(NAME).spec
RPMBUILDARCH	= $(shell rpm --showrc | grep "^build arch" | cut -d: -f2 | xargs echo )

all: $(PRGS)

$(NAME) : $(EXTRA_DEPS) version.h ${OBJS}
	$(CC) -o $(NAME) $(LDFLAGS) $(OBJS) $(LIBS)

ztelnet : $(NAME)
	@-rm $@ > /dev/null 2>&1
	ln $(NAME) $@

install :
	strip $(NAME)
	$(INSTALL) -m 0711 zssh ${exec_prefix}/bin
	ln -f ${exec_prefix}/bin/zssh  ${exec_prefix}/bin/ztelnet
	$(INSTALL) -m 0644 $(MANS) ${prefix}/man/man1

uninstall :
	-cd ${exec_prefix}/bin      && rm $(PRGS)
	-cd ${prefix}/man/man1 && rm $(MANS)

fake_readline : force
	-cd fake_readline && $(MAKE)

lrzsz :
	cd lrzsz-0.12.20 && ./configure --prefix=/usr/local
	cd lrzsz-0.12.20 && $(MAKE)

lrzsz_links :
	ln -s ${exec_prefix}/bin/lrz ${exec_prefix}/bin/rz
	ln -s ${exec_prefix}/bin/lsz ${exec_prefix}/bin/sz
	ln -s ${exec_prefix}/bin/lrb ${exec_prefix}/bin/rb
	ln -s ${exec_prefix}/bin/lsb ${exec_prefix}/bin/sb
	ln -s ${exec_prefix}/bin/lrx ${exec_prefix}/bin/rx
	ln -s ${exec_prefix}/bin/lsx ${exec_prefix}/bin/sx

lrzsz_install :
	cd lrzsz-0.12.20 && $(MAKE) install

# create source archive in ~/backup
tgz $(TGZ) : distclean force
	@cdir=`pwd` && cdir=`basename $$cdir` && cd .. && \
	echo "#################################################" && \
	echo $(TAR) -cvzf "$(BACKDIR)/$(TGZ)" "$$cdir" && \
	echo "#################################################" && echo -n "Press return" && read f && \
	     $(TAR) -cvzf "$(BACKDIR)/$(TGZ)" "$$cdir"
	ln -sf $(BACKDIR) $(BACKLINK)

# create rpm and srpm
rpm : $(RPMSPEC)
	@echo -n "Be sure to 'make tgz' before 'make rpm'. Usually must be root to succeed. Press return if ok" && read f
	cp -f $(BACKLINK)/$(TGZ) $(RPMDIR)/SOURCES
	rpm -ba $(RPMSPEC)
	$(INSTALL) -o $(BACKOWNER) -g $(BACKGROUP) -m 600 $(RPMDIR)/RPMS/$(RPMBUILDARCH)/$(NAME)-$(VERSION)-1.$(RPMBUILDARCH).rpm  $(BACKLINK)
	$(INSTALL) -o $(BACKOWNER) -g $(BACKGROUP) -m 600 $(RPMDIR)/SRPMS/$(NAME)-$(VERSION)-1.src.rpm  $(BACKLINK)


$(RPMSPEC) : $(RPMSPEC:.spec=.spec.tpl)
	echo  "%define ZSSHVER		$(VERSION)" > $(RPMSPEC)
	cat $(RPMSPEC:.spec=.spec.tpl) >> $(RPMSPEC)


version.h : force
	echo '#define ZSSH_VERSION "' `cat VERSION` ', built' `date` '"' > version.h

fun.h : $(SRC)
	protos -o fun.h $(SRC)

TAGS :
	etags *.[ch]

new : clean all

clean :
	-rm *.o *~ *.a \#*\# core $(PRGS) typescript nohup.out $(RPMSPEC) $(BACKLINK)

distclean : clean
	-rm Makefile config.cache config.status config.log config.scan config.h TAGS
	-(cd lrzsz-0.12.20 && $(MAKE) distclean)
	-(cd fake_readline && $(MAKE) distclean)
	-(cd test && $(MAKE) distclean)

autoconf:
	autoconf
	autoheader

force :


$(OBJS) : $(INCL)
init.o : version.h
