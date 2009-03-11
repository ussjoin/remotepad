/*
 *  Version.h
 *  RemotePad, RemotePad Server
 *
 *  Created by iKawamoto Yosihisa! on 09/03/07.
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

// version strings
#define kVersionRemotePad	@"1.4"
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
#define kVersionMac			@"2.2 for Mac OS X 10.5"
#else
#define kVersionMac			@"2.2 for Mac OS X 10.4"
#endif
#define kVersionX11			"1.9"
#define kVersionWindows		"1.8"

// current version
#define kVersionRemotePadCurrent	0x01010400
#define kVersionMacCurrent			0x02020200
#define kVersionX11Current			0x03010900
#define kVersionWindowsCurrent		0x04010800

// keyboard supported version
#define kVersionRemotePadKeyboard	0x01010400
#define kVersionMacKeyboard			0x02020200
#define kVersionX11Keyboard			0x03010800
#define kVersionWindowsKeyboard		0x04010800
