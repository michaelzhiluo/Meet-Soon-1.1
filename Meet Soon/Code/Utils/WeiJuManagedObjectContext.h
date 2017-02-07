//
//  WeiJuManagedObjectContext.h
//  WeiJu
//
//  Created by Michael Luo on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WeiJuManagedObjectContext : NSObject 

@property (nonatomic,retain) NSString *contextName;

+ (NSManagedObjectContext *) getManagedObjectContext;

+ (NSManagedObjectContext *) getManagedObjectContextWithContextName:(NSString *)contextName;

+ (void)quickSave;

+ (void)quickSaveWithContextName:(NSString *)contextName;

+ (void)save;

+ (void) saveAll;

+ (void)deleteSqlistFile;

@end
