//
//  WeiJuListDCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WeiJuListVCtrl, WeiJuData, FriendData, DataFetchUtil;

@interface WeiJuListDCtrl : NSObject <NSFetchedResultsControllerDelegate>

@property (retain, nonatomic) WeiJuListVCtrl *weiJuListVCtrl;

@property (nonatomic, retain) NSFetchedResultsController *fetcher;

@property (retain, nonatomic) EKEventStore *eventStore;
@property (assign, nonatomic) BOOL hasAcceessToCalendar;
@property (assign, nonatomic) BOOL hasLoadedEvents; //in ios6, the events might be load in a separate thread in the callback

@property (assign, nonatomic) BOOL hasServerBasedCalendar;

@property (retain, nonatomic) NSMutableArray *eventChangeBuf;//store the evetn change operation for duplication control
@property (retain, nonatomic) NSOperationQueue *eventChangeQ;
@property (retain, nonatomic) NSOperationQueue *eventHistQ;
@property (retain, nonatomic) NSOperationQueue *checkEmailQ;

@property (retain, nonatomic) NSMutableArray *eventDaySections; //each element in the array corresponds to a day, and the value is the date for the day
@property (retain, nonatomic) NSMutableArray *eventDayEvents; //each element  maps to a NSMutableArray that contains all the events in that day
@property (assign, nonatomic) int currentDaySectionIndex;
@property (retain, nonatomic) NSDate *lastTimeTodayDate;

+ (WeiJuListDCtrl *) getSharedInstance;
- (id)initWithVC:(WeiJuListVCtrl *) vctrl;
- (void) releaseResource;

- (NSString *) listOfAllCalendars; //return description of all calsource types to cusotmer support email

//EKEvent data
- (NSDate *)dateForSection:(NSInteger)section;
- (int)numberOfSections;
- (int)todaySectionIndex;
- (int)numberOfRowsInSection:(NSInteger)section;
- (EKEvent *)objectInListAtIndex:(NSIndexPath *)theIndex;

- (EKEvent *) getTodayEKEventFromEventIDAfterColon:(NSString *)eventID;

- (void) checkIfCalendarHasChanged;

- (BOOL) dateHasChanged; //called by weijulistvctrl to check if today's date has changed
- (void) reloadDemoEvent:(BOOL)demoEvent; //called by settings to redisplay the event after demoevent is switched on/off
- (void) deleteEvent:(EKEvent *)event atIndexPath:(NSIndexPath *)indexPath;
- (void) startFetcher:(NSDate *)date;
- (void) insertDemoEvent;

//weijuData -> 1:1 mapping with EKEvent
- (void) setUpWeiJuContext;
- (void) startFetcher; //search all from coredata
- (WeiJuData *)weiJuDataObjectInListAtIndex:(NSIndexPath *)theIndex;
- (void)addWeiJu:(WeiJuData *) weiJuData;

-(NSArray *)getMessageStatus:(NSArray *) messageStatusList;
-(NSString *)getMessageStatusStr:(NSArray *) messageStatusList;

- (void)contextChanged:(NSNotification *)note;

//netowrk methods
-(void) createWeiJuOperationDone:(NSDictionary *) messageData;
-(void) getNewMessageOperationDone:(NSDictionary *) messageData;
-(void)deleteFriendFavoriteLocation:(NSString *)userId;
-(void)createFriendFavoriteLoaction:(NSArray *)friendFavoriteLoactionArr friendUser:(FriendData *)friendUser;
-(void)setFriendAgreeStatus:(WeiJuData *) weiJuData;
//convert tools
-(NSDate *)convertJSONDatetoCurrentDateStr:(NSDictionary *) JSONDate;
-(int) getSectionIndex:(NSDate *)date;

//-(NSMutableArray *)setUploadEkEventCoreData:(EKEvent *)event; //add event hist for all attendees
- (void) add:(NSURL *)url description:(NSString *)ekdescription friendData:(FriendData *)fData event:(EKEvent *)event toTodayEventHistory:(NSMutableArray *)todayHistoryEventList with:(DataFetchUtil *)dataFetchUtil; //add event hist for one attendee
@end
