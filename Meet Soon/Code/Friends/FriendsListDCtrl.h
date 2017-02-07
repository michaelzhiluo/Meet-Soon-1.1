//
//  FriendsListDCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FriendData;

@interface FriendsListDCtrl : NSObject<NSFetchedResultsControllerDelegate> 

@property (nonatomic, retain) NSMutableArray *friendDataAllList;

@property (nonatomic, retain) NSMutableArray *friendDataAllSectionList;

@property (nonatomic, retain) NSMutableArray *friendDataSearchList;

@property (nonatomic, retain) NSMutableArray *friendDataSearchSectionList;

@property (nonatomic, retain) NSMutableDictionary *friendEmailsDictionary;
@property (nonatomic, retain) NSMutableDictionary *addressBookDictionary;
@property (nonatomic, retain) NSMutableArray *addressBookSectionsArr;
@property (nonatomic, retain) NSMutableArray *addressBookCurrentSearchArr;
@property (nonatomic, retain) NSString *addressBookCurrentSearchStr;
@property (nonatomic, retain) NSMutableArray *addressBookSearchAllArr;

@property (nonatomic, retain) NSFetchedResultsController *fetcher;

@property (retain, nonatomic) NSMutableArray *eventChangeBuf;
@property (retain, nonatomic) NSOperationQueue *eventChangeQ;
@property (retain, nonatomic) NSNull *addrMutex;

@property (assign, nonatomic) BOOL hasAcceessToAddr;
@property (assign, nonatomic) BOOL hasLoadedAddr;
- (void) getAccessToAddr;
//- (void) openAddrBook; //called by flistvctrl
- (void) closeAddrBook;
- (ABAddressBookRef) getAddressBook;
- (NSData *)getImageByRecordID:(int32_t) abRecordID;

- (int)numberOfSections;

- (int)numberOfRowsInSection:(NSInteger)section;

- (NSArray *)sectionIndexTitles;

- (FriendData *)objectInListAtIndex:(NSIndexPath *)theIndex;

- (void)contextChanged:(NSNotification *)note;

- (NSDictionary *)adbObjectInListAtIndex:(NSIndexPath *)theIndex;

- (int)adbNumberOfRowsInSection:(NSInteger)section;

- (int)adbNumberOfSections;

- (NSArray *)adbSectionIndexTitles;

- (void) startAddressBookSearch;

+(FriendsListDCtrl *)getSharedInstance;

- (void) startSearch;

- (void) processAddrChange:(BOOL)reopenABR;

- (void) reset;

@end
