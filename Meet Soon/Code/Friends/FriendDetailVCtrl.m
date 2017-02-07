//
//  FriendDetailVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#define CELL_TAG_EVENTNAME 11
#define CELL_TAG_STARTTIME 12
#define CELL_TAG_LOCATION 13

#import "FriendDetailVCtrl.h"
#import "FriendsListVCtrl.h"
#import "FriendsListDCtrl.h"
#import "DataFetchUtil.h"
#import "FriendData.h"
#import "EventHistoryListDCtrl.h"
#import "FileOperationUtils.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuNetWorkClient.h"
#import "Utils.h"
#import "EventHistory.h"
#import "ConvertUtil.h"
#import "WeiJuManagedObjectContext.h"




@implementation FriendDetailVCtrl

#define ADDRBOOK_NAME_TAG 2
#define LOGIN_USER_NAME_TAG 3
#define LOGIN_EMAIL_TAG 4
#define TABLE_VIEW_TAG 18
#define CLEAR_HIST_BTN_TAG 18


@synthesize personImageView;

@synthesize friend=_friend;

@synthesize tableView=_tableView;
@synthesize eventHistoryVCtrlCell = _eventHistoryVCtrlCell;
@synthesize swipeGestureRecognizerRight;
@synthesize swipeGestureRecognizerLeft;
@synthesize eventHistoryListDCtrl;
@synthesize isBeingDisplayed=_isBeingDisplayed;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil friendData:(FriendData *)friendData
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.friend = friendData;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.eventHistoryListDCtrl == nil) {
        self.eventHistoryListDCtrl = [[EventHistoryListDCtrl alloc] init];
       [self.eventHistoryListDCtrl startFetcher:self.friend.userEmails];
    }
    
    self.swipeGestureRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.swipeGestureRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    
    self.swipeGestureRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    self.swipeGestureRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    
    self.swipeGestureRecognizerLeft.numberOfTouchesRequired = 1;
    self.swipeGestureRecognizerRight.numberOfTouchesRequired = 1;
    /*
    [self.view addGestureRecognizer:self.swipeGestureRecognizerRight];
    [self.view addGestureRecognizer:self.swipeGestureRecognizerLeft];
    */
	/*
    //add to phone contants btn
    UIButton *btn = (UIButton *)[self.view viewWithTag:4];
    [btn addTarget:self action:@selector(addToPhoneContants) forControlEvents:UIControlEventTouchUpInside];
	[Utils initCustomGradientButton:btn title:nil image:nil gradientStart:[UIColor greenColor] gradientEnd:[UIColor grayColor] cornerRadius:10 borderWidth:0];
    btn.hidden = YES;
    
	//the reminder button
	btn = (UIButton *)[self.view viewWithTag:5];
    [btn addTarget:self action:@selector(remind) forControlEvents:UIControlEventTouchUpInside];
	[Utils initCustomGradientButton:btn title:nil image:nil gradientStart:[UIColor greenColor] gradientEnd:[UIColor grayColor] cornerRadius:10 borderWidth:0];
	 */
	self.title = self.friend.abRecordName;
	
	//UILabel *label1 = (UILabel *)[self.view viewWithTag:ADDRBOOK_NAME_TAG];
	UILabel *label2 = (UILabel *)[self.view viewWithTag:LOGIN_USER_NAME_TAG];
	UILabel *label3 = (UILabel *)[self.view viewWithTag:LOGIN_EMAIL_TAG];

	//label1.text = [@"Full Name: " stringByAppendingString:self.friend.abRecordName];
	label2.text = self.friend.userName;
	label3.text = self.friend.userLogin;
	
	//UIImageView *imageView = (UIImageView *)[self.view viewWithTag:10];
    
    self.personImageView.layer.masksToBounds=YES;
    self.personImageView.layer.cornerRadius=5.0; 
    self.personImageView.layer.borderWidth=1.0; 
    self.personImageView.layer.borderColor=[[UIColor lightGrayColor] CGColor];
    
	[self updateImageView];
//    if(self.friend.userImageFileData != nil){
//        self.personImageView.image = [UIImage imageWithData:self.friend.userImageFileData]; //[[[Utils alloc] init] rotateImage:[UIImage imageWithData:self.friend.userImageFileData] orient:UIImageOrientationRight];
//    }else{
//        self.personImageView.image = [UIImage imageNamed:@"person_list_none.png"];      
//    }
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
	[self.personImageView addGestureRecognizer:tap];
    // Do any additional setup after loading the view from its nib.
	
	[self.view viewWithTag:TABLE_VIEW_TAG].layer.borderWidth=1.0;
	[self.view viewWithTag:TABLE_VIEW_TAG].layer.cornerRadius=4.0;
		
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteFriend)];
}

- (void)viewDidUnload
{
    
    [self setTableView:nil];
    [self setEventHistoryVCtrlCell:nil];
    [self setPersonImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
	[Utils hideTabBar:YES For:self.tabBarController];
	[Utils hideNavToolBar:YES For:self.navigationController];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.isBeingDisplayed = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.isBeingDisplayed = NO;

    [DataFetchUtil saveButtonsEventRecord:@"24"];
    [super viewWillDisappear:animated];
}



-(void) handleSwipes:(UISwipeGestureRecognizer *)paramSender{
    if (paramSender.direction & UISwipeGestureRecognizerDirectionDown) {
        //NSLog(@"down");
    }else if(paramSender.direction & UISwipeGestureRecognizerDirectionUp){
        //NSLog(@"up");
    }else if(paramSender.direction & UISwipeGestureRecognizerDirectionLeft){
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"28"];
    }else if(paramSender.direction & UISwipeGestureRecognizerDirectionRight){
        [DataFetchUtil saveButtonsEventRecord:@"29"];
    }
}

//-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    //added Button click Event
//    [DataFetchUtil saveButtonsEventRecord:@"27"];
//   
//}

- (void)addToPhoneContants
{
    
}
- (void)invite
{
//	if([[WeiJuAppPrefs getSharedInstance] demo])
//		[self.navigationController pushViewController:[[ChatVCtrl alloc] initDemoWithNibName:@"ChatVCtrl" bundle:nil newWeiJu:0 startView:START_WITH_BUBBLE center:CLLocationCoordinate2DMake(0, 0) latDistance:0 longDistance:0 crumbs:nil annotations:nil] animated:YES];
//	else {
//		[self.navigationController pushViewController:[[ChatVCtrl alloc] initWithNibName:@"ChatVCtrl" bundle:nil weiJuData:nil] animated:YES];
//	}
	/*
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:@"" forKey:self.friend.userId];
    [dictionary setObject:@"" forKey:[[WeiJuAppDelegate getSharedInstance].appPrefs userId]];
    ChatViewCtrl *chatViewController = [[ChatViewCtrl alloc] initWithNibName:@"ChatViewCtrl" weiJuData:nil inviteUserDictionary:dictionary];
    [[WeiJuAppDelegate getSharedInstance].tabBarCtrl setSelectedIndex:0];
    [[[[WeiJuAppDelegate getSharedInstance].tabBarCtrl viewControllers] objectAtIndex:1] popToViewController:[FriendsListVCtrl getSharedInstance]  animated:YES];
    [[[[WeiJuAppDelegate getSharedInstance].tabBarCtrl viewControllers] objectAtIndex:0] pushViewController:chatViewController animated:YES];
	 */
}
/*
- (void)deleteFriend 
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Do you need to delete this user?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Yes",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        self.friend.hide = @"1";
        [WeiJuManagedObjectContext quickSave];
        [[FriendsListVCtrl getSharedInstance].friendsListDCtrl startSearch];
        [[FriendsListVCtrl getSharedInstance].tableView reloadData];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
*/
- (void) updateImageView
{
	if(self.friend.userImageFileData != nil){
        self.personImageView.image = [UIImage imageWithData:self.friend.userImageFileData]; //[[[Utils alloc] init] rotateImage:[UIImage imageWithData:self.friend.userImageFileData] orient:UIImageOrientationRight];
    }else{
        self.personImageView.image = [UIImage imageNamed:@"person_list_none.png"];
    }
}

-(void) imageViewTapped:(id) tap
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"How to add/change image" message:@"Go to iPhone's built-in \"Contact\" app and edit his/her image there; re-launch this app, enter this contact screen again, you'll see his/her updated image." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alert show];
}

//清楚所有的历史
- (IBAction)clearHistory:(id)sender 
{
    [DataFetchUtil saveButtonsEventRecord:@"25"];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm to clear all history?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes",nil];
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
		NSString *emailsSearchStr = [[[self.friend.userEmails stringByReplacingOccurrencesOfString:@")(" withString:@"','"] stringByReplacingOccurrencesOfString:@"(" withString:@"'"] stringByReplacingOccurrencesOfString:@")" withString:@"'"];
		
		NSArray *allEvent = [[[DataFetchUtil alloc] init] searchObjectArray:@"EventHistory" filterString:[@"email in" stringByAppendingFormat:@"{%@}",emailsSearchStr]];
		for (int i=0; i < [allEvent count]; i++) {
			((EventHistory *)[allEvent objectAtIndex:i]).isClientDeleted = @"1";
		}
		[self.eventHistoryListDCtrl startFetcher:self.friend.userEmails];
		self.friend.lastMeetingDate = nil;
		self.friend.lastMeetingLocation = nil;
		[self.tableView reloadData];
		[[FriendsListVCtrl getSharedInstance].tableView reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.eventHistoryListDCtrl numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"eventHistoryListVCell";
    	
	UILabel *eventName;
	UILabel *startTime;
    UILabel *location;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) 
	{
        [[NSBundle mainBundle] loadNibNamed:@"EventHistoryListVCell" owner:self options:nil];
        cell = self.eventHistoryVCtrlCell;
		self.eventHistoryVCtrlCell = nil;
    }
    
	eventName = (UILabel *)[cell viewWithTag:CELL_TAG_EVENTNAME];
	startTime = (UILabel *)[cell viewWithTag:CELL_TAG_STARTTIME];
    location = (UILabel *)[cell viewWithTag:CELL_TAG_LOCATION];
	
    EventHistory *eventHistory = (EventHistory *)[self.eventHistoryListDCtrl objectInListAtIndex:indexPath];
    eventName.text = eventHistory.title;
    location.text = eventHistory.location;
    startTime.text = [[ConvertUtil convertDateToString:eventHistory.startTime dateFormat:@"YYYY-MM-dd"] stringByAppendingFormat:@"\n%@ %@",[Utils getHourMinutes:eventHistory.startTime],[Utils getAMPM:eventHistory.startTime]];
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [DataFetchUtil saveButtonsEventRecord:@"26"];
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @"Event Title              Start Time";	
}




@end
