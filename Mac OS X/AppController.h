//
//  AppController.h
//  RemotePad Server
//
//  Derived from an Apple's sample code AppController.h of WiTap.
//  Modified by iKawamoto Yosihisa! on 08/08/17.
//  Modified by Rui Paulo on 23/01/2009.
//  Copyright 2008, 2009 tenjin.org. All rights reserved.
//
//

/*
 
 File: AppController.m
 Abstract: UIApplication's delegate class, the central controller of the
 application.
 
 Version: 1.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

#import "TCPServer.h"
#import "Event.h"

#define kNumUniChar 65536

@interface AppController : NSObject <TCPServerDelegate> {
	TCPServer* _server;
	NSInputStream* _inStream;
	NSOutputStream* _outStream;
	BOOL _inReady;
	BOOL _outReady;
	MouseEvent prevevent;	
	BOOL mouse1Clicked;
	BOOL mouse2Clicked;
	BOOL mouse3Clicked;
	NSThread *streamThread;
	CFRunLoopSourceRef runLoopSource;
	NSTimer *keepAliveTimer;
	int32_t accumuW;
	int32_t accumuZ;
	UCKeyboardLayout *currentKeyboardLayout;
	CGKeyCode charToKey[kNumUniChar];
	UInt32 charToMod[kNumUniChar];
	UCKeyboardLayout *currentKeyboardLayoutKCHR;
	CGKeyCode charToKeyKCHR[kNumUniChar];
	UInt32 charToModKCHR[kNumUniChar];
	
	NSStatusItem *statusItem;
	NSMenuItem *inTheDockItem;
	NSImage *connectedImage;
	NSImage *notConnectedImage;
	
	BOOL notInTheDock;
}
- (void)setup:(id)sender;
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void)applicationTerminated:(NSNotification *)aNotification;
- (void)disconnect:(id)sender;
- (void)_showAlert:(NSString *)title;

- (void)quitMenu:(id)sender;
- (void)aboutMenu:(id)sender;

- (void)mouseDown:(MouseEvent)event0;
- (void)mouseUp:(MouseEvent)event0;
- (void)mouseMoveX:(MouseEvent)x Y:(MouseEvent)y;
- (void)scrollWheelW:(MouseEvent)w Z:(MouseEvent)z;
- (void)scrollWheelZ:(MouseEvent)z;

- (void)addSourceToCurrentRunLoop;
// Client interface for registering commands to process
- (void)requestExitStreamThread;
@end


// These are the CFRunLoopSourceRef callback functions.
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
void RunLoopSourcePerformRoutine (void *info);
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
