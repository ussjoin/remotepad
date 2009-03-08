CC= gcc
CFLAGS= -g -O2 -l/usr/X11R6/include -l/usr/X11R7/include -I/usr/X11/include -I../Common
LDFLAGS=  -L/usr/X11R6/lib -L/usr/X11R7/lib -L/usr/X11/lib -lXtst -lX11 -lm 
exec_prefix= ${prefix}
prefix= /usr/local
BINDIR= ${exec_prefix}/bin

PROGNAME= remotepad
OBJS= $(PROGNAME).o ucs2keysym.o

all: $(PROGNAME)

$(PROGNAME):  $(OBJS)
	$(CC) $(LDFLAGS) -o $(PROGNAME) $(OBJS)

.c.o:
	$(CC) $(CFLAGS) -c -o $@ $^$(.ALLSRC)

install: $(PROGNAME)
	cp $(PROGNAME) $(BINDIR)

clean:
	rm -f $(PROGNAME) $(OBJS)

distclean:
	rm -rf $(PROGNAME) $(OBJS) config.h config.log config.status Makefile.bak autom4te.cache .deps
