//
//  WeiJuAppDelegate.h
//  OnMyWay
//
//  Created by Luo Michael on 11/4/12.
//  Copyright (c) 2012 Luo Michael. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeiJuListDCtrl, WeiJuAppPrefs;

@interface WeiJuAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
/*
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
*/
//customized
@property (strong, nonatomic) UINavigationController *navCtrl;

@property (strong, nonatomic) WeiJuAppPrefs *appPrefs; //存放app的启动参数
@property (retain, nonatomic) EKEventStore *eventStore;

+ (WeiJuAppDelegate *) getSharedInstance;

//this method might be called from RegisterVCtrl.m as well
-(void) setUpMainUSUIWithOptions:(NSDictionary *)launchOptions displayMainUI:(BOOL) display;//for US UI


@end
