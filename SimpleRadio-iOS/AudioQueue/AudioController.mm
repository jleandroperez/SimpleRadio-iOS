/*

    File: AudioController.mm
Abstract: n/a
 Version: 2.5

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2012 Apple Inc. All Rights Reserved.


*/

#import "AudioController.h"
#import "AQPlayer.h"
#import "AQRecorder.h"
#import <AVFoundation/AVFoundation.h>



@interface AudioController ()
@property (nonatomic, assign)	AQPlayer	*player;
@property (nonatomic, assign)	AQRecorder	*recorder;
@property (nonatomic, assign)	BOOL		playbackWasPaused;
@property (nonatomic, assign)	BOOL		playbackWasInterrupted;
@property (nonatomic, assign)	BOOL		inBackground;
@property (nonatomic, assign)	BOOL		inputAvailable;
- (void)registerForNotifications;
@end


@implementation AudioController

char *OSTypeToStr(char *buf, OSType t)
{
	char *p = buf;
	char str[4] = {0};
    char *q = str;
	*(UInt32 *)str = CFSwapInt32(t);
	for (int i = 0; i < 4; ++i) {
		if (isprint(*q) && *q != '\\')
			*p++ = *q++;
		else {
			sprintf(p, "\\x%02x", *q++);
			p += 4;
		}
	}
	*p = '\0';
	return buf;
}

#pragma mark Playback routines
- (void)startPlayback:(NSData *)data
{
	if (!data) {
		return;
	}
	
	_player->SetAudioData(data);
	
	if (_player->IsRunning())
	{
		if (_playbackWasPaused) {
			OSStatus result = _player->StartQueue(true);
            _playbackWasPaused = NO;
			if (result == noErr) {
				[self.delegate audioControllerDidBeginPlayback:self audioQueue:_player->Queue()];
			}
		}
		else {
			[self stopPlayback];
		}
	}
	else
	{
		// dispose the previous playback queue
		_player->DisposeQueue(true);
		
		OSStatus result = _player->StartQueue(false);
		if (result == noErr) {
			[self.delegate audioControllerDidBeginPlayback:self audioQueue:_player->Queue()];
		}
	}
}

-(void)pausePlayQueue
{
	_player->PauseQueue();
	_playbackWasPaused = YES;
}

-(void)stopPlayback
{
	if (_player->IsRunning() == NO)
	{
		return;
	}
	
	_player->StopQueue();
	[self.delegate audioControllerDidStopPlayback:self];
}


#pragma mark Record routines
- (void)startRecording
{
	if (_recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
		[self stopRecording];
	}
	else // If we're not recording, start.
	{
		_recorder->StartRecord(CFSTR("recordedFile.aac"));
		[self.delegate audioControllerDidBeginRecording:self audioQueue:_recorder->Queue()];
	}	
}

- (void)stopRecording
{
	if (_recorder->IsRunning() == NO)
	{
		return;
	}
	
	_recorder->StopRecord();
		
	// Return the audio recording
	NSString *recordFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: @"recordedFile.aac"];
	NSData *audioData = [NSData dataWithContentsOfFile:recordFilePath];
	[self.delegate audioControllerDidStopRecording:self audioData:audioData];
}

				
#pragma mark Initialization routines
- (instancetype)init
{
	if ((self = [super init])) {
		// Allocate our singleton instance for the recorder & player object
		_recorder = new AQRecorder();
		_player = new AQPlayer();

		//get your app's audioSession singleton object
		AVAudioSession* session = [AVAudioSession sharedInstance];

		//error handling
		BOOL success;
		NSError* error;

		//set the audioSession category.
		//Needs to be Record or PlayAndRecord to use audioRouteOverride:
		success = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
		if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
			
		//set the audioSession override
		success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
		if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);

		self.inputAvailable = session.inputAvailable;
			
		//activate the audio session
		success = [session setActive:YES error:&error];
		if (!success) NSLog(@"AVAudioSession error activating: %@",error);
		else NSLog(@"audioSession active");
				
		// disable the play button since we have no recording to play yet
		_playbackWasInterrupted = NO;
		_playbackWasPaused = NO;
		
		[self registerForNotifications];
	}
	
	return self;
}


#pragma mark Notification
- (void)registerForNotifications
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleInterruptNote:)  name:AVAudioSessionInterruptionNotification object:nil];
	[nc addObserver:self selector:@selector(handleRouteNote:)	   name:AVAudioSessionRouteChangeNotification object:nil];
	[nc addObserver:self selector:@selector(resignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[nc addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)handleRouteNote:(NSNotification *)note
{
	NSNumber *reason = note.userInfo[AVAudioSessionRouteChangeReasonKey];
	if (reason.intValue != kAudioSessionRouteChangeReason_CategoryChange)
	{
		if (reason.intValue == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
		{
			if (self.player->IsRunning()) {
				[self pausePlayQueue];
				[self.delegate audioControllerDidStopPlayback:self];
			}
		}
		
		// stop the queue if we had a non-policy route change
		if (self.recorder->IsRunning()) {
			[self stopRecord];
		}
	}
}

- (void)handleInterruptNote:(NSNotification *)note
{
	NSNumber *state = note.userInfo[AVAudioSessionInterruptionTypeKey];
	if (state.intValue == AVAudioSessionInterruptionTypeBegan)
	{
		if (self.recorder->IsRunning()) {
			[self stopRecord];
		}
		else if (self.player->IsRunning()) {
			//the queue will stop itself on an interruption, we just need to update the UI
			[self.delegate audioControllerDidStopPlayback:self];
			self.playbackWasInterrupted = YES;
		}
	}
	else if ((state.intValue == AVAudioSessionInterruptionTypeEnded) && self.playbackWasInterrupted)
	{
		// we were playing back when we were interrupted, so reset and resume now
		self.player->StartQueue(true);
		[self.delegate audioControllerDidBeginPlayback:self audioQueue:_player->Queue()];
		self.playbackWasInterrupted = NO;
	}
}

- (void)resignActive
{
    if (_recorder->IsRunning()) [self stopRecord];
    if (_player->IsRunning()) [self stopPlayback];
    _inBackground = true;
}

- (void)enterForeground
{
	NSError *error = nil;
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) printf("AudioSessionSetActive (true) failed");
	_inBackground = false;
}

#pragma mark Cleanup

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	delete _player;
	delete _recorder;
	
	[super dealloc];
}

@end
