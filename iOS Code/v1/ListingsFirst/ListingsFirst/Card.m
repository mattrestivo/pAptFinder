//
//  Card.m
//  ListingsFirst
//
//  Created by Matt Restivo on 8/13/15.
//  Copyright (c) 2015 Matt Restivo. All rights reserved.
//

#import "Card.h"

@implementation Card

@synthesize title = _titleLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // configure control(s)
        self.title = [[UILabel alloc] initWithFrame:CGRectMake(5, 10, 300, 30)];
        self.title.textColor = [UIColor blackColor];
        self.title.font = [UIFont fontWithName:@"Arial" size:12.0f];
        
        [self addSubview:self.title];
    }
    return self;
}

@end