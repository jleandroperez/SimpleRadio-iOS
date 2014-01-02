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



@interface AudioController ()

@property (nonatomic, assign)	AQPlayer	*player;
@property (nonatomic, assign)	AQRecorder	*recorder;
@property (nonatomic, assign)	BOOL		playbackWasPaused;
@property (nonatomic, assign)	BOOL		playbackWasInterrupted;
@property (nonatomic, assign)	BOOL		inBackground;
@property (nonatomic, assign)	BOOL		inputAvailable;

- (void)registerForBackgroundNotifications;

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

-(void)stopPlayQueue
{
	_player->StopQueue();
	[self.delegate audioControllerDidStopPlayback:self];
}

-(void)pausePlayQueue
{
	_player->PauseQueue();
	_playbackWasPaused = YES;
}

- (void)stopRecord
{
	_recorder->StopRecord();
	
	// dispose the previous playback queue
	_player->DisposeQueue(true);

	// now create a new queue for the recorded file
	recordFilePath = (CFStringRef)[NSTemporaryDirectory() stringByAppendingPathComponent: @"recordedFile.caf"];
	_player->CreateQueueForFile(recordFilePath);
		
	// Set the button's state back to "record"
	[self.delegate audioControllerDidStopRecording:self];
}

- (void)play
{
	if (_player->IsRunning())
	{
		if (_playbackWasPaused) {
			OSStatus result = _player->StartQueue(true);
            _playbackWasPaused = NO;
			if (result == noErr) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
			}
		}
		else {
			[self stopPlayQueue];
		}
	}
	else
	{		
		OSStatus result = _player->StartQueue(false);
		if (result == noErr) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
		}
	}
}

- (void)record
{
	if (_recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
		[self stopRecord];
	}
	else // If we're not recording, start.
	{
		[self.delegate audioControllerDidBeginRecording:self audioQueue:_recorder->Queue()];

		// Start the recorder
		_recorder->StartRecord(CFSTR("recordedFile.caf"));
	}	
}

#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
							UInt32	inInterruptionState)
{
	AudioController *THIS = (AudioController*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		if (THIS->_recorder->IsRunning()) {
			[THIS stopRecord];
		}
		else if (THIS->_player->IsRunning()) {
			//the queue will stop itself on an interruption, we just need to update the UI
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
			THIS->_playbackWasInterrupted = YES;
		}
	}
	else if ((inInterruptionState == kAudioSessionEndInterruption) && THIS->_playbackWasInterrupted)
	{
		// we were playing back when we were interrupted, so reset and resume now
		THIS->_player->StartQueue(true);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:THIS];
		THIS->_playbackWasInterrupted = NO;
	}
}

void propListener(	void *                  inClientData,
					AudioSessionPropertyID	inID,
					UInt32                  inDataSize,
					const void *            inData)
{
	AudioController *THIS = (AudioController*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{
			if (reasonVal == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
			{			
				if (THIS->_player->IsRunning()) {
					[THIS pausePlayQueue];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
				}		
			}

			// stop the queue if we had a non-policy route change
			if (THIS->_recorder->IsRunning()) {
				[THIS stopRecord];
			}
		}	
	}
	else if (inID == kAudioSessionProperty_AudioInputAvailable)
	{
		if (inDataSize == sizeof(UInt32)) {
			// disable recording if input is not available
			THIS->_inputAvailable = *(UInt32*)inData;
		}
	}
}
				
#pragma mark Initialization routines
- (instancetype)init
{
	if ((self == [super init])) {
		// Allocate our singleton instance for the recorder & player object
		_recorder = new AQRecorder();
		_player = new AQPlayer();
			
		OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
		if (error) printf("ERROR INITIALIZING AUDIO SESSION! %d\n", (int)error);
		else 
		{
			UInt32 category = kAudioSessionCategory_PlayAndRecord;	
			error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
			if (error) printf("couldn't set audio category!");
										
			error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
			if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", (int)error);
			UInt32 inputAvailable = 0;
			UInt32 size = sizeof(inputAvailable);
			
			// we do not want to allow recording if input is not available
			error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
			if (error) printf("ERROR GETTING INPUT AVAILABILITY! %d\n", (int)error);
			self.inputAvailable = inputAvailable;
			
			// we also need to listen to see if input availability changes
			error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
			if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", (int)error);

			error = AudioSessionSetActive(true); 
			if (error) printf("AudioSessionSetActive (true) failed");
		}
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(playbackQueueStopped:) name:@"playbackQueueStopped" object:nil];
		[nc addObserver:self selector:@selector(playbackQueueResumed:) name:@"playbackQueueResumed" object:nil];
		
		// disable the play button since we have no recording to play yet
		_playbackWasInterrupted = NO;
		_playbackWasPaused = NO;
		
		[self registerForBackgroundNotifications];
	}
	
	return self;
}

# pragma mark Notification routines
- (void)playbackQueueStopped:(NSNotification *)note
{
	[self.delegate audioControllerDidStopPlayback:self];
}

- (void)playbackQueueResumed:(NSNotification *)note
{
	[self.delegate audioControllerDidBeginPlayback:self audioQueue:_player->Queue()];
}

#pragma mark background notifications
- (void)registerForBackgroundNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resignActive)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(enterForeground)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
}

- (void)resignActive
{
    if (_recorder->IsRunning()) [self stopRecord];
    if (_player->IsRunning()) [self stopPlayQueue];
    _inBackground = true;
}

- (void)enterForeground
{
    OSStatus error = AudioSessionSetActive(true);
    if (error) printf("AudioSessionSetActive (true) failed");
	_inBackground = false;
}

#pragma mark Cleanup

- (void)dealloc
{
	delete _player;
	delete _recorder;
	
	[super dealloc];
}

@end
