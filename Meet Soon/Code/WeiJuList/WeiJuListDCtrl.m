//
//  WeiJuListDCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuListDCtrl.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuData.h"
#import "WeiJuMessage.h"
#import "FriendData.h"
#import "WeiJuManagedObjectContext.h"
#import "OperationQueue.h"
#import "DataFetchUtil.h"
#import "WeiJuNetWorkClient.h"
#import "ConvertUtil.h"
#import "WeiJuPathShareVCtrl.h"
#import "Location.h"
#import "ChatDCtrl.h"
#import "FileOperationUtils.h"
#import "MessageStatus.h"
#import "FriendFavoriteLocation.h"
#import "FriendAgreedStatus.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "ConvertUtil.h"
#import "ConvertData.h"
#import "Utils.h"
#import "EventHistory.h"
#import "JSONKit.h"
#import "DESUtils.h"
#import "ConvertUtil.h"
#import "OperationTask.h"
#import "OperationQueue.h"
#import "MBProgressHUD.h" 

@interface WeiJuListDCtrl ()
//The @interface WeiJuListDCtrl() code block is called a class extension. A class extension allows you to declare a method that is private to the class (to learn more, see “Extensions” in The Objective-C Programming Language).
@end

@implementation WeiJuListDCtrl

#define PAST_DAYS 30
#define FUTURE_DAYS 90

@synthesize weiJuListVCtrl;
@synthesize eventStore=_eventStore,hasAcceessToCalendar=_hasAcceessToCalendar, hasLoadedEvents=_hasLoadedEvents, hasServerBasedCalendar=_hasServerBasedCalendar, eventChangeBuf=_eventChangeBuf, eventChangeQ=_eventChangeQ, eventHistQ=_eventHistQ, checkEmailQ=_checkEmailQ;
@synthesize eventDayEvents;
@synthesize eventDaySections;
@synthesize currentDaySectionIndex, lastTimeTodayDate;

@synthesize fetcher=_fetcher;

static WeiJuListDCtrl *sharedInstance;

+ (WeiJuListDCtrl *) getSharedInstance
{
    if (sharedInstance == nil && [WeiJuListVCtrl getSharedInstance] != nil) {
        sharedInstance = [[WeiJuListDCtrl alloc] initWithVC:[WeiJuListVCtrl getSharedInstance]];
    }

    return sharedInstance;
}


//初始化
- (id)initWithVC:(WeiJuListVCtrl *) vctrl
{
	self = [super init];
    if (self!=nil) 
    {   
		sharedInstance = self;     
		self.weiJuListVCtrl=vctrl;
		self.hasAcceessToCalendar=NO;
		self.hasLoadedEvents=NO;
		
		self.eventChangeBuf = [[NSMutableArray alloc] init];
		self.eventChangeQ=[[NSOperationQueue alloc] init];
		[self.eventChangeQ setName:@"EventChangeQ"];
		[self.eventChangeQ setMaxConcurrentOperationCount:1]; //only one update can run, no concurrency
		self.eventHistQ=[[NSOperationQueue alloc] init];
		[self.eventHistQ setName:@"EventHistQ"];
		self.checkEmailQ=[[NSOperationQueue alloc] init];
		[self.checkEmailQ setName:@"CheckEmailQ"];

		if([WeiJuAppDelegate getSharedInstance].eventStore==nil)
		{
			[WeiJuAppDelegate getSharedInstance].eventStore = [[EKEventStore alloc] init]; //An EKEventStore object requires a relatively large amount of time to initialize and release. Consequently, you should not initialize and release a separate event store for each event-related task. Instead, initialize a single event store when your app loads and use it repeatedly
			
			//here is the flow in ios6:
			//viewdidload->willappear->numberOfSections(could be 0)->didappear
			//nonmain thread:setUpEventData->tableview reload->will not call listvctrl number of sections if view didload not called yet->gototoday
			if([[WeiJuAppDelegate getSharedInstance].eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)] && [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]!= EKAuthorizationStatusAuthorized)//ios6
			{
				WeiJuListDCtrl * __weak weakSelf = self;// avoid capturing self in the block
				[[WeiJuAppDelegate getSharedInstance].eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
					if(granted)
					{
						[DataFetchUtil saveButtonsEventRecord:@"1s"];
						weakSelf.eventStore = [WeiJuAppDelegate getSharedInstance].eventStore;
						weakSelf.hasAcceessToCalendar=YES;
						[weakSelf checkNumberOfCalendarChanges];
						[weakSelf setUpEventData];
						//if(self.weiJuListVCtrl.currentVCtrl!=nil) //viewDidAppear has finished (otherwise reload before viewdidappear will cause the table to be empty? not true
						{
							//load table must be done on main thread because the mapview can only be created on main thread
							[self.weiJuListVCtrl.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
							//NSLog(@"gotoToday1");
							[self.weiJuListVCtrl performSelectorOnMainThread:@selector(gotoToday) withObject:nil waitUntilDone:YES];
							//since it is on main thread's msg queue, gotoToday will have to wait until the reloadData been executed; but this thread will move on to the next line (simply put msg on mainthread's queue)
						}
					}
					else
					{
						[DataFetchUtil saveButtonsEventRecord:@"1t"];
						[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_CAL_ACCESS_TITLE", nil) message:NSLocalizedString(@"NO_CAL_ACCESS_MSG", nil) noLocalNotif:YES];
					}
				}];
				
				return self;
			}
			
			self.eventStore = [WeiJuAppDelegate getSharedInstance].eventStore;
			self.hasAcceessToCalendar=YES;
			[self checkNumberOfCalendarChanges];
			
		}
		
		[self setUpEventData];
		
        //[self startFetcher];        
    }
    return self;
}

- (void) checkNumberOfCalendarChanges
{
	//register how many calendars we have at this point
	int numberOfCals;
	if([self.eventStore respondsToSelector:@selector(calendarsForEntityType:)]) //ios6
		numberOfCals = [[self.eventStore calendarsForEntityType:EKEntityTypeEvent] count];
	else
		numberOfCals = [self.eventStore.calendars count];
	
	if ([[WeiJuAppPrefs getSharedInstance] numberOfCals]!=numberOfCals)
	{
		
		[Utils log:@"checkNumberOfCalendarChanges: cal# %d %d", [[WeiJuAppPrefs getSharedInstance] numberOfCals], numberOfCals];
		[[WeiJuAppPrefs getSharedInstance] setNumberOfCals:numberOfCals];
		[[WeiJuAppPrefs getSharedInstance] setCheckedSelfEmail:NO];//will do self check next
	}

}

- (void) setUpEventData
{
	//NSDate *start=[NSDate date];
	self.hasServerBasedCalendar = [self checkServerBasedCalendar];
	//self.hasEventStoreChangeNotification=NO;
	
	NSInvocationOperation *checkEmailTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(initialCheckForSelfEmails) object:nil];
	[checkEmailTask setQueuePriority:NSOperationQueuePriorityLow];
	[checkEmailTask setThreadPriority:1.0];
	[self.checkEmailQ addOperation:checkEmailTask];
	//[self initialCheckForSelfEmails];
	
	self.eventDayEvents = [[NSMutableArray alloc] init];
	self.eventDaySections = [[NSMutableArray alloc] init];
	
	self.currentDaySectionIndex = -1;
	//[self.eventStore reset];
	[self fetchEventsFromPastDays:PAST_DAYS toNextDays:FUTURE_DAYS]; //fetch events from the past xx days, to the next yy days
	
	self.hasLoadedEvents=YES; //has to be here, for the next reloadData to work proerly
			
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(eventDataBaseChanged:)
												 name:EKEventStoreChangedNotification object:nil];
	//NSLog(@"setup duration is %g", [[NSDate date] timeIntervalSinceDate:start]);
}

- (BOOL) checkServerBasedCalendar
{
	BOOL result=NO;
	for(EKCalendar *ical in self.eventStore.calendars)
	{
		if(ical.type==EKCalendarTypeCalDAV || ical.type==EKCalendarTypeExchange)
			result=YES;
	}
	return result;
}

- (NSString *) listOfAllCalendars
{
	NSArray *iCalSourceTypes = [[NSArray alloc] initWithObjects:@"Local", @"Exchange", @"CalDAV", @"MobileMe", @"Subscription", @"Birthdays", nil];
	//int counter=1;
	
	NSString* result=@"";
	for(EKCalendar *ical in self.eventStore.calendars)
	{
		//[Utils log:@"ical %d: title=%@ | type=%@ | source=%@ | subsribed=%d", counter, ical.title, [iCalTypes objectAtIndex:ical.type], ical.source, ical.subscribed];
		//counter++;
		result=[result stringByAppendingFormat:@"<source:%@|%@|%@>", [self extractCalTypeTitle:ical.source.description], ical.source.title, [iCalSourceTypes objectAtIndex:ical.source.sourceType]];
	}
	return result;
	/*
	 ical 4: title=Work | type=CalDAV | source=EKSource <0x3b4910> {UUID = 29F1A098-7318-4B30-83D0-F17AD50093A7; type = CalDAV; title = iCloud; externalId = 29F1A098-7318-4B30-83D0-F17AD50093A7} | subsribed=0
	 2012-10-09 23:47:05.258 WeiJu[9083:707] ical 5: title=Calendar | type=Exchange | source=EKSource <0x3b49b0> {UUID = 50F10A0C-B56D-4E87-959C-3034FA855C6F; type = Exchange; title = Exchange; externalId = 97039D42-B673-4F0E-96E2-25C3E00BF3F8} | subsribed=0
	 */
}

//return: type = CalDAV; title = iCloud
- (NSString *) extractCalTypeTitle:(NSString *) source
{
	NSString *type = [source substringFromIndex:[source rangeOfString:@"type = "].location];
	if (type!=nil) {
		type = [type substringToIndex:[type rangeOfString:@"; externalId"].location];
		if (type!=nil)
			return type;
	} 

	return @"";
}

- (void) releaseResource
{
	//if(self.eventChangeTimer!=nil)
	//	[self.eventChangeTimer invalidate];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.eventStore=nil;
	self.eventDaySections=nil;
	self.eventDayEvents=nil;
	self.weiJuListVCtrl=nil;
	//self.hasServerBasedCalendar=nil;
	self.hasLoadedEvents=NO;
	
	[self.eventChangeBuf removeAllObjects];
	[self.eventChangeQ cancelAllOperations];
	[self.eventHistQ cancelAllOperations];
	[self.checkEmailQ cancelAllOperations];
}

#pragma mark - coredata methods
- (void) startFetcher //search all from coredata
{    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"weiJuId" ascending:YES] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WeiJuData" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];   
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:nil] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
       [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [error userInfo], error];
    }   
}

-(void) initialCheckForSelfEmails
{
	FriendData *myself = [[WeiJuAppPrefs getSharedInstance] friendData]; //frienddata already searched and saved at appdelegate, hence it is safe here to load it on another thread (no search on coredata)
	
	if(myself==nil)
	{
		[Utils log:@"initialCheckForSelfEmails: error - can't find myself friendData"];
		return;
	}

	//comment out the next line in release
	//[[WeiJuAppPrefs getSharedInstance] setFoundSelfEmail:NO];
	
	if([[WeiJuAppPrefs getSharedInstance] checkedSelfEmail]==NO)
	{
		NSCalendar *gregorian = [NSCalendar autoupdatingCurrentCalendar];//[[NSCalendar alloc]
								// initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSDate *todayDate = [NSDate date];
		NSDateComponents *comps = [gregorian components:NSYearCalendarUnit |NSMonthCalendarUnit |NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit fromDate:todayDate];
		[comps setHour:0];
		[comps setMinute:0];
		todayDate = [gregorian dateFromComponents:comps]; 
		
		NSDate *startDate = [NSDate dateWithTimeInterval:-(86400*2*365) sinceDate:todayDate];	
		NSDate *endDate = [NSDate dateWithTimeInterval:(86400*90) sinceDate:todayDate];
		
		NSPredicate *predicate = [self.eventStore  predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil]; 
		
		NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
		//NSDate *start = [NSDate date];
		if(events != nil && [events count]>0)
		{
			//get the email array first
			NSString *emailAddrs = @"";
			//NSString *URNs = @"";
			
			NSString *URN;
			NSString *emailAddr;
						
			for (EKEvent *event in events)
			{
				NSDictionary *foundEmailOrURNResult = [Utils getMyEmailFromEvent: event];
				if(foundEmailOrURNResult!=nil)
				{
					emailAddr = [foundEmailOrURNResult valueForKey:@"email"];
					URN = [foundEmailOrURNResult valueForKey:@"urn"];
					
					//note, they both have () around them now
					//NSLog(@"myself: %@", myself.userEmails);
					if(emailAddr!=nil && [emailAddrs rangeOfString:emailAddr].location==NSNotFound && [myself.userEmails rangeOfString:emailAddr].location==NSNotFound )
						emailAddrs = [emailAddrs stringByAppendingString:emailAddr]; //this is a new email found
					
					if(URN!=nil && [emailAddrs rangeOfString:URN].location==NSNotFound && [myself.userEmails rangeOfString:URN].location==NSNotFound )
						emailAddrs =[emailAddrs stringByAppendingString:URN]; //add a new URN to emailAddrs as well (even though it is not an email addr per se, it is just an id)
				}
				
			}//for loop
			
			if(emailAddrs.length>0)
			{
                if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
					[Utils log:@"%s [line:%d] found self email in initial check:%@",__FUNCTION__,__LINE__, emailAddrs];
                [[[Utils alloc] init] requestServerToAddEmail:emailAddrs callBack:self alertForFailure:NO];
			}
		}
		//NSLog(@"check duration is %g", [[NSDate date] timeIntervalSinceDate:start]);
	}
}

- (void) checkIfCalendarHasChanged
{
	if(self.hasLoadedEvents)
		[self.eventStore refreshSourcesIfNecessary];
}

- (void) eventDataBaseChanged:(NSNotification *)notification
{
	if(notification!=nil)
		[Utils log:@"EventStoreChangedNotif: %@", [NSDate date]]; //NSDictionary* info = [notification userInfo];
	else
		[Utils log:@"EventStoreChanged - toggle demo: %@", [NSDate date]];
	
	@synchronized(self.eventChangeBuf)
	{
		//0:add the operation since there is no prior unfinished processing
		//1:this one might have got start nbut not finsished, to play safe, let add the operation as well
		//2+: at least one must be waiting (since the queue's maxconcurrency is 1, no need to add more operations
		if([self.eventChangeBuf count]>1)
		{
			NSLog(@"skip update, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
			return;
		}
		
		NSLog(@"continue to update, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
		
		[self.eventChangeBuf addObject:[NSNull null]];
	
		NSInvocationOperation *eventChangeTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processEventChangeInThread) object:nil];
		[eventChangeTask setQueuePriority:NSOperationQueuePriorityLow];
		[eventChangeTask setThreadPriority:1.0];
		[self.eventChangeQ addOperation:eventChangeTask];
		
	}
	
	NSLog(@"exit eventDataBaseChanged, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
}

- (void) reloadDemoEvent:(BOOL)demoEvent
{
	//[self eventDataBaseChanged:nil];
	//as if there were an event change. cannot simply change self.eventDayEvents since another thread might be updating it, better use the same operation queue to wait for myturn
	
	@synchronized(self.eventDayEvents)
	{
		if(demoEvent)//add
		{
			[(NSMutableArray *)[self.eventDayEvents objectAtIndex:self.currentDaySectionIndex] insertObject:[NSNumber numberWithInt:1] atIndex:1];
		}
		else //delete
		{
			[(NSMutableArray *)[self.eventDayEvents objectAtIndex:self.currentDaySectionIndex] removeObjectAtIndex:1];
		}
	}
	
	[self.weiJuListVCtrl eventDataBaseChanged]; //this is performed on main thread!!!
}

- (void) processEventChangeInThread
{
	if(self.hasLoadedEvents==NO)
		return;
	
	self.hasServerBasedCalendar = [self checkServerBasedCalendar];//check regardless of numofcals changes or not

	//要测试是否当添加calendar的时候,会有这个通知
	[self checkNumberOfCalendarChanges];
	if([[WeiJuAppPrefs getSharedInstance] checkedSelfEmail]==NO)
		[self initialCheckForSelfEmails];
	
	//1) rebuild the event cache
	self.lastTimeTodayDate=[NSDate dateWithTimeIntervalSince1970:0]; //force a reload of event data from  eventStore
	[self fetchEventsFromPastDays:PAST_DAYS toNextDays:FUTURE_DAYS];
	
	@synchronized(self.eventChangeBuf)
	{
		[self.eventChangeBuf removeLastObject];
		NSLog(@"done with fetchEvents, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
	}
	
	//2) notify weijulistvctrl that the eventstore has changed, refresh the data
	[self.weiJuListVCtrl eventDataBaseChanged]; //this is performed on main thread!!!
}

- (BOOL) dateHasChanged
{
	//self.eventStore could be nil in ios6, bcos wjlistvctrl is calling this in its viewwillappear, while the eventstore is not init by the ios check callback
	if(self.hasLoadedEvents && [self fetchEventsFromPastDays:PAST_DAYS toNextDays:FUTURE_DAYS])
	{
		//first, remove the weijumessages from before
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		[dictionary setObject:self forKey:@"invokeObjectClass1"];
		[dictionary setObject:@"deleteMessageAndEventHistoryCoreData" forKey:@"invokeObjectMethodName1"];
		[OperationQueue addTask:@"task" operationObject:[[OperationTask alloc] init] parameters:dictionary]; 
		return YES;
	}
	else 
		return NO;
}

-(void)deleteMessageAndEventHistoryCoreData
{
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    /**delete message**/
    NSDate *startDate = [NSDate dateWithTimeInterval:-(86400*2) sinceDate:[NSDate date]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sendTime <= %@",startDate];
    [dataFetchUtil deleteObjectArray:@"WeiJuMessage" filter:predicate];
    
    /**delete clientDeleted UserEventHistory **/
	//这里只是删除用户想要删除的历史: 客户端点击clear histroy其实是逻辑删除,把isClientDeleted置为1
    NSPredicate *predicateEventHistory = [NSPredicate predicateWithFormat:@"isClientDeleted == '1'"];
    [dataFetchUtil deleteObjectArray:@"EventHistory" filter:predicateEventHistory];
    
    NSPredicate *predicateUserEventHistory = [NSPredicate predicateWithFormat:@"isUploaded == '1'"];
    [dataFetchUtil deleteObjectArray:@"UserEventHistory" filter:predicateUserEventHistory];
}


- (BOOL)fetchEventsFromPastDays:(int)pastDays toNextDays:(int)nextDays 
{
	//NSLog(@"fetchEventsFromPastDays - start");
	
	FriendData *myself = [[WeiJuAppPrefs getSharedInstance] friendData];
	if(myself==nil)
	{
		[Utils log:@"fetchEventsFromPastDays: error - can't find myself friendData"];
		return NO;
	}

	BOOL eventDBHasChanged = NO;
	NSMutableArray *prevTodayEvents;
	
	NSMutableArray *todayHandleEvents = [[NSMutableArray alloc] init];
    
	NSCalendar *gregorian = [NSCalendar autoupdatingCurrentCalendar];//[[NSCalendar alloc]
							// initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *todayDate = [NSDate date];
	NSDateComponents *comps = [gregorian components:NSYearCalendarUnit |NSMonthCalendarUnit |NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit fromDate:todayDate];
	NSInteger todayYear = [comps year];
	NSInteger todayMonth = [comps month];
	NSInteger todayDay = [comps day];
	[comps setHour:0];
	[comps setMinute:0];
	todayDate = [gregorian dateFromComponents:comps]; //today now points to 0hour:0minute
	
	if(NO/*[[WeiJuAppPrefs getSharedInstance] demo]*/)
	{
		//get the two demo events on July 14th, 2012, otherwise the other dates won't have the sharebtn tp push to demo
		[comps setYear:2012];
		[comps setMonth:9];
		[comps setDay:27];
		[comps setHour:0];
		[comps setMinute:0];
		todayYear = [comps year];
		todayMonth = [comps month];
		todayDay = [comps day];
		
		todayDate = [gregorian dateFromComponents:comps];
	}
	
	NSMutableArray *dayEvents, *daySections;
	if(self.lastTimeTodayDate!=nil) //not the first time
	{
		//check whether the today has changed
		comps = [gregorian components:NSYearCalendarUnit |NSMonthCalendarUnit |NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit fromDate:self.lastTimeTodayDate];
		if([comps year]==todayYear && [comps month]==todayMonth && [comps day]==todayDay) //today has not changed
		{
			//NSLog(@"fetchEventsFromPastDays - end0");
			return NO;
		}
		else {
			//[self.eventStore refreshSourcesIfNecessary]; //dont callit here, as it can cause another notification of evendatabase change -> recursive
			
			//I decided to treat date change the same as event change for today, so that the events in the previous today can be properly shutdown and removed from pvs dict in vctrl
			//if([comps year]==1970) //it means that the event database has changed, not today's date has really changed
			//{
				eventDBHasChanged=YES;
				prevTodayEvents= [[NSMutableArray alloc] initWithArray:[self.eventDayEvents objectAtIndex:self.currentDaySectionIndex]];
			//}
						
		}
	}

    NSDate *startDate = [NSDate dateWithTimeInterval:-(86400*pastDays) sinceDate:todayDate];	
    NSDate *endDate = [NSDate dateWithTimeInterval:(86400*nextDays) sinceDate:todayDate];
		
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil]; 
    
    NSArray *origEvents = [self.eventStore eventsMatchingPredicate:predicate];
	//NSMutableArray *todayHistoryEventList = [NSMutableArray array];
	//NSLog(@"origEvents:%@ %@",self.eventStore, origEvents);
	
	int curSectionIndex=-1;
	int todaySectionIndex = -1;
	//reset the arrays
	//self.eventDayEvents = [[NSMutableArray alloc] init];
	//self.eventDaySections = [[NSMutableArray alloc] init];
	dayEvents = [[NSMutableArray alloc] init];
	daySections = [[NSMutableArray alloc] init];
	
    if(origEvents != nil)// && [origEvents count]>0) //if==0, no processing
	{
		//now, preprocess the events so that the multi-day events (sorted by endDate weirdly) will be placed properly in the array
		NSMutableArray *events = [[NSMutableArray alloc] init];
		EKEvent *prevEvent; //=[origEvents objectAtIndex:0];
		for (EKEvent *event in origEvents) 
		{
			//if([event.title rangeOfString:@"dddd"].location!=NSNotFound)
			//	[Utils log:@"Found: %@, %@ %@ %d", event.title, event.startDate, prevEvent.startDate, [event.startDate compare:prevEvent.startDate] ];
			if(prevEvent==nil || [event.startDate compare:prevEvent.startDate]!=NSOrderedAscending) //event is not ahead of previous event
				[events addObject:event];
			else 
			{
				int b=0;
				EKEvent *correctEvent;
				for (b=[events count]-1;b>=0;b--) 
				{
					correctEvent = (EKEvent *)[events objectAtIndex:b];
					//[Utils log:@"comp: %@ %@ %d", event.startDate, correctEvent.startDate, [event.startDate compare:correctEvent.startDate] ];
					if([event.startDate compare:correctEvent.startDate]!=NSOrderedAscending)
					{
						[events insertObject:event atIndex:b+1];
						//[Utils log:@"put %@ ahead of %@", event.title, correctEvent];
						break;
					}
					if(b==0)
						[events insertObject:event atIndex:0];
				}
			}
			prevEvent = (EKEvent *)[events lastObject];
		}
		origEvents=nil;
		
		//EKEvent *event;
		NSInteger prevYear=-1, prevMonth =-1, prevDay = -1;
		NSInteger curYear=-1, curMonth =-1, curDay = -1;
		
		//for retrieving self email addr and URN
		NSString *emailAddrs = @"";
		NSString *URN;
		NSString *emailAddr;
				
		for (EKEvent *event in events)
		{
            comps = [gregorian components:NSYearCalendarUnit |NSMonthCalendarUnit |NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit fromDate:event.startDate];
			curYear = [comps year];
			curMonth = [comps month];
			curDay = [comps day];
			//[Utils log:@"%@ <%@> <%@> %d %d", event.title,event.startDate, event.endDate, curDay, prevDay];
			
			if(!(curYear==prevYear&&curMonth==prevMonth&&curDay==prevDay)) //a new date
			{
				//another new day: not the same day as the previous event
				
				//first, find out whether the new date is today
				BOOL todayFound=NO;
                if(todaySectionIndex==-1) //today not found yet
				{
					if(curYear==todayYear&&curMonth==todayMonth&&curDay==todayDay)
					{
						todaySectionIndex = curSectionIndex+1;
						todayFound=YES;
						//[Utils log:@"**************found toady: %d", self.currentDaySectionIndex];
					}
					else //not today, either before today, or past today
					{
						if([event.startDate timeIntervalSinceDate:todayDate]>0) //past today
						{	//current eventdate already passes today because there is no event today, need to create day's data
							[daySections addObject:todayDate]; //create a section entry for today
							[dayEvents addObject:[[NSMutableArray alloc] init] ]; //create an empty array for today
							curSectionIndex++;
							todaySectionIndex=curSectionIndex;
							todayFound=YES;
						}
					}
					
				}
				
				curSectionIndex++;
				[daySections addObject:event.startDate]; //create a new section, with that day's first event's start date as section date
				[dayEvents addObject:[[NSMutableArray alloc] init] ]; //create the array for all the events on the date
				
				if(todayFound) //found today, add two events to today's event array
				{
					//empty event - for table to properly scroll to today on the top of screen
					[(NSMutableArray *)[dayEvents objectAtIndex:todaySectionIndex] addObject:[NSNumber numberWithInt:0]];
					
					//add the demo event
					if([[WeiJuAppPrefs getSharedInstance] demoEventOnOff])
						[(NSMutableArray *)[dayEvents objectAtIndex:todaySectionIndex] addObject:[NSNumber numberWithInt:1]];
				}

				prevYear=curYear;
				prevMonth=curMonth;
				prevDay=curDay;
			}//the date is not today
			
			if(curYear==todayYear&&curMonth==todayMonth&&curDay==todayDay)
			{
                [todayHandleEvents addObject:event];
			}
			
			[(NSMutableArray *)[dayEvents objectAtIndex:curSectionIndex] addObject:event];
			
			//debug用,勿删
//			if(/*event.organizer!=nil && [[event.organizer.URL scheme]  isEqualToString:@"urn"]*/todaySectionIndex==curSectionIndex)
//			{
//							
//				NSLog(@"%@: \norganizer: %@ of %@", event.title, event.organizer, [event.organizer description]);
//							for (int k=0; k<MIN([event.attendees count],MAX_ATTENDEES); k++) {
//								NSLog(@"%d %@ %@", k, ((EKParticipant *)[event.attendees objectAtIndex:k]).URL, [((EKParticipant *)[event.attendees objectAtIndex:k]) description]);
//							}
//							
//				NSLog(@"today: %@ %@", event.title, event.eventIdentifier);
//			}
			
			//NSLog(@"%d/%d/%d:%@ %d %d", curYear,curMonth, curDay, event.title, curSectionIndex , todaySectionIndex);
			
			//now, find if there is new unknown self email from the event
			NSDictionary *foundEmailOrURNResult = [Utils getMyEmailFromEvent:event];
			if(foundEmailOrURNResult!=nil)
			{
				emailAddr = [foundEmailOrURNResult valueForKey:@"email"];
				URN = [foundEmailOrURNResult valueForKey:@"urn"];
				
				//note, they both have () around them now
				//NSLog(@"myself.userEmails=%@ foundeamil=%@ foundurn=%@",myself.userEmails, emailAddr, URN);
				if(emailAddr!=nil && [emailAddrs rangeOfString:emailAddr].location==NSNotFound && [myself.userEmails rangeOfString:emailAddr].location==NSNotFound )
					emailAddrs = [emailAddrs stringByAppendingString:emailAddr]; //this is a new email found
				
				if(URN!=nil && [emailAddrs rangeOfString:URN].location==NSNotFound && [myself.userEmails rangeOfString:URN].location==NSNotFound)
					emailAddrs =[emailAddrs stringByAppendingString:URN]; //add a new URN to emailAddrs as well (even though it is not an email addr per se, it is just an id)
			}

        }//for loop
		
		
		if(emailAddrs.length>0)
		{
			[[[Utils alloc] init] requestServerToAddEmail:emailAddrs callBack:self alertForFailure:NO];
			if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
				[Utils log:@"%s [line:%d] found self email in normal check: %@",__FUNCTION__,__LINE__,emailAddrs];
		}
        
    } //[events count]>0
	else //empty calendar during this time frame
	{
		//no need to do anything
	}
	
	if(todaySectionIndex==-1) //no event found or only found event before today
	{
		[daySections addObject:todayDate]; //create a section entry for today
		[dayEvents addObject:[[NSMutableArray alloc] init] ]; //create an empty array for today
		todaySectionIndex = curSectionIndex+1;
		
		//empty event - for table to properly scroll to today on the top of screen
		[(NSMutableArray *)[dayEvents objectAtIndex:todaySectionIndex] addObject:[NSNumber numberWithInt:0]];
		//demo event
		if([[WeiJuAppPrefs getSharedInstance] demoEventOnOff])
			[(NSMutableArray *)[dayEvents objectAtIndex:todaySectionIndex] addObject:[NSNumber numberWithInt:1]];
	}
	
	//now compare the new today events vs old today events, either today's date change or real event change for today
	//but why prevtodayevent!=nil: this is because if so, there was no pvc, hence no need to inform listvctrl to change pvc 
	NSString *whomToNotify=@"";
	if(eventDBHasChanged && prevTodayEvents!=nil)
	{
		NSMutableArray *todayEvents = [[NSMutableArray alloc] initWithArray:[dayEvents objectAtIndex:todaySectionIndex] ];

		//for (int j=0; j<[todayEvents count]; j++)
		for (EKEvent *event in todayEvents)
		{
			if(![event isKindOfClass:[EKEvent class]])
				continue;
			
			BOOL found=NO;
			for (EKEvent *oldEvent in prevTodayEvents)
			{
				if([oldEvent isKindOfClass:[EKEvent class]] && [ (NSString *)[[oldEvent.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] isEqualToString:(NSString *)[[event.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] ])
				{
					[prevTodayEvents removeObject:oldEvent];
					found=YES;
					break;
				}
			}//end of k
			
			if(found) //this event exist before, but its properties might have changed 
			{
				[self.weiJuListVCtrl todayEventHasChanged:event]; //redo the pvc dict, but not redispayed yet
				whomToNotify = [whomToNotify stringByAppendingString:[Utils retrieveParticipantEmails:event notIn:whomToNotify] ]; //if self is organizer, notify others
			}
			else {
				//added event, no need to do anything
				whomToNotify = [whomToNotify stringByAppendingString:[Utils retrieveParticipantEmails:event notIn:whomToNotify] ];
			}
			
		}//end of j
		
		//what's left in prevEvents are the deleted events
		for (EKEvent *oldEvent in prevTodayEvents)
		{
			if([oldEvent isKindOfClass:[EKEvent class]])
			{
				[self.weiJuListVCtrl todayEventHasBeenDeleted:oldEvent]; //shutdown the sharing for the event etc.
				
				whomToNotify = [whomToNotify stringByAppendingString:[Utils retrieveParticipantEmails:oldEvent notIn:whomToNotify] ];
			}
		}
		
		//[self.weiJuListVCtrl eventDataBaseChanged];//redisplay the table: do it later
		
		[prevTodayEvents removeAllObjects];
		[todayEvents removeAllObjects];

	}

	@synchronized(self.eventDayEvents)
	{
		self.currentDaySectionIndex = todaySectionIndex;
		self.lastTimeTodayDate = todayDate;
		if(self.eventDayEvents!=nil)
			[self.eventDayEvents removeAllObjects];
		self.eventDayEvents=dayEvents;
		if(self.eventDaySections!=nil)
			[self.eventDaySections removeAllObjects];
		self.eventDaySections = daySections;
	}

	if(eventDBHasChanged) //tell weijulistvctrl to refresh table
		[self.weiJuListVCtrl eventDataBaseChanged];//redisplay the table, BUT not for the first time
	
	//now send out the event change notification to others
	if(![whomToNotify isEqualToString:@""])
	{
		//first, itis not thread safe - have to be performed on mainthread since it will have coredata access
		//second, there is no point of doing this
		[self performSelectorOnMainThread:@selector(informCalendarUpdateToFriend:) withObject:[whomToNotify substringFromIndex:1] waitUntilDone:NO]; //get rid of the first "," in the string
	}
	
	if(todayHandleEvents != nil && [todayHandleEvents count] > 0)
	{
        //[self setUploadEkEventCoreData:event]; //record today's event into history
        NSMutableDictionary *withObject = [NSMutableDictionary dictionary];
        [withObject setObject:todayHandleEvents forKey:@"events"];
		NSInvocationOperation *eventHistTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setUploadEkEventsArrayCoreData:) object:withObject];
		[eventHistTask setQueuePriority:NSOperationQueuePriorityVeryLow];
		[eventHistTask setThreadPriority:0.0];
		[self.eventHistQ addOperation:eventHistTask];
	}
    
	//upload today's event to server, no need to do it in this version - has issues with encryption: 1024 is the max size
    //[self uploadEkEventToServer:todayHistoryEventList];
	
    return YES;
	
}

- (void) informCalendarUpdateToFriend:(NSString *)allUserEmailString
{
	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
	FriendData *me = [[WeiJuAppPrefs getSharedInstance] friendData];
	
	WeiJuMessage *message = (WeiJuMessage *)[dataFetchUtil createSavedObject:@"WeiJuMessage"];
	message.weiJuId = @"0"; //fixed
	message.sendUser = me;
	message.sendTime = [NSDate date];
	message.isSendBySelf = @"1";
	message.messageRecipients = allUserEmailString;
	message.messageType = [NSString stringWithFormat:@"%d", WEIJU_MSG_ICAL_EVENT_UPDATE];
	message.messagePushAlert=@"";
	message.isPushMessage=@"0"; //no need to push
	message.messageContentType = @"1"; //1 - text, 2 - picture
	//the following is key
	message.messageContent = @"";
	[WeiJuManagedObjectContext save];
}


-(void)uploadedEventSuccess:(NSDictionary *)dic
{
    if ([ConvertData getErrorInfo:dic] == nil)
	{
        NSArray *array = (NSArray *)[ConvertData getWithOjbect:dic];
        for (int i=0; i<[array count]; i++) {
            ((EventHistory *)[array objectAtIndex:i]).isUploaded = @"1";
        }
    }
}

- (EKEvent *) getTodayEKEventFromEventIDAfterColon:(NSString *)eventID
{
	@synchronized(self.eventDayEvents)
	{
		
		NSArray *todayEvents = [self.eventDayEvents objectAtIndex:self.currentDaySectionIndex];
		for (EKEvent *result in todayEvents)
		{
			if([result isKindOfClass:[EKEvent class]])
			{
				if ( [(NSString *)[[result.eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1] isEqualToString:eventID] )
					return result;
			}
		}
		return nil;
	}
}

-(void) uploadSelfEmailsCallBack:(NSDictionary *)dic
{
	//NSLog(@"uploadSelfEmailsCallBack: %@", dic);
	if (![ConvertData getErrorInfo:dic])
	{ //server won't put the email-in-use error here because we don't want the user know that we are doing this backend check
		//upload success
		//NSLog(@"uploadSelfEmailsCallBack: succeed");

		[[[ConvertData alloc] init] syncCoreDataWithNetDictionaryWithoutInitData:dic]; //sync local and server friedndata
		
		[[WeiJuAppPrefs getSharedInstance] setCheckedSelfEmail:YES]; //set preference, so that next time the app is started, no need to check and upload self emails, except for during the daily event refresh
	}
	else
	{
        [Utils log:@"%s [line:%d] can't upload: %@",__FUNCTION__,__LINE__, [ConvertData getValue:dic key:@"error"]];
		
		[[WeiJuAppPrefs getSharedInstance] setCheckedSelfEmail:NO]; //force rechecking event store next time (redudant, but no better easy approach now) and hence resubmit to server again

	}
}

- (void) deleteEvent:(EKEvent *)event atIndexPath:(NSIndexPath *)indexPath
{	
	//this is a potential bug: removing the event from the array, trigger the thread of fetch, then delete another event, but the previous fetch could load back this second deleted event from eventstore; but the next thread would remove the deleted event
	@synchronized(self.eventDayEvents)
	{
		[(NSMutableArray *)[self.eventDayEvents objectAtIndex:indexPath.section] removeObject:event]; //removeObjectAtIndex:indexPath.row]; //dont use row because it might have changed due to eventchnagenotification processing from prior deletion
	}
	[self.weiJuListVCtrl eventDataBaseChanged]; //simply reload the table
	
	[self.eventStore removeEvent:event span:EKSpanThisEvent commit:YES error:nil];
	//this should trigger the notification, which will also refresh the table
}

#pragma mark - data source for weijulistvctrl
- (int)numberOfSections
{
	@synchronized(self.eventDayEvents)
	{
		return [self.eventDaySections count];
	}
}

- (int)numberOfRowsInSection:(NSInteger)section;
{
	@synchronized(self.eventDayEvents)
	{
		return [((NSArray *)[self.eventDayEvents objectAtIndex:section]) count];
	}
}

- (int)todaySectionIndex
{
	@synchronized(self.eventDayEvents)
	{
		return self.currentDaySectionIndex;
	}
}

- (EKEvent *)objectInListAtIndex:(NSIndexPath *)theIndex
{
	@synchronized(self.eventDayEvents)
	{
		return [((NSArray *)[self.eventDayEvents objectAtIndex:theIndex.section]) objectAtIndex:theIndex.row];
	}
}

- (NSDate *)dateForSection:(NSInteger)section
{
	@synchronized(self.eventDayEvents)
	{
		return [self.eventDaySections objectAtIndex:section];
	}
}

-(int) getSectionIndex:(NSDate *)date
{
	@synchronized(self.eventDayEvents)
	{
		NSDateFormatter *fSelected = [[NSDateFormatter alloc] init];
		[fSelected setTimeZone:[NSTimeZone localTimeZone]];
		[fSelected setDateFormat:@"YYYY-MM-dd"];
		[fSelected setDefaultDate:date];
		NSString *selectDataStr = [fSelected stringFromDate:date];
		
		for (int i=0; i<[self.eventDaySections count]; i++) {
			
			if ([selectDataStr isEqualToString:[fSelected stringFromDate:((NSDate *)[self.eventDaySections objectAtIndex:i])]]) {
				return i;
			}
			
			if ([date compare:((NSDate *)[self.eventDaySections objectAtIndex:i])] == NSOrderedAscending ) {
				return i;
			}
		}
		return [self.eventDaySections count]-1;
	}
}


#pragma mark - event history
-(void)uploadEkEventToServer:(NSMutableArray *)todayHistoryEventList{
	//upload today's event to server, no need to do it in this version - has issues with encryption: 1024 is the max size
	NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
	NSLog(@"js=%@", [todayHistoryEventList JSONString]);
	[paraDic setObject:[DESUtils encryptUseDESDefaultKey:[todayHistoryEventList JSONString]] forKey:@"ed"];
	[[[WeiJuNetWorkClient alloc] init] requestData:@"loginAction.loginInitData" parameters:paraDic withObject:todayHistoryEventList callbackInstance:self callbackMethod:@"uploadedEventSuccess:"];
	
}

-(void *)setUploadEkEventsArrayCoreData:(NSDictionary *)withObject//:(EKEvent *)event
{
    
	//NSDictionary *withObject = (NSDictionary *)[ConvertData getWithOjbect:dict];
    NSMutableArray *todayHistoryEventList = [NSMutableArray array];
    NSArray *eventsArr = (NSArray *)[withObject objectForKey:@"events"];
	for (EKEvent *event in eventsArr)
	{
        //NSLog(@"%@",event.attendees);
        int count=0;
        for (EKParticipant* person in event.attendees) //a lot faster than traditional for-loop
        {
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setObject:person.URL forKey:@"url"];
            [dic setObject:[person description] forKey:@"description"];
            [dic setObject:event forKey:@"event"];
            [dic setObject:todayHistoryEventList forKey:@"todayHistoryEventList"];
            [self performSelectorOnMainThread:@selector(addWithDictionary:) withObject:dic waitUntilDone:YES];
            
            count++;
            if(count>MAX_ATTENDEES)
                break;
		}
		
		if(event.organizer!=nil)
		{
			NSMutableDictionary *dic = [NSMutableDictionary dictionary];
			[dic setObject:event.organizer.URL forKey:@"url"];
			[dic setObject:[event.organizer description] forKey:@"description"];
			[dic setObject:event forKey:@"event"];
			[dic setObject:todayHistoryEventList forKey:@"todayHistoryEventList"];
			[self performSelectorOnMainThread:@selector(addWithDictionary:) withObject:dic waitUntilDone:YES];
		}
    }
}

-(void) addWithDictionary:(NSDictionary *)dic{
    NSURL *url = (NSURL *)[dic objectForKey:@"url"];
	if([url relativeString]==nil)
		return;

    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    EKEvent *event = (EKEvent *)[dic objectForKey:@"event"];
    NSMutableArray *todayHistroyEventList = (NSMutableArray *)[dic objectForKey:@"todayHistoryEventList"];
    NSString *description = (NSString *)[dic objectForKey:@"description"];
    [self add:url description:description friendData:nil event:event toTodayEventHistory:todayHistroyEventList with:dataFetchUtil];
}

- (void) add:(NSURL *)url description:(NSString *)ekdescription friendData:(FriendData *)fData event:(EKEvent *)event toTodayEventHistory:(NSMutableArray *)todayHistoryEventList with:(DataFetchUtil *)dataFetchUtil
{
	int idType;
    NSString *email;
    NSString *URNEmail;
    bool isSetUpload = false;
	
	FriendData *friendD = fData;
	
	if(dataFetchUtil==nil)
		dataFetchUtil = [[DataFetchUtil alloc] init];
	
	if([[url scheme] isEqualToString:@"mailto"]) //it is email address
	{
		idType = 1;
		email = [[[url relativeString] substringFromIndex:[@"mailto:" length]] lowercaseString];
	}
	else //if([[url scheme] isEqualToString:@"urn"])
	{
		idType = 0;
		email = [[url relativeString] lowercaseString];
		
		//extract the URNEmail
		ekdescription = [ekdescription substringFromIndex:[ekdescription rangeOfString:@"{"].location];
		ekdescription = [ekdescription substringToIndex:[ekdescription rangeOfString:@"}"].location];
		NSRange emailStringRange = [ekdescription rangeOfString:@"email"];
		if(emailStringRange.location!=NSNotFound)
		{
			URNEmail = [ekdescription substringFromIndex:emailStringRange.location];
			URNEmail = (NSString *)[[URNEmail componentsSeparatedByString:@";"] objectAtIndex:0];
			URNEmail = [(NSString *)[[URNEmail componentsSeparatedByString:@" "] lastObject] lowercaseString];
			
			if(URNEmail!=nil && [URNEmail rangeOfString:@"@"].location==NSNotFound) //it is not a valid email address
				URNEmail=nil;
			
		}
	}
	
	NSArray *friendDataResult;
	//first, decide this user has frienddata or not; if no, don't create for him/her
	if(fData==nil)
	{
		if(idType==0) //URN
		{
			friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",email]];
			if((friendDataResult==nil || [friendDataResult count]==0)&&URNEmail!=nil)
				friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",URNEmail]];
		}
		else
			//friendDataResult = [dataFetchUtil searchObjectArray:@"eventHistory" managedObjectName:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",email]];
			friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userEmails like" stringByAppendingFormat:@"'*(%@)*'",email]];
		//NSLog(@"friendDataResult:%@", friendDataResult);
		if(friendDataResult==nil || [friendDataResult count]==0)
			return;
		else 
			friendD = (FriendData *)[friendDataResult objectAtIndex:0];
	}
	
	NSArray *searchPropertyArray;
	if(idType==0 && URNEmail!=nil)
		searchPropertyArray = [dataFetchUtil searchObjectArray:@"EventHistory" filterString:[@"" stringByAppendingFormat:@"ekEventFullId == '%@' and email='%@'",[event eventIdentifier],URNEmail]];
	else 
		searchPropertyArray = [dataFetchUtil searchObjectArray:@"EventHistory" filterString:[@"" stringByAppendingFormat:@"ekEventFullId == '%@' and email='%@'",[event eventIdentifier],email]];
	
	EventHistory *eventHistory;
	
	if (searchPropertyArray == nil || [searchPropertyArray count] <= 0 ) 
	{
		eventHistory = (EventHistory *)[dataFetchUtil createSavedObject:@"EventHistory"];
		
		//NOTE: need to copy the event content such as string, not copy the pointer which will block the system from releasing the event
		eventHistory.ekEventId =[NSString stringWithString: [[[event eventIdentifier] componentsSeparatedByString:@":"] objectAtIndex:1] ];
		eventHistory.ekEventFullId =[NSString stringWithString: [event eventIdentifier]];
		/*
		if(event.title==nil|| [event.title isEqualToString:@""])
		{
			eventHistory.title = @"New Event";
		}
		else
			eventHistory.title =[NSString stringWithString: event.title];
		
		if (event.location == nil|| [event.location isEqualToString:@""])
			eventHistory.location = @"Place unspecified";
		else 
			eventHistory.location=[NSString stringWithString:event.location];
		*/
		eventHistory.title = [[[Utils alloc] init] getEventProperty:event.title nilReplaceMent:@"New Event"];
		eventHistory.location = [[[Utils alloc] init] getEventProperty:event.location nilReplaceMent:@"Place unspecified"];
		
		eventHistory.startTime =[NSDate dateWithTimeInterval:0 sinceDate:event.startDate];
		
		if (!isSetUpload && todayHistoryEventList!=nil) {
			eventHistory.isUploaded = @"1";
			NSMutableDictionary *eventHistoryDic = [NSMutableDictionary dictionary];    
			[eventHistoryDic setObject:eventHistory.ekEventId forKey:@"ekEventId"];
			[eventHistoryDic setObject:eventHistory.title forKey:@"title"];
			[eventHistoryDic setObject:eventHistory.location forKey:@"location"];
			[eventHistoryDic setObject:[ConvertUtil convertDateToString:eventHistory.startTime dateFormat:@"YYYY-MM-dd HH:mm:ss"] forKey:@"startDate"];
			[todayHistoryEventList addObject:eventHistoryDic];
			isSetUpload = true;
		}else {
			eventHistory.isUploaded = @"0";
		}
		eventHistory.isClientDeleted = @"0";

		if(idType==0 && URNEmail!=nil)
			eventHistory.email = URNEmail;
		else
			eventHistory.email = email;
	}
	else {
		//found one, need to update its content in case event has changed
		eventHistory = (EventHistory *)[searchPropertyArray objectAtIndex:0];
		eventHistory.title = [[[Utils alloc] init] getEventProperty:event.title nilReplaceMent:@"New Event"];
		eventHistory.location = [[[Utils alloc] init] getEventProperty:event.location nilReplaceMent:@"Place unspecified"];
		
		eventHistory.startTime =[NSDate dateWithTimeInterval:0 sinceDate:event.startDate];
		
		//NSLog(@"add event:%@ for %@ %@, %@", event.title, email, URNEmail, eventHistory.isClientDeleted);
		//eventHistory.isClientDeleted = @"0";
		//NOTE: do we need to add it to todayHistoryEventList?
	}
	
	//friendD.lastMeetingTitle = [NSString stringWithString: eventHistory.title];
	friendD.lastMeetingDate = [NSDate dateWithTimeInterval:0 sinceDate:eventHistory.startTime];
	//NSLog(@"update: %@ for %@, %@",event.title,friendD.userLogin, friendD.lastMeetingDate);
	friendD.lastMeetingLocation = [NSString stringWithString:eventHistory.location];
}

- (WeiJuData *) weiJuDataObjectInListAtIndex:(NSIndexPath *)theIndex 
{    
    return [self.fetcher objectAtIndexPath:theIndex];
}

- (void)addWeiJu:(WeiJuData *) weiJuData {
    //if(weiJuData!=nil)
    //    [self.weiJuList addObject:weiJuData];
}

#pragma mark - Fetched results controller callbacks
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
// A delegate callback called by the fetched results controller when its content 
// changes.  If anything interesting happens (that is, an insert, delete or move), we 
// respond by reloading the entire table.  This is rather a heavy-handed approach, but 
// I found it difficult to correctly handle the updates.  Also, the insert, delete and 
// move aren't on the critical performance path (which is scrolling through the list 
// loading thumbnails), so I can afford to keep it simple.
{
    if([[[anObject class] description] isEqualToString:@"WeiJuData"]){
        switch (type) {
            case NSFetchedResultsChangeInsert: {
                WeiJuData *weiJuData = (WeiJuData *)anObject;
                if(weiJuData.weiJuId != nil){
                    if([weiJuData.weiJuId intValue] == 0){
                        //create weiju to send data to server
                        NSMutableDictionary *withObjectDictionary = [NSMutableDictionary dictionary];
                        [withObjectDictionary setValue:weiJuData forKey:@"weiJuData"];
                        [withObjectDictionary setValue:weiJuData.lastMessage forKey:@"weijumessage"];
                        
                        NSMutableDictionary *paraDictionary = [NSMutableDictionary dictionary];
                        [paraDictionary setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs userId] forKey:@"userId"];
                        [paraDictionary setObject:[weiJuData.weiJuType stringValue] forKey:@"partyType"];
                        [paraDictionary setObject:[ConvertUtil convertDateToString:weiJuData.inviteDate dateFormat:@"YYYY-MM-dd HH:mm:ss"]  forKey:@"partyTime"];
                        [paraDictionary setObject:weiJuData.lastMessage.messageType forKey:@"messageType"];
                        [paraDictionary setObject:weiJuData.lastMessage.messageContentType forKey:@"messageContentType"];
                        [paraDictionary setObject:[ConvertUtil convertStrToIntStr:weiJuData.inviteUserIds] forKey:@"partyPersonUserIds"];
                        [paraDictionary setObject:weiJuData.lastMessage.messageContent forKey:@"messageContent"];
                        [paraDictionary setObject:weiJuData.inviteLocation.locationId forKey:@"partyLocationId"];
                        [[[WeiJuNetWorkClient alloc] init] requestData:@"userPartyMessageAction.createParty" parameters:paraDictionary withObject:withObjectDictionary callbackInstance:self callbackMethod:@"createWeiJuOperationDone:"];
						
                        //如果当前界面在发送Weiju的ChatViewCtrl上,那么需要刷新ChatViewCtrl的聊天信息
                        //if([weiJuData.weiJuClientId isEqualToString:[ChatVCtrl getSharedInstance].selfWeiJuData.weiJuClientId]){
                        //    [[ChatVCtrl getSharedInstance].chatDCtrl startFetcherWithWeiJuClientId:weiJuData.weiJuClientId];
                        //    [[ChatVCtrl getSharedInstance] sendAndReceiveMessageDone];
                        //}
                    }
                }
                
                [[WeiJuListVCtrl getSharedInstance].tableView reloadData];                
            } break;
            case NSFetchedResultsChangeDelete: {
                [[WeiJuListVCtrl getSharedInstance].tableView reloadData];
            } break;
            case NSFetchedResultsChangeMove: {
                [[WeiJuListVCtrl getSharedInstance].tableView reloadData];
            } break;
            case NSFetchedResultsChangeUpdate: {
                [[WeiJuListVCtrl getSharedInstance].tableView reloadData];
            } break;
            default: {
                [[WeiJuListVCtrl getSharedInstance].tableView reloadData];
            } break;
        }
    }
    
}


#pragma mark - network callback
-(void) createWeiJuOperationDone:(NSDictionary *) messageData
{
    if(messageData == nil)return;
    NSArray *result = ((NSArray *)[messageData objectForKey:@"netarray"]);
    if([messageData count] <= 0)return;
    
    NSDictionary *dictionaryAll = (NSDictionary *)[result objectAtIndex:0];
    NSString *weiJuId = (NSString *)[dictionaryAll objectForKey:@"partyId"];
    NSString *messageSendId = (NSString *)[dictionaryAll objectForKey:@"messageSendId"];
    
    NSMutableDictionary *dictionary = ((NSMutableDictionary *)[messageData objectForKey:@"withObject"]);
    
    WeiJuData *weiJuData = (WeiJuData *)[dictionary valueForKey:@"weiJuData"];
    weiJuData.weiJuId = weiJuId;
    
    WeiJuMessage *message = (WeiJuMessage *)[dictionary valueForKey:@"weijumessage"];
    message.weiJuId = weiJuId;
    message.messageSendId = messageSendId;
    
    //如果当前界面在发送Weiju的ChatViewCtrl上,那么需要刷新ChatViewCtrl的聊天信息
//    if([weiJuData.weiJuClientId isEqualToString:[ChatVCtrl getSharedInstance].selfWeiJuData.weiJuClientId])
//	{
//        [[ChatVCtrl getSharedInstance].chatDCtrl startFetcher:weiJuData.weiJuId];
//        [[ChatVCtrl getSharedInstance] sendAndReceiveMessageDone];
//    }
}
-(void) getNewMessageOperationDone:(NSDictionary *) messageData
{
    //1.convert message data to WeiJuData List;
    //2.update coredata cache (fetcher will be autiomaticcaly updated, and contextChanged: will be called
    //insetnew, or update, in the context
    if(messageData == nil)return;
    NSArray *result = ((NSArray *)[messageData objectForKey:@"netarray"]);
    if([result count] <= 0)return;
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    ConvertUtil *convertUtil = [[ConvertUtil alloc] init];
    NSDictionary *dictionaryAll = (NSDictionary *)[result objectAtIndex:0];
    NSArray *partyArray = (NSArray *)[dictionaryAll objectForKey:@"party"];
    for (int i=0; i<[partyArray count]; i++) {        
        
        NSDictionary *dictionary = (NSDictionary *)[partyArray objectAtIndex:i];
        
        NSString *weiJuId = [[dictionary objectForKey:@"partyId"] stringValue];
        
        NSArray *array = [dataFetchUtil searchObjectArray:@"WeiJuData" filterString:[@"weiJuId == " stringByAppendingFormat:@"'%@'",weiJuId]];
        
        WeiJuData *weiJuData = nil;
        if(array != nil && [array count] > 0 ){
            weiJuData = [array objectAtIndex:0];        
        }else{
            weiJuData = (WeiJuData *)[dataFetchUtil createSavedObject:@"WeiJuData"]; 
            [weiJuData setPrimitiveValue:weiJuId forKey:@"weiJuId"];
            weiJuData.weiJuCell = [NSNumber numberWithInt:[[dictionary objectForKey:@"partyCellType"] intValue]];
            weiJuData.weiJuType = [NSNumber numberWithInt:[[dictionary objectForKey:@"partyType"] intValue]];
            weiJuData.weiJuScope = [NSNumber numberWithInt:[[dictionary objectForKey:@"partyScope"] intValue]];
 
        }
        
        weiJuData.inviteDate = [convertUtil convertJSONDatetoCurrentDateStr:[dictionary objectForKey:@"inviteTime"]];
        
        //search responseUsersArray of frienddata to set to weijudata
        weiJuData.inviteUserIds  = [ConvertUtil convertIntStrToStr:[dictionary objectForKey:@"inviteUserIds"]];
        
        //search requestUserArray of frienddata to set to weijudata
        NSArray *requestUserArray = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId in " stringByAppendingFormat:@"{'%@'}",[dictionary objectForKey:@"requestUserId"]]];
        weiJuData.invitor = [requestUserArray objectAtIndex:0];
        
        NSArray *locationArray = [dataFetchUtil searchObjectArray:@"Location" filterString:[@"locationId in " stringByAppendingFormat:@"{'%@'}",[dictionary objectForKey:@"inviteLocationId"]]];
        //search Locaiton  to set to weijudata
        
        weiJuData.inviteLocation = [locationArray objectAtIndex:0];
        
        //search timeAgreedUserList of frienddata to set to weijudata
        weiJuData.timeAgreedUserIds = [ConvertUtil convertIntStrToStr:[dictionary objectForKey:@"timeAgreedUserIds"]];
        
        //search locationAgreedUserList of frienddata to set to weijudata
        weiJuData.locationAgreedUserIds = [ConvertUtil convertIntStrToStr:[dictionary objectForKey:@"locationAgreedUserIds"]];
        
        //create invitor agreed status
        NSArray *friendStatusArr = [dataFetchUtil searchObjectArray:@"FriendAgreedStatus" filterString:[@"(friendUser.userId == " stringByAppendingFormat:@"'%@') AND  (weiJuData.weiJuId == '%@')",weiJuData.invitor.userId,weiJuData.weiJuId]];
        if([friendStatusArr count] < 1){
            FriendAgreedStatus *friendAgreedStatus = (FriendAgreedStatus *)[dataFetchUtil createSavedObject:@"FriendAgreedStatus"];
            friendAgreedStatus.weiJuData = weiJuData;
            friendAgreedStatus.friendUser = weiJuData.invitor;
            
            friendAgreedStatus.locationAgreed = @"1";
            friendAgreedStatus.timeAgreed = @"1";
        }

        //set agreed status to weijuagreestatus in core data
        [self setRecivedFriendAgreeStatus:weiJuData statusList:[dictionary objectForKey:@"inviteUserAgreeStatusList"]];
        
    }  
    
    if([dictionaryAll objectForKey:@"weijumessage"] != nil){
        //insert new messages
        NSArray *messageRecArray = (NSArray *)[dictionaryAll objectForKey:@"weijumessage"];
        for (int ii=0; ii<[messageRecArray count]; ii++) {                
            NSDictionary *messageDictionary = (NSDictionary *)[messageRecArray objectAtIndex:ii];
            WeiJuMessage *message = (WeiJuMessage *)[dataFetchUtil createSavedObject:@"WeiJuMessage"];
            message.weiJuId = [[NSNumber numberWithInt:[[messageDictionary objectForKey:@"partyId"] intValue]] stringValue];
            message.messageId = [[NSNumber numberWithInt:[[messageDictionary objectForKey:@"id"] intValue]] stringValue];
            message.messageClientId = [[[FileOperationUtils alloc] init] getDisName];
            message.sendTime = [convertUtil convertJSONDatetoCurrentDateStr:[messageDictionary objectForKey:@"sendTime"]];
            message.messageType = [messageDictionary objectForKey:@"partyScope"];
            message.messageContentType =[messageDictionary objectForKey:@"messageContentType"];
            message.messageContent =[messageDictionary objectForKey:@"messageContent"];
            NSArray *messageUser = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",[messageDictionary objectForKey:@"userId"]]];                
            message.sendUser = [messageUser objectAtIndex:0];
            NSArray *array = [dataFetchUtil searchObjectArray:@"WeiJuData" filterString:[@"weiJuId == " stringByAppendingFormat:@"'%@'",message.weiJuId]];
            if([array count] > 0){
                ((WeiJuData *)[array objectAtIndex:0]).lastMessage = message;
            }
                 
        }
		//震动手机,提示用户有新的信息到达
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }

    
    if([dictionaryAll objectForKey:@"messageStatus"] != nil){
        //message status
        NSDictionary *messageStatusDictionary = (NSDictionary *)[dictionaryAll objectForKey:@"messageStatus"];
        NSArray *messageDictionKeys = [messageStatusDictionary allKeys];
        for(int i = 0; i<[messageDictionKeys count];i++){
            NSString *messageSendId = [messageDictionKeys objectAtIndex:i];
            NSArray *messageStatusArray = [messageStatusDictionary objectForKey:messageSendId];
            NSArray *messageArr = (NSArray *) [dataFetchUtil searchObjectArray:@"WeiJuMessage" filterString:[@"messageSendId == " stringByAppendingFormat:@"'%@'",messageSendId]];
            if([messageArr count] > 0){
                WeiJuMessage *message = [messageArr objectAtIndex:0];
                message.messageStatusClientIds = [ConvertUtil convertMessageStatusListToStr:[self getMessageStatus:messageStatusArray]];
            }
        }
        
    } 
    
    if([dictionaryAll objectForKey:@"friendfavoriteLocation"] != nil){
        NSDictionary *friendfavoriteLocationDic = (NSDictionary *)[dictionaryAll objectForKey:@"friendfavoriteLocation"];
        NSArray *friendfavoriteLocationKeys = [friendfavoriteLocationDic allKeys];
        for(int i = 0; i<[friendfavoriteLocationKeys count];i++){
            NSString *userId = [friendfavoriteLocationKeys objectAtIndex:i];
            NSArray *friendfavoriteLocationArr = [friendfavoriteLocationDic objectForKey:userId];
            NSArray *userIdArr = (NSArray *) [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",userId]];
            if([userIdArr count] > 0){
                //delete one user's loction frist 
                [self deleteFriendFavoriteLocation:userId];
                //create
                [self createFriendFavoriteLoaction:friendfavoriteLocationArr friendUser:[userIdArr objectAtIndex:0]];
            }
        }
    }

    [WeiJuNetWorkClient setSearchEnabled:true];
}

-(void)setRecivedFriendAgreeStatus:(WeiJuData *) weiJuData statusList:(NSArray *) statusList{
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    int allAgreedCount = 0;
    int allPeople = [statusList count];
    bool hasTimeProposePerson = NO;
    bool hasTimeDelinePerson = NO;
    bool hasLocationProposePerson = NO;
    bool hasLocationDelinePerson = NO;

    //bool needSendAgree = NO;
    //int needSendAgreeType = 0;
    
    for(int a=0;a<[statusList count];a++){
        NSDictionary *agreedStatusData = (NSDictionary *)[statusList objectAtIndex:a];
        NSString *userId = [agreedStatusData objectForKey:@"userId"];
        
        NSArray *arr = [dataFetchUtil searchObjectArray:@"FriendAgreedStatus" filterString:[@"(friendUser.userId == " stringByAppendingFormat:@"'%@') AND  (weiJuData.weiJuId == '%@')",userId,weiJuData.weiJuId]];
        FriendAgreedStatus *friendAgreedStatus;    
        if([arr count] > 0){
            friendAgreedStatus = [arr objectAtIndex:0];                   
        }else{
            friendAgreedStatus = (FriendAgreedStatus *)[dataFetchUtil createSavedObject:@"FriendAgreedStatus"];
            FriendData *friendData = [[dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",userId]] objectAtIndex:0];
            friendAgreedStatus.weiJuData = weiJuData;
            friendAgreedStatus.friendUser = friendData;
        }
        friendAgreedStatus.locationAgreed = [((NSNumber *)[agreedStatusData objectForKey:@"locationStatus"]) stringValue]; ;
        friendAgreedStatus.timeAgreed = [(NSNumber *)[agreedStatusData objectForKey:@"timeStatus"] stringValue];
//        if([[((NSNumber *)[agreedStatusData objectForKey:@"locationStatus"]) stringValue] isEqual:[[NSNumber numberWithInt:WEIJU_STATUS_ACCEPT] stringValue] ] && [[(NSNumber *)[agreedStatusData objectForKey:@"timeStatus"] stringValue] isEqual:[[NSNumber numberWithInt:WEIJU_STATUS_ACCEPT] stringValue]]){
//            allAgreedCount ++;
//        }
        //如果接受到自己的状态为Propose(这种情况是发方重新Propose一个新的地点或时间),那么就重置自己的状态
        if([userId intValue] == [[[WeiJuAppDelegate getSharedInstance].appPrefs userId] intValue]){
            //判断为收方,设置收方的btn状态(从 其他状态 变成 未设置状态或同意状态)
            //normal mode
//            if([friendAgreedStatus.locationAgreed isEqualToString:[[NSNumber numberWithInt:WEIJU_STATUS_UNDECIDED] stringValue] ]){
//  /*              if ([weiJuData.currentMessageMode intValue] == WEIJU_STATUS_PROPOSE && [weiJuData.proposeDate.description isEqualToString:weiJuData.inviteDate.description]) {
//                    //agree mode
//                    weiJuData.locationBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_ACCEPT];
//                    weiJuData.currentMessageMode = [NSNumber numberWithInt:MESSAGE_STATUS_AGREED];
//                    needSendAgreeType = AGREE_LOACTION;
//                    needSendAgree = YES;
//                }else{*/
//                    //normal mode
//                    weiJuData.locationBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_UNDECIDED];
//                    weiJuData.weiJuCurrentStatus = [NSNumber numberWithInt:WEIJU_STATUS_UNDECIDED];
//               /* }*/
//				
//            }
            
            
//            if([friendAgreedStatus.timeAgreed isEqualToString:[[NSNumber numberWithInt:WEIJU_STATUS_UNDECIDED] stringValue] ]){
//				
//                //NSLog(@"%@",weiJuData.proposeDate.description);
//                //NSLog(@"%@",[weiJuData.proposeDate.description]);
//           /*     if ([weiJuData.currentMessageMode intValue] == [@"3" intValue] && [weiJuData.proposeDate.description isEqualToString:weiJuData.inviteDate.description]) {
//                    //agree mode
//                    weiJuData.timeBtnStatus = [NSNumber numberWithInt:TIME_LOCATION_STATUS_ACCEPT_OR_CONFIRMED];
//                    weiJuData.currentMessageMode = [NSNumber numberWithInt:1];
//                    if (needSendAgreeType == AGREE_LOACTION) {
//                        needSendAgreeType = AGREE_TIME_AND_LOCATION;
//                        allAgreedCount ++;
//                    }else {
//                        needSendAgreeType = AGREE_TIME;
//                    }
//                    needSendAgree = YES;
//                }else {*/
//                    //normal mode
//                    weiJuData.timeBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_UNDECIDED];
//                    weiJuData.weiJuCurrentStatus = [NSNumber numberWithInt:WEIJU_STATUS_UNDECIDED];
//             /*   } */
//                
//            }
            /*
            if (needSendAgree) {
                //send meesage to server to agree my weiju
                WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init];
                [weiJuNetWorkClient agreeRequest:weiJuData.weiJuId agreeType:[[NSNumber numberWithInt:needSendAgreeType] stringValue]];
            }
            */
            
        }
		
        //判断为收方,设置收方的btn状态(从 其他状态 变成 未设置状态)
//        if([friendAgreedStatus.locationAgreed intValue] == WEIJU_STATUS_PROPOSE){
//            hasLocationProposePerson = YES;
//        }
//        
//        //判断为收方,设置收方的btn状态(从 其他状态 变成 未设置状态)
//        if([friendAgreedStatus.timeAgreed intValue] == WEIJU_STATUS_PROPOSE){
//            hasTimeProposePerson = YES;
//        }
//        
//        //判断为收方,设置收方的btn状态(从 其他状态 变成 未设置状态)
//        if([friendAgreedStatus.locationAgreed intValue] == WEIJU_STATUS_DECLINE){
//            hasLocationDelinePerson = YES;
//        }
//        
//        //判断为收方,设置收方的btn状态(从 其他状态 变成 未设置状态)
//        if([friendAgreedStatus.timeAgreed intValue] == WEIJU_STATUS_DECLINE){
//            hasTimeDelinePerson = YES;
//        }
        
    }
    /**如果微局为自己发出的微局**/
//    if([weiJuData.invitor.userId intValue] == [[[WeiJuAppDelegate getSharedInstance].appPrefs userId] intValue]){
//        //agree btn
//        if(allAgreedCount == allPeople){
//            weiJuData.timeBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_ACCEPT];
//            weiJuData.locationBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_ACCEPT];
//        }else {
//            if(hasTimeProposePerson || hasLocationProposePerson){
//                if(hasTimeProposePerson){
//                    weiJuData.timeBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_PROPOSE];
//                }
//                if(hasLocationProposePerson){
//                    weiJuData.locationBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_PROPOSE];
//                }
//            }else if(hasTimeDelinePerson || hasLocationDelinePerson){
//                if(hasTimeDelinePerson){
//                    weiJuData.timeBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_DECLINE];
//                }
//                if(hasLocationDelinePerson){
//                    weiJuData.locationBtnStatus = [NSNumber numberWithInt:WEIJU_STATUS_DECLINE];
//                }
//            }
//        }
//        
//    }
    
    weiJuData.aggreeStatusDisplay = [[[NSNumber numberWithInt:allAgreedCount] stringValue] stringByAppendingFormat:@"/%@",[[NSNumber numberWithInt:allPeople] stringValue]];
}

-(void)deleteFriendFavoriteLocation:(NSString *)userId{
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    NSArray *friendFavoriteLocationArr = (NSArray *) [dataFetchUtil searchObjectArray:@"FriendfavoriteLocation" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",userId]];
    for(int i=0;i<[friendFavoriteLocationArr count];i++){
        FriendFavoriteLocation *friendFavoriteLocation = (FriendFavoriteLocation *)[friendFavoriteLocationArr objectAtIndex:i];
        [[WeiJuManagedObjectContext getManagedObjectContext] deleteObject:friendFavoriteLocation];
    }
}

-(void)createFriendFavoriteLoaction:(NSArray *)friendFavoriteLoactionArr friendUser:(FriendData *)friendUser{
    for (int i = 0; i < [friendFavoriteLoactionArr count]; i++) {
        DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
        FriendFavoriteLocation *friendFavoriteLocation = (FriendFavoriteLocation *)[dataFetchUtil createSavedObject:@"FriendfavoriteLocation"];
        friendFavoriteLocation.friendUser = friendUser;
        NSArray *locationArr = (NSArray *) [dataFetchUtil searchObjectArray:@"Location" filterString:[@"locationId == " stringByAppendingFormat:@"'%@'",[friendFavoriteLoactionArr objectAtIndex:i]]];
        if([locationArr count] > 0){
            friendFavoriteLocation.friendLocation = [locationArr objectAtIndex:0];
        }else{
           
            [Utils log:@"%s [line:%d] Error:create find Location in Local DataBase",__FUNCTION__,__LINE__];
        }
    }
}


-(NSArray *)getMessageStatus:(NSArray *) messageStatusList{
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    NSMutableArray *messageStatusSaveList = [[NSMutableArray alloc] init];
    for(int i=0;i<[messageStatusList count];i++){
        MessageStatus *messageStatus = (MessageStatus *)[dataFetchUtil createSavedObject:@"MessageStatus"];
        NSDictionary *messageStatusDic = (NSDictionary *)[messageStatusList objectAtIndex:i];
        //search user id from frienddata
        messageStatus.messageStatusClientId = [[[FileOperationUtils alloc] init] getDisName];
        messageStatus.userId = [messageStatusDic objectForKey:@"responseUserId"];
        FriendData *receiveUser = (FriendData *)[[dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",[messageStatusDic objectForKey:@"responseUserId"]]] objectAtIndex:0]; 
        messageStatus.receiveUser = receiveUser;
        messageStatus.messageStatus = [NSNumber numberWithInt:[[messageStatusDic objectForKey:@"readStatus"] intValue]];
        [messageStatusSaveList addObject:messageStatus];
    }
    return messageStatusSaveList;
}

@end
