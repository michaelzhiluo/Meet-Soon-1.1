//
//  UserEventHistory.h
//  WeiJu
//
//  Created by Michael Luo on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserEventHistory : NSManagedObject

@property (nonatomic, retain) NSString * buttonCode;
@property (nonatomic, retain) NSDate * clickTime;
@property (nonatomic, retain) NSString * isUploaded;

@end
