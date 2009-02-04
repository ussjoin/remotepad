//
//  Picker.m
//  RemotePad
//
//  Derived from an Apple's sample code Picker.m of WiTap.
//  Modified by iKawamoto Yosihisa! on 08/08/17.
//
/*

File: Picker.m
Abstract: 
 A view that displays both the currently advertised game name and a list of
other games
 available on the local network (discovered & displayed by
BrowserViewController).
 

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

#import "Picker.h"
#import "AppController.h"
#import "Constants.h"

@interface Picker ()
@property (nonatomic, retain, readwrite) BrowserViewController* bvc;
@property (nonatomic, retain, readwrite) UIButton *gameNameLabel;
@end

@implementation Picker

@synthesize bvc = _bvc;
@synthesize gameNameLabel = _gameNameLabel;

- (id)initWithFrame:(CGRect)frame type:(NSString*)type {
	if ((self = [super initWithFrame:frame])) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if (![defaults stringForKey:kDefaultKeyServerName]) {
			[defaults registerDefaults:[NSDictionary dictionaryWithObject:kDefaultServerName forKey:kDefaultKeyServerName]];
		}
		CGFloat runningY = kStatusBarHeight;
		self.bvc = [[BrowserViewController alloc] initWithTitle:nil showDisclosureIndicators:NO showCancelButton:NO];
		[self.bvc searchForServicesOfType:type inDomain:@"local"];
		
		self.opaque = YES;
		self.backgroundColor = [UIColor blackColor];
		
		UIImageView* img = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bg.png"] stretchableImageWithLeftCapWidth:1.0 topCapHeight:25.0]];
		[self addSubview:img];
		
		runningY += kOffset;
		CGFloat width = self.bounds.size.width - 2 * kOffset;
		
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"My name:";
		label.numberOfLines = 1;
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.bounds.size.height;
		[label release];

		self.gameNameLabel = [UIButton buttonWithType:UIButtonTypeCustom];
		[self.gameNameLabel setFont:[UIFont boldSystemFontOfSize:24.0]];
		[self.gameNameLabel setLineBreakMode:UILineBreakModeTailTruncation];
		[self.gameNameLabel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self.gameNameLabel setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75] forState:UIControlStateNormal];
		[self.gameNameLabel setTitleShadowOffset:CGSizeMake(1,1)];
		[self.gameNameLabel setTitle:@"Default Name" forState:UIControlStateNormal];
		[self.gameNameLabel sizeToFit];
		[self.gameNameLabel setFrame:CGRectMake(kOffset, runningY, width, self.gameNameLabel.frame.size.height)];
		[self.gameNameLabel setTitle:@"" forState:UIControlStateNormal];
		[self.gameNameLabel addTarget:self action:@selector(startDemoModeWithDelay) forControlEvents:UIControlEventTouchDown];
		[self.gameNameLabel addTarget:self action:@selector(cancelDemoMode) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel|UIControlEventTouchDragExit];
		[self addSubview:self.gameNameLabel];
		
		runningY += self.gameNameLabel.bounds.size.height + kOffset * 2;
		
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		messageLabel = [label retain];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		[self setMessage:@""];
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.bounds.size.height + 2;
		[label release];
		
		UITextField *serverName = [[UITextField alloc] initWithFrame:CGRectZero];
		[serverName setDelegate:self];
		[serverName setAutocorrectionType:UITextAutocorrectionTypeNo];
		[serverName setClearButtonMode:UITextFieldViewModeWhileEditing];
		[serverName setClearsOnBeginEditing:NO];
		[serverName setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
		[serverName setReturnKeyType:UIReturnKeyGo];
		[serverName setTextAlignment:UITextAlignmentCenter];
		[serverName setFont:[UIFont boldSystemFontOfSize:24.0]];
		[serverName setBorderStyle:UITextBorderStyleRoundedRect];
		[serverName setPlaceholder:@"<IP or Hostname>"];
		[serverName setText:[defaults stringForKey:kDefaultKeyServerName]];
		[serverName sizeToFit];
		serverName.frame = CGRectMake(kOffset, runningY, width, serverName.frame.size.height);
		[self addSubview:serverName];
		
		runningY += serverName.bounds.size.height + kOffset * 2;
		[serverName release];
		
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		[label setTextColor:[UIColor whiteColor]];
		[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[label setShadowOffset:CGSizeMake(1,1)];
		[label setBackgroundColor:[UIColor clearColor]];
		label.text = @"Or, select RemotePad servers:";
		[label sizeToFit];
		label.frame = CGRectMake(kOffset, runningY, width, label.frame.size.height);
		[self addSubview:label];
		
		runningY += label.bounds.size.height + 2;
		[label release];
		
		[img setFrame:CGRectMake(0, kStatusBarHeight, self.bounds.size.width, runningY)];
		[img release];
		
		[self.bvc.view setFrame:CGRectMake(0, runningY, self.bounds.size.width, self.bounds.size.height - runningY)];
		[self addSubview:self.bvc.view];
		
	}
	[gameNameLabelTimer invalidate];
	gameNameLabelTimer = nil;

	return self;
}


- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self.bvc release];
	[self.gameNameLabel release];
	[messageLabel release];
	
	[super dealloc];
}


- (id<BrowserViewControllerDelegate>)delegate {
	return self.bvc.delegate;
}


- (void)setDelegate:(id<BrowserViewControllerDelegate>)delegate {
	[self.bvc setDelegate:delegate];
}

- (NSString *)gameName {
	return [self.gameNameLabel titleForState:UIControlStateNormal];
}

- (void)setGameName:(NSString *)string {
	[self.gameNameLabel setTitle:string forState:UIControlStateNormal];
	[self.bvc setOwnName:string];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString *serverString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
	[[NSUserDefaults standardUserDefaults] setObject:serverString forKey:kDefaultKeyServerName];
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultKeyServerName];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSMutableString *serverString = [NSMutableString stringWithString:[textField text]];
	if ([serverString replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [serverString length])]) {
		[[NSUserDefaults standardUserDefaults] setObject:serverString forKey:kDefaultKeyServerName];
		[textField setText:serverString];
	}
	if ([serverString length] == 0) {
		[self setMessage:@""];
		return;
	}
	NSRange separator = [serverString rangeOfString:@":" options:NSBackwardsSearch];
	NSInteger port;
	NSString *hostname;
	if (separator.location != NSNotFound) {
		hostname = [serverString substringToIndex:separator.location];
		port = [[serverString substringFromIndex:separator.location + separator.length] integerValue];
		if (port <= 0 || 65536 <= port) {
			[self setMessage:@"Invalid port number:"];
			return;
		}
	} else {
		hostname = serverString;
		port = kDefaultPort;
	}
	NSHost *host = [NSHost hostWithAddress:hostname];
	if (host == nil) {
		host = [NSHost hostWithName:hostname];
		if (host == nil) {
			[self setMessage:@"Invalid IP address or hostname:"];
			return;
		}
	}
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
	[NSStream getStreamsToHost:host port:port inputStream:&inputStream outputStream:&outputStream];
	if (inputStream == nil || outputStream == nil) {
		[self setMessage:@"Cannot connect:"];
	} else {
		[self setMessage:@""];
		[(AppController *)[UIApplication sharedApplication].delegate setInputStream:inputStream outputStream:outputStream];
	}
}


- (void)setMessage:(NSString *)message {
	if (!message || [message isEqual:@""]) {
		[messageLabel setTextColor:[UIColor whiteColor]];
		[messageLabel setText:@"Enter server IP address or Hostname:"];
	} else {
		[messageLabel setTextColor:[UIColor redColor]];
		[messageLabel setText:message];
	}
}


- (void)startDemoModeWithDelay {
	[gameNameLabelTimer invalidate];
	gameNameLabelTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(startDemoMode:) userInfo:nil repeats:NO];
}

- (void)cancelDemoMode {
	[gameNameLabelTimer invalidate];
	gameNameLabelTimer = nil;
}

- (void)startDemoMode:(NSTimer*)theTimer {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Demo start?" message:@"Do you want to start demo mode?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Start", nil];
	[alertView show];
	[alertView release];
	gameNameLabelTimer = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1)
		[self.bvc startDemoResolve];
}

@end
