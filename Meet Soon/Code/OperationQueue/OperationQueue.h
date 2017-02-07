//
//  HttpOperationFactory.h
//  TestNSOperation
//
//  Created by Michael Luo on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OperationQueue : NSObject {  
    
}  
+(NSOperationQueue *)getOperationQueue:(NSString *)queueName;

+(void) addTask:(NSString *)queueName operationObject:(id)operationObject  parameters:(NSMutableDictionary *) parameters;
+(void)cancelAllOperations;
@end
