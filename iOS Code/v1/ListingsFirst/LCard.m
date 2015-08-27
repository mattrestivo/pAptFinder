//
//  LCard.m
//  ListingsFirst
//
//  Created by Matt Restivo on 8/4/15.
//  Copyright (c) 2015 Matt Restivo. All rights reserved.
//

#import "LCard.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+WebCache.h"

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
    
    self.listingDictionary = dictionary;
    
    NSLog(@"%@",dictionary);
    
    self.mainView.layer.cornerRadius = 10;
    self.mainView.layer.masksToBounds = YES;
    
    // share and maps
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharingButton:)]; // forControlEvents:UIControlEventTouchUpInside
    toolbar.frame = CGRectMake(220, 220, 40, 30);
    toolbar.barTintColor = [UIColor redColor];
    [toolbar setItems:[NSArray arrayWithObject:item] animated:NO];
    [self.mainView addSubview:toolbar];
    
    // values
    NSString *listingId = [self.listingDictionary valueForKey:@"objectId"];
    NSString *listingUrl = [self.listingDictionary valueForKey:@"url"]; // convert to NSURL?
    NSString *thumbnailImageUrl = [self.listingDictionary valueForKey:@"thumbUrl"];
    
    // IMAGE
    //self.thumbnail.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:thumbnailImageUrl]]];
    
    // Here we use the new provided sd_setImageWithURL: method to load the web image
    [self.thumbnail sd_setImageWithURL:[NSURL URLWithString:thumbnailImageUrl]
                    placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    
    // change this to lazy load images here.
    
    // ALL OTHER TEXT
    self.price.text = [NSString stringWithFormat: @" $%@", [self.listingDictionary valueForKey:@"price"]];
    self.title.text = [self.listingDictionary valueForKey:@"title"];
    
    NSString *dateStr = [self.listingDictionary valueForKey:@"created"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [dateFormat dateFromString:dateStr];
    
    self.postedTime.text = [self timeAgo:date];
    
    if ( listingUrl ) {
        self.webLabel.text = [self.listingDictionary valueForKey:@"url"];
    } else {
        self.webLabel.hidden = YES;
        self.webButton.hidden = YES;
    }
    
    
    
}

- (IBAction)sharingButton:(UIButton*)sender {
    
    NSLog(@"%@",sender);
    
    NSString *shareText = @"Check out this listing I found... \n\n";
    NSString *price = [@"$" stringByAppendingString:[self.listingDictionary objectForKey:@"price"]];
    NSString *subject = [price stringByAppendingString:[@" " stringByAppendingString:[self.listingDictionary objectForKey:@"title"]]];
    shareText = [shareText stringByAppendingString:[subject stringByAppendingString:@"\n"]];
    NSURL *myWebsite = [NSURL URLWithString:[self.listingDictionary objectForKey:@"url"]];
    NSArray *objectsToShare = @[shareText, myWebsite];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    
    activityViewController.excludedActivityTypes = excludeActivities;
    [activityViewController setValue:subject forKey:@"subject"];
    
    [self.window.rootViewController presentViewController:activityViewController animated:YES completion:nil];
    
}

- (IBAction)mapsButton:(id)sender {
    
    NSLog(@"%@",@"Open Maps");
 
 if ([[UIApplication sharedApplication] canOpenURL:
 [NSURL URLWithString:@"comgooglemaps://"]]) {
 [[UIApplication sharedApplication] openURL:
 [NSURL URLWithString:@"comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic"]];
 } else {
 NSLog(@"Can't use comgooglemaps://");
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
