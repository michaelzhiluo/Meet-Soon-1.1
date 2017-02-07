//
//  PathShareHelperVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PathShareHelperVCtrl.h"
#import "Utils.h"
#import "DataFetchUtil.h"

@interface PathShareHelperVCtrl ()

@end

@implementation PathShareHelperVCtrl
@synthesize userBarHelpView;
@synthesize toolBarHelpView;

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
	
	self.title = @"Tips";
	self.view.backgroundColor= [UIColor underPageBackgroundColor];
	
	UIView *greenBtn = [self createFriendButton:CGPointMake(22, 165) image:[UIImage imageNamed:@"person_list_none.png"] nameLabel:@"F.Last"];
	greenBtn.layer.borderWidth=2;
	greenBtn.layer.borderColor=[[UIColor greenColor] CGColor];		

	UIView *yellowBtn = [self createFriendButton:CGPointMake(260, 97) image:[UIImage imageNamed:@"person_list_none.png"] nameLabel:@"F.Last"];
	yellowBtn.layer.borderWidth=2;
	yellowBtn.layer.borderColor=[[UIColor yellowColor] CGColor];		

	UIView *blueBtn = [self createFriendButton:CGPointMake(22, 29) image:[UIImage imageNamed:@"person_list_none.png"] nameLabel:@"F.Last"];
	CAShapeLayer *shapeLayer = [CAShapeLayer layer];
	CGRect shapeRect = CGRectMake(0.0f, 0.0f, blueBtn.frame.size.width-3, blueBtn.frame.size.height-3);
	[shapeLayer setBounds:shapeRect];
	[shapeLayer setPosition:CGPointMake(blueBtn.frame.size.width/2, blueBtn.frame.size.height/2)];
	[shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
	[shapeLayer setStrokeColor:[[UIColor darkGrayColor] CGColor]];
	[shapeLayer setLineWidth:2.0f];
	[shapeLayer setLineJoin:kCALineJoinRound];
	[shapeLayer setLineDashPattern:
	 [NSArray arrayWithObjects:[NSNumber numberWithInt:3], 
	  [NSNumber numberWithInt:3], 
	  nil]];
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:shapeRect cornerRadius:4.0];
	[shapeLayer setPath:path.CGPath];	
	[[blueBtn layer] addSublayer:shapeLayer];
	
	[self.userBarHelpView addSubview:greenBtn];
	[self.userBarHelpView addSubview:yellowBtn];
	[self.userBarHelpView addSubview:blueBtn];
	
	self.userBarHelpView.layer.cornerRadius=4;
	
	self.toolBarHelpView.layer.cornerRadius=4;
}

- (void)viewDidUnload
{
	[self setUserBarHelpView:nil];
	[self setToolBarHelpView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[Utils hideNavToolBar:YES For:self.navigationController];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [DataFetchUtil saveButtonsEventRecord:@"56"]; 
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIView *) createFriendButton:(CGPoint)startCoord image:(UIImage *)image nameLabel:(NSString *)flname
{
	UIView *result = [[UIButton alloc] initWithFrame:CGRectMake(startCoord.x, startCoord.y, 40, 50)];
	result.layer.borderWidth=0.5,
	result.layer.cornerRadius=4;
	result.layer.masksToBounds=YES; //for cornerradius
	
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = result.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:(CGFloat)239/255 green:(CGFloat)239/255 blue:(CGFloat)239/255 alpha:1.00] CGColor], (id)[[UIColor colorWithRed:(CGFloat)197/255 green:(CGFloat)199/255 blue:(CGFloat)203/255 alpha:1.00] CGColor], nil];
	[result.layer insertSublayer:gradient atIndex:0];
	
	UIButton *resultBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	resultBtn.frame = CGRectMake(0, 0, 40, 50);
	resultBtn.tintColor=[UIColor blackColor];
	
	UIImageView *pic = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:image.size.width/2 topCapHeight:image.size.height/2] ];
	
	pic.layer.masksToBounds=YES; 
    pic.layer.cornerRadius=5.0; 
    pic.layer.borderWidth=1.0; 
    pic.layer.borderColor=[[UIColor lightGrayColor] CGColor]; 
    
	pic.frame = CGRectMake((40-35)/2, 2, 35, 35);
	[result addSubview:pic];
	
	UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(1, 2+35, 40-2, 50-1-35-1-2)];
	name.textAlignment = UITextAlignmentCenter;
	name.font = [UIFont boldSystemFontOfSize:11];
	name.text = flname;
	//name.layer.borderWidth=1.0;
	name.backgroundColor=[UIColor clearColor];
	
	[resultBtn addSubview:name];
		
	[result addSubview:resultBtn];
	
	return  result;				  
}

@end
