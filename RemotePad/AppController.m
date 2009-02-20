//
//  AppController.m
//  RemotePad
//
//  Derived from an Apple's sample code AppController.m of WiTap.
//  Modified by iKawamoto Yosihisa! on 08/08/17.
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

#import "AppController.h"
#import "TapView.h"
#import "SetupViewController.h"
#import "Constants.h"

#include <sys/time.h>

//INTERFACES:

@interface AppController ()
- (void) setup;
- (void) presentPicker:(NSString*)name;
@end

//CLASS IMPLEMENTATIONS:

@implementation AppController

@synthesize tapViewController;

- (void) _showAlert:(NSString*)title
{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	
	//Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[_window setBackgroundColor:[UIColor darkGrayColor]];
	
	//Create a picker view
	pickerViewController = [[PickerViewController alloc] init];
	navigationController = [[UINavigationController alloc] initWithRootViewController:pickerViewController];
	[navigationController setNavigationBarHidden:YES animated:NO];
	
	//Create the tap views and add them to the view controller's view
	tapViewController = [[TapViewController alloc] init];
	[tapViewController resetAllStates:self];

	//Create the setup view
	setupViewController = [[SetupViewController alloc] init];

	[_window addSubview:navigationController.view];
	
	//Show the window
	[application setStatusBarHidden:NO animated:YES];
	[_window makeKeyAndVisible];
	
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	
	//Create and advertise a new game and discover other availble games
	[self setup];
}
- (void)applicationWillTerminate:(UIApplication *)application {
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) dealloc
{
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_inStream release];

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_outStream release];

	[_server release];
	
	[tapViewController release];
	[setupViewController release];
	[navigationController release];
	[pickerViewController release];

	[_window release];
	
	[super dealloc];
}

- (void) setup {
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream release];
	_inStream = nil;
	_inReady = NO;

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
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
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kBonjourIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}
	
	[self presentPicker:nil];
}

- (void) showSetupView:(id)sender {
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	if (tapViewController.tapViewOrientation != UIInterfaceOrientationPortrait) {
		[tapViewController showToolbars:NO showStatusbar:NO temporal:YES];
		[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
	}
	[navigationController pushViewController:setupViewController animated:YES];
}

- (void) hideSetupView:(id)sender {
	[navigationController popViewControllerAnimated:YES];
	[tapViewController prepareTapView];
	[[UIAccelerometer sharedAccelerometer] setDelegate:tapViewController];
}

- (void) showTapView {
	[tapViewController resetAllStates:self];
	[navigationController pushViewController:tapViewController animated:YES];
	[tapViewController prepareTapView];
	[[UIAccelerometer sharedAccelerometer] setDelegate:tapViewController];
}

// Make sure to let the user know what name is being used for Bonjour advertisement.
// This way, other players can browse for and connect to this game.
// Note that this may be called while the alert is already being displayed, as
// Bonjour may detect a name conflict and rename dynamically.
- (void) presentPicker:(NSString*)name {
	[(Picker *)[pickerViewController view] setGameName:name];
	[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	[navigationController popToRootViewControllerAnimated:YES];
}

// If we display an error or an alert that the remote disconnected, handle dismissal and return to setup
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup];
}

- (void)send:(uint32_t)type with:(int32_t)value time:(NSTimeInterval)timestamp {
	uint32_t tv_sec = (uint32_t)timestamp;
	MouseEvent event = {htonl(type), htonl(value), htonl(tv_sec), htonl((long)((timestamp-tv_sec)*1.0E9))};

	if (_outStream && [_outStream hasSpaceAvailable])
		if([_outStream write:(uint8_t *)&event maxLength:sizeof(MouseEvent)] == -1)
			[self _showAlert:@"Failed sending data to peer"];
}

- (void) openStreams
{
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)netService
{
	if (!netService) {
		[self setup];
		return;
	}

	if (![netService getInputStream:&_inStream outputStream:&_outStream]) {
		[self _showAlert:@"Failed connecting to server"];
		return;
	}

	[self openStreams];
}

- (void)setInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {
	_inStream = inputStream;
	[_inStream retain];
	_outStream = outputStream;
	[_outStream retain];
	
	[self openStreams];
}

@end

@implementation AppController (NSStreamDelegate)

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
	UIAlertView* alertView;
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
				[self showTapView];
				
				alertView = [[UIAlertView alloc] initWithTitle:@"Connected!" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
				[alertView show];
				[alertView release];
			}
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inStream) {
				uint8_t b;
				unsigned int len = 0;
				len = [_inStream read:&b maxLength:sizeof(uint8_t)];
				if(!len) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self _showAlert:@"Failed reading data from peer"];
				}
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			UIAlertView*			alertView;
			
			alertView = [[UIAlertView alloc] initWithTitle:@"Peer Disconnected!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];

			break;
		}
		case NSStreamEventErrorOccurred:
		{
			[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			[_inStream release];
			_inStream = nil;
			_inReady = NO;
			[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			[_outStream release];
			_outStream = nil;
			_outReady = NO;
			NSError *theError = [stream streamError];
			UIAlertView *alertView;
			NSString *message = @"";
			if ([[theError domain] isEqualToString:NSPOSIXErrorDomain]) {
				switch ([theError code]) {
					case EAFNOSUPPORT:
						message = @"\nAdvice:\nPlease change the settings of your Firewall on your Mac to allow connections for the RemotePad Server.";
						break;
					case ETIMEDOUT:
						message = @"\nAdvice:\nPlease change the settings of your Windows Firewall on your PC to allow connections for the RemotePad Server.";
						break;
				}
			}
			alertView = [[UIAlertView alloc] initWithTitle:@"Error from stream!" message:[NSString stringWithFormat:@"System Message:\n%@%@", [theError localizedDescription], message] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];
			if (!_server)
				[self setup];
			break;
		}
	}
}

@end

@implementation AppController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	NSLog(@"%s", _cmd);
	[self presentPicker:string];
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
	
	[self openStreams];
}

@end
