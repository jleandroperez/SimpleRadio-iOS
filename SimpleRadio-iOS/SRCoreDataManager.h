//
//  SRCoreDataManager.h
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Simperium/Simperium.h>


@interface SRCoreDataManager : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext			*managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel			*managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (readonly, strong, nonatomic) Simperium						*simperium;

+ (instancetype)sharedInstance;

- (void)startupSimperiumWithAppId:(NSString*)appId APIKey:(NSString*)APIKey rootViewController:(UIViewController*)rootViewController;

- (void)startNetworkingWithEmail:(NSString *)email token:(NSString *)token;
- (void)stopNetworking;

- (void)save;

@end
