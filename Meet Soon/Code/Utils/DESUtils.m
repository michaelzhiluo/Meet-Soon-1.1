//
//  Util.m
//  AESCryptoiPhone
//
//  Created by dumbbellyang on 1/12/11.
//  Copyright 2011 Foxconn Technology Group. All rights reserved.
//
#import <CommonCrypto/CommonCryptor.h>
#import "DESUtils.h"
#import "NSData+Base64.h"

@implementation DESUtils

static Byte iv[] = {1,2,3,4,5,6,7,8};
NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_+/";

+ (NSString*) getRandomString:(int)keySize{
	
	NSMutableString *randomString = [NSMutableString stringWithCapacity: keySize];        
	for (int i=0; i<keySize; i++) {           
		[randomString appendFormat: @"%c", [letters characterAtIndex: rand()%[letters length]]];      
	}        
	return randomString;  
}

+ (NSString*) getRandomUUID:(int)keySize{
	NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
	while (keySize > [uuid length]) {
		uuid = [uuid stringByAppendingFormat:@"--%@",[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	
	return [uuid substringToIndex:keySize];
}

+ (NSString*) getCachesDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString*) getDocumentsDirectory{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
}

+ (NSMutableArray*) getFilesList:(NSString*)documentsDirectory{
	NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *fileList = [manager directoryContentsAtPath:documentsDirectory];
	NSMutableArray *list = [[NSMutableArray alloc] init];
    for (NSString *s in fileList){
		//NSLog(s);
		[list addObject:s];
    }
	
	return list;;
}

+ (NSString*) getCurrentDateTime{
	NSDateFormatter *format = [[NSDateFormatter alloc] init] ;
	[format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	return [format stringFromDate:[NSDate date]];
}



+ (NSData*) hexToBytes:(NSString*)strHex {
	NSMutableData* data = [[NSMutableData alloc] init] ;
	int idx;
	for (idx = 0; idx+2 <= strHex.length; idx+=2) {
		NSRange range = NSMakeRange(idx, 2);
		NSString* hexStr = [strHex substringWithRange:range];
		NSScanner* scanner = [NSScanner scannerWithString:hexStr];
		unsigned int intValue;
		[scanner scanHexInt:&intValue];
		[data appendBytes:&intValue length:1];
	}
	return data;
}



+ (NSString*) DataToASCIIString:(NSData*)data{
	return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
}

+ (NSData*) ASCIIStringToData:(NSString*)str{
	return [str dataUsingEncoding:NSASCIIStringEncoding];
}

+ (NSString*) DataToUTF8String:(NSData*)data{
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ;
}

+ (NSData*) UTF8StringToData:(NSString*)str{
	return [str dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*) compositePublicKeyFromJavaKeyString:(NSString*)strPublicKey{
	NSString *strResult = [strPublicKey substringToIndex:64];
	int lineCount = [strPublicKey length] / 64;
	for (int i = 1; i < lineCount; i ++) {
		strResult = [strResult stringByAppendingFormat:@"\n%@",[strPublicKey substringWithRange:NSMakeRange(i * 64, 64)]];
	}
	strResult = [strResult stringByAppendingFormat:@"\n%@",[strPublicKey substringFromIndex:lineCount * 64]];;
	
	return [NSString stringWithFormat:@"%@\n%@\n%@",@"-----BEGIN PUBLIC KEY-----",strResult,@"-----END PUBLIC KEY-----"];
}

+ (NSString*) compositePrivateKeyFromJavaKeyString:(NSString*)strPrivateKey{
	NSString *strResult = [strPrivateKey substringToIndex:64];
	int lineCount = [strPrivateKey length] / 64;
	for (int i = 1; i < lineCount; i ++) {
		strResult = [strResult stringByAppendingFormat:@"\n%@",[strPrivateKey substringWithRange:NSMakeRange(i * 64, 64)]];
	}
	strResult = [strResult stringByAppendingFormat:@"\n%@",[strPrivateKey substringFromIndex:lineCount * 64]];;
	
	return [NSString stringWithFormat:@"%@\n%@\n%@",@"-----BEGIN RSA PRIVATE KEY-----",strResult,@"-----END RSA PRIVATE KEY-----"];	
}


+(NSString *) encryptUseDES:(NSString *)plainText key:(NSString *)key
{
    NSString *ciphertext = nil;
    const char *textBytes = [plainText UTF8String];
    NSUInteger dataLength = [plainText length];
    unsigned char buffer[1024];
    memset(buffer, 0, sizeof(char));
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding,
                                          [key UTF8String], kCCKeySizeDES,
                                          iv,
                                          textBytes, dataLength,
                                          buffer, 1024,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *data = [NSData dataWithBytes:buffer length:(NSUInteger)numBytesEncrypted];
        ciphertext = [data base64Encoding];
    }
    return ciphertext;
}

+(NSString *) encryptUseDESDefaultKey:(NSString *)plainText 
{
    return [self encryptUseDES:plainText key:@"_weiju!@"];
}

//-(NSString*) decryptUseDES:(NSString*)cipherText key:(NSString*)key {
//    NSData* cipherData = [GTMBase64 decodeString:cipherText];
//    unsigned char buffer[1024];
//    memset(buffer, 0, sizeof(char));
//    size_t numBytesDecrypted = 0;
//    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, 
//                                          kCCAlgorithmDES, 
//                                          kCCOptionPKCS7Padding, 
//                                          [key UTF8String], 
//                                          kCCKeySizeDES, 
//                                          iv, 
//                                          [cipherData bytes], 
//                                          [cipherData length], 
//                                          buffer, 
//                                          1024, 
//                                          &numBytesDecrypted);
//    NSString* plainText = nil;
//    if (cryptStatus == kCCSuccess) {
//        NSData* data = [NSData dataWithBytes:buffer length:(NSUInteger)numBytesDecrypted];
//        plainText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ;
//    }
//    return plainText;
//}

+(NSString *) parseByte2HexString:(Byte *) bytes
{
    NSMutableString *hexStr = [[NSMutableString alloc]init];
    int i = 0;
    if(bytes)
    {
        while (bytes[i] != '\0') 
        {
            NSString *hexByte = [NSString stringWithFormat:@"%x",bytes[i] & 0xff];///16进制数
            if([hexByte length]==1)
                [hexStr appendFormat:@"0%@", hexByte];
            else 
                [hexStr appendFormat:@"%@", hexByte];
            
            i++;
        }
    }
    //NSLog(@"bytes 的16进制数为:%@",hexStr);
    return hexStr;
}

+(NSString *) parseByteArray2HexString:(Byte[]) bytes
{
    NSMutableString *hexStr = [[NSMutableString alloc]init];
    int i = 0;
    if(bytes)
    {
        while (bytes[i] != '\0') 
        {
            NSString *hexByte = [NSString stringWithFormat:@"%x",bytes[i] & 0xff];///16进制数
            if([hexByte length]==1)
                [hexStr appendFormat:@"0%@", hexByte];
            else 
                [hexStr appendFormat:@"%@", hexByte];
            
            i++;
        }
    }
    //NSLog(@"bytes 的16进制数为:%@",hexStr);
    return hexStr;
}



@end
