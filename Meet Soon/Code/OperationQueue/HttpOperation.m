/**
 *    @file            HTTPOperationUtils.m
 *    @author            
 *    @date            
 *    @version        
 *    @description     
 *    @copyright        
 *    @brief
 */

#import "HttpOperation.h"
#import "WeiJuNetWorkClient.h"
#import "QLog.h"
#import "Utils.h"
#import "ASIFormDataRequest.h"
#import "WeiJuAppPrefs.h"
#import "Utils.h"

@implementation HttpOperation

@synthesize parameters;

- (void)setParameter:(NSMutableDictionary *)para{
    parameters = para;
}

- (void)main {  
    //将targetURL 的值返回为webpageString 对象  
        //get invoke object,and invoke the method of object   
    
    NSString *webpageData = [self getStringFromHttpUrl:[parameters valueForKey:@"url"] postData:[parameters valueForKey:@"postData"]];
    NSMutableArray *myArray = nil;
    
    if(webpageData != nil && [webpageData rangeOfString:@"<TITLE>Service unavailable!</TITLE>"].location == NSNotFound) {
        @try{
            NSString *a = [webpageData stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *b = [a stringByReplacingOccurrencesOfString:@"+" withString:@" "];
            myArray = (NSMutableArray *)[NSJSONSerialization JSONObjectWithData:[b dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            if(myArray == nil){
                 myArray = [[NSMutableArray alloc] init];
            }
            [WeiJuNetWorkClient setNetWorkEnabled:YES];
        }
        @catch (NSException *e) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setValue:@"Your iPhone can not access our server. Please check your network connectivity and retry.\n\nIf the issue persists, our server might be overloaded and is under upgrade, please try later or report issue to us." forKey:@"error"];
            if (myArray == nil) {
                myArray = [[NSMutableArray alloc] init];
            }
            [myArray addObject:dictionary];
        }
    }else {
        [WeiJuNetWorkClient setNetWorkEnabled:NO];
        myArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:@"Your iPhone can not access our server. Please check your network connectivity and retry.\n\nIf the issue persists, our server might be overloaded and is under upgrade, please try later or report issue to us." forKey:@"error"];
        [myArray addObject:dictionary];
        
    }
    if([parameters objectForKey:@"NoCheck"] == nil && [@"0" isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]){
        return;
    }
    
    NSMutableDictionary *dictionary;
    if(![parameters valueForKey:@"invokeObjectClass1"] == nil){   
        
        dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:myArray forKey:@"netarray"];
        
        if(![parameters valueForKey:@"withObject"] == nil){
            [dictionary setObject:[parameters valueForKey:@"withObject"] forKey:@"withObject"];
        }
        if ([parameters valueForKey:@"runInBackground1"] != nil) {
            
            [[parameters valueForKey:@"invokeObjectClass1"] performSelectorInBackground:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName1"]) withObject:dictionary];       
        }else {
            [[parameters valueForKey:@"invokeObjectClass1"] performSelectorOnMainThread:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName1"]) withObject:dictionary waitUntilDone:NO];
        }
        
    } 

    if(![parameters valueForKey:@"invokeObjectClass2"] == nil){   
        if([parameters objectForKey:@"NoCheck"] == nil && [@"0" isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]){
            return;
        }
        if ([parameters valueForKey:@"runInBackground2"] != nil) {
            [[parameters valueForKey:@"invokeObjectClass2"] performSelectorInBackground:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName2"]) withObject:dictionary];       
        }else {
            [[parameters valueForKey:@"invokeObjectClass2"] performSelectorOnMainThread:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName2"]) withObject:dictionary waitUntilDone:NO];
        }      
    }
    if(![parameters valueForKey:@"invokeObjectClass3"] == nil){
        if([parameters objectForKey:@"NoCheck"] == nil && [@"0" isEqualToString:[[WeiJuAppPrefs getSharedInstance] userId]]){
            return;
        }
        if ([parameters valueForKey:@"runInBackground3"] != nil) {
            [[parameters valueForKey:@"invokeObjectClass3"] performSelectorInBackground:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName3"]) withObject:dictionary];       
        }else {
            [[parameters valueForKey:@"invokeObjectClass3"] performSelectorOnMainThread:NSSelectorFromString([parameters valueForKey:@"invokeObjectMethodName3"]) withObject:dictionary waitUntilDone:NO];
        }       
    }
   
} 

-(NSString *)getStringFromHttpUrl:(NSURL *) url postData:(NSDictionary *)postData
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    //[request setShouldCompressRequestBody:YES];
    [request setAllowCompressedResponse:YES];
    [request setTimeOutSeconds:30];
    if ([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE) 
	{
        //[self printRequestLog:url.absoluteString postData:postData];
    }
    
    for (int i = 0; i < [[postData allKeys] count]; i++) {
        [request setPostValue:[postData objectForKey:[[postData allKeys] objectAtIndex:i]] forKey:[[postData allKeys] objectAtIndex:i]];
    }
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        //[Utils log:@"%s [line:%d] Net Result:%@",__FUNCTION__,__LINE__,[[request responseString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        return [request responseString];
    }else {
        [WeiJuNetWorkClient setNetWorkEnabled:NO];
		//don't comment out
        [Utils log:@"%s [line:%d] NSURLConnection error: %@ %@",__FUNCTION__,__LINE__,[error localizedDescription], [error localizedRecoverySuggestion]];
        return nil;
    }
}

- (void)printRequestLog:(NSString *)url postData:(NSDictionary *) postData
{
    
    NSString *postDataStr = @"";
    for (int i=0; i<[[postData allKeys] count]; i++) {
        NSString *key = [[postData allKeys] objectAtIndex:i];
        NSString *value = [postData objectForKey:key];
        if(value == nil || [value isEqualToString:@""])continue;
        
        NSString *outputStr = (__bridge NSString *) 
        CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                (__bridge CFStringRef)value,
                                                NULL,
                                                (CFStringRef)@"-!*'();:@&=+$,/?%#[]",
                                                kCFStringEncodingUTF8);
        if(i == 0){
            postDataStr = [postDataStr stringByAppendingFormat:@"%@=%@",key,outputStr];
        }else {
            postDataStr = [postDataStr stringByAppendingFormat:@"&%@=%@",key,outputStr];
        }
    } 
    [Utils log:@"%s [line:%d] request Url:%@?%@",__FUNCTION__,__LINE__,url,postDataStr];
}

-(NSString *)getStringFromHttpUrlWithIOSAPI:(NSURL *) url postData:(NSDictionary *)postData
{
    NSString *postDataStr = @"";
    for (int i=0; i<[[postData allKeys] count]; i++) {
        NSString *key = [[postData allKeys] objectAtIndex:i];
        NSString *value = [postData objectForKey:key];
        if(value == nil || [value isEqualToString:@""])continue;
        
        NSString *outputStr = (__bridge NSString *) 
        CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                (__bridge CFStringRef)value,
                                                NULL,
                                                (CFStringRef)@"-!*'();:@&=+$,/?%#[]",
                                                kCFStringEncodingUTF8);
        if(i == 0){
            postDataStr = [postDataStr stringByAppendingFormat:@"%@=%@",key,outputStr];
        }else {
            postDataStr = [postDataStr stringByAppendingFormat:@"&%@=%@",key,outputStr];
        }
    }
    
    NSData *postDataTemp = [postDataStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];  
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postDataTemp length]];  
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;  
    [request setURL:url];  
    [request setHTTPMethod:@"POST"]; 
    if(postData == nil){
        [Utils log:@"%s [line:%d] request Url:%@?%@",__FUNCTION__,__LINE__,url,postDataStr];
        //NSLog(@"requestURL:%@",[url description]);
    }else{
        [Utils log:@"%s [line:%d] request Url:%@",__FUNCTION__,__LINE__,url];
        //NSLog(@"requsssestURL:%@",[[url description] stringByAppendingFormat:@"?%@",postData]);
    }
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];  
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];  
    [request setHTTPBody:postDataTemp];  
    [NSURLConnection connectionWithRequest:request delegate:self ];  
    [request setTimeoutInterval:30];
    //同步请求的的代码
    //returnData就是返回得到的数据
    NSError *error;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];    
    
    if (error) {
        [WeiJuNetWorkClient setNetWorkEnabled:NO];
        //don't comment out
        [Utils log:@"%s [line:%d] NSURLConnection error: %@ %@",__FUNCTION__,__LINE__,[error localizedDescription], [error localizedRecoverySuggestion]];
        return nil;
    }else {
        if (returnData) {
            NSString *responseString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            //NSLog(@"Net Result:%@",[responseString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
            return responseString;
        }else{
            return @"";
        }
    }
}

@end