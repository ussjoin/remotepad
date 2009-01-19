/*
 *  Event.h
 *  RemotePad Server
 *
 *  Created by iKawamoto Yosihisa! on 08/08/27.
 *  Copyright 2008, 2009 tenjin.org. All rights reserved.
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

#define EVENT_NULL               0
/* $NetBSD: wsconsio.h,v 1.88 2007/08/27 02:01:23 macallan Exp $ */
#define EVENT_KEY_UP             1       /* key code */
#define EVENT_KEY_DOWN           2       /* key code */
#define EVENT_ALL_KEYS_UP        3       /* void */
#define EVENT_MOUSE_UP           4       /* button # (leftmost = 0) */
#define EVENT_MOUSE_DOWN         5       /* button # (leftmost = 0)  */
#define EVENT_MOUSE_DELTA_X      6       /* X delta amount */
#define EVENT_MOUSE_DELTA_Y      7       /* Y delta amount */
#define EVENT_MOUSE_ABSOLUTE_X   8       /* X location */
#define EVENT_MOUSE_ABSOLUTE_Y   9       /* Y location */
#define EVENT_MOUSE_DELTA_Z      10      /* Z delta amount */
#define EVENT_MOUSE_ABSOLUTE_Z   11      /* Z location */
#define EVENT_SCREEN_SWITCH      12      /* New screen number */
#define EVENT_ASCII              13      /* key code is already ascii */
#define EVENT_MOUSE_DELTA_W      14      /* W delta amount */
#define EVENT_MOUSE_ABSOLUTE_W   15      /* W location */

// key codes
#define kKeycodeLeft             123
#define kKeycodeRight            124
#define kKeycodeDown             125
#define kKeycodeUp               126

struct mouseEvent {
	uint32_t type;
	int32_t  value;
	struct timespec time;
};

#define MouseNumber(v)			((int)(v) & 0xff)
#define MouseClickCount(v)		((int)(v) >> 8)
#define MouseEventValue(n,c)	(((int)(c) << 8) | (int)(n) & 0xff)
