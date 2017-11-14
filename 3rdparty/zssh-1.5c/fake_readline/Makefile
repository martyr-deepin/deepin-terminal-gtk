# Generated automatically from Makefile.in by configure.

MAKE		=  gmake
INSTALL		=  /usr/bin/install -c
TAR		=  tar
AR		=  ar
RANLIB		=  ranlib
CC		=  gcc
CFLAGS		=  -g -O2 -Wall -DHAVE_CONFIG_H
CPPFLAGS	=  
LIBS		=  -lreadline  -ltermcap 
LDFLAGS 	=  


NAME	= libreadline.a
SRC	= readline.c
OBJ	= $(SRC:.c=.o)

all : $(NAME)


$(NAME) : $(OBJ)
	-rm $@
	$(AR) cq $@ $(OBJ)
	$(RANLIB) $@


new : clean all


clean :
	-rm *.o *~ *.a \#*\# core $(NAME) typescript nohup.out 

distclean : clean


