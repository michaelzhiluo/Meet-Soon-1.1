//
//  WeiJuAppDelegate.m
//  OnMyWay
//
//  Created by Luo Michael on 11/4/12.
//  Copyright (c) 2012 Luo Michael. All rights reserved.
//

#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "InitCoreData.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuListDCtrl.h"
#import "FriendsListVCtrl.h"
#import "WeiJuNetWorkClient.h"
#import "WeiJuManagedObjectContext.h"
#import "FirstLoginVCtrl.h"
#import "DataFetchUtil.h"
#import "LoginUser.h"
#import "Utils.h"
#import "WeiJuMessage.h"
#import "WeiJuPathShareVCtrl.h"
#import "FriendData.h"
#import "ConvertData.h"
#import "FriendsListDCtrl.h"

@implementation WeiJuAppDelegate

//@synthesize managedObjectContext = _managedObjectContext;
//@synthesize managedObjectModel = _managedObjectModel;
//@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize navCtrl=_navCtrl, window = _window, appPrefs=_appPrefs, eventStore=_eventStore;

static WeiJuAppDelegate *sharedInstance;

+ (WeiJuAppDelegate *) getSharedInstance{
    return sharedInstance;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	/*
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
	*/
	
	sharedInstance = self;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    assert(self.window);
	
    // Override point for customization after application launch.
	//get default setting
    self.appPrefs = [[WeiJuAppPrefs alloc] init];
	[self.appPrefs setSharedInstance:self.appPrefs];
	[self.appPrefs setDemo:NO]; //comment this to enter non demo mode
    
	//note: go live three to-dos:
	//0. change target setting's version
	//1. check logmode to PRODUCTION_MODE
	//2. set ipaddress to amazon
	//3. set the appver and protover properly
	
    //1.Developing mode:NSlog  2.Test Mode:Qlog Open and NSLog close  3.prodctionMode:only qlog
	[self.appPrefs setLogMode:TEST_MODE];
	
	if([self.appPrefs logMode]==PRODUCTION_MODE)
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; //turn off the network indicator
	
	//[UIApplication sharedApplication].idleTimerDisabled = YES; //prevent screen locking
	
    // Let the device know we want to receive push notifications
    //[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	
	//这儿需要判断,此人是否注册过,并且是否记住密码
    if([[self.appPrefs userId] isEqualToString:@"0"] && [self.appPrefs demo]==NO)
	{
        self.navCtrl = [[UINavigationController alloc] initWithRootViewController:[[FirstLoginVCtrl alloc] initWithNibName:@"FirstLoginVCtrl" bundle:nil]];
        
        //self.navCtrl.toolbarHidden=YES;
        //self.navCtrl.navigationBarHidden=YES;
        self.window.rootViewController = self.navCtrl;
        
		//[self.window makeKeyAndVisible];
    }
	else
	{
		//[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(flashScreenDone) userInfo:nil repeats:NO];
		//self.window.rootViewController = [[FlashScreenVCtrl alloc] initWithNibName:@"FlashScreenVCtrl" bundle:nil];
		//[self.window makeKeyAndVisible];
		
		[WeiJuNetWorkClient setScheduleFristEnabled:true];
		
		//[self setUpMainUSUIWithOptions:launchOptions displayMainUI:NO];
		[self setUpMainUSUIWithOptions:launchOptions displayMainUI:YES];
	}
	
	[self.window makeKeyAndVisible];
	
	return YES;
}

-(void) setUpMainUSUIWithOptions:(NSDictionary *)launchOptions displayMainUI:(BOOL) display
{
	//print out the local frienddata
	NSArray *friendDataResult = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:nil];
	FriendData *person;
	for (int i=0; i<MIN(MAX_ATTENDEES, [friendDataResult count]); i++)
	{
		person = (FriendData *)[friendDataResult objectAtIndex:i];
		if([self.appPrefs logMode]!=PRODUCTION_MODE)
			[Utils log:@"Local FD %d/%d: %@ %@ %@ %@ %@", i,[friendDataResult count], person.userId, person.userName, person.userLogin, person.userEmails, person.hide];
		else
			[Utils log:@"Local FD %d/%d: %@ %@", i, [friendDataResult count], person.userId, person.hide];
	}

	//force weijuappprefs to use datafetcher to search/load my frienddata, for used by other classes in non-mainthread, so tha there is no more need to search
	FriendData *myself = [self.appPrefs friendData];
	if (myself!=nil)
		[Utils log:@"Found myself in appdelegate: %@", myself.userId];
	else
		[Utils log:@"Warning: not found myself in appdelegate for id %@", [self.appPrefs userId]];
	
	self.navCtrl = [[UINavigationController alloc] initWithRootViewController:[[WeiJuListVCtrl alloc] initWithNibName:@"WeiJuListVCtrl" bundle:nil demoOrNot:NO]];
	self.navCtrl.toolbarHidden=NO;
	
    // Let the device know we want to receive push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	
    //start NetWorking&NSTimer to get Messages - move it to later
	[[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] startReceive];
    
	// Check if the app was launched in response to the user tapping on a
	// push notification. If so, we add the new message to the data model.
	if (launchOptions != nil)
	{
		NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (dictionary != nil)
		{
			//NSLog(@"Launched from push notification: %@", dictionary);
			[self addMessageFromRemoteNotification:dictionary updateUI:NO];
		}
	}
	
	if(display)
		self.window.rootViewController = self.navCtrl;
	
}

#pragma mark - Push Support
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	//NSLog(@"My token is: %@", deviceToken);
	
	// We have received a new device token. This method is usually called right
	// away after you've registered for push notifications, but there are no
	// guarantees. It could take up to a few seconds (especially if your app
	// hasn’t tried to obtain a device token before, i.e. the very first time it is run) and you should take this
	// into consideration when you design your app. In our case, the user could
	// send a "login" request to the server before we have received the device
	// token. In that case, we silently send an "update" request to the server
	// API once we receive the token.
	
	NSString* oldToken = [self.appPrefs deviceToken];
	
	NSString* newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	//NSLog(@"My token is: %@ %d", newToken, [[UIApplication sharedApplication] enabledRemoteNotificationTypes]);
    [Utils log:@"%s [line:%d] Get token:%@",__FUNCTION__,__LINE__, newToken];

	if (newToken!=nil && [newToken isEqualToString:@""]==NO)
	{
		[self.appPrefs setDeviceToken:newToken];
		
		if (![newToken isEqualToString:oldToken])
			[self.appPrefs setNewDeviceToken:newToken]; //mark for submission
    }
	
    if ( ![[self.appPrefs userId] isEqualToString:@"0"] && ![@"" isEqualToString:[self.appPrefs newDeviceToken]]) //newDeviceToken could be empty if we have succeeded in submitting
	{
        NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
        [paraDic setObject:newToken forKey:@"deviceToken"];
        [[[WeiJuNetWorkClient alloc] init] requestData:@"loginAction.uploadAccountInfo" parameters:paraDic withObject:nil callbackInstance:self callbackMethod:@"changeDeviceTokenDone:"];
    }
}

- (void)changeDeviceTokenDone:(NSDictionary *)dictionary
{
    if ([ConvertData getErrorInfo:dictionary] != nil)
		[self.appPrefs setNewDeviceToken:@""];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [Utils log:@"%s [line:%d] Failed to get token, error:%@, %@",__FUNCTION__,__LINE__, [error userInfo], error];
	//[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_PUSH_TITLE", nil) message:NSLocalizedString(@"NO_PUSH_MSG", nil) noLocalNotif:YES];
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	// This method is invoked when the app is running and a push notification
	// is received. If the app was suspended in the background, it is woken up
	// and this method is invoked as well. We add the new message to the data
	// model and add it to the ChatViewController's table view.
	
	[self addMessageFromRemoteNotification:userInfo updateUI:YES];
}

- (void)addMessageFromRemoteNotification:(NSDictionary*)userInfo updateUI:(BOOL)updateUI
{
	// The JSON payload is already converted into an NSDictionary for us.
	// We are interested in the contents of the alert message.
	
    if([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE)
		[Utils log:@"%s [line:%d] Received notification:%@",__FUNCTION__,__LINE__, userInfo];
	
	if ([@"0" isEqualToString:[self.appPrefs userId]]) //logoff
		return;
	//NSString* alertValue = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
    //[[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] searchMessages];
	
	NSString * messageValue = [[[userInfo valueForKey:@"aps"] valueForKey:@"alert"] valueForKey:@"body"];
    NSArray  * messageArr = [messageValue componentsSeparatedByString:@":"];
    int messageType = [[messageArr objectAtIndex:0] intValue];
    switch (messageType) {
        case 1:{
			//get FriendData,LocationData infomation
            [[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] syncMyData:nil syncUserIds:nil];
        }
        case 2:{
			//get new Message
			//[[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] searchMessages];
        }
        default:{
            
        }
    }
	
	/*
	 This obtains the alert text from the push notification. The JSON payload of our push notifications looks like this:
	 {
	 "aps":
	 {
	 "alert": "SENDER_NAME: MESSAGE_TEXT",
	 "sound": "default"
	 },
	 }
	 */
	
	// The server API formatted the alert text as "sender: message", so we
	// split that up into a sender name and the actual message text.
	//NSMutableArray* parts = [NSMutableArray arrayWithArray:[alertValue componentsSeparatedByString:@": "]];
	//message.senderName = [parts objectAtIndex:0];
	//[parts removeObjectAtIndex:0];
	//message.text = [parts componentsJoinedByString:@": "];
	
	// Add the Message to the data model's list of messages
	//int index = [dataModel addMessage:message];
	
	// If we are called from didFinishLaunchingWithOptions, we should not
	// tell the ChatViewController's table view to insert the new Message.
	// At that point, the table view isn't loaded yet and it gets confused.
	
}

#pragma mark - App States Management
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

	[WeiJuManagedObjectContext quickSave];
    [WeiJuManagedObjectContext saveAll];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
    //check the calendar and reload table if date/events have changed
    if ([WeiJuListVCtrl getSharedInstance] != nil)
	{
        if([WeiJuListVCtrl getSharedInstance].weiJuListDCtrl != nil)
		{
            if([[WeiJuListVCtrl getSharedInstance].weiJuListDCtrl dateHasChanged])
            {
                [[WeiJuListVCtrl getSharedInstance].tableView reloadData];
                [[WeiJuListVCtrl getSharedInstance].weiJuPathShareVCtrls removeAllObjects]; //purge the dict since it is a new day
            }
			
			//may we should also ask dctrl to check google pull-type server cal on new events
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	//called, when first start, or when enter from background into foreground
	[UIApplication sharedApplication].applicationIconBadgeNumber=0;

}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Saves changes in the application's managed object context before the application terminates.
	//[self saveContext];
	
	[[FriendsListDCtrl getSharedInstance] closeAddrBook]; //for remove the access to addressbook in loading table cell
	
    [WeiJuManagedObjectContext saveAll];
}
/*
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OnMyWay" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OnMyWay.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
//         Replace this implementation with code to handle the error appropriately.
//         
//         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
//         
//         Typical reasons for an error here include:
//         * The persistent store is not accessible;
//         * The schema for the persistent store is incompatible with current managed object model.
//         Check the error message to determine what the actual problem was.
//         
//         
//         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
//         
//         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
//         * Simply deleting the existing store:
//         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
//         
//         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
//         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
//         
//         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
        
         
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
*/
@end
