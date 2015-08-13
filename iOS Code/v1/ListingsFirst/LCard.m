//
//  LCard.m
//  ListingsFirst
//
//  Created by Matt Restivo on 8/4/15.
//  Copyright (c) 2015 Matt Restivo. All rights reserved.
//

#import "LCard.h"
#import <QuartzCore/QuartzCore.h>

@interface LCard () {
    
}

@end

@implementation LCard

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setupWithDictionary:(NSDictionary *)dictionary
{
    self.mainView.layer.cornerRadius = 10;
    self.mainView.layer.masksToBounds = YES;
    
    // values
    NSString *listingId = [dictionary valueForKey:@"objectId"];
    NSString *listingUrl = [dictionary valueForKey:@"url"]; // convert to NSURL?
    
    self.thumbnail.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[dictionary valueForKey:@"thumbUrl"]]]];
    self.price.text = [dictionary valueForKey:@"price"];
    self.title.text = [dictionary valueForKey:@"title"];
    
    NSLog(@"%@",dictionary);
    NSLog(@"%@",listingUrl);
    NSLog(@"%@",listingId);
    NSLog(@"%@",[dictionary valueForKey:@"price"]);
    NSLog(@"%@",[dictionary valueForKey:@"title"]);
    
//    NSString *aboutText = [dictionary valueForKey:@"about"];
//    NSString *newlineString = @"\n";
//    self.aboutLabel.text = [aboutText stringByReplacingOccurrencesOfString:@"\\n" withString:newlineString];
    
    if ( listingUrl ) {
        self.webLabel.text = [dictionary valueForKey:@"web"];
    } else {
        self.webLabel.hidden = YES;
        self.webButton.hidden = YES;
    }
    
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
