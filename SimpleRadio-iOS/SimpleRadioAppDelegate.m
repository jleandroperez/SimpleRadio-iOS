//
//  AppDelegate.m
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/27/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import "SimpleRadioAppDelegate.h"
#import "SRCoreDataManager.h"


NSString* const SimpleRadioAppId	= @"";
NSString* const SimpleRadioAPIKey	= @"";


@implementation SimpleRadioAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[SRCoreDataManager sharedInstance] startupSimperiumWithAppId:SimpleRadioAppId APIKey:SimpleRadioAPIKey rootViewController:self.window.rootViewController];
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{

}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[SRCoreDataManager sharedInstance] save];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	return UIInterfaceOrientationMaskPortrait;
}

@end
