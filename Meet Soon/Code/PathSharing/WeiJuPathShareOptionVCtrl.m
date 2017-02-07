//
//  WeiJuPathShareOptionVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuPathShareOptionVCtrl.h"
#import "WeiJuPathShareVCtrl.h"
#import "WeiJuAppPrefs.h"
#import "DataFetchUtil.h"

@interface WeiJuPathShareOptionVCtrl ()

@end

@implementation WeiJuPathShareOptionVCtrl

#define TAG_TOOLBAR 14

@synthesize delegate;
@synthesize timerSegCtrl;

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
	self.view.backgroundColor= [UIColor underPageBackgroundColor];
	
	UIToolbar *toolBar = (UIToolbar *)[self.view viewWithTag:TAG_TOOLBAR];
	UIBarButtonItem *curlButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl target:self action:@selector(curlBackBtnPushed:)];
	curlButton.style = UIBarButtonItemStyleDone;
	
	int duration = (int)[[WeiJuAppPrefs getSharedInstance] pathSharingDuration];
	if(duration==600)
		self.timerSegCtrl.selectedSegmentIndex=0;
	else if(duration==1200)
		self.timerSegCtrl.selectedSegmentIndex=1;
	else if(duration==1800)
		self.timerSegCtrl.selectedSegmentIndex=2;
	
	[toolBar setItems:[ [NSArray alloc] initWithObjects:
					   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],
					   curlButton , nil]];
}

- (void)viewDidUnload
{
	[self setTimerSegCtrl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.delegate=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)curlBackBtnPushed:(id)sender 
{
	[self.delegate pageCurlUp];
}


- (IBAction)timerSegCtrlSelected:(id)sender {
	if (self.timerSegCtrl.selectedSegmentIndex==0) {
		[DataFetchUtil saveButtonsEventRecord:@"58"];        
		[[WeiJuAppPrefs getSharedInstance] setPathSharingDuration:600];
	}
	else if (self.timerSegCtrl.selectedSegmentIndex==1) {
        [DataFetchUtil saveButtonsEventRecord:@"59"];        
		[[WeiJuAppPrefs getSharedInstance] setPathSharingDuration:1200];
	}
	else if (self.timerSegCtrl.selectedSegmentIndex==2) {
        [DataFetchUtil saveButtonsEventRecord:@"60"];        
		[[WeiJuAppPrefs getSharedInstance] setPathSharingDuration:1800];
	}
}
@end
