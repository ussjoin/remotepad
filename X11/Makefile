CFLAGS= -g -O2 -Wall -Werror -I ../Common -I/usr/X11R6/include -I/usr/X11R7/include -I/usr/X11/include
LDFLAGS= -L/usr/X11R6/lib -L/usr/X11R7/lib -L/usr/X11/lib -lX11 -lXtst -lm

OBJS= remotepad.o

all: remotepad

remotepad:  $(OBJS)

clean:
	rm -f remotepad $(OBJS)
