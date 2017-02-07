//
//  OperationTask.m
//  WeiJu
//
//  Created by Michael Luo on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OperationTask.h"

@implementation OperationTask

@synthesize parameters;

- (void)setParameter:(NSMutableDictionary *)para{
    self.parameters = para;
}

- (void)main {  
    
    NSMutableDictionary *dictionary;
    if(![parameters valueForKey:@"invokeObjectClass1"] == nil){   
        
        dictionary = [NSMutableDictionary dictionary];
        if(![parameters valueForKey:@"withObject"] == nil){
            [dictionary setObject:[parameters valueForKey:@"withObject"] forKey:@"withObject"];
        }
        if ([parameters valueForKey:@"runInBackground1"] != nil) {
            
            if ([@"queue" isEqualToString:[parameters valueForKey:@"runInBackgdround1"]]) {
                [[parameters valueForKey:@"invokeObjectClass1"] performSelector:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName1"]) withObject:dictionary];
            }else {
                [[parameters valueForKey:@"invokeObjectClass1"] performSelectorInBackground:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName1"]) withObject:dictionary];
            }
            
        }else {
            [[parameters valueForKey:@"invokeObjectClass1"] performSelectorOnMainThread:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName1"]) withObject:dictionary waitUntilDone:NO];
        }
        
    } 
    
    if(![parameters valueForKey:@"invokeObjectClass2"] == nil){   
        if ([parameters valueForKey:@"runInBackground2"] != nil) {
            if ([@"queue" isEqualToString:[parameters valueForKey:@"runInBackground2"]]) {
                [[parameters valueForKey:@"invokeObjectClass2"] performSelector:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName2"]) withObject:dictionary];
            }else {
                [[parameters valueForKey:@"invokeObjectClass2"] performSelectorInBackground:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName2"]) withObject:dictionary];
            }    
        }else {
            [[parameters valueForKey:@"invokeObjectClass2"] performSelectorOnMainThread:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName2"]) withObject:dictionary waitUntilDone:NO];
        }      
    }
    if(![parameters valueForKey:@"invokeObjectClass3"] == nil){   
        if ([parameters valueForKey:@"runInBackground3"] != nil) {
            if ([@"queue" isEqualToString:[parameters valueForKey:@"runInBackground3"]]) {
                [[parameters valueForKey:@"invokeObjectClass3"] performSelector:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName3"]) withObject:dictionary];
            }else {
                [[parameters valueForKey:@"invokeObjectClass3"] performSelectorInBackground:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName3"]) withObject:dictionary];
            }       
        }else {
            [[parameters valueForKey:@"invokeObjectClass3"] performSelectorOnMainThread:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName3"]) withObject:dictionary waitUntilDone:NO];
        }       
    }
    
} 

@end
