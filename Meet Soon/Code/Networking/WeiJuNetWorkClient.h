//
//  TestOut.h
//  TestNSOperation
//
//  Created by Michael Luo on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeiJuNetWorkClient : NSObject

@property (nonatomic, assign) BOOL networkEnabled;
/**find messages of all party messages and system messages**/

-(void) requestDataWithNoToken:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod ;

-(void) requestData:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod;

-(void) requestData:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance1:(id)callbackInstance1 callbackMethod1:(NSString *)callbackMethod1 callbackInstance2:(id)callbackInstance2 callbackMethod2:(NSString *)callbackMethod2 callbackInstance3:(id)callbackInstance3 callbackMethod3:(NSString *)callbackMethod3;

-(void) sendData:(NSString *)serviceName parameters:(NSMutableDictionary *)parameters withObject:(id)withObject callbackInstance:(id)callbackInstance callbackMethod:(NSString *)callbackMethod;



-(void) uploadEvent:(NSString *)userId;

/**if you required a new API method ,please added in the file**/
- (NSString *)encodeToPercentEscapeString: (NSString *) input;

+(void)setSearchEnabled:(bool)enabled;

+(void)setSearchVersionEnabled:(bool)enabled;

+(WeiJuNetWorkClient *) getSharedWeiJuNetWorkClient;

-(void) syncMyData:(NSString *)userEmails syncUserIds:(NSString *)syncUserIds;

-(void) syncMyData:(NSMutableDictionary *)paraDic netParameters:(NSMutableDictionary *)netParameter withObject:(id)withObject userEmails:(NSString *)userEmails syncUserIds:(NSString *)syncUserIds initEnabled:(bool)initEnabled;

-(void) startReceive;

+(void)setNetWorkEnabled:(bool)enabled;

+(bool)getNetWorkEnabled;

+(void)setScheduleFristEnabled:(bool)enabled;

-(void) stopReceive;

+(NSString *)getIpAddress;

@end
