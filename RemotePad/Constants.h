/*
 *  Constants.h
 *  RemotePad
 *
 *  Created by iKawamoto Yosihisa! on 08/09/04.
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


// version
#define kVersion @"1.3"


// application defaults keys
#define kDefaultKeyVersion					@"version"
#define kDefaultKeyTopviewLocationX			@"topviewLocationX"
#define kDefaultKeyTopviewLocationY			@"topviewLocationY"
#define kDefaultKeyNumberOfButtons			@"numberOfButtons"
#define kDefaultKeyMouseMapLeftToRight		@"leftPrimaryButton"
#define kDefaultKeyNumberArrowKeyGesture	@"numberArrowKeyGesture"
#define kDefaultKeyTwoFingersScroll			@"twoFingerScroll"
#define kDefaultKeyAllowHorizontalScroll	@"horizontalScroll"
#define kDefaultKeyClickByTap				@"clickByTap"
#define kDefaultKeyDragByTap				@"dragByTap"
#define kDefaultKeyDragByTapLock			@"dragByTapLock"
#define kDefaultKeyNumberToggleStatusbar	@"numberToggleStatusbar"
#define kDefaultKeyNumberToggleToolbars		@"numberToggleToolbars"
#define kDefaultKeyScrollWithMouse3			@"scrollWithMouse3"
#define kDefaultKeyEnableAccelMouse			@"enableAccelMouse"
#define kDefaultKeyServerName				@"serverName"
#define kDefaultKeyTapViewOrientation		@"tapviewOrientation"
#define kDefaultKeyAutorotateOrientation	@"autorotateOrientation"
#define kDefaultKeyTwoFingersSecondary		@"twoFingersSecondary"
// application defaults values
#define kDefaultVersion					kVersion
#define kDefaultTopviewLocationX		@"0"
#define kDefaultTopviewLocationY		@"20"
#define kDefaultNumberOfButtons			@"3"
#define kDefaultMouseMapLeftToRight		@"YES"
#define kDefaultNumberArrowKeyGesture	@"0"
#define kDefaultTwoFingersScroll		@"YES"
#define kDefaultAllowHorizontalScroll	@"YES"
#define kDefaultClickByTap				@"NO"
#define kDefaultDragByTap				@"YES"
#define kDefaultDragByTapLock			@"YES"
#define kDefaultNumberToggleStatusbar	@"1"
#define kDefaultNumberToggleToolbars	@"3"
#define kDefaultScrollWithMouse3		@"NO"
#define kDefaultEnableAccelMouse		@"NO"
#define kDefaultServerName				@""
#define kDefaultTapViewOrientation		@"1"
#define kDefaultAutorotateOrientation	@"YES"
#define kDefaultTwoFingersSecondary		@"YES"

// Bonjour constants

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kBonjourIdentifier		@"remotepad"
#define kDefaultPort			5583


// Accelerometer constants

// Constant for the number of times per second (Hertz) to sample acceleration.
#define kAccelerometerFrequency			40
// Constant for the high-pass filter.
#define kFilteringFactor				0.1
// misc
#define kVerticalAccelerationFactor		12.0
#define kHorizontalAccelerationFactor	8.0
#define kAccelerationStabilityFactor	0.9
#define kAccelerationReleaseFactor		0.8
#define kAccelerationSmoothFactor		0.95

// picker view constants

#define kStatusBarHeight			20.0
#define kOffset						5.0


// tap view constants

#define kOffsetDragBegins			50
#define kButtonHeight				100
#define kTapHoldInterval			0.3
#define kOffsetMultiTapDrift		4

// setup view constants

// padding for margins
#define kLeftMargin					20.0
#define kTopMargin					20.0
#define kRightMargin				20.0
#define kBottomMargin				20.0
#define kTweenMargin				10.0

// control dimensions
#define kSegmentedControlWidth		96.0
#define kSegmentedControlWidthLong	280.0
#define kSegmentedControlHeight		30.0
#define kSwitchWidth				90.0
#define kSwitchHeight				27.0
#define kLabelHeight				20.0
#define kToggleButtonItemWidth		90.0

// table row dimensions
#define kUIRowSegmentHeight			40.0
#define kUIRowSwitchHeight			40.0
#define kUIRowButtonHeight			40.0
#define kUIRowCommentHeight			20.0
#define kUIRowLabelHeight			40.0
