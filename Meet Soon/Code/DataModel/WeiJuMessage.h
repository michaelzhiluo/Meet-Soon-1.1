//
//  WeiJuMessage.h
//  WeiJu
//
//  Created by Michael Luo on 10/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendData;

@interface WeiJuMessage : NSManagedObject

@property (nonatomic, retain) NSString * isPushMessage;
@property (nonatomic, retain) NSString * isSendBySelf;
@property (nonatomic, retain) NSString * messageClientId;
@property (nonatomic, retain) NSString * messageContent;
@property (nonatomic, retain) NSString * messageContentType;
@property (nonatomic, retain) NSString * messageId;
@property (nonatomic, retain) NSString * messagePushAlert;
@property (nonatomic, retain) NSString * messageReadStatus;
@property (nonatomic, retain) NSString * messageRecipients;
@property (nonatomic, retain) NSString * messageSendId;
@property (nonatomic, retain) NSString * messageStatusClientIds;
@property (nonatomic, retain) NSString * messageType;
@property (nonatomic, retain) NSString * protocolVersion;
@property (nonatomic, retain) NSDate * sendTime;
@property (nonatomic, retain) NSString * weiJuClientId;
@property (nonatomic, retain) NSString * weiJuId;
@property (nonatomic, retain) FriendData *sendUser;

@end
