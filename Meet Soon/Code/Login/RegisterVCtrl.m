//
//  RegisterVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RegisterVCtrl.h"
#import "WeiJuNetWorkClient.h"
#import "DataFetchUtil.h"
#import "LoginUser.h"
#import "MBProgressHUD.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "FileOperationUtils.h"
#import "ConvertData.h"
#import "DESUtils.h"
#import "FriendData.h"
#import "WeiJuManagedObjectContext.h"
#import "InitCoreData.h"
#import "Utils.h"
#import "ConvertData.h"
#import "LoginVCtrl.h"
#import "ConvertData.h"
#import "TermsOfServiceVCtrl.h"

@interface RegisterVCtrl ()

@end

@implementation RegisterVCtrl

#define TEXT_FIELD_USERNAME 11
#define TEXT_FIELD_EMAIL 12
#define TEXT_FIELD_PASSWORD 13

@synthesize verificationCode, userId, verificationAlert; //termOfServiceAlert;

static RegisterVCtrl *sharedInstace;

+ (RegisterVCtrl *)getSharedInstance{
    return sharedInstace;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    sharedInstace = self;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.title = @"Register";//NSLocalizedString(@"REGISTER_TITLE", nil);
 	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonPressed)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.verificationAlert = nil;
	//self.termOfServiceAlert = nil;
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

-(void) cancelBarButtonPressed
{
    [DataFetchUtil saveButtonsEventRecord:@"71"];
	[self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)registerBtnPushed:(id)sender 
{
	[self continueToRegister];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

-(void) continueToRegister
{
    [DataFetchUtil saveButtonsEventRecord:@"72"];
    [((UITextField *)[self.view viewWithTag:11]) resignFirstResponder];
    [((UITextField *)[self.view viewWithTag:12]) resignFirstResponder];
    [((UITextField *)[self.view viewWithTag:13]) resignFirstResponder];

	//first check if there is indeed input
	NSString *userName = ((UITextField *)[self.view viewWithTag:TEXT_FIELD_USERNAME]).text;
	if(userName==nil || [userName isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User Name is not specified" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	NSString *userEmail = ((UITextField *)[self.view viewWithTag:TEXT_FIELD_EMAIL]).text;
	if(userEmail==nil || [userEmail isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email is not specified" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		return;
	}
	if(![Utils validateEmail:userEmail])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email is not in the right email address format" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		[Utils log:@"Login email register input: %@",userEmail];
		return;
	}
	NSString *userPasswd = ((UITextField *)[self.view viewWithTag:TEXT_FIELD_PASSWORD]).text;
	if(userPasswd==nil || [userPasswd isEqualToString:@""] || userPasswd.length < 4)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password is not specified properly, and it must be at least 4 digits" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		return;
	}
	[self.navigationController pushViewController:[[TermsOfServiceVCtrl alloc] initWithNibName:@"TermsOfServiceVCtrl" bundle:nil accpectAble:YES] animated:YES];
}

- (void) verificationUserCode{
     //here: send the username, email, passwd and verification code etc. to the server
     FileOperationUtils *fileOperationUtils = [[FileOperationUtils alloc] init];
     NSString *vcode = [fileOperationUtils randomNumber:4];
     
     
     self.verificationCode = vcode;
     NSString *vcodeEn = [DESUtils encryptUseDESDefaultKey:vcode];
     
     // Show an activity spinner that blocks the whole screen
     MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
     hud.labelText = @"Contacting Server";//NSLocalizedString(@"PROGRESS_CREATE", nil);
     
     NSMutableDictionary *dic = [NSMutableDictionary dictionary];
     
     [dic setObject:vcodeEn forKey:@"verificationCode"];
     [dic setObject:[FileOperationUtils md5:[vcodeEn stringByAppendingFormat:@"%@",@"@"]] forKey:@"token"];
     [dic setObject:((UITextField *)[self.view viewWithTag:12]).text forKey:@"relationEmail"];
     
     [[[WeiJuNetWorkClient alloc] init] requestDataWithNoToken:@"loginAction.sendEmailToActiveAccount" parameters:dic withObject:nil callbackInstance:self callbackMethod:@"callBackForSubmittingToServer:"];
}

- (void)callBackForSubmittingToServer:(NSDictionary *)dictionary
{
	//server may reply: email has been used
	[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    NSString *errorInfo = nil;
    if([ConvertData getErrorInfo:dictionary] != nil){
        errorInfo = [ConvertData getErrorInfo:dictionary];
    }
    
    if(errorInfo != nil){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Creating Account Failed" message:errorInfo delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
        [alert show];
        return;
    }
	
	NSArray *result = ((NSArray *)[dictionary objectForKey:@"netarray"]);
    if([result count] <= 0)return;
    NSDictionary *dictionaryAll = (NSDictionary *)[result objectAtIndex:0];
    self.userId = (NSString *)[dictionaryAll objectForKey:@"userId"];
	
    self.verificationAlert = [[UIAlertView alloc] initWithTitle:@"We have sent a verification code to your email. Please retrieve it from your email" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
	
	self.verificationAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[self.verificationAlert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
	[self.verificationAlert textFieldAtIndex:0].placeholder=@"Input verification code here";
	
//    if ([[WeiJuAppPrefs getSharedInstance] logMode]==DEVELOP_MODE){
//        [self.verificationAlert textFieldAtIndex:0].text = self.verificationCode;
//    }
    
	[self.verificationAlert show];
    

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [DataFetchUtil saveButtonsEventRecord:@"75"];
        return;
    }
	if([alertView isEqual:self.verificationAlert])
	{
        [DataFetchUtil saveButtonsEventRecord:@"76"];
		if([[alertView textFieldAtIndex:0].text isEqualToString:self.verificationCode])
		{
			//verified, notifiy the server here????? and download the friendData?
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setObject:((UITextField *)[self.view viewWithTag:TEXT_FIELD_USERNAME]).text forKey:@"userName"];
            [dic setObject:((UITextField *)[self.view viewWithTag:TEXT_FIELD_EMAIL]).text forKey:@"loginName"];
            [dic setObject:[[WeiJuAppDelegate getSharedInstance].appPrefs deviceToken] forKey:@"deviceToken"];
            [dic setObject:[FileOperationUtils md5:((UITextField *)[self.view viewWithTag:TEXT_FIELD_PASSWORD]).text] forKey:@"password"];
            
            [dic setObject:[FileOperationUtils md5:[((UITextField *)[self.view viewWithTag:TEXT_FIELD_EMAIL]).text stringByAppendingFormat:@"%@",@"@"]] forKey:@"token"];
            
            [[[WeiJuNetWorkClient alloc] init] requestDataWithNoToken:@"loginAction.createAccount" parameters:dic withObject:((UITextField *)[self.view viewWithTag:TEXT_FIELD_EMAIL]).text callbackInstance:self callbackMethod:@"createAccountSucceed:"];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            hud.labelText = NSLocalizedString(@"PROGRESS_CREATE", nil);
        }
		else 
		{
            self.verificationAlert = [[UIAlertView alloc] initWithTitle:@"Verification code does not match. Please input again" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
            
            self.verificationAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [self.verificationAlert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
            [self.verificationAlert textFieldAtIndex:0].placeholder=@"Input verification code here";
			[self.verificationAlert show];
		}
	}
	
}

//在Server端创建Account成功后,调用此方法
-(void)createAccountSucceed:(NSDictionary*)dictionary
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
	NSString *errorInfo = [ConvertData getErrorInfo:dictionary];
	if(errorInfo == nil) {
        //switch to the main user interface of tab controller view

        [[WeiJuAppDelegate getSharedInstance].appPrefs setUserId:[ConvertData getValue:dictionary key:@"userId"]];
		[[WeiJuAppPrefs getSharedInstance] setLoginName:[ConvertData getWithOjbect:dictionary]];
		
        @try
        {
            FriendData *me = (FriendData *)[[[DataFetchUtil alloc] init] createSavedObject:@"FriendData"]; 
            me.userLogin = [[WeiJuAppPrefs getSharedInstance] loginName];
            me.userId = [[WeiJuAppPrefs getSharedInstance] userId];
			me.userName = ((UITextField *)[self.view viewWithTag:TEXT_FIELD_USERNAME]).text;
            me.userEmails = [@"" stringByAppendingFormat:@"(%@)",me.userLogin];
            me.hide = @"0";
            [[ConvertData getSharedInstance] initCoreDataDone:@"sync"];
            [WeiJuManagedObjectContext quickSave];
            [[WeiJuAppPrefs getSharedInstance] setIsInitCoreData:false];
            [[LoginVCtrl getSharedInstance] performSelectorOnMainThread:NSSelectorFromString(@"setUpMainUSUI") withObject:nil waitUntilDone:NO];
            
        }
        @catch(NSException *e){
            [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, e, [e userInfo]];
        } 
		
    }else 
	{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Creating Account Failed" message:errorInfo delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
		
		[Utils log:@"Registration error: %@ %@",((UITextField *)[self.view viewWithTag:TEXT_FIELD_EMAIL]).text, errorInfo];
		
		return;
    }
}

- (IBAction)termOfService:(id)sender{
	[DataFetchUtil saveButtonsEventRecord:@"1c"];
    [self.navigationController pushViewController:[[TermsOfServiceVCtrl alloc] initWithNibName:@"TermsOfServiceVCtrl" bundle:nil accpectAble:NO]animated:YES];
}

- (IBAction)reportIssue:(id)sender 
{
	[DataFetchUtil saveButtonsEventRecord:@"1d"];
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
