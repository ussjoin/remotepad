//
//  TapView.h
//  RemotePad
//
//  Derived from an Apple's sample code TapView.h of WiTap.
//  Modified by iKawamoto Yosihisa! on 08/08/17.
//
/*

File: TapView.h
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

#import <UIKit/UIKit.h>
#import "Event.h"

@class AppController;


typedef struct {
	UITouch *touch;
	CGPoint tapLocation;
	CGRect nonDragArea;
	// for button click
	UIButton *button;
	BOOL dragMode;
	BOOL twoFingersClick;
	// for multi-fingers click
	NSTimeInterval timestamp;
	int numFingers;
	UITouchPhase phase;
} MouseTap;

typedef struct {
	BOOL valid;
	BOOL stopping;
	BOOL enabled;
	UIAccelerationValue ax;
	UIAccelerationValue ay;
	UIAccelerationValue az;
	UIAccelerationValue vx;
	UIAccelerationValue vy;
	UIAccelerationValue vz;
	double stability;
} AccelValues;

//CLASS INTERFACES:

@interface TapViewController : UIViewController <UIAccelerometerDelegate>
{
	AppController *appc;
	CGPoint start;
	MouseTap mouse1Tap, mouse2Tap, mouse3Tap, topviewTap, arrowKeyTap, multiFingersTap;
	int numTouches;
	UIView *topview;
	UIToolbar *bottombar;
	BOOL hiddenStatusbar;
	BOOL hiddenToolbars;
	UIImage *buttonLeftImage, *buttonLeftHighlightedImage;
	UIImage *buttonRightImage, *buttonRightHighlightedImage;
	UIImage *buttonCenterImage, *buttonCenterHighlightedImage;
	UIImage *buttonRoundedImage, *buttonRoundedHighlightedImage;
	CGPoint prevDelta;
	BOOL dragByTapDragMode;
	NSTimer *clickTimer;
	UITouch *clickTimerTouch;
	//config value
	CGPoint topviewLocation;
	int numberOfButtons;
	BOOL mouseMapLeftToRight;
	int numberArrowKeyGesture;
	BOOL twoFingersScroll;
	BOOL allowHorizontalScroll;
	BOOL clickByTap;
	BOOL dragByTap;
	BOOL dragByTapLock;
	int numberToggleStatusbar;
	int numberToggleToolbars;
	BOOL scrollWithMouse3;
	AccelValues currAccel;
	BOOL enableAccelMouse;
	UIInterfaceOrientation tapViewOrientation;
	BOOL autorotateOrientation;
	BOOL twoFingersSecondary;
	BOOL prohibitSleeping;
}

- (void)resetAllStates:(id)applicationControllerDelegate;
- (void)toggleStatusbars;
- (void)showToolbars:(BOOL)show temporal:(BOOL)temporally;
- (void)showToolbars:(BOOL)showToolbars showStatusbar:(BOOL)showStatusbar temporal:(BOOL)temporally;
- (void)prepareToolbarsAndStatusbar;
- (void)setNumberOfButtons:(int)val;
- (void)setMouseMapLeftToRight:(BOOL)isLeftToRight;
- (void)setNumberOfButtons:(int)val mouseMapLeftToRight:(BOOL)isLeftToRight;
- (void)setProhibitSleeping:(BOOL)value;
- (void)registerDefaults;
- (void)readDefaults;
- (void)prepareTapView;

@property (nonatomic,retain) AppController *appc;
@property (readonly) UIView *topview;
@property CGPoint topviewLocation;
@property (readonly) int numberOfButtons;
@property (readonly) BOOL mouseMapLeftToRight;
@property int numberArrowKeyGesture;
@property BOOL twoFingersScroll;
@property BOOL allowHorizontalScroll;
@property BOOL clickByTap;
@property BOOL dragByTap;
@property BOOL dragByTapLock;
@property int numberToggleStatusbar;
@property BOOL scrollWithMouse3;
@property BOOL enableAccelMouse;
@property UIInterfaceOrientation tapViewOrientation;
@property BOOL autorotateOrientation;
@property BOOL twoFingersSecondary;
@property (readonly) BOOL prohibitSleeping;

@end
