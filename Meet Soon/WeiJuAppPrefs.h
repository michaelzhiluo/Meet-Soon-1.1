//
//  WeiJuAppPrefs.h
//  WeiJu
//
//  Created by Michael Luo on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FriendData;
@interface WeiJuAppPrefs : NSObject

extern const NSString *currentAppVersion;
extern const NSString *curProtoVer;
extern const BOOL paidVersion;

extern const NSString *supportEmail;

extern const int DEVELOP_MODE;
extern const int TEST_MODE;
extern const int PRODUCTION_MODE;

+ (WeiJuAppPrefs *) getSharedInstance;
- (void) setSharedInstance:(WeiJuAppPrefs *)instance;

- (void) resetPrefs;

// Get the app's logging setting
- (NSInteger)logMode;
- (void)setLogMode:(NSInteger)value;
- (BOOL)qLogEnabled;
- (void)setQLogEnabled:(BOOL)value;

// Get and set the app's demo setting
- (BOOL)demo;
- (void)setDemo:(BOOL)value;

// Get and set the user's nickname, which can be diff from userName
- (NSString*)nickname;
- (void)setNickname:(NSString*)name;

- (FriendData*)friendData; //get the userName from coredata
//- (NSString*)password; //get the password from coredata

// Get and set the device token. We cache the token so we can determine whether
// to send an "update" request to the server.
- (NSString*)deviceToken;
- (void)setDeviceToken:(NSString*)token;

//是否有新的DeviceToken
- (NSString*)newDeviceToken;
- (void)setNewDeviceToken:(NSString*)token;

//userid
- (NSString*)userId;
- (void)setUserId:(NSString*)token;

//user login name,email (not user name!)
- (NSString*)loginName;
- (void)setLoginName:(NSString*)loginName;

// Determines whether the user has successfully runthrough all the calendar events to find self's emails (as organizer)
- (BOOL)checkedSelfEmail;
- (void)setCheckedSelfEmail:(BOOL)value;

//HOW MANY CALENDARS in the current event store
- (NSInteger) numberOfCals;
- (void) setNumberOfCals:(NSInteger)value;

// display demo event or not
- (BOOL)demoEventOnOff;
- (void)setDemoEventOnOff:(BOOL)value;

- (BOOL)isInitCoreData;
- (void)setIsInitCoreData:(BOOL)value;

//pathsharing duration
- (double)pathSharingDuration;
- (void) setPathSharingDuration:(double)value;

//是否有新版本
- (NSString*)newAppVer;
- (void)setNewAppVer:(NSString*)name;

- (NSString*)newProtoVer;
- (void)setNewProtoVer:(NSString*)name;

- (NSString*)newAppVerData;
- (void)setNewAppVerData:(NSString*)token;

- (NSString*)newProtoVerData;
- (void)setNewProtoVerData:(NSString*)token;

//vibration控制
- (BOOL)inviteVibrate;
- (void)setInviteVibrate:(BOOL)value;
- (BOOL)pathUpdateVibrate;
- (void)setPathUpdateVibrate:(BOOL)value;

@end
