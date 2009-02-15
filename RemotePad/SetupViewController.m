/*
 *  SetupViewController.m
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

#import "SetupViewController.h"
#import "Constants.h"

@implementation SetupViewController


enum TableSections
{
	kSectionButtonOptions = 0,
	kSectionScrollingOptions,
	kSectionClickingOptions,
	kSectionToggleStatusbar,
	kSectionArrowKeyGestures,
	kSectionAccelMouse,
	kSectionApplication,
	kSectionResetButtonLocation,
	kSectionConnection,
	kSectionVersion,
	kSectionEnd
};


+ (UILabel *)labelWithFrame:(CGRect)frame title:(NSString *)title {
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    
	label.textAlignment = UITextAlignmentLeft;
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor darkGrayColor];
    label.backgroundColor = [UIColor clearColor];
	
    return label;
}

- (void)loadView {
	tapViewController = [(AppController *)([UIApplication sharedApplication].delegate) tapViewController];
	CGRect rect = [[UIScreen mainScreen] applicationFrame];
	UIView *contentView = [[UIView alloc] initWithFrame:rect];
	[contentView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	[contentView setAutoresizesSubviews:YES];
	self.view = contentView;
	UIToolbar *toolbar = [[[UIToolbar alloc] init] autorelease];
	[toolbar setBarStyle:UIBarStyleDefault];
	UIBarButtonItem *flexItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	UIBarButtonItem *doneItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:[UIApplication sharedApplication].delegate action:@selector(hideSetupView:)] autorelease];
	[toolbar setItems:[NSArray arrayWithObjects:flexItem, doneItem, nil]];
	[toolbar sizeToFit];
	CGFloat height = [toolbar frame].size.height;
	[toolbar setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height)];
	[contentView addSubview:toolbar];
	setupTableView = [[UITableView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y + height, rect.size.width, rect.size.height - height) style:UITableViewStyleGrouped];
	[setupTableView setDelegate:self];
	[setupTableView setDataSource:self];
	[setupTableView setAutoresizesSubviews:YES];
	[contentView addSubview:setupTableView];
	[contentView release];
}

// callback routines
- (void) changeNumButtons:(id)sender {
	NSInteger value = [sender selectedSegmentIndex] + 1;
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyNumberOfButtons];
	[tapViewController setNumberOfButtons:value];
}

- (void) changeButtonMapping:(id)sender {
	BOOL value = [sender selectedSegmentIndex] == 0;
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyMouseMapLeftToRight];
	[tapViewController setMouseMapLeftToRight:value];
}

- (void)changeTwoFingersScroll:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyTwoFingersScroll];
	[tapViewController setTwoFingersScroll:value];
}

- (void)changeAllowHorizontalScroll:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyAllowHorizontalScroll];
	[tapViewController setAllowHorizontalScroll:value];
}

- (void)changeScrollWithMouse3:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyScrollWithMouse3];
	[tapViewController setScrollWithMouse3:value];
}

- (void)changeClickByTap:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyClickByTap];
	[tapViewController setClickByTap:value];
}

- (void)changeDragByTap:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyDragByTap];
	[tapViewController setDragByTap:value];
}

- (void)changeDragByTapLock:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyDragByTapLock];
	[tapViewController setDragByTapLock:value];
}

- (void)changeToggleStatusbarClick:(id)sender {
	NSInteger value = ([sender selectedSegmentIndex] == 0) ? 1 : ([sender selectedSegmentIndex] == 1) ? 3 : 0;
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyNumberToggleStatusbar];
	[tapViewController setNumberToggleStatusbar:value];
}

- (void)changeArrowKeyGestureClick:(id)sender {
	NSInteger value = ([sender selectedSegmentIndex] == 0) ? 1 : ([sender selectedSegmentIndex] == 1) ? 2 : 0;
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyNumberArrowKeyGesture];
	[tapViewController setNumberArrowKeyGesture:value];
}

- (void)changeEnableAccelMouse:(id)sender {
	NSInteger value = [sender selectedSegmentIndex] == 0;
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyEnableAccelMouse];
	[tapViewController setEnableAccelMouse:value];
}

- (void)changeAutorotateOrientation:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyAutorotateOrientation];
	[tapViewController setAutorotateOrientation:value];
}

- (void)changeTwoFingersSecondary:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyTwoFingersSecondary];
	[tapViewController setTwoFingersSecondary:value];
}

- (void)changeProhibitSleeping:(id)sender {
	BOOL value = [sender isOn];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:kDefaultKeyProhibitSleeping];
	[tapViewController setProhibitSleeping:value];
}

- (void)resetButtonLocation {
	CGPoint value = CGPointMake([kDefaultTopviewLocationX floatValue], [kDefaultTopviewLocationY floatValue]);
	[[NSUserDefaults standardUserDefaults] setFloat:value.x forKey:kDefaultKeyTopviewLocationX];
	[[NSUserDefaults standardUserDefaults] setFloat:value.y forKey:kDefaultKeyTopviewLocationY];
	[tapViewController setTopviewLocation:value];
	[tapViewController prepareToolbarsAndStatusbar];
}

- (void)disconnectSession {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Disconnect?" message:@"Do you want to disconnect this session?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Disconnect", nil];
	[alertView show];
	[alertView release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[(AppController *)([UIApplication sharedApplication].delegate) setup];
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[setupTableView release];
	[super dealloc];
}


// UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == kSectionResetButtonLocation) {
		[self resetButtonLocation];
	} else if ([indexPath section] == kSectionConnection) {
		[self disconnectSession];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSectionEnd;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title;
	switch (section) {
		case kSectionButtonOptions:
			title = @"Button Options";
			break;
		case kSectionScrollingOptions:
			title = @"Scrolling Options";
			break;
		case kSectionClickingOptions:
			title = @"Clicking Options";
			break;
		case kSectionToggleStatusbar:
			title = @"Toggle Statusbar";
			break;
		case kSectionArrowKeyGestures:
			title = @"Arrow key gestures";
			break;
		case kSectionAccelMouse:
			title = @"Mouse moving by Accelerometer";
			break;
		case kSectionApplication:
			title = @"Application Options";
			break;
		case kSectionResetButtonLocation:
		case kSectionConnection:
		case kSectionVersion:
			title = nil;
			break;
	}
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger number;
	switch (section) {
		case kSectionToggleStatusbar:
		case kSectionResetButtonLocation:
		case kSectionConnection:
		case kSectionVersion:
			number = 1;
			break;
		case kSectionButtonOptions:
		case kSectionArrowKeyGestures:
		case kSectionAccelMouse:
		case kSectionApplication:
			number = 2;
			break;
		case kSectionScrollingOptions:
			number = 3;
			break;
		case kSectionClickingOptions:
			number = 6;
			break;
	}
	return number;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat height;
	
	switch ([indexPath section]) {
		case kSectionButtonOptions:
		case kSectionToggleStatusbar:
			height = kUIRowSegmentHeight;
			break;
		case kSectionScrollingOptions:
		case kSectionApplication:
			height = kUIRowSwitchHeight;
			break;
		case kSectionClickingOptions:
			switch ([indexPath row]) {
				case 3:
				case 5:
					height = kUIRowCommentHeight;
					break;
				default:
					height = kUIRowSwitchHeight;
					break;
			}
			break;
		case kSectionArrowKeyGestures:
		case kSectionAccelMouse:
			if ([indexPath row] == 0)
				height = kUIRowSegmentHeight;
			else
				height = kUIRowCommentHeight;
			break;
		case kSectionResetButtonLocation:
		case kSectionConnection:
			height = kUIRowButtonHeight;
			break;
		case kSectionVersion:
			height = kUIRowLabelHeight;
			break;
	}
	
	return height;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given row
//
- (UITableViewCell *)obtainTableCell {
	UITableViewCell *cell = nil;
	
	cell = [setupTableView dequeueReusableCellWithIdentifier:nil];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[cell setFont:[UIFont systemFontOfSize:16.0]];
	
	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger row = [indexPath row];
	UITableViewCell *cell = [self obtainTableCell];
	UISegmentedControl *segment;
	UISwitch *switchui;
	UILabel *label;
	
	switch ([indexPath section]) {
		case kSectionButtonOptions:
			if (row == 0) {
				[cell setText:@"Number of buttons"];
				segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"1", @"2", @"3", nil]];
				[segment addTarget:self action:@selector(changeNumButtons:) forControlEvents:UIControlEventValueChanged];
				segment.segmentedControlStyle = UISegmentedControlStyleBar;
				segment.selectedSegmentIndex = tapViewController.numberOfButtons - 1;
				[segment setFrame:CGRectMake(0, 0, kSegmentedControlWidth, kSegmentedControlHeight)];
				[cell setAccessoryView:segment];
				[segment release];
			} else {
				[cell setText:@"Primary mouse button"];
				segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Left", @"Right", nil]];
				[segment addTarget:self action:@selector(changeButtonMapping:) forControlEvents:UIControlEventValueChanged];
				segment.segmentedControlStyle = UISegmentedControlStyleBar;
				segment.selectedSegmentIndex = tapViewController.mouseMapLeftToRight ? 0 : 1;
				[segment setFrame:CGRectMake(0, 0, kSegmentedControlWidth, kSegmentedControlHeight)];
				[cell setAccessoryView:segment];
				[segment release];
			}
			break;
		case kSectionScrollingOptions:
			if (row == 0) {
				[cell setText:@"Use two fingers to scroll"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeTwoFingersScroll:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.twoFingersScroll;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else if (row == 1) {
				[cell setText:@"Arrow horizontal scrolling"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeAllowHorizontalScroll:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.allowHorizontalScroll;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else {
				[cell setText:@"Center button scrolling"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeScrollWithMouse3:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.scrollWithMouse3;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			}
			break;
		case kSectionClickingOptions:
			if (row == 0) {
				[cell setText:@"Clicking"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeClickByTap:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.clickByTap;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else if (row == 1) {
				[cell setText:@"Dragging"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeDragByTap:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.dragByTap;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else if (row == 2) {
				[cell setText:@"Drag Lock"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeDragByTapLock:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.dragByTapLock;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else if (row == 3) {
				[cell setText:@"tap again to release"];
				[cell setIndentationLevel:1];
				[cell setFont:[UIFont systemFontOfSize:14.0]];
			} else if (row == 4) {
				[cell setText:@"Secondary clicking"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeTwoFingersSecondary:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.twoFingersSecondary;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else {
				[cell setText:@"by two fingers"];
				[cell setIndentationLevel:1];
				[cell setFont:[UIFont systemFontOfSize:14.0]];
			}
			break;
		case kSectionToggleStatusbar:
			[cell setText:@""];
			segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Single-Click", @"Triple-Click", @"Disable", nil]];
			[segment addTarget:self action:@selector(changeToggleStatusbarClick:) forControlEvents:UIControlEventValueChanged];
			segment.segmentedControlStyle = UISegmentedControlStyleBar;
			if (tapViewController.numberToggleStatusbar == 0)
				segment.selectedSegmentIndex = 2;
			else if (tapViewController.numberToggleStatusbar == 1)
				segment.selectedSegmentIndex = 0;
			else
				segment.selectedSegmentIndex = 1;
			[segment setFrame:CGRectMake(0, 0, kSegmentedControlWidthLong, kSegmentedControlHeight)];
			[cell setAccessoryView:segment];
			[segment release];
			break;
		case kSectionArrowKeyGestures:
			if (row == 0) {
				[cell setText:@""];
				segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Single-Click", @"Double-Click", @"Disable", nil]];
				[segment addTarget:self action:@selector(changeArrowKeyGestureClick:) forControlEvents:UIControlEventValueChanged];
				segment.segmentedControlStyle = UISegmentedControlStyleBar;
				if (tapViewController.numberArrowKeyGesture == 0)
					segment.selectedSegmentIndex = 2;
				else if (tapViewController.numberArrowKeyGesture == 1)
					segment.selectedSegmentIndex = 0;
				else
					segment.selectedSegmentIndex = 1;
				[segment setFrame:CGRectMake(0, 0, kSegmentedControlWidthLong, kSegmentedControlHeight)];
				[cell setAccessoryView:segment];
				[segment release];
			} else {
				[cell setText:@"Click and drag to input arrow key"];
				[cell setIndentationLevel:1];
				[cell setFont:[UIFont systemFontOfSize:14.0]];
			}
			break;
		case kSectionAccelMouse:
			if (row == 0) {
				[cell setText:@""];
				segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Pseudo high pass filter", @"Disable", nil]];
				[segment addTarget:self action:@selector(changeEnableAccelMouse:) forControlEvents:UIControlEventValueChanged];
				segment.segmentedControlStyle = UISegmentedControlStyleBar;
				segment.selectedSegmentIndex = tapViewController.enableAccelMouse ? 0 : 1;
				[segment setFrame:CGRectMake(0, 0, kSegmentedControlWidthLong, kSegmentedControlHeight)];
				[cell setAccessoryView:segment];
				[segment release];
			} else {
				[cell setText:@"Cursor moves only when you hold tapping"];
				[cell setIndentationLevel:1];
				[cell setFont:[UIFont systemFontOfSize:14.0]];
			}
			break;
		case kSectionApplication:
			if (row == 0) {
				[cell setText:@"Autorotating orientation"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeAutorotateOrientation:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.autorotateOrientation;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			} else {
				[cell setText:@"Prohibit sleeping"];
				switchui = [[UISwitch alloc] initWithFrame:CGRectZero];
				[switchui addTarget:self action:@selector(changeProhibitSleeping:) forControlEvents:UIControlEventValueChanged];
				switchui.on = tapViewController.prohibitSleeping;
				switchui.backgroundColor = [UIColor clearColor];
				[cell setAccessoryView:switchui];
				[switchui release];
			}
			break;
		case kSectionResetButtonLocation:
			[cell setText:@"Reset button location"];
			[cell setTextAlignment:UITextAlignmentCenter];
			[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
			break;
		case kSectionConnection:
			[cell setText:@"Disconnect this session"];
			[cell setTextAlignment:UITextAlignmentCenter];
			[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
			break;
		case kSectionVersion:
			[cell setText:@"Version"];
			label = [[UILabel alloc] initWithFrame:CGRectZero];
			[label setText:kVersion];
			[label setFont:[UIFont systemFontOfSize:16.0]];
			[label setTextColor:[UIColor colorWithRed:0.2 green:0.3 blue:0.4 alpha:1.0]];
			[label setBackgroundColor:[UIColor clearColor]];
			[label sizeToFit];
			[cell setAccessoryView:label];
			[label release];
			break;
	}
	
	return cell;
}


@end
