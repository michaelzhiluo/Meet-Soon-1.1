//
//  RegisterVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RegisterVerifyVCtrl.h"
#import "WeiJuNetWorkClient.h"
#import "DataFetchUtil.h"
#import "LoginUser.h"
#import "MBProgressHUD.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "FileOperationUtils.h"
#import "ConvertData.h"
#import "DESUtils.h"
#import "Utils.h"

@interface RegisterVerifyVCtrl ()

@end

@implementation RegisterVerifyVCtrl

#define TEXT_FIELD_USERNAME 11
#define TEXT_FIELD_EMAIL 12
#define TEXT_FIELD_PASSWORD 13

@synthesize verificationCode, userId, verificationAlert;

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
	self.title = @"RegisterVerification";//NSLocalizedString(@"REGISTER_TITLE", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonPressed)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) cancelBarButtonPressed
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)registerVerifyBtnPushed:(id)sender 
{
    //[((UITextField *)[self.view viewWithTag:11]) resignFirstResponder];
    //[((UITextField *)[self.view viewWithTag:12]) resignFirstResponder];
    //[((UITextField *)[self.view viewWithTag:13]) resignFirstResponder];

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
	NSString *userPasswd = ((UITextField *)[self.view viewWithTag:TEXT_FIELD_PASSWORD]).text;
	if(userPasswd==nil || [userPasswd isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password is not specified" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	//here: send the username, email, passwd and verification code etc. to the server
    FileOperationUtils *fileOperationUtils = [[FileOperationUtils alloc] init];
    NSString *vcode = [fileOperationUtils randomNumber:4];


	self.verificationCode = vcode;
	NSString *vcodeEn = [DESUtils encryptUseDESDefaultKey:vcode];
	
	// Show an activity spinner that blocks the whole screen
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	hud.labelText = @"Verifying"; //NSLocalizedString(@"PROGRESS_CREATE", nil);
	
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    [dic setObject:vcodeEn forKey:@"verificationCode"];
    [dic setObject:[FileOperationUtils md5:[vcodeEn stringByAppendingFormat:@"%@",@"@"]] forKey:@"token"];
    [dic setObject:((UITextField *)[self.view viewWithTag:12]).text forKey:@"relationEmail"];
    
    
    [[[WeiJuNetWorkClient alloc] init] requestData:@"loginAction.sendEmailToActiveAccount" parameters:dic withObject:nil callbackInstance:self callbackMethod:@"callBackForSubmittingToServer:"];
                              
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Account Failed" message:errorInfo delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
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
	
	[self.verificationAlert show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if([alertView isEqual:self.verificationAlert])
	{
		if([[alertView textFieldAtIndex:0].text isEqualToString:self.verificationCode])
		{
			//verified, notifiy the server here????? and download the friendData?
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setObject:((UITextField *)[self.view viewWithTag:12]).text forKey:@"loginName"];
            [dic setObject:[FileOperationUtils md5:((UITextField *)[self.view viewWithTag:13]).text] forKey:@"password"];
            
            [dic setObject:[FileOperationUtils md5:[((UITextField *)[self.view viewWithTag:12]).text stringByAppendingFormat:@"%@",@"@"]] forKey:@"token"];
            
            [[[WeiJuNetWorkClient alloc] init] requestData:@"loginAction.createAccount" parameters:dic withObject:nil callbackInstance:self callbackMethod:@"createAccountSucceed:"];
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

     if([ConvertData getErrorInfo:dictionary] == nil)
	 {
        //switch to the main user interface of tab controller view
        // NSLog(@"%@",[ConvertData getValue:dictionary key:@"userId"]);
        [[WeiJuAppDelegate getSharedInstance].appPrefs setUserId:[ConvertData getValue:dictionary key:@"userId"]];
        
        @try
        {
            //switch to the main user interface of tab controller view
            [[WeiJuAppDelegate getSharedInstance]  setUpMainUSUIWithOptions:nil displayMainUI:YES];
        }
        @catch(NSException *e){
            [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [e userInfo], [e reason]];
        }

    }
	else
		[Utils displaySmartAlertWithTitle:[ConvertData getErrorInfo:dictionary] message:nil noLocalNotif:YES];
}


@end
