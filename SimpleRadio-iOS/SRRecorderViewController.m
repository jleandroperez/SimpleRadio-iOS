//
//  SRRecorderViewController.m
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import "SRRecorderViewController.h"
#import "AQLevelMeter.h"
#import "AudioController.h"
#import "SRCoreDataManager.h"
#import "SRRecording.h"
#import "UIAlertView+Blocks.h"
#import "SRRecordingCell.h"



@interface SRRecorderViewController () <NSFetchedResultsControllerDelegate, AudioControllerDelegate>

@property (nonatomic, weak)		IBOutlet UITableView		*tableView;
@property (nonatomic, weak)		IBOutlet AQLevelMeter		*meter;
@property (nonatomic, weak)		IBOutlet UIButton			*recordButton;
@property (nonatomic, strong)	AudioController				*controller;
@property (nonatomic, strong)	NSFetchedResultsController	*fetchedResultsController;
@property (nonatomic, strong)	NSString					*playingSimperiumKey;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end


@implementation SRRecorderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Recorder", nil);
	
	// Tune UI
	UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
	self.meter.backgroundColor = bgColor;
	self.meter.borderColor = bgColor;

	// Setup AudioController
	self.controller = [[AudioController alloc] init];
	self.controller.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	self.meter.aq = nil;
	
	[self.controller stopPlayback];
	[self.controller stopRecording];
}


#pragma mark -
#pragma mark AudioController Delegate

- (void)audioControllerDidBeginRecording:(AudioController *)audioController audioQueue:(AudioQueueRef)audioQueue
{
	[self.recordButton setTitle:@"Done Recording" forState:UIControlStateNormal];
	self.meter.aq = audioQueue;
}

- (void)audioControllerDidStopRecording:(AudioController *)audioController audioData:(NSData *)audioData
{
	// Disable Meter
	[self.recordButton setTitle:@"Start Recording" forState:UIControlStateNormal];
	self.meter.aq = nil;
	
	// AlertView Handler
	UIAlertViewCompletion completion = ^(UIAlertView* alertView, NSUInteger buttonIndex) {
		
		if (buttonIndex == 0) {
			return;
		}
		
		NSString *details = [[alertView textFieldAtIndex:0] text];
		[self insertAudioData:audioData details:details];
	};

	// Ask for confirmation before saving
	NSString *title				= @"New Recording";
	NSString *message			= @"Enter a name for this recording";
	NSString *cancelButtonTitle = @"Cancel";
	NSArray *otherButtonTitles	= @[ @"OK" ];
	NSString *textPlaceholder	= [self newRecordingDetails];
	
	UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles completion:completion];
	av.alertViewStyle = UIAlertViewStylePlainTextInput;
	[[av textFieldAtIndex:0] setText:textPlaceholder];
    [av show];
}

- (void)audioControllerDidBeginPlayback:(AudioController *)audioController audioQueue:(AudioQueueRef)audioQueue
{
	self.meter.aq = audioQueue;
}

- (void)audioControllerDidStopPlayback:(AudioController *)audioController
{
	self.meter.aq = nil;
	self.playingSimperiumKey = nil;
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark Helpers

- (void)insertAudioData:(NSData *)audioData details:(NSString *)details
{
	NSManagedObjectContext *context = [[SRCoreDataManager sharedInstance] managedObjectContext];
	SRRecording *recording = (SRRecording *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SRRecording class]) inManagedObjectContext:context];
	
	recording.audio		= audioData;
	recording.timeStamp = [NSDate date];
	recording.details	= (details.length > 0) ? details : [self newRecordingDetails];
	
	[[SRCoreDataManager sharedInstance] save];
}

- (NSString *)newRecordingDetails
{
	NSString *shortDate = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
	return [NSString stringWithFormat:@"Recording %@", shortDate];
}


#pragma mark -
#pragma mark Button Delegates

- (IBAction)btnRecordPressed:(id)sender
{
	// Just in case, stop any playback
	[self.controller stopPlayback];
	
	// startRecording will stop, if anything else was in course
	[self.controller startRecording];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![context save:&error])
		{
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Stop previous playback
	[self.controller stopPlayback];
	
	// Start playing!
    SRRecording *object = (SRRecording *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	[self.controller startPlayback:object.audio];
	self.playingSimperiumKey = object.simperiumKey;
	
	// Refresh UI
	[tableView reloadData];
}


#pragma mark - 
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSManagedObjectContext *context = [[SRCoreDataManager sharedInstance] managedObjectContext];
	
    fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass([SRRecording class]) inManagedObjectContext:context];
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO] ];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}

    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


#pragma mark -
#pragma mark UI Helpers

- (void)configureCell:(SRRecordingCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SRRecording *object = (SRRecording *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = object.details;
	cell.playing		= [object.simperiumKey isEqualToString:self.playingSimperiumKey];
}

@end
