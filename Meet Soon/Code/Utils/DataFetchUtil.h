//
//  DataPersisitenceUtil.h
//  WeiJu
//
//  Created by Michael Luo on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface DataFetchUtil : NSObject



-(NSArray *)searchObjectArray:(NSString *) managedObjectName filterString:(NSString *) filterString;

-(NSArray *)searchObjectArray:(NSString *) managedObjectName filter:(NSPredicate *) filter;

-(NSArray *)searchObjectArray:(NSString *)contextName managedObjectName:(NSString *) managedObjectName filterString:(NSString *) filterString;

-(NSArray *)searchObjectArrayOrderby:(NSString *) managedObjectName filterString:(NSString *) filterString orderbyStrArray:(NSArray *) orderbyStrArray;

- (NSManagedObject *)createSavedObject:(NSString *) manageObjectName;

- (NSManagedObject *)createSavedObject:(NSString *)contextName manageObjectName:(NSString *) manageObjectName;

- (void)deleteAll:(NSString *)managedObjectName;

- (void)deleteObjectArray:(NSString *) managedObjectName filterString:(NSString *) filterString;

- (void)deleteObjectArray:(NSString *) managedObjectName filter:(NSPredicate *) predicate;

+ (void)saveButtonsEventRecord:(NSString *)butsCode;

-(void)deleteAllCoreData;
@end
