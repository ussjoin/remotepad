/*
 *  remotepadwin.cpp
 *  RemotePad Server
 *
 *  Derived from itp-server-win.cpp
 *  Modified by iKawamoto Yosihisa! on 08/09/19.
 *  Copyright 2008, 2009 tenjin.org. All rights reserved.
 *
 */

/*
 * =====================================================================================
 *
 *	  Filename:  itp-server-win.cpp
 *
 *    Description:  itp-server --listens for a itp client and accepts mouse requests..
 *
 *	   Version:  1.0
 *	   Created:  02/21/2008 05:01AM
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

#include <tchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <winsock.h>
#if !defined(SD_BOTH)
#define SD_BOTH 2
#endif

#include "inputevent.h"
typedef unsigned long uint32_t;
typedef long int32_t;
struct timespec {
	__time32_t tv_sec;
	long tv_nsec;
};
#include "Event.h"
#include "Version.h"

//dang windows lack of compliance
#ifndef MSG_WAITALL
//#define MSG_WAITALL 0x08
//we define it as zero, since I can't get it to work.
#define MSG_WAITALL 0
#endif

void handleKeyEvent( MouseEvent *pEvent );
void simulateKeyWithUnichar(MouseEvent *pEvent);

int _tmain(int argc, _TCHAR* argv[])
{
	MouseEvent event, prevevent;
	MouseEvent *pEvent = &event;
	//POINT pt;
	prevevent.type = EVENT_NULL;
	prevevent.value = 0;
	
	SOCKET s, s_accept;
	struct sockaddr_in s_add; //from anyone!
	struct sockaddr s_client;
	int s_client_size = sizeof( struct sockaddr );
	int port = PORT;
	int recvsize;
	int button;

	fprintf(stderr, "RemotePad Server for Windows version %s\n", kVersionWindows);
	fprintf(stderr, "Application launched.\n");

//network stuff
	//WSA \o/
	WSADATA WsaDat;
	if (WSAStartup(MAKEWORD(1, 1), &WsaDat) != 0)
	{
		perror("WSA Initialization failed.");
	} 

	//configure socket
	if ( ( s = socket( PF_INET, SOCK_STREAM, 0 ) ) == -1 ) 
	{
		perror ( "Failed to create socket :(" ); 
		exit( 2 );

	}

	int yes = 1;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char *)&yes, sizeof(yes));
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
		char myname[128] = "";
		if(gethostname(myname, sizeof(myname)) == 0) {
			struct sockaddr_in addr;
			struct hostent *hptr;
			hptr = gethostbyname(myname);
			if(hptr) {
				fprintf(stderr, "enter ");
				char *or = "";
				for (int i = 0; hptr->h_addr_list[i]; i++) {
					memcpy(&addr.sin_addr, hptr->h_addr_list[i], hptr->h_length);
					fprintf(stderr, "%s%s ", or, inet_ntoa(addr.sin_addr));
					or = "or ";
				}
				fprintf(stderr, "in your iPhone/iPod touch\n");
			} else {
				fprintf(stderr, "waiting for clients\n");
			}
		} else {
			fprintf(stderr, "waiting for clients\n");
		}

		s_accept = accept( s, &s_client, &s_client_size );

		if ( s_accept == -1 )
		{
			perror( "failed to accept!" );
			return -1;
		} else {
			fprintf(stderr, "Connected!\n");
		}

		int timeout = 5*1000; //ms
		setsockopt(s_accept, SOL_SOCKET, SO_RCVTIMEO, (const char *)&timeout, sizeof(timeout));

		MouseEvent versionEvent = {htonl(EVENT_VERSION), htonl(kVersionWindowsCurrent), 0, 0};
		send(s_accept, (const char *)&versionEvent, sizeof(MouseEvent), 0);

		while( 1 )
		{
			recvsize = recv( s_accept, (char *)pEvent, sizeof( MouseEvent ), MSG_WAITALL );
			int errorno = WSAGetLastError();
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
						if (prevevent.type != EVENT_MOUSE_DELTA_X) {
							fprintf(stderr, "stray event EVENT_MOUSE_DELTA_Y\n");
							break;
						}
//						GetCursorPos( &pt );
//						SetCursorPos( pt.x + pEvent->move_info.dx, pt.y + pEvent->move_info.dy );
						//the mouse-accel related code is from synergy, ty
						// save mouse speed & acceleration
						mouse_event(MOUSEEVENTF_MOVE, prevevent.value, event.value, 0, 0);

						break;
					case EVENT_MOUSE_DELTA_W:
						//HWHEEL doesn't seem to work?
						mouse_event( MOUSEEVENTF_HWHEEL, 0, 0, event.value, 0 );
						break;
					case EVENT_MOUSE_DELTA_Z:
						mouse_event( MOUSEEVENTF_WHEEL, 0, 0, -event.value, 0 );
						break;
					
						//NOTE: this assumes the mouse events are lbutton. fine for now, but needs to change!
					case EVENT_MOUSE_DOWN:
						button = MouseNumber(event.value) + 1;
						if ( button == BUTTON_LEFT )
						{
							mouse_event( MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0 );
						}
						else if ( button == BUTTON_RIGHT )
						{
							mouse_event( MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0 );
						}
							
						break;

					case EVENT_MOUSE_UP:
						button = MouseNumber(event.value) + 1;
						if ( button == BUTTON_LEFT )
						{
							mouse_event( MOUSEEVENTF_LEFTUP, 0, 0, 0, 0 );
						}
						else if ( button == BUTTON_RIGHT )
						{
							mouse_event( MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0 );
						}
						break;

					case EVENT_KEY_DOWN:
						handleKeyEvent( pEvent );
						break;

					case EVENT_KEY_UP:
						//printf( "%c", pEvent->key_info.keycode ); 
						//fflush( stdout );
						handleKeyEvent( pEvent );
						break;

					case EVENT_ASCII:
						simulateKeyWithUnichar(pEvent);
						break;

					default:
						//fprintf( stderr, "unknown message type: %d\n", event.type );
						break;
				}
				prevevent = event;

				//XFlush( dpy );

				//sending a ACK packet for the winsock 200ms problem
				MouseEvent event = {htonl(EVENT_NULL), 0, 0, 0};
				send(s_accept, (const char *)&event, sizeof(event), 0);
			}
			else if ( recvsize > 0 )
			{
				fprintf( stderr, "partial recv!" );
			}
			else if ( recvsize == 0 )
			{
				//connection terminated
				closesocket( s_accept );
				break; //exit this while loop, wait for another connection
			}
			else
			{
				if (errorno == WSAETIMEDOUT) {
					// sending a keep-alive packet
					MouseEvent event = {htonl(EVENT_NULL), 0, 0, 0};
					send(s_accept, (const char *)&event, sizeof(event), 0);
				} else {
					if (errorno == WSAECONNRESET) {
						fprintf(stderr, "Connection reset by peer.\n");
					} else if (errorno == WSAENETRESET) {
						fprintf(stderr, "Network dropped connection on reset.\n");
					} else {
						fprintf(stderr, "error in recv: %ld\n", errorno);
					}
					shutdown(s_accept, SD_BOTH);
					closesocket(s_accept);
					break;
				}
			}
		}

		fprintf(stderr, "Disconnected!\n");

	}

	//shouldn't get here!

	return 0;
}

void handleKeyEvent(MouseEvent *pEvent) {
	unsigned int keycode = LOBYTE(pEvent->value);
	byte winKeycode = 0;
	switch (keycode) {
	case kKeycodeLeft:
		winKeycode = VK_LEFT;
		break;
	case kKeycodeUp:
		winKeycode = VK_UP;
		break;
	case kKeycodeRight:
		winKeycode = VK_RIGHT;
		break;
	case kKeycodeDown:
		winKeycode = VK_DOWN;
		break;
	case kKeycodeBackSpace:
		winKeycode = VK_BACK;
		break;
	case kKeycodeReturn:
		winKeycode = VK_RETURN;
		break;
	default:
		MessageBeep(MB_OK);
		return;
		break;
	}
	if (pEvent->type == EVENT_KEY_DOWN) {
		keybd_event(winKeycode, 0, 0, 0);
	} else {
		keybd_event(winKeycode, 0, KEYEVENTF_KEYUP, 0);
	}

}

void simulateKeyWithUnichar(MouseEvent *pEvent) {
	unsigned int charCode = pEvent->value, mod = 0;
	short winKeycode = VkKeyScan(charCode);
	if (winKeycode != -1) {
		byte bKey = LOBYTE(winKeycode), bMod = HIBYTE(winKeycode);
		if (bKey == '\r')
			bMod = 0;
		if (bMod) {
			if (bMod & kWinModifierShift)
				keybd_event(VK_SHIFT, 0, 0, 0);
			if (bMod & kWinModifierControl)
				keybd_event(VK_CONTROL, 0, 0, 0);
			if (bMod & kWinModifierAlternate)
				keybd_event(VK_MENU, 0, 0, 0);
		}
		keybd_event(bKey, 0, 0, 0);
		if (bMod) {
			if (bMod & kWinModifierShift)
				keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
			if (bMod & kWinModifierControl)
				keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
			if (bMod & kWinModifierAlternate)
				keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
		}
		keybd_event(bKey, 0, KEYEVENTF_KEYUP, 0);
	} else {
		MessageBeep(MB_OK);
	}
}
