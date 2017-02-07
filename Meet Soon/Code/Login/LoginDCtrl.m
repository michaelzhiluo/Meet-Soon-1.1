//
//  FriendsListDCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginDCtrl.h"
#import "WeiJuListDCtrl.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuData.h"
#import "LoginUser.h"
#import "FriendData.h"
#import "WeiJuManagedObjectContext.h"
#import "OperationQueue.h"
#import "DataFetchUtil.h"
#import "WeiJuNetWorkClient.h"
#import "ConvertUtil.h"
#import "LoginVCtrl.h"
#import "Utils.h"

@implementation LoginDCtrl

@synthesize fetcher=_fetcher;

//初始化
- (id)init
{
    if (self = [super init]) 
    {      
        [self startFetcher];
        return self;
    }
    return nil;
}

#pragma mark - coredata methods
- (void) startFetcher //search all from coredata
{    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"isAppDefaultLogin" ascending:YES] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LoginUser" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];   
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isAppDefaultLogin = 1"]];    
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:nil] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
        [Utils log:@"%s [line:%d] NSURLConnection error:%@, %@",__FUNCTION__,__LINE__, [error localizedDescription], [error localizedRecoverySuggestion]];
    }
   
}

#pragma mark - Fetched results controller callbacks
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
//    if([[[anObject class] description] isEqualToString:@"LoginUser"]){
        LoginUser *loginUser = (LoginUser *)anObject;
        switch (type) {
            case NSFetchedResultsChangeInsert: {
				/*
                if(loginUser.password != nil){
                    //判断是否是create account
                    WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init]; 
                    [weiJuNetWorkClient createAccount:(id)loginUser loginName:(NSString *)loginUser.loginName email:loginUser.email password:loginUser.password  callBackTarget:self callBackMethodName:@"createAccountSucceed:"];
                }
				*/
            } break;
            case NSFetchedResultsChangeDelete: {
            } break;
            case NSFetchedResultsChangeMove: {
            } break;
            case NSFetchedResultsChangeUpdate: {
            } break;
            default: {
            } break;
        }
//    }
    
}


-(void)removeAllInvaildAccount{
    
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


- (FriendData *)objectInListAtIndex:(NSIndexPath *)theIndex {    
    return [self.fetcher objectAtIndexPath:theIndex];
}


@end
