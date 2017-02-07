//
//  ConvertUtil.h
//  WeiJu
//
//  Created by Michael Luo on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConvertUtil : NSObject
-(NSDate *)convertJSONDatetoCurrentDateStr:(NSDictionary *) JSONDate;
+(NSString *)convertDateToString:(NSDate *)date dateFormat:(NSString *) dateFormat;
+(NSString *)convertArrayStrToStr:(NSArray *) array;
+(NSString *)convertArrayStrToIntStr:(NSArray *) array;
+(NSString *)convertFriendDataListToStr:(NSArray *) array;
+(NSString *)convertFriendDataListToIntStr:(NSArray *) array;
+(NSString *)convertIntStrToStr:(NSString *) intStr;
+(NSString *)convertMessageStatusListToStr:(NSArray *) array;
+(NSString *)convertFriendDataSetToStr:(NSOrderedSet *) array;
+(NSString *)convertStrToIntStr:(NSString *)ids;
+(CLLocationCoordinate2D) convertNSStringToCLLocation:(NSString *)locationStr;
+(NSString *) convertCLLocationToNSString:(CLLocationCoordinate2D)location;
@end
