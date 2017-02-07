//
//  FirstLoginVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FirstLoginVCtrl.h"
#import "RegisterVCtrl.h"
#import "LoginVCtrl.h"
#import "WeiJuListVCtrl.h"
#import "DataFetchUtil.h"
#import "Utils.h"
#import "WeiJuAppPrefs.h"

@interface FirstLoginVCtrl ()

@end

@implementation FirstLoginVCtrl

static FirstLoginVCtrl *currentInstance;

+ (FirstLoginVCtrl *)getCurrentInstance{
    return currentInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    currentInstance = self;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	UILabel *titleL = (UILabel *)[self.view viewWithTag:15];
	titleL.layer.cornerRadius = 4.0;
	titleL.text = [titleL.text stringByAppendingFormat:@"%@) ", currentAppVersion];
	UILabel *tagL = (UILabel *)[self.view viewWithTag:16];
	tagL.layer.cornerRadius = 4.0;
	
//	titleL.backgroundColor=[UIColor blackColor];
//	tagL.backgroundColor=[UIColor blackColor];
//	titleL.textColor=[UIColor whiteColor];
//	tagL.textColor=[UIColor whiteColor];
	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{        
   // [self.navigationController setToolbarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES];
	[Utils hideNavToolBar:YES For:self.navigationController];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (IBAction)pageControl:(id)sender {
    
}

- (IBAction)loginBtnPushed:(id)sender {
    LoginVCtrl *loginVCtrl = [[LoginVCtrl alloc] initWithNibName:@"LoginVCtrl" bundle:nil];
    //[self.navigationController setModalTransitionStyle:UIModalPresentationPageSheet];
	[self.navigationController pushViewController:loginVCtrl animated:YES];
	
	//added Button click Event
    [DataFetchUtil saveButtonsEventRecord:@"66"];  
	
}

- (IBAction)registerBtnPushed:(id)sender {
    [DataFetchUtil saveButtonsEventRecord:@"67"];

    //[self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
	[self.navigationController pushViewController:[[RegisterVCtrl alloc] initWithNibName:@"RegisterVCtrl" bundle:nil]animated:YES];
}

- (IBAction)takeALookBtnPushed:(id)sender 
{
	[DataFetchUtil saveButtonsEventRecord:@"1b"];
    [self.navigationController pushViewController:[[WeiJuListVCtrl alloc] initWithNibName:@"WeiJuListVCtrl" bundle:nil demoOrNot:YES] animated:YES];
}


@end
