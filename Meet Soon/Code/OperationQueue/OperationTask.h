//
//  OperationTask.h
//  WeiJu
//
//  Created by Michael Luo on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OperationTask : NSOperation

//to create a OperationUtils and use Queue,you should assign url,invokeObject and invoke property.
@property(retain,nonatomic) NSMutableDictionary *parameters;

@property(retain,nonatomic) NSThread *queueThread;

- (void)setParameter:(NSMutableDictionary *)para;

@end
