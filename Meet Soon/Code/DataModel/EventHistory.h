//
//  EventHistory.h
//  OnMyWay
//
//  Created by luowenlei on 4/11/12.
//  Copyright (c) 2012 Luo Michael. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EventHistory : NSManagedObject

@property (nonatomic, retain) NSString * ekEventFullId;
@property (nonatomic, retain) NSString * ekEventId;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * isClientDeleted;
@property (nonatomic, retain) NSString * isUploaded;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSString * title;

@end
