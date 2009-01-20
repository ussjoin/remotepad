//
//  MyDocument.m
//  RemotePad Server
//
//  Derived from an Apple's sample code AppController.m of WiTap.
//  Modified by iKawamoto Yosihisa! on 08/08/17.
//  Copyright 2008, 2009 tenjin.org. All rights reserved.
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

#import <Carbon/Carbon.h>
#import "MyDocument.h"
#include <sys/time.h>

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
#define kVersion	@"1.2 for Mac OS X 10.5"
#else
#define kVersion	@"1.2 for Mac OS X 10.4"
#endif

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kGameIdentifier		@"remotepad"

#define delta 5

@implementation MyDocument

- (void) _showAlert:(NSString *)title {
	[message setEditable:YES];
	[message insertText:title];
	[message insertText:@"\n"];
	[message setEditable:NO];
}

- (id)init
{
    self = [super init];
    if (self) {
		CFRunLoopSourceContext context = {0, self, NULL, NULL, NULL, NULL, NULL, NULL, NULL, RunLoopSourcePerformRoutine};

		runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
    }
    return self;
}

- (void) dealloc
{	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
	[_inStream release];
	
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
	[_outStream release];
	
	[_server release];
	
	[self requestExitStreamThread];
	
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	[self _showAlert:[NSString stringWithFormat:@"RemotePad Server version %@", kVersion]];
	[self _showAlert:@"Application launched."];
	[self setup];
}

- (void) setup {
	streamThread = nil;
	
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
	[_inStream release];
	_inStream = nil;
	_inReady = NO;
	
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
	[_outStream release];
	_outStream = nil;
	_outReady = NO;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError* error;
	if(_server == nil || ![_server start:&error]) {
		NSLog(@"Failed creating server: %@", error);
		[self _showAlert:@"Failed creating server"];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}
	
	//[self presentPicker:nil];
	[self _showAlert:[NSString stringWithFormat:@"Waiting with Bonjour (port %d)", [_server port]]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (void) openStreams
{
	streamThread = [NSThread currentThread];
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
	[self addSourceToCurrentRunLoop];
	keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(sendKeepAlive:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] run];
}

- (void)exitStreamThread {
	if (streamThread) {
		if (![streamThread isEqual:[NSThread currentThread]]) {
			fprintf(stderr, "warning: exitStreamThread: invoked from a non streaming thread\n");
		}
		streamThread = nil;
	}
	[NSThread exit];
}

- (CGPoint)getMousePointWithDeltaX:(int)x deltaY:(int)y {
	CGPoint point;
	Point globalPoint;
	CGDirectDisplayID displayID;
	CGDisplayCount displayCnt;
	CGRect disp = CGDisplayBounds(kCGDirectMainDisplay);
	GetGlobalMouse(&globalPoint);
	point.x = globalPoint.h;
	point.y = globalPoint.v;
	if (x == 0 && y == 0)
		return point;

	double accel = 1;
	if (delta < abs(x) || delta < abs(y)) {
		accel = sqrt(x*x+y*y)/delta;
	}
	point.x += x*accel;
	point.y += y*accel;
	if (CGGetDisplaysWithPoint(point, 1, &displayID, &displayCnt) != 0 || displayCnt < 1) {
		CGPoint oldPoint;
		oldPoint.x = globalPoint.h;
		oldPoint.y = globalPoint.v;
		if (CGGetDisplaysWithPoint(oldPoint, 1, &displayID, &displayCnt) == 0 && displayCnt > 0)
			disp = CGDisplayBounds(displayID);
		if (point.x < disp.origin.x) point.x = disp.origin.x;
		else if (disp.origin.x + disp.size.width - 1 < point.x) point.x = disp.origin.x + disp.size.width - 1;
		if (point.y < disp.origin.y) point.y = disp.origin.y;
		else if (disp.origin.y + disp.size.height - 1 < point.y) point.y = disp.origin.y + disp.size.height - 1;
	}
	return point;
}

- (void)mouseDown:(struct mouseEvent)event0 {
	CGPoint point = [self getMousePointWithDeltaX:0 deltaY:0];
	CGEventType type;
	CGMouseButton button;
	int mouseNum = MouseNumber(event0.value), clickCount = MouseClickCount(event0.value);
	if (mouseNum == 0) {
		type = kCGEventLeftMouseDown;
		button = kCGMouseButtonLeft;
		mouse1Clicked = YES;
	} else if (mouseNum == 1) {
		type = kCGEventRightMouseDown;
		button = kCGMouseButtonRight;
		mouse2Clicked = YES;
	} else {
		type = kCGEventOtherMouseDown;
		button = kCGMouseButtonCenter;
		mouse3Clicked = YES;
	}
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateMouseEvent(NULL, type, point, button);
	CGEventSetIntegerValueField(event, kCGMouseEventClickState, clickCount);
	CGEventSetType(event, type);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (void)mouseUp:(struct mouseEvent)event0 {
	CGPoint point = [self getMousePointWithDeltaX:0 deltaY:0];
	CGEventType type;
	CGMouseButton button;
	int mouseNum = MouseNumber(event0.value), clickCount = MouseClickCount(event0.value);
	if (mouseNum == 0) {
		type = kCGEventLeftMouseUp;
		button = kCGMouseButtonLeft;
		mouse1Clicked = NO;
	} else if (mouseNum == 1) {
		type = kCGEventRightMouseUp;
		button = kCGMouseButtonRight;
		mouse2Clicked = NO;
	} else {
		type = kCGEventOtherMouseUp;
		button = kCGMouseButtonCenter;
		mouse3Clicked = NO;
	}
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateMouseEvent(NULL, type, point, button);
	CGEventSetIntegerValueField(event, kCGMouseEventClickState, clickCount);
	CGEventSetType(event, type);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (void)mouseMoveX:(struct mouseEvent)x Y:(struct mouseEvent)y {
	CGPoint point = [self getMousePointWithDeltaX:x.value deltaY:y.value];
	CGEventType type;
	CGMouseButton button;
	if (mouse1Clicked) {
		type = kCGEventLeftMouseDragged;
		button = kCGMouseButtonLeft;
	} else if (mouse2Clicked) {
		type = kCGEventRightMouseDragged;
		button = kCGMouseButtonRight;
	} else if (mouse3Clicked) {
		type = kCGEventOtherMouseDragged;
		button = kCGMouseButtonCenter;
	} else {
		type = kCGEventMouseMoved;
		button = kCGMouseButtonLeft;
	}
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateMouseEvent(NULL, type, point, button);
	CGEventSetType(event, type);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (void)scrollWheelW:(struct mouseEvent)w Z:(struct mouseEvent)z {
	double accel = 1;
	if (delta < abs(w.value) || delta < abs(z.value)) {
		accel = sqrt(w.value*w.value+z.value*z.value)/delta;
	}
	int32_t countW = -w.value*accel;
	int32_t countZ = -z.value*accel;
	if (countW != 0 || countZ != 0) {
		CFRelease(CGEventCreate(NULL));
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
		CGEventRef event = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 2, countZ, countW);
#else
		CGEventRef event = CGEventCreate(NULL);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, countZ);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2, countW);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventInstantMouser, 0);
#endif
		CGEventSetType(event, kCGEventScrollWheel);
		CGEventPost(kCGSessionEventTap, event);
		CFRelease(event);
	}
}

- (void)scrollWheelZ:(struct mouseEvent)z {
	double accel = 1;
	if (delta < abs(z.value)) {
		accel = abs(z.value)/delta;
	}
	int32_t countZ = -z.value*accel;
	if (countZ != 0) {
		CFRelease(CGEventCreate(NULL));
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
		CGEventRef event = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, countZ);
#else
		CGEventRef event = CGEventCreate(NULL);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, countZ);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2, 0);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventInstantMouser, 0);
#endif
		CGEventSetType(event, kCGEventScrollWheel);
		CGEventPost(kCGSessionEventTap, event);
		CFRelease(event);
	}
}

- (void)keyDown:(struct mouseEvent)event0 {
	CGKeyCode key = (CGKeyCode)event0.value;
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, key, true);
	CGEventSetType(event, kCGEventKeyDown);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (void)keyUp:(struct mouseEvent)event0 {
	CGKeyCode key = (CGKeyCode)event0.value;
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, key, false);
	CGEventSetType(event, kCGEventKeyUp);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (IBAction)disconnect:(id)sender {
	[self requestExitStreamThread];
	[_inStream close];
	[_outStream close];
	[self _showAlert:@"Disconnected!"];
	[disconnectButton setEnabled:NO];
	[self setup];
}

- (void)addSourceToCurrentRunLoop {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
}

- (void)requestExitStreamThread {
    CFRunLoopSourceSignal(runLoopSource);
}

- (void)sendKeepAlive:(NSTimer*)theTimer {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	
	struct mouseEvent event = {htonl(EVENT_NULL), htonl(0), {htonl(tv.tv_sec), htonl(tv.tv_usec*1000)}};
	if (_outStream && [_outStream hasSpaceAvailable])
		if([_outStream write:(uint8_t *)&event maxLength:sizeof(struct mouseEvent)] == -1)
			[self _showAlert:@"Failed sending data to peer"];
}

@end

// This is the CFRunLoopSourceRef callback function.
void RunLoopSourcePerformRoutine (void *info) {
    MyDocument* obj = (MyDocument*)info;
    [obj exitStreamThread];
}

@implementation MyDocument (NSStreamDelegate)

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			[_server release];
			_server = nil;
			
			if (stream == _inStream)
				_inReady = YES;
			else
				_outReady = YES;
			
			if (_inReady && _outReady) {
				[self _showAlert:@"Connected!"];
				prevevent.type = EVENT_NULL;
				mouse1Clicked = NO;
				mouse2Clicked = NO;
				mouse3Clicked = NO;
				[disconnectButton setEnabled:YES];
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inStream) {
				struct mouseEvent event;
				unsigned int len = 0;
				len = [_inStream read:(uint8_t *)&event maxLength:sizeof(struct mouseEvent)];
				if(len != sizeof(struct mouseEvent)) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self _showAlert:@"Failed reading data from peer"];
				} else {
					event.type = ntohl(event.type);
					event.value = htonl(event.value);
					event.time.tv_sec = htonl(event.time.tv_sec);
					event.time.tv_nsec = htonl(event.time.tv_nsec);
					//We received a remote tap update, forward it to the appropriate view
					switch (event.type) {
						case EVENT_MOUSE_DOWN:
							[self mouseDown:event];
							break;
						case EVENT_MOUSE_UP:
							[self mouseUp:event];
							break;
						case EVENT_MOUSE_DELTA_X:
							// following event should be EVENT_MOUSE_DELTA_Y
							break;
						case EVENT_MOUSE_DELTA_Y:
							if (prevevent.type == EVENT_MOUSE_DELTA_X) {
								[self mouseMoveX:prevevent Y:event];
							} else {
								[self _showAlert:@"stray event EVENT_MOUSE_DELTA_Y"];
							}
							break;
						case EVENT_MOUSE_DELTA_W:
							// following event should be EVENT_MOUSE_DELTA_Z
							break;
						case EVENT_MOUSE_DELTA_Z:
							if (prevevent.type == EVENT_MOUSE_DELTA_W) {
								[self scrollWheelW:prevevent Z:event];
							} else {
								[self scrollWheelZ:event];
							}
							break;
						case EVENT_KEY_DOWN:
							[self keyDown:event];
							break;
						case EVENT_KEY_UP:
							[self keyUp:event];
							break;
						default:
							break;
					}
					prevevent = event;
				}
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			[self _showAlert:@"Connection Closed."];
			[self performSelectorOnMainThread:@selector(disconnect:) withObject:nil waitUntilDone:YES];
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			[self _showAlert:@"Connection Error!"];
			[self performSelectorOnMainThread:@selector(disconnect:) withObject:nil waitUntilDone:YES];
			break;
		}
	}
}

@end

@implementation MyDocument (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	//[self presentPicker:string];
}

- (void)didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	if (_inStream || _outStream || server != _server)
		return;
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[NSApplication detachDrawingThread:@selector(openStreams) toTarget:self withObject:nil];
}

@end
