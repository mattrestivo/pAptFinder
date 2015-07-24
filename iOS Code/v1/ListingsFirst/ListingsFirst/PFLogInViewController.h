//
//  PFLogInViewController.h
//  ListingsFirst
//
//  Created by Matt Restivo on 7/23/15.
//  Copyright (c) 2015 Matt Restivo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PFLogInViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)loginButtonTouchHandler:(id)sender;

@end
