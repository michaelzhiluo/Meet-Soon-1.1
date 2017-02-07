//
//  MessageTemplate.h
//  WeiJu
//
//  Created by Michael Luo on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendData;

@interface MessageTemplate : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * messageMode;
@property (nonatomic, retain) NSString * messageTemplateContent;
@property (nonatomic, retain) FriendData *sendUser;

@end
