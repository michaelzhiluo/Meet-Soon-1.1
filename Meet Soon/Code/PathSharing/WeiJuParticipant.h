//
//  WeiJuParticipant.h
//  WeiJu
//
//  Created by Michael Luo on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FriendData, CrumbPath;

@interface WeiJuParticipant : NSObject

@property (assign, nonatomic) BOOL isRealUser; //ALL, ME, ADD, are not real users, not treated the same
@property (retain, nonatomic) NSString *displayName;
@property (retain, nonatomic) NSString *fullName;

@property (retain, nonatomic) NSString *fullNameABR;
@property (retain, nonatomic) NSString *fullNameABRNoCase;
@property (retain, nonatomic) NSString *firstNameABR;
@property (retain, nonatomic) NSString *lastNameABR;

@property (retain, nonatomic) UIImage *userImage;

@property (retain, nonatomic) NSURL *url;
@property (retain, nonatomic) NSString *personDesp;
@property (retain, nonatomic) NSString *urlString; //either urn, or email
@property (assign, nonatomic) int idType; //0: URN, 1:email
@property (retain, nonatomic) NSString *URN;
@property (retain, nonatomic) NSString *URNEmail; //different from email from URL; this email is obtained from the EKParticipant description string since when URL is URN, there is no emial info there
@property (retain, nonatomic) NSString *email;

@property (retain, nonatomic) NSString *friendDataUserID;
@property (retain, nonatomic) FriendData *friendData;
@property (assign, nonatomic) BOOL hasABRecord;

@property (retain, nonatomic) NSMutableArray *phoneLabels;
@property (retain, nonatomic) NSMutableArray *phoneNumbers;

@property (assign, nonatomic) BOOL isSharing;
@property (retain, nonatomic) NSTimer *sharingTimeOut; //timeout timer,stared when the user last shares path

@property (retain, nonatomic) CrumbPath *crumbPath;
@property (retain, nonatomic) NSMutableArray *annotations;
@property (assign, nonatomic) CLLocationCoordinate2D lastCoord;

@property (assign, nonatomic) int newMsg;

/*
 @dynamic userClientId;//手机自己生成关联ID(很少用)
 @dynamic userId;//用户业务ID号
 @dynamic userImageFileName;
 @dynamic userLogin;//用户登陆名(主要电邮)
 @dynamic userName;//用户姓名
 @dynamic userNameSectionTitle;//用来区分用户section的
 @dynamic userNickName;//别名
 @dynamic userPassword;//密码
 @dynamic userEmails;//所有电邮,使用逗号分割
 */

@end
