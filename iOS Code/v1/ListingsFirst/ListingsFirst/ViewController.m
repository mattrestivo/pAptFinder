//
//  ViewController.m
//  ListingsFirst
//
//  Created by Matt Restivo on 7/23/15.
//  Copyright (c) 2015 Matt Restivo. All rights reserved.
//

#import "ViewController.h"
#import "ListingsTableView.h"
#import "LCard.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+WebCache.h"

@interface ViewController ()

@property (strong, nonatomic) NSArray *listings;
@property (assign, nonatomic) CATransform3D initialTransformation;
@property (nonatomic, strong) NSMutableSet *shownIndexes;


@end

@implementation ViewController{
    UITableView *mainTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars=NO;
        self.automaticallyAdjustsScrollViewInsets=NO;
    }*/
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableViewData) name:@"ReloadAppDelegateTable" object:nil];
    
    // retreive current user session from parse.
    NSString *sessionToken = [PFUser currentUser].sessionToken;
    //NSLog(@"User Session Token: %@",sessionToken);
    
    // ensure that we map the user's installation to their PFUser ObjectID as a channel for sending push notifications.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSLog(@"this-> %@",[@"a_" stringByAppendingString:[PFUser currentUser].objectId]);
    [currentInstallation addUniqueObject:[@"a_" stringByAppendingString:[PFUser currentUser].objectId] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
    // put entire view into loading state here?
    
    // now what we actually want to do is retreive the user's listings
    PFQuery *userInquiryListingsQuery = [PFQuery queryWithClassName:@"UserInquiryListing"];
    [userInquiryListingsQuery whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    [userInquiryListingsQuery orderByDescending:@"created"];
    [userInquiryListingsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        //NSLog(@"%@", objects);
        self.listings = objects;
        
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height;
        CGRect tableFrame = CGRectMake(x, y, width, height);
        
        mainTableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
        mainTableView.delegate = self;
        mainTableView.dataSource = self;
        [self.view addSubview:mainTableView];
        
    }];
    
    // if they have listings, let's build a tableview of their listings.
    if ( self.listings ){
        // do something
        NSLog(@"%s","Do they have listings?");
        NSLog(@"%@",self.listings);
    }
    
    CGFloat rotationAngleDegrees = -15;
    CGFloat rotationAngleRadians = rotationAngleDegrees * (M_PI/180);
    CGPoint offsetPositioning = CGPointMake(-20, -20);
    
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DRotate(transform, rotationAngleRadians, 0.0, 0.0, 1.0);
    transform = CATransform3DTranslate(transform, offsetPositioning.x, offsetPositioning.y, 0.0);
    _initialTransformation = transform;
    _shownIndexes = [NSMutableSet set];
    
    // if they don't have listings, let's tell them they don't have them and show them a button to go to the edit webview.
//    [self.view addSubview:listingsView];
    
//    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
//    [self.view addSubview:newTableViewController];
    
    // now pop a webview into the view
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(_userInquirySettings:)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)reloadTableViewData{
    [mainTableView reloadData];
}

- (IBAction)_userInquirySettings:(id)sender {
    // create a webview, just in case we're deeplinking.
    CGRect webFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    UIWebView *webView = [[UIWebView alloc] initWithFrame:webFrame];
    [webView setBackgroundColor:[UIColor clearColor]];
    
    NSString *sessionToken = [PFUser currentUser].sessionToken;
    NSString *urlAddress = [NSString stringWithFormat: @"http://mattrestivo.com/tml/select.php?user_session=%@",sessionToken];
    NSURL *url = [NSURL URLWithString:urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObj];
    [webView setBackgroundColor:[UIColor whiteColor]];
    
    UIViewController *detailViewController = [[UIViewController alloc] init];
    [detailViewController.view addSubview:webView];
    [self.navigationController pushViewController:detailViewController animated:YES];
    
}

- (void)_loadData {
    
    // removed the profile data update to the view here.

    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        // handle response
        if (!error) {
            // Parse the data received
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            
            NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:7];
            
            if (facebookID) {
                userProfile[@"facebookId"] = facebookID;
            }
            
            NSString *name = userData[@"name"];
            if (name) {
                userProfile[@"name"] = name;
            }
            
            NSString *email = userData[@"email"];
            
            userProfile[@"pictureURL"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID];
            
            [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
            if ( email ){
                [[PFUser currentUser] setObject:email forKey:@"email"];
                [[PFUser currentUser] setObject:@YES forKey:@"enabled"];
            }
            [[PFUser currentUser] saveInBackground];
            
            // removed additional profile data update.
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
            [self logoutButtonAction:nil];
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

- (void)logoutButtonAction:(id)sender {
    // @todo-- display a dialouge here first
    
    // Logout user, this automatically clears the cache
    [PFUser logOut];
    
    // Return to login view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.listings count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10];
     NSString *newlineString = @"\n";
     NSString *newAboutText = [aboutText stringByReplacingOccurrencesOfString:@"\\n" withString:newlineString];*/
    //CGSize aboutSize = [newAboutText sizeWithFont:font constrainedToSize:CGSizeMake(268, 4000)];
    
    return 270;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellIdentifier = @"LCard";
    LCard *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = (LCard *)[nib objectAtIndex:0];
    }

    [cell setupWithDictionary:[self.listings objectAtIndex:indexPath.row]];
    
    return cell;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    NSString *url = [self.listings objectAtIndex:indexPath.row][@"url"];
    NSString *title = [self.listings objectAtIndex:indexPath.row][@"url"];
     
    UIViewController *detailViewController = [[UIViewController alloc] init];
    CGRect webFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height); // @todo - this is wrong, fix it. it should be based on the view in the UIViewController.
    UIWebView *webView = [[UIWebView alloc] initWithFrame:webFrame];
    NSURL *openUrl = [NSURL URLWithString:url];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:openUrl];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
    [webView loadRequest:requestObj];
    [webView setBackgroundColor:[UIColor whiteColor]];
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(_showActionSheet:)];
    detailViewController.navigationItem.rightBarButtonItem = anotherButton;
    
    [detailViewController.view addSubview:webView];
    
}

- (IBAction)_showActionSheet:(id)sender {
    // create a webview, just in case we're deeplinking.
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete"
                                                    otherButtonTitles:@"Share", @"Google Maps", nil];
    actionSheet.tag = 1;
    actionSheet.accessibilityValue = @"-";
    [actionSheet showInView:self.view];

}

- (IBAction)showDeleteConfirmation:(id)sender {
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (actionSheet.tag == 1) {
        if ( buttonIndex == 0) {
            
            // delete!
/*            NSIndexPath *indexPath = [mainTableView indexPathForCell:(UITableViewCell *)];
            NSLog(@"current row -> %d",indexPath.row);
*/
            
/*          
            NSIndexPath *indexPath = [rootViewControler .mainTableView indexPathForCell:(UITableViewCell *)];
            NSObject *listingObject = [self.listings objectAtIndex:indexPath.row];
            NSLog(@"%@",listingObject);
            
            UIActionSheet *secondActionSheet = [[UIActionSheet alloc] initWithTitle:@"Do you really want to delete this listing?"
                                                                     delegate:self
                                                            cancelButtonTitle:@"No, I changed my mind"
                                                       destructiveButtonTitle:@"Yes"
                                                            otherButtonTitles:nil];

            [secondActionSheet showInView:self.view];
*/
            
        } else if ( buttonIndex == 1 ){
            // do share stuff again here.
            
        } else if ( buttonIndex == 2 ){

            NSLog(@"%@",@"Open Maps");
            
            if ([[UIApplication sharedApplication] canOpenURL:
                 [NSURL URLWithString:@"comgooglemaps://"]]) {
                [[UIApplication sharedApplication] openURL:
                 [NSURL URLWithString:@"comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic"]];
            } else {
                NSLog(@"Can't use comgooglemaps://");
            }

        }
    }
    else if (actionSheet.tag == 2){
        // run your parse delete stuff here.
    }
    
    NSLog(self);
    NSLog(@"Index = %d - Title = %@", buttonIndex, [actionSheet buttonTitleAtIndex:buttonIndex]);
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.shownIndexes containsObject:indexPath]) {
        [self.shownIndexes addObject:indexPath];
        
        UIView *card = [(LCard* )cell mainView];
        
        card.layer.transform = self.initialTransformation;
        card.layer.opacity = 0.5;
        
        [UIView animateWithDuration:0.9 animations:^{
            card.layer.transform = CATransform3DIdentity;
            card.layer.opacity = 1;
        }];
    }
}
@end
