#import <Foundation/Foundation.h>

@interface DESUtils : NSObject {
    
}

+ (NSString*) getRandomString:(int)keySize;

+ (NSString*) getRandomUUID:(int)keySize;

+ (NSString*) getCachesDirectory;

+ (NSString*) getDocumentsDirectory;

+ (NSMutableArray*) getFilesList:(NSString*)documentsDirectory;

+ (NSString*) zipFiles:(NSArray*)arrFile NewFileNames:(NSMutableArray*)arrNewFileNames 
			  Password:(NSString*)password ZipToFileName:(NSString*)zipFileName;

+ (NSString*) unzipFile:(NSString*)zippedFile Password:(NSString*)password ToFolder:(NSString*)toFolder;

+ (NSString*) getCurrentDateTime;

+ (NSData*) hexToBytes:(NSString*)strHex;

+ (NSString*) Base64Encode:(NSData*)data;

+ (NSData*) Base64Decode:(NSString*)string;

+ (NSString*) DataToASCIIString:(NSData*)data;

+ (NSData*) ASCIIStringToData:(NSString*)str;

+ (NSString*) DataToUTF8String:(NSData*)data;

+ (NSData*) UTF8StringToData:(NSString*)str;

+ (NSString*) compositePublicKeyFromJavaKeyString:(NSString*)strPublicKey;

+ (NSString*) compositePrivateKeyFromJavaKeyString:(NSString*)strPrivateKey;

+ (NSString *) encryptUseDES:(NSString *)plainText key:(NSString *)key;

+ (NSString *) encryptUseDESDefaultKey:(NSString *)plainText ;

@end