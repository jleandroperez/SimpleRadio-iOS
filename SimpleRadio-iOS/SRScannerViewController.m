//
//  SRScannerViewController.m
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import "SRScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>



// Ref: http://www.ama-dev.com/iphone-qr-code-library-ios-7/

@interface SRScannerViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureDevice				*device;
@property (nonatomic, strong) AVCaptureDeviceInput			*input;
@property (nonatomic, strong) AVCaptureMetadataOutput		*output;
@property (nonatomic, strong) AVCaptureSession				*session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer	*preview;
@property (nonatomic, strong) UIButton						*cancelButton;
@end



@implementation SRScannerViewController

- (id)init {
	if ((self = [super init])) {
		self.cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
		[self.cancelButton addTarget:self action:@selector(btnDismissPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		
		self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
		
		self.session = [[AVCaptureSession alloc] init];
		
		self.output = [[AVCaptureMetadataOutput alloc] init];
		[self.session addOutput:self.output];
		[self.session addInput:self.input];
		
		[self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
		self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
		
		self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
		self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
		self.preview.frame = self.view.bounds;
		
		AVCaptureConnection *con = self.preview.connection;
		con.videoOrientation = AVCaptureVideoOrientationPortrait;
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
			
	// Align the button
	[self.cancelButton sizeToFit];
	
	CGRect buttonFrame = self.cancelButton.frame;
	CGPoint buttonCenter = self.cancelButton.center;
	buttonCenter.x = self.view.center.x;
	buttonCenter.y = self.view.frame.size.height - buttonFrame.size.height;
	self.cancelButton.center = buttonCenter;
	
	// Prepare the views!
	self.view.backgroundColor = [UIColor whiteColor];
    [self.view.layer insertSublayer:self.preview atIndex:0];
	[self.view addSubview:self.cancelButton];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [self.session stopRunning];
}


#pragma mark -
#pragma mark UIViewController Overrides

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}


#pragma mark -
#pragma mark UIButton delegate methods

- (void)btnDismissPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
	if (!self.callback) {
		return;
	}
	
    for(AVMetadataObject *current in metadataObjects) {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
			NSString *scannedValue = [((AVMetadataMachineReadableCodeObject *) current) stringValue];
			self.callback(scannedValue);
		}
    }
}


#pragma mark -
#pragma mark Static Helpers

+ (BOOL)isCameraAvailable {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return videoDevices.count > 0;
}

+ (instancetype)scanner {
	return [[[self class] alloc] init];
}

@end
