//
//  FileOperationUtils.h
//  WeiJu
//
//  Created by Michael Luo on 2/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



@interface FileOperationUtils : NSObject

@property (nonatomic,retain) NSString *documentPath;

- (NSString *) getDocumentPath;
- (NSString *) createDifferentFile:(NSData *) fileData suffixFileName:(NSString *) suffixFileName;
- (NSString *) readTextFromFileName:(NSString *) fileName;
- (UIImage *) readImageFromFileName:(NSString *) fileName;
- (NSString *) getDisName;
+ (NSString *) md5:(NSString *) str ;
-(NSString *) randomNumber:(int) num;
-(NSString *) getWeiJuCommonMd5:(NSString *) userId;
-(void) saveFileWithDisFileName:(NSString *) fileName image:(UIImage *)image;
@end
