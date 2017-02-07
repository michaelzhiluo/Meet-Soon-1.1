//
//  TestOut.m
//  TestNSOperation
//
//  Created by Michael Luo on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuNetWorkClient.h"
#import "OperationQueue.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuListDCtrl.h"
#import "HttpOperation.h"
#import "LoginVCtrl.h"
#import "FileOperationUtils.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "FriendsListVCtrl.h"
#import "ConvertData.h"
#import "FileOperationUtils.h"
#import "DataFetchUtil.h"
#import "UserEventHistory.h"
#import "WeiJuManagedObjectContext.h"

static NSString *ipAddress = @"onmyway.meetsoon.mobi";
//static NSString *ipAddress = @"corpose.d113.163ns.cn";
//static NSString *ipAddress = @"192.168.1.104:8080";
//static NSString *ipAddress = @"localhost:8080";

static WeiJuNetWorkClient *sharedWeiJuNetWorkClient;
static bool searchVersionEnabled = true;
static bool networkEnabled =true;

static bool scheduleFristEnabled = false;
static int timerFristPeriod = 60;

NSTimer *messageSchedule;

@implementation WeiJuNetWorkClient


+(NSString *)getIpAddress{
    return ipAddress;
}

+(void)setNetWorkEnabled:(bool)enabled{
	networkEnabled = enabled;
	if (networkEnabled) {
		[[WeiJuListVCtrl getSharedInstance] performSelectorOnMainThread:NSSelectorFromString(@"dismissNetworkMessageView") withObject:nil waitUntilDone:YES];
		//[[WeiJuListVCtrl getSharedInstance] dismissNetworkMessageView];
	}else {
		[[WeiJuListVCtrl getSharedInstance] performSelectorOnMainThread:NSSelectorFromString(@"displayNetworkMessageView") withObject:nil waitUntilDone:YES];
		//[[WeiJuListVCtrl getSharedInstance] displayNetworkMessageView];
	}
}

+(bool)getNetWorkEnabled{
    return networkEnabled;
}

+(void)setScheduleFristEnabled:(bool)enabled{
    scheduleFristEnabled = enabled;
}

+(void)setSearchVersionEnabled:(bool)enabled{
    searchVersionEnabled = enabled;
}


+(WeiJuNetWorkClient *) getSharedWeiJuNetWorkClient{
    if (sharedWeiJuNetWorkClient == nil){
        sharedWeiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init];
    }    
    return sharedWeiJuNetWorkClient;
}


-(void) startReceive{
    //start NetWorking to fetch new messages
    messageSchedule = [NSTimer scheduledTimerWithTimeInterval:timerFristPeriod target:[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] selector:@selector(syncMyDataByTimer) userInfo:nil repeats:YES];
    [messageSchedule fire];
    
    
}

-(void) stopReceive{
    //start NetWorking to fetch new messages
    if(messageSchedule != nil){
        [messageSchedule invalidate];
        messageSchedule = nil;
        scheduleFristEnabled = false;
    }
}

-(void) requestDataWithNoToken:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod  {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSString *tempServiceName = [serviceName stringByReplacingOccurrencesOfString:@"." withString:@"!"];
    NSString *tempUrl = [@"http://" stringByAppendingFormat:@"%@/Party/%@.action",ipAddress,tempServiceName];
    [dictionary setObject:[NSURL URLWithString:tempUrl] forKey:@"url"];
    [dictionary setObject:@"True" forKey:@"NoCheck"];
    if(parameters != nil){
        [parameters setObject:curProtoVer forKey:@"protocolVersion"];
        [dictionary setObject:parameters forKey:@"postData"];
    }
    if(withObject != nil){
        [dictionary setObject:withObject forKey:@"withObject"];
    }
    if(callbackInstance != nil && callbackMethod != nil) {
        [dictionary setObject:callbackInstance forKey:@"invokeObjectClass1"];
        [dictionary setObject:callbackMethod forKey:@"invokeObjectMethodName1"];
    }
    //NSLog(@"Send Request Url: %@",[tempUrl stringByAppendingFormat:@"?%@",postData]);
	[OperationQueue addTask:@"httpRequest" operationObject:[[HttpOperation alloc] init] parameters:dictionary]; 
}



-(void) requestData:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod  {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSString *tempServiceName = [serviceName stringByReplacingOccurrencesOfString:@"." withString:@"!"];
    NSString *tempUrl = [@"http://" stringByAppendingFormat:@"%@/Party/%@.action",ipAddress,tempServiceName];
    [dictionary setObject:[NSURL URLWithString:tempUrl] forKey:@"url"];
    
    if(parameters != nil){
        [parameters setObject:curProtoVer forKey:@"protocolVersion"];
        [parameters setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:[[WeiJuAppPrefs getSharedInstance] userId]] forKey:@"token"];
        if ([parameters objectForKey:@"userId"] == nil ) {
            [parameters setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
        }
        [dictionary setObject:parameters forKey:@"postData"];
    }
    if(withObject != nil){
        [dictionary setObject:withObject forKey:@"withObject"];
    }
    if(callbackInstance != nil && callbackMethod != nil) {
        [dictionary setObject:callbackInstance forKey:@"invokeObjectClass1"];
        [dictionary setObject:callbackMethod forKey:@"invokeObjectMethodName1"];
    }
    //NSLog(@"Send Request Url: %@",[tempUrl stringByAppendingFormat:@"?%@",postData]);
	[OperationQueue addTask:@"httpRequest" operationObject:[[HttpOperation alloc] init] parameters:dictionary]; 
}

-(void) requestData:(NSString *)serviceName newParameters:(NSMutableDictionary *)newParameters parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod  {
    
    NSString *tempServiceName = [serviceName stringByReplacingOccurrencesOfString:@"." withString:@"!"];
    NSString *tempUrl = [@"http://" stringByAppendingFormat:@"%@/Party/%@.action",ipAddress,tempServiceName];
    [newParameters setObject:[NSURL URLWithString:tempUrl] forKey:@"url"];

    if(parameters != nil){
        [parameters setObject:curProtoVer forKey:@"protocolVersion"];
        [parameters setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:[[WeiJuAppPrefs getSharedInstance] userId]] forKey:@"token"];
        if ([parameters objectForKey:@"userId"] == nil ) {
            [parameters setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
        }
        [newParameters setObject:parameters forKey:@"postData"];
    }
    if(withObject != nil){
        [newParameters setObject:withObject forKey:@"withObject"];
    }
    if(callbackInstance != nil && callbackMethod != nil) {
        [newParameters setObject:callbackInstance forKey:@"invokeObjectClass1"];
        [newParameters setObject:callbackMethod forKey:@"invokeObjectMethodName1"];
    }
    //NSLog(@"Send Request Url: %@",[tempUrl stringByAppendingFormat:@"?%@",postData]);
	[OperationQueue addTask:@"httpRequest" operationObject:[[HttpOperation alloc] init] parameters:newParameters]; 
}

-(void) sendData:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod  {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSString *tempServiceName = [serviceName stringByReplacingOccurrencesOfString:@"." withString:@"!"];
    NSString *tempUrl = [@"http://" stringByAppendingFormat:@"%@/Party/%@.action",ipAddress,tempServiceName];
    [dictionary setObject:[NSURL URLWithString:tempUrl] forKey:@"url"];

    if(parameters != nil){
        [parameters setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:[[WeiJuAppPrefs getSharedInstance] userId]] forKey:@"token"];
        [parameters setObject:curProtoVer forKey:@"protocolVersion"];
        if ([parameters objectForKey:@"userId"] == nil ) {
            [parameters setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
        }
        [dictionary setObject:parameters forKey:@"postData"];
    }
    
    if(withObject != nil){
        [dictionary setObject:withObject forKey:@"withObject"];
    }
    if(callbackInstance != nil && callbackMethod != nil) {
        [dictionary setObject:callbackInstance forKey:@"invokeObjectClass1"];
        [dictionary setObject:callbackMethod forKey:@"invokeObjectMethodName1"];
    }
    //NSLog(@"Send Request Url: %@",[tempUrl stringByAppendingFormat:@"?%@",postData]);
	[OperationQueue addTask:@"httpSend" operationObject:[[HttpOperation alloc] init] parameters:dictionary]; 
    
    if (networkEnabled) {
        [[OperationQueue getOperationQueue:@"httpSend"] setSuspended:NO];
    }else{
        [[OperationQueue getOperationQueue:@"httpSend"] setSuspended:YES];  
    }
}

-(void) requestData:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance1:(id)callbackInstance1 callbackMethod1:(NSString *)callbackMethod1 callbackInstance2:(id)callbackInstance2 callbackMethod2:(NSString *)callbackMethod2 callbackInstance3:(id)callbackInstance3 callbackMethod3:(NSString *)callbackMethod3  {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSString *tempServiceName = [serviceName stringByReplacingOccurrencesOfString:@"." withString:@"!"];
    NSString *tempUrl = [@"http://" stringByAppendingFormat:@"%@/Party/%@.action",ipAddress,tempServiceName];
    [dictionary setObject:[NSURL URLWithString:tempUrl] forKey:@"url"];

    if(parameters != nil){
        [parameters setObject:curProtoVer forKey:@"protocolVersion"];
        [parameters setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:[[WeiJuAppPrefs getSharedInstance] userId]] forKey:@"token"];
        if ([parameters objectForKey:@"userId"] == nil ) {
            [parameters setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
        }
        [dictionary setObject:parameters forKey:@"postData"];
    }
    if(withObject != nil){
        [dictionary setObject:withObject forKey:@"withObject"];
    }
    if(callbackInstance1 != nil && callbackMethod1 != nil) {
        [dictionary setObject:callbackInstance1 forKey:@"invokeObjectClass1"];
        [dictionary setObject:callbackMethod1 forKey:@"invokeObjectMethodName1"];
    }
    if(callbackInstance2 != nil && callbackMethod2 != nil) {
        [dictionary setObject:callbackInstance2 forKey:@"invokeObjectClass2"];
        [dictionary setObject:callbackMethod2 forKey:@"invokeObjectMethodName2"];
    }
    if(callbackInstance3 != nil && callbackMethod3 != nil) {
        [dictionary setObject:callbackInstance3 forKey:@"invokeObjectClass3"];
        [dictionary setObject:callbackMethod3 forKey:@"invokeObjectMethodName3"];
    }
    //NSLog(@"Send Request Url: %@",[tempUrl stringByAppendingFormat:@"?%@",postData]);
	[OperationQueue addTask:@"httpRequest" operationObject:[[HttpOperation alloc] init] parameters:dictionary]; 
}

-(void) requestData:(NSString *)serviceName netParameters:(NSMutableDictionary *)netParameters parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance1:(id)callbackInstance1 callbackMethod1:(NSString *)callbackMethod1 callbackInstance2:(id)callbackInstance2 callbackMethod2:(NSString *)callbackMethod2 callbackInstance3:(id)callbackInstance3 callbackMethod3:(NSString *)callbackMethod3  {

    NSString *tempServiceName = [serviceName stringByReplacingOccurrencesOfString:@"." withString:@"!"];
    NSString *tempUrl = [@"http://" stringByAppendingFormat:@"%@/Party/%@.action",ipAddress,tempServiceName];
    [netParameters setObject:[NSURL URLWithString:tempUrl] forKey:@"url"];

    if(parameters != nil){
        [parameters setObject:curProtoVer forKey:@"protocolVersion"];
        [parameters setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:[[WeiJuAppPrefs getSharedInstance] userId]] forKey:@"token"];
        if ([parameters objectForKey:@"userId"] == nil ) {
            [parameters setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
        }
        [netParameters setObject:parameters forKey:@"postData"];
    }
    if(withObject != nil){
        [netParameters setObject:withObject forKey:@"withObject"];
    }
    if(callbackInstance1 != nil && callbackMethod1 != nil) {
        [netParameters setObject:callbackInstance1 forKey:@"invokeObjectClass1"];
        [netParameters setObject:callbackMethod1 forKey:@"invokeObjectMethodName1"];
    }
    if(callbackInstance2 != nil && callbackMethod2 != nil) {
        [netParameters setObject:callbackInstance2 forKey:@"invokeObjectClass2"];
        [netParameters setObject:callbackMethod2 forKey:@"invokeObjectMethodName2"];
    }
    if(callbackInstance3 != nil && callbackMethod3 != nil) {
        [netParameters setObject:callbackInstance3 forKey:@"invokeObjectClass3"];
        [netParameters setObject:callbackMethod3 forKey:@"invokeObjectMethodName3"];
    }
    //NSLog(@"Send Request Url: %@",[tempUrl stringByAppendingFormat:@"?%@",postData]);
	[OperationQueue addTask:@"httpRequest" operationObject:[[HttpOperation alloc] init] parameters:netParameters]; 
}




-(void) syncMyDataByTimer{ //get message etc. from server
    if([[[WeiJuAppPrefs getSharedInstance] userId] intValue] == 0)return;
    //NSLog(@"syncMyData: %@",[[WeiJuAppPrefs getSharedInstance] userId]);
    if (!scheduleFristEnabled) {
        scheduleFristEnabled = true;
        return;
    }
    //upload event history
    NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
    NSDateFormatter *fSelected;
    NSString *temp = @"";
    NSArray *userEventHistroyArr = [[[DataFetchUtil alloc] init] searchObjectArray:@"UserEventHistory" filterString:@"isUploaded = '0'"];
    for (int i = 0; i < [userEventHistroyArr count]; i++) {
        UserEventHistory *userEventHistory = (UserEventHistory *)[userEventHistroyArr objectAtIndex:i];
        if (i == 0) {
            //upload event history
            fSelected = [[NSDateFormatter alloc] init];
            [fSelected setTimeZone:[NSTimeZone localTimeZone]];
            [fSelected setDateFormat:@"YYYYMMddHHmmss"];
            temp = [temp stringByAppendingFormat:@"%@-%@",userEventHistory.buttonCode,[fSelected stringFromDate:userEventHistory.clickTime]];
        }else {
            temp = [temp stringByAppendingFormat:@",%@-%@",userEventHistory.buttonCode,[fSelected stringFromDate:userEventHistory.clickTime]];
        }
    }
    id withObject = nil;
    if (userEventHistroyArr != nil && [userEventHistroyArr count] != 0 ) {
        withObject = userEventHistroyArr;
    }
    if (![@"" isEqualToString:temp]) {
        [paraDic setObject:temp forKey:@"userEvents"];
    }
    //upload event history end
    NSMutableDictionary *netParameters = [NSMutableDictionary dictionary];
    [netParameters setObject:@"2" forKey:@"queueTaskSize"];
    //[netParameters setObject:@"YES" forKey:@"runInBackground2"];
    //[netParameters setObject:@"YES" forKey:@"runInBackground3"];
    [self syncMyData:paraDic netParameters:netParameters withObject:withObject userEmails:nil syncUserIds:nil initEnabled:NO];
    
}

-(void) syncMyData:(NSString *)userEmails syncUserIds:(NSString *)syncUserIds{ //get message etc. from server
    if([[[WeiJuAppPrefs getSharedInstance] userId] intValue] == 0)return;
    
    NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
    NSMutableDictionary *netParameters = [NSMutableDictionary dictionary];
    //[netParameters setObject:@"YES" forKey:@"runInBackground1"];
    //[netParameters setObject:@"YES" forKey:@"runInBackground2"];
    //[netParameters setObject:@"YES" forKey:@"runInBackground3"];
    [self syncMyData:paraDic netParameters:netParameters withObject:nil userEmails:userEmails syncUserIds:nil initEnabled:NO];
    [[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] stopReceive];
    [[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] startReceive];
}

-(void) uploadEvent:(NSString *)userId{ //get message etc. from server
    if([[[WeiJuAppPrefs getSharedInstance] userId] intValue] == 0)return;
    
    NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
    NSMutableDictionary *netParameters = [NSMutableDictionary dictionary];
    [paraDic setObject:userId forKey:@"userId"];

    //upload event history
    NSDateFormatter *fSelected;
    NSString *temp = @"";
    NSArray *userEventHistroyArr = [[[DataFetchUtil alloc] init] searchObjectArray:@"UserEventHistory" filterString:@"isUploaded = '0'"];
    for (int i = 0; i < [userEventHistroyArr count]; i++) {
        UserEventHistory *userEventHistory = (UserEventHistory *)[userEventHistroyArr objectAtIndex:i];
        if (i == 0) {
            //upload event history
            fSelected = [[NSDateFormatter alloc] init];
            [fSelected setTimeZone:[NSTimeZone localTimeZone]];
            [fSelected setDateFormat:@"YYYYMMddHHmmss"];
            temp = [temp stringByAppendingFormat:@"%@-%@",userEventHistory.buttonCode,[fSelected stringFromDate:userEventHistory.clickTime]];
        }else {
            temp = [temp stringByAppendingFormat:@",%@-%@",userEventHistory.buttonCode,[fSelected stringFromDate:userEventHistory.clickTime]];
        }
    }
    id withObject = nil;
    if (userEventHistroyArr != nil && [userEventHistroyArr count] != 0 ) {
        withObject = userEventHistroyArr;
    }
    if (![@"" isEqualToString:temp]) {
        [paraDic setObject:temp forKey:@"userEvents"];
    }
    [self syncMyData:paraDic netParameters:netParameters withObject:nil userEmails:nil syncUserIds:nil initEnabled:NO];
    [[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] stopReceive];
    [[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] startReceive];
}


-(void) syncMyData:(NSMutableDictionary *)paraDic netParameters:(NSMutableDictionary *)netParameter withObject:(id)withObject userEmails:(NSString *)userEmails syncUserIds:(NSString *)syncUserIds initEnabled:(bool)initEnabled{ 
    NSString *queueName = @"sync";
    //get message etc. from server
    if ([@"0" isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]) {
        return;
    }
    if([[WeiJuAppPrefs getSharedInstance] isInitCoreData]){
        [paraDic setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs userId] forKey:@"allFriend"];
    }
    if (userEmails != nil) {
        [paraDic setObject:userEmails forKey:@"userEmails"];
    }
    if (syncUserIds != nil) {
        [paraDic setObject:syncUserIds forKey:@"syncUserIds"];
    }
    
    NSString *syncMethod = @"syncCoreDataWithNetDictionaryWithoutInitData:";
    if(initEnabled){
        syncMethod = @"syncCoreDataWithNetDictionaryByTimer:";
    }

    [netParameter setObject:[NSURL URLWithString:[@"http://" stringByAppendingFormat:@"%@/Party/userFriendsAction!syncClientData.action",ipAddress]] forKey:@"url"];
    
    if(paraDic != nil){
        [paraDic setObject:curProtoVer forKey:@"protocolVersion"];
        [paraDic setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:[[WeiJuAppPrefs getSharedInstance] userId]] forKey:@"token"];
        if ([paraDic objectForKey:@"userId"] == nil ) {
            [paraDic setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
        }
        [netParameter setObject:paraDic forKey:@"postData"];
    }
    if(withObject != nil){
        [netParameter setObject:withObject forKey:@"withObject"];
    }
    if(searchVersionEnabled){
        [paraDic setObject:@"1" forKey:@"version"];
        
        [netParameter setObject:self forKey:@"invokeObjectClass1"];
        [netParameter setObject:@"versionCallBak:" forKey:@"invokeObjectMethodName1"];
        
        [netParameter setObject:[ConvertData getSharedInstance] forKey:@"invokeObjectClass2"];
        [netParameter setObject:syncMethod forKey:@"invokeObjectMethodName2"];
        
        [netParameter setObject:[[WeiJuNetWorkClient alloc] init] forKey:@"invokeObjectClass3"];
        [netParameter setObject:@"updateObjectArrayWithNetObjectToUploadedStatus:" forKey:@"invokeObjectMethodName3"];
        [OperationQueue addTask:queueName operationObject:[[HttpOperation alloc] init] parameters:netParameter];
        return;
    }else {
        
        [netParameter setObject:[ConvertData getSharedInstance] forKey:@"invokeObjectClass1"];
        [netParameter setObject:syncMethod forKey:@"invokeObjectMethodName1"];
        
        [netParameter setObject:[[WeiJuNetWorkClient alloc] init] forKey:@"invokeObjectClass2"];
        [netParameter setObject:@"updateObjectArrayWithNetObjectToUploadedStatus:" forKey:@"invokeObjectMethodName2"];
    }
    
    if ([OperationQueue getOperationQueue:queueName].operationCount > 2 ) {
        NSLog(@"Canceled task sync with network........................");
        return;
    }
    [OperationQueue addTask:queueName operationObject:[[HttpOperation alloc] init] parameters:netParameter]; 
}

-(void)updateObjectArrayWithNetObjectToUploadedStatus:(NSDictionary *) dic{
    if ([dic objectForKey:@"withObject"] == nil) {
        return;
    }
    if ([ConvertData getErrorInfo:dic] != nil) {
        return;
    }
    for(int i = 0;i<[[dic objectForKey:@"withObject"] count];i++){
        ((UserEventHistory *)[[dic objectForKey:@"withObject"] objectAtIndex:i]).isUploaded = @"1";
    }
    [WeiJuManagedObjectContext save];
    
}



-(void) versionCallBak:(NSDictionary *)dictionary
{
    if ([ConvertData getErrorInfo:dictionary] != nil) return;
    if ([ConvertData getValue:dictionary key:@"cav"] != nil) {
        [[WeiJuAppPrefs getSharedInstance] setNewAppVer:[ConvertData getValue:dictionary key:@"cav"]];
        [[WeiJuAppPrefs getSharedInstance] setNewAppVerData:[ConvertData getValue:dictionary key:@"cav_data"]];
        [[WeiJuAppPrefs getSharedInstance] setNewProtoVer:[ConvertData getValue:dictionary key:@"cpv"]];
        [[WeiJuAppPrefs getSharedInstance] setNewProtoVerData:[ConvertData getValue:dictionary key:@"cpv_data"]];
        searchVersionEnabled = false;
    }
//    if(![@"1" isEqualToString:[ConvertData getValue:dictionary key:@"isLastVersion"]]){
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Found New Version" message:[ConvertData getValue:dictionary key:@"versionInfo"] delegate:self cancelButtonTitle:@"Remind Later" otherButtonTitles:@"Upgrade Now",nil];
//        [alert show];
//		[[WeiJuAppPrefs getSharedInstance] setNewVersionAvailable:YES];
//    }
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex == 1) {
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/gb/app/calendarium/id482136387?l=en&mt=8"]];
//    }
//}


/**find messages of all party messages and system messages**/
//-(void) searchMessages{
//    if([WeiJuListVCtrl getSharedInstance] == nil)return;
//    if([WeiJuListVCtrl getSharedInstance].weiJuListDCtrl == nil)return;   
//    if([[[WeiJuAppDelegate getSharedInstance].appPrefs userId] intValue] == 0)return;
//    NSString *urlStr = [@"http://" stringByAppendingFormat:@"%@/Party/userPartyMessageAction!searchNewMessages.action?userId=%@",ipAddress,[[WeiJuAppDelegate getSharedInstance].appPrefs userId]];
//    //NSLog(@"%@",urlStr);
//    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
//    [dictionary setObject:[NSURL URLWithString:urlStr] forKey:@"url"];
//    [dictionary setObject:[WeiJuListVCtrl getSharedInstance].weiJuListDCtrl forKey:@"invokeObjectClass"];
//    [dictionary setObject:@"getNewMessageOperationDone:" forKey:@"invokeObjectMethodName"];
//    HttpOperation *httpOperation = [[HttpOperation alloc] init];
//    [OperationQueue addTask:@"http" operationObject:httpOperation parameters:dictionary];
//}




@end
