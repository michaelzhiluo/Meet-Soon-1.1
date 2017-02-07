//
//  LoginVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginVCtrl.h"
#import "PwdVCtrl.h"
#import "WeiJuNetWorkClient.h"
#import "DataFetchUtil.h"
#import "LoginUser.h"
#import "MBProgressHUD.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "ConvertData.h"
#import "FileOperationUtils.h"
#import "WeiJuManagedObjectContext.h"
#import "InitCoreData.h"
#import "Utils.h"
#import "FriendData.h"
#import "QLog.h"

@interface LoginVCtrl ()

@end

@implementation LoginVCtrl

static LoginVCtrl *sharedInstance;

+(LoginVCtrl *)getSharedInstance{
    if (sharedInstance == nil) {
        sharedInstance = [[LoginVCtrl alloc] initWithNibName:@"LoginVCtrl" bundle:nil];
    }
    return sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    sharedInstance = self;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.title = NSLocalizedString(@"LOGIN_TITLE", nil);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonPressed)];

	if (![@"" isEqualToString:[WeiJuAppPrefs getSharedInstance].loginName]) {
        [((UITextField *)[self.view viewWithTag:10]) setText:[WeiJuAppPrefs getSharedInstance].loginName];
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
	//[Utils hideNavToolBar:NO For:self.navigationController];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

-(void) cancelBarButtonPressed
{
    [DataFetchUtil saveButtonsEventRecord:@"68"];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)signInBtnPushed:(id)sender 
{
   [DataFetchUtil saveButtonsEventRecord:@"69"];
    [((UITextField *)[self.view viewWithTag:10]) resignFirstResponder];
    [((UITextField *)[self.view viewWithTag:11]) resignFirstResponder];

    NSString *userEmail = ((UITextField *)[self.view viewWithTag:10]).text;
    
	if(userEmail==nil || [userEmail isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign in email is not specified" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		return;
	}
	if(![Utils validateEmail:userEmail])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign in email is not in the right email address format" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		[Utils log:@"Login email input: %@",userEmail];
		return;
	}
    
	// Show an activity spinner that blocks the whole screen
	MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	hud.labelText = NSLocalizedString(@"PROGRESS_LOGIN", nil);

    NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
    [paraDic setObject:userEmail forKey:@"loginName"];
    [paraDic setObject:[FileOperationUtils md5:((UITextField *)[self.view viewWithTag:11]).text] forKey:@"password"];
   
    [paraDic setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs deviceToken] forKey:@"deviceToken"];
    [[[WeiJuNetWorkClient alloc] init] requestDataWithNoToken:@"loginAction.login" parameters:paraDic withObject:((UITextField *)[self.view viewWithTag:10]).text callbackInstance:self callbackMethod:@"signInSucceed:"];

}

-(void) signInSucceed:(NSDictionary*)dictionary
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    NSArray *result = ((NSArray *)[dictionary objectForKey:@"netarray"]);
	//NSLog(@"login callback %@", dictionary);
    NSString *errorInfo = nil;
    if([ConvertData getErrorInfo:dictionary] != nil)
	{
        errorInfo = [ConvertData getErrorInfo:dictionary];
    }
    
    if(errorInfo != nil)
	{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign In Failed" message:errorInfo delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
		[Utils log:@"Login error: %@ %@",((UITextField *)[self.view viewWithTag:10]).text, errorInfo];
        return;
    }
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = @"Contacting server...";
	
    NSDictionary *dictionaryAll = (NSDictionary *)[result objectAtIndex:0];
    NSString *userId = (NSString *)[dictionaryAll objectForKey:@"userId"];
	
	[[WeiJuAppPrefs getSharedInstance] setUserId:userId];
    [[WeiJuAppPrefs getSharedInstance] setLoginName:[ConvertData getWithOjbect:dictionary]];
	
    [[WeiJuNetWorkClient getSharedWeiJuNetWorkClient] syncMyData:[NSMutableDictionary dictionary] netParameters:[NSMutableDictionary dictionary] withObject:nil userEmails:nil syncUserIds:nil initEnabled:YES];
    
    //start NetWorking&NSTimer to get Messages
    //[[WeiJuAppDelegate getSharedInstance] performSelectorOnMainThread:NSSelectorFromString(@"setUpMainUSUI") withObject:nil waitUntilDone:NO];
}

-(void) setUpMainUSUI
{
    @try
	{
		[[WeiJuAppDelegate getSharedInstance] setUpMainUSUIWithOptions:nil displayMainUI:YES];
    }
    @catch(NSException *e){
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, e, [e userInfo]];
    }    
}

-(void)loginFailed:(NSString *)message{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign In Failed" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)pwdBtnPushed:(id)sender 
{
    [DataFetchUtil saveButtonsEventRecord:@"70"];
	[self.navigationController pushViewController:[[PwdVCtrl alloc] initWithNibName:@"PwdVCtrl" bundle:nil] animated:YES];
}

- (IBAction)reportIssue:(id)sender 
{
	[Utils sendEmailToSupport:self];
}

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
