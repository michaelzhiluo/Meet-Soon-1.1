//
//  FriendsListDCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EventHistoryListDCtrl.h"
#import "EventHistory.h"
#import "WeiJuManagedObjectContext.h"
#import "DataFetchUtil.h"
#import "ConvertUtil.h"
#import "Character.h"
#import "Utils.h"

@implementation EventHistoryListDCtrl

@synthesize fetcher=_fetcher;


//初始化
- (id)init
{
    if (self = [super init]) 
    {        
               return self;
    }
    return nil;
}

#pragma mark - addressbook methods

#pragma mark - coredata methods
- (void) startFetcher:(NSString *)emails //search all from coredata
{     
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EventHistory" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];   
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    NSString *emailsSearchStr = [[[emails stringByReplacingOccurrencesOfString:@")(" withString:@"','"] stringByReplacingOccurrencesOfString:@"(" withString:@"'"] stringByReplacingOccurrencesOfString:@")" withString:@"'"];

    //NSLog(@"%@",emailsSearchStr);
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:[@"isClientDeleted == '0' and email in" stringByAppendingFormat:@"{%@}",emailsSearchStr],nil]]; 
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:@"root"] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, error, [error userInfo]];
    }
   
}


- (int)numberOfSections
{
    //NSLog(@"%i",[[self.fetcher sections] count]);
    return [[self.fetcher sections] count];
}

- (int)numberOfRowsInSection:(NSInteger)section;
{
    //NSLog(@"%i",[[[self.fetcher sections] objectAtIndex:section] numberOfObjects]);
    return [[[self.fetcher sections] objectAtIndex:section] numberOfObjects];
}


- (EventHistory *)objectInListAtIndex:(NSIndexPath *)theIndex {    
    return [self.fetcher objectAtIndexPath:theIndex];
}



@end
