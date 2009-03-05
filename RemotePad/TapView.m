//
//  TapView.m
//  RemotePad
//
//  Derived from an Apple's sample code TapView.m of WiTap.
//  Modified by iKawamoto Yosihisa! on 08/08/17.
//
/*

File: TapView.m
Abstract: UIView subclass that can highlight itself when locally or remotely
tapped.

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

#import "TapView.h"
#import "AppController.h"
#import "Constants.h"

//CLASS IMPLEMENTATIONS:

@implementation TapViewController


@synthesize appc;
@synthesize topview;
@synthesize topviewLocation;
@synthesize numberOfButtons;
@synthesize mouseMapLeftToRight;
@synthesize numberArrowKeyGesture;
@synthesize twoFingersScroll;
@synthesize allowHorizontalScroll;
@synthesize clickByTap;
@synthesize dragByTap;
@synthesize dragByTapLock;
@synthesize numberToggleStatusbar;
@synthesize scrollWithMouse3;
@synthesize enableAccelMouse;
@synthesize tapViewOrientation;
@synthesize autorotateOrientation;
@synthesize twoFingersSecondary;
@synthesize prohibitSleeping;
@synthesize trackingSpeed;
@synthesize scrollingSpeed;
@synthesize doneInsecureKeyboardWarning;
@synthesize doLabelsForMouseButtons;


- (void)loadView {
	CGRect rect;
	rect = [[UIScreen mainScreen] bounds];
	UIView *view = [[UIView alloc] initWithFrame:rect];
	[view setMultipleTouchEnabled:YES];
	[view setExclusiveTouch:YES];
	[view setBackgroundColor:[UIColor blackColor]];
	self.view = view;
	
	int buttonHeight = rect.size.height / 5;
	topview = [[UIView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, buttonHeight)];
	// Disable user interaction for this view. You must do this if you want to handle touches for more than one object at at time.
	// You'll get events for the superview, and then dispatch them to the appropriate subview in the touch handling methods.
	[topview setUserInteractionEnabled:NO];
	[topview setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
	buttonLeftImage = [[[UIImage imageNamed:@"ButtonLeft.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonRightImage = [[[UIImage imageNamed:@"ButtonRight.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonCenterImage = [[[UIImage imageNamed:@"ButtonCenter.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonRoundedImage = [[[UIImage imageNamed:@"ButtonRounded.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonLeftHighlightedImage = [[[UIImage imageNamed:@"ButtonLeftHighlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonRightHighlightedImage = [[[UIImage imageNamed:@"ButtonRightHighlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonCenterHighlightedImage = [[[UIImage imageNamed:@"ButtonCenterHighlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	buttonRoundedHighlightedImage = [[[UIImage imageNamed:@"ButtonRoundedHighlighted.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:10.0] retain];
	mouse1Tap.button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	[mouse1Tap.button setTitleColor:[mouse1Tap.button titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected];
	[topview addSubview:mouse1Tap.button];
	mouse3Tap.button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	[mouse3Tap.button setTitleColor:[mouse3Tap.button titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected];
	[topview addSubview:mouse3Tap.button];
	mouse2Tap.button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	[mouse2Tap.button setTitleColor:[mouse2Tap.button titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected];
	[topview addSubview:mouse2Tap.button];
	[view addSubview:topview];
	bottombar = [[UIToolbar alloc] init];
	[bottombar setBarStyle:UIBarStyleBlackOpaque];
	
	UIBarButtonItem *toggleButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Hide button" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleToolbars)] autorelease];
	toggleButtonItem.width = kToggleButtonItemWidth;
	UIBarButtonItem *flexItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	UIBarButtonItem *setupItem = [[[UIBarButtonItem alloc] initWithTitle:@"Setup" style:UIBarButtonItemStyleBordered target:[UIApplication sharedApplication].delegate action:@selector(showSetupView:)] autorelease];

	UIBarButtonItem *toggleKeyboardItem = [[[UIBarButtonItem alloc] initWithTitle:@"Show Keyboard" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleKeyboard)] autorelease];
	toggleKeyboardItem.width = kToggleKeyboardItemWidth;

	[bottombar setItems:[NSArray arrayWithObjects:toggleButtonItem, flexItem, toggleKeyboardItem, flexItem, setupItem, nil]];
	[bottombar sizeToFit];
	
	float bbHeight = rect.origin.y + rect.size.height;
	if (!hiddenKeyboard) bbHeight -= ((tapViewOrientation == UIInterfaceOrientationLandscapeLeft) || (tapViewOrientation == UIInterfaceOrientationLandscapeRight)) ? kStatusKeyboardOffsetLand : kStatusKeyboardOffsetPort;

	[bottombar setFrame:CGRectMake(rect.origin.x, bbHeight, rect.size.width, [bottombar frame].size.height)];
	[view addSubview:bottombar];
	
	keyboardField = [[UITextField alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y + rect.size.height + 32.0, rect.size.width, 32.0)];
	keyboardField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	keyboardField.autocorrectionType = UITextAutocorrectionTypeNo;
//	keyboardField.keyboardAppearance = UIKeyboardAppearanceAlert;
//	keyboardField.clearsOnBeginEditing = TRUE;
	keyboardField.delegate = self;
	
	[view addSubview:keyboardField];
	[view release];

	// read defaults
	[self registerDefaults];
	[self readDefaults];
	
	// initial settting
	[self setNumberOfButtons:numberOfButtons mouseMapLeftToRight:mouseMapLeftToRight];
	[self setDoLabelsForMouseButtons:doLabelsForMouseButtons];
	if (clickByTap || numberToggleStatusbar == 0) {
		hiddenToolbars = NO;
		hiddenStatusbar = NO;
		hiddenKeyboard = YES;
	} else {
		hiddenToolbars = NO;
		hiddenStatusbar = YES;
		hiddenKeyboard = YES;
	}
	[self prepareToolbarsAndStatusbar];
}

- (void) registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultVersion forKey:kDefaultKeyVersion]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultTopviewLocationX forKey:kDefaultKeyTopviewLocationX]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultTopviewLocationY forKey:kDefaultKeyTopviewLocationY]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultNumberOfButtons forKey:kDefaultKeyNumberOfButtons]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultMouseMapLeftToRight forKey:kDefaultKeyMouseMapLeftToRight]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultNumberArrowKeyGesture forKey:kDefaultKeyNumberArrowKeyGesture]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultTwoFingersScroll forKey:kDefaultKeyTwoFingersScroll]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultAllowHorizontalScroll forKey:kDefaultKeyAllowHorizontalScroll]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultClickByTap forKey:kDefaultKeyClickByTap]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultDragByTap forKey:kDefaultKeyDragByTap]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultDragByTapLock forKey:kDefaultKeyDragByTapLock]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultNumberToggleStatusbar forKey:kDefaultKeyNumberToggleStatusbar]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultNumberToggleToolbars forKey:kDefaultKeyNumberToggleToolbars]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultScrollWithMouse3 forKey:kDefaultKeyScrollWithMouse3]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultEnableAccelMouse forKey:kDefaultKeyEnableAccelMouse]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultTapViewOrientation forKey:kDefaultKeyTapViewOrientation]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultAutorotateOrientation forKey:kDefaultKeyAutorotateOrientation]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultTwoFingersSecondary forKey:kDefaultKeyTwoFingersSecondary]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultProhibitSleeping forKey:kDefaultKeyProhibitSleeping]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultTrackingSpeed forKey:kDefaultKeyTrackingSpeed]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultScrollingSpeed forKey:kDefaultKeyScrollingSpeed]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultDoneInsecureKeyboardWarning forKey:kDefaultKeyDoneInsecureKeyboardWarning]];
	[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultDoLabelsForMouseButtons forKey:kDefaultKeyDoLabelsForMouseButtons]];
}

- (void) readDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	topviewLocation = CGPointMake([defaults floatForKey:kDefaultKeyTopviewLocationX], [defaults floatForKey:kDefaultKeyTopviewLocationY]);
	numberOfButtons = [defaults integerForKey:kDefaultKeyNumberOfButtons];
	if (numberOfButtons < 1 || 3 < numberOfButtons)
		numberOfButtons = 3;
	mouseMapLeftToRight = [defaults boolForKey:kDefaultKeyMouseMapLeftToRight];
	numberArrowKeyGesture = [defaults integerForKey:kDefaultKeyNumberArrowKeyGesture];
	if (numberArrowKeyGesture < 0)
		numberArrowKeyGesture = 0;
	twoFingersScroll = [defaults boolForKey:kDefaultKeyTwoFingersScroll];
	allowHorizontalScroll = [defaults boolForKey:kDefaultKeyAllowHorizontalScroll];
	clickByTap = [defaults boolForKey:kDefaultKeyClickByTap];
	dragByTap = [defaults boolForKey:kDefaultKeyDragByTap];
	dragByTapLock = [defaults boolForKey:kDefaultKeyDragByTapLock];
	numberToggleStatusbar = [defaults integerForKey:kDefaultKeyNumberToggleStatusbar];
	if (numberToggleStatusbar < 0)
		numberToggleStatusbar = 0;
	numberToggleToolbars = [defaults integerForKey:kDefaultKeyNumberToggleToolbars];
	if (numberToggleToolbars < 0)
		numberToggleToolbars = 0;
	scrollWithMouse3 = [defaults boolForKey:kDefaultKeyScrollWithMouse3];
	enableAccelMouse = [defaults boolForKey:kDefaultKeyEnableAccelMouse];
	tapViewOrientation = (UIInterfaceOrientation)[defaults integerForKey:kDefaultKeyTapViewOrientation];
	autorotateOrientation = [defaults boolForKey:kDefaultKeyAutorotateOrientation];
	twoFingersSecondary = [defaults boolForKey:kDefaultKeyTwoFingersSecondary];
	prohibitSleeping = [defaults boolForKey:kDefaultKeyProhibitSleeping];
	trackingSpeed = [defaults integerForKey:kDefaultKeyTrackingSpeed];
	scrollingSpeed = [defaults integerForKey:kDefaultKeyScrollingSpeed];
	doneInsecureKeyboardWarning = [defaults boolForKey:kDefaultKeyDoneInsecureKeyboardWarning];
	doLabelsForMouseButtons = [defaults boolForKey:kDefaultKeyDoLabelsForMouseButtons];
}

- (void) showToolbars:(BOOL)showToolbars showStatusbar:(BOOL)showStatusbar temporal:(BOOL)temporally {
	CGRect rect = [self.view bounds];
	CGRect tbRect = [topview frame];
	CGRect bbRect = [bottombar frame];
	if (showToolbars) {
		[[[bottombar items] objectAtIndex:0] setTitle:@"Hide button"];
	} else {
		[[[bottombar items] objectAtIndex:0] setTitle:@"Show button"];
	}

	if (hiddenKeyboard) {
		[[[bottombar items] objectAtIndex:2] setTitle:@"Show keyboard"];
	} else {
		[[[bottombar items] objectAtIndex:2] setTitle:@"Hide keyboard"];
	}
	
	[topview setFrame:CGRectMake(topviewLocation.x, topviewLocation.y, rect.size.width, tbRect.size.height)];
	[topview setHidden:NO];

	float bbHeight = rect.origin.y + rect.size.height - bbRect.size.height;
	if (!hiddenKeyboard) bbHeight -= ((tapViewOrientation == UIInterfaceOrientationLandscapeLeft) || (tapViewOrientation == UIInterfaceOrientationLandscapeRight)) ? kStatusKeyboardOffsetLand : kStatusKeyboardOffsetPort;

	[bottombar setFrame:CGRectMake(rect.origin.x, bbHeight, rect.size.width, bbRect.size.height)];
	[bottombar setHidden:NO];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(showToolbarsFinished:finished:context:)];
	[UIView setAnimationDuration:0.3];
	if (showToolbars) {
		[topview setAlpha:1.0];
	} else {
		[topview setAlpha:0.0];
	}
	if (!temporally)
		hiddenToolbars = !showToolbars;
	if (showStatusbar) {
		[bottombar setAlpha:1.0];
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
	} else {
		[bottombar setAlpha:0.0];
		[[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
	}
	if (!temporally)
		hiddenStatusbar = !showStatusbar;
	[UIView commitAnimations];
}

- (void) showToolbarsFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	CGRect rect = [self.view frame];
	CGRect tbRect = [topview frame];
	CGRect bbRect = [bottombar frame];
	if (topview.alpha == 0.0) {
		[topview setFrame:CGRectMake(rect.origin.x, rect.origin.y - tbRect.size.height, tbRect.size.width, tbRect.size.height)];
		[topview setHidden:YES];
	} else {
		[topview setHidden:NO];
	}
	if (bottombar.alpha == 0.0) {
		
		float bbHeight = rect.origin.y + rect.size.height;
	if (!hiddenKeyboard) bbHeight -= ((tapViewOrientation == UIInterfaceOrientationLandscapeLeft) || (tapViewOrientation == UIInterfaceOrientationLandscapeRight)) ? kStatusKeyboardOffsetLand : kStatusKeyboardOffsetPort;
		
		[bottombar setFrame:CGRectMake(rect.origin.x, bbHeight, bbRect.size.width, bbRect.size.height)];
		[bottombar setHidden:YES];
	} else {
		[bottombar setHidden:NO];
	}
}

- (void) showToolbars:(BOOL)show temporal:(BOOL)temporally {
	[self showToolbars:show showStatusbar:!hiddenStatusbar temporal:temporally];
}

- (void)prepareToolbarsAndStatusbar {
	if (!hiddenKeyboard) {
		[bottombar setAlpha:0.0];
		[keyboardField becomeFirstResponder];
		if (!doneInsecureKeyboardWarning)
			[self showInsecureKeyboardWarning];
	} else {
		[keyboardField resignFirstResponder];
	}
	[self showToolbars:!hiddenToolbars showStatusbar:!hiddenStatusbar temporal:NO];
}

- (void)toggleToolbars {
	hiddenToolbars = !hiddenToolbars;
	[self prepareToolbarsAndStatusbar];
}

- (void)toggleKeyboard {
	hiddenKeyboard = !hiddenKeyboard;
	[self prepareToolbarsAndStatusbar];
}

- (void)toggleStatusbars {
	hiddenStatusbar = !hiddenStatusbar;
	[self prepareToolbarsAndStatusbar];
}

- (void)resetAllStates:(id)applicationControllerDelegate {
	appc = applicationControllerDelegate;
	mouse1Tap.touch = nil;
	mouse2Tap.touch = nil;
	mouse3Tap.touch = nil;
	topviewTap.touch = nil;
	arrowKeyTap.touch = nil;
	multiFingersTap.touch = nil;
	mouse1Tap.dragMode = NO;
	mouse2Tap.dragMode = NO;
	mouse3Tap.dragMode = NO;
	topviewTap.dragMode = NO;
	arrowKeyTap.dragMode = NO;
	numTouches = 0;
	prevDelta = CGPointZero;
	dragByTapDragMode = NO;
	currAccel.enabled = NO;
	currAccel.stopping = NO;
	currAccel.stability = 0;
	currAccel.ax = currAccel.ay = currAccel.az = 0.0;
	currAccel.vx = currAccel.vy = currAccel.vz = 0.0;
	[clickTimer invalidate];
	clickTimer = nil;
	clickTimerTouch = nil;
	insecureKeyboardWarningDialog = nil;
	insecureKeyboardWarningTimer = nil;
}

- (void)setNumberOfButtons:(int)val mouseMapLeftToRight:(BOOL)isLeftToRight {
	CGRect rect = [self.view bounds];
	[topview setFrame:CGRectMake([topview frame].origin.x, [topview frame].origin.y, rect.size.width, rect.size.height / 5)];
	numberOfButtons = val;
	mouseMapLeftToRight = isLeftToRight;
	int buttonWidth = rect.size.width / numberOfButtons;
	int buttonHeight = rect.size.height / 5;
	UIImage *mouse1Norm, *mouse1High, *mouse2Norm, *mouse2High;
	if (isLeftToRight) {
		mouse1Norm = buttonLeftImage;
		mouse1High = buttonLeftHighlightedImage;
		mouse2Norm = buttonRightImage;
		mouse2High = buttonRightHighlightedImage;
		[mouse1Tap.button setFrame:CGRectMake(0, 0, buttonWidth, buttonHeight)];
		[mouse2Tap.button setFrame:CGRectMake(buttonWidth * (numberOfButtons - 1), 0, buttonWidth, buttonHeight)];
		[mouse3Tap.button setFrame:CGRectMake(buttonWidth, 0, buttonWidth, buttonHeight)];
	} else {
		mouse1Norm = buttonRightImage;
		mouse1High = buttonRightHighlightedImage;
		mouse2Norm = buttonLeftImage;
		mouse2High = buttonLeftHighlightedImage;
		[mouse1Tap.button setFrame:CGRectMake(buttonWidth * (numberOfButtons - 1), 0, buttonWidth, buttonHeight)];
		[mouse2Tap.button setFrame:CGRectMake(0, 0, buttonWidth, buttonHeight)];
		[mouse3Tap.button setFrame:CGRectMake(buttonWidth, 0, buttonWidth, buttonHeight)];
	}
	switch (numberOfButtons) {
		case 1:
			[mouse1Tap.button setBackgroundImage:buttonRoundedImage forState:UIControlStateNormal];
			[mouse1Tap.button setBackgroundImage:buttonRoundedHighlightedImage forState:UIControlStateSelected];
			[mouse1Tap.button setBackgroundImage:buttonRoundedHighlightedImage forState:UIControlStateHighlighted];
			[mouse2Tap.button setHidden:YES];
			[mouse3Tap.button setHidden:YES];
			break;
		case 2:
			[mouse1Tap.button setBackgroundImage:mouse1Norm forState:UIControlStateNormal];
			[mouse1Tap.button setBackgroundImage:mouse1High forState:UIControlStateSelected];
			[mouse1Tap.button setBackgroundImage:mouse1High forState:UIControlStateHighlighted];
			[mouse2Tap.button setBackgroundImage:mouse2Norm forState:UIControlStateNormal];
			[mouse2Tap.button setBackgroundImage:mouse2High forState:UIControlStateSelected];
			[mouse2Tap.button setBackgroundImage:mouse2High forState:UIControlStateHighlighted];
			[mouse2Tap.button setHidden:NO];
			[mouse3Tap.button setHidden:YES];
			break;
		case 3:
			[mouse1Tap.button setBackgroundImage:mouse1Norm forState:UIControlStateNormal];
			[mouse1Tap.button setBackgroundImage:mouse1High forState:UIControlStateSelected];
			[mouse1Tap.button setBackgroundImage:mouse1High forState:UIControlStateHighlighted];
			[mouse2Tap.button setBackgroundImage:mouse2Norm forState:UIControlStateNormal];
			[mouse2Tap.button setBackgroundImage:mouse2High forState:UIControlStateSelected];
			[mouse2Tap.button setBackgroundImage:mouse2High forState:UIControlStateHighlighted];
			[mouse3Tap.button setBackgroundImage:buttonCenterImage forState:UIControlStateNormal];
			[mouse3Tap.button setBackgroundImage:buttonCenterHighlightedImage forState:UIControlStateSelected];
			[mouse3Tap.button setBackgroundImage:buttonCenterHighlightedImage forState:UIControlStateHighlighted];
			[mouse2Tap.button setHidden:NO];
			[mouse3Tap.button setHidden:NO];
			break;
	}
}

- (void)setNumberOfButtons:(int)val {
	[self setNumberOfButtons:val mouseMapLeftToRight:mouseMapLeftToRight];
}

- (void)setMouseMapLeftToRight:(BOOL)isLeftToRight {
	[self setNumberOfButtons:numberOfButtons mouseMapLeftToRight:isLeftToRight];
}

- (void)setDoLabelsForMouseButtons:(BOOL)value {
	doLabelsForMouseButtons = value;
	if (doLabelsForMouseButtons) {
		[mouse1Tap.button setTitle:@"left" forState:UIControlStateNormal];
		[mouse1Tap.button setTitle:@"end drag" forState:UIControlStateSelected];
		[mouse3Tap.button setTitle:@"center" forState:UIControlStateNormal];
		[mouse3Tap.button setTitle:@"end drag" forState:UIControlStateSelected];
		[mouse2Tap.button setTitle:@"right" forState:UIControlStateNormal];
		[mouse2Tap.button setTitle:@"end drag" forState:UIControlStateSelected];
	} else {
		[mouse1Tap.button setTitle:@"" forState:UIControlStateNormal];
		[mouse1Tap.button setTitle:@"" forState:UIControlStateSelected];
		[mouse3Tap.button setTitle:@"" forState:UIControlStateNormal];
		[mouse3Tap.button setTitle:@"" forState:UIControlStateSelected];
		[mouse2Tap.button setTitle:@"" forState:UIControlStateNormal];
		[mouse2Tap.button setTitle:@"" forState:UIControlStateSelected];
	}
}

- (void)setProhibitSleeping:(BOOL)value {
	prohibitSleeping = value;
	[[UIApplication sharedApplication] setIdleTimerDisabled:prohibitSleeping];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	for (UITouch *touch in touches) {
		CGPoint touchPointForButton = [touch locationInView:topview];
		NSUInteger tapCount = [touch tapCount];
		if (!mouse1Tap.touch && CGRectContainsPoint([mouse1Tap.button frame], touchPointForButton)) {
			[mouse1Tap.button setHighlighted:YES];
			mouse1Tap.touch = touch;
			if (!mouse1Tap.dragMode) {
				mouse1Tap.twoFingersClick = (twoFingersSecondary && numTouches == 2);
				[appc send:EVENT_MOUSE_DOWN with:MouseEventValue(mouse1Tap.twoFingersClick ? 1 : 0, tapCount) time:event.timestamp];
			} else {
				[mouse1Tap.button setSelected:NO];
				mouse1Tap.dragMode = NO;
			}
		} else if (!mouse2Tap.touch && CGRectContainsPoint([mouse2Tap.button frame], touchPointForButton)) {
			[mouse2Tap.button setHighlighted:YES];
			mouse2Tap.touch = touch;
			if (!mouse2Tap.dragMode) {
				mouse2Tap.twoFingersClick = (twoFingersSecondary && numTouches == 2);
				[appc send:EVENT_MOUSE_DOWN with:MouseEventValue(mouse2Tap.twoFingersClick ? 1 : 1, tapCount) time:event.timestamp];
			} else {
				[mouse2Tap.button setSelected:NO];
				mouse2Tap.dragMode = NO;
			}
		} else if (!mouse3Tap.touch && CGRectContainsPoint([mouse3Tap.button frame], touchPointForButton)) {
			[mouse3Tap.button setHighlighted:YES];
			mouse3Tap.touch = touch;
			if (!mouse3Tap.dragMode) {
				if (!scrollWithMouse3) {
					mouse3Tap.twoFingersClick = (twoFingersSecondary && numTouches == 2);
					[appc send:EVENT_MOUSE_DOWN with:MouseEventValue(mouse3Tap.twoFingersClick ? 1 : 2, tapCount) time:event.timestamp];
				}
			} else {
				[mouse3Tap.button setSelected:NO];
				mouse3Tap.dragMode = NO;
			}
		} else {
			numTouches++;
			if (numTouches == 1) {
				currAccel.enabled = YES;
				currAccel.stopping = NO;
				multiFingersTap.touch = touch;
				multiFingersTap.timestamp = touch.timestamp;
				multiFingersTap.phase = touch.phase;
				multiFingersTap.numFingers = numTouches;
			} else if (multiFingersTap.phase == UITouchPhaseBegan) {
				multiFingersTap.numFingers = numTouches;
			} else {
				multiFingersTap.phase = UITouchPhaseCancelled;
			}
			prevDelta = CGPointZero;
			if (clickByTap) {
				dragByTapDragMode = NO;
			} else {
				// Timer for click & drag gestures
				[clickTimer invalidate];
				clickTimer = [NSTimer scheduledTimerWithTimeInterval:kTapHoldInterval target:self selector:@selector(clicked:) userInfo:[NSArray arrayWithObjects:[NSNumber numberWithInt:numTouches], [NSNumber numberWithUnsignedInteger:tapCount], nil] repeats:NO];
				clickTimerTouch = touch;
			}
		}
	}
}

- (void)clicked:(NSTimer*)theTimer {
	int oldNumTouches = [[[theTimer userInfo] objectAtIndex:0] intValue];
	NSUInteger tapCount = [[[theTimer userInfo] objectAtIndex:1] unsignedIntegerValue];
	if (clickTimerTouch != nil) {
		// click and hold or drag
		CGPoint touchPoint = [clickTimerTouch locationInView:self.view];
		if (numberToggleToolbars && numberToggleToolbars == tapCount && !topviewTap.touch && oldNumTouches == 1) {
			if ([clickTimerTouch phase] == UITouchPhaseBegan)
				[self showToolbars:YES temporal:NO];
			topviewTap.touch = clickTimerTouch;
			topviewTap.tapLocation = touchPoint;
			topviewTap.nonDragArea = CGRectMake(touchPoint.x - kOffsetDragBegins, touchPoint.y - kOffsetDragBegins, kOffsetDragBegins * 2, kOffsetDragBegins * 2);
			topviewTap.dragMode = NO;
			numTouches--;
			multiFingersTap.touch = nil;
		} else if (numberArrowKeyGesture && numberArrowKeyGesture == tapCount && !arrowKeyTap.touch && oldNumTouches == 1) {
			arrowKeyTap.touch = clickTimerTouch;
			arrowKeyTap.tapLocation = touchPoint;
			arrowKeyTap.nonDragArea = CGRectMake(touchPoint.x - kOffsetDragBegins, touchPoint.y - kOffsetDragBegins, kOffsetDragBegins * 2, kOffsetDragBegins * 2);
			arrowKeyTap.dragMode = NO;
			numTouches--;
			multiFingersTap.touch = nil;
		}
	} else {
		// click and release
		if (numberToggleStatusbar && numberToggleStatusbar == tapCount && oldNumTouches == 1)
			[self toggleStatusbars];
		else if (numberToggleToolbars && numberToggleToolbars == tapCount && oldNumTouches == 1)
			[self toggleToolbars];
	}
	clickTimer = nil;
	clickTimerTouch = nil;
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	for (UITouch *touch in touches) {
		NSUInteger tapCount = [touch tapCount];
		if (touch == mouse1Tap.touch) {
			[appc send:EVENT_MOUSE_UP with:MouseEventValue(mouse1Tap.twoFingersClick ? 1 : 0, tapCount) time:event.timestamp];
			[mouse1Tap.button setHighlighted:NO];
			mouse1Tap.touch = nil;
		} else if (touch == mouse2Tap.touch) {
			[appc send:EVENT_MOUSE_UP with:MouseEventValue(mouse2Tap.twoFingersClick ? 1 : 1, tapCount) time:event.timestamp];
			[mouse2Tap.button setHighlighted:NO];
			mouse2Tap.touch = nil;
		} else if (touch == mouse3Tap.touch) {
			if (!scrollWithMouse3)
				[appc send:EVENT_MOUSE_UP with:MouseEventValue(mouse3Tap.twoFingersClick ? 1 : 2, tapCount) time:event.timestamp];
			[mouse3Tap.button setHighlighted:NO];
			mouse3Tap.touch = nil;
		} else if (touch == topviewTap.touch) {
			[[NSUserDefaults standardUserDefaults] setFloat:topviewLocation.x forKey:kDefaultKeyTopviewLocationX];
			[[NSUserDefaults standardUserDefaults] setFloat:topviewLocation.y forKey:kDefaultKeyTopviewLocationY];
			topviewTap.touch = nil;
		} else if (touch == arrowKeyTap.touch) {
			arrowKeyTap.touch = nil;
		} else {
			numTouches--;
			if (numTouches == 0) {
				currAccel.stopping = YES;
				multiFingersTap.touch = nil;
			}
			if (multiFingersTap.phase == UITouchPhaseBegan) {
				multiFingersTap.phase = UITouchPhaseEnded;
			}
			prevDelta = CGPointZero;
			if (!clickByTap) {
				// Timer for click & drag gestures
				if (clickTimerTouch == touch)
					clickTimerTouch = nil;
			} else if (event.timestamp - multiFingersTap.timestamp < kTapHoldInterval && numTouches == 0 && multiFingersTap.phase == UITouchPhaseEnded) {
				if (mouse1Tap.dragMode) {
					[appc send:EVENT_MOUSE_UP with:MouseEventValue(mouse1Tap.twoFingersClick ? 1 : 0, tapCount) time:event.timestamp];
					[mouse1Tap.button setSelected:NO];
					mouse1Tap.dragMode = NO;
				} else if (mouse2Tap.dragMode) {
					[appc send:EVENT_MOUSE_UP with:MouseEventValue(mouse2Tap.twoFingersClick ? 1 : 1, tapCount) time:event.timestamp];
					[mouse2Tap.button setSelected:NO];
					mouse2Tap.dragMode = NO;
				} else if (mouse3Tap.dragMode) {
					[appc send:EVENT_MOUSE_UP with:MouseEventValue(mouse3Tap.twoFingersClick ? 1 : 2, tapCount) time:event.timestamp];
					[mouse3Tap.button setSelected:NO];
					mouse3Tap.dragMode = NO;
				} else if (dragByTapDragMode && dragByTapLock) {
					[appc send:EVENT_MOUSE_UP with:MouseEventValue(0, tapCount) time:event.timestamp];
					dragByTapDragMode = NO;
				} else if (twoFingersSecondary && multiFingersTap.numFingers == 2) {
					[appc send:EVENT_MOUSE_DOWN with:MouseEventValue(1, tapCount) time:event.timestamp];
					[appc send:EVENT_MOUSE_UP with:MouseEventValue(1, tapCount) time:event.timestamp];
				} else if (multiFingersTap.numFingers == 1) {
					[appc send:EVENT_MOUSE_DOWN with:MouseEventValue(0, tapCount) time:event.timestamp];
					[appc send:EVENT_MOUSE_UP with:MouseEventValue(0, tapCount) time:event.timestamp];
				}
			} else if (dragByTapDragMode && !dragByTapLock) {
				[appc send:EVENT_MOUSE_UP with:MouseEventValue(0, tapCount) time:event.timestamp];
				dragByTapDragMode = NO;
			}
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
	multiFingersTap.phase = UITouchPhaseCancelled;
	// Extra cancellings may come out
	if (numTouches < 0)
		numTouches = 0;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	int trackingDelta[kTrackingSpeedSteps] = { 480, 16, 8, 7, 6, 5, 4, 3, 2, 1 };
	int scrollingDelta[kScrollingSpeedSteps] = { 480, 16, 8, 7, 6, 5, 4, 3, 2, 1 };
	if ([clickTimer isValid])
		[clickTimer fire];
	for (UITouch *touch in touches) {
		CGPoint touchPoint = [touch locationInView:self.view];
		CGPoint touchPointForButton = [touch locationInView:topview];
		CGPoint prevPoint = [touch previousLocationInView:self.view];
		if (touch == mouse1Tap.touch) {
			if (!mouse1Tap.dragMode && !CGRectContainsPoint([mouse1Tap.button frame], touchPointForButton)) {
				[mouse1Tap.button setSelected:YES];
				[mouse1Tap.button setHighlighted:NO];
				mouse1Tap.dragMode = YES;
				mouse1Tap.touch = nil;
				numTouches++;
				if (numTouches == 1) {
					currAccel.enabled = YES;
					currAccel.stopping = NO;
				}
			}
		} else if (touch == mouse2Tap.touch) {
			if (!mouse2Tap.dragMode && !CGRectContainsPoint([mouse2Tap.button frame], touchPointForButton)) {
				[mouse2Tap.button setSelected:YES];
				[mouse2Tap.button setHighlighted:NO];
				mouse2Tap.dragMode = YES;
				mouse2Tap.touch = nil;
				numTouches++;
				if (numTouches == 1) {
					currAccel.enabled = YES;
					currAccel.stopping = NO;
				}
			}
		} else if (touch == mouse3Tap.touch) {
			if (!mouse3Tap.dragMode && !CGRectContainsPoint([mouse3Tap.button frame], touchPointForButton)) {
				[mouse3Tap.button setSelected:YES];
				[mouse3Tap.button setHighlighted:NO];
				mouse3Tap.dragMode = YES;
				mouse3Tap.touch = nil;
				numTouches++;
				if (numTouches == 1) {
					currAccel.enabled = YES;
					currAccel.stopping = NO;
				}
			}
		} else if (touch == topviewTap.touch) {
			if (topviewTap.dragMode || !CGRectContainsPoint(topviewTap.nonDragArea, touchPoint)) {
				topviewTap.dragMode = YES;
				topviewLocation = CGPointMake(topviewLocation.x, touchPoint.y - [topview frame].size.height/2);
				[self showToolbars:YES temporal:YES];
			}
		} else if (touch == arrowKeyTap.touch) {
			if (!CGRectContainsPoint(arrowKeyTap.nonDragArea, touchPoint)) {
				arrowKeyTap.dragMode = YES;
				int32_t keycode;
				if (arrowKeyTap.tapLocation.y - touchPoint.y > abs(touchPoint.x - arrowKeyTap.tapLocation.x)) {
					keycode = kKeycodeUp;
				} else if (touchPoint.y - arrowKeyTap.tapLocation.y > abs(touchPoint.x - arrowKeyTap.tapLocation.x)) {
					keycode = kKeycodeDown;
				} else if (arrowKeyTap.tapLocation.x > touchPoint.x) {
					keycode = kKeycodeLeft;
				} else {
					keycode = kKeycodeRight;
				}
				[appc send:EVENT_KEY_DOWN with:keycode time:event.timestamp];
				[appc send:EVENT_KEY_UP with:keycode time:event.timestamp];
				arrowKeyTap.tapLocation = touchPoint;
				arrowKeyTap.nonDragArea = CGRectMake(touchPoint.x - kOffsetDragBegins, touchPoint.y - kOffsetDragBegins, kOffsetDragBegins * 2, kOffsetDragBegins * 2);
			}
		} else {
			CGPoint delta = CGPointMake(touchPoint.x - prevPoint.x, touchPoint.y - prevPoint.y);
			CGRect driftRect = CGRectMake(-kOffsetMultiTapDrift, -kOffsetMultiTapDrift, kOffsetMultiTapDrift*2, kOffsetMultiTapDrift*2);
			if (numTouches >= 2 && multiFingersTap.phase == UITouchPhaseBegan && event.timestamp - multiFingersTap.timestamp < kTapHoldInterval && CGRectContainsPoint(driftRect, delta)) {
				// multi-tap drifts frequently
				continue;
			}
			multiFingersTap.phase = UITouchPhaseMoved;
			if (twoFingersScroll && numTouches == 2 || scrollWithMouse3 && mouse3Tap.dragMode && numTouches == 1) {
				float accel = 1;
				int deltaRange = scrollingDelta[scrollingSpeed];
				CGRect accelRect = CGRectMake(-deltaRange, -deltaRange, deltaRange*2, deltaRange*2);
				if (!CGRectContainsPoint(accelRect, delta)) {
					accel = sqrt(delta.x*delta.x + delta.y*delta.y) / deltaRange;
				}
				if (numTouches == 1)
					accel = accel * 2;
				if (allowHorizontalScroll)
					[appc send:EVENT_MOUSE_DELTA_W with:accel * (delta.x + prevDelta.x) / 2 time:event.timestamp];
				[appc send:EVENT_MOUSE_DELTA_Z with:accel * (delta.y + prevDelta.y) / 2 time:event.timestamp];
				prevDelta = delta;
			} else if (numTouches == 1) {
				NSUInteger tapCount = [touch tapCount];
				if (dragByTap && clickByTap && !dragByTapDragMode && tapCount > 1) {
					[appc send:EVENT_MOUSE_DOWN with:MouseEventValue(0, tapCount) time:event.timestamp];
					dragByTapDragMode = YES;
				}
				float accel = 1;
				int deltaRange = trackingDelta[trackingSpeed];
				CGRect accelRect = CGRectMake(-deltaRange, -deltaRange, deltaRange*2, deltaRange*2);
				if (!CGRectContainsPoint(accelRect, delta)) {
					accel = sqrt(delta.x*delta.x + delta.y*delta.y) / deltaRange;
				}
				[appc send:EVENT_MOUSE_DELTA_X with:accel * (delta.x + prevDelta.x) / 2 time:event.timestamp];
				[appc send:EVENT_MOUSE_DELTA_Y with:accel * (delta.y + prevDelta.y) / 2 time:event.timestamp];
				prevDelta = delta;
			}
		}
	}
}


// UIAccelerometerDelegate method, called when the device accelerates.
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	if (!enableAccelMouse)
		return;
	// pseudo high pass filter
	currAccel.ax = acceleration.x * kFilteringFactor + currAccel.ax * (1.0 - kFilteringFactor);
	currAccel.ay = acceleration.y * kFilteringFactor + currAccel.ay * (1.0 - kFilteringFactor);
	currAccel.az = acceleration.z * kFilteringFactor + currAccel.az * (1.0 - kFilteringFactor);
	UIAccelerationValue dx = acceleration.x - currAccel.ax, dy = acceleration.y - currAccel.ay, dz = acceleration.z - currAccel.az;
	// check if iphone is stable or not
	currAccel.stability = currAccel.stability * kAccelerationStabilityFactor + dx*dx + dy*dy + dz*dz;
	if (!currAccel.enabled)
		return;
	int32_t deltaX, deltaY;
	if (currAccel.stopping || currAccel.stability < 0.1) {
		currAccel.vx = currAccel.vx * kAccelerationReleaseFactor;
		currAccel.vy = currAccel.vy * kAccelerationReleaseFactor;
		currAccel.vz = currAccel.vz * kAccelerationReleaseFactor;
	} else {
		// changing current velocity smoothly
		currAccel.vx = currAccel.vx * kAccelerationSmoothFactor + dx;
		currAccel.vy = currAccel.vy * kAccelerationSmoothFactor + dy;
		currAccel.vz = currAccel.vz * kAccelerationSmoothFactor + dz;
	}
	deltaX = currAccel.vx * kHorizontalAccelerationFactor;
	deltaY = -currAccel.vz * kVerticalAccelerationFactor;
	if (deltaX == 0 && deltaY == 0) {
		currAccel.enabled = !currAccel.stopping;
	} else {
		[appc send:EVENT_MOUSE_DELTA_X with:deltaX time:acceleration.timestamp];
		[appc send:EVENT_MOUSE_DELTA_Y with:deltaY time:acceleration.timestamp];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	if (autorotateOrientation && tapViewOrientation != interfaceOrientation && !insecureKeyboardWarningDialog) {
		tapViewOrientation = interfaceOrientation;
		[[NSUserDefaults standardUserDefaults] setInteger:tapViewOrientation forKey:kDefaultKeyTapViewOrientation];
		[self prepareTapView];
	}
	return NO;
}

- (void)prepareTapView {
	[keyboardField resignFirstResponder];
	CGRect rect = [[UIScreen mainScreen] bounds];
	[self showToolbars:NO showStatusbar:NO temporal:YES];
	switch (tapViewOrientation) {
		case UIInterfaceOrientationPortrait:
			[self.view setTransform:CGAffineTransformIdentity];
			[self.view setBounds:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			[self.view setTransform:CGAffineTransformMakeRotation(M_PI)];
			[self.view setBounds:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
			break;
		case UIInterfaceOrientationLandscapeLeft:
			[self.view setTransform:CGAffineTransformMakeRotation(-M_PI/2)];
			[self.view setBounds:CGRectMake(rect.origin.x, rect.origin.y, rect.size.height, rect.size.width)];
			break;
		case UIInterfaceOrientationLandscapeRight:
			[self.view setTransform:CGAffineTransformMakeRotation(M_PI/2)];
			[self.view setBounds:CGRectMake(rect.origin.x, rect.origin.y, rect.size.height, rect.size.width)];
			break;
	}
	[[UIApplication sharedApplication] setStatusBarOrientation:tapViewOrientation];
	[self setNumberOfButtons:numberOfButtons];
	[self prepareToolbarsAndStatusbar];
}

// START keyboardField delegate methods
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	textField.text = @" ";
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
	if ([string isEqualToString:@""]) { // backspace
		[appc send:EVENT_KEY_DOWN with:kKeycodeBackSpace time:timestamp];
		[appc send:EVENT_KEY_UP with:kKeycodeBackSpace time:timestamp];
	} else {
		[appc send:EVENT_ASCII with:[string characterAtIndex:0] time:timestamp];
	}
	return FALSE;
}
// END keyboardField delegate methods

- (void)showInsecureKeyboardWarning {
	[insecureKeyboardWarningDialog dismissWithClickedButtonIndex:0 animated:NO];
	[insecureKeyboardWarningDialog release];
	[insecureKeyboardWarningTimer invalidate];
	[insecureKeyboardWarningTimer release];
	
	insecureKeyboardWarningCount = 7;
	insecureKeyboardWarningDialog = [[UIAlertView alloc] initWithTitle:@"Security Notice" message:[NSString stringWithFormat:@"%@\n(Please click a button after %d seconds to use a keyboard.)", kInsecureKeyboardMessage, insecureKeyboardWarningCount] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"I understand", nil];
	[insecureKeyboardWarningDialog show];
	insecureKeyboardWarningTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(insecureKeyboardWarningCountDown:) userInfo:nil repeats:YES] retain];
}

- (void)insecureKeyboardWarningCountDown:(NSTimer*)timer {
	if (insecureKeyboardWarningDialog && --insecureKeyboardWarningCount > 0) {
		[insecureKeyboardWarningDialog setMessage:[NSString stringWithFormat:@"%@\n(Please click a button after %d %@ to use a keyboard.)", kInsecureKeyboardMessage, insecureKeyboardWarningCount, (insecureKeyboardWarningCount == 1) ? @"second" : @"seconds"]];
	} else {
		[insecureKeyboardWarningDialog setMessage:kInsecureKeyboardMessage];
		[timer invalidate];
		[insecureKeyboardWarningTimer release];
		insecureKeyboardWarningTimer = nil;
		[insecureKeyboardWarningDialog release];
		insecureKeyboardWarningDialog = nil;
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[insecureKeyboardWarningDialog release];
	insecureKeyboardWarningDialog = nil;
	[insecureKeyboardWarningTimer invalidate];
	[insecureKeyboardWarningTimer release];
	insecureKeyboardWarningTimer = nil;
	if (buttonIndex != [alertView cancelButtonIndex] && insecureKeyboardWarningCount == 0) {
		doneInsecureKeyboardWarning = YES;
		[[NSUserDefaults standardUserDefaults] setBool:doneInsecureKeyboardWarning forKey:kDefaultKeyDoneInsecureKeyboardWarning];
	} else {
		hiddenKeyboard = YES;
		[self prepareToolbarsAndStatusbar];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[topview release];
	[bottombar release];
	[keyboardField release];
	[mouse1Tap.button release];
	[mouse2Tap.button release];
	[mouse3Tap.button release];
	[buttonLeftImage release];
	[buttonRightImage release];
	[buttonCenterImage release];
	[buttonRoundedImage release];
	[buttonLeftHighlightedImage release];
	[buttonRightHighlightedImage release];
	[buttonCenterHighlightedImage release];
	[buttonRoundedHighlightedImage release];
	[super dealloc];
}


@end
