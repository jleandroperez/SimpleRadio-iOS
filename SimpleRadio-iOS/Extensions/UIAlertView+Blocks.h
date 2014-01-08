//
//  UIAlertView+Blocks.h
//  SimpleRadio
//
//  Created by Jorge Leandro Perez on 9/3/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^UIAlertViewCompletion) (UIAlertView* alertView, NSUInteger buttonIndex);


@interface UIAlertView (Blocks)

- (id)initWithTitle:(NSString*)title
			message:(NSString*)message
  cancelButtonTitle:(NSString*)cancelButtonTitle
  otherButtonTitles:(NSArray*)otherButtonTitles
		 completion:(UIAlertViewCompletion)completion;

@end
