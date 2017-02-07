//
//  TermsOfServiceVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 26/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TermsOfServiceVCtrl.h"
#import "RegisterVCtrl.h"
#import "WeiJuNetWorkClient.h"
#import "DataFetchUtil.h"

@implementation TermsOfServiceVCtrl
@synthesize webView;

bool accpectAble = YES;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accpectAble:(bool)accpectAbleTmp
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    accpectAble = accpectAbleTmp;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.title = @"Terms of Service"; //NSLocalizedString(@"TERMSOFSERVICE_TITLE", nil);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed)];
    [self loadWebPageWithString:[@"http://" stringByAppendingFormat:@"%@/Party/html/termsofservice.html",[WeiJuNetWorkClient getIpAddress]]];
    self.navigationController.toolbarHidden=NO;
    if (accpectAble) {
        UIBarButtonItem *decline = [[UIBarButtonItem alloc] initWithTitle:@"Decline" style:UIBarButtonItemStyleBordered target:self action:@selector(declineButtonPressed) ];
        
        UIBarButtonItem *accept = [[UIBarButtonItem alloc] initWithTitle:@"Accept" style:UIBarButtonItemStyleBordered target:self action:@selector(acceptBarButtonPressed) ];
        
        [self setToolbarItems: [ [NSArray alloc] initWithObjects:
                                decline,
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil],
                                accept, nil] ];
    }
}

- (void)backButtonPressed{
    [DataFetchUtil saveButtonsEventRecord:@"1f"];
    self.navigationController.toolbarHidden=YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)declineButtonPressed{
    [DataFetchUtil saveButtonsEventRecord:@"1g"];
    self.navigationController.toolbarHidden=YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)acceptBarButtonPressed{
    [DataFetchUtil saveButtonsEventRecord:@"1h"];
    [self.navigationController popViewControllerAnimated:YES];
    [[RegisterVCtrl getSharedInstance] performSelectorOnMainThread:@selector(verificationUserCode) withObject:nil waitUntilDone:YES];
}
- (void)viewDidUnload
{
    [self setWebView:nil];
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

- (void)loadWebPageWithString:(NSString*)urlString
{
    NSURL *url =[NSURL URLWithString:urlString];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

@end
