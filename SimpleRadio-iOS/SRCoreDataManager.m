//
//  SRCoreDataManager.m
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import "SRCoreDataManager.h"



@interface Simperium ()
- (void)startNetworkManagers;
- (void)stopNetworkManagers;
@end


@interface SRCoreDataManager ()
@property (readwrite, strong, nonatomic) NSManagedObjectContext			*managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel			*managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (readwrite, strong, nonatomic) Simperium						*simperium;
@end


@implementation SRCoreDataManager

+ (instancetype)sharedInstance {
	static id _instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_instance = [[[self class] alloc] init];
	});
	
	return _instance;
}

- (void)startupSimperiumWithAppId:(NSString*)appId APIKey:(NSString*)APIKey rootViewController:(UIViewController*)rootViewController
{
	self.simperium = [[Simperium alloc] initWithRootViewController:rootViewController];
	self.simperium.authenticationEnabled = NO;
	[self.simperium startWithAppID:appId APIKey:APIKey model:self.managedObjectModel context:self.managedObjectContext coordinator:self.persistentStoreCoordinator];
}

- (void)startNetworkingWithEmail:(NSString *)email token:(NSString *)token
{
    self.simperium.user = [[SPUser alloc] initWithEmail:email token:token];
    [self.simperium performSelector:@selector(startNetworkManagers)];
}

- (void)stopNetworking
{
    [self.simperium performSelector:@selector(stopNetworkManagers)];
	self.simperium.user = nil;
}


- (void)save {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SimpleRadio_iOS" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SimpleRadio_iOS.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
