//
//  WeiJuManagedObjectContext.m
//  WeiJu
//
//  Created by Michael Luo on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuManagedObjectContext.h"
#import "WeiJuNetWorkClient.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "Utils.h"
#import "DataFetchUtil.h"
#import "FriendData.h"
static NSMappingModel *managedObjectModel;
static NSPersistentStoreCoordinator *persistentStoreCoordinator;
static NSTimer *saveTimer;
static NSTimer *saveTimerWithContentName;
static NSMutableDictionary *contextDictionary;
static int savedDelayTime= 5.0;
@implementation WeiJuManagedObjectContext
@synthesize contextName;

+ (void)save
{
    // Disable the auto-save timer. which could have been started
    [saveTimer invalidate];
    saveTimer = nil;    
    // Save.
    NSError *error;
    if ( ([WeiJuManagedObjectContext getManagedObjectContext] != nil) && [[WeiJuManagedObjectContext getManagedObjectContext] hasChanges] ) {
        BOOL success = [[WeiJuManagedObjectContext getManagedObjectContext] save:&error];
        if (success) {
            error = nil;
        }else{
            [Utils log:@"%s [line:%d] Save WeiJuContext Error:%@,%@",__FUNCTION__,__LINE__, [error userInfo], error];
        }
    }
    
}

+ (void)quickSave{
    NSError *error;
    if ( ([WeiJuManagedObjectContext getManagedObjectContext] != nil) && [[WeiJuManagedObjectContext getManagedObjectContext] hasChanges] ) {
        BOOL success = [[WeiJuManagedObjectContext getManagedObjectContext] save:&error];
        if (success) {
            error = nil;
        }else{
            [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [error userInfo], error];

        }
    }
}

+ (void) saveAll{
    if (contextDictionary != nil) {
        NSArray *allContextKey = [contextDictionary allKeys];
        for (int i=0; i <[allContextKey count] ; i++) {
            NSManagedObjectContext *managedObjectContext = [contextDictionary objectForKey:[allContextKey objectAtIndex:i]];
            NSError *error;
            if ( (managedObjectContext != nil) && [managedObjectContext hasChanges] ) {
                BOOL success = [managedObjectContext save:&error];
                if (success) {
                    error = nil;
                }else{
                    [Utils log:@"%s [line:%d] Save WeiJuContext:(%@) Error:%@",__FUNCTION__,__LINE__, [allContextKey objectAtIndex:i],[error userInfo]];
                }
            }
        }
    }

}

+ (void)saveWithContextName:(NSTimer *)timer 
{
    // Disable the auto-save timer. which could have been started
    [saveTimerWithContentName invalidate];
    saveTimerWithContentName = nil;    
    // Save.
    NSString *contenxtNameTemp = [timer.userInfo string];
    NSError *error;
    if ( ([WeiJuManagedObjectContext getManagedObjectContextWithContextName:contenxtNameTemp] != nil) && [[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contenxtNameTemp] hasChanges] ) {
        BOOL success = [[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contenxtNameTemp] save:&error];
        if (success) {
            error = nil;
        }else{
            
            [Utils log:@"%s [line:%d] Save WeiJuContext:%@ Error:%@",__FUNCTION__,__LINE__, contenxtNameTemp,[error userInfo]];
        }
    }
    
}

+ (void)quickSaveWithContextName:(NSString *)contextName{
    NSError *error;
    if ( ([WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName] != nil) && [[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName] hasChanges] ) {
        BOOL success = [[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName] save:&error];
        if (success) {
            error = nil;
        }else{
            [Utils log:@"%s [line:%d] Save WeiJuContext:%@ Error:%@",__FUNCTION__,__LINE__, contextName,[error userInfo]];
        }
    }
}

+ (void)contextChangedWithContentName:(NSNotification *)note{
    if (saveTimerWithContentName != nil) {
        [saveTimerWithContentName invalidate];
    }
    NSString *contextName = ((WeiJuManagedObjectContext *)note.object).contextName;
    saveTimerWithContentName = [NSTimer scheduledTimerWithTimeInterval:savedDelayTime target:self selector:@selector(saveWithContextName:) userInfo:contextName repeats:NO];
}

+ (void)contextChanged:(NSNotification *)note{
    if (saveTimer != nil) {
        [saveTimer invalidate];
    }
    saveTimer = [NSTimer scheduledTimerWithTimeInterval:savedDelayTime target:self selector:@selector(save) userInfo:nil repeats:NO];
}

+ (NSManagedObjectContext *) getNotificationChangedContextWithContextName:(NSString *) contextName{
    
    if (contextDictionary == nil) {
        contextDictionary = [NSMutableDictionary dictionary];
    }
    NSManagedObjectContext *managedObjectContext;
    if([contextDictionary objectForKey:contextName] == nil){
        
        managedObjectContext = [WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName];
        //add observer to NSManagedObjectContext
        WeiJuManagedObjectContext *weiJuManagedObjectContext = [[WeiJuManagedObjectContext alloc] init];
        weiJuManagedObjectContext.contextName = contextName;
        [[NSNotificationCenter defaultCenter] addObserver:[[WeiJuManagedObjectContext alloc] init] selector:@selector(contextChangedWithContentName:) name:NSManagedObjectContextObjectsDidChangeNotification object:[self getManagedObjectContextWithContextName:contextName] ];
        [contextDictionary setObject:contextDictionary forKey:contextName];
    }
    return managedObjectContext;
}

+ (NSManagedObjectContext *) getNotificationChangedWeiJuContext{
    if (contextDictionary == nil) {
        contextDictionary = [NSMutableDictionary dictionary];
    }
    NSManagedObjectContext *managedObjectContext;
    if([contextDictionary objectForKey:@"default"] == nil){
        
        managedObjectContext = [self getManagedObjectContext];
        //add observer to NSManagedObjectContext
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:[WeiJuManagedObjectContext getManagedObjectContext] ];
        [contextDictionary setObject:contextDictionary forKey:@"default"];
    }
    return managedObjectContext;
}



+ (NSManagedObjectContext *) getManagedObjectContext {
	//NSLog(@"getManagedObjectContext.....%@ %@", [NSThread currentThread], [NSThread mainThread]);
    if (contextDictionary == nil) {
        contextDictionary = [NSMutableDictionary dictionary];
    }
    NSManagedObjectContext *managedObjectContext;
    if([contextDictionary objectForKey:@"default"] == nil){
  
        NSPersistentStoreCoordinator *coordinator = [self getPersistentStoreCoordinator];
        if (coordinator != nil) {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator: coordinator];
        }
        [contextDictionary setObject:managedObjectContext forKey:@"default"];
        
    }
    return [contextDictionary objectForKey:@"default"];	
}

+ (NSManagedObjectContext *) getManagedObjectContextWithContextName:(NSString *)contextName {
	
    if (contextDictionary == nil) {
        contextDictionary = [NSMutableDictionary dictionary];
    }
    NSManagedObjectContext *managedObjectContext;
    if([contextDictionary objectForKey:contextName] == nil){
        
        NSPersistentStoreCoordinator *coordinator = [self getPersistentStoreCoordinator];
        if (coordinator != nil) {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setUndoManager:nil];
            [managedObjectContext setPersistentStoreCoordinator: coordinator];
            [managedObjectContext setStalenessInterval:0.0]; 
            [managedObjectContext setMergePolicy:NSOverwriteMergePolicy]; 
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeContextChangesForNotification:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext]; 
        }
        [contextDictionary setObject:managedObjectContext forKey:contextName];
        
    }
    
    return [contextDictionary objectForKey:contextName];	
}

+ (void)mergeOnMainThread:(NSNotification *)aNotification 
{ 
    [[WeiJuManagedObjectContext getManagedObjectContext] mergeChangesFromContextDidSaveNotification:aNotification];
/** for debug    
    NSArray *searchList1 = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:nil];
    for (int i=0; i < [searchList1 count]; i++) {
        FriendData *friendData = (FriendData *)[searchList1 objectAtIndex:i];
        [Utils log:@"%s [line:%d] info:%@:%@:%@",__FUNCTION__,__LINE__,friendData.userId,friendData.userName,friendData.userNameSectionTitle];
    }
    
    NSArray *searchList2 = [[[DataFetchUtil alloc] init] searchObjectArray:@"sync" managedObjectName:@"FriendData" filterString:nil];
    for (int i=0; i < [searchList2 count]; i++) {
        FriendData *friendData = (FriendData *)[searchList2 objectAtIndex:i];
        [Utils log:@"%s [line:%d] info:%@:%@:%@",__FUNCTION__,__LINE__,friendData.userId,friendData.userName,friendData.userNameSectionTitle];
    }
    
    NSArray *searchList3 = [[[DataFetchUtil alloc] init] searchObjectArray:@"sync3" managedObjectName:@"FriendData" filterString:nil];
    for (int i=0; i < [searchList3 count]; i++) {
        FriendData *friendData = (FriendData *)[searchList3 objectAtIndex:i];
        [Utils log:@"%s [line:%d] info:%@:%@:%@",__FUNCTION__,__LINE__,friendData.userId,friendData.userName,friendData.userNameSectionTitle];
    }
**/
} 

+ (void)mergeContextChangesForNotification:(NSNotification *)aNotification 
{ 
    [self performSelectorOnMainThread:@selector(mergeOnMainThread:) withObject:aNotification waitUntilDone:YES]; 
} 


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
+ (NSManagedObjectModel *)getManagedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
+ (NSPersistentStoreCoordinator *)getPersistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    //sqliteFileName = [sqliteFileName stringByAppendingFormat:@"%@",[WeiJuNetWorkClient getMyUserId]];
    NSString *sqliteFileName = [currentAppVersion stringByAppendingString:@".sqlite"];
	//此处还应该删除以前版本的sqlite文件

    //得到数据库的路径  
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];  
    //CoreData是建立在SQLite之上的，数据库名称需与Xcdatamodel文件同名  
    NSURL *storeUrl = [NSURL fileURLWithPath:[docs stringByAppendingPathComponent:sqliteFileName]];  
    
    NSError *error = nil;  
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:[self getManagedObjectModel]];  
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]){  
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [error userInfo], error];
    }  
    
    return persistentStoreCoordinator;  

}

+ (void)deleteSqlistFile{
    
    if (contextDictionary != nil) {
        NSArray *allContextKey = [contextDictionary allKeys];
        for (int i=0; i <[allContextKey count] ; i++) {
            NSManagedObjectContext *managedObjectContext = [contextDictionary objectForKey:[allContextKey objectAtIndex:i]];
            managedObjectContext = nil;
        }
        contextDictionary = nil;
    }
    
    managedObjectModel = nil;
    persistentStoreCoordinator = nil;
    
    NSString *sqliteFileName = [currentAppVersion stringByAppendingString:@".sqlite"];
    
    //得到数据库的路径  
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];  
    //CoreData是建立在SQLite之上的，数据库名称需与Xcdatamodel文件同名  
    NSURL *storeUrl = [NSURL fileURLWithPath:[docs stringByAppendingPathComponent:sqliteFileName]];  
    NSError *error;
    [[[NSFileManager alloc] init] removeItemAtURL:storeUrl error:&error];
}

@end
