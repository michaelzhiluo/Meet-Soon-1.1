//
//  FriendsListDCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EventHistory;

@interface EventHistoryListDCtrl : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetcher;



- (int)numberOfRowsInSection:(NSInteger)section;

- (EventHistory *)objectInListAtIndex:(NSIndexPath *)theIndex;

- (void) startFetcher:(NSString *)emails; //search all from coredata



@end
