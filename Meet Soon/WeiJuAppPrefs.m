//
//  WeiJuAppPrefs.m
//  WeiJu
//
//  Created by Michael Luo on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "WeiJuAppPrefs.h"
#import "DataFetchUtil.h"
#import "FriendData.h"

// We store our settings in the NSUserDefaults dictionary using these keys
static NSString* const logMode = @"logMode";
static NSString* const QLogEnabledKey = @"qLogEnabled";
static NSString* const DemoKey = @"demo";
static NSString* const NicknameKey = @"Nickname";
static NSString* const DeviceTokenKey = @"DeviceToken";
static NSString* const newDeviceToken = @"newDeviceToken";
static NSString* const userId = @"userId";
static NSString* const loginName = @"loginName";
static NSString* const CheckedSelfEmailKey = @"CheckedSelfEmail";
static NSString* const NumberOfCALKey = @"ncalkey";
static NSString* const DemoEventOnOffKey = @"demoOnOff";
static NSString* const isInitCoreData = @"isInitCoreData";
static NSString* const PathSharingDurationKey = @"PSDKey";

static NSString* const newAppVerKey = @"newAppVerKey";
static NSString* const newProtoVerKey = @"newProtoVerKey";
static NSString* const newAppVerData = @"newAppVerData";
static NSString* const newProtoVerData = @"newProtoVerData";

static NSString* const inviteVibrateKey = @"inviteVibrateKey";
static NSString* const pathUpdateVibrateKey = @"pathUpdateVibrateKey";


static FriendData *selfFriendData = nil;

const NSString *currentAppVersion = @"1.1"; //1) can  be x.yz, but y can't be zero, z means bug fix, y means minor feature add, z mean major upgrade, 2) when release new version, change this and the default newAppVer and newProtoVer; 3) this is also used by firstloginvctrl and setting vctrl to display version
const NSString *curProtoVer = @"1.0"; //when there is a change in proto, appver must change too, x or y
const BOOL isPaidVer = NO;

const NSString *supportEmail = @"meetsoon.help@gmail.com";

const int DEVELOP_MODE =1;
const int TEST_MODE = 2;
const int PRODUCTION_MODE = 3; //if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)


@implementation WeiJuAppPrefs

static WeiJuAppPrefs *sharedInstance;

+ (WeiJuAppPrefs *) getSharedInstance{
    return sharedInstance;
}

- (void) setSharedInstance:(WeiJuAppPrefs *)instance
{
	sharedInstance=instance;
}

+ (void)initialize
{
	if (self == [WeiJuAppPrefs class]) //????what does it mean?
	{
		// Register default values for our settings
		[[NSUserDefaults standardUserDefaults] registerDefaults:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInteger:1], logMode, 
		  [NSNumber numberWithInt:1], QLogEnabledKey,
		  @"0", DemoKey,
		  @"", NicknameKey,
		  @"0", DeviceTokenKey,
          @"", newDeviceToken,
          @"0", userId,
          @"",loginName,
		  [NSNumber numberWithInt:0], CheckedSelfEmailKey,
          [NSNumber numberWithInteger:0], NumberOfCALKey, 
		  [NSNumber numberWithInt:1], DemoEventOnOffKey,
          [NSNumber numberWithInt:1], isInitCoreData,
          [NSNumber numberWithDouble:600], PathSharingDurationKey,
		  @"1.0", newAppVerKey,
		  @"1.0", newProtoVerKey,
          @"", newAppVerData,
		  @"", newProtoVerData,
		  [NSNumber numberWithInt:1], inviteVibrateKey,
		  [NSNumber numberWithInt:1], pathUpdateVibrateKey,
		  nil]];
		/*
		 The contents of the registration domain are not written to disk; 
		 you need to call this method each time your application starts. 
		 You can place a plist file in the application's Resources directory 
		 and call registerDefaults: with the contents that you read in from that file.
		 */
	}
}


- (void) resetPrefs
{
	[self setIsInitCoreData:YES];
	//[self setDeviceToken:@"0"]; //不能重置,否则logout再login就没有token
	[self setNewDeviceToken:@""];
	[self setUserId:@"0"];
    //[self setLoginName:@""]; //it's login email, not name
	[self setCheckedSelfEmail:NO];
	selfFriendData = nil;
	[self setDemoEventOnOff:YES];
	
}

- (NSInteger)logMode
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:logMode];
}
- (void)setLogMode:(NSInteger)value
{
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:logMode];
	if(value==2)
		[self setQLogEnabled:YES];
}
- (BOOL)qLogEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:QLogEnabledKey];
}

- (void)setQLogEnabled:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:QLogEnabledKey];
}

- (BOOL)demo
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DemoKey];
}

- (void)setDemo:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:DemoKey];
}

- (NSString*)nickname
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:NicknameKey];
}

- (void)setNickname:(NSString*)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:NicknameKey];
}

- (FriendData*)friendData
{
    if(selfFriendData == nil)
	{
        DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
        NSArray *friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId=" stringByAppendingFormat:@"'%@'", [self userId]] ];
        if([friendDataResult count]==1)
        {
            selfFriendData = (FriendData *)[friendDataResult objectAtIndex:0];
        }else {
            return nil;
        }
    }
    //NSLog(@"%@",selfFriendData.userName);
	return selfFriendData;
    
}

//此方法有问题,获得不到password,因为password的数据不存放本地
//- (NSString*)password
//{
//	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
//    NSArray *friendDataResult = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId=" stringByAppendingFormat:@"'%@'", [self userId]] ];
//	if([friendDataResult count]==1)
//	{
//		return ((FriendData *)[friendDataResult objectAtIndex:0]).userPassword;
//	}
//	else {
//		return nil;
//	}
//}

- (NSString*)deviceToken
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:DeviceTokenKey];
}

- (void)setDeviceToken:(NSString*)token
{
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:DeviceTokenKey];
}

- (NSString*)newDeviceToken
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:newDeviceToken];
}

- (void)setNewDeviceToken:(NSString*)token
{
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:newDeviceToken];
}

- (NSString*)userId
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:userId];
}

- (void)setUserId:(NSString*)token
{
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:userId];
}

- (NSString*)loginName
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:loginName];
}

- (void)setLoginName:(NSString*)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:loginName];
}

// Determines whether the user has successfully runthrough all the calendar events to find self's emails (as organizer)
- (BOOL)checkedSelfEmail
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:CheckedSelfEmailKey];
}
- (void)setCheckedSelfEmail:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:CheckedSelfEmailKey];	
}

- (NSInteger)numberOfCals
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:NumberOfCALKey];
}
- (void)setNumberOfCals:(NSInteger)value
{
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:NumberOfCALKey];
}


- (BOOL)demoEventOnOff
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DemoEventOnOffKey];
}

- (void)setDemoEventOnOff:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:DemoEventOnOffKey];
}

- (BOOL)isInitCoreData
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:isInitCoreData];
}

- (void)setIsInitCoreData:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:isInitCoreData];
}

- (double)pathSharingDuration
{
	return [[NSUserDefaults standardUserDefaults] doubleForKey:PathSharingDurationKey];	
}
- (void) setPathSharingDuration:(double)value
{
	[[NSUserDefaults standardUserDefaults] setDouble:value forKey:PathSharingDurationKey];	
}

- (NSString*)newAppVer
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:newAppVerKey];
}
- (void)setNewAppVer:(NSString*)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:newAppVerKey];
}

- (NSString*)newProtoVer
{
return [[NSUserDefaults standardUserDefaults] stringForKey:newProtoVerKey];
}
- (void)setNewProtoVer:(NSString*)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:newProtoVerKey];
}

- (NSString*)newAppVerData
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:newAppVerData];
}
- (void)setNewAppVerData:(NSString*)token
{
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:newAppVerData];
}

- (NSString*)newProtoVerData
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:newProtoVerData];
}
- (void)setNewProtoVerData:(NSString*)token
{
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:newProtoVerData];
}

//vibration控制
- (BOOL)inviteVibrate
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:inviteVibrateKey];
}
- (void)setInviteVibrate:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:inviteVibrateKey];
}
- (BOOL)pathUpdateVibrate
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:pathUpdateVibrateKey];
}
- (void)setPathUpdateVibrate:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:pathUpdateVibrateKey];
}

@end
