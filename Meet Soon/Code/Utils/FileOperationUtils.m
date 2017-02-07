//
//  FileOperationUtils.m
//  WeiJu
//
//  Created by Michael Luo on 2/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileOperationUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation FileOperationUtils

@synthesize documentPath;

-(NSString *) getDocumentPath{
    if(documentPath == nil){
        documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }
    return documentPath;
}

- (NSString *) getDisName{
    NSDate* nowData = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmssSSS"];
    int randomNumber = 1+ arc4random() %(100000);
    if(randomNumber < 10000){
        randomNumber = randomNumber + 10000;
    }
    return [NSString localizedStringWithFormat:@"%s%s",[[dateFormatter stringFromDate:nowData] UTF8String],[[NSString stringWithFormat:@"%d",randomNumber] UTF8String]];
}

-(NSString *) createDifferentFile:(NSData *) fileData suffixFileName:(NSString *) suffixFileName{   
    NSDate* nowData = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmssS"];
    int randomNumber = 1+ arc4random() %(100000);
    if(randomNumber < 10000){
        randomNumber = randomNumber + 10000;
    }
    NSString * fileName = [NSString localizedStringWithFormat:@"%s%s",[[dateFormatter stringFromDate:nowData] UTF8String],[[NSString stringWithFormat:@"%d",randomNumber] UTF8String]];
    NSString *createPath=[NSString stringWithFormat:@"%@/%@",[self getDocumentPath],[fileName stringByAppendingFormat:suffixFileName]];//用文件名补全路径
    [[NSFileManager defaultManager] createFileAtPath:createPath contents:fileData attributes:nil];//创建文件
    return [fileName stringByAppendingFormat:suffixFileName];
}

-(UIImage *) readImageFromFileName:(NSString *) fileName{
    NSString *filePath=[NSString stringWithFormat:@"%@/%@",[self getDocumentPath],[fileName stringByAppendingFormat:@"%@",@".png"]];
    UIImage *readImage=[UIImage imageWithContentsOfFile:filePath];
    return readImage;
}

-(void) saveFileWithDisFileName:(NSString *) fileName image:(UIImage *)image{
    
    fileName = [fileName stringByAppendingString:@".png"];
    
    //得到数据库的路径  
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];  
    //CoreData是建立在SQLite之上的，数据库名称需与Xcdatamodel文件同名  
    NSString *filePath = [docs stringByAppendingPathComponent:fileName];
    NSURL *storeUrl = [NSURL fileURLWithPath:filePath];  
    NSError *error;
    [[[NSFileManager alloc] init] removeItemAtURL:storeUrl error:&error];
    
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];   
}

-(NSString *) readTextFromFileName:(NSString *) fileName{
    NSString *filePath=[NSString stringWithFormat:@"%@/%@",[self getDocumentPath],fileName];
    return [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
}

+(NSString *) md5:(NSString *) str  
{    
    const char *cStr = [str UTF8String];    
    unsigned char result[CC_MD5_DIGEST_LENGTH];    
    CC_MD5( cStr, strlen(cStr), result );    
    
    NSMutableString *hash = [NSMutableString string];  
    for(int i=0;i<CC_MD5_DIGEST_LENGTH;i++)  
    {  
        [hash appendFormat:@"%02X",result[i]];  
    }  
    return [hash lowercaseString];  
} 

-(NSString *) randomNumber:(int) num{   
    int i = 1;
    int j = 1;
    for(int m=0;m <num ;m++){
        if(m == (num-1)){
            i = i*10;
        }else{
            j = j*10;
            i = i*10;

        }
    }
    
    int randomNumber = 1+ arc4random() %(i);
    if(randomNumber < j){
        randomNumber = randomNumber + j;
    }
    return [NSString stringWithFormat:@"%d",randomNumber];
}

-(NSString *) getWeiJuCommonMd5:(NSString *) userId{   
    return [FileOperationUtils md5:[@"" stringByAppendingFormat:@"%@weiju@_@",userId]];
}


@end
