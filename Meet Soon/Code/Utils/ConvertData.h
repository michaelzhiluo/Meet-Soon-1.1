//
//  ConvertUtil.h
//  WeiJu
//
//  Created by Michael Luo on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WeiJuData;
@interface ConvertData: NSObject


+(NSString *)getWithOjbect:(NSDictionary *) messageData;
+(id)getValue:(NSDictionary *) messageData key:(NSString *)key;
-(void)syncCoreDataWithNetDictionaryWithoutInitData:(NSDictionary *)messageData;
-(void)syncCoreDataWithNetDictionaryByTimer:(NSDictionary *)messageData;
+(NSString *)getErrorInfo:(NSDictionary *) messageData;
+(ConvertData *)getSharedInstance;
-(void)initCoreDataDone:(NSString *)contextName;
@end
