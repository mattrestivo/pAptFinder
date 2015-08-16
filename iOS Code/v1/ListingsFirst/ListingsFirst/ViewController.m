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
//#import "Card.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface ViewController ()

@property (strong, nonatomic) NSArray *listings;

@end

@implementation ViewController{
    UITableView *mainTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // retreive current user session from parse.
    NSString *sessionToken = [PFUser currentUser].sessionToken;
    NSLog(@"User Session Token: %@",sessionToken);
    
    // ensure that we map the user's installation to their PFUser ObjectID as a channel for sending push notifications.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[PFUser currentUser].objectId forKey:@"channels"];
    [currentInstallation saveInBackground];
    
    // put entire view into loading state here?
    
    // now what we actually want to do is retreive the user's listings
    PFQuery *userInquiryListingsQuery = [PFQuery queryWithClassName:@"UserInquiryListing"];
    [userInquiryListingsQuery whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    [userInquiryListingsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        //NSLog(@"%@", objects);
        self.listings = objects;
        
        CGFloat x = 0;
        CGFloat y = 64;
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height - 50;
        CGRect tableFrame = CGRectMake(x, y, width, height);
        
        mainTableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
        mainTableView.delegate = self;
        mainTableView.dataSource = self;
        //mainTableView.backgroundColor = [UIColor cyanColor];
        [self.view addSubview:mainTableView];
        
    }];
    
    // if they have listings, let's build a tableview of their listings.
    if ( self.listings ){
        // do something
        NSLog(@"%s","Do they have listings?");
        NSLog(@"%@",self.listings);
    }
    
    
    // if they don't have listings, let's tell them they don't have them and show them a button to go to the edit webview.
//    [self.view addSubview:listingsView];
    
//    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
//    [self.view addSubview:newTableViewController];
    
    // now pop a webview into the view
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(_userInquirySettings:)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
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
    
    return 230;
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
    /*
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Open URL"
                                                                   message:url
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    */
     
    UIViewController *detailViewController = [[UIViewController alloc] init];
    CGRect webFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height); // @todo - this is wrong, fix it. it should be based on the view in the UIViewController.
    UIWebView *webView = [[UIWebView alloc] initWithFrame:webFrame];
    NSURL *openUrl = [NSURL URLWithString:url];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:openUrl];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
    [webView loadRequest:requestObj];
    [webView setBackgroundColor:[UIColor whiteColor]];
    [detailViewController.view addSubview:webView];
    
    
    // CoverVertical
    /*[self.window.rootViewController.view.window.layer addAnimation:transition forKey:kCATransition];
    [self presentViewController:adjustViewController animated:NO completion:nil];
    
    [self.window.rootViewController.view addSubview:webView];
    self.window.backgroundColor = [UIColor whiteColor];

    
    Navigation logic may go here. Create and push another view controller.
    
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] init];
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
    */
    
}





@end
