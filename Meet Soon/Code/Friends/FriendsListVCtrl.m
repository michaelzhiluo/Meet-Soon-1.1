//
//  FriendsListVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "WeiJuAppPrefs.h"
#import "FriendsListVCtrl.h"
#import "FriendDetailVCtrl.h"
#import "FriendsListDCtrl.h"
#import "FriendsScrollVCtrl.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuData.h"
#import "ConvertData.h"
#import "FriendData.h"
#import "FileOperationUtils.h"
#import "Utils.h"
#import "DataFetchUtil.h"
#import "WeiJuNetWorkClient.h"
#import "WeiJuManagedObjectContext.h"
#import "ConvertUtil.h"
#import "MBProgressHUD.h"
#import "OperationQueue.h"
#import "OperationTask.h"

@interface FriendsListVCtrl ()

@end

@implementation FriendsListVCtrl

#define CELL_TAG_USERIMAGE 10
#define CELL_TAG_USERNAME 11
#define CELL_TAG_HISTORY 12
#define CELL_TAG_TELLBTN 13

#define BOTTOM_BAR_HEIGHT 55

@synthesize tableView=_tableView;
@synthesize searchController = _searchController;
@synthesize searchBar = _searchBar;
@synthesize friendsVCell=_friendsVCell;
@synthesize contactsVCell=_contactsVCell;
@synthesize friendsListDCtrl=_friendsListDCtrl, friendsScrollVCtrl=_friendsScrollVCtrl, fDetailVCtrl=_fDetailVCtrl;
@synthesize listOption=_listOption, indexPaths=_indexPaths;
@synthesize swipeGestureRecognizerRight;
@synthesize swipeGestureRecognizerLeft;
@synthesize viewType=_viewType, dictionary=_dictionary, collation=_collation;
@synthesize loadAddrBookQ=_loadAddrBookQ, loadImageQ=_loadImageQ, isBeingDisplayed=_isBeingDisplayed;

static FriendsListVCtrl *friendsListVCtrl;

UIImage *noneImage;

+ (FriendsListVCtrl *)getSharedInstance
{
    return friendsListVCtrl;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil type:(NSString *)type
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
	{
		friendsListVCtrl = self;

        // Custom initialization
		if([type isEqualToString:@"All"]){
            self.viewType =  @"All";
        }
		else if([type isEqualToString:@"FriendList"]){
            self.viewType =  @"FriendList";
        }
		else{//??
            self.viewType =  @"FriendList";
        }        
        self.dictionary = [NSMutableDictionary dictionary];
		
		self.loadAddrBookQ = [[NSOperationQueue alloc] init];
		self.loadImageQ = [[NSOperationQueue alloc] init];
		noneImage = [UIImage imageNamed:@"person_list_none.png"];
		
		self.isBeingDisplayed=NO;
    }
    //[self.friendsListDCtrl startSearch];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self != nil) 
    {
        if (self.friendsListDCtrl == nil) {
            self.friendsListDCtrl = [FriendsListDCtrl getSharedInstance];
            [self.friendsListDCtrl startSearch];
        }
		
		//[self.friendsListDCtrl openAddrBook]; //for access to addressbook in loading table cell
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backBarButtonPressed)];

		//self.searchController.active=YES;
		
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
        if(self.viewType == nil)
		{
            self.viewType = @"FriendList";
        }
		
        if([self.viewType isEqualToString:@"All"])
		{
			self.title = NSLocalizedString(@"CONTACT_SELECT_TITLE", nil);
            //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]  initWithTitle:@"Confirm" style:UIBarButtonItemStyleBordered target:self action:@selector(addFriendDoneBarButtonPressed)];
			//self.navigationItem.rightBarButtonItem.enabled=NO;//disable the button since no one is selected yet
			
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(addFriendCancelBarButtonPressed)]; 
            
			//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAddressBook)]; //refreshAddressBook还没实现
			//[self.navigationItem.rightBarButtonItem setEnabled:NO];
			
			//[Utils hideTabBar:YES For:self.tabBarController];
			[Utils hideNavToolBar:YES For:self.navigationController];
			
			self.friendsScrollVCtrl = [[FriendsScrollVCtrl alloc] initWithNibName:nil bundle:nil rect:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+self.view.frame.size.height-BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT) mode:FRIEND_SCROLL_LIST_MODE_CONTACT friends:nil callBack:self];
			[self.view addSubview:self.friendsScrollVCtrl.view];
			
			[Utils shiftView:self.tableView changeInX:0 changeInY:0 changeInWidth:0 changeInHeight:-BOTTOM_BAR_HEIGHT];
						
        }
		else if([self.viewType isEqualToString:@"FriendList"])
		{
			self.title = @"Meeting History"; //NSLocalizedString(@"TAB2_TITLE", nil);
            
			//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFriendBarButtonPressed)];
			//self.searchBar.placeholder = @"Search (Case Sensitive)";
			
			self.listOption =[[UISegmentedControl alloc] initWithItems:[[NSArray alloc] initWithObjects:@"Registered Friends", @"Phone Book", nil]];
			self.listOption.segmentedControlStyle = UISegmentedControlStyleBar;
			self.listOption.selectedSegmentIndex=0;
			[self.listOption addTarget:self action:@selector(listOptionChanged:) forControlEvents:UIControlEventValueChanged];
			
			[self setToolbarItems: [ [NSArray alloc] initWithObjects:
									[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],
									[[UIBarButtonItem alloc] initWithCustomView: self.listOption],
									[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil], 
									//add,
									nil]];
			
        }
        self.tableView.tableHeaderView = _searchBar;
		
    }
}

- (void)viewDidUnload
{

    [self setFriendsVCell:nil];
    [self setContactsVCell:nil];
    [self setTableView:nil];
	
	self.friendsListDCtrl=nil;
	self.friendsScrollVCtrl=nil;
	self.fDetailVCtrl=nil;
	
	self.listOption=nil;
	self.indexPaths=nil;
	self.searchBar=nil;
	
	self.viewType=nil;
	self.dictionary=nil;
	self.collation=nil;
	
	[self setSearchBar:nil];
    [self setSearchController:nil];
    [self setSearchBar:nil];
	
	[self.loadAddrBookQ cancelAllOperations];
	[self.loadImageQ cancelAllOperations];
	self.loadAddrBookQ=nil;
	self.loadImageQ=nil;
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[Utils hideNavToolBar:NO For:self.navigationController];

	/*
	if(self.viewType == nil)
	{
		[Utils hideTabBar:NO For:self.tabBarController];
	}
	else if([self.viewType isEqualToString:@"AddWeiJu"])
	{
		[Utils hideTabBar:YES For:self.tabBarController];
	}
	*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if (ABAddressBookRequestAccessWithCompletion != NULL && ABAddressBookGetAuthorizationStatus()!=kABAuthorizationStatusAuthorized ) //ios6
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(addressBookIsReady:)
													 name:@"AddrBookNotif" object:self.friendsListDCtrl];
		[self.friendsListDCtrl getAccessToAddr];
	}
	
	self.isBeingDisplayed = YES;
}

- (void) addressBookIsReady:(NSNotification *)notification
{
	//note, this is executed on the thread that ABAddressBookRequestAccessWithCompletion is called, hence put it on mainthread, to ensure execution right away
	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddrBookNotif" object:self.friendsListDCtrl];

}

- (void)viewWillDisappear:(BOOL)animated
{        
	self.isBeingDisplayed = NO;

    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"20"];
        
    }else {
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"14"];
    }
	
	[self.loadImageQ cancelAllOperations]; //stop loading image
	
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void) handleSwipes:(UISwipeGestureRecognizer *)paramSender{
    if (paramSender.direction & UISwipeGestureRecognizerDirectionDown) {
        //NSLog(@"down");
    }else if(paramSender.direction & UISwipeGestureRecognizerDirectionUp){
        //NSLog(@"up");
    }else if(paramSender.direction & UISwipeGestureRecognizerDirectionLeft){
        //added Button click Event
        if(self.listOption.selectedSegmentIndex==0) //my friends
        {
            //added Button click Event
            [DataFetchUtil saveButtonsEventRecord:@"11"];
            
        }else {
            //added Button click Event
            [DataFetchUtil saveButtonsEventRecord:@"21"];

        }
    }else if(paramSender.direction & UISwipeGestureRecognizerDirectionRight){
        
        if(self.listOption.selectedSegmentIndex==0) //my friends
        {//added Button click Event
            [DataFetchUtil saveButtonsEventRecord:@"12"];
            
        }else {
            //added Button click Event
            [DataFetchUtil saveButtonsEventRecord:@"22"];
        }
    }
}

- (void) backBarButtonPressed
{
	//[self.friendsListDCtrl closeAddrBook]; //for remove the access to addressbook in loading table cell
	
	[self.navigationController popViewControllerAnimated:YES];
}
//-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    //added Button click Event
//    if(self.listOption.selectedSegmentIndex==0) //my friends
//    {//added Button click Event
//        [DataFetchUtil saveButtonsEventRecord:@"y"];
//        
//    }else {
//        //added Button click Event
//        [DataFetchUtil saveButtonsEventRecord:@"19"];
//    }
//    
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.listOption.selectedSegmentIndex==0) //my friends
	{
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"x"];
		//FriendDetailVCtrl *friendDetailVCtrl;
		
		FriendData *friendData = (FriendData *)[self.friendsListDCtrl objectInListAtIndex:indexPath];
		self.fDetailVCtrl = [[FriendDetailVCtrl alloc] initWithNibName:@"FriendDetailVCtrl" bundle:nil friendData:friendData];
		
        [self.navigationController pushViewController:self.fDetailVCtrl animated:YES];
    }else {//all contants
        //[self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
        //[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [DataFetchUtil saveButtonsEventRecord:@"17"];
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
   	
}

//横向滑动,显示删除的按钮
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//	if (editingStyle == UITableViewCellEditingStyleDelete) 
//	{
//		FriendData *friendData = (FriendData *)[self.friendsListDCtrl objectInListAtIndex:indexPath];
//        friendData.hide = @"1";
//        [WeiJuManagedObjectContext quickSave];
//        [self.friendsListDCtrl startSearch];
//        [self.tableView reloadData];
//	}
//}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{	
	NSString *userID;
	
	FriendData *friendData = (FriendData *)[self.friendsListDCtrl objectInListAtIndex:indexPath];
	userID = friendData.userId;
	
	if([self.dictionary objectForKey:userID] == nil)
	{ //select and add user
        [self.dictionary setObject:@"" forKey:userID];
		
		if([[WeiJuAppPrefs getSharedInstance] demo])
		{
			//[self.friendsScrollVCtrl addFriendViewAndName:selectedName];
			//[self.friendsScrollVCtrl setFriend:selectedName status:FRIEND_SCROLL_LIST_STAUS_UNDECIDED];
		}
		else {
			
		}
    }
	else
	{ //undelect user
        [self.dictionary removeObjectForKey:userID];

		if([[WeiJuAppPrefs getSharedInstance] demo])
		{
			//[self.friendsScrollVCtrl removeFriendViewAndName:selectedName];
		}
		else {
			
		}
    } 

	BOOL checked = NO; //search dict again to decide whether to display checked mark
	if([self.dictionary objectForKey:userID] == nil)
	{
        checked = NO;
    }
	else
	{
		checked = YES;
    } 

    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];   
    UIButton *button = (UIButton *)cell.accessoryView;	
	UIImage *newImage = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
	[button setBackgroundImage:newImage forState:UIControlStateNormal];
	
	if([self.dictionary count]>0) //or shall we use "[[dictionary allKeys] count] > 1" as in "(void) addFriendDoneBarButtonPressed"?
		self.navigationItem.rightBarButtonItem.enabled=YES;
	else {
		self.navigationItem.rightBarButtonItem.enabled=NO;//disable the button since no one is slecte
	}
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
		if ([[WeiJuAppPrefs getSharedInstance] demo]) {
			return 1;
		}
		
		if(self.friendsListDCtrl.hasLoadedAddr==NO)
			return 0;
        else
			return [self.friendsListDCtrl numberOfSections];
    }
	else { //all contatcs
		return [self.friendsListDCtrl adbNumberOfSections];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(self.listOption.selectedSegmentIndex==0) //my friends
	{
		if ([[WeiJuAppPrefs getSharedInstance] demo]) {
			return 7;
		}
        
		if(self.friendsListDCtrl.hasLoadedAddr==NO)
			return 0;
        else
			return [self.friendsListDCtrl numberOfRowsInSection:section];
    }
	else { //all contatcs
		return [self.friendsListDCtrl adbNumberOfRowsInSection:section];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if([[WeiJuAppPrefs getSharedInstance] demo])
		return nil;
    if (![@"" isEqualToString:self.searchBar.text]) {
        return @"";
    }
    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
        return [[self.friendsListDCtrl sectionIndexTitles] objectAtIndex:section];
    }else {
        return [[self.friendsListDCtrl adbSectionIndexTitles] objectAtIndex:section];
    }
	
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	if([[WeiJuAppPrefs getSharedInstance] demo])
		return nil;
    if (![@"" isEqualToString:self.searchBar.text]) {
        return nil;
    }
    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
        return [self.friendsListDCtrl sectionIndexTitles];
    }else {
         return [self.friendsListDCtrl adbSectionIndexTitles];
    }
  
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"FriendCell";
    
	UIImageView *userImage;
	UILabel *userName;
	UILabel *historyLabel;
	UIButton *tellBtn;
    UILabel *indexLabel;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) 
	{
        [[NSBundle mainBundle] loadNibNamed:@"FriendsListVCell" owner:self options:nil];
		
		cell = self.friendsVCell;
		self.friendsVCell = nil;
		historyLabel = (UILabel *)[cell viewWithTag:CELL_TAG_HISTORY]; //UI label last meeting info
		historyLabel.layer.cornerRadius=3.0;
		
		tellBtn = (UIButton *)[cell viewWithTag:CELL_TAG_TELLBTN];
		[tellBtn setBackgroundImage:[[UIImage imageNamed:@"TellBtnBg.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:12] forState:UIControlStateNormal];
        [tellBtn addTarget:self action:@selector(tellBtnPushed:) forControlEvents:UIControlEventTouchUpInside];
	}
	userImage = (UIImageView *)[cell viewWithTag:CELL_TAG_USERIMAGE];
	userName = (UILabel *)[cell viewWithTag:CELL_TAG_USERNAME];
	historyLabel = (UILabel *)[cell viewWithTag:CELL_TAG_HISTORY]; //UI label 
	userImage.layer.masksToBounds=YES; 
    userImage.layer.cornerRadius=5.0; 
    userImage.layer.borderWidth=1.0; 
    userImage.layer.borderColor=[[UIColor lightGrayColor] CGColor];
	
	tellBtn = (UIButton *)[cell viewWithTag:CELL_TAG_TELLBTN];
	historyLabel.hidden = YES;
    tellBtn.hidden = YES;
    indexLabel.text = [NSString stringWithFormat:@"%i,%i",indexPath.section,indexPath.row];
    
    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
        FriendData *friendData = (FriendData *)[self.friendsListDCtrl objectInListAtIndex:indexPath];
		//NSLog(@"fvlvc - cellForRowAtIndexPath:friendData:%@",friendData);
		if([friendData.abRecordLastName isEqualToString:@""]==NO)
			userName.text = [friendData.abRecordLastName stringByAppendingFormat:@" %@", friendData.abRecordFirstName];
		else 
			userName.text = friendData.abRecordName;

        historyLabel.hidden = NO;
        if (friendData.lastMeetingDate == nil) 
		{            
            historyLabel.text = @"No meeting history";
        }else{
            historyLabel.text = [[ConvertUtil convertDateToString:friendData.lastMeetingDate dateFormat:@"YYYY-MM-dd"] stringByAppendingFormat:@"\n%@",friendData.lastMeetingLocation];
			//historyLabel.text = [friendData.lastMeetingTitle stringByAppendingFormat:@"\n%@",friendData.lastMeetingLocation];
        }
		
		userImage.image = noneImage; //[UIImage imageNamed:@"person_list_none.png"];
		//NSLog(@"add updateImage: %@ %d", friendData.userName,[friendData.userImageFileData length]);
		if(friendData.userImageFileData!=nil) //load image in background
		{
			/*
			NSMutableDictionary *withObject = [NSMutableDictionary dictionary];
            [withObject setObject:friendData forKey:@"friendData"];
            [withObject setObject:cell forKey:@"cell"];
			NSInvocationOperation *imageTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateImage:) object:withObject];
			//[imageTask setQueuePriority:NSOperationQueuePriorityVeryLow];
			//[imageTask setThreadPriority:0.0];
			[self.loadImageQ addOperation:imageTask];
			*/
			userImage.image = [UIImage imageWithData:friendData.userImageFileData];
		}
        
		/*
        //check if user has added a new image for this person
		//NSLog(@"abRecordNameNoCase: %@",friendData.abRecordNameNoCase);
		if(friendData.abRecordNameNoCase!=nil)
		{
			NSString *idString = (NSString *)[[friendData.abRecordNameNoCase componentsSeparatedByString:@"|"] objectAtIndex:1];
			//NSLog(@"idString: %@", idString);
			if(idString!=nil&&[idString isEqualToString:@""]==NO)
			{
				int32_t abRecordID = [idString intValue];
				friendData.userImageFileData  = [self.friendsListDCtrl getImageByRecordID:abRecordID];
			}
		}
		
		if(friendData.userImageFileData!=nil)
			userImage.image = [UIImage imageWithData:friendData.userImageFileData];
		else
			userImage.image = noneImage; //[UIImage imageNamed:@"person_list_none.png"];// [UIImage imageNamed:@"person_none_image.png"];
		 */
    }
	else {//all contacts
        NSDictionary *dictionaryFriend = [self.friendsListDCtrl adbObjectInListAtIndex:indexPath];
        userName.text = [dictionaryFriend objectForKey:@"username"];
        if ([dictionaryFriend objectForKey:@"image"] == nil) 
        {
            userImage.image = noneImage; //[UIImage imageNamed:@"person_list_none.png"];
        }
        else
        {
            userImage.image = [dictionaryFriend objectForKey:@"image"];
        }
        
        if ([dictionaryFriend objectForKey:@"FriendData"] == nil) {
            tellBtn.hidden = NO;
        }else {
            FriendData *friendData = (FriendData *)[dictionaryFriend objectForKey:@"FriendData"];
            historyLabel.hidden = NO;
            if (friendData.lastMeetingDate == nil) {
                
                historyLabel.text = @"No meeting history";
            }else{
                historyLabel.text = [[ConvertUtil convertDateToString:friendData.lastMeetingDate dateFormat:@"YYYY-MM-dd"] stringByAppendingFormat:@"\n%@",friendData.lastMeetingLocation];
            }
        }
    }
    return cell;
}
/* //no longer using thread to load image
-(void) updateImage:(NSDictionary *)withObject
{
    //NSDictionary *withObject = (NSDictionary *)[ConvertData getWithOjbect:dict];
	UITableViewCell *cell = (UITableViewCell *)[withObject objectForKey:@"cell"];
    FriendData *friendData = (FriendData *)[withObject objectForKey:@"friendData"];
	if([[self.tableView visibleCells] containsObject:cell])
	{
		//NSLog(@"updateImage: %@ %@ %@", friendData.userName, [NSThread currentThread], [NSThread mainThread]);
		if(friendData.userImageFileData!=nil)
		{
			UIImageView *userImage = (UIImageView *)[cell viewWithTag:CELL_TAG_USERIMAGE];
			userImage.image = [UIImage imageWithData:friendData.userImageFileData];
		}
	}
}
*/
#pragma mark - Buttons

- (void) tellBtnPushed:(id)sender {
    
    [DataFetchUtil saveButtonsEventRecord:@"16"];
    
    NSDictionary *personDic = (NSDictionary *)[self.friendsListDCtrl adbObjectInListAtIndex:[self.tableView indexPathForCell:((UITableViewCell*)[[sender superview]superview])]];
    
    if ([personDic objectForKey:@"email"] == nil) {
        [self promptForAddrSelection:personDic]; //not registered user for sure
        return;
    }
    
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = @"Checking friend's registration status...";
    
    NSMutableDictionary *dicP = [NSMutableDictionary dictionary];
    [dicP setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs userId] forKey:@"userId"];
    [dicP setObject:[personDic objectForKey:@"email"] forKey:@"userEmails"];
    [[[WeiJuNetWorkClient alloc] init] requestData:@"userFriendsAction.syncClientData" parameters:dicP withObject:personDic callbackInstance:self callbackMethod:@"checkUserResgisterStatusCallBack:"];
    
}

-(void) checkUserResgisterStatusCallBack:(NSDictionary *)dic
{
    @try{
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
	}
    @catch(NSException *e){
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, e, [e userInfo]];
    }
	if ([ConvertData getErrorInfo:dic] != nil)
	{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:[ConvertData getErrorInfo:dic] delegate:self cancelButtonTitle:@"Dimiss" otherButtonTitles:nil];
        [alert show];
        return; 
    }
	
	
	[[[ConvertData alloc] init] syncCoreDataWithNetDictionaryWithoutInitData:dic];
    //at this point, the user's frienddata might have been downloaded, hence let's do a search
    NSDictionary *personDic = (NSDictionary *)[ConvertData getWithOjbect:dic];
	
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    NSArray *emailArr = [[personDic objectForKey:@"email"] componentsSeparatedByString:@","];
    for(int i = 0;i<[emailArr count];i++){
        NSString *email = [emailArr objectAtIndex:i];
        NSArray *friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",email]];
        if([friendDataResult count]==1)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"This person has registered as a Meet Soon user already." delegate:self cancelButtonTitle:@"Dimiss" otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    [self promptForAddrSelection:personDic];

}

-(void) promptForAddrSelection:(NSDictionary *)friendDic
{
	NSString *msg;
	msg=[[friendDic objectForKey:@"username"] stringByAppendingString:@" is not a registered user; choose the SMS/Email address to invite him/her to download this iPhone app"];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:@"Dismiss" destructiveButtonTitle:nil otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    NSMutableArray *personPhoneLabelArr = (NSMutableArray *)[friendDic objectForKey:@"personPhoneLabelArr"];
    NSMutableArray *personPhoneArr = (NSMutableArray *)[friendDic objectForKey:@"personPhoneArr"];

	for (int i=0; i<[personPhoneLabelArr count]; i++) 
	{
		[actionSheet addButtonWithTitle:[(NSString *)[personPhoneLabelArr objectAtIndex:i] stringByAppendingFormat:@": %@", [personPhoneArr objectAtIndex:i]] ];
	}

	[actionSheet addButtonWithTitle:@"Manually input phone number"];
		
	if ([friendDic objectForKey:@"email"] != nil) 
	{
		NSArray *emails = [[friendDic objectForKey:@"email"] componentsSeparatedByString:@","];
		for (NSString * emailAddr in emails)
			[actionSheet addButtonWithTitle:emailAddr];
    }
	[actionSheet showFromToolbar:self.navigationController.toolbar];

}

//The receiver is automatically dismissed after this method is invoked
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex!=0) //dismiss?
	{
        
        //NSLog(@"%i",[[actionSheet buttonTitleAtIndex:buttonIndex] rangeOfString:@":"].location);
        
		if ([[actionSheet buttonTitleAtIndex:buttonIndex] rangeOfString:@":"].location != NSNotFound)
		{
			//phone numbers
            [DataFetchUtil saveButtonsEventRecord:@"86"];
			[Utils sendReferral:self to:[ NSArray arrayWithObject:[[[actionSheet buttonTitleAtIndex:buttonIndex] componentsSeparatedByString:@":"] objectAtIndex:1] ] viaMedium:0];
        }
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] rangeOfString:@"@"].location != NSNotFound)
		{
			//email
           [DataFetchUtil saveButtonsEventRecord:@"88"];
            //email address
			[Utils sendReferral:self to:[NSArray arrayWithObject:[actionSheet buttonTitleAtIndex:buttonIndex]] viaMedium:1];
        }
		else 
		{	//input own number
            [DataFetchUtil saveButtonsEventRecord:@"87"];
			[Utils sendReferral:self to:nil/*[NSArray arrayWithObjects:@"", nil]*/ viaMedium:0];
        }
        

	}else {
        [DataFetchUtil saveButtonsEventRecord:@"85"];
    }
}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) listOptionChanged:(UISegmentedControl *)favOption
{
    self.friendsListDCtrl.addressBookCurrentSearchStr = @"";

	//load diff table based on segmentcontrol choice
    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"23"];
		self.title = @"Meeting History";
		
		NSIndexPath *ip;
		if(self.indexPaths!=nil&&[self.indexPaths count]>0)
			ip=(NSIndexPath *)[self.indexPaths objectAtIndex:0];
		self.indexPaths=[self.tableView indexPathsForVisibleRows]; //record the previous table row position

        [self.tableView reloadData];
		if(ip!=nil)
			[self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];

		[self.navigationItem.rightBarButtonItem setEnabled:NO];
    }else {
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"13"];
		self.title = @"Refer App to Friends";
        if (self.friendsListDCtrl.addressBookDictionary == nil) {
            MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.labelText = @"Loading ...";
        }
		/*
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:self forKey:@"invokeObjectClass1"];
        [dictionary setObject:@"startAddressBookSearch" forKey:@"invokeObjectMethodName1"];
        [OperationQueue addTask:@"task" operationObject:[[OperationTask alloc] init] parameters:dictionary];
		*/
        NSInvocationOperation *addrTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(startAddressBookSearch) object:nil];
		[self.loadAddrBookQ addOperation:addrTask];
		
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    
}

- (void) startAddressBookSearch
{
    [self.friendsListDCtrl startAddressBookSearch];
    [self performSelectorOnMainThread:@selector(reloadTableAndCancelHUD) withObject:nil waitUntilDone:YES];
}

-(void) reloadTableAndCancelHUD
{
	NSIndexPath *ip;
	if(self.indexPaths!=nil&&[self.indexPaths count]>0)
		ip=(NSIndexPath *)[self.indexPaths objectAtIndex:0];
	self.indexPaths=[self.tableView indexPathsForVisibleRows]; //record the previous table row position
	
	[self.tableView reloadData];
	if(ip!=nil)
		[self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];

    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
}

- (void) addFriendCancelBarButtonPressed 
{     
	if([[WeiJuAppPrefs getSharedInstance] demo])
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
	else 
	{
		[Utils hideTabBar:NO For:self.tabBarController];
		self.viewType = nil;    
		[self.navigationController popToViewController:[WeiJuListVCtrl getSharedInstance] animated:NO];
	}
    
}

- (void) addFriendDoneBarButtonPressed 
{   
	if([[WeiJuAppPrefs getSharedInstance] demo])
	{
		//need to callback to pass the selected user info to delegate
		[self.navigationController popViewControllerAnimated:YES];		
	}
	else 
	{
		//add my userid
		[self.dictionary setObject:@"" forKey:[[WeiJuAppPrefs getSharedInstance] userId]];
		//NSLog(@"selected %@",[dictionary allKeys]);
		//NSLog(@"selected: %i",[[dictionary allKeys] count]);
		if([[self.dictionary allKeys] count] > 1){
			//ChatViewCtrl *chatViewController = [[ChatViewCtrl alloc] initWithNibName:@"ChatViewCtrl" weiJuData:nil inviteUserDictionary:self.dictionary];
			//[self.navigationController pushViewController:chatViewController animated:YES]; 
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"No friend is selected" delegate:self cancelButtonTitle:@"Dimiss" otherButtonTitles:nil];
			[alert show];
		}
	}
    
}

- (void) checkButtonTapped:(id)sender event:(id) event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    if (indexPath !=nil)
    {
        [self tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];       
    }
}

- (void) addFriendBarButtonPressed{
    
}

#pragma mark -
#pragma mark Search Bar Delegate Methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    //[self.tableView reloadData];
    //added Button click Event
    if(self.listOption.selectedSegmentIndex==0) //my friends
	{
       [DataFetchUtil saveButtonsEventRecord:@"w"];        
    }else {
       [DataFetchUtil saveButtonsEventRecord:@"15"]; 
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
   
    if ([@"" isEqualToString: self.searchBar.text]) {
        [Utils hideNavToolBar:NO For:self.navigationController];
    }else {
        [Utils hideNavToolBar:YES For:self.navigationController];
    }
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
   [Utils hideNavToolBar:NO For:self.navigationController];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
   
}

#pragma mark - FriendSelected protocol
- (void) friendSelected:(NSString *)friendID
{
	
	//1) scroll to that row
	//2) prompt for reminder sending - if yes, auto-fill the text
	
	if([[WeiJuAppPrefs getSharedInstance] demo])
	{
		/*
		switch (indexPath.row)
		{
			case 0:
				selectedName=@"C.A";
				break;
			case 1:
				selectedName=@"J.B";
				break;
			case 2:
				selectedName=@"K.C";
				break;
			case 3:
				selectedName=@"B.J";
				break;
			case 4:
				selectedName=@"D.K";
				break;
			case 5:
				selectedName=@"W.O";
				break;
			case 6:
				selectedName=@"M.Z";
				break;				
			default:
				break;
				
		}
		*/

	}
}
@end
