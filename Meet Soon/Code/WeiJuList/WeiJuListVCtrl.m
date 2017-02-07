//
//  WeiJuListVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuListVCtrl.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "FirstLoginVCtrl.h"
#import "WeiJuCell.h"
#import "WeiJuListDCtrl.h"
#import "WeiJuData.h"
#import "ChatDCtrl.h"
#import "WeiJuMessage.h"
#import "FriendsListVCtrl.h"
#import "FriendData.h"
#import "Location.h"
#import "Utils.h"
#import "WeiJuNetWorkClient.h"
#import "FileOperationUtils.h"
#import "DataFetchUtil.h"
#import "WeiJuManagedObjectContext.h"
#import "Character.h"
#import "ConvertData.h"
#import "FriendsListDCtrl.h"

#import "FriendFavoriteLocation.h"
#import "MessageTemplate.h"

#import "CalendarMonthVCtrl.h"
#import "CalendarMonthLogic.h"
#import "CalEventVCtrl.h"
#import "CrumbPath.h"
#import "BridgeAnnotation.h"

#import "WeiJuPathShareVCtrl.h"
#import "MapVCtrl.h"

#import "WEPopoverController.h"
#import "PopOverTexiViewReminder.h"

#import "QLogViewer.h"

#import "SettingsVCtrl.h"

#import "OperationQueue.h"
#import "OperationTask.h"
#import "MBProgressHUD.h" 
#import "QLog.h"

@interface WeiJuListVCtrl ()

@end

@implementation WeiJuListVCtrl

#define DEMO_TOPVIEW_TAG 31
#define DEMO_BOTVIEW_TAG 32
#define DEMO_FINGERIMG_TAG 33

@synthesize firstLaunch, demoMode;

@synthesize dayMonth=_dayMonth;

@synthesize tableView = _tableView;
@synthesize backgroundView=_backgroundView;
@synthesize messageView=_messageView, currentVCtrl;
@synthesize popoverCtrl, popoverReminder;
@synthesize currentSelectedSharingCell;
@synthesize notifBtn=_notifBtn;
@synthesize calMouthVCtrl=_calMouthVCtrl;
@synthesize weiJuListDCtrl=_weiJuListDCtrl,friendsListDCtrl=_friendsListDCtrl, chatDCtrl=_chatDCtrl, currentWeiJuPathShareVCtrl = _currentWeiJuPathShareVCtrl;
@synthesize weiJuPathShareVCtrls;
@synthesize checkEventQ=_checkEventQ;

static WeiJuListVCtrl *sharedInstance;
static NSString *listMonthStatus = @"list";

+ (WeiJuListVCtrl *) getSharedInstance
{
    return sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil demoOrNot:(BOOL)demo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        sharedInstance=self;
        // Custom initialization
		self.weiJuPathShareVCtrls = [[NSMutableDictionary alloc] init];
		self.firstLaunch=YES;
		self.demoMode=demo;
		self.checkEventQ=[[NSOperationQueue alloc] init];
		
		if (self.demoMode == NO)
		{
			self.weiJuListDCtrl = [WeiJuListDCtrl getSharedInstance];//force the use of a new dctrl, since we might come back from logout and log in using a new account
			self.friendsListDCtrl = [FriendsListDCtrl getSharedInstance]; //start the startFetcher to monitor change
            self.chatDCtrl = [ChatDCtrl getSharedInstance];
		}

    }
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view from its nib.
    if (self != nil) 
    {
        if (self.demoMode == NO) 
		{
			/* //move it to init
			self.weiJuListDCtrl = [WeiJuListDCtrl getSharedInstance];//force the use of a new dctrl, since we might come back from logout and log in using a new account
			self.friendsListDCtrl = [FriendsListDCtrl getSharedInstance]; //start the startFetcher to monitor change
            self.chatDCtrl = [ChatDCtrl getSharedInstance];
			*/
			self.title = NSLocalizedString(@"WEIJULIST_TITLE", nil);
        }
		else 
		{
			self.title = @"Meet Soon Demo";
			
			self.tableView.scrollEnabled=NO;
			
			//create a shadown view to cover up the whole screen to prevent tapping
			UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 150)];
			topView.backgroundColor = [UIColor blackColor];
			topView.alpha=0.5;
			topView.tag=DEMO_TOPVIEW_TAG;
			[self.view addSubview:topView];
			
			UIView *botView = [self.navigationController.view viewWithTag:DEMO_BOTVIEW_TAG];
			if(botView==nil) //don't keep creating the view when user go back and forth
			{
				botView = [[UIView alloc] initWithFrame:CGRectMake(0, 266, 320, 220)];
				botView.backgroundColor = [UIColor blackColor];
				botView.alpha=0.5;
				botView.tag=DEMO_BOTVIEW_TAG;
				
//				UILabel *tagL = [[UILabel alloc] initWithFrame:CGRectMake(80, 20, 160, 33)];
//				tagL.layer.cornerRadius=4.0;
//				tagL.alpha=1.0;
//				tagL.text=@"Fully integrated with your calendar";
//				tagL.font = [UIFont boldSystemFontOfSize:16];
//				tagL.textColor = [UIColor yellowColor];
//				//tagL.backgroundColor = [UIColor clearColor];
//				[botView addSubview:tagL];
				
				[self.navigationController.view addSubview:botView];
			}
			
			//create the finger animation
			int numberOfFames = 3;
			NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:numberOfFames];
			for (int i=1; numberOfFames >= i; ++i)
			{
				[imagesArray addObject:[UIImage imageNamed:
										[NSString stringWithFormat:@"click-%d.png", i]]];
			}
			
			UIImageView *clickImage = [[UIImageView alloc] initWithFrame:CGRectMake(320-30, 150-42, 25, 42)];
			clickImage.animationImages = imagesArray;
			clickImage.animationDuration = 1;
			clickImage.tag=DEMO_FINGERIMG_TAG;
			clickImage.userInteractionEnabled=YES; //to receive taps!
			[self.view addSubview:clickImage];
			
			[clickImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFingerImage:)]];
			
		}
		
		//self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
		//self.navigationController.toolbar.barStyle=UIBarStyleBlack;
		
		if (self.demoMode == NO) 
		{
			//set up the network error msg view
			UIButton *closeMsgViewBtn = (UIButton *)[self.messageView viewWithTag:10];
			[closeMsgViewBtn setImage:[UIImage imageNamed:@"cancel-icon-red.png"] forState:UIControlStateNormal];
			[closeMsgViewBtn addTarget:self action:@selector(dismissNetworkMessageView) forControlEvents:UIControlEventTouchUpInside];
			
			[self setUpNavBar];
		}
		
		[self setUpToolBar];
	}
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewDidUnload
{
	self.dayMonth=nil;
	
    [self setTableView:nil];
	self.backgroundView=nil;
	
	[self.weiJuListDCtrl releaseResource];
    self.weiJuListDCtrl=nil;

    self.friendsListDCtrl=nil;

	self.chatDCtrl=nil;
	self.currentWeiJuPathShareVCtrl=nil;
	
	if(self.weiJuPathShareVCtrls!=nil)
	{
		NSArray *pvcArray = [self.weiJuPathShareVCtrls allValues];
		for (WeiJuPathShareVCtrl *pvc in pvcArray) {
			if(pvc.hasBeenShutdown==NO)
				[pvc shutDown:2];
		}
		pvcArray = nil;
		[self.weiJuPathShareVCtrls removeAllObjects];
		self.weiJuPathShareVCtrls=nil;
	}
	
	self.currentSelectedSharingCell=nil;

	self.popoverCtrl=nil;
	self.popoverReminder = nil;
	
    [self setMessageView:nil];
	self.currentVCtrl=nil;
	self.firstLaunch=NO;
	
	[self.checkEventQ cancelAllOperations];
	self.checkEventQ=nil;
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[Utils log:@"%s [line:%d]: viewDidUnload",__FUNCTION__,__LINE__];
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
		[Utils displaySmartAlertWithTitle:@"WJLVC unload" message:nil noLocalNotif:YES];
}

/*
- (void) didReceiveMemoryWarning
{
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=3) //PRODUCTION_MODE
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"WJLVC didReceiveMemoryWarning" 
														message:nil
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
	}
	[super didReceiveMemoryWarning];
}
*/

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
	self.navigationController.navigationBar.barStyle = UIBarStyleDefault;// UIBarStyleBlack;
	self.navigationController.toolbar.barStyle=UIBarStyleDefault; //UIBarStyleBlack;
	self.navigationController.toolbar.translucent=NO;
	
	[Utils hideNavToolBar:NO For:self.navigationController];
	
	if(self.demoMode==NO)
	{
		//check the calendar and reload table if date/events have changed
		if([self.weiJuListDCtrl dateHasChanged])
		{
			[WeiJuNetWorkClient setSearchVersionEnabled:true]; //hopefully, this will force checking new version daily
			
			[self.tableView reloadData]; //force reload since cells might not have moved hence tableview won't reload
			
			//[self.weiJuPathShareVCtrls removeAllObjects]; //purge the dict since it is a new day: should have been done in [self.weiJuListDCtrl dateHasChanged], calling [self todayEventHasBeenDeleted]
			
			[[Utils getSharedInstance] alertNewVerson:YES alertProtocolVersion:NO];
			
			[[QLog log] clear];
		}
		
		//might need to move this ahead of dateHasChanged
		[[WeiJuListVCtrl getSharedInstance].weiJuListDCtrl checkIfCalendarHasChanged];//will result in notification
		
		if([WeiJuNetWorkClient getNetWorkEnabled]==NO)
			[self displayNetworkMessageView];
		else
			[self dismissNetworkMessageView];
	}
	else {
		self.navigationController.navigationBarHidden=NO; //loginview has the bar hidden
		[self.navigationController.view viewWithTag:DEMO_BOTVIEW_TAG].hidden=NO;
		[self.navigationController.view bringSubviewToFront:[self.navigationController.view viewWithTag:DEMO_BOTVIEW_TAG] ];//otherwise, the view will be put under the toolbar
		
		//prep for animation in viewdidappear
		[self.view viewWithTag:DEMO_TOPVIEW_TAG].frame=CGRectMake(0, -150, 320, 150);
		[self.navigationController.view viewWithTag:DEMO_BOTVIEW_TAG].frame=CGRectMake(0, 266+220, 320, 220);
		[self.view viewWithTag:DEMO_FINGERIMG_TAG].hidden=YES;

	}
}

- (void) displayNetworkMessageView
{
	if (self.demoMode == YES)
		return;
	
	if([self.messageView superview]==nil)
	{
		[self.view addSubview:self.messageView];
		[Utils shiftView:self.tableView changeInX:0 changeInY:self.messageView.frame.size.height changeInWidth:0 changeInHeight:-self.messageView.frame.size.height];
	}
}

- (void) dismissNetworkMessageView
{
	if (self.demoMode == YES)
		return;

	if([self.messageView superview]!=nil)
	{
		[self.messageView removeFromSuperview];
		[Utils shiftView:self.tableView changeInX:0 changeInY:-self.messageView.frame.size.height changeInWidth:0 changeInHeight:self.messageView.frame.size.height];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

	if(self.demoMode==NO)
	{
		if(self.firstLaunch)
		{
			//scroll to display today's first event
			if(self.weiJuListDCtrl.hasLoadedEvents)  
			{
				//if([[WeiJuAppDelegate getSharedInstance].eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]==NO) //tableview'cells may still be empty yet in ios6 since the dctrl might have not started call reloadData yet
					[self gotoToday];
				if(self.weiJuListDCtrl.hasServerBasedCalendar==NO)
					[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_SERVER_CAL_TITLE", nil) message:NSLocalizedString(@"NO_SERVER_CAL_MSG", nil) noLocalNotif:YES];
			}
			
			self.firstLaunch = NO;
			
			[[Utils getSharedInstance] alertNewVerson:YES alertProtocolVersion:NO];
		}
		
		self.currentVCtrl=self;
		
		if(self.weiJuListDCtrl.hasLoadedEvents)
		{
			//if(self.weiJuListDCtrl.hasServerBasedCalendar==NO)
			//	[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_SERVER_CAL_TITLE", nil) message:NSLocalizedString(@"NO_SERVER_CAL_MSG", nil) noLocalNotif:YES];
			//else
				[self.weiJuListDCtrl checkIfCalendarHasChanged]; //refreshSourcesIfNecessary
		}
		
		//[Utils displaySmartAlertWithTitle:@"Test1" message:@"Test2" noLocalNotif:NO];
	}
	else {
		//demo mode - do the animation
		[UIView transitionWithView:self.view duration:1 options:UIViewAnimationOptionCurveLinear animations:^{
			[self.view viewWithTag:DEMO_TOPVIEW_TAG].frame=CGRectMake(0, 0, 320, 150);
		} completion:^(BOOL finished) {
			
		}]; 
		
		[UIView transitionWithView:self.navigationController.view duration:1 options:UIViewAnimationOptionCurveLinear animations:^{
			[self.navigationController.view viewWithTag:DEMO_BOTVIEW_TAG].frame=CGRectMake(0, 266, 320, 220);
		} completion:^(BOOL finished) {
			[self.view viewWithTag:DEMO_FINGERIMG_TAG].hidden=NO;
			[(UIImageView *)[self.view viewWithTag:DEMO_FINGERIMG_TAG] startAnimating];
		} ];

	}
	
	/* //勿删除
	MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
	overlay.animation = MTStatusBarOverlayAnimationFallDown;  // MTStatusBarOverlayAnimationShrink
	overlay.detailViewMode = MTDetailViewModeHistory;         // enable automatic history-tracking and show in detail-view
	overlay.historyEnabled = YES;
	overlay.hidesActivity = YES; //dont display the activity icon on the left side
	overlay.delegate = self;
	overlay.progress = 0.0;
	[overlay postMessage:@"Following @myell0w on Twitter…"];
	overlay.progress = 0.1;
	// ...
	[overlay postMessage:@"uploadSelfEmailsCallBack: succeed" animated:YES];
	overlay.progress = 0.8;
	*/
	
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	
	[Utils hideNavToolBar:YES For:self.navigationController];
	//self.navigationController.navigationBar.barStyle=UIBarStyleDefault;
	
	if(self.demoMode==YES)
	{
		[self.navigationController.view  viewWithTag:DEMO_BOTVIEW_TAG].hidden=YES;
		//[self.navigationController.view sendSubviewToBack:[self.navigationController.view  viewWithTag:999] ];//sometimes, the view remain in place, covering the login buttons
		[(UIImageView *)[self.view viewWithTag:DEMO_FINGERIMG_TAG] stopAnimating];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	self.currentVCtrl=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) eventDataBaseChanged
{
	[self.checkEventQ cancelAllOperations];
	//refresh the table display: put it on mainthread, to ensure execution right away
	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void) todayEventHasChanged:(EKEvent *)event //event participants might have changed -> need to set up again
{
	WeiJuPathShareVCtrl *pvc= [self.weiJuPathShareVCtrls valueForKey:[[event.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] ];
	if (pvc!=nil && pvc.hasBeenShutdown==NO)
	{
		pvc.selfEvent=event;
		[pvc setUpParticipants:[NSNumber numberWithInt:1]]; //executed on main thread since the listdctrl eventchange notif was called on main thread, hence no need to do the following
		//[pvc performSelectorOnMainThread:@selector(setUpParticipants:) withObject:[NSNumber numberWithInt:1] waitUntilDone:YES];//YES
	}
}

- (void) todayEventHasBeenDeleted:(EKEvent *)event 
{
	WeiJuPathShareVCtrl *pvc= [self.weiJuPathShareVCtrls valueForKey:[[event.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] ];
	if (pvc!=nil && pvc.hasBeenShutdown==NO)
	{
		if(pvc.isBeingDisplayed)
			[pvc shutDown:0]; //show alert
		else 
			[pvc shutDown:2]; //show no alert, don;t make switch in screen
		[self.weiJuPathShareVCtrls removeObjectForKey:[[event.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] ];
	}

}

- (void) deletePVC:(WeiJuPathShareVCtrl *)pvc
{
	[self.weiJuPathShareVCtrls removeObjectForKey:[[pvc.selfEvent.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] ];
}

- (void) shutdownAllPVC
{
    NSArray *pvcs = [self.weiJuPathShareVCtrls allValues];
    for (WeiJuPathShareVCtrl *pvc in pvcs) {
        if(pvc.hasBeenShutdown==NO)
			[pvc shutDown:2];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
	if(self.demoMode==NO)
	{
		//NSLog(@"numberOfSections: %d %d", self.weiJuListDCtrl.hasLoadedEvents, [self.weiJuListDCtrl numberOfSections]);
		if(self.weiJuListDCtrl.hasLoadedEvents==NO)
			return 0;
		else
			return [self.weiJuListDCtrl numberOfSections];
	}
	else
		return 3; //yesterday, today and tomorrow
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
	if(self.demoMode==NO)
	{
		if(self.weiJuListDCtrl.hasLoadedEvents==NO)
			return 0;
		else
			return [self.weiJuListDCtrl numberOfRowsInSection:section];
	}
	else {
		int rows=0;
		switch (section) {
			case 0:
				rows=2;
				break;
			case 1:
				rows=2;				
				break;
			case 2:
				rows=1;
				break;
				
			default:
				break;
		}
		return rows;
	}
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

	NSDate *sectionDate;
	if(self.demoMode==NO)
		sectionDate = [self.weiJuListDCtrl dateForSection:section];
	
	[formatter setDateFormat:@"E"];
    NSString *weekday;
	if(self.demoMode==NO)
		weekday = [formatter stringFromDate:sectionDate];
	else 
	{
		switch (section) {
			case 0:
				weekday=@"Mon";
				break;
			case 1:
				weekday=@"Today";				
				break;
			case 2:
				weekday=@"Wed";
				break;
				
			default:
				break;
		}
	}

    if (weekday == nil) {
        return  nil;
    }

	[formatter setDateFormat:@"MMM d yyyy"];
    NSString *date;
	if(self.demoMode==NO)
		date = [formatter stringFromDate:sectionDate];
	else 
	{
		switch (section) {
			case 0:
				date=@"Sep 30 2013";
				break;
			case 1:
				date=@"Oct 1 2013";				
				break;
			case 2:
				date=@"Oct 2 2013";
				break;
				
			default:
				break;
		}
	}
	
    UILabel * label1 = [[UILabel alloc] init];
    label1.frame = CGRectMake(0, 0, 68, 22);
    label1.font=[UIFont fontWithName:@"Helvetica-Bold" size:17];
	label1.textAlignment=UITextAlignmentRight;
    label1.text = weekday;
	label1.shadowOffset=CGSizeMake(0, 1);
    label1.backgroundColor = [UIColor clearColor];
    //label.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CalendarTitleDimColor.png"]];
    UILabel * label2 = [[UILabel alloc] init];
    label2.frame = CGRectMake(160, 0, 120, 22);
    label2.font=[UIFont fontWithName:@"Helvetica-Bold" size:17];
	label2.textAlignment=UITextAlignmentRight;
    label2.text = date;
	label2.shadowOffset=CGSizeMake(0, 1);
    label2.backgroundColor = [UIColor clearColor];
	
	if((self.demoMode==NO && section==[self.weiJuListDCtrl todaySectionIndex]) || (self.demoMode==YES && section==1))
	{
		label1.textColor=label2.textColor=[UIColor blueColor];
		label1.shadowColor=label2.shadowColor=[UIColor whiteColor];
	}
	else {
		label1.textColor=label2.textColor=[UIColor whiteColor];
		label1.shadowColor=label2.shadowColor=[UIColor darkGrayColor];
	}

    UIView * sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 22)];
    sectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WeiJuSectionTitleColor.png"]];
	sectionView.alpha=0.9;
	
    [sectionView addSubview:label1];
    [sectionView addSubview:label2];
	
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //不能从tableview get cell，因为这时tableview中的cell还没ready	
	if(self.demoMode==NO && indexPath.section==[self.weiJuListDCtrl todaySectionIndex] && indexPath.row==0)
		return 0; //the first event for today is always a faked event
	else 
		return CAL_DAYVIEW_EVENT_HEIGHT+3; //why 3? 1+1 for margin at top/bottom, 1 for contentview which is always 1 pixel less
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"cellForRowAtIndexPath: %d %d", indexPath.section, indexPath.row);
    static NSString *CellIdentifier = @"WeiJuCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if(((WeiJuCell *)cell).displayMode==CAL_EVENT_MODE_MAP)
		cell = nil; //don't use this one as template, since the map will screw up the non-map cells' content (text is shifted)
  	
    if (cell == nil) {
        cell = (WeiJuCell *)[[WeiJuCell alloc] initWithDelegate:self]; //cell里面的time或location按钮有被按之后的callback
    }
	
	if(self.demoMode==NO)
	{
		//if(self.weiJuListDCtrl.hasLoadedEvents==NO) //not possible, since he number of sections would be zero if events not loaded yet
		//	return nil;
		// Configure the cell...
		EKEvent *event = (EKEvent *)[self.weiJuListDCtrl objectInListAtIndex:indexPath];
		//WeiJuData *weiJuData = [self.weiJuListDCtrl weiJuDataObjectInListAtIndex:indexPath];
		
		if([event isKindOfClass:[EKEvent class]])
		{
			[(WeiJuCell *)cell setSubject:event.title 
									place:event.location 
								startTime:event.startDate];//设置标题时间地点等
			//[(WeiJuCell *)cell setCellColor:event.calendar.CGColor];
			
			if(indexPath.section==[self.weiJuListDCtrl todaySectionIndex])
			{
				WeiJuPathShareVCtrl *pVC = [self.weiJuPathShareVCtrls valueForKey:[[event.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1]];
				
				if(pVC!=nil && pVC.hasBeenShutdown==NO)
				{
					if (pVC.numberOfNewMessage>0) {
						[(WeiJuCell *)cell setBadge:pVC.numberOfNewMessage]; //add the red dot
					}
				}
				
				if (pVC!=nil && pVC.hasBeenShutdown==NO && pVC.numberOfSharings>0) //只要至少有一人分享
					[(WeiJuCell *)cell toggleMapMode:YES center: CLLocationCoordinate2DMake(pVC.centerCoordinate.latitude+3300.0/111000, pVC.centerCoordinate.longitude) latDistance:2000 longDistance:2000 annotation:pVC.mapVCtrl.lastAnnotation ];
				else //if(pVC.hasBeenShutdown==NO): no need, call has nothing to do with pvc's value
					[(WeiJuCell *)cell ensureToShowEventContent];
				//	else //照说没有必要,因为在weijucell里面的prepareforreuse就会把map和动画关闭;但是不这样做的话,有些cell会是blank,tap之后才会显示标题
				//		[(WeiJuCell *)cell toggleMapMode:NO center:CLLocationCoordinate2DMake(-300,-300) latDistance:0 longDistance:0 crumbs:nil annotations:nil];
			}
			
			if(event.status==EKEventStatusCanceled)
			{
				[(WeiJuCell *)cell setStrike:YES];
			}
			else 
			{
				if(indexPath.section>=[self.weiJuListDCtrl todaySectionIndex]) //for future events, 用虚线标示mark the events that i am invited but have not responded
				{	
					/*
					 //an event with thousands of participants (load the .attendees property) will take 5 seconds & block the UI, unless we do multi-threading here; also need to use category to extend ekevent with number of attendees property so that next time there is no need to load .attendees again (unless it is cached)
					 if ([Utils isUnprocessedEvent:event])
					 [(WeiJuCell *)cell setAcceptanceStatusBoundary:NO];
					 */
					//still slowing down the main thread
					
					NSMutableDictionary *withObject = [NSMutableDictionary dictionary];
					[withObject setObject:event forKey:@"event"];
					[withObject setObject:cell forKey:@"cell"];
					NSInvocationOperation *checkTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(checkEventStatus:) object:withObject];
					//[checkTask setQueuePriority:NSOperationQueuePriorityVeryLow];
					//[checkTask setThreadPriority:0.0];
					[self.checkEventQ addOperation:checkTask];
					
					//if([event.title rangeOfString:@"Vaccin"].location!=NSNotFound)
					//	NSLog(@"check for %@ %@",event.title,cell);
					
					//else //no need to do this part, as the prepareforresuse will get rid of the dashes
					//[(WeiJuCell *)cell setAcceptanceStatusBoundary:YES];
				}
			}
		}
		else 
		{ //NUSnumber class, for faked event or demo event
			if([(NSNumber *)event intValue]==0)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:
						@"noneedtoreuse"];
				return cell;
			}
			else 
			{
				//NSLog(@"Demo cell: index path = %d %d, %@", indexPath.section, indexPath.row, self.weiJuListDCtrl.lastTimeTodayDate);
				[(WeiJuCell *)cell setSubject:@"Demo event: Meeting" 
										place:@"Tap right button to view full map"//"To remove, swipe or go to settings" 
									startTime:self.weiJuListDCtrl.lastTimeTodayDate];
				[self setUpDemoEventCellMap:(WeiJuCell *)cell];
			}
			
		}
		
		//display the earth button only for today's events 
		if(indexPath.section==[self.weiJuListDCtrl todaySectionIndex])
			[(WeiJuCell *)cell displayShareBtn:YES];
		else 
			[(WeiJuCell *)cell displayShareBtn:NO];
		
		//if([event isKindOfClass:[EKEvent class]])
		//	NSLog(@"cell - %@:%f %f %f %f", event.title, -[timeNow1 timeIntervalSinceNow],-[timeNow2 timeIntervalSinceNow],-[timeNow3 timeIntervalSinceNow],-[timeNow4 timeIntervalSinceNow] );
	}
	else 
	{
		//demo cells
		[self setUpDemoCell:(WeiJuCell *)cell forRowAtIndexPath:indexPath];
	}
	
    return cell;
}

-(void) setUpDemoCell:(WeiJuCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *title, *location;
	NSDate *startDate;
	
	switch (indexPath.section) {
		case 0:
			if(indexPath.row==0)
			{
				title=@"Breakfast with Jerry";
				location=@"StarBucks, Cupertino";
				startDate=[Utils buildDateFromHour:8 minutes:30];
			}
			else {
				title=@"Sync up with Mike";
				location=@"Sequoia Room";
				startDate=[Utils buildDateFromHour:16 minutes:0];
			}
			break;
		case 1:
			if(indexPath.row==0)
			{
				title=@"Lunch meeting with Dan";
				location=@"Judy's Kitchen";
				startDate=[Utils buildDateFromHour:12 minutes:00];
			}
			else {
				title=@"Celebrate Kate's birthday";
				location=@"P.F. Chang, Palo Alto";
				startDate=[Utils buildDateFromHour:18 minutes:30];
			}
			break;
		case 2:
			title=@"Team weekly meeting";
			location=@"Online meeting: 650-758-8388";
			startDate=[Utils buildDateFromHour:10 minutes:00];
			break;
			
		default:
			break;
	}
	
	[(WeiJuCell *)cell setSubject:title 
							place:location 
						startTime:startDate];//设置标题时间地点等
	
	if(indexPath.section==1 && indexPath.row==0)
	{
		[self setUpDemoEventCellMap:(WeiJuCell *)cell];
		[(WeiJuCell *)cell setAcceptanceStatusBoundary:NO];
		[(WeiJuCell *)cell setBadge:3];
	}
	
	if(indexPath.section==1)
		[(WeiJuCell *)cell displayShareBtn:YES];
	else 
		[(WeiJuCell *)cell displayShareBtn:NO];

}

- (void) setUpDemoEventCellMap:(WeiJuCell *)cell
{
	CLLocationCoordinate2D center=CLLocationCoordinate2DMake(37.42173, -122.18453);
	BridgeAnnotation *ba = [[BridgeAnnotation alloc] init];
	ba.theTitle=@"Tom Eichert";
	ba.theSubtitle=@"T.E: 11:40am @ 23mph";
	[ba setCoordinate:center];
	[cell toggleMapMode:YES center:CLLocationCoordinate2DMake(center.latitude+3300.0/111000, center.longitude) latDistance:2000 longDistance:2000 annotation:ba];// crumbs:nil annotations:[NSMutableArray arrayWithObjects:ba, nil]]; 
	//shift the center up by 1280 to display part of the annotation for 1000 span
}

-(void) checkEventStatus:(NSDictionary *)withObject
{
    //NSDictionary *withObject = (NSDictionary *)[ConvertData getWithOjbect:dict];

	WeiJuCell *cell = (WeiJuCell *)[withObject objectForKey:@"cell"];

	//EKEvent *event = (EKEvent *)[withObject objectForKey:@"event"];
	//if([event.title rangeOfString:@"Vaccin"].location!=NSNotFound)
	//	NSLog(@"1 execute check for %@ %@",event.title, cell);
	
	if([[self.tableView visibleCells] containsObject:cell])
	{
		//if([event.title rangeOfString:@"Vaccin"].location!=NSNotFound)
		//	NSLog(@"2 checkEventStatus: %@", event.title);
		if ([Utils isUnprocessedEvent:[withObject objectForKey:@"event"]])
		{
			//NSLog(@"NO");
			[cell setAcceptanceStatusBoundary:NO];
		}
	}
	//else
	//	NSLog(@"%@: Cell no visible longer - no checking", ((EKEvent *)[withObject objectForKey:@"event"]).title);
}

#pragma mark - Table view delegate
//某一行被选择
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
		
	EKEvent *event = [self.weiJuListDCtrl objectInListAtIndex:indexPath];
	if([event isKindOfClass:[EKEvent class]])
	{
        [DataFetchUtil saveButtonsEventRecord:@"63"];
		
		if(self.weiJuListDCtrl.hasLoadedEvents && self.weiJuListDCtrl.hasServerBasedCalendar==NO)
		{
			[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_SERVER_CAL_TITLE", nil) message:NSLocalizedString(@"NO_SERVER_CAL_MSG", nil) noLocalNotif:YES];
		}
		
		EKEventViewController *evc = [[EKEventViewController alloc] init];
		evc.event = event;
		evc.allowsEditing=YES;
		evc.allowsCalendarPreview=YES;
		evc.delegate=self;
		UINavigationController * navigationController = [[UINavigationController alloc]
                                initWithRootViewController:evc];
		[self.navigationController pushViewController:evc animated:YES];
		//[self.navigationController presentViewController:navigationController animated:YES completion:nil];
		/*
		EKEventEditViewController  *evc = [[EKEventEditViewController alloc] init];
		evc.editViewDelegate=self;
		evc.event = event;
		evc.eventStore=self.weiJuListDCtrl.eventStore;
		[self.navigationController presentViewController:evc animated:YES completion:nil];
		*/
	}
	else {
		//demo event: popup
        [DataFetchUtil saveButtonsEventRecord:@"7"];
		//[self addPopOverReminder:@"Map displayed when at least one person is sharing path\n\nTap the button to view path sharing demo" fromRect:[[tableView cellForRowAtIndexPath:indexPath] convertRect:[(WeiJuCell *)[tableView cellForRowAtIndexPath:indexPath] getShareBtnRect] toView:self.view]];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo Event" message:@"Tap the button on the right of this demo event to view the path sharing demo in action\n\nMap for a real event is flip-displayed when 1) the event is for today, and 2) at least one participant in the event is sharing his/her path" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		if(self.demoMode==YES)
			alert.message=@"Tap the button on the right of this demo event to view the path sharing demo in action";
        [alert show];

	}	
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
*/


// Override to support editing the table view.
//横向滑动,显示删除的按钮
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.demoMode==YES)
		return;
	
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		//[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [DataFetchUtil saveButtonsEventRecord:@"d"];
		// Delete the row from the data source        
		EKEvent *event = [self.weiJuListDCtrl objectInListAtIndex:indexPath];
		if([event isKindOfClass:[EKEvent class]])
		{
			//notify server and others, not to forward location updates anymore?
			
			[self.weiJuListDCtrl deleteEvent:event atIndexPath:indexPath];		
		}
		else {
			//demo event
			[[WeiJuAppPrefs getSharedInstance] setDemoEventOnOff:NO];	
			[self.weiJuListDCtrl reloadDemoEvent:NO];
		}	
		
	}   
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}   
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - WeiJuCellDelegate
//cell里面的按钮被按之后的callback
- (void) notifBtnPushed:(WeiJuCell *)cell;
{
	//WeiJuMapVCtrl *mapVCtrl= [[WeiJuMapVCtrl alloc] initWithNibName:@"WeiJuMapVCtrl" bundle:nil];
	//[self.navigationController pushViewController:mapVCtrl animated:YES];
	
	//NSIndexPath *indexPath= [self.tableView indexPathForCell:cell];

	//[self.navigationController pushViewController:[[NotificationsVCtrl alloc] initWithNibName:@"NotificationsVCtrl" bundle:nil] animated:YES];
}

- (void) shareBtnPushed:(WeiJuCell *)cell
{
	self.currentSelectedSharingCell = cell;
	NSIndexPath *indexPath= [self.tableView indexPathForCell:cell];
	
	EKEvent *ekevent;
	if(self.demoMode==NO)
		ekevent = [self.weiJuListDCtrl objectInListAtIndex:indexPath];
	else
		ekevent = [NSNumber numberWithInt:1];

	if([ekevent isKindOfClass:[EKEvent class]])
        [DataFetchUtil saveButtonsEventRecord:@"64"];    
	else
        [DataFetchUtil saveButtonsEventRecord:@"8"];
	
	[self selectWeiJuPathShareVCtrl:ekevent eventID:nil display:YES];
}


- (WeiJuPathShareVCtrl *) selectWeiJuPathShareVCtrl:(EKEvent *)ekevent eventID:(NSString *)eventID display:(BOOL)yesOrNot
{
	EKEvent *event = ekevent;
	if(event==nil)
	{ 
		if(eventID!=nil)
			event = [self.weiJuListDCtrl getTodayEKEventFromEventIDAfterColon:[[eventID  componentsSeparatedByString:@":"] objectAtIndex:1] ];
		else 
			return nil;
	}
	
	if (event==nil) //still can't find event
		return nil;
	
	WeiJuPathShareVCtrl *pVC;
	if([event isKindOfClass:[EKEvent class]])
	{
		pVC = [self getWeiJuPathShareVCtrl:event]; //get from dict, or create a new pvc, but has not caledl viewloaded yet, called only init
	}
	else //demo event
		pVC = [self tapOnFingerImage:nil];
	
	if (pVC==nil || pVC.hasBeenShutdown)
		return nil;
	
	self.currentWeiJuPathShareVCtrl = pVC;
	
	if(yesOrNot)
	{
		[self.navigationController pushViewController:pVC animated:YES];
	}
	//else //decided not to do this, as we just need hasnewmessage之类的各类属性, no need to call viewdidload
	//	pVC.view; //simply force its viewdidload to be executed to load its mapview etc., but why??? 在chatdctrl,当收到某种信息的时候,例如invitetoshare,此时pvc可能还没被创建,在此处创建之后,调用.view之后,force viewdidload,才能设置mapvctrl,hasnewmessage之类的各类属性,这些属性会被调用,否则会出错
	
	return pVC;
}

-(WeiJuPathShareVCtrl *)getWeiJuPathShareVCtrl:(EKEvent *)ekevent
{
    NSString *eventIdAfterColon = [[ekevent.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1];
    WeiJuPathShareVCtrl *pVC = [self.weiJuPathShareVCtrls valueForKey:eventIdAfterColon];
    if(pVC==nil && [ekevent refresh]) //event is still valid, not deleted
    {
        if(YES) //显示所有用户中最近更新location的那个用户的地址为中心的地图:应该判读weijudata.isSharingLocation==YES
        {
            pVC = [[WeiJuPathShareVCtrl alloc] initWithNibName:@"WeiJuPathShareVCtrl" bundle:nil event:ekevent center:CLLocationCoordinate2DMake(-300, -300) latDistance:0 longDistance:0 crumbs:nil annotations:nil locSharing:NO demoMode:NO];
        }
        else //显示本用户为中心的地图
        {
            pVC = [[WeiJuPathShareVCtrl alloc] initWithNibName:@"WeiJuPathShareVCtrl" bundle:nil event:ekevent center:CLLocationCoordinate2DMake(-300, -300) latDistance:0 longDistance:0 crumbs:nil annotations:nil locSharing:NO demoMode:NO];
        }

        [pVC setUpParticipants:[NSNumber numberWithInt:0]]; //NOt refresh
        [self.weiJuPathShareVCtrls setValue:pVC forKey:eventIdAfterColon];
    }
	
	if(pVC!=nil && pVC.hasBeenShutdown==NO)
		return pVC; //[self.weiJuPathShareVCtrls objectForKey:eventId];
	else
		return nil;
}

-(WeiJuPathShareVCtrl *) tapOnFingerImage:(id)tap
{
	//demo event: create a new one everytime, do not store in dict
	//pVC = [self.weiJuPathShareVCtrls valueForKey:@"demoevent"];
	//if(pVC==nil)
	//{
		WeiJuPathShareVCtrl *pVC = [[WeiJuPathShareVCtrl alloc] initWithNibName:@"WeiJuPathShareVCtrl" bundle:nil event:nil center:CLLocationCoordinate2DMake(0, 0) latDistance:0 longDistance:0 crumbs:nil annotations:nil locSharing:NO demoMode:YES]; //can't be -300, -300, as it will center the map to user's current location
		[pVC setUpDemoParticipants];
		//[self.weiJuPathShareVCtrls setValue:pVC forKey:@"demoevent"];
	//}
	if(tap==nil) //called by selectWeiJuPathShareVCtrl
		return pVC;
	else {
		[self.navigationController pushViewController:pVC animated:YES];
		return nil;
	}
}

#pragma mark - EKEventViewDelegate, EKEventEditViewDelegate
- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action
{
	//if event has been modified, reload the Dctrl and table!!!!!
	
	[self.navigationController popViewControllerAnimated:YES];
	//[self.navigationController dismissViewControllerAnimated:YES completion:nil];	
	
	//can't do this, because the done action could mean there is no change
//	if([controller.event hasChanges])
//	{
//		MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
//		hud.labelText = @"Processing event...";
//		//but don't know when to hide it: ldctrl's processEventChangeNotification
//	}
}

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
	[self.navigationController dismissViewControllerAnimated:YES
												  completion:nil];	
	
	//no need - event change processing is now instant, rather than wait for 5 seconds
//	if(action!=EKEventEditViewActionCanceled) //saved or deleted event
//	{
//		MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
//		if(action==EKEventEditViewActionDeleted)
//			hud.labelText = @"Deleting event...";
//		else if(action==EKEventEditViewActionSaved)
//			hud.labelText = @"Saving event...";
//		//but don't know when to hide it: ldctrl's processEventChangeNotification
//	}
}

#pragma mark - NavBar ToolBar Buttons
-(void) setUpNavBar
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonPressed)];
	
	UIButton *settingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	settingBtn.frame=CGRectMake(0, 0, 34, 30);
	//[settingBtn setBackgroundImage:[UIImage imageNamed:@"UINavigationBarMiniDefaultButton.png"] forState:UIControlStateNormal];
	[settingBtn setBackgroundImage:[[UIImage imageNamed:@"UINavigationBarDefaultButton.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:15] forState:UIControlStateNormal];
	[settingBtn setImage:[UIImage imageNamed:@"Settings.png"] forState:UIControlStateNormal];
	[settingBtn addTarget:self action:@selector(settingBtnPushed:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingBtn]; 

	/* //勿删除
	 UIButton * settingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	 settingBtn.frame=CGRectMake(0, 0, 33, 30);
	 [settingBtn setBackgroundImage:[[UIImage imageNamed:@"Settings.png"] stretchableImageWithLeftCapWidth:16 topCapHeight:16] forState:UIControlStateNormal];
	 settingBtn.layer.cornerRadius = 6;
	 settingBtn.layer.masksToBounds = YES;
	 settingBtn.layer.borderWidth = 0.5;
	 
	 [settingBtn addTarget:self action:@selector(settingBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	 self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingBtn];
	 */
	

	//self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"QLog"/*NSLocalizedString(@"SETTINGS", nil)*/ style:UIBarButtonItemStyleBordered target:self action:@selector(logButtonPushed)];
}

-(void) setUpToolBar
{	
	
	UIBarButtonItem *today = [[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStyleBordered target:self action:@selector(todayBarButtonPressed) ];
	
	self.dayMonth = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Day", @"Month", nil] ]; //[[UIBarButtonItem alloc] initWithTitle:@"Month" style:UIBarButtonItemStyleBordered target:self action:@selector(monthBarButtonPressed) ];
	//dayMonth.width = 56;
	self.dayMonth.selectedSegmentIndex=0;
	self.dayMonth.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.dayMonth addTarget:self action:@selector(monthBarButtonPressed:) forControlEvents:UIControlEventValueChanged];
    /*
	UIButton *contactBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	contactBtn.frame=CGRectMake(0, 0, 50, 30);
	[contactBtn setBackgroundImage:[[UIImage imageNamed:@"UINavigationBarDefaultButton.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:15] forState:UIControlStateNormal];
	[contactBtn setImage:[UIImage imageNamed:@"multiplepeople.png"] forState:UIControlStateNormal];
	[contactBtn addTarget:self action:@selector(contactBtnPushed:) forControlEvents:UIControlEventTouchUpInside];
	 */
	UIBarButtonItem *contactBtn = [[UIBarButtonItem alloc] initWithTitle:@"Friends" style:UIBarButtonItemStyleBordered target:self action:@selector(contactBtnPushed:) ];
	
	[self setToolbarItems: [ [NSArray alloc] initWithObjects:
							today,
							[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],
							[[UIBarButtonItem alloc] initWithCustomView:self.dayMonth],
							[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],
							contactBtn/*[[UIBarButtonItem alloc] initWithCustomView:contactBtn]*/, nil] ];
	
}

- (void) addBarButtonPressed 
{    
    //[self.navigationController pushViewController:[[FriendsListVCtrl alloc] initWithNibName:@"FriendsListVCtrl" bundle:nil type:@"AddWeiJu"] animated:YES];
	[DataFetchUtil saveButtonsEventRecord:@"2"];
	
	if (self.weiJuListDCtrl.hasLoadedEvents==NO)
	{
		if(self.weiJuListDCtrl.hasAcceessToCalendar==NO)
			[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_CAL_ACCESS_TITLE", nil) message:NSLocalizedString(@"NO_CAL_ACCESS_MSG", nil) noLocalNotif:YES];
		return;
	}
	
	if(self.weiJuListDCtrl.hasLoadedEvents && self.weiJuListDCtrl.hasServerBasedCalendar==NO)
	{
		[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_SERVER_CAL_TITLE", nil) message:NSLocalizedString(@"NO_SERVER_CAL_MSG", nil) noLocalNotif:YES];
		//return;
	}
	
    //create a new one
	EKEventEditViewController  *evc = [[EKEventEditViewController alloc] init];
	evc.editViewDelegate=self;
	evc.eventStore=self.weiJuListDCtrl.eventStore;
	[self.navigationController presentViewController:evc animated:YES completion:nil];
}

- (void) notifBarButtonPressed
{
    //printf("settingBarButtonPressed\n");
	//[self.navigationController pushViewController:[[NotificationsVCtrl alloc] initWithNibName:@"NotificationsVCtrl" bundle:nil] animated:YES];
}

-(void) todayBarButtonPressed
{
	if (self.demoMode == YES)
		return;

	[DataFetchUtil saveButtonsEventRecord:@"3"];
	if(self.weiJuListDCtrl.hasLoadedEvents==NO)
	{
		if(self.weiJuListDCtrl.hasAcceessToCalendar==NO)
			[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_CAL_ACCESS_TITLE", nil) message:NSLocalizedString(@"NO_CAL_ACCESS_MSG", nil) noLocalNotif:YES];
		return;
	}
	
	[self gotoToday];
}

- (void) gotoToday
{
    if ([@"month" isEqualToString:listMonthStatus])
	{
        [self.calMouthVCtrl.calendarLogic setReferenceDate:[[NSDate alloc] init]];
    }
	else
	{
        if([self.weiJuListDCtrl numberOfSections] <= 0 || self.tableView==nil || [self.tableView numberOfSections]<=0) //eventdata not loaded, or table not loaded yet due to reloaddata not called yet
            return;
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self.weiJuListDCtrl todaySectionIndex]] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) monthBarButtonPressed:(UISegmentedControl *)favOption
{
	if (self.demoMode == YES)
		return;

	if (self.weiJuListDCtrl.hasLoadedEvents==NO)
	{
		if(self.weiJuListDCtrl.hasAcceessToCalendar==NO)
			[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_CAL_ACCESS_TITLE", nil) message:NSLocalizedString(@"NO_CAL_ACCESS_MSG", nil) noLocalNotif:YES];
		
		favOption.selectedSegmentIndex=0;
		return;
	}

	if(self.dayMonth.selectedSegmentIndex==1) //month
	{
        [DataFetchUtil saveButtonsEventRecord:@"6"];

		if(self.backgroundView==nil)
		{
			self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
			self.backgroundView.backgroundColor = [UIColor whiteColor];
		}
		[self.view addSubview:self.backgroundView];

		if(self.calMouthVCtrl==nil)
        {
            self.calMouthVCtrl = [[CalendarMonthVCtrl alloc] initWithNibName:nil bundle:nil rect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        }
        [self.calMouthVCtrl setCalendarViewControllerDelegate:self];
		
        self.calMouthVCtrl.view.layer.shadowColor = [UIColor blackColor].CGColor;
        self.calMouthVCtrl.view.layer.shadowOffset = CGSizeMake(4, 4);
        self.calMouthVCtrl.view.layer.shadowOpacity = 0.5;
        self.calMouthVCtrl.view.layer.shadowRadius = 10.0;
		
        [self.view addSubview:self.calMouthVCtrl.view];
		
		listMonthStatus=@"month";
	}
	else {
        [DataFetchUtil saveButtonsEventRecord:@"5"];
		[self.calMouthVCtrl.view removeFromSuperview];
		[self.backgroundView removeFromSuperview];
		listMonthStatus=@"list";
	}

}

- (void)selectedDayInMonthCalendar:(CalendarMonthVCtrl *)aCalendarViewController dateDidChange:(NSDate *)aDate {
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self.weiJuListDCtrl getSectionIndex:aDate]] atScrollPosition:UITableViewScrollPositionTop animated:NO];
           
    [self.calMouthVCtrl.view removeFromSuperview];
	[self.backgroundView removeFromSuperview];

    listMonthStatus=@"list";
    
	[self.dayMonth setSelectedSegmentIndex:0];
}


- (void)contactBtnPushed:(id)sender 
{
	if (self.demoMode == YES)
		return;

    [DataFetchUtil saveButtonsEventRecord:@"4"];
	[self.navigationController pushViewController:[[FriendsListVCtrl alloc] initWithNibName:@"FriendsListVCtrl" bundle:nil type:@"FriendList"] animated:YES];
	/*
	if([Utils isOSLowerThan5]==NO)
	{
		[self dismissViewControllerAnimated:YES completion:^
		 {
			 [self.navigationController pushViewController:[[FriendsListVCtrl alloc] initWithNibName:@"FriendsListVCtrl" bundle:nil type:@"FriendList"] animated:YES];
		 }];
	}
	else {
		[self dismissModalViewControllerAnimated:YES];
		[self.navigationController pushViewController:[[FriendsListVCtrl alloc] initWithNibName:@"FriendsListVCtrl" bundle:nil type:@"FriendList"] animated:YES];
	}
	*/
}

- (void)settingBtnPushed:(id)sender 
{
    [DataFetchUtil saveButtonsEventRecord:@"1"];
	[self.navigationController pushViewController:[[SettingsVCtrl alloc] initWithNibName:@"SettingsVCtrl" bundle:nil] animated:YES];
}

#pragma mark - WEPopoverControllerDelegate implementation
- (void)popoverControllerDidDismissPopover:(WEPopoverController *)thePopoverController {
	//Safe to release the popover here
	//self.popoverCtrl = nil; //dont release, it might set a new popoverctrl to nil due to multithread
}

- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)thePopoverController 
{
	//The popover is automatically dismissed if you click outside it, unless you return NO here
	return YES;
}

-(void) dismissPopover
{
	if(self.popoverCtrl!=nil)
		[self.popoverCtrl dismissPopoverAnimated:YES];
}

-(void) addPopOverReminder:(NSString *)textContent fromRect:(CGRect)targetRect
{
	[self dismissPopover];
	

		self.popoverReminder = [[PopOverTexiViewReminder alloc] initWithNibName:@"PopOverTexiViewReminder" bundle:nil size:CGRectMake(0, 0, 160, 120/*55*/)];
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.frame = CGRectMake(self.popoverReminder.view.frame.size.width-38, -2, 40, 40);
		[closeButton setImage:[UIImage imageNamed:@"cancel-icon-red.png"]  forState:UIControlStateNormal];
		closeButton.imageEdgeInsets = UIEdgeInsetsMake(-10, 10, 10, -10); //move the cross image to the top right corner
		closeButton.backgroundColor = [UIColor clearColor]; 
        [closeButton addTarget:self action:@selector(dismissPopover) forControlEvents:UIControlEventTouchUpInside];
        [self.popoverReminder.view addSubview:closeButton];
		
		self.popoverCtrl = [[WEPopoverController alloc] initWithContentViewController:self.popoverReminder];
        self.popoverCtrl.delegate = self;
        self.popoverCtrl.passthroughViews = nil; //[NSArray arrayWithObjects:self.view, nil];
        [self.popoverCtrl setContainerViewProperties:[self.popoverCtrl improvedContainerViewProperties]];
	
	if(CGRectIsNull(targetRect)) //point to the toolbar barbutton
		[self.popoverCtrl presentPopoverFromBarButtonItem:nil permittedArrowDirections:UIPopoverArrowDirectionDown|UIPopoverArrowDirectionUp animated:YES];
	else 
		[self.popoverCtrl presentPopoverFromRect:targetRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown|UIPopoverArrowDirectionUp animated:YES];
	
	[self.popoverReminder setTextContent:textContent];
	
}

@end
