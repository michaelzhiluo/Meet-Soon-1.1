//
//  Location.h
//  WeiJu
//
//  Created by Michael Luo on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSString * locationAddress;
@property (nonatomic, retain) NSString * locationClientId;
@property (nonatomic, retain) NSString * locationId;
@property (nonatomic, retain) NSString * locationName;
@property (nonatomic, retain) NSString * locationPhone;

@end
