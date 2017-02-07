//
//  MyAccountVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 9/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyAccountVCtrl.h"
#import "WeiJuAppPrefs.h"
#import "SettingsVCtrl.h"
#import "FriendData.h"
#import "MBProgressHUD.h"
#import "DataFetchUtil.h"

@interface MyAccountVCtrl ()

@end

@implementation MyAccountVCtrl

@synthesize delegate=_delegate;
@synthesize userNameTF = _userNameTF;
@synthesize oldPwdTF = _oldPwdTF;
@synthesize pwdTF1 = _pwdTF1;
@synthesize pwdTF2 = _pwdTF2;

NSString *changeType;

static MyAccountVCtrl *sharedInstance;

+(MyAccountVCtrl *)getSharedInstance{
    return sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil changeType:(NSString *)changeTypeTemp
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        changeType = changeTypeTemp;
    }
    sharedInstance = self;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	//self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
}

- (void)viewDidUnload
{
	[self setUserNameTF:nil];
	[self setOldPwdTF:nil];

	[self setPwdTF1:nil];
	[self setPwdTF2:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([@"changeUserName" isEqualToString:changeType]){
		self.title=@"Change User Name";
        [self.oldPwdTF setHidden:YES];
        [self.pwdTF1 setHidden:YES];
        [self.pwdTF2 setHidden:YES];
        self.userNameTF.placeholder = [[WeiJuAppPrefs getSharedInstance] friendData].userName;
    }
    if([@"changePassword" isEqualToString:changeType]){
		self.title=@"Change Password";
        [self.userNameTF setHidden:YES];
    }         
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


- (void) done
{
	if([@"changeUserName" isEqualToString:changeType]){
        [DataFetchUtil saveButtonsEventRecord:@"78"];
    }else {
        [DataFetchUtil saveButtonsEventRecord:@"80"];
    }
	if([@"changeUserName" isEqualToString:changeType]){
        [self.userNameTF resignFirstResponder];
//        if(self.oldPwdTF.text==nil||[self.oldPwdTF.text isEqualToString:@""])
//        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Old password field is empty" message:@"You need to input existing password to make changes to user name or password" delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
//            [alert show];
//            return;
//        }
        if(self.userNameTF.text==nil||[self.userNameTF.text isEqualToString:@""])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User Name can not be empty" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
            [alert show];
            return;
        }
        if (![self.userNameTF.text isEqualToString:[[WeiJuAppPrefs getSharedInstance] friendData].userName]) {
            //修改用户名
            [self.delegate changeUserName:self.userNameTF.text password:nil newPassword:nil ];

        }
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.labelText = @"Changing User Name..."; //NSLocalizedString(@"Changing User Name...", nil);
    }
    if([@"changePassword" isEqualToString:changeType]){
        [self.oldPwdTF resignFirstResponder];
        [self.pwdTF1 resignFirstResponder];
        [self.pwdTF2 resignFirstResponder];
        if(self.oldPwdTF.text==nil||[self.oldPwdTF.text isEqualToString:@""])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Old password field is empty" message:@"You need to input existing password to make changes to user name or password" delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
            [alert show];
            return;
        }
        //修改密码
		if(![self.pwdTF1.text isEqualToString:self.pwdTF2.text])
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New passwords do not match each other" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
			[alert show];
			return;
		}
        if([self.oldPwdTF.text isEqualToString:self.pwdTF2.text])
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New password can not be the same as the old password" message:nil delegate:self cancelButtonTitle:@"Input Again" otherButtonTitles:nil];
			[alert show];
			return;
		}
		
        [self.delegate changeUserName:nil password:self.oldPwdTF.text newPassword:self.pwdTF1.text];
		
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
		
        hud.labelText = @"Changing Password..."; //NSLocalizedString(@"Changing Password...", nil);
    }      
	
    
}

- (void) cancel
{
    if([@"changeUserName" isEqualToString:changeType]){
        [DataFetchUtil saveButtonsEventRecord:@"77"];
    }else {
         [DataFetchUtil saveButtonsEventRecord:@"79"];
    }
   [self.navigationController popViewControllerAnimated:YES];
}

- (void) cancel:(BOOL)isSuccess
{
    
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
	
    if (isSuccess) 
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Change is completed!" message:nil delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
        [self.navigationController popViewControllerAnimated:YES];
    }
	else 
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Change failed!" message:@"If the error persists, please tap \"Email Support\" in the Setting screen" delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
		[alert show];
	}
}

@end
