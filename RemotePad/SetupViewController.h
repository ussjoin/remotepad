/*
 *  SetupViewController.h
 *  RemotePad
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

#import <UIKit/UIKit.h>
#import "AppController.h"
#import "TapView.h"

@interface SetupViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	TapViewController *tapViewController;
	UITableView *setupTableView;
	
	UITableViewCell *connectionCell;

	UITableViewCell *numberOfButtonsCell;
	UITableViewCell *mouseMapLeftToRightCell;
	UITableViewCell *doLabelsForMouseButtonsCell;

	UITableViewCell *twoFingersScrollCell;
	UITableViewCell *allowHorizontalScrollCell;
	UITableViewCell *scrollWithMouse3Cell;
	UITableViewCell *scrollingSpeedCell;

	UITableViewCell *trackingSpeedCell;

	UITableViewCell *clickByTapCell;
	UITableViewCell *dragByTapCell;
	UITableViewCell *dragByTapLockCell;
	UITableViewCell *dragByTapLockCommentCell;
	UITableViewCell *twoFingersSecondaryCell;
	UITableViewCell *twoFingersSecondaryCommentCell;

	UITableViewCell *numberToggleStatusbarCell;

	UITableViewCell *numberArrowKeyGestureCell;
	UITableViewCell *numberArrowKeyGestureCommentCell;

	UITableViewCell *enableAccelMouseCell;
	UITableViewCell *enableAccelMouseCommentCell;

	UITableViewCell *autorotateOrientationCell;
	UITableViewCell *prohibitSleepingCell;

	UITableViewCell *topviewLocationCell;
	UITableViewCell *topviewLocationCommentCell;

	UITableViewCell *resetSecurityWarningsCell;

	UITableViewCell *versionCell;
}

+ (UILabel *)labelWithFrame:(CGRect)frame title:(NSString *)title;

@end
