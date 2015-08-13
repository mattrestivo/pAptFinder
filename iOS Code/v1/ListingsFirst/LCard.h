//
//  LCard.h
//  ListingsFirst
//
//  Created by Matt Restivo on 8/4/15.
//  Copyright (c) 2015 Matt Restivo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCard : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *price;
@property (weak, nonatomic) IBOutlet UILabel *postedTime;
@property (weak, nonatomic) IBOutlet UILabel *webLabel;
@property (weak, nonatomic) IBOutlet UIButton *webButton;

- (void)setupWithDictionary:(NSDictionary *)dictionary;


@end
