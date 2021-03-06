//
//  AppController.m
//  RemotePad Server
//
//  Derived from an Apple's sample code AppController.m of WiTap.
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


#import <Carbon/Carbon.h>
#include <sys/time.h>
#import "Version.h"
#import "AppController.h"


// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html

#define kBonjourIdentifier		@"remotepad"

#define kNumModifierKeyState 4

@implementation AppController

#pragma mark (De-)Initialization routines

- (id)init
{
	self = [super init];
    if (self) {
		CFRunLoopSourceContext context = { 0, self, NULL, NULL, NULL, NULL,
			NULL, NULL, NULL, RunLoopSourcePerformRoutine };
		
		runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
    }
    return self;
}

- (void)dealloc
{
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
	[_inStream release];
	
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(NSString*)kCFRunLoopCommonModes];
	[_outStream release];
	
	[_server release];
	
	[self requestExitStreamThread];
	
	[super dealloc];
}

- (void)setup:(id)sender
{
	//
	// Server setup
	//
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
		NSLog(@"Quit: another RemotePad Server is running");
		[NSApp terminate:self];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kBonjourIdentifier] name:nil]) {
		NSLog(@"Failed advertising server");
		return;
	}
	
	accumuW = 0;
	accumuZ = 0;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[self setup:self];
	
	notInTheDock = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSUIElement"] boolValue];
	
	//
	// Setup the menu bar item
	//
	statusItem = [[NSStatusBar systemStatusBar]
					statusItemWithLength:NSVariableStatusItemLength];
	
	[statusItem retain];
	NSString *imageName;
	imageName = [[NSBundle mainBundle] pathForResource:@"pointer" ofType:@"png"];
	connectedImage = [[NSImage alloc] initWithContentsOfFile:imageName];
	imageName = [[NSBundle mainBundle] pathForResource:@"pointer-notconnected" ofType:@"png"];
	notConnectedImage = [[NSImage alloc] initWithContentsOfFile:imageName];
	[statusItem setImage:notConnectedImage];
	[statusItem setHighlightMode:YES];
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Menu"];	
	NSMenuItem *menuItem;
	
	[menu setAutoenablesItems:NO];
	
	menuItem = [[NSMenuItem alloc]
				initWithTitle:@"RemotePad: No peer connected"
				action:nil keyEquivalent:@""];
	[menuItem setEnabled:NO];
	[menu addItem:menuItem];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"About RemotePad..."
										  action:@selector(aboutMenu:)
								   keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Show an icon in the Dock..."
										  action:@selector(inTheDockMenu:)
								   keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setState:notInTheDock ? NSOffState : NSOnState];
	[menu addItem:menuItem];
	inTheDockItem = [menuItem retain];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Quit RemotePad"
										  action:@selector(quitMenu:)
								   keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menu addItem:menuItem];
	
	[statusItem setMenu:menu];
}

- (void)applicationTerminated:(NSNotification *)aNotification;
{

}
- (void)disconnect:(id)sender
{
	[self requestExitStreamThread];
	[_inStream close];
	[_outStream close];
	NSLog(@"Disconnected!");
	[[[statusItem menu] itemAtIndex:0] setTitle:@"RemotePad: no peer connected"];
	[statusItem setImage:notConnectedImage];
	//[disconnectButton setEnabled:NO];
	[self setup:sender];
}


- (void)_showAlert:(NSString *)title
{
	[NSAlert alertWithMessageText:@"RemotePad error"
					defaultButton:@"OK"
				  alternateButton:nil
					  otherButton:nil
		informativeTextWithFormat:title];
}

#pragma mark Menu actions

- (void)quitMenu:(id)sender
{
	[NSApp terminate:sender];
}

- (void)aboutMenu:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:sender];
}

- (void)inTheDockMenu:(id)sender
{
	NSString *plistPath;
	
	if (plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]) {
		NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager isWritableFileAtPath:plistPath]) {
			[NSApp activateIgnoringOtherApps:YES];
			if ([[NSAlert alertWithMessageText:@"Updating RemotePad Server.app"
								 defaultButton:@"OK"
							   alternateButton:@"Cancel"
								   otherButton:nil
					 informativeTextWithFormat:@"To make this change effective, you need to restart the RemotePad Server.app."]
				 runModal]) {
				notInTheDock = !notInTheDock;
				[inTheDockItem setState:notInTheDock ? NSOffState : NSOnState];
				
				NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
				[infoDict setObject:[NSNumber numberWithBool:notInTheDock] forKey:@"NSUIElement"];
				[infoDict writeToFile:plistPath atomically:NO];
				[manager setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:[[NSBundle mainBundle] bundlePath] error:NULL];
			}
		} else {
			[NSApp activateIgnoringOtherApps:YES];
			[[NSAlert alertWithMessageText:@"Cannot update RemotePad Server.app"
							 defaultButton:@"OK"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"To change a Dock setting, RemotePad Server.app should be writable."]
			 runModal];
		}
	}
}

#pragma mark CG routines

- (CGPoint)getMousePointWithDeltaX:(int)x deltaY:(int)y
{
	CGPoint point;
	NSPoint globalPoint;
	CGDirectDisplayID displayID;
	CGDisplayCount displayCnt;
	CGRect disp = CGDisplayBounds(kCGDirectMainDisplay);
	
	// NB: NSPoint and CGPoint have different Y coordinates (top vs bottom)
	globalPoint = [NSEvent mouseLocation];
	point.x = globalPoint.x;
	point.y = disp.size.height - globalPoint.y;
	if (x == 0 && y == 0)
		return point;
	
	point.x += x;
	point.y += y;
	if (CGGetDisplaysWithPoint(point, 1, &displayID, &displayCnt) != 0 || displayCnt < 1) {
		CGPoint oldPoint;
		oldPoint.x = globalPoint.x;
		oldPoint.y = disp.size.height - globalPoint.y;
		if (CGGetDisplaysWithPoint(oldPoint, 1, &displayID, &displayCnt) == 0 && displayCnt > 0)
			disp = CGDisplayBounds(displayID);
		if (point.x < disp.origin.x) point.x = disp.origin.x;
		else if (disp.origin.x + disp.size.width - 1 < point.x) point.x = disp.origin.x + disp.size.width - 1;
		if (point.y < disp.origin.y) point.y = disp.origin.y;
		else if (disp.origin.y + disp.size.height - 1 < point.y) point.y = disp.origin.y + disp.size.height - 1;
	}
	
	return point;
}

- (void)mouseDown:(MouseEvent)event0
{
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

- (void)mouseUp:(MouseEvent)event0
{
	CGPoint point = [self getMousePointWithDeltaX:0 deltaY:0];
	CGEventType type;
	CGEventType typedown;
	CGMouseButton button;
	
	int mouseNum = MouseNumber(event0.value), clickCount = MouseClickCount(event0.value);
	if (mouseNum == 0) {
		type = kCGEventLeftMouseUp;
		typedown = kCGEventLeftMouseDown;
		button = kCGMouseButtonLeft;
		mouse1Clicked = NO;
	} else if (mouseNum == 1) {
		type = kCGEventRightMouseUp;
		typedown = kCGEventRightMouseDown;
		button = kCGMouseButtonRight;
		mouse2Clicked = NO;
	} else {
		type = kCGEventOtherMouseUp;
		typedown = kCGEventOtherMouseDown;
		button = kCGMouseButtonCenter;
		mouse3Clicked = NO;
	}
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateMouseEvent(NULL, type, point, button);
	CGEventSetIntegerValueField(event, kCGMouseEventClickState, clickCount);
	CGEventSetType(event, type);
	CGEventPost(kCGSessionEventTap, event);
#if (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
	if (clickCount > 1 && mouseNum == 0) {
		for (int i = 1; i < clickCount; i++) {
			CGEventSetType(event, typedown);
			CGEventSetIntegerValueField(event, kCGMouseEventClickState, clickCount);
			CGEventPost(kCGSessionEventTap, event);
			CGEventSetType(event, type);
			CGEventSetIntegerValueField(event, kCGMouseEventClickState, clickCount);
			CGEventPost(kCGSessionEventTap, event);
		}
	}
#endif
	CFRelease(event);
}

- (void)mouseMoveX:(MouseEvent)x Y:(MouseEvent)y
{
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

- (void)scrollWheelW:(MouseEvent)w Z:(MouseEvent)z
{
	int32_t countW = -w.value;
	int32_t countZ = -z.value;
	
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
	if (countW != 0 || countZ != 0) {
		CFRelease(CGEventCreate(NULL));
		CGEventRef event = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 2, countZ, countW);
		CGEventSetType(event, kCGEventScrollWheel);
		CGEventPost(kCGSessionEventTap, event);
		CFRelease(event);
	}
#else
#define kAdhocFactor 16
	accumuW += countW;
	countW = accumuW / kAdhocFactor;
	accumuW = accumuW % kAdhocFactor;
	accumuZ += countZ;
	countZ = accumuZ / kAdhocFactor;
	accumuZ = accumuZ %kAdhocFactor;
	if (countW != 0 || countZ != 0) {
		CFRelease(CGEventCreate(NULL));
		CGEventRef event = CGEventCreate(NULL);
		CGEventSetType(event, kCGEventScrollWheel);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, countZ);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2, countW);
		CGEventSetIntegerValueField(event, kCGScrollWheelEventInstantMouser, 0);
		CGEventSetType(event, kCGEventScrollWheel);
		CGEventPost(kCGSessionEventTap, event);
		CFRelease(event);
	}
#endif
}

- (void)scrollWheelZ:(MouseEvent)z
{
	MouseEvent w;
	w.value = 0;
	[self scrollWheelW:w Z:z];
}

- (void)keyDown:(MouseEvent)event0
{
	CGKeyCode key = (CGKeyCode)event0.value;
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, key, true);
	CGEventSetType(event, kCGEventKeyDown);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (void)keyUp:(MouseEvent)event0
{
	CGKeyCode key = (CGKeyCode)event0.value;
	CFRelease(CGEventCreate(NULL));
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, key, false);
	CGEventSetType(event, kCGEventKeyUp);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- (void)prepareTables
{
	TISInputSourceRef keyboardLayoutRef;
	const void *chr_data = NULL;
	UCKeyboardLayout *keyboardLayout = NULL;
	
	keyboardLayoutRef = TISCopyCurrentKeyboardLayoutInputSource();
	keyboardLayout = TISGetInputSourceProperty(keyboardLayoutRef, kTISPropertyUnicodeKeyLayoutData);
	chr_data = CFDataGetBytePtr((CFDataRef)keyboardLayout);

	if (keyboardLayout == NULL) {
		currentKeyboardLayout = NULL;
	} else if (currentKeyboardLayout != keyboardLayout) {
		currentKeyboardLayout = keyboardLayout;
		memset(charToKey, 0xff, sizeof(CGKeyCode)*kNumUniChar);
		memset(charToMod, 0, sizeof(UInt32)*kNumUniChar);
		UInt32 keyboardType = LMGetKbdType();
		UInt32 deadKeyState;
		UniCharCount actualStringLength;
		UniChar unicodeString[255];
		CGKeyCode keyCode;
		UInt32 modifierKeyStates[kNumModifierKeyState] = { 0, shiftKey, optionKey, shiftKey | optionKey };
		for (int i = 0; i < kNumModifierKeyState; i++) {
			UInt32 modifierKeyState = (modifierKeyStates[i] >> 8) & 0xff;
			for (keyCode = 0; keyCode < 128; keyCode++) {
				if (UCKeyTranslate(chr_data, keyCode, kUCKeyActionDown, 
								   modifierKeyState, keyboardType, 1,
								   &deadKeyState, 255, &actualStringLength, 
								   unicodeString) == noErr) {
					unicodeString[actualStringLength] = 0;
					if (actualStringLength == 1 && charToKey[unicodeString[0]] == 0xffff) {
						charToKey[unicodeString[0]] = keyCode;
						charToMod[unicodeString[0]] = modifierKeyStates[i];
					}
				}
			}
		}
		// special treatments
		if (charToKey['\n'] == 0xffff)
			charToKey['\n'] = kKeycodeReturn;
	}
#if 0
	if (KLGetKeyboardLayoutProperty(keyboardLayoutRef, kKLKCHRData, (const void **)&keyboarLayout) != noErr) {
		currentKeyboardLayoutKCHR = NULL;
	} else if (currentKeyboardLayoutKCHR != keyboardLayout) {
		currentKeyboardLayoutKCHR = keyboarLayout;
		memset(charToKeyKCHR, 0xff, sizeof(CGKeyCode)*kNumUniChar);
		memset(charToModKCHR, 0, sizeof(UInt32)*kNumUniChar);
		UInt32 deadKeyState;
		UInt16 keyCode;
		UInt32 modifierKeyStates[kNumModifierKeyState] = { 0, shiftKey, optionKey, shiftKey | optionKey };
		for (int i = 0; i < kNumModifierKeyState; i++) {
			for (keyCode = 0; keyCode < 128; keyCode++) {
				deadKeyState = 0;
				UInt32 char12 = KeyTranslate(keyboarLayout, (UInt16)(keyCode | modifierKeyStates[i]), &deadKeyState);
				UInt8 cString[3];
				cString[0] = (char12 >> 16) & 0xff;
				if (cString[0] == 0) {
					cString[0] = char12 & 0xff;
					cString[1] = 0;
				} else {
					cString[1] = char12 & 0xff;
					cString[2] = 0;
				}
				if (cString[0] == 0)
					continue;
				CFStringRef unicodeString;
				unicodeString = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, (const char *)cString, kCFStringEncodingMacRoman, kCFAllocatorNull);
				CFIndex unicodeLength = CFStringGetLength(unicodeString);
				if (unicodeLength != 1)
					continue;
				UniChar unicodeChar = CFStringGetCharacterAtIndex(unicodeString, 0);
				if (charToKeyKCHR[unicodeChar] == 0xffff) {
					charToKeyKCHR[unicodeChar] = keyCode;
					charToModKCHR[unicodeChar] = modifierKeyStates[i];
				}
			}
		}
		// special treatments
		if (charToKeyKCHR['\n'] == 0xffff)
			charToKeyKCHR['\n'] = kKeycodeReturn;
	}
#endif
	
	if (keyboardLayoutRef)
		CFRelease(keyboardLayoutRef);
}

- (void)simulateKeyWithUnichar:(MouseEvent)event0 {
	if (event0.value < 0 || kNumUniChar <= event0.value) {
		NSBeep();
		return;
	}
	[self prepareTables];
	
	CGKeyCode keyCode = 0xffff;
	CGEventFlags modifierFlags = 0;
	if (currentKeyboardLayout != NULL && charToKey[event0.value] != 0xffff) {
		keyCode = charToKey[event0.value];
		if (charToMod[event0.value] & optionKey)
			modifierFlags |= kCGEventFlagMaskAlternate;
		if (charToMod[event0.value] & shiftKey)
			modifierFlags |= kCGEventFlagMaskShift;
	}
#if 0
	else if (currentKeyboardLayoutKCHR != NULL && charToKeyKCHR[event0.value] != 0xffff) {
		keyCode = charToKeyKCHR[event0.value];
		if (charToModKCHR[event0.value] & optionKey)
			modifierFlags |= kCGEventFlagMaskAlternate;
		if (charToModKCHR[event0.value] & shiftKey)
			modifierFlags |= kCGEventFlagMaskShift;
	}
#endif
	
	if (keyCode != 0xffff) {
		CFRelease(CGEventCreate(NULL));
		CGEventRef event = CGEventCreateKeyboardEvent(NULL, keyCode, true);
		CGEventSetType(event, kCGEventKeyDown);
		CGEventSetFlags(event, modifierFlags);
		CGEventPost(kCGSessionEventTap, event);
		CGEventSetType(event, kCGEventKeyUp);
		CGEventPost(kCGSessionEventTap, event);
		CFRelease(event);
	} else {
		NSLog(@"keyboard layout = %x & %x, charcode = %d, keycode = %d", currentKeyboardLayout, currentKeyboardLayoutKCHR, event0.value, keyCode);
		NSBeep();
	}
}

#pragma mark Stream routines

- (void)openStreams
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
	struct timeval tv;
	gettimeofday(&tv, NULL);
	MouseEvent event = {htonl(EVENT_VERSION), htonl(kVersionMacCurrent), htonl(tv.tv_sec), htonl(tv.tv_usec*1000)};
	[_outStream write:(uint8_t *)&event maxLength:sizeof(MouseEvent)];
}

- (void)exitStreamThread
{
	if (streamThread) {
		if (![streamThread isEqual:[NSThread currentThread]]) {
			fprintf(stderr, "warning: exitStreamThread: invoked from a non streaming thread\n");
		}
		streamThread = nil;
	}
	[NSThread exit];
}

#pragma mark NSDocument delegates

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if (outError != NULL) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain
										code:unimpErr
									userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if (outError != NULL) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain
										code:unimpErr
									userInfo:NULL];
	}
    return YES;
}

#pragma mark Run Loop delegates/routines

- (void)addSourceToCurrentRunLoop
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
}

- (void)requestExitStreamThread
{
    CFRunLoopSourceSignal(runLoopSource);
}

#pragma mark Keep alive delegates

- (void)sendKeepAlive:(NSTimer*)theTimer
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	
	MouseEvent event = {htonl(EVENT_NULL), 0, htonl(tv.tv_sec), htonl(tv.tv_usec*1000)};
	if (_outStream && [_outStream hasSpaceAvailable]) {
		if([_outStream write:(uint8_t *)&event maxLength:sizeof(MouseEvent)] == -1) {
			NSLog(@"Failed sending data to peer");
			[self performSelectorOnMainThread:@selector(disconnect:) withObject:nil waitUntilDone:YES];
		}
	}
}

@end


@implementation AppController (NSStreamDelegate)

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
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
				[[[statusItem menu] itemAtIndex:0] setTitle:@"RemotePad: peer connected"];
				[statusItem setImage:connectedImage];
				
				currentKeyboardLayout = NULL;
				currentKeyboardLayoutKCHR = NULL;
				
				prevevent.type = EVENT_NULL;
				mouse1Clicked = NO;
				mouse2Clicked = NO;
				mouse3Clicked = NO;
				//XXX [disconnectButton setEnabled:YES];
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inStream) {
				MouseEvent event;
				unsigned int len = 0;
				len = [_inStream read:(uint8_t *)&event maxLength:sizeof(MouseEvent)];
				if(len != sizeof(MouseEvent)) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						NSLog(@"Failed reading data from peer");
				} else {
					event.type = ntohl(event.type);
					event.value = ntohl(event.value);
					event.tv_sec = ntohl(event.tv_sec);
					event.tv_nsec = ntohl(event.tv_nsec);
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
								NSLog(@"stray event EVENT_MOUSE_DELTA_Y");
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
						case EVENT_ASCII:
							[self simulateKeyWithUnichar:event];
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
			[self performSelectorOnMainThread:@selector(disconnect:) withObject:nil waitUntilDone:YES];
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"Connection Error!");
			[self performSelectorOnMainThread:@selector(disconnect:) withObject:nil waitUntilDone:YES];
			break;
		}
	}
}

@end

@implementation AppController (TCPServerDelegate)

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


// This is the CFRunLoopSourceRef callback function.
void RunLoopSourcePerformRoutine (void *info)
{
    AppController* obj = (AppController*)info;
    [obj exitStreamThread];
}

