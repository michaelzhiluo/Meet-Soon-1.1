//
//  WeiJuPathShareVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuPathShareVCtrl.h"
#import "WeiJuListDCtrl.h"
#import "MapVCtrl.h"
#import "PathDCtrl.h"
#import "FriendsScrollVCtrl.h"
#import "DataFetchUtil.h"
#import "FriendData.h"
#import "Utils.h"
#import "CrumbPath.h"
#import "BridgeAnnotation.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuPathShareOptionVCtrl.h"
#import "PathShareHelperVCtrl.h"
#import "PopOverTexiViewReminder.h"
#import "MKMapView+Google.h"
#import "WeiJuParticipant.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuListDCtrl.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuNetWorkClient.h"
#import "ConvertData.h"
#import "WeiJuMessage.h"
#import "ChatDCtrl.h"
#import "Logging.h"
#import "MBProgressHUD.h"
#import "OperationQueue.h"
#import "OperationTask.h"
#import "WeiJuManagedObjectContext.h"
#import "FileOperationUtils.h"
#import "DESUtils.h"
#import "FriendsListDCtrl.h"

@interface WeiJuPathShareVCtrl ()

@end

@implementation WeiJuPathShareVCtrl

#define PATH_UPDATE_INTERVAL 60 //second, 1 minute
//#define PATH_UPDATE_DISTANCE 100 //meters 

const int MAX_ATTENDEES = 20;

#define FRIEND_BAR_HEIGHT 56
#define FRIEND_BAR_LEFT_MARGIN 34

//three ways/objectives for displaying user phonenumbers
#define ADDR_MODE_INVITE 0
#define ADDR_MODE_CALL 1
#define ADDR_MODE_MSG 2
#define ADDR_MODE_SELFIDENTIFY 3

@synthesize mapVCtrl, pathDCtrl, friendsScrollVCtrl, optionVCtrl, popoverCtrl, popoverReminder;

@synthesize demoMode, demoPathTimer, demoPathCount, demoMinTime, demoReplayAlert;

@synthesize hasSetUpP=_hasSetUpP, hasFailedAddr = _hasFailedAddr, hasBeenLoaded=_hasBeenLoaded, hasBeenShutdown=_hasBeenShutdown, isBeingDisplayed=_isBeingDisplayed, numberOfNewMessage=_numberOfNewMessage, numberOfSharings=_numberOfSharings;
@synthesize selfEvent=_selfEvent;
@synthesize isOrganizer=_isOrganizer;
@synthesize userActionCtrl;
@synthesize currentToolbarItems, locSwitch = _locSwitch, locSwitchBarBtn, pageCurlBarBtn;
@synthesize mySharingStatus, duration, autoOffTimer, progressTimer;
@synthesize progressViewContainer = _progressViewContainer;
@synthesize progressView = _progressView;
@synthesize progressLabel = _progressLabel, progressLabel_Min, progressLabel_Sec;
@synthesize progressViewText = _progressViewText;

@synthesize centerCoordinate=_centerCoordinate, latitudinalMeters=_latitudinalMeters, longitudinalMeters=_longitudinalMeters, initialCrumbs=_initialCrumbs, initialAnnotations=_initialAnnotations;

@synthesize prevCoordinate=_prevCoordinate, distanceTravelled=_distanceTravelled, lastAnnotationUpdateTime, lastLocationUpdateTime, cachedLocations;

@synthesize weiJuParticipants, foundMyself, mySelf, emailTobeValidated, emailVerificationCode, countOfUnregisteredParticipants, currentSelectedParticipantIndex, addrDisplayMode, allUserEmailString;

@synthesize addUserAlert, inviteUserAlert, selfIdentifyAlert;

static BOOL firstLaunch=YES; //display version alert only once for all PVC instances/not just this instance

#pragma mark - init data structures
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil event:(EKEvent *)ekevent center:(CLLocationCoordinate2D) centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations locSharing:(BOOL)onOrOff demoMode:(BOOL)demo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.selfEvent = ekevent;
		
		self.isOrganizer = NO;

		self.centerCoordinate = centerCoordinate;
		self.latitudinalMeters = latitudinalMeters;
		self.longitudinalMeters = longitudinalMeters;
		
		self.initialCrumbs = initialCrumbs;
		self.initialAnnotations = initialAnnotations;

		self.mySharingStatus = onOrOff;
		self.duration = [[WeiJuAppPrefs getSharedInstance] pathSharingDuration];
		
		self.weiJuParticipants = [[NSMutableArray alloc] init];
		
		self.demoMode=NO;
		self.demoPathCount=0;
		self.demoMinTime=10;
		
		self.hasSetUpP=NO;
		self.hasFailedAddr=YES;
		self.hasBeenLoaded=NO;
		self.hasBeenShutdown=NO;
		self.isBeingDisplayed=NO;
		self.hasBeenShutdown=NO;
		
		self.numberOfNewMessage=0;
		self.numberOfSharings=0;
		
		//NSLog(@"prevCoordinate: %f %f,", self.prevCoordinate.latitude, self.prevCoordinate.longitude);
		if(demo==NO)
		{
			if (ABAddressBookRequestAccessWithCompletion != NULL && ABAddressBookGetAuthorizationStatus()!=kABAuthorizationStatusAuthorized ) //ios6
			{
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(addressBookIsReady:)
															 name:@"AddrBookNotif" object:[FriendsListDCtrl getSharedInstance]];
				[[FriendsListDCtrl getSharedInstance] getAccessToAddr];
			}
		}
		else
			self.demoMode=YES;

    }
    return self;
}

- (void) addressBookIsReady:(NSNotification *)notification
{
	//note, this is executed on the thread that ABAddressBookRequestAccessWithCompletion is called, hence put it on mainthread, to ensure execution right away
	//execute only if setupparticipant has not run or has run but failed to get addr check); since the setuppariticipant run on main thread, this oen will run oly after the previous call on setupparticipants has started - self.hasSetUpP==YES
	if (self.hasBeenShutdown==NO && self.hasSetUpP==YES && self.hasFailedAddr)
		[self performSelectorOnMainThread:@selector(setUpParticipants:) withObject:[NSNumber numberWithInt:1] waitUntilDone:YES];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddrBookNotif" object:[FriendsListDCtrl getSharedInstance]];
	
}

- (void) shutDown:(int)mode //after shutdown: 0: show alert, 1: go back to weijulistv, 2: do nothing
{
	self.hasBeenShutdown=YES; //let others know as early as possible

	if(self.isBeingDisplayed) //we might be in the event's pvc view, sending it to bg, then activating the app again on the second day; or others deleted this event from the serevr
	{
		if(mode==0)
		{
			[Utils displaySmartAlertWithTitle:@"Event is no longer valid" message:@"This event has either passed its ending time or has been deleted from the calendar (by event organizer or yourself). Please tap on the top left arrow to go back to Calendar view" noLocalNotif:YES];
		}
		else if(mode==1)
		{ //go back to wjlistvctrl
			[self backToListView];
		}
	}

	if(self.locSwitch.on==YES) 
	{
		//turn off sharing
		self.locSwitch.on=NO;
		[self locSwitchChanged:self.locSwitch];
	}
	
	if(self.autoOffTimer!=nil && [self.autoOffTimer isValid])
		[self.autoOffTimer invalidate];
	self.autoOffTimer=nil;
	
	if(self.progressTimer!=nil && [self.progressTimer isValid])
		[self.progressTimer invalidate];
	self.progressTimer=nil;

	
	@synchronized(self.mapVCtrl) //prevent path update execution on the mapview at the same time
	{
		for (WeiJuParticipant *person in self.weiJuParticipants)
		{
			if(person.crumbPath!=nil)
			{
				[self.mapVCtrl removeOverlay:person.crumbPath];
				person.crumbPath=nil;
			}
			
			if(person.annotations!=nil)
			{
				[self.mapVCtrl removeAnnotations:person.annotations];
				person.annotations=nil;
			}
			
			if(person.sharingTimeOut!=nil)
				[person.sharingTimeOut invalidate];

		}
	
		[self.mapVCtrl.mapView removeFromSuperview];
		self.mapVCtrl.mapView = nil; //forece unload of mapview
		[self.mapVCtrl.view removeFromSuperview];
		self.mapVCtrl.view = nil;
		self.mapVCtrl = nil;
		self.pathDCtrl=nil;
		
		self.initialCrumbs = nil;
		self.initialAnnotations = nil;
		
		self.cachedLocations = nil;
		
		self.weiJuParticipants=nil;
		self.mySelf=nil;
		
		self.emailTobeValidated = nil;
		self.emailVerificationCode=nil;
		self.allUserEmailString = nil;

		//self.selfEvent=nil; //don't nil it, as the [[WeiJuListVCtrl getSharedInstance] deletePVC:self] need to use it
	}
	
	//unload various views
	self.currentToolbarItems=nil;
	self.locSwitchBarBtn=nil;
	self.pageCurlBarBtn=nil;
	[self setLocSwitch:nil];
	[self setProgressViewContainer:nil];
	[self setProgressViewText:nil];
	[self setProgressView:nil];
	[self setProgressLabel:nil];
	[self setUserActionCtrl:nil];

	self.friendsScrollVCtrl=nil;
	self.optionVCtrl=nil;
	self.popoverCtrl=nil;
	self.popoverReminder=nil;

	self.addUserAlert = nil;
	self.inviteUserAlert = nil;
	self.selfIdentifyAlert =nil;
	
	self.demoReplayAlert = nil;
	self.demoPathTimer = nil;
		
	[[WeiJuListVCtrl getSharedInstance] deletePVC:self];	
}

-(void) setUpParticipants:(NSNumber *) updateFlag
{
	self.hasSetUpP=YES; //hace started setup - work with the ios addrbook readiness notification
	
	BOOL updateOrNot=NO;
	if ([updateFlag intValue]==1)
		updateOrNot=YES;
	
	//NSLog(@"organizer: %@", self.selfEvent.organizer);
	//NSLog(@"attendees: %@", self.selfEvent.attendees);
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
		[Utils log:@"Enter event: Title:%@ %@ %d",self.selfEvent.title, self.selfEvent.eventIdentifier,self.selfEvent.calendar.type];
	else
		[Utils log:@"Enter ev: IID:%@ %d",self.selfEvent.eventIdentifier, self.selfEvent.calendar.type];
	
	if([self.selfEvent respondsToSelector:@selector(calendarItemExternalIdentifier)]) //ios6
		[Utils log:@"Ev EID:%@",self.selfEvent.calendarItemExternalIdentifier];

	NSMutableArray *people = [[NSMutableArray alloc] init];;  //[[NSMutableArray alloc] initWithArray:self.selfEvent.attendees];
	
	//add myself as orgnaizer; when others is organizer, it's already in attendees?? may not be true, in some event, the non-self orgnizer is not in attendees
	NSString *organizerEmailAddr;
	NSString *organizerURN;
	NSDictionary *foundEmailOrURNResult = [Utils getMyEmailFromEvent:self.selfEvent];
	if(foundEmailOrURNResult!=nil)
	{
		organizerEmailAddr = [foundEmailOrURNResult valueForKey:@"email"];
		organizerURN = [foundEmailOrURNResult valueForKey:@"urn"];
		//note, they both have () around them now, remove it
		if(organizerEmailAddr!=nil)
			organizerEmailAddr = [organizerEmailAddr substringWithRange:NSMakeRange(1, organizerEmailAddr.length-2)];
		if(organizerURN!=nil)
			organizerURN = [organizerURN substringWithRange:NSMakeRange(1, organizerURN.length-2)];
		
		if(organizerEmailAddr!=nil || organizerURN!=nil)
		{
			[people insertObject:self.selfEvent.organizer atIndex:0]; //when self is the organzer, it is not in the attendeed property, hence need to add it; however, it still may be in the attendees if we add invites from a self-only event - system will add self to both organizer and attendee, hence in the people loop, we need to check for such duplicates
		}

		if([foundEmailOrURNResult valueForKey:@"isOrganizer"]!=nil)
			self.isOrganizer=YES;

	}
	else {
		if(self.selfEvent.organizer!=nil) //non-self organizer
			[people insertObject:self.selfEvent.organizer atIndex:0]; //system will add non-self organizer to both organizer and attendee, hence in the people loop, we will need to check for such duplicates
		else 
			self.isOrganizer = YES;
	}
	
	//for (int i=0; i<MIN([self.selfEvent.attendees count], MAX_ATTENDEES); i++) //limit the total number of attendees
	//{
	//	[people addObject:[self.selfEvent.attendees objectAtIndex:i] ];
	//}
	int count = 1;
	for (EKParticipant *attendee in self.selfEvent.attendees) 
	{
		[people addObject:attendee];
		count++;
		if(count>MAX_ATTENDEES)
			break;
	}
	
	NSMutableArray *oldParticiantsList=nil;
	if(updateOrNot)
	{
		oldParticiantsList = [NSMutableArray arrayWithArray:self.weiJuParticipants];
		[oldParticiantsList removeLastObject];
		[oldParticiantsList removeObjectAtIndex:0];	
		[self.weiJuParticipants removeAllObjects];
	}
	
	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];

	NSString *ekdescription;
	NSURL *url;
	NSArray *friendDataResult;
	NSString *unregisteredEmails = @"";
	
	ABAddressBookRef addressBook = NULL;
	if([FriendsListDCtrl getSharedInstance].hasAcceessToAddr && [FriendsListDCtrl getSharedInstance].hasLoadedAddr)
		addressBook = [[FriendsListDCtrl getSharedInstance] getAddressBook]; //ABAddressBookCreate();
	if(addressBook)
		self.hasFailedAddr=NO;
	
	self.foundMyself=NO;
	self.mySelf=nil;
	self.countOfUnregisteredParticipants=0;
	
	for(int i=0;i<[people count];i++)
	{
		ekdescription = [(EKParticipant *)[people objectAtIndex:i] description];
		/*EKAttendee <0x232fa0> {UUID = A42B42BB-425A-4DF3-A0C1-DE9FD782EA80; name = Luo Michael; email = michael.luo@berkeley.edu; status = 2; role = 0; type = 1}*/
		url = ((EKParticipant *)[people objectAtIndex:i]).URL;
		
		//check for duplicates
		if([self foundDuplicate:url])
			continue;
		
		WeiJuParticipant *oldPerson=nil;
		if(updateOrNot==YES)
			oldPerson = [self foundInOldParticipantList:url List:oldParticiantsList];
		
		if(YES/*updateOrNot==NO || (updateOrNot==YES && oldPerson==nil)*/) //in ios6, there might be change in addrbook, hence even though we found old participants, we should recreate the participant
		{
			//NSLog(@"[url scheme]=%@", [url scheme]);
			if([url relativeString]!=nil/*[[url scheme] isEqualToString:@"mailto"] || [[url scheme] isEqualToString:@"urn"]*/)
			{
				WeiJuParticipant *person;
				if (updateOrNot==YES && oldPerson!=nil) //keep the old person properties such as sharing, new messages etc.
				{
					person = oldPerson;
					person.friendDataUserID=nil;
					person.friendData=nil;
					person.userImage=nil;
					person.hasABRecord=NO;
					
					[oldParticiantsList removeObject:oldPerson];
				}
				else
					person = [[WeiJuParticipant alloc] init];

				person.url = url;
				person.personDesp = [NSString stringWithString:ekdescription]; 
				
				person.fullName=((EKParticipant *)[people objectAtIndex:i]).name; //this is the name in the invitor's contact book
				
				if([[url scheme] isEqualToString:@"mailto"]) //it is email address
				{
					person.email = [[[url relativeString] substringFromIndex:[@"mailto:" length]] lowercaseString];
					if(i>0 && [person.email isEqualToString:organizerEmailAddr])
						continue; //organizer/attenndee duplicate 
					person.idType=1;
					person.urlString = [NSString stringWithString:person.email];
				}
				else/* if([[url scheme] isEqualToString:@"urn"])*/
				{
					person.URN = [[url relativeString] lowercaseString];
					if(i>0 && [person.URN isEqualToString:organizerURN])
						continue; //organizer/attenndee duplicate 
					person.idType=0;
					person.urlString = [NSString stringWithString:person.URN];
					
					//extract the URNEmail
					ekdescription = [ekdescription substringFromIndex:[ekdescription rangeOfString:@"{"].location];
					ekdescription = [ekdescription substringToIndex:[ekdescription rangeOfString:@"}"].location];
					NSRange emailStringRange = [ekdescription rangeOfString:@"email"];
					if(emailStringRange.location!=NSNotFound)
					{
						person.URNEmail = [ekdescription substringFromIndex:emailStringRange.location];
						person.URNEmail = (NSString *)[[person.URNEmail componentsSeparatedByString:@";"] objectAtIndex:0];
						person.URNEmail = [(NSString *)[[person.URNEmail componentsSeparatedByString:@" "] lastObject] lowercaseString];
						
						if(person.URNEmail!=nil && [person.URNEmail rangeOfString:@"@"].location==NSNotFound) //it is not a valid email address
							person.URNEmail=nil;
						
						person.email = person.URNEmail; //双保险
						person.urlString = person.URNEmail;
						if(i>0 && [person.URNEmail isEqualToString:organizerEmailAddr])
							continue; //organizer/attenndee duplicate 
					}
				}
				
				//when sending invitation from icloud to google, the organizer's email is changed into sth like: EKOrganizer <0x1d501170> {UUID = 7D485A81-7734-41CB-930B-F2F46A57E5C6; name = Luo Michael; email = 2_dmuzf42teyclb37lc4k6p57ndqqopnuf56o4ldg4ogp7spcidljwb3bbiam5c3n2huukpb3y4rhag@imip.me.com; isSelf = 0}; this is for invitee to respond properly back to icloud, not the original email registered with icloud; hence we need to exclude this organizer from the list (the true person is already in the attendee list)
				if([person.urlString rangeOfString:@"@imip.me"].location!=NSNotFound && [person.urlString rangeOfString:@"@imip.me"].location>10) //ensure it's not a real email address
					continue;

				//用email or URN找到frienddata
				if(person.idType==0) //URN
				{
					friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",person.URN]];
					if((friendDataResult==nil || [friendDataResult count]==0)&&person.URNEmail!=nil)
						friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",person.URNEmail]];
				}
				else
					friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",person.email]];
				
				if(friendDataResult!=nil && [friendDataResult count]>0)
				{
					person.friendData = [friendDataResult objectAtIndex:0];
					person.friendDataUserID = person.friendData.userId;
                    
					//person.friendData.lastMeetingTitle = [NSString stringWithString:self.selfEvent.title];
					person.friendData.lastMeetingDate =[NSDate dateWithTimeInterval:0 sinceDate:self.selfEvent.startDate];
					person.friendData.lastMeetingLocation = [[[Utils alloc] init] getEventProperty:self.selfEvent.location nilReplaceMent:@"Place unspecified"];
					if([person.fullName rangeOfString:@"@"].location!=NSNotFound && person.friendData.userName!=nil)
						person.fullName = person.friendData.userName; //if the user has defined his own name (usually not a full name, maybe just a nickname), and the event does not have its full name (only email address), use this one
					
					//decide to have event history for all events, not just pvc, hence comment out this one
                    //[[WeiJuListDCtrl getSharedInstance] setUploadEkEventCoreData:self.selfEvent]; //bug: for all particiapnts, this is called every time, not efficient, should called just once: - (void) add:(NSURL *)url event:(EKEvent *)event toTodayEventHistory:(NSMutableArray *)todayHistoryEventList with:(DataFetchUtil *)dataFetchUtil
					[[WeiJuListDCtrl getSharedInstance] add:person.url description:person.personDesp friendData:person.friendData event:self.selfEvent toTodayEventHistory:nil with:dataFetchUtil];
				}
				else
				{
                    if (self.countOfUnregisteredParticipants == 0) 
					{
                        if(person.idType==0&&person.URNEmail!=nil)
							unregisteredEmails = person.URNEmail; //don't use urn, since the user might register with email, then register with icloud to have urn, but haven't updated the server with its urn yet - hecne server doesn't recognize the urn
						else 
							unregisteredEmails = person.urlString;
                    }
					else {
                        if(person.idType==0&&person.URNEmail!=nil)
							unregisteredEmails = [unregisteredEmails stringByAppendingFormat:@",%@",person.URNEmail];
						else 
							unregisteredEmails = [unregisteredEmails stringByAppendingFormat:@",%@",person.urlString];
                    }
                    self.countOfUnregisteredParticipants++;
                }
				
				//用URL找到address book record
				if(addressBook)
				{
					ABRecordRef abr = [((EKParticipant *)[people objectAtIndex:i]) ABRecordWithAddressBook:addressBook];
					if(abr)
					{
						[self fillInAddressBookInfoFor:person fromAddrBookReference:abr];	//mainly for getting the phone numbers for this aprticipant, if found in addressbook
						//fullname is the name in "my" contact book
						
						//NSLog(@"abr %@", abr);
						//CFRelease(abr); //just can't release, probably because abr is not created from addressbook directly - it is from the ekparticipant method, it is not a copy, it's retained by the ekevent, can only released by the ekevent
						
					}//abr!=nil
				}
				
				if(person.friendDataUserID!=nil)
					[self hideFriendDataOrNot:person];
				
				if(person.fullName==nil)//very unlikely, since the user's email shall be used by event even if there is no fullname; but it happens: luowenlei@163.com has no name is ekparticipant, and if there is no frienddata nd abr, there is no fuullname
					person.fullName=person.email;
				
				if(person.fullName!=nil)
					person.displayName = [[self getFLFromFullName:person.fullName] capitalizedString];
				else
					person.displayName = @"N/A";  
				
				if(person.userImage==nil && person.friendDataUserID!=nil && person.friendData.userImageFileData!=nil)
					person.userImage = [UIImage imageWithData:person.friendData.userImageFileData];
				
				//determine whether this participant is myself
				if(self.foundMyself==NO && person.friendDataUserID!=nil && [person.friendDataUserID isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]])
				{
					self.foundMyself=YES;
					self.mySelf=person;
					person.displayName = @"Me";
					[self.weiJuParticipants insertObject:person atIndex:0];
				}
				else 
					[self.weiJuParticipants addObject:person]; //not self, add to the end
            
                
                if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
					[Utils log:@"#%d: id %@, fname:%@, dname:%@, email:%@, urn:%@ urnEmail:%@", i, person.friendDataUserID, person.fullName, person.displayName, person.email, person.URN, person.URNEmail];
				else 
					[Utils log:@"#%d: id %@", i, person.friendDataUserID];
                
               				
			}//url is valid
			
		}//if update==NO...
		/* //don't delete
		else if(updateOrNot==YES && oldPerson!=nil)
		{
			if(oldPerson.friendDataUserID!=nil && [oldPerson.friendDataUserID isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId] ])
			{
				self.foundMyself=YES;
				self.mySelf=oldPerson;
				[self.weiJuParticipants insertObject:oldPerson atIndex:0];
			}
			else 
				[self.weiJuParticipants addObject:oldPerson];
			
			[oldParticiantsList removeObject:oldPerson];
		}*/
		
	}//end of for
	
	//CFRelease(addressBook); //we are now using the FriendsListDCtrl addressbook, don't close it here
	
	//now go to the network to ask for frienddata info for unknown users, and their sharing status
	//decided no - ask server only when/before inviting a user to register 
		
	/* //decided dont do this smart now, still ask user to select and go thru the validation process
	//then check whether has found myself
	if(self.foundMyself==NO && self.countOfUnregisteredParticipants==1)
	{
		//that person must be me
		for (int i=0;i<[self.weiJuParticipants count]-1;i++) 
		{
			WeiJuParticipant *person = (WeiJuParticipant *)[self.weiJuParticipants objectAtIndex:i];
			if (person.friendDataUserID==nil) //found the only unregistered user
			{
				[self.weiJuParticipants removeObject:person];
				[self.weiJuParticipants insertObject:person atIndex:0];
				person.displayName=@"Me";
				
				person.friendData = [Utils addEmailOrURNToSelf:person];
				person.friendDataUserID = person.friendData.userId;
								
				self.foundMyself = YES;
				self.mySelf=person;
			}
		}
	}
	*/
	
	if(self.foundMyself==NO && self.selfEvent.organizer==nil) //event is initially created for just myself; even after adding an invitee, the organzier is still nil during the first eventstore notification (but it will be non-nil later for some reason with another notification from eventstore)
	{
		//add myself
		WeiJuParticipant *person = [[WeiJuParticipant alloc] init];
		person.displayName=@"Me";
		person.fullName=@"Me";
		person.friendDataUserID = [[WeiJuAppPrefs getSharedInstance] userId];
		person.friendData = [[WeiJuAppPrefs getSharedInstance] friendData];
		[self.weiJuParticipants insertObject:person atIndex:0];
		self.mySelf=person;
		self.foundMyself=YES;
	}
	
	if(self.foundMyself)
		[self createAllUserEmailString];
	
	[WeiJuManagedObjectContext save];

	[self addAllandAdd];
	
	if(updateOrNot==YES)
		[self.friendsScrollVCtrl updateFriendList:self.weiJuParticipants];
    
	if(self.countOfUnregisteredParticipants>0)
	{
		if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
			[Utils log:@"%s [line:%d] unregisteredEmails:%@",__FUNCTION__,__LINE__, unregisteredEmails];
		
		[[[WeiJuNetWorkClient alloc] init] syncMyData:unregisteredEmails syncUserIds:nil];//FriendsListDCtrl will call refreshParticipantColorStatus to change the color if user turns out to be registered user
	}
	
}

//called by FriendsListDCtrl after checking whether unregistered users are actually registered, dont delete
-(void) refreshParticipantColorStatus:(FriendData *)friendData setColor:(BOOL)setColor
{
	for (WeiJuParticipant *person in self.weiJuParticipants)
	{
		if (person.friendDataUserID != nil)
		   continue; //we are looking for unregisterd users that have been found to be registered this time
	   
	   //NSLog(@"~~~~~~%@ %@", friendData.userEmails, person.urlString);
	   
       if (person.isRealUser==YES && [friendData.userEmails rangeOfString:[@"" stringByAppendingFormat:@"(%@)",person.urlString]].location != NSNotFound) 
	   {
		   
           person.friendData = friendData;
           person.friendDataUserID = friendData.userId;
           
		   //person.friendData.lastMeetingTitle = [NSString stringWithString:self.selfEvent.title];
		   person.friendData.lastMeetingDate =[NSDate dateWithTimeInterval:0 sinceDate:self.selfEvent.startDate];
		   person.friendData.lastMeetingLocation = [[[Utils alloc] init] getEventProperty:self.selfEvent.location nilReplaceMent:@"Place unspecified"];
		   if(person.userImage!=nil)
		   {
			   person.friendData.userImageFileData = UIImagePNGRepresentation(person.userImage);
			   [WeiJuManagedObjectContext quickSave];
			   //[self.friendsScrollVCtrl setImageForFriend:person]; //no need since the image must have been set during init when the person.userimage was found
		   }
		   
		   [self hideFriendDataOrNot:person];
		   
		   //the following should be consisten with what we did in setupparticipants for fullname
           if([person.fullName rangeOfString:@"@"].location!=NSNotFound && person.friendData.userName!=nil)
		   {
			   person.fullName = person.friendData.userName; //if the user has defined his own name (usually not a full name, maybe just a nickname), and the event does not have its full name (only email address), use this one
			   person.displayName = [[self getFLFromFullName:person.fullName] capitalizedString];
			   [self.friendsScrollVCtrl setNameForFriend:person];
		   }
		   
           if (setColor) {
               [self.friendsScrollVCtrl setColorFor:person color:[UIColor yellowColor] exclusive:NO];
           }
		   
		   if(self.foundMyself)
			   [self createAllUserEmailString];
		   
		   [[WeiJuListDCtrl getSharedInstance] add:person.url description:person.personDesp friendData:person.friendData event:self.selfEvent toTodayEventHistory:nil with:nil]; //update eventhistory
           
       }
       
   }
   
}

-(void) addAllandAdd //all and add
{
	WeiJuParticipant *all = [[WeiJuParticipant alloc] init];
	all.isRealUser=NO;
	all.displayName=@"All";
	all.userImage = [UIImage imageNamed:@"group.png"];
	[self.weiJuParticipants insertObject:all atIndex:0];
	
	WeiJuParticipant *add = [[WeiJuParticipant alloc] init];
	add.isRealUser=NO;
	add.displayName=@"Add";
	add.userImage = [UIImage imageNamed:@"add.png"];
	[self.weiJuParticipants addObject:add];
}

//mainly for getting the phone numbers for this aprticipant, if found in addressbook
-(void) fillInAddressBookInfoFor:(WeiJuParticipant *)person fromAddrBookReference:(ABRecordRef) abr
{
	person.hasABRecord = YES;
	
	//if(person.fullName==nil || [person.fullName rangeOfString:@"@"].location!=NSNotFound )//fullname from event, or fullname is email (with @)
	//{
	//fullname from event is the name from the invitor's contact book, not necessarily the name from this user's contact book, hence this user's contact book should take precendence
	
		//update name
		CFStringRef cfn = ABRecordCopyValue(abr, kABPersonFirstNameProperty);
		NSString * firstName;
		if(cfn)
		{
			firstName = [NSString stringWithFormat:@"%@", cfn];
			CFRelease(cfn); //copy from abr, can be released
		}
		CFStringRef cln = ABRecordCopyValue(abr, kABPersonLastNameProperty);
		NSString * lastName;	
		if(cln)
		{
			lastName = [NSString stringWithFormat:@"%@", cln]; 
			CFRelease(cln);
		}
		
		if(lastName!=nil&&firstName!=nil)
		{
			//person.displayName=[ [firstName substringWithRange:NSMakeRange(0, 1)] stringByAppendingFormat:@".%@", [lastName substringWithRange:NSMakeRange(0, 1)] ];
			person.fullName = [firstName stringByAppendingFormat:@" %@", lastName];
			person.fullNameABR = person.fullName;
			person.fullNameABRNoCase = [[lastName stringByAppendingFormat:@" %@", firstName] lowercaseString];
			person.lastNameABR = lastName;
			person.firstNameABR = firstName;
		}
		else 
		{
			if(lastName!=nil)
			{
				person.fullName=lastName;
				person.fullNameABR = person.fullName;
				person.fullNameABRNoCase = [lastName lowercaseString];
				person.lastNameABR = lastName;
				person.firstNameABR = @"";
			}
			else if(firstName!=nil)
			{
				person.fullName=firstName;
				person.fullNameABR = person.fullName;
				person.fullNameABRNoCase = [firstName lowercaseString];
				person.lastNameABR = @"";
				person.firstNameABR = firstName;
			}
			else {
				NSString *emailAddr = person.email;
				if(person.email==nil)
					emailAddr = person.URNEmail;
				person.fullName=emailAddr;
				person.fullNameABR = emailAddr;
				person.fullNameABRNoCase = emailAddr;
				person.lastNameABR = emailAddr;
				person.firstNameABR = @"";
			}
		}
			
	//}
	
	person.fullNameABRNoCase = [person.fullNameABRNoCase stringByAppendingFormat:@"|%d", ABRecordGetRecordID(abr)];
	//NSLog(@"person.fullNameABRNoCase: %@", person.fullNameABRNoCase);
	
	person.phoneLabels = [[NSMutableArray alloc] init];
	person.phoneNumbers = [[NSMutableArray alloc] init];
	
	ABMutableMultiValueRef multi = ABRecordCopyValue(abr, kABPersonPhoneProperty);
	if(multi)
	{
		for(CFIndex x=0;x<ABMultiValueGetCount(multi);x++)
		{
			CFStringRef phoneNumber = ABMultiValueCopyValueAtIndex(multi, x);
			CFStringRef phoneLabel = ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(multi, x));
			//NSLog(@"%d: %@ %@", x, [@"Lable is " stringByAppendingFormat:@"%@",phoneLabel], phoneNumber);
			[person.phoneLabels addObject:[NSString stringWithFormat:@"%@",phoneLabel] ];
			[person.phoneNumbers addObject:[NSString stringWithFormat:@"%@",phoneNumber] ];
			
			if(phoneLabel)CFRelease(phoneLabel); //copy, can be released
			if(phoneNumber)CFRelease(phoneNumber);
		}
		CFRelease(multi); //a copy from abr, can be released
	}
	
    //读取照片
    if (ABPersonHasImageData(abr)){
        CFDataRef imageC = ABPersonCopyImageDataWithFormat(abr,kABPersonImageFormatThumbnail);//ABPersonCopyImageData(abr);
		if(imageC)
		{
			UIImage *addressVookImage = [UIImage imageWithData:(__bridge NSData*)imageC];
			person.userImage = [[[Utils alloc] init] rotateImage:addressVookImage orient:addressVookImage.imageOrientation]; //addressVookImage;
			
			if (person.friendData != nil) //store/update image into frienddata
			{
				person.friendData.userImageFileData = UIImagePNGRepresentation(person.userImage);
				[WeiJuManagedObjectContext quickSave];
			}
			
			CFRelease(imageC);
		}
    }
	else {
		//remove the image from frienddata since user has removed it from phonebook
		if (person.friendData != nil) //store/update image into frienddata
		{
            person.friendData.userImageFileData = nil;
            [WeiJuManagedObjectContext quickSave];
        }

	}
}

-(NSString *) getFLFromFullName:(NSString *)fullname
{
	//convert "Frank Li" into "F.L"
	NSArray *nameComps = [fullname componentsSeparatedByString:@" "];
	if([nameComps count]>1)
	{
		return [[(NSString *)[nameComps objectAtIndex:0] substringToIndex:1] stringByAppendingFormat:@".%@", [(NSString *)[nameComps objectAtIndex:1] substringToIndex:1]];
	}
	else //no space in name, limit the name to 3 characters, such as chinese name
		return [fullname substringToIndex:MIN(3, fullname.length)];
}

//prevent the duplicates in organizer and participants
-(BOOL) foundDuplicate:(NSURL *)url
{
	//NSLog(@"foundDuplicate: %@", self.weiJuParticipants);
	for (WeiJuParticipant *person in self.weiJuParticipants)
	{
		if(person.isRealUser)
		{
			if([person.url isEqual:url])
				return YES;
		}
	}
	
	return NO;
}

-(WeiJuParticipant *) foundInOldParticipantList:(NSURL *)url List:(NSMutableArray *)oldList
{
	for (WeiJuParticipant *person in oldList)
	{
		if([person.url isEqual:url]) //Two NSURLs are considered equal if and only if they return identical values for both baseURL (page 21) and relativeString (page 35).
		{
			return person;
		}
	}
	
	return nil;
}

//this is for creating the recipient string for weijumessage (path update message)
-(void) createAllUserEmailString
{
	@synchronized(self.allUserEmailString)
	{
		self.allUserEmailString=nil; //reset it
		
		for (WeiJuParticipant *person in self.weiJuParticipants)
		{
			if(person.isRealUser)
			{
				//if(person.friendDataUserID==nil || [person.friendDataUserID isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]==NO) //not self, or just use person!=self.myself
				if(person.friendDataUserID!=nil && [person.friendDataUserID isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]==NO) //not self, or just use person!=self.myself
				{
					if (self.allUserEmailString==nil)
					{
						if(person.email!=nil)
							self.allUserEmailString = [NSString stringWithString:person.email];
						else if(person.URNEmail!=nil)
							self.allUserEmailString = [NSString stringWithString:person.URNEmail];
						else 
							self.allUserEmailString = [NSString stringWithString:person.urlString]; //urlString is the last resort, because the other person might have registed with icloud later (using the same login email), and server doesn't know its urn yet
					}
					else
						if(person.email!=nil)
							self.allUserEmailString = [self.allUserEmailString stringByAppendingFormat:@",%@", person.email];
						else if(person.URNEmail!=nil)
							self.allUserEmailString = [self.allUserEmailString stringByAppendingFormat:@",%@", person.URNEmail];
						else 
							self.allUserEmailString = [self.allUserEmailString stringByAppendingFormat:@",%@", person.urlString];
				}
			}
		}
		
	}
	
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
		[Utils log:@"%s [line:%d]:\nAllUserEmail:%@",__FUNCTION__,__LINE__, self.allUserEmailString];
}

-(WeiJuParticipant *) weiJuParticipantForUserId:(NSString *)userId
{
	for (WeiJuParticipant *person in self.weiJuParticipants)
	{
		if(person.isRealUser)
		{
			if(person.friendDataUserID!=nil && [person.friendDataUserID isEqualToString:userId]==YES)
				return person;
		}
	}
	
	return nil;
}

//decide wehther to hide this frienddata in contact, and update/store the info onto server fpr recovery from logout 
-(void) hideFriendDataOrNot:(WeiJuParticipant *)person
{
	NSString *oldHide = person.friendData.hide;
	BOOL updateABR = NO;
	NSString *name=@"", *nameNoCase=@"", *firstName=@"", *lastName=@""; //@"" means server will ignore it
	if(person.hasABRecord) //in the contact book, thus set the hide to be NO
	{
		if(person.friendData.abRecordEmails==nil)
			person.friendData.abRecordEmails = @"";
		if([person.friendData.abRecordEmails rangeOfString:person.urlString].location==NSNotFound)
		{
			person.friendData.abRecordEmails = [person.friendData.abRecordEmails stringByAppendingFormat:@"(%@)", person.urlString]; //add the email/url to this property
			updateABR=YES;
		}
		
		person.friendData.hide=@"0";
		
		if(person.friendData.abRecordName==nil || [person.friendData.abRecordName isEqualToString:person.fullNameABR]==NO)
		{
			person.friendData.abRecordName = person.fullNameABR;
			name = person.fullNameABR;
			updateABR=YES;
		}
		if(person.friendData.abRecordNameNoCase==nil || [person.friendData.abRecordNameNoCase isEqualToString:person.fullNameABRNoCase]==NO)
		{
			person.friendData.abRecordNameNoCase = person.fullNameABRNoCase;
			nameNoCase = person.fullNameABRNoCase;
			updateABR=YES;
		}
		if(person.friendData.abRecordFirstName==nil || [person.friendData.abRecordFirstName isEqualToString:person.firstNameABR]==NO)
		{
			person.friendData.abRecordFirstName = person.firstNameABR;
			firstName = person.firstNameABR;
			updateABR=YES;
		}
		if(person.friendData.abRecordLastName==nil || [person.friendData.abRecordLastName isEqualToString:person.lastNameABR]==NO)
		{
			person.friendData.abRecordLastName = person.lastNameABR;
			lastName = person.lastNameABR;
			updateABR=YES;
		}
	}
	else
	{
		if(person.friendData.abRecordEmails!=nil) //first, delete this person's email from the record
		{
			NSRange emailRange = [person.friendData.abRecordEmails rangeOfString:[@"(" stringByAppendingFormat:@"%@)", person.urlString]];
			if(emailRange.location!=NSNotFound)
			{
				if(emailRange.location==0) //the first email string
				{
					person.friendData.abRecordEmails = [person.friendData.abRecordEmails substringFromIndex:emailRange.location+emailRange.length];
				}
				else {
					NSString *previous=[person.friendData.abRecordEmails substringToIndex:emailRange.location];
					NSString *after=[person.friendData.abRecordEmails substringFromIndex:emailRange.location+emailRange.length];
					person.friendData.abRecordEmails = [previous stringByAppendingString:after];
				}
			}
		}
		
		if(person.friendData.abRecordEmails!=nil && [person.friendData.abRecordEmails length]>2)
		{
			person.friendData.hide=@"0"; //there is an abr, but not found because not associated with this email/url; but this is a bug: delete the person from the contactbook, but this person will still show in registered, but with no name
		}
		else 
			person.friendData.hide=@"1";
	}
	
	if ([oldHide isEqualToString:person.friendData.hide]==NO || updateABR)
	{
		[[[Utils alloc] init] updateMyFriend:person.friendData.userId friendHidden:person.friendData.hide abRecordName:name abRecordFirstName:firstName abRecordLastName:lastName abRecordNameNoCase:nameNoCase abRecordEmails:person.friendData.abRecordEmails];
	}
}

-(MapVCtrl *)getMapVCtrl
{
    if (self.mapVCtrl == nil) 
	{
        self.mapVCtrl = [[MapVCtrl alloc] initWithNibName:@"MapVCtrl" bundle:nil rect:CGRectMake(0, FRIEND_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height-FRIEND_BAR_HEIGHT) center:self.centerCoordinate latDistance:self.latitudinalMeters longDistance:self.longitudinalMeters annotation:nil]; // crumbs:self.initialCrumbs annotations:self.initialAnnotations];
    }
    return self.mapVCtrl;
}

#pragma mark - view loading methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Do any additional setup after loading the view.
	self.title = @"All Status";

	self.navigationController.navigationBarHidden=YES;
	//self.navigationController.navigationBar.barStyle=UIBarStyleBlackTranslucent;
	[Utils hideNavToolBar:NO For:self.navigationController];
	self.navigationController.toolbar.barStyle=UIBarStyleDefault; //UIBarStyleBlack; //need to be ahead of bubbleVCtrl 
	self.navigationController.toolbar.translucent=NO; //dont make it transparent anymore, otherwise annotation might fall underneath it
	
	self.mapVCtrl = [self getMapVCtrl];
	
	[self.view addSubview:self.mapVCtrl.view];
	
	if(self.demoMode)
	{
		[self.mapVCtrl setMapViewRegionCenter:self.centerCoordinate latDistance:self.latitudinalMeters longDistance:self.longitudinalMeters];
		[self setUpDemoPath];
		[self.mapVCtrl addInitialOverLays:self.initialCrumbs initialAnnotations:self.initialAnnotations];
		[self startDemoAnimation];
		self.locSwitch.on=YES;
		[self locSwitchChanged:nil]; //pass nil as parameter to disable the alert view
	}
	
	//configure the top bar
	//create the background bars for the back button on the top nav bar
	UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, FRIEND_BAR_HEIGHT/2)];
	UIView *botBar = [[UIView alloc] initWithFrame:CGRectMake(0, FRIEND_BAR_HEIGHT/2, self.view.frame.size.width, FRIEND_BAR_HEIGHT/2)];
	topBar.backgroundColor=[UIColor blackColor];
	topBar.alpha = 0.5;
	botBar.backgroundColor=[UIColor blackColor];
	botBar.alpha = 0.55;
	[self.view addSubview:topBar];
	[self.view addSubview:botBar];
	
	UIButton *back=[UIButton buttonWithType:UIButtonTypeCustom];
	back.frame=CGRectMake(0, 0, FRIEND_BAR_LEFT_MARGIN, FRIEND_BAR_HEIGHT);
	back.backgroundColor=[UIColor clearColor];
	[back setImage:[UIImage imageNamed:@"arrow_left"] forState:UIControlStateNormal];
	[back addTarget:self action:@selector(backToListView) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:back];
	
	UIButton *info=[UIButton buttonWithType:UIButtonTypeInfoLight];
	info.frame=CGRectMake(self.view.frame.size.width-FRIEND_BAR_LEFT_MARGIN+10, 0, FRIEND_BAR_LEFT_MARGIN-10, FRIEND_BAR_HEIGHT);
	info.backgroundColor=[UIColor clearColor];
	//[back setImage:[UIImage imageNamed:@"arrow_left"] forState:UIControlStateNormal];
	[info addTarget:self action:@selector(helpInfo) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:info];
	
	self.friendsScrollVCtrl = [[FriendsScrollVCtrl alloc] initWithNibName:nil bundle:nil rect:CGRectMake(FRIEND_BAR_LEFT_MARGIN, 0, self.view.frame.size.width-2*FRIEND_BAR_LEFT_MARGIN, FRIEND_BAR_HEIGHT) mode:FRIEND_SCROLL_LIST_MODE_MAP friends:self.weiJuParticipants callBack:self];
	
	[self.view addSubview:self.friendsScrollVCtrl.view];
	
	//configure tool bar
	[self.locSwitch addTarget:self action:@selector(locSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	self.locSwitch.on = self.mySharingStatus;
	self.locSwitchBarBtn = [[UIBarButtonItem alloc] initWithCustomView:self.locSwitch];
	self.pageCurlBarBtn=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl target:self action:@selector(pageCurlUp)];
	self.progressViewText.text=@"Tap the switch to turn on my sharing, auto-off with timer";

	[self setUpToolBar]; //do it here, so that the pagecurl button is transparent
	
//	if (self.demoMode) {
//		[self setUpDemoABtn];
//	}
//	
//	//purely for test
//	[self setUpDemoBBtn];

	
    //现在,搜索message的coredata,重新显示crash之前的那些path
    NSArray *a = [[NSArray alloc] initWithObjects:[[NSSortDescriptor alloc] initWithKey:@"sendTime" ascending:YES],nil];
	NSArray *locationDataResult = [[[DataFetchUtil alloc] init] searchObjectArrayOrderby:@"WeiJuMessage" filterString:[@"messageContent like " stringByAppendingFormat:@"'*%@|*' and messageType = '11'",[[[self.selfEvent eventIdentifier] componentsSeparatedByString:@":"] objectAtIndex:1]] orderbyStrArray:a];
	
	for (WeiJuMessage *message in locationDataResult)
	{
		WeiJuParticipant *sender = [self weiJuParticipantForUserId:message.sendUser.userId];
		if(sender==nil)
			continue;
		
		//以下的代码,从chatdctrl复制过来
		NSArray *messageArr = [message.messageContent componentsSeparatedByString:@"|"];
		
		NSString *locaitonStr = [messageArr objectAtIndex:3];
		NSArray *locationArr = [locaitonStr componentsSeparatedByString:@"#"];
		
		for (int i=0; i<[locationArr count]; i++) 
		{
			NSString *locationBoth = [locationArr objectAtIndex:i];
			NSArray *locationBothArr = [locationBoth componentsSeparatedByString:@","];
			//NSLog(@"message=%@ %@, %@, %g",message.sendUser, message.sendTime, [NSDate date],[message.sendTime timeIntervalSinceDate:[NSDate date]]);
			if(i == ([locationArr count] -1))
			{
				BOOL turnStatusToGreenOrNot=NO;
				if([message.sendTime timeIntervalSinceNow]> -(PATH_UPDATE_INTERVAL+60.0))
					turnStatusToGreenOrNot=YES; //if the message was sent recently, change the sender status to green
				[self participant:sender locationChanged:CLLocationCoordinate2DMake([(NSString *)[locationBothArr objectAtIndex:0] doubleValue],[(NSString *)[locationBothArr objectAtIndex:1] doubleValue]) annotationSubTitle:(NSString *)[messageArr objectAtIndex:4] updateSenderStatus:turnStatusToGreenOrNot];
			}
			else {
				[self participant:sender locationChanged:CLLocationCoordinate2DMake([(NSString *)[locationBothArr objectAtIndex:0] doubleValue],[(NSString *)[locationBothArr objectAtIndex:1] doubleValue]) annotationSubTitle:nil updateSenderStatus:NO];
			}
		}//end of for
	}
	
	
	self.hasBeenLoaded = YES;
}

- (void)viewDidUnload
{
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	
	if(self.hasBeenShutdown==NO)
		[self shutDown:1]; //go back to weijulistvctrl
	
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PVC unload" 
														message:nil
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
	}
	else
		[Utils log:@"PVC viewDidUnload!"];
}
/*
- (void) didReceiveMemoryWarning
{
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PVC didReceiveMemoryWarning" 
														message:nil
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
	}
	else
		[Utils log:@"PVC didReceiveMemoryWarning!"];
	
	[super didReceiveMemoryWarning];
}
*/
-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];	

	self.navigationController.navigationBarHidden=YES;
	//self.navigationController.navigationBar.barStyle=UIBarStyleBlackTranslucent;
	[Utils hideNavToolBar:NO For:self.navigationController];
	self.navigationController.toolbar.barStyle=UIBarStyleDefault; //need to be ahead of bubbleVCtrl 
	//self.navigationController.toolbar.translucent=YES;
		
	//add popover if the loc sharing is off
	/*
	if(self.mySharingStatus==NO)
		[self addPopOverReminder:@"D.K. invites you to share your location" fromRect:CGRectNull];
	 */
	if (self.demoMode) {
		[self refreshBadgeAndReset:NO];//turn on the red dots
		[self.mapVCtrl zoomMapViewToFitAnnotations];
	}
	
	if(self.numberOfNewMessage>0)
	{
		//[self refreshBadgeAndReset:NO];//turn on the red dots: no need to do it here, will do it in viewdidappear
		
		self.numberOfNewMessage=0;//clear the flag, since we have entered the event, we assume all msg are read now
		//[[WeiJuListVCtrl getSharedInstance].tableView reloadData]; //remove the reddot - no need to do this, will do so in viewWillDisappear
	}
}

-(void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

    if(self.demoMode)
	{
        [DataFetchUtil saveButtonsEventRecord:@"30"];
    }else{
        [DataFetchUtil saveButtonsEventRecord:@"43"];
    }
	
	self.navigationController.navigationBarHidden=NO; //since we hide the nav bar, we need to restore it for other views
	
	self.numberOfNewMessage=0; //in background mode, this counter will also been incremented 
	//if(self.numberOfSharings>0)
	[[WeiJuListVCtrl getSharedInstance].tableView reloadData]; //display the map, or undisplay the map
	
	[self refreshBadgeAndReset:YES];//turn off the red dots
	
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	//[self relocateGoogleLogo]; //can't be in willAppear, has to be here to work; no need to do this anymore, as we don't do transparent toolbar anymore
	
	//then check whether has found myself
	if(self.foundMyself==NO && self.emailTobeValidated==nil) //here, countOfUnregisteredParticipants>1
	{
		//if self.emailTobeValidated!=nil, it means the validation process is ongoing - no need to prompt again
		[self promptForSelfIdentification];
	}
	else
	{
		if(self.demoMode==NO)
		{
			if(firstLaunch)
			{
				firstLaunch = NO;				
				[[Utils getSharedInstance] alertNewVerson:NO alertProtocolVersion:YES];
			}
			//else {
				//update the UI if neccesary: right now it is mainly the user image that might have changed
			for (WeiJuParticipant *person in self.weiJuParticipants)
			{
				if (person.isRealUser && person.friendDataUserID != nil)
				{
					if(person.userImage==nil && person.friendData.userImageFileData!=nil) //might have found new image from friendlistvctrl's cellforrow
					{
						person.userImage = [UIImage imageWithData:person.friendData.userImageFileData];
						[self.friendsScrollVCtrl setImageForFriend:person];
					}
					
					if(person.isRealUser && person.newMsg>0)
						[self.friendsScrollVCtrl setBadgeForFriend:person];
				}
			}
			//}
			
			if(self.mapVCtrl!=nil && self.mapVCtrl.lastAnnotation!=nil) //center the map around the last coord, and the annotation
			{
				[self.mapVCtrl setMapViewRegionCenter:[self.mapVCtrl.lastAnnotation coordinate]];
				[self.mapVCtrl.mapView selectAnnotation:self.mapVCtrl.lastAnnotation animated:YES]; //maynot work for the pvc's first launch, maybe because mapview is not displayed yet
			}
		}
	}
	
	self.isBeingDisplayed=YES;
}

- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	self.isBeingDisplayed=NO;
}

//move the google logo above the bottom toolbar
- (void)relocateGoogleLogo {
	UIImageView *logo = [self.mapVCtrl.mapView googleLogo];
	if (logo == nil)
		return;
	CGRect frame = logo.frame;
	//frame.origin.y = self.navigationController.toolbar.frame.origin.y - frame.size.height - frame.origin.x;
	frame.origin.y = frame.origin.y - self.navigationController.toolbar.frame.size.height;
	logo.frame = frame;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - FriendSelected protocol
-(void) refreshBadgeAndReset:(BOOL)reset
{
	for (WeiJuParticipant *person in self.weiJuParticipants)
	{
		if(person.isRealUser)
		{
			if(reset)
				person.newMsg=0;
			[self.friendsScrollVCtrl setBadgeForFriend:person];
		}
	}
	
}

- (void) friendSelected:(WeiJuParticipant *)friend
{
	self.currentSelectedParticipantIndex = [self.weiJuParticipants indexOfObject:friend];
	
	if(self.currentSelectedParticipantIndex==0) //tap on all
	{
        if(self.demoMode)
		{
           [DataFetchUtil saveButtonsEventRecord:@"31"];
        }else{
           [DataFetchUtil saveButtonsEventRecord:@"44"]; 
        }
        
		[self.mapVCtrl zoomMapViewToFitAnnotations];
		return;
	}
	
	if (self.currentSelectedParticipantIndex==[self.weiJuParticipants count]-1) { //add
		if(self.demoMode)
		{
            [DataFetchUtil saveButtonsEventRecord:@"33"];

			self.addUserAlert = [[UIAlertView alloc] initWithTitle:@"Demo mode - can not add participants" 
														   message:nil
														  delegate:self 
												 cancelButtonTitle:@"Dismiss" 
												 otherButtonTitles:nil];
			[self.addUserAlert show];
			
		}
		else 
		{
            [DataFetchUtil saveButtonsEventRecord:@"46"];
			
			if(self.foundMyself==NO)
			{
				[self promptForSelfIdentification];
				return;
			}
			//NSLog(@"self.selfEvent.calendar.type=%d", self.selfEvent.calendar.type);
			if(self.selfEvent.calendar.type!=EKCalendarTypeCalDAV && self.selfEvent.calendar.type!=EKCalendarTypeExchange)
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Important Notice!" message:nil delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
				if([WeiJuListDCtrl getSharedInstance].hasServerBasedCalendar==NO)
					alert.message = NSLocalizedString(@"NO_SERVER_CAL_MSG", nil);
				else 
					alert.message = @"This event belongs to a local calendar, hence you can't add invitees to it and can't share path with one another. You can share path only within a server based calendar event.\n\nNote that iCloud and Exchange Calendars are preferred, because Google Calendar doesn't allow users to add/edit invitees directly on iPhone";
				[alert show];
				return;
			}
			
			if(self.isOrganizer)
			{
				//display alert to tell user how to add invitees
				self.addUserAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ADD_INVITEE_TITLE", nil) 
														   message:NSLocalizedString(@"ADD_INVITEE_MSG", nil)
														  delegate:self 
												 cancelButtonTitle:@"Dismiss" 
												 otherButtonTitles:@"Continue",nil];
				[self.addUserAlert show];
			}
			else 
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You are not the organizer of this event, hence can't add/remove invitees" 
															   message:nil
															  delegate:self 
													 cancelButtonTitle:@"Dismiss" 
													 otherButtonTitles:nil];
				[alert show];
			}
		}
		return;
	}
	
	//press any person's icon, means, we don't want to keep shifting map center around self location - no need to do this now, since the map only center around self once in mapvctrl
	//self.mapVCtrl.centerMapOnSelfLocation=NO;
	
	if (self.currentSelectedParticipantIndex==1 && self.foundMyself/* friend.friendDataUserID!=nil && [friend.friendDataUserID isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]*/) 
	{	//me - 我自己!!!!
        
        if(self.demoMode)
		{
            [DataFetchUtil saveButtonsEventRecord:@"32"];
			[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord latDistance:1000 longDistance:1000];
			[self.mapVCtrl selectAnnotation:[friend.annotations lastObject]];
			
        }else
		{
            [DataFetchUtil saveButtonsEventRecord:@"45"]; 
			[self.mapVCtrl centerSelfLocation];
        }
        
		return;
	}
	
	//tap on a real user (other than me)
	if(friend.newMsg>0) //turn off red dot
	{
		friend.newMsg=0;
		[self.friendsScrollVCtrl setBadgeForFriend:friend];
	}
	
	if(self.demoMode)
	{
        [DataFetchUtil saveButtonsEventRecord:@"34"]; 
        
		if(self.currentSelectedParticipantIndex==1) //me
		{
			[self.mapVCtrl centerSelfLocation];
		}
		else if(self.currentSelectedParticipantIndex==2) //T.E
		{
			//[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord];
			[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord latDistance:1000 longDistance:1000];
			[self.mapVCtrl selectAnnotation:[friend.annotations lastObject]];			
		}
		else if(self.currentSelectedParticipantIndex==3) //J.S
		{
			//[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord];
			[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord latDistance:1000 longDistance:1000];
			[self.mapVCtrl selectAnnotation:[friend.annotations lastObject]];
		}
		else {
			self.inviteUserAlert = [[UIAlertView alloc] initWithTitle:@"Kate Perry" 
															message:@"is not sharing path"
														   delegate:self 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:@"Invite to share", nil];
			[self.inviteUserAlert show];
		}
	}
	else //not demo
	{
        [DataFetchUtil saveButtonsEventRecord:@"47"];
		
		//now we know a real user (can not be me) is tapped on
		if(self.foundMyself==NO)
		{
			[self promptForSelfIdentification];
			return;
		}
		
		if(friend.isSharing==NO) 
		{ 
			//unregistered user, or registered user not sharing
			if(friend.friendDataUserID==nil && self.emailTobeValidated!=nil && ([self.emailTobeValidated isEqualToString:friend.URNEmail]||[self.emailTobeValidated isEqualToString:friend.email]))
				return; //this user may be me and its email is being validated
			else 
			{
				if(friend.friendDataUserID!=nil) //registered user, not sharing, send invite 
				{
					//center the map around this person's last annnotation!!
					[self centerAroundHisLastCoord:friend];
					
					self.inviteUserAlert = [[UIAlertView alloc] initWithTitle:friend.fullName 
																	  message:@"is currently not sharing path"
																	 delegate:self 
															cancelButtonTitle:@"Dismiss" 
															otherButtonTitles:@"Invite to share", nil];
					[self.inviteUserAlert show];
					
				}
				else 
				{ //unregistered user
					//sync the other user's freinddata from server (since he might have registered, and it is just that this user doesn't know yet					
					MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
					hud.labelText = @"Checking registration status";
					
					NSMutableDictionary *dic = [NSMutableDictionary dictionary];
					[dic setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs userId] forKey:@"userId"];
					if (friend.idType==0&&friend.URNEmail!=nil)
						[dic setObject:friend.URNEmail forKey:@"userEmails"];	
					else 
						[dic setObject:friend.urlString forKey:@"userEmails"];
					[[[WeiJuNetWorkClient alloc] init] requestData:@"userFriendsAction.syncClientData" parameters:dic withObject:friend callbackInstance:self callbackMethod:@"checkUserResgisterStatusCallBack:"];
				}			}
		}
		else {
			//center the map around this person's last annnotation!!
			[self centerAroundHisLastCoord:friend];
		}
	}
}
					   
- (void) centerAroundHisLastCoord:(WeiJuParticipant *)friend
{
	if(CLLocationCoordinate2DIsValid(friend.lastCoord))
	{
		[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord];
		//[self.mapVCtrl setMapViewRegionCenter:friend.lastCoord latDistance:1000 longDistance:1000];
		[self.mapVCtrl selectAnnotation:[friend.annotations lastObject]];
	}
	
}

-(void) friendLongPressed:(WeiJuParticipant *) friend
{
	self.currentSelectedParticipantIndex = [self.weiJuParticipants indexOfObject:friend];

	if(self.currentSelectedParticipantIndex>0 && self.currentSelectedParticipantIndex< [self.weiJuParticipants count]-1) //not ALL/ADD
	{
		if(self.foundMyself==NO || self.currentSelectedParticipantIndex>1) //not ME
			[self displayUserActionBar];
	}

}

-(void) displayUserActionBar
{	
	if (self.userActionCtrl==nil) {
		self.userActionCtrl = [[UIView alloc] initWithFrame:CGRectMake(FRIEND_BAR_LEFT_MARGIN, FRIEND_BAR_HEIGHT+2, self.view.frame.size.width-2*FRIEND_BAR_LEFT_MARGIN, 40)];
		//self.userActionCtrl.backgroundColor=[UIColor blackColor];
		self.userActionCtrl.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		//self.userActionCtrl.alpha=0.5;
		self.userActionCtrl.hidden=YES;
		
		UIButton *dismissBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		dismissBtn.backgroundColor=[UIColor clearColor];
		dismissBtn.frame = CGRectMake(self.userActionCtrl.frame.size.width-40, 0, 40, self.userActionCtrl.frame.size.height);
		dismissBtn.layer.borderWidth=0.5;
		[dismissBtn addTarget:self action:@selector(dismissUserActionCtrl) forControlEvents:UIControlEventTouchUpInside];
		[dismissBtn setImage:[UIImage imageNamed:@"delete-icon-8"] forState:UIControlStateNormal];
		[self.userActionCtrl addSubview:dismissBtn];
		
		[self.view addSubview:self.userActionCtrl];
		
		UIButton *routeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		routeBtn.backgroundColor=[UIColor clearColor];
		routeBtn.frame = CGRectMake(0, 0, (self.userActionCtrl.frame.size.width-40)/3, self.userActionCtrl.frame.size.height);
		routeBtn.tag = 10;
		routeBtn.layer.borderWidth=0.5;
		[routeBtn addTarget:self action:@selector(routeToUserActionCtrl) forControlEvents:UIControlEventTouchUpInside];
		[routeBtn setTitle:@"Route" forState:UIControlStateNormal];
		routeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
		[self.userActionCtrl addSubview:routeBtn];

		UIButton *callBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		callBtn.backgroundColor=[UIColor clearColor];
		callBtn.frame = CGRectMake((self.userActionCtrl.frame.size.width-40)/3, 0, (self.userActionCtrl.frame.size.width-40)/3, self.userActionCtrl.frame.size.height);
		callBtn.tag = 11;
		callBtn.layer.borderWidth=0.5;
		[callBtn addTarget:self action:@selector(callUserActionCtrl) forControlEvents:UIControlEventTouchUpInside];
		[callBtn setTitle:@"Call" forState:UIControlStateNormal];
		callBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
		[self.userActionCtrl addSubview:callBtn];
	
		UIButton *msgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		msgBtn.backgroundColor=[UIColor clearColor];
		msgBtn.frame = CGRectMake((self.userActionCtrl.frame.size.width-40)/3*2, 0, (self.userActionCtrl.frame.size.width-40)/3, self.userActionCtrl.frame.size.height);
		msgBtn.tag = 12;
		msgBtn.layer.borderWidth=0.5;
		[msgBtn addTarget:self action:@selector(messageUserActionCtrl) forControlEvents:UIControlEventTouchUpInside];
		[msgBtn setTitle:@"Message" forState:UIControlStateNormal];
		msgBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
		[self.userActionCtrl addSubview:msgBtn];

	}
	
	self.userActionCtrl.hidden=NO;
}

-(void) dismissUserActionCtrl
{
	self.userActionCtrl.hidden=YES;
}

-(void) routeToUserActionCtrl
{
	
}

-(void) callUserActionCtrl
{
	self.addrDisplayMode=ADDR_MODE_CALL;	
}

-(void) messageUserActionCtrl
{
	WeiJuParticipant *friend = (WeiJuParticipant *) [self.weiJuParticipants objectAtIndex:self.currentSelectedParticipantIndex];
	
	self.addrDisplayMode=ADDR_MODE_MSG;
	[self promptForAddrSelection:friend];

}

-(void) promptForSelfIdentification
{
	self.addrDisplayMode = ADDR_MODE_SELFIDENTIFY;
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Your sign in email does not match any of the event attendees' emails. Please choose your email in this event before sharing your path or receiving others' sharing. You will receive an email to that address with a validation code. Input the code in the next screen." delegate:self cancelButtonTitle:@"Dismiss" destructiveButtonTitle:nil otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	for (WeiJuParticipant *person in self.weiJuParticipants)
	{
		if (person.isRealUser && person.friendDataUserID==nil)
		{ //found non-registered user, hence may be myself
			if(person.idType==0) //urn
			{
				if(person.URNEmail!=nil && [person.URNEmail rangeOfString:@"@"].location!=NSNotFound) //just in case, urmemail is not retrieved
					[actionSheet addButtonWithTitle:person.URNEmail];
			}
			else //email
				[actionSheet addButtonWithTitle:person.email];
		}
	}
	
	if(actionSheet.numberOfButtons>1) //not just the cancel button
		[actionSheet showFromToolbar:self.navigationController.toolbar];
	else //what if the numofbuttons==1: all users are egisered users, it means this user is using other's calendar. the event doens't have him as attendee
		[Utils displaySmartAlertWithTitle:@"Warning" message:@"Your sign in email does not match any of the event attendees' emails. You won't be able to share with others in this event.\n\nYou might be using a calendar of which the associated email belongs to another registered account. Please try signing in from that account, or go to \"Settings\" to email customer support." noLocalNotif:YES];
}

-(void) promptForAddrSelection:(WeiJuParticipant *)friend
{
	//[DataFetchUtil saveButtonsEventRecord:@"2b"];
	NSString *msg;
	
	if(self.addrDisplayMode==ADDR_MODE_INVITE)
		msg=[friend.fullName stringByAppendingString:@" is not a registered user; choose the SMS/Email address to invite him/her to join"];
	else if(self.addrDisplayMode==ADDR_MODE_MSG)
		msg=[@"Choose how to message " stringByAppendingString:friend.fullName];
	else if(self.addrDisplayMode==ADDR_MODE_CALL) 
		msg=[@"Choose the number to call " stringByAppendingString:friend.fullName];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:@"Dismiss" destructiveButtonTitle:nil otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	if(friend.phoneNumbers!=nil)
	{
		for (int i=0; i<[friend.phoneNumbers count]; i++) //phonenumbers can be null
		{
			[actionSheet addButtonWithTitle:[(NSString *)[friend.phoneLabels objectAtIndex:i] stringByAppendingFormat:@": %@", [friend.phoneNumbers objectAtIndex:i]] ];
		}
	}
	
	if (self.addrDisplayMode!=ADDR_MODE_CALL) 
	{
		[actionSheet addButtonWithTitle:@"Manually input phone number"];
		if(friend.email!=nil)
			[actionSheet addButtonWithTitle:friend.email];
		else if(friend.URNEmail!=nil)
			[actionSheet addButtonWithTitle:friend.URNEmail]; //dont add urn here!
	}
	
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//add
	if(alertView==self.addUserAlert)
	{
		if(buttonIndex==1)
		{
			[DataFetchUtil saveButtonsEventRecord:@"1y"];
			EKEventEditViewController  *evc = [[EKEventEditViewController alloc] init];
			evc.editViewDelegate=self;
			evc.event=self.selfEvent;
			evc.eventStore=[WeiJuListDCtrl getSharedInstance].eventStore;
			[self.navigationController presentViewController:evc animated:YES completion:nil];
		}
	}
	else if(alertView==self.selfIdentifyAlert)
	{
		if(buttonIndex==self.selfIdentifyAlert.firstOtherButtonIndex) //user has input the verification code, and tap "next" - want to submit to server to validate
		{
			if ([self.emailVerificationCode isEqualToString:[self.selfIdentifyAlert textFieldAtIndex:0].text]==NO) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Verification code doesn't match" 
																message:nil
															   delegate:nil 
													  cancelButtonTitle:@"Dismiss" 
													  otherButtonTitles:nil];
				[alert show];
			}
			else { //submit to server to update frienddata, which will sync the local frienddata as well
				[DataFetchUtil saveButtonsEventRecord:@"1z"];
				MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
				hud.labelText = @"Updating account properties.";
				
				[[[Utils alloc] init] requestServerToAddEmail:self.emailTobeValidated callBack:self alertForFailure:YES];
			}
		}else{
            [DataFetchUtil saveButtonsEventRecord:@"92"];
        }
	}
	else if(alertView==self.inviteUserAlert)
	{
		if(buttonIndex==1) 
		{
			WeiJuParticipant *friend = (WeiJuParticipant *) [self.weiJuParticipants objectAtIndex:self.currentSelectedParticipantIndex];
			
			if(friend.friendDataUserID!=nil) //the other side is weiju registered user, send invitation here
			{
				[DataFetchUtil saveButtonsEventRecord:@"2a"];
				[Utils inviteFriend:friend toSharePathForEvent:self.selfEvent from:self.mySelf];
			}
			else 
			{ //unregistered user, need to send invite to join
				if(self.demoMode)
				{
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo only - invitation not sent" 
																	message:nil
																   delegate:nil 
														  cancelButtonTitle:@"Dismiss" 
														  otherButtonTitles:nil];
					[alert show];
				}
				/* moved this portion to friendselected: no need to present an alert for unregistered userelse 
				{
					//sync the other user's freinddata from server (since he might have registered, and it is just that this user doesn't know yet)
					[alertView dismissWithClickedButtonIndex:buttonIndex animated:NO];

					MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
					hud.labelText = @"Checking friend's registration status...";

					NSMutableDictionary *dic = [NSMutableDictionary dictionary];
					[dic setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs userId] forKey:@"userId"];
					[dic setObject:friend.urlString forKey:@"userEmails"];
					[[[WeiJuNetWorkClient alloc] init] requestData:@"userFriendsAction.syncClientData" parameters:dic withObject:friend callbackInstance:self callbackMethod:@"checkUserResgisterStatusCallBack:"];
					
				}
				*/
			}
			
		}
	}//inviteUserAlert
	else if(alertView==self.demoReplayAlert)
	{
		if(buttonIndex==1) 
		{
			//clear up the path: we don't support it yet
			//[self rewindDemoPath];
			//[self startDemoAnimation];
		}
	}
}

//The receiver is automatically dismissed after this method is invoked
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	
	if(buttonIndex!=0) //dismiss?
	{
		WeiJuParticipant *friend = (WeiJuParticipant *) [self.weiJuParticipants objectAtIndex:self.currentSelectedParticipantIndex];
		if(self.addrDisplayMode==ADDR_MODE_CALL)
		{
			//[friend.phoneNumbers objectAtIndex:buttonIndex-1]
			
		}
		else if(self.addrDisplayMode==ADDR_MODE_MSG||self.addrDisplayMode==ADDR_MODE_INVITE)
		{
			//record how many times the user has tell others to join; can also limit the invites here to be less than 5? for paid users?
			//[[WeiJuAppPrefs getSharedInstance] friendData].tellFriends++;
			NSArray *recipients;
			if(buttonIndex<=[friend.phoneNumbers count] || buttonIndex==actionSheet.numberOfButtons-2) //phone numbers
			{
                [DataFetchUtil saveButtonsEventRecord:@"82"];
				if(buttonIndex!=actionSheet.numberOfButtons-2)
					recipients = [NSArray arrayWithObjects:[friend.phoneNumbers objectAtIndex:buttonIndex-1], nil];
				[Utils sendReferral:self to:recipients viaMedium:0];
			}
			else
			{
                [DataFetchUtil saveButtonsEventRecord:@"84"];
				//email address
				if(friend.email!=nil)
					recipients = [NSArray arrayWithObject:friend.email];
				else if(friend.URNEmail!=nil)
					recipients = [NSArray arrayWithObject:friend.URNEmail];
				
				[Utils sendReferral:self to:recipients viaMedium:1];
			}
		}//MSG or INVITE
		else if(self.addrDisplayMode == ADDR_MODE_SELFIDENTIFY) 
		{
            [DataFetchUtil saveButtonsEventRecord:@"90"];
			self.emailTobeValidated = [actionSheet  buttonTitleAtIndex:buttonIndex];
			/*
			self.selfIdentifyAlert = [[UIAlertView alloc] initWithTitle:[@"You have selected " stringByAppendingFormat:@"\"%@\"", self.emailTobeValidated]
														   message:@"Tap \"Submit\" to have our server to send a validation email to this email address. Click on the link in that email to go to the validation page in your browser, and input 33 as validation code to activate this email in your account"
														  delegate:self 
												 cancelButtonTitle:@"Dismiss" 
												 otherButtonTitles:@"Submit", nil];
			
			[self.selfIdentifyAlert show];
			 */
			MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
			hud.labelText = @"Submitting to server";
			
			//submit the email validation request to server
			FileOperationUtils *fileOperationUtils = [[FileOperationUtils alloc] init];
			self.emailVerificationCode = [fileOperationUtils randomNumber:4];
			NSString *vcode= [DESUtils encryptUseDESDefaultKey:self.emailVerificationCode];
			//NSLog(@"self.emailVerificationCode = %@", self.emailVerificationCode);
			[Utils requestServerToValidateEmail:self.emailTobeValidated withCode:vcode callBack:self];
		}
	}
	else //buttonindex==0
	{
        if(self.addrDisplayMode == ADDR_MODE_SELFIDENTIFY){
            [DataFetchUtil saveButtonsEventRecord:@"89"];
        }else{
            [DataFetchUtil saveButtonsEventRecord:@"81"];
        }
    }
}

#pragma mark - callbacks from server
-(void) createEmailBindingCallBack:(NSDictionary *)dic
{
	@try{
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
	}
    @catch(NSException *e){
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [e userInfo], [e reason]];
    }
	
	if (![ConvertData getErrorInfo:dic])
	{
		//success
		self.selfIdentifyAlert = [[UIAlertView alloc] initWithTitle:self.emailTobeValidated/*[@"You have submitted " stringByAppendingFormat:@"\"%@\"", self.emailTobeValidated]*/
															message:@"Get the verification code from the email and input here"
														   delegate:self 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:@"Next", nil];
		self.selfIdentifyAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
		[self.selfIdentifyAlert show];

		/*
		for (int i=0;i<[self.weiJuParticipants count]-1;i++) 
		{
			WeiJuParticipant *person = (WeiJuParticipant *)[self.weiJuParticipants objectAtIndex:i];
			
			if(person.isRealUser==NO)
				continue;

			if ([person.email isEqualToString:self.emailTobeValidated]||[person.URNEmail isEqualToString:self.emailTobeValidated])
			{
				[self.weiJuParticipants removeObject:person];
				[self.weiJuParticipants insertObject:person atIndex:0];
				person.displayName=@"Me";
				
				person.friendData = [Utils addEmailOrURNToSelf:person];
				
				person.friendDataUserID = person.friendData.userId;
				
				self.foundMyself = YES;
				self.mySelf=person;
				self.emailTobeValidated = nil;
			}
		}
		
		//what about update the scrollv, and other users????
		
		if(self.foundMyself)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.emailTobeValidated stringByAppendingString:@" has been successfully added to your account"]
															message:nil
														   delegate:nil 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
			[alert show];
		}
		*/
		
	}else{
		//error: 有邮箱已经关联了
		self.emailTobeValidated = nil;

		NSString *error = [ConvertData getValue:dic key:@"error"];
		[Utils log:@"%s [line:%d] error:%@",__FUNCTION__,__LINE__, error];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.emailTobeValidated stringByAppendingFormat:@"%@",@" can not be added to your account"]
														message:error
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
	}
}

-(void) uploadSelfEmailsCallBack:(NSDictionary *)dic
{
    @try{
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
	}
    @catch(NSException *e){
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [e userInfo], [e reason]];
    }

	if (![ConvertData getErrorInfo:dic])
	{
		//upload success
		
		[[[ConvertData alloc] init] syncCoreDataWithNetDictionaryWithoutInitData:dic]; //sync local and server friedndata
		
		for (WeiJuParticipant *person in self.weiJuParticipants)
		{
			if(person.isRealUser==NO)
				continue;
			
			if ([person.email isEqualToString:self.emailTobeValidated]||[person.URNEmail isEqualToString:self.emailTobeValidated])
			{
				[self.weiJuParticipants removeObject:person];
				[self.weiJuParticipants insertObject:person atIndex:1];
				person.displayName=@"Me";
				
				person.friendData = [[WeiJuAppPrefs getSharedInstance] friendData];
				person.friendDataUserID = person.friendData.userId;
				
				//person.friendData.lastMeetingTitle = [NSString stringWithString:self.selfEvent.title];
				person.friendData.lastMeetingDate =[NSDate dateWithTimeInterval:0 sinceDate:self.selfEvent.startDate];
				/*
				if(self.selfEvent.location==nil||[self.selfEvent.location isEqualToString:@""])
					person.friendData.lastMeetingLocation = @"Place unspecified";
				else
					person.friendData.lastMeetingLocation = [NSString stringWithString:self.selfEvent.location];
				*/
				person.friendData.lastMeetingLocation = [[[Utils alloc] init] getEventProperty:self.selfEvent.location nilReplaceMent:@"Place unspecified"];
				if(person.userImage!=nil)
				{
					person.friendData.userImageFileData = UIImagePNGRepresentation(person.userImage);
					[WeiJuManagedObjectContext quickSave];
					//[self.friendsScrollVCtrl setImageForFriend:person];//no need since the image must have been set during init when the person.userimage was found
					
				}
				
				[self hideFriendDataOrNot:person];

				self.foundMyself = YES;
				self.mySelf=person;
				
				//then set up self.isOrganizer
				NSDictionary *foundEmailOrURNResult = [Utils getMyEmailFromEvent:self.selfEvent];
				if(foundEmailOrURNResult!=nil)
				{					
					if([foundEmailOrURNResult valueForKey:@"isOrganizer"]!=nil)
					//if(organizerEmailAddr!=nil || organizerURN!=nil)
						self.isOrganizer=YES;
				}
				else {
					if(self.selfEvent.organizer==nil)
						self.isOrganizer = YES;
				}
				
				[self createAllUserEmailString]; //now we can create he email list of all other people in the event
				
				[self.friendsScrollVCtrl updateFriendList:self.weiJuParticipants]; //re-display me to the front!
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.emailTobeValidated stringByAppendingString:@" has been successfully added to your account"]
																message:nil
															   delegate:nil 
													  cancelButtonTitle:@"Dismiss" 
													  otherButtonTitles:nil];
				[alert show];
				
				self.emailTobeValidated = nil;
				
				[[WeiJuListDCtrl getSharedInstance] add:person.url description:person.personDesp friendData:person.friendData event:self.selfEvent toTodayEventHistory:nil with:nil];
				
				break;
			}
		}
		
	}
	else
	{
		
        [Utils log:@"%s [line:%d] uploadSelfEmailsCallBack: fatal error - can't upload: %@",__FUNCTION__,__LINE__, [ConvertData getValue:dic key:@"error"]];
        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self.emailTobeValidated stringByAppendingString:@" was not added to your account"]
														message:[ConvertData getValue:dic key:@"error"]
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
		
	}
}


-(void) checkUserResgisterStatusCallBack:(NSDictionary *)dic
{
    @try{
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
	}
    @catch(NSException *e){
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [e userInfo], [e reason]];
    }
	if ([ConvertData getErrorInfo:dic] != nil)
	{
        
    }
	
	[[[ConvertData alloc] init] syncCoreDataWithNetDictionaryWithoutInitData:dic];
	//at this point, the user's frienddata might have been downloaded, hence let's do a search
    WeiJuParticipant *person = (WeiJuParticipant *)[ConvertData getWithOjbect:dic];
	
    FriendData *friendData = nil;
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    NSArray *friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",person.urlString]];
	if(friendDataResult==nil && person.URNEmail!=nil) //search again using URNemail in case the user's urn has not been submitted to the server yet
		friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",person.URNEmail]];
	
    if(friendDataResult!=nil &&[friendDataResult count]==1)
    {
        friendData = (FriendData*)[friendDataResult objectAtIndex:0];
		
		person.friendDataUserID = friendData.userId;
		person.friendData=friendData;
		
		//person.friendData.lastMeetingTitle = [NSString stringWithString:self.selfEvent.title];
		person.friendData.lastMeetingDate =[NSDate dateWithTimeInterval:0 sinceDate:self.selfEvent.startDate];
		person.friendData.lastMeetingLocation = [[[Utils alloc] init] getEventProperty:self.selfEvent.location nilReplaceMent:@"Place unspecified"];
		if(person.userImage!=nil)
		{
			person.friendData.userImageFileData = UIImagePNGRepresentation(person.userImage);
			[WeiJuManagedObjectContext quickSave];
			//[self.friendsScrollVCtrl setImageForFriend:person];//no need since the image must have been set during init when the person.userimage was found

		}
		
		[self hideFriendDataOrNot:person];
		
		//the following should be consisten with what we did in setupparticipants for fullname: replace fullname that's an email
		if([person.fullName rangeOfString:@"@"].location!=NSNotFound && person.friendData.userName!=nil)
		{
			person.fullName = person.friendData.userName; //if the user has defined his own name (usually not a full name, maybe just a nickname), and the event does not have its full name (only email address), use this one
			person.displayName = [[self getFLFromFullName:person.fullName] capitalizedString];
			[self.friendsScrollVCtrl setNameForFriend:person];
		}
		
        [self.friendsScrollVCtrl setColorFor:person color:[UIColor yellowColor] exclusive:NO]; //since we found this user, we need to change his color status to yellow
		
		if(self.foundMyself)
			[self createAllUserEmailString];
		
		//shall we pop up here an alert telling the user that the other user has registered???
		//shall we invite him right away? NO
        //[Utils inviteFriend:person toSharePathForEvent:self.selfEvent.eventIdentifier title:self.selfEvent.title from:self.mySelf];
		self.inviteUserAlert = [[UIAlertView alloc] initWithTitle:person.fullName 
														  message:@"is a registered user but not sharing path"
														 delegate:self 
												cancelButtonTitle:@"Dismiss" 
												otherButtonTitles:@"Invite to share", nil];
		[self.inviteUserAlert show];
		
		[[WeiJuListDCtrl getSharedInstance] add:person.url description:person.personDesp friendData:person.friendData event:self.selfEvent toTodayEventHistory:nil with:dataFetchUtil];
    }
    else {
        self.addrDisplayMode=ADDR_MODE_INVITE;
        [self promptForAddrSelection:person];
    }
}

#pragma mark - Toolbar and nav bar
- (void)locSwitchChanged:(id)sender {
	
	if(self.demoMode && sender!=nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo mode" 
														message:@"Only the user interface is demonstrated. Your path sharing will not be actually turned on/off."
													   delegate:self 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
		//self.locSwitch.on = NO;
		//return;
	}
	else 
	{
		if(self.mySelf==nil)
		{
			self.locSwitch.on = NO;
			
			[self promptForSelfIdentification];
			
			return;
		}
	}
	
	self.mySharingStatus = self.locSwitch.on;
		
//	if(self.progressTimer!=nil && [self.progressTimer isValid])
//		[self.progressTimer invalidate];
//	self.progressTimer=nil;

	//set the frame color for the ME button on the scrollbar
	if(self.mySharingStatus==YES)
	{		
		self.numberOfSharings++;
		[self turnOnSharing];
	}
	else 
	{
		self.numberOfSharings=MAX(self.numberOfSharings-1, 0);
		[self turnOffSharing];
	}
		
	[self setUpToolBar];
	
	//NSLog(@"=============locSwitchChanged:self.numberOfSharings=%d", self.numberOfSharings);


}

- (void) turnOnSharing
{
    if (self.demoMode) 
	{
        [DataFetchUtil saveButtonsEventRecord:@"40"];
		
		[self.friendsScrollVCtrl setColorFor:self.mySelf color:[UIColor greenColor] exclusive:NO];

		self.progressLabel_Min=0;
		self.progressLabel_Sec=0;
		self.progressLabel.text = [self generateProgressLabel];
		self.progressView.progress=0.0;
		
		self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshProgressLabelTimesUp:) userInfo:nil repeats:YES];
		
    }else
	{
        [DataFetchUtil saveButtonsEventRecord:@"53"];
		
		//do we need to check if there are registered users in this event, and if not, we should prompt user that it is useless to share: no, the user can simply track himself
		
		[self.friendsScrollVCtrl setColorFor:self.mySelf color:[UIColor greenColor] exclusive:NO];
		
		//[self.mapVCtrl showsUserLocation:YES];
		[self.mapVCtrl centerSelfLocation];
		
		if ( (self.pathDCtrl=[PathDCtrl getSharedInstance])==nil) {
			self.pathDCtrl = [[PathDCtrl alloc] init]; //start the location tracking object
		}
		
		if(self.pathDCtrl!=nil) //prevent failure from pdctrl init
		{
			[self.pathDCtrl registerLocationUpdate];
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(myLocationChanged:)
														 name:@"MyLocUpdateNotif" object:self.pathDCtrl];
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(gpsInitFailed:)
														 name:@"gpsInitFailed" object:self.pathDCtrl];
			
			self.progressLabel_Min=0;
			self.progressLabel_Sec=0;
			self.progressLabel.text = [self generateProgressLabel];
			self.progressView.progress=0.0;
			
			self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshProgressLabelTimesUp:) userInfo:nil repeats:YES];
			
			//[self updateMyLocation:CLLocationCoordinate2DMake(0, 0)]; //the first update
		}
		else 
			self.locSwitch.on=NO;
	}
}

- (void) turnOffSharing
{
    if(self.demoMode) 
	{
        [DataFetchUtil saveButtonsEventRecord:@"41"];
		
		if(self.progressTimer!=nil && [self.progressTimer isValid])
			[self.progressTimer invalidate];
		self.progressTimer=nil;

		[self.friendsScrollVCtrl setColorFor:self.mySelf color:[UIColor yellowColor] exclusive:NO];
    }else 
	{
        [DataFetchUtil saveButtonsEventRecord:@"54"];
		
		if(self.progressTimer!=nil && [self.progressTimer isValid])
			[self.progressTimer invalidate];
		self.progressTimer=nil;
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"MyLocUpdateNotif" object:self.pathDCtrl];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"gpsInitFailed" object:self.pathDCtrl];
		
		[self.pathDCtrl deRegisterLocationUpdate];
		
		[self.cachedLocations removeAllObjects];
		
		self.prevCoordinate = CLLocationCoordinate2DMake(0, 0);
		
		[self.mapVCtrl showsUserLocation:NO];
		
		//comment out to keep them on the map for now
		/*
		 [self.mapVCtrl removeOverlay:self.mySelf.crumbPath];	
		 self.mySelf.crumbPath = nil;
		 [self.mapVCtrl removeAnnotations:self.mySelf.annotations];
		 self.mySelf.annotations = nil;
		 */
		
		if(self.allUserEmailString!=nil)
			[Utils informSharingOffToFriend:self.allUserEmailString forEventID:self.selfEvent.eventIdentifier from:self.mySelf];
		
		[self.friendsScrollVCtrl setColorFor:self.mySelf color:[UIColor yellowColor] exclusive:NO];
	}
}

- (void) refreshProgressLabelTimesUp:(NSTimer *)timer
{
	//[timer invalidate];
	//NSLog(@"refreshProgressLabel2: %d", [timer isValid]);
	self.progressLabel_Sec++;
	if(self.progressLabel_Sec==60)
	{
		self.progressLabel_Sec = 0;
		self.progressLabel_Min++;
		
		if(self.demoMode==NO) 
			[self updateMyLocation:CLLocationCoordinate2DMake(0, 0) addAnnotation:YES];
	}
	
	if(self.progressLabel_Min<(int)([[WeiJuAppPrefs getSharedInstance] pathSharingDuration]/60))
	{
		self.progressLabel.text = [self generateProgressLabel];
		self.progressView.progress = (float)(self.progressLabel_Min*60+self.progressLabel_Sec)/[[WeiJuAppPrefs getSharedInstance] pathSharingDuration];
	}
	else 
	{
		[self.progressTimer invalidate];
		self.locSwitch.on = NO;
		
		if(self.demoMode==NO)
		{
			[self locSwitchChanged:self.locSwitch];
			
			if([self.selfEvent refresh]!=NO) //evetn hasn't been updated yet
			{
				NSString *title = [[[Utils alloc] init] getEventProperty:self.selfEvent.title nilReplaceMent:@"Event"];
				NSString *time = [[Utils getHourMinutes:self.selfEvent.startDate] stringByAppendingFormat:@" %@", [Utils getAMPM:self.selfEvent.startDate] ];
				[Utils displaySmartAlertWithTitle:[@"Notice for " stringByAppendingFormat:@"\"%@\" @ %@", title, time] message:@"Your path sharing timer has timed out and your path updates to others is thus turned off.\n\nTo resume sharing, please go back to the event screen and tap on the sharing switch again." noLocalNotif:NO];
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			}
		}
	}
}

- (NSString *)generateProgressLabel
{
	NSString *result=@"";
	if(self.progressLabel_Sec<10)
		result=@"0";

	return [[NSString stringWithFormat:@"%d",self.progressLabel_Min] stringByAppendingFormat:@":%@%d / %d:00 minutes", result, self.progressLabel_Sec, (int)([[WeiJuAppPrefs getSharedInstance] pathSharingDuration]/60)];
}

- (void)myLocationChanged:(NSNotification *)notification
{
	[self updateMyLocation:CLLocationCoordinate2DMake(0, 0) addAnnotation:NO];
}

- (void)gpsInitFailed:(NSNotification *)notification
{
	self.prevCoordinate = CLLocationCoordinate2DMake(0, 0);
	self.locSwitch.on = NO;
	[self locSwitchChanged:self.locSwitch];
}

- (void) updateMyLocation:(CLLocationCoordinate2D)myCoord addAnnotation:(BOOL)addOrNot
{
	WeiJuParticipant *me = self.mySelf; //[self.weiJuParticipants objectAtIndex:1]; 
	if(me==nil)
		return;
	
	NSDate *now = [NSDate date];

	if(self.pathDCtrl.locationManagerOn==NO) 
	{	//no gps, no internet, but user might still turn on the sharing switch after the first warning from pdctrl, in this case, pdctrl won't have second warning to call gpsInitFailed, hence pvc might think pdctrl is running 
		[Utils log:@"%s [line:%d] self.pathDCtrl.locationManagerOn=%d, registeredListners=%d",__FUNCTION__,__LINE__, self.pathDCtrl.locationManagerOn, self.pathDCtrl.registeredListners];
		return;
	}
		
	CLLocationCoordinate2D curCoordinate = [self.pathDCtrl getUserCurrentCoord]; //copy over
	
	int firstTime = 0; //used to tell recipient whether to display the alerview that i start sharing path now

	if(!(self.prevCoordinate.latitude==0 && self.prevCoordinate.longitude==0)) //not the first, or use me.crumbPath==nil
	{
		CLLocationDistance distance = [ [[CLLocation alloc] initWithLatitude:curCoordinate.latitude longitude:curCoordinate.longitude] distanceFromLocation: [[CLLocation alloc] initWithLatitude:self.prevCoordinate.latitude longitude:self.prevCoordinate.longitude] ];
		
		int speed = (int)(distance/[now timeIntervalSinceDate:self.lastLocationUpdateTime]*3600/1000);
		double seconds = [now timeIntervalSinceDate:self.lastLocationUpdateTime];
		//NSLog(@"-----Notif: speed=%d dist=%f seconds=%f", speed, distance, seconds);
		if( (seconds<2&&speed>300) || distance>5000 ) //1) faster than 400kmh within 2 seconds, or 2) in 60 seconds, distance can't be more than 400*1000/60=6666
		{
			/*
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unusual movement warning" 
															message:[@"iPhone indicates your speed is " stringByAppendingFormat:@"%d kmh, %f %f", speed, distance, [now timeIntervalSinceDate:self.lastLocationUpdateTime]]
														   delegate:nil 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
			[alert show];
			*/
			curCoordinate = self.prevCoordinate; //do this, rather than return, because return may lead to the skip of adding annotation
			distance = 0;
		}
		
		if(addOrNot==NO && curCoordinate.latitude==self.prevCoordinate.latitude && curCoordinate.longitude==self.prevCoordinate.longitude)
			return;
		
		self.distanceTravelled += distance;
	}
	else 
	{
		//first update, or restart sharing after turning off sharing
		
		//self.distanceTravelled=0; //no need, will do it below
		//self.lastAnnotationUpdateTime=now;
		firstTime = 1;		
	}

	self.lastLocationUpdateTime=now;
		
	if(self.cachedLocations==nil)
	{
		self.cachedLocations = [[NSMutableArray alloc] init];
	}
	
	if(myCoord.latitude==0 && myCoord.longitude==0) //true update, not demo
	{
		[self.cachedLocations addObject:[[CLLocation alloc] initWithLatitude:curCoordinate.latitude longitude:curCoordinate.longitude] ];
	}
	else 
	{ //demo, use passed-in coord
		[self.cachedLocations addObject:[[CLLocation alloc] initWithLatitude:myCoord.latitude longitude:myCoord.longitude] ];
	}
		
	NSString *subTitle; //nil
	if(firstTime==1 || addOrNot==YES) //要把自己的地址的更新传给其他人
	{
		//first, generate the subtitle in annotation
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"HH:mm"];
		//subTitle = [[self getFLFromFullName:me.fullName] stringByAppendingFormat:@": %@%@", [formatter stringFromDate:now], [[Utils getAMPM:now] lowercaseString] ]; 
		subTitle = [[formatter stringFromDate:now] stringByAppendingFormat:@"%@",[[Utils getAMPM:now] lowercaseString] ]; 
		if(firstTime==0) //add speed if not the first time
		{
			//NSLog(@"speed:%f %@ %@ %f %d",self.distanceTravelled,now, self.lastAnnotationUpdateTime,[now timeIntervalSinceDate:self.lastAnnotationUpdateTime],(int)(self.distanceTravelled/[now timeIntervalSinceDate:self.lastAnnotationUpdateTime]*3600/1000*0.62));
			subTitle = [subTitle stringByAppendingFormat:@" @ %d mph", (int)(self.distanceTravelled/[now timeIntervalSinceDate:self.lastAnnotationUpdateTime]*3600/1000*0.62)];
		}
		else {
			subTitle = [subTitle stringByAppendingString:@" (init update)"];
		}
		
		self.distanceTravelled = 0;
		self.lastAnnotationUpdateTime = now;
				
		@synchronized(self.allUserEmailString)
		{
			if(self.allUserEmailString!=nil && [self.cachedLocations count]>0)
			{
				//[Utils log:@"%s [line:%d] sent out: subtitle=%@",__FUNCTION__,__LINE__, subTitle];
				
				[[[Utils alloc] init] updateFriend:self.allUserEmailString firstTime:firstTime /*withMyName:self.mySelf.fullName*/ subtitle:subTitle locations:self.cachedLocations forEvent:self.selfEvent];
				
				[self.cachedLocations removeAllObjects];
			}
		}
	}
	
	//update my local map: if subtitle=nil, don't add subtitl
	if(myCoord.latitude==0 && myCoord.longitude==0)
		[self participant:me locationChanged:curCoordinate annotationSubTitle:subTitle updateSenderStatus:YES];
	else 
		[self participant:me locationChanged:myCoord annotationSubTitle:subTitle updateSenderStatus:YES];
	
	self.prevCoordinate = curCoordinate;
	
}

//这是收到对方的地址更新之后,要调用的API,更新地图
-(void)participant:(WeiJuParticipant *)person locationChanged:(CLLocationCoordinate2D) coord annotationSubTitle:(NSString *)subTitle updateSenderStatus:(BOOL)updateStatus //the last param is used to tell whether to change color of sender - when recovering for coredata, there is no need to update the status color
{	
	//WeiJuParticipant *person = [self weiJuParticipantForUserId:userID];

	if(subTitle!=nil)
	{
		if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
			[Utils log:@"Recv from %@ %@ %d: (%f,%f) %@", person.friendDataUserID, person.fullName, person.isSharing, coord.latitude, coord.longitude, subTitle];
		else 
			[Utils log:@"r: %@-%@", person.friendDataUserID, subTitle];
	}
	
	@synchronized(self.mapVCtrl)//prevent shutdown execution at the same time
	{
		if(person==nil || self.mapVCtrl==nil) //map don't exist anymore due to shutdown
			return;
		
		if(updateStatus==YES && person.isSharing==NO)
		{
			if(self.mySelf!=nil && person!=self.mySelf) //for self, the number of sharing property is controlled in locswitchchanged
				self.numberOfSharings++;
			//NSLog(@"===========participantID:self.numberOfSharings=%d", self.numberOfSharings);
			
			person.isSharing = YES;
			[self.friendsScrollVCtrl setColorFor:person color:[UIColor greenColor] exclusive:NO];
		}
		
		if (person.crumbPath==nil) 
		{	//first update
			person.crumbPath = [self.mapVCtrl addOverlay:coord]; //crumbpath will be init there
			person.annotations = [[NSMutableArray alloc] init];
		}
		else 
		{
			MKMapRect updateRect = [person.crumbPath addCoordinate:coord];
			
			if (!MKMapRectIsNull(updateRect)) //也即:metersApart > MINIMUM_DELTA_METERS in crumbpath
			{
				[self.mapVCtrl updateCrumbViewForOverlay:person.crumbPath rect:updateRect];
			}
		}
		
		person.lastCoord=CLLocationCoordinate2DMake(coord.latitude, coord.longitude);
		self.centerCoordinate=CLLocationCoordinate2DMake(coord.latitude, coord.longitude);

		if(subTitle!=nil)
		{
			//if(updateStatus==YES) //not reload of previous annoation which already has the name in the subtitle
				if(person==self.mySelf)
					subTitle = [@"Me: " stringByAppendingString:subTitle];
				else 
					subTitle = [person.displayName stringByAppendingFormat:@": %@", subTitle];
			
			[person.annotations addObject:[self.mapVCtrl addAnnotation:coord title:person.fullName subTitle:subTitle repositionMap:NO]];
			
			//if(self.isBeingDisplayed==NO) //even if pvc is being diaplyed, need to update wjlistvctrl, because when we go from pvc back to there, the reload won't happen
			//{
				//if([WeiJuListVCtrl getSharedInstance].currentVCtrl!=nil) //listvctrl is being displayed - don't do this because if we are in contact book, when we go back to listvctrl, the table won't be refreshed
					[[WeiJuListVCtrl getSharedInstance].tableView reloadData]; //display the updated map center, in weijulistv's row
			//}

		}
		
		//start the timeout timer for this user
		if(self.mySelf!=nil && person!=self.mySelf && updateStatus==YES)//if updateStatus==NO, it means the system is reading from the msg in viewdidload, no need to start the timer
		{
			if(person.sharingTimeOut!=nil && [person.sharingTimeOut isValid])
				[person.sharingTimeOut invalidate]; //first stop the timer
			person.sharingTimeOut = [NSTimer scheduledTimerWithTimeInterval:PATH_UPDATE_INTERVAL+120.0 target:self selector:@selector(userSharingTimesUp:) userInfo:person repeats:NO];
		}
		
		if(self.mySelf!=nil && person!=self.mySelf)
		{
			person.newMsg++;
			if(self.hasBeenLoaded && self.isBeingDisplayed)
				[self.friendsScrollVCtrl setBadgeForFriend:person];
		}
		
	}//sync
}

- (void) userSharingTimesUp:(NSTimer *)timer
{
	[self changeSharingStatusToOffFor:(WeiJuParticipant *)[timer userInfo]];
}

- (void) changeSharingStatusToOffFor:(WeiJuParticipant *)person//(NSString *)invitorUserID
{
	//WeiJuParticipant *person = [self weiJuParticipantForUserId:invitorUserID];
	
	if(person != nil)
	{
		self.numberOfSharings=MAX(self.numberOfSharings-1, 0);

		person.isSharing=NO;
		[self.friendsScrollVCtrl setColorFor:person color:[UIColor yellowColor] exclusive:NO];
		
		//seems unnecessary: even if he stops sharing, the user should know that he has updated his location for N times
		/*
		if(person.newMsg>0)
		{
			//self.numberOfNewMessage=MAX(0, self.numberOfNewMessage - person.newMsg);
			
			person.newMsg=0;
			[self.friendsScrollVCtrl setBadgeForFriend:person];
			
			//if(self.isBeingDisplayed==NO && self.numberOfNewMessage==0)
			//{
			//	[[WeiJuListVCtrl getSharedInstance].tableView reloadData];
			//	return; //no need to execute below and reload again
			//}

		}
		*/
	}
	
	if(self.isBeingDisplayed==NO && self.numberOfSharings==0)
		[[WeiJuListVCtrl getSharedInstance].tableView reloadData]; //display the map, or undisplay the map
}

-(void) displaySharingRequestFrom:(NSString *)invitorUserID
{
	WeiJuParticipant *person = [self weiJuParticipantForUserId:invitorUserID];
		
	if(person != nil)
		[self addPopOverReminder:[person.fullName stringByAppendingString: @" invites you to share your path"] fromRect:CGRectNull];
}

- (void) setUpToolBar
{
	if(self.mySharingStatus==YES)
	{
		//NSLog(@"setUpToolBar:self.progressViewContainer:%@", self.progressViewContainer);
		self.currentToolbarItems = [ [NSArray alloc] initWithObjects:
								self.locSwitchBarBtn, 
								/*[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],*/
								[[UIBarButtonItem alloc] initWithCustomView:self.progressViewContainer],
							 self.pageCurlBarBtn,
								nil];
	}
	else
		self.currentToolbarItems = [ [NSArray alloc] initWithObjects:
								self.locSwitchBarBtn, 
								/*[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],*/
								[[UIBarButtonItem alloc] initWithCustomView:self.progressViewText],
							 self.pageCurlBarBtn,
								nil];
	
	self.toolbarItems = self.currentToolbarItems;
	//NSLog(@"tb:%@ %@", sender, [self.toolbarItems objectAtIndex:0]);
}

-(void) pageCurlUp
{
	if(self.optionVCtrl==nil)
	{
		self.optionVCtrl = [[WeiJuPathShareOptionVCtrl alloc] initWithNibName:@"WeiJuPathShareOptionVCtrl" bundle:nil];
		[self.optionVCtrl setModalTransitionStyle:UIModalTransitionStylePartialCurl];
		self.optionVCtrl.delegate = self;
				
		if([Utils isOSLowerThan5])
			[self presentModalViewController:self.optionVCtrl animated:YES];
		else 
		{
			self.definesPresentationContext=YES;
            [self presentViewController:self.optionVCtrl animated:YES completion:nil];
		}
		
        if (self.demoMode) {
            [DataFetchUtil saveButtonsEventRecord:@"42"];
        }else {
            [DataFetchUtil saveButtonsEventRecord:@"55"];
        }
		
	}
	else 
	{
        if (self.demoMode) {
            [DataFetchUtil saveButtonsEventRecord:@"93"];
        }else {
            [DataFetchUtil saveButtonsEventRecord:@"57"];
        }
		if([Utils isOSLowerThan5]==NO)
		{
			[self dismissViewControllerAnimated:YES completion:^
				 {
					 //[self.dayVCtrl toggleEventAnimation:YES]; //restart the event animation if any
					 
				 }];
		}
		else
		{
			[self dismissModalViewControllerAnimated:YES];
		}
		
		self.optionVCtrl = nil;
		//self.optionViewPresented = NO;
		
	}
	  
}

-(void) backToListView
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(void) helpInfo
{
    if (self.demoMode) {
        [DataFetchUtil saveButtonsEventRecord:@"37"];
    }else {
        [DataFetchUtil saveButtonsEventRecord:@"50"];
    }
	[self.navigationController pushViewController:[[PathShareHelperVCtrl alloc] initWithNibName:@"PathShareHelperVCtrl" bundle:nil] animated:YES];
	/*
	if([[WeiJuAppPrefs getSharedInstance] logMode]!=3)
	{
		DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
		//delete message
		NSDate *startDate = [NSDate date];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sendTime <= %@",startDate];
		[dataFetchUtil deleteObjectArray:@"WeiJuMessage" filter:predicate];
		[WeiJuManagedObjectContext save];
	}
	*/

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

		self.popoverReminder = [[PopOverTexiViewReminder alloc] initWithNibName:@"PopOverTexiViewReminder" bundle:nil size:CGRectMake(0, 0, 136, 70)];
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
		[self.popoverCtrl presentPopoverFromBarButtonItem:self.locSwitchBarBtn permittedArrowDirections:UIPopoverArrowDirectionDown|UIPopoverArrowDirectionUp animated:YES];
	else 
		[self.popoverCtrl presentPopoverFromRect:targetRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown|UIPopoverArrowDirectionUp animated:YES];
	
	[self.popoverReminder setTextContent:textContent];

}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	/*
	 enum MessageComposeResult {
	 MessageComposeResultCancelled,
	 MessageComposeResultSent,
	 MessageComposeResultFailed
	 };
	 typedef enum MessageComposeResult MessageComposeResult;
	 */
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	/*
	 enum MFMailComposeResult {
	 MFMailComposeResultCancelled,
	 MFMailComposeResultSaved,
	 MFMailComposeResultSent,
	 MFMailComposeResultFailed
	 };
	 typedef enum MFMailComposeResult MFMailComposeResult;
	 
	 enum MFMailComposeErrorCode {
	 MFMailComposeErrorCodeSaveFailed,
	 MFMailComposeErrorCodeSendFailed
	 };
	 typedef enum MFMailComposeErrorCode MFMailComposeErrorCode;
	 */
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EKEventViewDelegate, EKEventEditViewDelegate
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
	[self.navigationController dismissViewControllerAnimated:YES
												  completion:nil];	
}

#pragma mark - demo code
-(void) setUpDemoParticipants
{	
	WeiJuParticipant *person = [[WeiJuParticipant alloc] init];
	
	person.fullName=@"My Name";
	person.displayName=@"Me";
    person.userImage = [UIImage imageNamed:@"demoperson1.png"];
	person.phoneLabels = [[NSMutableArray alloc] init];
	person.phoneNumbers = [[NSMutableArray alloc] init];
	person.friendDataUserID = @"11";
	person.isSharing=NO;
	
	self.foundMyself=YES;
	self.mySelf = person;

	[self.weiJuParticipants addObject:person];
	
	person = [[WeiJuParticipant alloc] init];
	
	person.fullName=@"Tom Eichert";
	person.displayName=@"T.E";
    person.userImage = [UIImage imageNamed:@"demoperson2.png"];
	person.phoneLabels = [[NSMutableArray alloc] init];
	person.phoneNumbers = [[NSMutableArray alloc] init];
	person.friendDataUserID = @"12";
	person.isSharing=YES;
	person.newMsg=3;
	
	[self.weiJuParticipants addObject:person];
	
	person = [[WeiJuParticipant alloc] init];
	
	person.fullName=@"John Stennis";
	person.displayName=@"J.S";
    person.userImage = [UIImage imageNamed:@"demoperson3.png"];
	person.phoneLabels = [[NSMutableArray alloc] init];
	person.phoneNumbers = [[NSMutableArray alloc] init];
	person.friendDataUserID = @"15";
	person.isSharing=YES;
	
	[self.weiJuParticipants addObject:person];
	
	person = [[WeiJuParticipant alloc] init];
	
	person.fullName=@"Kate Perry";
    person.userImage = [UIImage imageNamed:@"demoperson4.png"];
	person.displayName=@"K.P";
	person.phoneLabels = [[NSMutableArray alloc] init];
	person.phoneNumbers = [[NSMutableArray alloc] init];
	
	[self.weiJuParticipants addObject:person];
	
	[self addAllandAdd];
	
	self.demoMode=YES;
}

-(void) setUpDemoABtn
{
	UIButton *demoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	demoBtn.frame=CGRectMake(0, self.view.bounds.size.height-self.navigationController.toolbar.frame.size.height-40, 40, 40);
	[demoBtn setTitle:@"D" forState:UIControlStateNormal];
	[demoBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
	[demoBtn setBackgroundColor: [UIColor clearColor]];
	[demoBtn addTarget:self action:@selector(demoAButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	demoBtn.tag=33;
	
	[self.view addSubview:demoBtn];
}

-(void) setUpDemoBBtn
{
	UIButton *demoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	demoBtn.frame=CGRectMake(self.view.bounds.size.width-40, self.view.bounds.size.height-self.navigationController.toolbar.frame.size.height-40, 40, 40);
	[demoBtn setTitle:@"D" forState:UIControlStateNormal];
	[demoBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
	[demoBtn setBackgroundColor: [UIColor clearColor]];
	[demoBtn addTarget:self action:@selector(demoBButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	demoBtn.tag=33;
	
	[self.view addSubview:demoBtn];
	
}

- (void) startDemoAnimation
{
	self.demoMinTime = 10;
	self.demoPathCount = 0;
	
	self.demoPathTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(demoAButtonPressed) userInfo:nil repeats:YES];
}

//demo the moving of david for three times
-(void) demoAButtonPressed
{
	self.demoPathCount++;
	self.demoMinTime+=6; //every 6 minutes
	
	WeiJuParticipant *person = [self.weiJuParticipants objectAtIndex:3];

	CLLocationCoordinate2D coord;
	switch (self.demoPathCount) {
		case 1:
			coord = CLLocationCoordinate2DMake(37.47286, -122.21691);
			break;
		case 2:
			coord = CLLocationCoordinate2DMake(37.46921, -122.21196);
			break;
		case 3:
			coord = CLLocationCoordinate2DMake(37.46610, -122.20771);
			break;
		case 4:
			coord = CLLocationCoordinate2DMake(37.46318, -122.20247);
			break;
		//case 5: //not used
		//	coord = CLLocationCoordinate2DMake(37.46077, -122.19754);
		//	break;
			
		default:
			break;
	}
	
	[self participant:person locationChanged:coord annotationSubTitle:[@"" stringByAppendingFormat:@"12:%i @ 29mph",self.demoMinTime] updateSenderStatus:YES];
	
   	if (self.demoPathCount > 3) 
	{
        [self.demoPathTimer invalidate];
        self.demoPathTimer = nil;
		
        if (self.isBeingDisplayed) 
		{
            self.demoReplayAlert = [[UIAlertView alloc] initWithTitle:nil//@"Path sharing demo is done"
                                                              message:@"To view the animation again, tap the left arrow on the top left corner, and re-enter this screen.\n\n Tap on other buttons in this screen to experience more functions."
                                                             delegate:nil 
                                                    cancelButtonTitle:@"Dismiss" 
                                                    otherButtonTitles:nil];
            [self.demoReplayAlert show];
        }
		
		 
    }
}

- (void) rewindDemoPath
{
	
}

-(void) demoBButtonPressed
{
	static double lati = 39.992286, longti = 116.475609;
	double delta = 10.0/111000;
	
	[self updateMyLocation:CLLocationCoordinate2DMake(lati, longti) addAnnotation:YES];
	lati-=delta;
	longti-=delta;
}

-(void) setUpDemoPath
{
	WeiJuParticipant *person1 = [self.weiJuParticipants objectAtIndex:1];//ME
	CLLocationCoordinate2D c01 = CLLocationCoordinate2DMake(37.47482, -122.18790);
	CLLocationCoordinate2D c02 = CLLocationCoordinate2DMake(37.46851, -122.19157);
	CLLocationCoordinate2D c03 = CLLocationCoordinate2DMake(37.46978, -122.19458);
	BridgeAnnotation *ba01=[[BridgeAnnotation alloc] init];
	ba01.theTitle=person1.fullName;
	ba01.theSubtitle=@"Me: 11:20 @ 26mph";
	[ba01 setCoordinate:c01];

	BridgeAnnotation *ba02=[[BridgeAnnotation alloc] init];
	ba02.theTitle=person1.fullName;
	ba02.theSubtitle=@"Me: 11:23 @ 24mph";
	[ba02 setCoordinate:c02];
	
	BridgeAnnotation *ba03=[[BridgeAnnotation alloc] init];
	ba03.theTitle=person1.fullName;
	ba03.theSubtitle=@"Me: 11:25 @ 26mph";
	[ba03 setCoordinate:c03];

	person1.crumbPath = [[CrumbPath alloc] initWithCenterCoordinate:c01];
	[person1.crumbPath addCoordinate:c02];
	[person1.crumbPath addCoordinate:c03];

	person1.annotations = [NSMutableArray arrayWithObjects:ba01, ba02, ba03,nil];
	person1.lastCoord = c03;

	WeiJuParticipant *person2 = [self.weiJuParticipants objectAtIndex:2];//T.E
	
	CLLocationCoordinate2D c1=CLLocationCoordinate2DMake(37.44856, -122.18711);
	CLLocationCoordinate2D c2=CLLocationCoordinate2DMake(37.45098, -122.19166);
	CLLocationCoordinate2D c3=CLLocationCoordinate2DMake(37.45585, -122.18762);
	CLLocationCoordinate2D c4=CLLocationCoordinate2DMake(37.45990, -122.19552);
	CLLocationCoordinate2D mapcenter = CLLocationCoordinate2DMake(c4.latitude, c4.longitude);
	
	
	person2.crumbPath = [[CrumbPath alloc] initWithCenterCoordinate:c1];
	[person2.crumbPath addCoordinate:c2];
	[person2.crumbPath addCoordinate:c3];
	[person2.crumbPath addCoordinate:c4];
	
	person2.lastCoord = c4;
	
	BridgeAnnotation *ba1=[[BridgeAnnotation alloc] init];
	ba1.theTitle=person2.fullName;
	ba1.theSubtitle=@"T.E: 11:40 @ 23mph";
	[ba1 setCoordinate:c1];
	BridgeAnnotation *ba2=[[BridgeAnnotation alloc] init];
	ba2.theTitle=person2.fullName;
	ba2.theSubtitle=@"T.E: 11:45 @ 33mph";
	[ba2 setCoordinate:c2];
	BridgeAnnotation *ba3=[[BridgeAnnotation alloc] init];
	ba3.theTitle=person2.fullName;
	ba3.theSubtitle=@"T.E: 11:50 @ 22mph";
	[ba3 setCoordinate:c3];
	BridgeAnnotation *ba4=[[BridgeAnnotation alloc] init];
	ba4.theTitle=person2.fullName;
	ba4.theSubtitle=@"T.E: 11:55 @ 22mph";
	[ba4 setCoordinate:c4];		
	
	person2.annotations = [NSMutableArray arrayWithObjects:ba1,ba2,ba3,ba4,nil];
	
	WeiJuParticipant *person3 = [self.weiJuParticipants objectAtIndex:3];//D.K
	
	CLLocationCoordinate2D c5=CLLocationCoordinate2DMake(37.4827, -122.23050);
	CLLocationCoordinate2D c6=CLLocationCoordinate2DMake(37.47980, -122.22661);
	CLLocationCoordinate2D c7=CLLocationCoordinate2DMake(37.47621, -122.22159);
	
	person3.crumbPath = [[CrumbPath alloc] initWithCenterCoordinate:c5];
	[person3.crumbPath addCoordinate:c6];
	[person3.crumbPath addCoordinate:c7];
	//[person3.crumbPath addCoordinate:c8];
	
	person3.lastCoord = c7;
	
	BridgeAnnotation *ba5=[[BridgeAnnotation alloc] init];
	ba5.theTitle=person3.fullName;
	ba5.theSubtitle=@"J.S: 11:35 @ 23mph";
	[ba5 setCoordinate:c5];
	BridgeAnnotation *ba6=[[BridgeAnnotation alloc] init];
	ba6.theTitle=person3.fullName;
	ba6.theSubtitle=@"J.S: 11:42 @ 33mph";
	[ba6 setCoordinate:c6];
	BridgeAnnotation *ba7=[[BridgeAnnotation alloc] init];
	ba7.theTitle=person3.fullName;
	ba7.theSubtitle=@"J.S: 11:46 @ 31mph";;
	[ba7 setCoordinate:c7];
	/*
	BridgeAnnotation *ba8=[[BridgeAnnotation alloc] init];
	ba8.theTitle=person3.fullName;
	ba8.theSubtitle=@"11:57 @ 29mph";
	[ba8 setCoordinate:c8];
	*/
	
	person3.annotations = [NSMutableArray arrayWithObjects:ba5,ba6,ba7,nil];

	self.centerCoordinate = mapcenter;
	self.latitudinalMeters=2000;
	self.longitudinalMeters=2000;
	self.initialCrumbs=[NSMutableArray arrayWithObjects:person2.crumbPath, person3.crumbPath, person1.crumbPath, nil];
	self.initialAnnotations=[NSMutableArray arrayWithObjects:ba01, ba02, ba03, ba5,ba6,ba7,ba1,ba2,ba3,ba4,nil];
	
	
}
@end

