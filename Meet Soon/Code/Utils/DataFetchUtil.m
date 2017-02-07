//
//  DataPersisitenceUtil.m
//  WeiJu
//
//  Created by Michael Luo on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataFetchUtil.h"
#import "WeiJuManagedObjectContext.h"
#import "OperationQueue.h"
#import "OperationTask.h"
#import "UserEventHistory.h"
#import "ConvertData.h"
#import "Utils.h"
#import <CoreData/CoreData.h>
@implementation DataFetchUtil

-(void)deleteObjectArray:(NSString *) managedObjectName filterString:(NSString *) filterString{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];
	[fetchRequest setEntity:entity];	
    //NSLog(@"Search FilterStr:%@",filterString);
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:filterString,nil]];
    NSError *error;    
    NSArray *results = [[WeiJuManagedObjectContext getManagedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if(error == nil ){
        for(int i = 0;i<[results count];i++){
            [[WeiJuManagedObjectContext getManagedObjectContext] deleteObject:[results objectAtIndex:i]];
        }
    }else{
        [Utils log:@"%s [line:%d] error:%@, %@",__FILE__,__LINE__,__FUNCTION__, error, [error userInfo]];
        return;
    }
    
    [WeiJuManagedObjectContext quickSave];
    
}

-(void)deleteObjectArray:(NSString *) managedObjectName filter:(NSPredicate *) predicate{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];
	[fetchRequest setEntity:entity];	
    //NSLog(@"Search FilterStr:%@",filterString);
	[fetchRequest setPredicate:predicate];
    NSError *error;    
    NSArray *results = [[WeiJuManagedObjectContext getManagedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if(error == nil ){
        for(int i = 0;i<[results count];i++){
            [[WeiJuManagedObjectContext getManagedObjectContext] deleteObject:[results objectAtIndex:i]];
        }
    }else{
        [Utils log:@"%s [line:%d] error:%@, %@",__FILE__,__LINE__,__FUNCTION__, [error localizedFailureReason], [error localizedRecoverySuggestion]];
        return;
    }
    [WeiJuManagedObjectContext quickSave];
}

-(void)deleteObjectArray:(NSArray *) arrayObjectArray{
    
  for(int i = 0;i<[arrayObjectArray count];i++){
     [[WeiJuManagedObjectContext getManagedObjectContext] deleteObject:[arrayObjectArray objectAtIndex:i]];
  }
  [WeiJuManagedObjectContext quickSave];
}

-(void)deleteAllCoreData{
    [self deleteAll:@"WeiJuMessage"];
    [self deleteAll:@"EventHistory"];
    [self deleteAll:@"UserEventHistory"];
    [self deleteAll:@"FriendData"];
}


-(NSArray *)searchObjectArray:(NSString *) managedObjectName filter:(NSPredicate *) filter{
    @try{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:  [WeiJuManagedObjectContext getManagedObjectContext]];
        [fetchRequest setEntity:entity];	
        //NSLog(@"Search FilterStr:%@",filterString);
        [fetchRequest setPredicate:filter];
        NSError *error;    
    
        NSArray *results = [[WeiJuManagedObjectContext getManagedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if(error == nil ){
            return results;        
        }else{
            [Utils log:@"%s [line:%d] error:%@, %@",__FILE__,__LINE__,__FUNCTION__, [error localizedFailureReason], [error localizedRecoverySuggestion]];
            return nil;
        }
    }@catch (NSException *e) {
        @throw e;
    }
    
}

-(NSArray *)searchObjectArray:(NSString *) managedObjectName filterString:(NSString *) filterString{
    @try{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];
        [fetchRequest setEntity:entity];	
        //NSLog(@"Search FilterStr:%@",filterString);
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:filterString,nil]];
        NSError *error; 
        NSArray *results = [[WeiJuManagedObjectContext getManagedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if(error == nil ){
            return results;        
        }else{
            [Utils log:@"%s [line:%d] error:%@, %@",__FILE__,__LINE__,__FUNCTION__, [error localizedFailureReason], [error localizedRecoverySuggestion]];
            return nil;
        }
    }@catch (NSException *e) {
        @throw e;
    }
    
    
       
}

-(NSArray *)searchObjectArray:(NSString *)contextName managedObjectName:(NSString *) managedObjectName filterString:(NSString *) filterString{
    
    @try{
    
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName]];
        [fetchRequest setEntity:entity];	
        //NSLog(@"Search FilterStr:%@",filterString);
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:filterString,nil]];
        NSError *error;    
        NSArray *results = [[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName] executeFetchRequest:fetchRequest error:&error];
        if(error == nil ){
            return results;        
        }else{
            [Utils log:@"%s [line:%d] error:%@, %@",__FILE__,__LINE__,__FUNCTION__, [error localizedFailureReason], [error localizedRecoverySuggestion]];
            return nil;
        }
    }@catch (NSException *e) {
        @throw e;
    }
   
    
}


-(NSArray *)searchObjectArrayOrderby:(NSString *) managedObjectName filterString:(NSString *) filterString orderbyStrArray:(NSArray *) orderbyStrArray{
   
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:managedObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];
	[fetchRequest setEntity:entity];	
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:filterString,nil]];

    
    if (orderbyStrArray != nil && [orderbyStrArray count] > 0) {
        if ([@"NSSortDescriptor" isEqualToString:[[[orderbyStrArray objectAtIndex:0] class] description]]) {
            
            [fetchRequest setSortDescriptors:orderbyStrArray];
            
        }else {
            for(int i=0;i<[orderbyStrArray count];i++){
                
                NSString *orderbyName = (NSString *)[orderbyStrArray objectAtIndex:i];
                NSSortDescriptor *a = [[NSSortDescriptor alloc] initWithKey:orderbyName ascending:YES];
                NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:a,  nil];
                [fetchRequest setSortDescriptors:sortDescriptors];      
            
            }
        }
    }
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:filterString,nil]];	
    NSError *error;    
    NSArray *results = [[WeiJuManagedObjectContext getManagedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if(error == nil ){
        return results;        
    }else{
        [Utils log:@"%s [line:%d] error:%@, %@",__FILE__,__LINE__,__FUNCTION__, [error localizedFailureReason], [error localizedRecoverySuggestion]];
        return nil;
    }
    
}

- (NSManagedObject *)createSavedObject:(NSString *) manageObjectName{    
    return[NSEntityDescription insertNewObjectForEntityForName:manageObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];
}

- (NSManagedObject *)createSavedObject:(NSString *)contextName manageObjectName:(NSString *) manageObjectName{    
    return[NSEntityDescription insertNewObjectForEntityForName:manageObjectName inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContextWithContextName:contextName]];
}



- (void)deleteAll:(NSString *)managedObjectName{
    NSArray *searcharr = [self searchObjectArray:managedObjectName filterString:nil];
    for (int i = 0; i < [searcharr count]; i++) {
        [[WeiJuManagedObjectContext getManagedObjectContext] deleteObject:[searcharr objectAtIndex:i]];
    }
}


+ (void)saveButtonsEventRecord:(NSString *)butsCode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *withObject = [NSMutableDictionary dictionary];
    [withObject setObject:butsCode forKey:@"butsCode"];
    [withObject setObject:[[NSDate alloc] init] forKey:@"time"];
    //[dictionary setObject:@"YES" forKey:@"runInBackground1"];
    [dictionary setObject:[[DataFetchUtil alloc] init] forKey:@"invokeObjectClass1"];
    [dictionary setObject:@"saveButtonsEventRecordQueueTask:" forKey:@"invokeObjectMethodName1"];
    [dictionary setObject:withObject forKey:@"withObject"];
    [OperationQueue addTask:@"saveCoredataTask" operationObject:[[OperationTask alloc] init] parameters:dictionary]; 
}

- (void)saveButtonsEventRecordQueueTask:(NSDictionary *)dic {
    NSDictionary *withObject = (NSDictionary *)[ConvertData getWithOjbect:dic];
    UserEventHistory *userEventHistory = (UserEventHistory *)[self createSavedObject:@"UserEventHistory"];
    userEventHistory.clickTime = [withObject objectForKey:@"time"];
    userEventHistory.buttonCode = [withObject objectForKey:@"butsCode"];
    userEventHistory.isUploaded = @"0";
}

@end


