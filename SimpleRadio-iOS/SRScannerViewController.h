//
//  SRScannerViewController.h
//  SimpleRadio-iOS
//
//  Created by Jorge Leandro Perez on 12/30/13.
//  Copyright (c) 2013 Jorge Leandro Perez. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef void (^SRScannerCallback)(NSString *detectedValue);

@interface SRScannerViewController : UIViewController

@property (nonatomic, copy) SRScannerCallback callback;

+ (BOOL)isCameraAvailable;
+ (instancetype)scanner;

@end
