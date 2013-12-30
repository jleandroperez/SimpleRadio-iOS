//
//  SRCoreDataManager.h
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface SRCoreDataManager : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext			*managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel			*managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator	*persistentStoreCoordinator;

+ (instancetype)sharedInstance;
- (void)save;

@end
