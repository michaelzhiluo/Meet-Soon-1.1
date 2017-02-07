//
//  ConvertUtil.m
//  WeiJu
//
//  Created by Michael Luo on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConvertUtil.h"
#import "FriendData.h"
#import "MessageStatus.h"

@implementation ConvertUtil

-(NSDate *)convertJSONDatetoCurrentDateStr:(NSDictionary *) JSONDate{
    
    NSString *year = [NSString stringWithFormat:@"%d",([[JSONDate objectForKey:@"year"] intValue]+1900)];
    NSString *mouth = [NSString stringWithFormat:@"%d",([[JSONDate objectForKey:@"month"] intValue]+1)];
    if([mouth length] <2){
        mouth = [@"0" stringByAppendingFormat:mouth];
    }
    NSString *date = [NSString stringWithFormat:@"%d",([[JSONDate objectForKey:@"date"] intValue])];
    NSString *hours = [NSString stringWithFormat:@"%d",([[JSONDate objectForKey:@"hours"] intValue])];
    NSString *minutes = [NSString stringWithFormat:@"%d",([[JSONDate objectForKey:@"minutes"] intValue])];
    NSString *seconds = [NSString stringWithFormat:@"%d",([[JSONDate objectForKey:@"seconds"] intValue])];
    int timezone = ([[JSONDate objectForKey:@"timezoneOffset"] intValue]);
    NSString *dateStr = [[[[[[[[[[year stringByAppendingFormat:@"-"] stringByAppendingFormat:mouth] stringByAppendingFormat:@"-"] stringByAppendingFormat:date] stringByAppendingFormat:@" "] stringByAppendingFormat:hours] stringByAppendingFormat:@":"] stringByAppendingFormat:minutes] stringByAppendingFormat:@":"] stringByAppendingFormat:seconds];   
    NSDateFormatter *f1 = [[NSDateFormatter alloc] init];
    //[f1 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:480]];
    [f1 setDateFormat:[@"YYYY-MM-dd HH:mm:ss " stringByAppendingFormat:@"%i",timezone]];
    NSDate *d = [f1 dateFromString:dateStr]; 
    return d;
}

+(NSString *)convertDateToString:(NSDate *)date dateFormat:(NSString *) dateFormat{
    NSDateFormatter *f1 = [[NSDateFormatter alloc] init];
    [f1 setDateFormat:dateFormat];
    return [f1 stringFromDate:date];
}

+(NSString *)convertIntStrToStr:(NSString *) intStr{
    
    NSArray *a = [intStr componentsSeparatedByString:@","];
    NSString *r = @""; 
    for (int i=0;i<[a count] ; i++) {        
        if(i == [a count] - 1){
            r =[r stringByAppendingFormat:@"'%@'",[a objectAtIndex:i]];          
            break; 
        }
        r =[r stringByAppendingFormat:@"'%@',",[a objectAtIndex:i]];      
    }    
    return r;
}

+(NSString *)convertStrToIntStr:(NSString *)ids{
    return [ids stringByReplacingOccurrencesOfString:@"'" withString:@""];
}

+(NSString *)convertArrayStrToStr:(NSArray *) array{
  
    NSString *a = @"";
    for (int i=0;i<[array count] ; i++) {        
        if(i == [array count] - 1){
            a =[a stringByAppendingFormat:@"'%@'",[array objectAtIndex:i]];          
            break; 
        }
       a =[a stringByAppendingFormat:@"'%@',",[array objectAtIndex:i]];      
    }    
    return a;
}

+(NSString *)convertArrayStrToIntStr:(NSArray *) array{
    
    NSString *a = @"";
    for (int i=0;i<[array count] ; i++) {    
        
        if(i == [array count] - 1){
            a =[a stringByAppendingFormat:@"%@",[array objectAtIndex:i]];          
            break; 
        }
        a =[a stringByAppendingFormat:@"%@,",[array objectAtIndex:i]];      
    }    
    return a;
}

+(NSString *)convertFriendDataListToIntStr:(NSArray *) array{
    
    NSString *a = @"";
    for (int i=0;i<[array count] ; i++) {
        if(i == [array count] - 1){
            a =[a stringByAppendingFormat:@"%@",((FriendData *)[array objectAtIndex:i]).userId];          
            break; 
        }
        a =[a stringByAppendingFormat:@"%@,",((FriendData *)[array objectAtIndex:i]).userId];      
    }    
    return a;
}


//NSArray  * array= [fruits componentsSeparatedByString:@","];
+(NSString *)convertFriendDataSetToStr:(NSOrderedSet *) array{
    NSString *a = @"";
    for (int i=0;i<[array count] ; i++) {
        if(i == [array count] - 1){
            a =[a stringByAppendingFormat:@"'%@'",((FriendData *)[array objectAtIndex:i]).userId];          
            break; 
        }
        a =[a stringByAppendingFormat:@"'%@',",((FriendData *)[array objectAtIndex:i]).userId];      
    }    
    return a;
}

+(NSString *)convertFriendDataListToStr:(NSArray *) array{
    
    NSString *a = @"";
    for (int i=0;i<[array count] ; i++) {
        if(i == [array count] - 1){
            a =[a stringByAppendingFormat:@"'%@'",((FriendData *)[array objectAtIndex:i]).userId];          
            break; 
        }
        a =[a stringByAppendingFormat:@"'%@',",((FriendData *)[array objectAtIndex:i]).userId];      
    }    
    return a;
}

+(NSString *)convertMessageStatusListToStr:(NSArray *) array{
    
    NSString *a = @"";
    for (int i=0;i<[array count] ; i++) {
        if(i == [array count] - 1){
            a =[a stringByAppendingFormat:@"'%@'",((MessageStatus *)[array objectAtIndex:i]).messageStatusClientId];          
            break; 
        }
        a =[a stringByAppendingFormat:@"'%@',",((MessageStatus *)[array objectAtIndex:i]).messageStatusClientId];      
    }    
    return a;
}

-(CLLocationCoordinate2D) convertNSStringToCLLocation:(NSString *)locationStr {
       
    CLLocationCoordinate2D location;
    
    // split the string by comma
    NSArray * locationArray = [locationStr componentsSeparatedByString: @","];        
    
    // set our latitude and longitude based on the two chunks in the string
    location.latitude = [[locationArray objectAtIndex:0] doubleValue];
    location.longitude = [[locationArray objectAtIndex:1] doubleValue];

    return location;
}

-(NSString *) convertCLLocationToNSString:(CLLocationCoordinate2D)location {
    //NSString *locationString = @"123,0,0,0";

    NSString *lat = [[NSString alloc] initWithFormat:@"%g",location.latitude];
    NSString *longt = [[NSString alloc] initWithFormat:@"%g",location.longitude];
    
    return [lat stringByAppendingFormat:longt];
}

@end
