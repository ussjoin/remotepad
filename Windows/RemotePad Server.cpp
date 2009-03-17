/*
 *  RemotePad Server.cpp
 *  RemotePad Server
 *
 *  Created by iKawamoto Yosihisa! on 09/03/11.
 *  Copyright 2009 tenjin.org. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE TENJIN.ORG AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE TENJIN.ORG
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <winsock2.h>
#include <windows.h>
#include <process.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <sys/types.h>
#if !defined(SD_BOTH)
#define SD_BOTH 2
#endif
#include "RemotePad Server.h"

#define WM_TRAYMENU	(WM_USER + 1)
#define WM_NETWORK	(WM_USER + 2)

typedef enum {
	statusNotConnected = 0,
	statusConnected
} connStatus;
typedef enum {
	trayIconNotConnected = 0,
	trayIconConnected
} connTrayIcon;
typedef struct {
	HWND hWnd;
	SOCKET socket;
} ArgList;
typedef unsigned long uint32_t;
typedef long int32_t;
struct timespec {
	__time32_t tv_sec;
	long tv_nsec;
};
#include "Event.h"
#include "Version.h"

#define kMaxLoadString 128
#define kWidthMin 320
#define kHeightMin 300
#define kTrayId 101
#define kNumIPAddresses 8
#define kNumButtons 5
#define kDefaultPort 5583
#define kNumTrayIcons 2

HINSTANCE hInst;
TCHAR szTitle[kMaxLoadString];
TCHAR szWindowClass[kMaxLoadString];
NOTIFYICONDATA trayIcon[kNumTrayIcons];
BOOL bInTray;
SOCKADDR_IN addrList[kNumIPAddresses];
int numAddrs;
int flagButtonDown[kNumButtons] = {MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_XDOWN, MOUSEEVENTF_XDOWN};
int flagButtonUp[kNumButtons] = {MOUSEEVENTF_LEFTUP, MOUSEEVENTF_RIGHTUP, MOUSEEVENTF_MIDDLEUP, MOUSEEVENTF_XUP, MOUSEEVENTF_XUP};
int dataXButton[kNumButtons] = {0, 0, 0, XBUTTON1, XBUTTON2};
int connectionStatus;

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
INT_PTR CALLBACK About(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
void DisplayWindow(HWND hWnd);
void RepaintWindow(HWND hWnd);
void CreateTrayIcons(HWND hWnd, PNOTIFYICONDATA pTrayIcon);
void DisplayTrayMenu(HWND hWnd);
void HideInTray(HWND hWnd, BOOL hide);
void HandleKeyEvent(MouseEvent event);
void SimulateKeyWithUnichar(MouseEvent event);
SOCKET CreateSocket(HWND hWnd);
void ListAddresses();
SOCKET AcceptSocket(HWND hWnd, SOCKET serverSocket);
void CloseSocket(HWND hWnd, SOCKET clientSocket);
void StreamThread(void *args);

int APIENTRY _tWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPTSTR lpCmdLine, int nCmdShow) {
	LoadString(hInstance, IDS_APP_TITLE, szTitle, kMaxLoadString);
	LoadString(hInstance, IDC_REMOTEPADSERVER, szWindowClass, kMaxLoadString);

	if (!hPrevInstance) {
		WNDCLASSEX wcex;
		wcex.cbSize 		= sizeof(WNDCLASSEX);
		wcex.style			= CS_HREDRAW | CS_VREDRAW;
		wcex.lpfnWndProc	= WndProc;
		wcex.cbClsExtra		= 0;
		wcex.cbWndExtra		= 0;
		wcex.hInstance		= hInstance;
		wcex.hIcon			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_REMOTEPADSERVER));
		wcex.hIconSm		= LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_CONNECTED));
		wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
		wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
		wcex.lpszMenuName	= MAKEINTRESOURCE(IDC_REMOTEPADSERVER);
		wcex.lpszClassName	= szWindowClass;
		if (!RegisterClassEx(&wcex))
			return FALSE;
	}

	HWND hWnd;
	hInst = hInstance;
	hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, 0, kWidthMin, kHeightMin, NULL, NULL, hInstance, NULL);
	if (!hWnd)
		return FALSE;

	ShowWindow(hWnd, nCmdShow);
	if (nCmdShow == SW_SHOWMINNOACTIVE) {
		ShowWindow(hWnd, SW_HIDE);
		bInTray = TRUE;
	} else {
		UpdateWindow(hWnd);
		bInTray = FALSE;
	}

	CreateTrayIcons(hWnd, trayIcon);
	Shell_NotifyIcon(NIM_ADD, &trayIcon[trayIconNotConnected]);

	HACCEL hAccelTable;
	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_REMOTEPADSERVER));

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
	int wmId, wmEvent;
	LPMINMAXINFO minInfo;
	static SOCKET serverSocket;
	static SOCKET clientSocket;

	//fprintf(stderr, "message = 0x%04x, wParam = 0x%04x, lParam = 0x%04x\n", message, wParam, lParam);
	switch (message) {
	case WM_CREATE:
		serverSocket = CreateSocket(hWnd);
		connectionStatus = statusNotConnected;
		EnableMenuItem(GetMenu(hWnd), IDM_DISCONNECT, MF_BYCOMMAND | MF_GRAYED);
		ListAddresses();
		break;
	case WM_NETWORK:
		switch (WSAGETSELECTEVENT(lParam)) {
		case FD_ACCEPT:
			clientSocket = AcceptSocket(hWnd, serverSocket);
			break;
		case FD_CLOSE:
			if (connectionStatus == statusConnected)
				CloseSocket(hWnd, clientSocket);
			break;
		}
		break;
	case WM_COMMAND:
		wmId = LOWORD(wParam);
		wmEvent = HIWORD(wParam);
		switch (wmId) {
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			Shell_NotifyIcon(NIM_DELETE, &trayIcon[trayIconNotConnected]);
			DestroyWindow(hWnd);
			break;
		case IDM_TRAY:
			HideInTray(hWnd, TRUE);
			break;
		case IDM_DISCONNECT:
			if (connectionStatus == statusConnected)
				CloseSocket(hWnd, clientSocket);
			break;
		case IDM_OPEN:
			HideInTray(hWnd, FALSE);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_GETMINMAXINFO:
		minInfo = (LPMINMAXINFO)lParam;
		minInfo->ptMinTrackSize.x = kWidthMin;
		minInfo->ptMinTrackSize.y = kHeightMin;
		break;
	case WM_PAINT:
		DisplayWindow(hWnd);
		break;
	case WM_SYSCOMMAND:
		if (wParam == SC_MINIMIZE)
			HideInTray(hWnd, TRUE);
		else
			return DefWindowProc(hWnd, message, wParam, lParam);
		break;
	case WM_CLOSE:
		HideInTray(hWnd, TRUE);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	case WM_TRAYMENU:
		if (wParam == kTrayId) {
			switch (lParam) {
			case WM_RBUTTONDOWN:
				DisplayTrayMenu(hWnd);
				break;
			case WM_LBUTTONDBLCLK:
				HideInTray(hWnd, !bInTray);
				break;
			default:
				break;
			}
		}
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

INT_PTR CALLBACK About(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
	switch (message) {
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;
	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
			EndDialog(hWnd, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}

void DisplayWindow(HWND hWnd) {
	HDC hdc;
	PAINTSTRUCT ps;
	RECT rect;
	RECT labelRect;
	RECT valueRect;

	hdc = BeginPaint(hWnd, &ps);

	GetClientRect(hWnd, &rect);
	labelRect.top = rect.top + 20;
	labelRect.left = rect.left + 20;
#define kMessageValue	180
#define kMessageHeight	20
#define kMessageSpace	10
	labelRect.right = rect.right - 20;
	labelRect.bottom = rect.bottom;
	valueRect.top = labelRect.top;
	valueRect.left = kMessageValue;
	valueRect.right = rect.right - 20;
	valueRect.bottom = rect.bottom;
	TCHAR buf[kMaxLoadString];
	wsprintf(buf, L"%s for Windows", szTitle);
	DrawText(hdc, buf, -1, &labelRect, DT_WORDBREAK);

	labelRect.top += kMessageHeight + kMessageSpace * 2;
	valueRect.top += kMessageHeight + kMessageSpace * 2;
	DrawText(hdc, L"Version:", -1, &labelRect, DT_WORDBREAK);
	wsprintf(buf, L"%S", kVersionWindows);
	DrawText(hdc, buf, -1, &valueRect, DT_WORDBREAK);

	labelRect.top += kMessageHeight + kMessageSpace;
	valueRect.top += kMessageHeight + kMessageSpace;
	DrawText(hdc, L"Server IP addresses:", -1, &labelRect, DT_WORDBREAK);
	if (numAddrs) {
		for (int i = 0; i < numAddrs; i++) {
			wsprintf(buf, L"%S", inet_ntoa(addrList[i].sin_addr));
			DrawText(hdc, buf, -1, &valueRect, DT_WORDBREAK);
			labelRect.top += kMessageHeight;
			valueRect.top += kMessageHeight;
		}
	} else {
		DrawText(hdc, L"cannot detect", -1, &valueRect, DT_WORDBREAK);
		labelRect.top += kMessageHeight;
		valueRect.top += kMessageHeight;
	}

	labelRect.top += kMessageSpace;
	valueRect.top += kMessageSpace;
	DrawText(hdc, L"Port:", -1, &labelRect, DT_WORDBREAK);
	wsprintf(buf, L"%d", kDefaultPort);
	DrawText(hdc, buf, -1, &valueRect, DT_WORDBREAK);

	labelRect.top += kMessageHeight + kMessageSpace;
	valueRect.top += kMessageHeight + kMessageSpace;
	DrawText(hdc, L"Connection status:", -1, &labelRect, DT_WORDBREAK);
	wsprintf(buf, L"%Sconnected", (connectionStatus == statusConnected) ? "" : "not ");
	DrawText(hdc, buf, -1, &valueRect, DT_WORDBREAK);

	EndPaint(hWnd, &ps);
}

void RepaintWindow(HWND hWnd) {
	RECT rect;

	GetClientRect(hWnd, &rect);
	InvalidateRect(hWnd, &rect, true);
	UpdateWindow(hWnd);
}

void CreateTrayIcons(HWND hWnd, PNOTIFYICONDATA pTrayIcon) {
	pTrayIcon[trayIconNotConnected].cbSize = sizeof(NOTIFYICONDATA);
	pTrayIcon[trayIconNotConnected].hIcon = LoadIcon(hInst, MAKEINTRESOURCE(IDI_NOTCONNECTED));
	pTrayIcon[trayIconNotConnected].hWnd = hWnd;
	pTrayIcon[trayIconNotConnected].uCallbackMessage = WM_TRAYMENU;
	pTrayIcon[trayIconNotConnected].uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
	pTrayIcon[trayIconNotConnected].uID = kTrayId;
	LoadString(hInst, IDS_APP_TITLE, pTrayIcon[trayIconNotConnected].szTip, kMaxLoadString);
	pTrayIcon[trayIconConnected].cbSize = sizeof(NOTIFYICONDATA);
	pTrayIcon[trayIconConnected].hIcon = LoadIcon(hInst, MAKEINTRESOURCE(IDI_CONNECTED));
	pTrayIcon[trayIconConnected].hWnd = hWnd;
	pTrayIcon[trayIconConnected].uCallbackMessage = WM_TRAYMENU;
	pTrayIcon[trayIconConnected].uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
	pTrayIcon[trayIconConnected].uID = kTrayId;
	LoadString(hInst, IDS_APP_TITLE, pTrayIcon[trayIconConnected].szTip, kMaxLoadString);
	return;
}

void DisplayTrayMenu(HWND hWnd) {
	HMENU hMenu, hSubMenu;
	POINT point;

	hMenu = LoadMenu(hInst, L"IDC_TRAYMENU");
	hSubMenu = GetSubMenu(hMenu, 0);
	if (connectionStatus == statusConnected)
		EnableMenuItem(hSubMenu, IDM_DISCONNECT, MF_BYCOMMAND | MF_ENABLED);
	else
		EnableMenuItem(hSubMenu, IDM_DISCONNECT, MF_BYCOMMAND | MF_GRAYED);
	GetCursorPos(&point);
	SetForegroundWindow(hWnd);
	TrackPopupMenu(hSubMenu, TPM_BOTTOMALIGN, point.x, point.y, 0, hWnd, NULL);
	DestroyMenu(hMenu);
	return;
}

void HideInTray(HWND hWnd, BOOL hide) {
	if (hide) {
		ShowWindow(hWnd, SW_MINIMIZE);
		ShowWindow(hWnd, SW_HIDE);
	} else {
		ShowWindow(hWnd, SW_SHOW);
		ShowWindow(hWnd, SW_NORMAL);
		SetForegroundWindow(hWnd);
	}
	bInTray = hide;
}

SOCKET CreateSocket(HWND hWnd) {
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 1), &wsaData) != 0)
		return INVALID_SOCKET;

	SOCKET s;
	if ((s = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
		return INVALID_SOCKET;

	int yes = 1;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char *)&yes, sizeof(yes));

	SOCKADDR_IN server;
	memset(&server, 0, sizeof(server));
	server.sin_family = AF_INET;
	server.sin_port = htons(kDefaultPort);
	server.sin_addr.s_addr = htonl(INADDR_ANY);

	if (bind(s, (SOCKADDR *)&server, sizeof(server)) == SOCKET_ERROR)
		return INVALID_SOCKET;

	if (listen(s, 0) == SOCKET_ERROR)
		return INVALID_SOCKET;

	if (WSAAsyncSelect(s, hWnd, WM_NETWORK, FD_ACCEPT|FD_CLOSE) == SOCKET_ERROR)
		return INVALID_SOCKET;

	return s;
}

void ListAddresses() {
	char sHostName[256];
	int i = 0;
	if (gethostname(sHostName, sizeof(sHostName)) == 0) {
		PHOSTENT pHostEnt;
		if ((pHostEnt = gethostbyname(sHostName)) != NULL) {
			for (i = 0; pHostEnt->h_addr_list[i] && i < kNumIPAddresses; i++) {
				memcpy(&addrList[i].sin_addr, pHostEnt->h_addr_list[i], pHostEnt->h_length);
			}
		}
	}
	numAddrs = i;
	return;
}

SOCKET AcceptSocket(HWND hWnd, SOCKET serverSocket) {
	SOCKET clientSocket;
	SOCKADDR clientSockAddr;
	int clientSockLen;

	clientSockLen = sizeof(clientSockAddr);
	clientSocket = accept(serverSocket, &clientSockAddr, &clientSockLen);
	WSAAsyncSelect(clientSocket, hWnd, 0, 0);
	ULONG nonBlocking = 0;
	ioctlsocket(clientSocket, FIONBIO, &nonBlocking);

	connectionStatus = statusConnected;
	RepaintWindow(hWnd);
	Shell_NotifyIcon(NIM_MODIFY, &trayIcon[trayIconConnected]);
	EnableMenuItem(GetMenu(hWnd), IDM_DISCONNECT, MF_BYCOMMAND | MF_ENABLED);

	ArgList args;
	args.hWnd = hWnd;
	args.socket = clientSocket;
	_beginthread(StreamThread, 0, &args);

	return clientSocket;
}

void CloseSocket(HWND hWnd, SOCKET clientSocket) {
	shutdown(clientSocket, SD_BOTH);
	closesocket(clientSocket);
	connectionStatus = statusNotConnected;
	RepaintWindow(hWnd);
	Shell_NotifyIcon(NIM_MODIFY, &trayIcon[trayIconNotConnected]);
	EnableMenuItem(GetMenu(hWnd), IDM_DISCONNECT, MF_BYCOMMAND | MF_GRAYED);
	return;
}

void StreamThread(void *args) {
	HWND hWnd = ((ArgList *)args)->hWnd;
	SOCKET clientSocket = ((ArgList *)args)->socket;
	static MouseEvent event, prevevent;
	int button;

	int timeout = 5*1000; //ms
	setsockopt(clientSocket, SOL_SOCKET, SO_RCVTIMEO, (const char *)&timeout, sizeof(timeout));

	MouseEvent versionEvent = {htonl(EVENT_VERSION), htonl(kVersionWindowsCurrent), 0, 0};
	send(clientSocket, (const char *)&versionEvent, sizeof(versionEvent), 0);

	while (TRUE) {
		int recvsize = recv(clientSocket, (char *)&event, sizeof(event), 0);
		if (recvsize == sizeof(event)) {
			event.type = ntohl(event.type);
			event.value = ntohl(event.value);
			event.tv_sec = ntohl(event.tv_sec);
			event.tv_nsec = ntohl(event.tv_nsec);

			switch (event.type) {
			case EVENT_MOUSE_DELTA_X:
				break;
			case EVENT_MOUSE_DELTA_Y:
				if (prevevent.type == EVENT_MOUSE_DELTA_X)
					mouse_event(MOUSEEVENTF_MOVE, prevevent.value, event.value, 0, 0);
				break;
			case EVENT_MOUSE_DELTA_W:
				mouse_event( MOUSEEVENTF_HWHEEL, 0, 0, event.value, 0 );
				break;
			case EVENT_MOUSE_DELTA_Z:
				mouse_event( MOUSEEVENTF_WHEEL, 0, 0, -event.value, 0 );
				break;
			case EVENT_MOUSE_DOWN:
				button = MouseNumber(event.value);
				if (button < 0 || kNumButtons <= button)
					button = 0;
				mouse_event(flagButtonDown[button], 0, 0, dataXButton[button], 0 );
				break;
			case EVENT_MOUSE_UP:
				button = MouseNumber(event.value);
				if (button < 0 || kNumButtons <= button)
					button = 0;
				mouse_event(flagButtonUp[button], 0, 0, dataXButton[button], 0 );
				break;
			case EVENT_KEY_DOWN:
				HandleKeyEvent(event);
				break;
			case EVENT_KEY_UP:
				HandleKeyEvent(event);
				break;
			case EVENT_ASCII:
				SimulateKeyWithUnichar(event);
				break;
			default:
				break;
			}
			prevevent = event;

			//sending a ACK packet for the winsock 200ms problem
			MouseEvent nullEvent = {htonl(EVENT_NULL), 0, 0, 0};
			send(clientSocket, (const char *)&nullEvent, sizeof(nullEvent), 0);
		} else if (recvsize == 0) {
			connectionStatus = statusNotConnected;
			break;
		} else if (recvsize == SOCKET_ERROR) {
			int errorno = WSAGetLastError();
			if (errorno == WSAETIMEDOUT) {
				// sending a keep-alive packet
				MouseEvent nullEvent = {htonl(EVENT_NULL), 0, 0, 0};
				send(clientSocket, (const char *)&nullEvent, sizeof(nullEvent), 0);
			} else {
				connectionStatus = errorno;
				break;
			}
		}
	}

	RepaintWindow(hWnd);
	Shell_NotifyIcon(NIM_MODIFY, &trayIcon[trayIconNotConnected]);
	EnableMenuItem(GetMenu(hWnd), IDM_DISCONNECT, MF_BYCOMMAND | MF_GRAYED);

	shutdown(clientSocket, SD_BOTH);
	closesocket(clientSocket);

	_endthread();
	return;
}

void HandleKeyEvent(MouseEvent event) {
	unsigned int keycode = LOBYTE(event.value);
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
	if (event.type == EVENT_KEY_DOWN) {
		keybd_event(winKeycode, 0, 0, 0);
	} else {
		keybd_event(winKeycode, 0, KEYEVENTF_KEYUP, 0);
	}
	return;
}

void SimulateKeyWithUnichar(MouseEvent event) {
	unsigned int charCode = event.value, mod = 0;
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
	return;
}
