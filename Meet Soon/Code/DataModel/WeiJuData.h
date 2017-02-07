//
//  WeiJuData.h
//  WeiJu
//
//  Created by Michael Luo on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendData, Location, WeiJuMessage;

@interface WeiJuData : NSManagedObject

@property (nonatomic, retain) NSString * aggreeStatusDisplay;
@property (nonatomic, retain) NSDate * inviteDate;
@property (nonatomic, retain) NSString * inviteUserIds;
@property (nonatomic, retain) NSNumber * isSharingLocation;
@property (nonatomic, retain) NSNumber * isSharingMyLocation;
@property (nonatomic, retain) NSString * locationAgreedUserIds;
@property (nonatomic, retain) NSNumber * locationBtnStatus;
@property (nonatomic, retain) NSDate * proposeDate;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * timeAgreedUserIds;
@property (nonatomic, retain) NSNumber * timeBtnStatus;
@property (nonatomic, retain) NSNumber * weiJuCell;
@property (nonatomic, retain) NSString * weiJuClientId;
@property (nonatomic, retain) NSNumber * weiJuCurrentStatus;
@property (nonatomic, retain) NSString * weiJuId;
@property (nonatomic, retain) NSNumber * weiJuScope;
@property (nonatomic, retain) NSNumber * weiJuType;
@property (nonatomic, retain) NSString * ekEventID;
@property (nonatomic, retain) Location *inviteLocation;
@property (nonatomic, retain) FriendData *invitor;
@property (nonatomic, retain) WeiJuMessage *lastMessage;
@property (nonatomic, retain) Location *proposeLocation;

@end
