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
    
    //self.thumbnail.image = [UIImage imageNamed:@"brianB.png"];
    self.thumbnail.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[dictionary valueForKey:@"thumbUrl"]]]];
    self.price.text = [NSString stringWithFormat: @" $%@", [dictionary valueForKey:@"price"]];
    self.title.text = [dictionary valueForKey:@"title"];
    
    NSString *dateStr = [dictionary valueForKey:@"created"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [dateFormat dateFromString:dateStr];
    
    self.postedTime.text = [self timeAgo:date];
    
    NSLog(@"%@",dictionary);
    
//    NSString *aboutText = [dictionary valueForKey:@"about"];
//    NSString *newlineString = @"\n";
//    self.aboutLabel.text = [aboutText stringByReplacingOccurrencesOfString:@"\\n" withString:newlineString];
    
    if ( listingUrl ) {
        self.webLabel.text = [dictionary valueForKey:@"url"];
    } else {
        self.webLabel.hidden = YES;
        self.webButton.hidden = YES;
    }
    
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString *)timeAgo:(NSDate *)compareDate{
    NSTimeInterval timeInterval = -[compareDate timeIntervalSinceNow];
    int temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"now"];   //less than a minute
    }else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%dm",temp];   //minutes ago
    }else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%dh",temp];   //hours ago
    }else{
        temp = temp / 24;
        result = [NSString stringWithFormat:@"%dd",temp];   //days ago
    }
    return  result;
}

@end
