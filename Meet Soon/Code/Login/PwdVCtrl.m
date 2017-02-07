//
//  PwdVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PwdVCtrl.h"
#import "WeiJuNetWorkClient.h"
#import "MBProgressHUD.h"
#import "DataFetchUtil.h"
#import "Utils.h"
#import "ConvertData.h"
#import "FileOperationUtils.h"

@interface PwdVCtrl ()

@end

@implementation PwdVCtrl

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
	self.title = NSLocalizedString(@"PWD_TITLE", nil);
 

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

- (void)viewWillDisappear:(BOOL)animated
{
    [DataFetchUtil saveButtonsEventRecord:@"73"];
    [super viewWillDisappear:animated];
 
}


- (IBAction)submitBtnPushed:(id)sender 
{
    [DataFetchUtil saveButtonsEventRecord:@"74"];
	[((UITextField *)[self.view viewWithTag:10]) resignFirstResponder];
	
	// Show an activity spinner that blocks the whole screen
	MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
	hud.labelText = @"Requesting"; //NSLocalizedString(@"PROGRESS_CREATE", nil);
	
    NSMutableDictionary *paraDic = [NSMutableDictionary dictionary];
    [paraDic setObject:((UITextField *)[self.view viewWithTag:10]).text forKey:@"email"];
    [paraDic setObject:[[[FileOperationUtils alloc] init] getWeiJuCommonMd5:((UITextField *)[self.view viewWithTag:10]).text] forKey:@"token"];
   
    [[[WeiJuNetWorkClient alloc] init] requestDataWithNoToken:@"loginAction.requestForgotPassword" parameters:paraDic withObject:nil callbackInstance:self callbackMethod:@"requestForgotPasswordSucceed:"];
    
}

-(void) requestForgotPasswordSucceed:(NSDictionary*)dictionary
{
	
	[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];

    NSString *errorInfo = nil;
    if([ConvertData getErrorInfo:dictionary] != nil)
	{
        errorInfo = [ConvertData getErrorInfo:dictionary];
    }
    
    if(errorInfo != nil)
	{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Failed!" message:[ConvertData getErrorInfo:dictionary] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
        return;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Succeeded!" message:@"A new temporary password was sent to your sign in email address. Please check your email to retrieve the password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
    }
	
}

@end
