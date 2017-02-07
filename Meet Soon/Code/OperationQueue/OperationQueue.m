//
//  HttpOperationFactory.m
//  TestNSOperation
//
//  Created by Michael Luo on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OperationQueue.h"
#import "HttpOperation.h"
#import "OperationTask.h"
#import "WeiJuNetWorkClient.h"

@implementation OperationQueue

static NSMutableDictionary *dictionary;

+(void)initQueueSet{
    if(dictionary == nil)
        dictionary =[NSMutableDictionary dictionary];
}

+(void)cancelAllOperations{
    if(dictionary != nil){
        NSArray *allContextKey = [dictionary allKeys];
        for (int i=0; i <[allContextKey count] ; i++) {
            NSOperationQueue *queue = [dictionary objectForKey:[allContextKey objectAtIndex:i]];
            [queue cancelAllOperations];
        }
    }
}

+(NSOperationQueue *)getOperationQueue:(NSString *)queueName{
    if([dictionary objectForKey:queueName] == nil){
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];  
        [queue setMaxConcurrentOperationCount:1];
        [dictionary setObject:queue forKey:queueName];
    }
    return [dictionary objectForKey:queueName];
}

+(void) addTask:(NSString *)queueName operationObject:(id)operationObject  parameters:(NSMutableDictionary *) parameters{
    [self initQueueSet];
    if ([parameters objectForKey:@"queueTaskMaxSize"] != nil){
         
    }
    [((OperationTask *)operationObject) setParameter:parameters];     
    [[self getOperationQueue:queueName]  addOperation:operationObject];
}

@end
