//
//  FriendsListDCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FriendData;

@interface LoginDCtrl : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetcher;

- (int)numberOfSections;

- (int)numberOfRowsInSection:(NSInteger)section;

- (FriendData *)objectInListAtIndex:(NSIndexPath *)theIndex;

- (void) startFetcher; //search all from coredata

- (void)contextChanged:(NSNotification *)note;


- (void)createAccountDone;

- (void)removeAllInvaildAccount;

@end
