//
//  FriendAgreedStatus.h
//  OnMyWay
//
//  Created by luowenlei on 4/11/12.
//  Copyright (c) 2012 Luo Michael. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendData, WeiJuData;

@interface FriendAgreedStatus : NSManagedObject

@property (nonatomic, retain) NSString * locationAgreed;
@property (nonatomic, retain) NSString * timeAgreed;
@property (nonatomic, retain) FriendData *friendUser;
@property (nonatomic, retain) WeiJuData *weiJuData;

@end
