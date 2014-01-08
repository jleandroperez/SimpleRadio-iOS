//
//  SRRecordingCell.m
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 1/8/14.
//  Copyright (c) 2014 Jorge Leandro Perez. All rights reserved.
//

#import "SRRecordingCell.h"

@implementation SRRecordingCell

- (void)setPlaying:(BOOL)isPlaying
{
	NSLog(@"Here");
	
	NSString *imageName = isPlaying ? @"btn_pause" : @"btn_play";
	self.accessoryView	= [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
	
	_playing = isPlaying;
}

@end
