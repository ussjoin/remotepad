/*
 *  remotepad.c
 *  RemotePad Server
 *
 *  Derived from itp-server.c
 *  Modified by iKawamoto Yosihisa! on 08/09/05.
 *  Copyright 2008, 2009 tenjin.org. All rights reserved.
 *
 */

/*
 * =====================================================================================
 *
 *	  Filename:  itp-server.c
 *
 *    Description:  itp-server --listens for a itp client and accepts mouse requests..
 *
 *	   Version:  1.0
 *	   Created:  02/18/2008 09:18:12 PM
 *
 *	    Author:  Will Dietz (WD), wdietz2@uiuc.edu
 *	   Company:  dtzTech
 *
 * =====================================================================================
 */

/*
    This file is part of iTouchpad.

    iTouchpad is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    iTouchpad is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with iTouchpad.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <net/if.h>
#include <unistd.h>
#include <math.h>
#include <errno.h>
#include <sys/time.h>

#include "config.h"
#include "inputevent.h"
#include "Event.h"

#define kVersionX11 "1.6"

#define SCROLL_AMT 40
#define BUTTON_SCROLL_UP Button5
#define BUTTON_SCROLL_DOWN Button4

#define NButtons 5
int ButtonNumber[NButtons] = {Button1, Button3, Button2, Button4, Button5};

#if !defined(INADDR_LOOPBACK)
#define INADDR_LOOPBACK (uint32_t)0x7f000001
#endif

KeySym *keyboardMapping;
int minKeycode, maxKeycode;
int keysymsPerKeycode;

typedef int SOCKET;


/*-----------------------------------------------------------------------------
 *  Local method declarations
 *-----------------------------------------------------------------------------*/
void handleKeyEvent( Display * dpy, MouseEvent *pEvent );
void simulateKeyWithUnichar(Display *dpy, MouseEvent *pEvent);
KeySym ucs2keysym(long ucs);
int findInterfaceAddresses(SOCKET sockfd);

int main( int argc, char ** argv)
{
	MouseEvent event, prevevent;
	MouseEvent *pEvent = &event;
	prevevent.type = EVENT_NULL;
	prevevent.value = 0;

	Display	*dpy; /* X server connection */
	Window	win;
	XWindowAttributes winattr;
	int xtest_major_version = 0;
	int xtest_minor_version = 0;
	int dummy;

	SOCKET s, s_accept;
	struct sockaddr_in s_add; //from anyone!
	struct sockaddr s_client;
	socklen_t s_client_size = sizeof( struct sockaddr );
	int port = PORT;
	int recvsize;

	int button, yDelta = 0, yTmp;

	printf("RemotePad Server for X11 version %s\n", kVersionX11);
	printf("Application launched.\n");

    /*
	* Open the display using the $DISPLAY environment variable to locate
	* the X server.  See Section 2.1.
	*/
    if ((dpy = XOpenDisplay(NULL)) == NULL) {
	   printf("%s: can't open DISPLAY: %s\n", argv[0], XDisplayName(NULL));
	   exit(1);
    }

    Bool success = XTestQueryExtension(dpy, &dummy, &dummy,
&xtest_major_version, &xtest_minor_version);
    if(success == False || xtest_major_version < 2 ||
(xtest_major_version <= 2 && xtest_minor_version < 2))
    {
	   printf("XTEST extension not supported\n");
	   exit(1);
    }

	/*
	 * create a small unmapped window on a screen just so xdm can use
	 * it as a handle on which to killclient() us.
	 */
	win = XCreateWindow(dpy, DefaultRootWindow(dpy), 0, 0, 1, 1, 0, CopyFromParent, InputOutput, CopyFromParent, 0, (XSetWindowAttributes*)0);

	/*
	 * get keyboard mapping to detect modifier keys for each keysym
	 */
	XDisplayKeycodes(dpy, &minKeycode, &maxKeycode);
	int keycodeCount = maxKeycode - minKeycode + 1;
	keyboardMapping = XGetKeyboardMapping(dpy, minKeycode, keycodeCount, &keysymsPerKeycode);

//network stuff
	//configure socket
	if ( ( s = socket( PF_INET, SOCK_STREAM, 0 ) ) == -1 ) 
	{
		perror ( "Failed to create socket :(" ); 
		exit( 2 );

	}

	int yes = 1;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	memset( &s_add, 0, sizeof( struct sockaddr_in ) );
	s_add.sin_family = AF_INET;
	s_add.sin_port = htons( port );
	s_add.sin_addr.s_addr = INADDR_ANY;

	if ( bind( s, (struct sockaddr * )&s_add, sizeof( struct sockaddr_in ) ) == -1 )
	{
		perror( "Failed to bind socket" );
		exit( 2 );
	}

	if( listen( s , 1 ) )
	{
		perror( "Can't listen!" );
		exit( 2 );
	}

	while( 1 )
	{
		if(!findInterfaceAddresses(s))
			printf("waiting for clients\n");

		struct timeval tv = {5, 0};
		while (1) {
			fd_set fdset;
			FD_ZERO(&fdset);
			FD_SET(s, &fdset);
			select(s+1, &fdset, NULL, NULL, &tv);
			if (FD_ISSET(s, &fdset))
				break;
			// sending a keep-alive event for an X server
			XGetWindowAttributes(dpy, win, &winattr);
		}

		s_accept = accept( s, &s_client, &s_client_size );

		if ( s_accept == -1 )
		{
			perror( "failed to accept!" );
			return -1;
		} else {
			printf("Connected!\n");
		}

		setsockopt(s_accept, SOL_SOCKET, SO_RCVTIMEO, (void *)&tv, sizeof(tv));

		while( 1 )
		{
			recvsize = recv( s_accept, pEvent, sizeof( MouseEvent ), MSG_WAITALL );
			if ( recvsize == sizeof( MouseEvent ) )//got data
			{
				event.type = ntohl(event.type);
				event.value = ntohl(event.value);
				event.tv_sec = ntohl(event.tv_sec);
				event.tv_nsec = ntohl(event.tv_nsec);

				switch( event.type )
				{

					case EVENT_MOUSE_DELTA_X:
						// following event should be EVENT_MOUSE_DELTA_Y
						break;
					case EVENT_MOUSE_DELTA_Y:
					//	printf( "move: %d, %d!\n", pEvent->move_info.dx, pEvent->move_info.dy );
						if (prevevent.type == EVENT_MOUSE_DELTA_X) {
							XTestFakeRelativeMotionEvent( dpy, prevevent.value, event.value, 0 );
						} else {
							// printf( "stray event EVENT_MOUSE_DELTA_Y\n" );
						}

						break;
					case EVENT_MOUSE_DELTA_W:
						//no x-scrolling :-/
						break;
					case EVENT_MOUSE_DELTA_Z:
						//no x-scrolling :-/
						yDelta += event.value;
						if ( yDelta < 0 )//down
						{
							button = BUTTON_SCROLL_DOWN;
							yTmp = - yDelta;
						}
						else
						{
							button = BUTTON_SCROLL_UP;
							yTmp = yDelta;
						}

						// send as many clicks as necessary (ty synergy for this)
						for( ; yTmp >= SCROLL_AMT; yTmp -= SCROLL_AMT )
						{
							XTestFakeButtonEvent( dpy, button, 1, 0 );
							XTestFakeButtonEvent( dpy, button, 0, 0 );
						}

						//fix yTmp:
						if ( yDelta < 0 )//we were scrolling down
						{
							yDelta = -yTmp;
						}
						else
						{
							yDelta = yTmp;
						}

						break;

					case EVENT_MOUSE_DOWN:
						//printf( "mouse down: %d", pEvent->button_info.button );
						button = ButtonNumber[MouseNumber(event.value) % NButtons];
						XTestFakeButtonEvent( dpy, button, 1, 0 );
						break;

					case EVENT_MOUSE_UP:	
						//printf( "mouse up: %d", pEvent->button_info.button );
						button = ButtonNumber[MouseNumber(event.value) % NButtons];
						XTestFakeButtonEvent( dpy, button, 0, 0 );
						break;

					case EVENT_KEY_UP:	
					case EVENT_KEY_DOWN:
						handleKeyEvent( dpy, pEvent );
						break;

					case EVENT_ASCII:
						simulateKeyWithUnichar(dpy, pEvent);
						break;

					default:
						printf( "unknown message type: %d\n", event.type );
						break;
				}
				prevevent = event;

				XFlush( dpy );
			
			}
			else if ( recvsize > 0 )
			{
				// printf( "partial recv!\n" );
			}
			else if ( recvsize == 0 )
			{
				//connection terminated
				close( s_accept );
				break; //exit this while loop, wait for another connection
			}
			else if (errno == EAGAIN) {
				// sending a keep-alive event for an X server
				XGetWindowAttributes(dpy, win, &winattr);
			    // sending a keep-alive packet
			    struct timeval tv;
			    gettimeofday(&tv, NULL);
			    MouseEvent event = {htonl(EVENT_NULL), 0, htonl(tv.tv_sec), htonl(tv.tv_usec*1000)};
			    send(s_accept, (void *)&event, sizeof(event), 0);
			}
			else
			{
				perror( "error in recv" );
				shutdown(s_accept, SHUT_RDWR);
				close(s_accept);
				break;
			}
		}

		printf("Disconnected!\n");

	}

	//shouldn't get here!

	return 0;
}

void handleKeyEvent(Display * dpy, MouseEvent *pEvent) {
	unsigned int keycode = pEvent->value & 0xff;
	int keysym;
	switch (keycode) {
	case kKeycodeLeft:
		keysym = XK_Left;
		break;
	case kKeycodeRight:
		keysym = XK_Right;
		break;
	case kKeycodeDown:
		keysym = XK_Down;
		break;
	case kKeycodeUp:
		keysym = XK_Up;
		break;
	case kKeycodeBackSpace:
		keysym = XK_BackSpace;
		break;
	case kKeycodeReturn:
		keysym = XK_Return;
		break;
	default:
		XBell(dpy, 100);
		return;
		break;
	}
	KeyCode x11Keycode = XKeysymToKeycode(dpy, keysym);
	if (x11Keycode != 0) {
		XTestFakeKeyEvent(dpy, x11Keycode, pEvent->type == EVENT_KEY_DOWN, 0);
	}
}

void simulateKeyWithUnichar(Display *dpy, MouseEvent *pEvent) {
#define kNumModifierKeyState 4
	uint32_t modifierKeyStates[kNumModifierKeyState] = {0, kX11ModifierShift, kX11ModifierMod1, kX11ModifierShift | kX11ModifierMod1};
	KeySym keysym = ucs2keysym(pEvent->value);
	KeyCode x11Keycode = XKeysymToKeycode(dpy, keysym);
	if (x11Keycode != 0) {
		int modifierIndex = 0;
		for (modifierIndex = 0; modifierIndex < kNumModifierKeyState; modifierIndex++)
			if (keyboardMapping[(x11Keycode - minKeycode) * keysymsPerKeycode + modifierIndex] == keysym)
				break;
		if (modifierIndex == kNumModifierKeyState)
			modifierIndex = 0;
		KeyCode shiftKeycode = 0, mod1Keycode = 0;
		if (modifierKeyStates[modifierIndex] & kX11ModifierShift) {
			shiftKeycode = XKeysymToKeycode(dpy, XK_Shift_L);
			if (shiftKeycode == 0)
				shiftKeycode = XKeysymToKeycode(dpy, XK_Shift_R);
		}
		if (modifierKeyStates[modifierIndex] & kX11ModifierMod1)
			mod1Keycode = XKeysymToKeycode(dpy, XK_Mode_switch);
		if (shiftKeycode)
			XTestFakeKeyEvent(dpy, shiftKeycode, True, 0);
		if (mod1Keycode)
			XTestFakeKeyEvent(dpy, mod1Keycode, True, 0);
		XTestFakeKeyEvent(dpy, x11Keycode, True, 0);
		if (shiftKeycode)
			XTestFakeKeyEvent(dpy, shiftKeycode, False, 0);
		if (mod1Keycode)
			XTestFakeKeyEvent(dpy, mod1Keycode, False, 0);
		XTestFakeKeyEvent(dpy, x11Keycode, False, 0);
	}
}

int findInterfaceAddresses(SOCKET sockfd) {
	struct ifconf ifc;
	struct ifreq *ifr, ifrcopy;
	int lastlen = 0;
	int len = 32 * sizeof(struct ifreq);
	char *buf, addr[128], *ptr;
	for (;;) {
		buf = malloc(len);
		if (buf == NULL)
			return 0; // not found
		ifc.ifc_len = len;
		ifc.ifc_buf = buf;
		if (ioctl(sockfd, SIOCGIFCONF, &ifc) < 0) {
			if (errno != EINVAL || lastlen != 0) {
				free(buf);
				return 0; // not found
			}
		} else {
			if (ifc.ifc_len == lastlen)
				break;
			lastlen = ifc.ifc_len;
		}
		len = len * 2;
		free(buf);
	}
	int result = 0; // not found
	char *or = "enter ";
	for (ptr = buf; ptr < buf + ifc.ifc_len; ) {
		ifr = (struct ifreq *)ptr;
#if defined(HAVE_STRUCT_SOCKADDR_SA_LEN)
		len = (sizeof(struct sockaddr) > ifr->ifr_addr.sa_len) ? sizeof(struct sockaddr) : ifr->ifr_addr.sa_len;
#else
		len = sizeof(struct sockaddr);
#endif
		ptr += sizeof(ifr->ifr_name) + len;
		if (ifr->ifr_addr.sa_family != AF_INET)
			continue;
		ifrcopy = *ifr;
		ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);
		if ((ifrcopy.ifr_flags & IFF_UP) == 0)
			continue;
		struct sockaddr_in *sin = (struct sockaddr_in *)&ifrcopy.ifr_addr;
		if (sin->sin_addr.s_addr != htonl(INADDR_LOOPBACK)) {
			printf("%s%s ", or, inet_ntop(AF_INET, &sin->sin_addr, addr, sizeof(addr)));
			result = 1; // found
			or = "or ";
		}
	}
	if (result)
		printf("in your iPhone/iPod touch.\n");
	free(buf);
	return result;
}
