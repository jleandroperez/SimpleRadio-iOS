//
//  MasterViewController.h
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/27/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
