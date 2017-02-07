//
//  ConvertUtil.m
//  WeiJu
//
//  Created by Michael Luo on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConvertData.h"
#import "InitCoreData.h"
#import "WeiJuData.h"
#import "DataFetchUtil.h"
#import "Character.h"
#import "ConvertUtil.h"
#import "Utils.h"
#import "FriendData.h"
#import "WeiJuManagedObjectContext.h"
#import "WeiJuAppPrefs.h"
#import "FriendsListVCtrl.h"
#import "LoginVCtrl.h"
#import "WeiJuListVCtrl.h"

@implementation ConvertData

static ConvertData *sharedInstance;

+(ConvertData *)getSharedInstance{
    if (sharedInstance == nil) {
        sharedInstance = [[ConvertData alloc] init];
    }
    return sharedInstance;
}

+(id)getWithOjbect:(NSDictionary *) messageData{
    if(messageData == nil)return nil;
    if([messageData count] <= 0)return nil;
    return [messageData objectForKey:@"withObject"];
}


+(NSString *)getErrorInfo:(NSDictionary *) messageData{
    NSString *errorInfo = [self getValue:messageData key:@"error"];
    if(errorInfo == nil)return nil;
    else return errorInfo;
}

+(id)getValue:(NSDictionary *) messageData key:(NSString *)key{
    if(messageData == nil)return nil;
    if([messageData count] <= 0)return nil;
    NSArray *result = ((NSArray *)[messageData objectForKey:@"netarray"]);
    if([result count] <= 0)return nil;
    NSDictionary *dictionaryAll = (NSDictionary *)[result objectAtIndex:0];
    return [dictionaryAll objectForKey:key];
}

-(void)syncCoreDataWithNetDictionaryWithoutInitData:(NSDictionary *)messageData{
    if([ConvertData getErrorInfo:messageData] == nil){
        NSString *contextName = @"sync";
        [self syncCoreDataWithNetDictionary:messageData contextName:contextName]; 
    }
}

-(void)syncCoreDataWithNetDictionaryByTimer:(NSDictionary *)messageData{
    if ([@"0" isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]) {
        return;
    }
    if([ConvertData getErrorInfo:messageData] == nil){
        NSString *contextName = @"sync";
        
        //NSArray *searchArray1 = [[[DataFetchUtil alloc] init] searchObjectArray:@"sync" managedObjectName:@"FriendData" filterString:[@"" stringByAppendingFormat:@"userId ='%@'",@"64"]];
        [self syncCoreDataWithNetDictionary:messageData contextName:contextName];
        //NSArray *searchArray2 = [[[DataFetchUtil alloc] init] searchObjectArray:@"sync" managedObjectName:@"FriendData" filterString:[@"" stringByAppendingFormat:@"userId ='%@'",@"64"]];
        [self initCoreDataDone:contextName];
        //NSArray *searchArray3 = [[[DataFetchUtil alloc] init] searchObjectArray:@"sync" managedObjectName:@"FriendData" filterString:[@"" stringByAppendingFormat:@"userId ='%@'",@"64"]];

        if ([[WeiJuAppPrefs getSharedInstance] isInitCoreData]) {
            [[LoginVCtrl getSharedInstance] performSelectorOnMainThread:NSSelectorFromString(@"setUpMainUSUI") withObject:nil waitUntilDone:NO];
            [[WeiJuAppPrefs getSharedInstance] setIsInitCoreData:false];
        }
    }else {
        NSString *errorInfo = [ConvertData getErrorInfo:messageData];
        [[WeiJuAppPrefs getSharedInstance] setUserId:@"0"];
        [[WeiJuAppPrefs getSharedInstance] setLoginName:@""];
        [[[DataFetchUtil alloc] init] deleteAllCoreData];
        [[LoginVCtrl getSharedInstance] performSelectorOnMainThread:NSSelectorFromString(@"loginFailed:") withObject:errorInfo waitUntilDone:NO];
            return;
       
    }
    
}

-(void)syncCoreDataWithNetDictionary:(NSDictionary *)messageData contextName:(NSString *)contextName{
    @synchronized (self) 
    { 
    int savedCount = 0;
    int updateCount = 0;
    if(messageData == nil)return;
    if([messageData count] <= 0)return;
    NSArray *result = ((NSArray *)[messageData objectForKey:@"netarray"]);
    if([result count] <= 0)return;
    DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
    Character *character = [[Character alloc] init];
    NSDictionary *dictionaryAll = (NSDictionary *)[result objectAtIndex:0];
    NSArray *allKeys = [[dictionaryAll valueForKey:@"step"] componentsSeparatedByString:@":"];
	for(int i=0;i<[allKeys count];i++)
	{
        
        //DataModel Loop
        NSString *dataModelName = [allKeys objectAtIndex:i];
        NSArray *dataModelValueArr = [dictionaryAll objectForKey:dataModelName];
        //NSLog(@"%@",[dictionaryAll objectForKey:dataModelName]);
        if([dictionaryAll objectForKey:dataModelName] == nil || [((NSArray *)[dictionaryAll objectForKey:dataModelName]) count] == 0)continue;
		if([dataModelValueArr objectAtIndex:0] == nil)continue;
        //NSLog(@"%@",[dataModelValueArr objectAtIndex:0]);
        if([(NSDictionary *)[dataModelValueArr objectAtIndex:0] objectForKey:@"pkName"] == nil)continue;
        for (int j=0; j<[dataModelValueArr count]; j++)
		{
            //One DataModel Loop
            NSDictionary *dataInstanceDictionary = (NSDictionary *)[dataModelValueArr objectAtIndex:j];
            NSString *pkName = [dataInstanceDictionary objectForKey:@"pkName"];
            NSString *pkId ;
            NSString *pkIdType = [[[dataInstanceDictionary objectForKey:pkName] class] description];
            if([pkIdType isEqualToString:@"__NSCFString"] || [pkIdType isEqualToString:@"__NSCFConstantString"]){
                pkId = [dataInstanceDictionary objectForKey:pkName];
            }else{
                pkId = [[dataInstanceDictionary objectForKey:pkName] stringValue];
            }
            //NSLog(@"%@:%@",pkName,pkId);
            NSArray *searchArray;
            @try{
                searchArray = [dataFetchUtil searchObjectArray:contextName managedObjectName:dataModelName filterString:[@"" stringByAppendingFormat:@"%@ ='%@'",pkName,pkId]];
            }@catch (NSException *e) {
				[Utils log:@"%s [line:%d] exception:%@, %@",__FUNCTION__,__LINE__, [e userInfo], [e reason]];
                continue;
            }
			
            id dataInstance;
            if (searchArray != nil && [searchArray count] > 0 ) {
                dataInstance = [searchArray objectAtIndex:0];  
                updateCount++;
                //NSLog(@"get coredata");
            }else {
                dataInstance = [dataFetchUtil createSavedObject:contextName manageObjectName:dataModelName]; 
                //NSLog(@"create coredata");
                savedCount++;
            }
            for (int k=0; k < [[dataInstanceDictionary allKeys] count]; k++) 
			{
            //Propertys Loop    
                NSString *dataInstancePropertyName = [[dataInstanceDictionary allKeys] objectAtIndex:k];
                if([dataInstancePropertyName isEqualToString:@"pkName"]) continue;//pkName case
                /*for debug*/
                
                /*for debug*/
                                
                NSArray *searchPropertyNameArray = [dataInstancePropertyName componentsSeparatedByString:@"_"];
                NSString *propertyValue;
                
 
                NSString *propertyValueType = [[[dataInstanceDictionary objectForKey:dataInstancePropertyName] class] description];
                if([propertyValueType isEqualToString:@"__NSCFString"] || [propertyValueType isEqualToString:@"__NSCFConstantString"] || [propertyValueType isEqualToString:@"__NSCFDictionary"]){
                    propertyValue = [dataInstanceDictionary objectForKey:dataInstancePropertyName];
                }else if([propertyValueType isEqualToString:@"__NSCFNumber"]){
                    propertyValue = [((NSNumber *)[dataInstanceDictionary objectForKey:dataInstancePropertyName]) stringValue];
                }else {
                    propertyValue = [[dataInstanceDictionary objectForKey:dataInstancePropertyName] stringValue];
                }
                if(![@"<non-sync>" isEqualToString:propertyValue]){
                    if ([searchPropertyNameArray count] > 1){
                        //fix case of Property:DataModel 
                        NSString *propertyName = [searchPropertyNameArray objectAtIndex:0];
                        NSString *searchDataModelName = [searchPropertyNameArray objectAtIndex:1];
                        NSString *searchPropertyName = [searchPropertyNameArray objectAtIndex:2];
                        NSArray *searchPropertyArray = [dataFetchUtil searchObjectArray:contextName managedObjectName:searchDataModelName filterString:[@"" stringByAppendingFormat:@"%@ = '%@'",searchPropertyName,propertyValue]];
                        id propertyDataInstance;
                        if (searchPropertyArray != nil && [searchPropertyArray count] > 0 ) {
                            propertyDataInstance = [searchPropertyArray objectAtIndex:0]; 
                            [dataInstance setValue:propertyDataInstance forKey:propertyName];
                        }
                        continue;
                    }
                    if ([dataModelName isEqualToString:@"WeiJuMessage"] && [dataInstancePropertyName isEqualToString:@"sendTime"]) {
                        //FriendData property:time case
                        propertyValue = [[[ConvertUtil alloc] init] convertJSONDatetoCurrentDateStr:propertyValue];
                        //NSLog(@"%@:%@",dataInstancePropertyName,propertyValue);
                    }
//					if ([dataModelName isEqualToString:@"WeiJuMessage"] && [dataInstancePropertyName isEqualToString:@"messageContent"]) {
//						NSLog(@"-----%@:%@",dataInstancePropertyName,propertyValue);
//					}
                    if([dataInstancePropertyName isEqualToString:@"userEmails"]){
                        //NSLog(@"Debug:%@", propertyValue);
                    }
                    
                    if ([dataModelName isEqualToString:@"FriendData"] && [dataInstancePropertyName isEqualToString:@"userName"]) {
                        //FriendData property:Section title case
                        [dataInstance setValue:[character getFirstCharacter:[propertyValue substringToIndex:1]].uppercaseString forKey:@"userNameSectionTitle"];
                    }
                    
                    //set normal property value
                    [dataInstance setValue:propertyValue forKey:dataInstancePropertyName];
                }
            }//for k loop
			[WeiJuManagedObjectContext quickSaveWithContextName:contextName];
        }//for j loop
        
    }//for i loop
    //[WeiJuManagedObjectContext quickSaveWithContextName:contextName];
    //[Utils log:@"%s [line:%d] Sync Saved: %i Sync updated:%i",__FUNCTION__,__LINE__,savedCount,updateCount];

  }//@sync
    
}



-(void)initCoreDataDone:(NSString *)contextName{
    if ([[WeiJuAppPrefs getSharedInstance] isInitCoreData]) {
        [InitCoreData initWeiJu];
    }
}


@end
