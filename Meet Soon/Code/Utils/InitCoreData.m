//
//  ConvertUtil.m
//  WeiJu
//
//  Created by Michael Luo on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InitCoreData.h"
#import "DataFetchUtil.h"
#import "MessageTemplate.h"
#import "WeiJuAppPrefs.h"
#import "FriendData.h"
#import "WeiJuData.h"
#import "WeiJuMessage.h"
#import "WeiJuManagedObjectContext.h"

@implementation InitCoreData

+(void)initWeiJu{

    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    //NSArray *loginUserArr = [dataFetchUtil searchObjectArray:@"MessageTemplate" filterString:nil];
          //app init
    NSArray *messageTemplatearr = [dataFetchUtil searchObjectArray:@"FriendData" filterString:@"userId='1'"];
    if([messageTemplatearr count] < 1){
        {
                FriendData *friendData = (FriendData *)[dataFetchUtil createSavedObject:@"FriendData"];
                friendData.userId = @"1";
                friendData.userName = @"System Help";
                friendData.userLogin = @"meetsoon.help@gmail.com";
                friendData.userNameSectionTitle = @"s";
				friendData.hide=@"1";
        }
    }
	[WeiJuManagedObjectContext quickSave];
}




@end
