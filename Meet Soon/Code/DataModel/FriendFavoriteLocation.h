//
//  FriendFavoriteLocation.h
//  WeiJu
//
//  Created by Michael Luo on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendData, Location;

@interface FriendFavoriteLocation : NSManagedObject

@property (nonatomic, retain) NSString * deleted;
@property (nonatomic, retain) NSString * friendFavoriteLocationId;
@property (nonatomic, retain) FriendData *friendUser;
@property (nonatomic, retain) Location *friendLocation;

@end
