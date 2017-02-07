//
//  SettingsVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsVCtrl.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuListDCtrl.h"
#import "MyAccountVCtrl.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuNetWorkClient.h"
#import "FirstLoginVCtrl.h"
#import "ConvertData.h"
#import "FileOperationUtils.h"
#import "FriendData.h"
#import "DataFetchUtil.h"
#import "WeiJuManagedObjectContext.h"
#import "QLogViewer.h"
#import "AlertOptionVCtrl.h"
#import "Utils.h"
#import "FriendsListDCtrl.h"
#import "TermsOfServiceVCtrl.h"

@interface SettingsVCtrl ()

@end

@implementation SettingsVCtrl

@synthesize tableView=_tableView;
@synthesize logOffAlert=_logOffAlert, upgradeAlert=_upgradeAlert, rateUsAlert=_rateUsAlert;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	self.title = @"Settings";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backBarButtonPressed)];
    //if ([[WeiJuAppPrefs getSharedInstance] logMode]!=PRODUCTION_MODE) {
	//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout"/*NSLocalizedString(@"SETTINGS", nil)*/ style:UIBarButtonItemStyleBordered target:self action:@selector(logOffButtonPushed)];

    //}
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	UIRemoteNotificationType alertType = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
	
	if((alertType & UIRemoteNotificationTypeAlert)==NO)
		[Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_PUSH_TITLE", nil) message:NSLocalizedString(@"NO_PUSH_MSG", nil) noLocalNotif:YES];
	
}

- (void) backBarButtonPressed
{
    [DataFetchUtil saveButtonsEventRecord:@"e"];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.logOffAlert=nil;
	self.upgradeAlert=nil;
	self.rateUsAlert=nil;
}

-(void) viewWillDisappear:(BOOL)animated
{
    //added Button click Event
	[super viewWillDisappear:animated];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return 1;
			break;
		case 1:
			return 2;
			break;
		case 2:
			return 1;
			break;
		case 3:
			return 2;
			break;
		case 4:
			return 2;
			break;
		case 5:
			return 1;
			break;
		default:
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section==5) {
		return [@"Meet Soon v" stringByAppendingFormat:@"%@\n%@\n%@\n%@", currentAppVersion, @"Copyright (C) 2012 Michael Luo", @"All Rights Reserved", @"Patent Pending"];
	}
	else
		return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellIdentifier=@"default";
	UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];;
	
	switch (indexPath.section) 
	{
		case 0:
		{
			cell=[tableView dequeueReusableCellWithIdentifier:@"demooption"];;
			if(cell==nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"demooption"];
				UISwitch *demoSwitch = [[UISwitch alloc] init];
				demoSwitch.frame=CGRectMake(cell.contentView.bounds.size.width - demoSwitch.bounds.size.width-25, (cell.contentView.bounds.size.height - demoSwitch.bounds.size.height)/2, demoSwitch.bounds.size.width, demoSwitch.bounds.size.height);
				if([[WeiJuAppPrefs getSharedInstance] demoEventOnOff])
					demoSwitch.on=YES;
				else 
					demoSwitch.on=NO;
				[demoSwitch addTarget:self action:@selector(demoSwitch:) forControlEvents:UIControlEventValueChanged];
				[cell.contentView addSubview:demoSwitch];
				cell.textLabel.text=@"Show Demo Event";
			}
			break;
		}
		case 1:
		{            
			if(indexPath.row==0)
			{
				if(cell==nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                cell.textLabel.text=@"Change My User Name";
			}
			else if(indexPath.row==1)
			{
                if(cell==nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
				cell.textLabel.text=@"Change Password";
				//cell.detailTextLabel.text=@"Tap to select";
			}
			
			break;
		}
		case 2:
		{
			if(cell==nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			cell.textLabel.text=@"Manage Push and Vibrations";
			break;
		}
		case 3:
		{
			if(indexPath.row==0)
			{
				if(cell==nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                cell.textLabel.text=@"Email Support/Feedback";
			}
			else if(indexPath.row==1)
			{
                if(cell==nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
				cell.textLabel.text=@"Rate us on AppStore";
				//cell.detailTextLabel.text=@"Tap to select";
			}

			
			break;
		}
		case 4:
		{
			if(indexPath.row==0)
			{
				if(cell==nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
				//NSLog(@"Settings: %@ %@ %@ %@",[[WeiJuAppPrefs getSharedInstance] newAppVer], [[WeiJuAppPrefs getSharedInstance] newAppVerData], [[WeiJuAppPrefs getSharedInstance] newProtoVer], [[WeiJuAppPrefs getSharedInstance] newProtoVerData]);
				if ([[Utils getSharedInstance] hasNewVersonFrom:currentAppVersion to:[[WeiJuAppPrefs getSharedInstance] newAppVer]])
					cell.textLabel.text=[@"Upgrade to New Version" stringByAppendingFormat:@" (%@)", [[WeiJuAppPrefs getSharedInstance] newAppVer]];
				else 
				{
					cell.textLabel.text=@"No New Version Available";
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			}
			else if(indexPath.row==1)
			{
                if(cell==nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
				cell.textLabel.text=@"Terms of Service";
			}

			break;
		}
		case 5:
		{
			if(cell==nil)
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			cell.textLabel.text=@"Logout";
			break;
		}
		
	}

	return cell;
}

//某一行被选择
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.section) 
	{
		case 0:
		{
			break;
		}
		case 1:
		{
            
            if(indexPath.row==0)
			{
                //added Button click Event
                [DataFetchUtil saveButtonsEventRecord:@"h"];
				MyAccountVCtrl *myAcct = [[MyAccountVCtrl alloc] initWithNibName:@"MyAccountVCtrl" bundle:nil  changeType:@"changeUserName"];
                myAcct.delegate=self;
                [self.navigationController pushViewController:myAcct animated:YES];
                break;
			}
			else if(indexPath.row==1)
			{
                //added Button click Event
                [DataFetchUtil saveButtonsEventRecord:@"i"];
                MyAccountVCtrl *myAcct = [[MyAccountVCtrl alloc] initWithNibName:@"MyAccountVCtrl" bundle:nil changeType:@"changePassword"];
                myAcct.delegate=self;
                [self.navigationController pushViewController:myAcct animated:YES];
                break;
				//cell.detailTextLabel.text=@"Tap to select";
			}
			
		}
		case 2:
		{
			//added Button click Event
            [DataFetchUtil saveButtonsEventRecord:@"j"];
			AlertOptionVCtrl *alert= [[AlertOptionVCtrl alloc] initWithStyle:UITableViewStyleGrouped];
			[self.navigationController pushViewController:alert animated:YES];
			break;
		}
		case 3:
		{
			if(indexPath.row==0) //contact us via email
			{
				//added Button click Event
				[DataFetchUtil saveButtonsEventRecord:@"k"];
				
				[Utils sendEmailToSupport:self];
			}
			else if(indexPath.row==1) //feedback to customer support
			{
				//added Button click Event
				[DataFetchUtil saveButtonsEventRecord:@"1i"];
				//use the same self.upgradeAlert, since the URL is the same: but what if there is no upgrade info?
				self.rateUsAlert = [[UIAlertView alloc] initWithTitle:@"Go to AppStore to rate our app?" message:nil delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Confirm",nil];
				[self.rateUsAlert show];
			}
			break;
		}
		case 4:
		{
			if(indexPath.row==0)
			{
				//upgrade
				if([[Utils getSharedInstance] hasNewVersonFrom:currentAppVersion to:[[WeiJuAppPrefs getSharedInstance] newAppVer]])
				{
                    [DataFetchUtil saveButtonsEventRecord:@"1j"];
					NSArray *npdArray = [[[WeiJuAppPrefs getSharedInstance] newAppVerData] componentsSeparatedByString:@"|"];
					
					self.upgradeAlert = [[UIAlertView alloc] initWithTitle:@"Go to AppStore to download the latest version?" message:[npdArray objectAtIndex:0] delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Upgrade Now",nil];
					[self.upgradeAlert show];
				}
			}
			else if(indexPath.row==1) //about
			{
                [DataFetchUtil saveButtonsEventRecord:@"1k"];
				[self.navigationController pushViewController:[[TermsOfServiceVCtrl alloc] initWithNibName:@"TermsOfServiceVCtrl" bundle:nil accpectAble:NO]animated:YES];
			}
			break;
		}
		case 5: //logout
		{
            [DataFetchUtil saveButtonsEventRecord:@"l"];
			[self logOffButtonPushed];
			break;
		}
	}
    
}

- (void) logOffButtonPushed
{
	self.logOffAlert = [[UIAlertView alloc] initWithTitle:@"Do you want to log out?" 
												  message:@"Your account information (including meeting history record) will be removed from this iPhone (Calendar events will not be removed, and can still be accessed from the iPhone built-in Calendar app)"
												 delegate:self 
										cancelButtonTitle:@"Dismiss" 
										otherButtonTitles:@"Confirm", nil];
	[self.logOffAlert show];
	
}

- (void) demoSwitch:(id)sender
{
	if(((UISwitch *)sender).on){
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"g"];
		[[WeiJuAppPrefs getSharedInstance] setDemoEventOnOff:YES]; 
    }else {
        //added Button click Event
        [DataFetchUtil saveButtonsEventRecord:@"f"];
        [[WeiJuAppPrefs getSharedInstance] setDemoEventOnOff:NO];	
    }		
	
	[[WeiJuListDCtrl getSharedInstance] reloadDemoEvent:((UISwitch *)sender).on];
}



- (void) changeUserName:(NSString *)name password:(NSString *)pwd newPassword:(NSString *)newPwd
{
    
    NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
    
    //uploadAccountInfo
    if(name != nil)[paraDic setObject:name forKey:@"userName"];
	if(newPwd != nil){
        [paraDic setObject:[FileOperationUtils md5:pwd] forKey:@"password"];
        [paraDic setObject:[FileOperationUtils md5:newPwd] forKey:@"newPassword"];
    }
    [[[WeiJuNetWorkClient alloc] init] requestData:@"loginAction.uploadAccountInfo" parameters:paraDic withObject:name callbackInstance:self callbackMethod:@"uploadAccountCallBak:"];
        
}

- (void) uploadAccountCallBak:(NSDictionary *)dic
{

    if ([ConvertData getErrorInfo:dic] != nil)
	{
		[Utils displaySmartAlertWithTitle:[ConvertData getErrorInfo:dic] message:nil noLocalNotif:YES];
        [[MyAccountVCtrl getSharedInstance] cancel:NO];
    }
	else{
        [[WeiJuAppPrefs getSharedInstance] friendData].userName = [ConvertData getWithOjbect:dic];
        [[MyAccountVCtrl getSharedInstance] cancel:YES];
    }
   
}

- (void) logButtonPushed
{
	QLogViewer *            vc;
    
    vc = [[QLogViewer alloc] init];
    
    [vc presentModallyOn:self animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//add
	if(alertView==self.logOffAlert)
	{
		if(buttonIndex==1)
		{
			[DataFetchUtil saveButtonsEventRecord:@"1o"];
			
			[[[WeiJuNetWorkClient alloc] init] uploadEvent:[[WeiJuAppDelegate getSharedInstance].appPrefs userId]];
			
			//logout
			//[[UIApplication sharedApplication] unregisterForRemoteNotifications]; //can't remove push - re-register would prompt user again, bad UE
			NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
			[paraDic setObject:@"1" forKey:@"isLogout"];//[paraDic setObject:@"NONE" forKey:@"deviceToken"];
			[[[WeiJuNetWorkClient alloc] init] requestData:@"loginAction.uploadAccountInfo" parameters:paraDic withObject:nil callbackInstance:nil callbackMethod:nil];
			
			[[WeiJuListVCtrl getSharedInstance] shutdownAllPVC];
			
			[[WeiJuAppDelegate getSharedInstance].navCtrl popToRootViewControllerAnimated:NO];
			[[WeiJuListVCtrl getSharedInstance].view removeFromSuperview];
			[WeiJuListVCtrl getSharedInstance].view = nil;
			[WeiJuAppDelegate getSharedInstance].navCtrl = [[UINavigationController alloc] initWithRootViewController:[[FirstLoginVCtrl alloc] initWithNibName:@"FirstLoginVCtrl" bundle:nil]];
			[WeiJuAppDelegate getSharedInstance].window.rootViewController = [WeiJuAppDelegate getSharedInstance].navCtrl;
			
			//[self.window makeKeyAndVisible];
			
			[[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] stopReceive];
			[[WeiJuAppPrefs getSharedInstance] resetPrefs];
			
			[[[DataFetchUtil alloc] init] deleteAllCoreData];
			
			[WeiJuManagedObjectContext quickSave];
			[[FriendsListDCtrl getSharedInstance] reset];
			//[WeiJuManagedObjectContext deleteSqlistFile]; //purge the core data
		}else{
            [DataFetchUtil saveButtonsEventRecord:@"1n"];
        }
	}
	else if(alertView==self.upgradeAlert)
	{
        
		if(buttonIndex==1)
		{
            [DataFetchUtil saveButtonsEventRecord:@"1v"];
			NSArray *npdArray = [[[WeiJuAppPrefs getSharedInstance] newAppVerData] componentsSeparatedByString:@"|"];
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[npdArray objectAtIndex:1]]];
		}else{
            [DataFetchUtil saveButtonsEventRecord:@"1u"];
        }
	}
	else if(alertView==self.rateUsAlert)
	{
		if(buttonIndex==1)
		{
            [DataFetchUtil saveButtonsEventRecord:@"1m"];
			NSArray *npdArray = [[[WeiJuAppPrefs getSharedInstance] newAppVerData] componentsSeparatedByString:@"|"];
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[npdArray objectAtIndex:2]]];
		}else{
            [DataFetchUtil saveButtonsEventRecord:@"1l"];
        }
	}
}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	/*
	 enum MFMailComposeResult {
	 MFMailComposeResultCancelled,
	 MFMailComposeResultSaved,
	 MFMailComposeResultSent,
	 MFMailComposeResultFailed
	 };
	 typedef enum MFMailComposeResult MFMailComposeResult;
	 
	 enum MFMailComposeErrorCode {
	 MFMailComposeErrorCodeSaveFailed,
	 MFMailComposeErrorCodeSendFailed
	 };
	 typedef enum MFMailComposeErrorCode MFMailComposeErrorCode;
	 */
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
