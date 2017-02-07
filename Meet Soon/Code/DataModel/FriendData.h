//
//  FriendData.h
//  WeiJu
//
//  Created by Michael Luo on 10/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FriendData : NSManagedObject

@property (nonatomic, retain) NSString * abRecordEmails;
@property (nonatomic, retain) NSString * abRecordFirstName;
@property (nonatomic, retain) NSNumber * abRecordID;
@property (nonatomic, retain) NSString * abRecordLastName;
@property (nonatomic, retain) NSString * abRecordName;
@property (nonatomic, retain) NSString * abRecordNameNoCase;
@property (nonatomic, retain) NSString * hide;
@property (nonatomic, retain) NSDate * lastMeetingDate;
@property (nonatomic, retain) NSString * lastMeetingLocation;
@property (nonatomic, retain) NSString * messageReadType;
@property (nonatomic, retain) NSString * userClientId;
@property (nonatomic, retain) NSString * userEmails;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSData * userImageFileData;
@property (nonatomic, retain) NSString * userImageFileName;
@property (nonatomic, retain) NSString * userLogin;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * userNameSectionTitle;
@property (nonatomic, retain) NSString * userNickName;
@property (nonatomic, retain) NSString * userPassword;
@property (nonatomic, retain) NSString * userURN;

@end
