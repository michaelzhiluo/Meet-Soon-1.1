//
//  WeiJuParticipant.m
//  WeiJu
//
//  Created by Michael Luo on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuParticipant.h"

@implementation WeiJuParticipant

@synthesize isRealUser, fullName,fullNameABR,fullNameABRNoCase, firstNameABR, lastNameABR, displayName, userImage, url, personDesp, urlString, idType, URN, URNEmail, email, friendDataUserID, friendData, hasABRecord, phoneLabels, phoneNumbers, isSharing, sharingTimeOut, crumbPath, annotations, lastCoord, newMsg;

-(id) init
{
	self = [super init];
    if (self) {
		self.isRealUser=YES;
		self.isSharing=NO;
		self.hasABRecord=NO;
		self.lastCoord=CLLocationCoordinate2DMake(-300, -300);
		//self.annotations = [[NSMutableArray alloc] init];
		self.newMsg=0;
	}
	return  self;
}

@end
