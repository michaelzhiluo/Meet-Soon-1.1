//
//  LoginUser.h
//  WeiJu
//
//  Created by Michael Luo on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LoginUser : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * isAppDefaultLogin;
@property (nonatomic, retain) NSNumber * isVaild;
@property (nonatomic, retain) NSString * loginName;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userName;

@end
