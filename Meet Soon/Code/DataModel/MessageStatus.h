//
//  MessageStatus.h
//  WeiJu
//
//  Created by Michael Luo on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendData;

@interface MessageStatus : NSManagedObject

@property (nonatomic, retain) NSNumber * messageStatus;
@property (nonatomic, retain) NSString * messageStatusClientId;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) FriendData *receiveUser;

@end
