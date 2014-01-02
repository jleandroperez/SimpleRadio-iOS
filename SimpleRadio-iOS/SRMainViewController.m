//
//  MasterViewController.m
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/27/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import "SRMainViewController.h"
#import "SRScannerViewController.h"



@implementation SRMainViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = NSLocalizedString(@"Scan", nil);
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark -
#pragma mark UIButton Delegate Methods

- (IBAction)scanBarCode:(id)sender
{
//	if (![SRScannerViewController isCameraAvailable]) {
//		return;
//	}
//	
//	SRScannerViewController *scanner = [SRScannerViewController scanner];
//	scanner.callback = ^(NSString *detected) {
// TODO: Inject token in Simperium
//		[self dismissViewControllerAnimated:YES completion:^{
			[self performSegueWithIdentifier:@"showRecorder" sender:nil];
//		}];
//	};
//	
//	[self presentViewController:scanner animated:YES completion:nil];
}

@end
