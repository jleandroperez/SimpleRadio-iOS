//
//  SRRecording.h
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Simperium/SPManagedObject.h>



@interface SRRecording : SPManagedObject
@property (nonatomic, retain) NSDate	*timeStamp;
@property (nonatomic, retain) NSData	*audio;
@property (nonatomic, retain) NSString	*audioInfo;
@end
