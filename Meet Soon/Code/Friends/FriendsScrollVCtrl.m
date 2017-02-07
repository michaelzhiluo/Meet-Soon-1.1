//
//  FriendsScrollVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendsScrollVCtrl.h"
#import "WeiJuParticipant.h"
#import "FriendData.h"
#import "Utils.h"
#import "DataFetchUtil.h"
#import "WeiJuAppPrefs.h"

@interface FriendsScrollVCtrl ()

@end

@implementation FriendsScrollVCtrl

int const FRIEND_SCROLL_LIST_MODE_CONTACT = 0;
int const FRIEND_SCROLL_LIST_MODE_MAP = 1;

//int const FRIEND_SCROLL_LIST_STAUS_ACCEPT = 0;
//int const FRIEND_SCROLL_LIST_STAUS_DECLINE = 1;
//int const FRIEND_SCROLL_LIST_STAUS_UNDECIDED = 2;


#define FRIEND_FRAME_WIDTH 40
//#define FRIEND_FRAME_HEIGTH 42
#define FRIEND_IMAGE_WIDTH 35

#define BADGE_TAG 33
#define IMAGEVIEW_TAG 34
#define NAME_TAG 35

@synthesize delegate=_delegate, containerSize=_containerSize, scrollV=_scrollV, mode=_mode, numberOfFriends=_numberOfFriends, selectedFriend, friendsViews, friendsObjects;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect mode:(int)displayMode friends:(NSArray *)friends callBack:(id) callBackTarget
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.containerSize = rect;
		self.mode=displayMode;
		
		//self.numberOfFriends=friends; //this property will be set when initializing friendsViews
		self.numberOfFriends = 0;
		
		self.friendsViews = [[NSMutableArray alloc] init];
		if(friends!=nil)
			self.friendsObjects = [NSMutableArray arrayWithArray:friends];
		else 
			self.friendsObjects = [[NSMutableArray alloc] init];
		self.selectedFriend=-1;
		
		self.delegate = callBackTarget;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.view.frame = self.containerSize; 
	self.view.autoresizingMask = UIViewAutoresizingNone;//|UIViewAutoresizingFlexibleTopMargin; //cant be UIViewAutoresizingFlexibleTopMargin, otherwise when there is a phone call, this view will not be pushed down by 20 pixels from the top
	
	if(self.mode==FRIEND_SCROLL_LIST_MODE_MAP) //make bar tranparent
	{
		self.view.backgroundColor=[UIColor clearColor]; 
		UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2)];
		UIView *botBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height/2)];
		topBar.backgroundColor=[UIColor blackColor];
		topBar.alpha = 0.5;
		botBar.backgroundColor=[UIColor blackColor];
		botBar.alpha = 0.55;
		[self.view addSubview:topBar];
		[self.view addSubview:botBar];
		
		self.view.layer.borderWidth=1.5;
		
		self.scrollV=[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
		
	}
	else 
	{
		CAGradientLayer *gradient = [CAGradientLayer layer];
		gradient.frame = self.view.bounds;
		gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:(CGFloat)239/255 green:(CGFloat)239/255 blue:(CGFloat)239/255 alpha:1.00] CGColor], (id)[[UIColor colorWithRed:(CGFloat)197/255 green:(CGFloat)199/255 blue:(CGFloat)203/255 alpha:1.00] CGColor], nil];
		[self.view.layer insertSublayer:gradient atIndex:0];
		self.view.layer.borderColor = [[UIColor blackColor] CGColor];
		self.view.layer.borderWidth =0.5;

		self.scrollV=[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width/**3/4*/, self.view.frame.size.height)];
				
		/*
		UIView *info=[[UIView alloc] initWithFrame:CGRectMake(self.scrollV.frame.size.width, 0, self.view.frame.size.width-self.scrollV.frame.size.width, self.view.frame.size.height)];
		info.layer.borderWidth=0.5;
		
		UIImageView *top=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accept-icon.png"]];
		top.frame = CGRectMake(1, 12, top.frame.size.width, top.frame.size.height);
		UILabel *topL = [[UILabel alloc] initWithFrame:CGRectMake(1+top.frame.size.width+1, 12, info.frame.size.width-top.frame.size.width-2, top.frame.size.height)];
		topL.text=@"Registered";
		topL.font=[UIFont systemFontOfSize:12];
		topL.textAlignment=UITextAlignmentCenter;
		topL.textColor=[UIColor whiteColor];
		topL.backgroundColor=[UIColor lightGrayColor];
		[info addSubview:top];
		[info addSubview:topL];
		
		UIImageView *mid=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Question-icon.png"]];
		mid.frame = CGRectMake(1, top.frame.origin.y+top.frame.size.height+2, mid.frame.size.width, mid.frame.size.height);
		UILabel *midL = [[UILabel alloc] initWithFrame:CGRectMake(1+mid.frame.size.width+1, top.frame.origin.y+top.frame.size.height+2, info.frame.size.width-mid.frame.size.width-2, mid.frame.size.height)];
		midL.text=@"Not Yet";
		midL.font=[UIFont systemFontOfSize:12];
		midL.textAlignment=UITextAlignmentCenter;
		midL.textColor=[UIColor whiteColor];
		midL.backgroundColor=[UIColor lightGrayColor];
		[info addSubview:mid];
		[info addSubview:midL];
		
		[self.view addSubview:info];
		*/
	}
	
	self.scrollV.scrollEnabled=YES;
	self.scrollV.clipsToBounds=YES;
		
	self.scrollV.contentSize=CGSizeMake([self.friendsObjects count]*(FRIEND_FRAME_WIDTH+2), self.view.frame.size.height); //2 means 1 pixel on each side
	self.scrollV.backgroundColor=[UIColor clearColor];
	[self.view addSubview:self.scrollV];
    
	for (int i=0; i<[self.friendsObjects count]; i++) {
		[self addFriendView:[self.friendsObjects objectAtIndex:i]];
		//don't call addFriendViewAndObject, since self.friendsObjects has been set up already
	}

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	self.delegate=nil;
	self.scrollV=nil;
	self.friendsViews=nil;
	self.friendsObjects=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) updateFriendList:(NSArray *)newFriendsObjects
{
	
//	self.scrollV.frame = CGRectMake(0, 0, self.view.frame.size.width/**3/4*/, self.view.frame.size.height);
//	
//	[self.friendsViews removeAllObjects];
//	[self.friendsObjects removeAllObjects];
	
	for (int i=[self.friendsObjects count]-1; i>=0; i--) 
	{
		[self removeFriendViewAndObject:[self.friendsObjects objectAtIndex:i]];
	}
	
	self.friendsObjects = [NSMutableArray arrayWithArray:newFriendsObjects];
	
	self.numberOfFriends = 0;
	for (int i=0; i<[self.friendsObjects count]; i++) {
		[self addFriendView:[self.friendsObjects objectAtIndex:i]];
		//don't call addFriendViewAndObject, since self.friendsObjects has been set up already
	}


}

- (void) addFriendViewAndObject:(WeiJuParticipant *)person
{
	[self addFriendView:person];
	[self.friendsObjects addObject:person];
}

- (void) addFriendView:(WeiJuParticipant *)person
{
	CGFloat startX = self.numberOfFriends*(FRIEND_FRAME_WIDTH+2)+2; //2 is the startx for the first frame
	if(startX>self.scrollV.contentSize.width)
		self.scrollV.contentSize = CGSizeMake(startX+FRIEND_FRAME_WIDTH, self.scrollV.contentSize.height);
	
	UIImage *image = person.userImage;
	if(image==nil)
		image = [UIImage imageNamed:@"person_list_none.png"];//[UIImage imageNamed:@"person_none_image_40.png"];
	
	UIView *newFriendView = [self createFriendButton:startX image:image nameLabel:person.displayName];
		
	if(self.mode==FRIEND_SCROLL_LIST_MODE_MAP && person.isRealUser) //set up frame color for real users on the map
	{
		if(person.friendDataUserID!=nil)
		{
			UIColor *frameColor;
			if(person.isSharing)
				frameColor = [UIColor greenColor];
			else 
				frameColor = [UIColor yellowColor];

			newFriendView.layer.borderWidth=2;
			newFriendView.layer.borderColor=[frameColor CGColor];		
		}
		else {
			//dashed border
			CAShapeLayer *shapeLayer = [CAShapeLayer layer];
			CGRect shapeRect = CGRectMake(0.0f, 0.0f, newFriendView.frame.size.width-3, newFriendView.frame.size.height-3);
			[shapeLayer setBounds:shapeRect];
			[shapeLayer setPosition:CGPointMake(newFriendView.frame.size.width/2, newFriendView.frame.size.height/2)];
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
		
			[[newFriendView layer] addSublayer:shapeLayer];
		}
		
	}

	[self.friendsViews addObject:newFriendView];
	
	[self.scrollV addSubview: newFriendView];
	
	self.numberOfFriends++;
}

- (UIView *) createFriendButton:(CGFloat) startX image:(UIImage *)image nameLabel:(NSString *)flname
{
	UIView *result = [[UIButton alloc] initWithFrame:CGRectMake(startX, 2, FRIEND_FRAME_WIDTH, self.view.frame.size.height-4)];
	result.layer.borderWidth=0.5,
	result.layer.cornerRadius=4;
	result.layer.masksToBounds=YES; //for cornerradius
	
	if(self.mode==FRIEND_SCROLL_LIST_MODE_MAP)
	{
		CAGradientLayer *gradient = [CAGradientLayer layer];
		gradient.frame = result.bounds;
		gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:(CGFloat)239/255 green:(CGFloat)239/255 blue:(CGFloat)239/255 alpha:1.00] CGColor], (id)[[UIColor colorWithRed:(CGFloat)197/255 green:(CGFloat)199/255 blue:(CGFloat)203/255 alpha:1.00] CGColor], nil];
		[result.layer insertSublayer:gradient atIndex:0];
	}
	
	UIButton *resultBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	resultBtn.frame = CGRectMake(0, 0, FRIEND_FRAME_WIDTH, self.view.frame.size.height-4);
	resultBtn.tintColor=[UIColor blackColor];
	resultBtn.backgroundColor=[UIColor clearColor];
	
	UIImageView *pic = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:image.size.width/2 topCapHeight:image.size.height/2] ];
	
	pic.layer.masksToBounds=YES; 
    pic.layer.cornerRadius=5.0; 
    pic.layer.borderWidth=1.0; 
    pic.layer.borderColor=[[UIColor lightGrayColor] CGColor]; 
	pic.tag=IMAGEVIEW_TAG;
    
	//pic.frame = CGRectMake((FRIEND_FRAME_WIDTH-FRIEND_IMAGE_WIDTH)/2, 1, FRIEND_IMAGE_WIDTH, FRIEND_IMAGE_WIDTH);
	pic.frame = CGRectMake((FRIEND_FRAME_WIDTH-FRIEND_IMAGE_WIDTH)/2, 2, FRIEND_IMAGE_WIDTH, FRIEND_IMAGE_WIDTH);
	[result addSubview:pic];
	
	//[resultBtn setImage:[image stretchableImageWithLeftCapWidth:image.size.width/2-1 topCapHeight:image.size.height/2-1] forState:UIControlStateNormal];
	//resultBtn.imageEdgeInsets = UIEdgeInsetsMake(-6, 0, 6, 0); 
	
	UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(1, 2+FRIEND_IMAGE_WIDTH+2, FRIEND_FRAME_WIDTH-2, (self.view.frame.size.height-4)-1-FRIEND_IMAGE_WIDTH-1-2)];
	name.textAlignment = UITextAlignmentCenter;
	name.font = [UIFont boldSystemFontOfSize:11];
	name.text = flname;
	//name.layer.borderWidth=1.0;
	name.backgroundColor=[UIColor clearColor];
	name.tag = NAME_TAG;
	[resultBtn addSubview:name];

	//badge button
	UIButton *badge = [UIButton buttonWithType:UIButtonTypeCustom];
	[badge setBackgroundImage:[[UIImage imageNamed:@"UIButtonBarBadge.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:11] forState:UIControlStateNormal];
	badge.hidden=YES;
	badge.tag=BADGE_TAG;
	badge.userInteractionEnabled=NO;
	badge.frame = CGRectMake(resultBtn.frame.size.width-21, -1, 22, 23);
	badge.titleLabel.font=[UIFont boldSystemFontOfSize:10];
	badge.titleEdgeInsets = UIEdgeInsetsMake(-3, 0, 3, 0);
	[badge setTitle:@"1" forState:UIControlStateNormal];
	[resultBtn addSubview:badge];

	
//	[resultBtn setTitle:flname forState:UIControlStateNormal];
//	[resultBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//	resultBtn.titleLabel.font = [UIFont systemFontOfSize:12];
//	resultBtn.titleEdgeInsets = UIEdgeInsetsMake(20, -30, -20, 6); 
//	NSLog(@"%@", resultBtn.titleLabel);
	
	[resultBtn addTarget:self action:@selector(userSelected:) forControlEvents:UIControlEventTouchUpInside];
	
	/* //勿删,以后会用到
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userLongPressed:)];
	[resultBtn addGestureRecognizer:longPress];
	*/
	
	[result addSubview:resultBtn];
	
	return  result;				  
}

- (void) removeFriendViewAndObject:(WeiJuParticipant *)person
{
	int index = [self.friendsObjects indexOfObject:person];
	
	[(UIView *)[self.friendsViews objectAtIndex:index] removeFromSuperview];
	
	[self.friendsObjects removeObjectAtIndex:index];
	[self.friendsViews removeObjectAtIndex:index];
	
	self.numberOfFriends--;
	
	if(self.selectedFriend>self.numberOfFriends-1)
		self.selectedFriend = -1;
	
	for (int i=index; i<self.numberOfFriends; i++) 
	{
		[Utils shiftView:[self.friendsViews objectAtIndex:i] changeInX:-FRIEND_FRAME_WIDTH-2 changeInY:0 changeInWidth:0 changeInHeight:0];
	}
	
	self.scrollV.contentSize = CGSizeMake(MAX(self.view.frame.size.width, self.numberOfFriends*(FRIEND_FRAME_WIDTH+2)), self.scrollV.contentSize.height);
}

- (void) userSelected:(id)sender
{
	int index = [self.friendsViews indexOfObject:[sender superview]];
	
	if(index!=NSNotFound)
		[self.delegate friendSelected:[self.friendsObjects objectAtIndex:index]];
	
}

- (void) userLongPressed:(UIGestureRecognizer *)longPress
{
	//NSLog(@"userLongPressed: %@", longPress);
	if(longPress.state==UIGestureRecognizerStateBegan)
	{
		int index = [self.friendsViews indexOfObject:[longPress.view superview]];
		
		if(index!=NSNotFound)
			[self.delegate friendLongPressed:[self.friendsObjects objectAtIndex:index]];
	}
}

//add a small icom to the top right corner of the frame
- (void) setIconFor:(WeiJuParticipant *)person status:(int)mode
{
	UIImage *statusIcon;
	/* //work on this later
	switch (mode) {
		case FRIEND_SCROLL_LIST_STAUS_ACCEPT:
			statusIcon = [UIImage imageNamed:@"accept-icon.png"];
			break;
		case FRIEND_SCROLL_LIST_STAUS_DECLINE:
			statusIcon = [UIImage imageNamed:@"decline-icon.png"];
			break;
		case FRIEND_SCROLL_LIST_STAUS_UNDECIDED:
			statusIcon = [UIImage imageNamed:@"Question-icon.png"];
			break;
		default:
			break;
	}
	*/
	int index = -1;
	index = [self.friendsObjects indexOfObject:person];

	if(index!=-1)
	{
		UIView *targetBtn = (UIButton *)[self.friendsViews objectAtIndex:index];		
		UIImageView *icon = (UIImageView *)[targetBtn viewWithTag:33];
		if(icon==nil) //first time
		{
			icon= [[UIImageView alloc] initWithImage:statusIcon];
			icon.frame=CGRectMake(targetBtn.frame.size.width-icon.bounds.size.width, 0, icon.bounds.size.width, icon.bounds.size.height);
			icon.tag=33;
			[targetBtn addSubview:icon];
			
		}
		else { //a previous icon already added
			icon.image=statusIcon;
		}
	}
}

//set the color of the frame
- (void) setColorFor:(WeiJuParticipant *)person color:(UIColor *)frameColor exclusive:(BOOL) yesOrNo
{
	UIView * btn;
	
	//remove the previous selection first
	if(yesOrNo && self.selectedFriend!=-1 && self.selectedFriend<self.numberOfFriends)
	{
		btn = (UIView *)[self.friendsViews objectAtIndex:self.selectedFriend];
		btn.layer.borderWidth=0.5;
		btn.layer.borderColor=[[UIColor blackColor] CGColor]; //restore the black color
	}
	
	int index = -1;
	index = [self.friendsObjects indexOfObject:person];
	self.selectedFriend = index;

	if(index!=-1)
	{
		btn = (UIView *)[self.friendsViews objectAtIndex:index];
		
		btn.layer.borderWidth=2;
		btn.layer.borderColor=[frameColor CGColor];	
		
		NSArray *layers = btn.layer.sublayers;
		for (int i=0; i<[layers count]; i++) 
		{
			CALayer *layer = [layers objectAtIndex:i];
			if ([layer isKindOfClass:[CAShapeLayer class]]) 
			{
				[layer removeFromSuperlayer];
				break;
			}
		}
	}
}

-(void) setBadgeForFriend:(WeiJuParticipant *)person
{
	int index = [self.friendsObjects indexOfObject:person];
	
	if(index!=-1)
	{
		UIView *btn = (UIView *)[self.friendsViews objectAtIndex:index];
		
		UIButton *badge = (UIButton *)[btn viewWithTag:BADGE_TAG];
		
		if(person.newMsg<=0)
		{
			badge.hidden=YES;
		}
		else if(person.newMsg<9)
		{
			[badge setTitle:[NSString stringWithFormat:@"%d", person.newMsg] forState:UIControlStateNormal];
			badge.hidden=NO;
		}
		else {
			[badge setTitle:@"N" forState:UIControlStateNormal];
			badge.hidden=NO;
		}
	}
}

-(void) setImageForFriend:(WeiJuParticipant *)person
{
	int index = [self.friendsObjects indexOfObject:person];
	
	if(index!=-1 && person.userImage!=nil)
	{
		UIView *btn = (UIView *)[self.friendsViews objectAtIndex:index];
		
		UIImageView *head = (UIImageView *)[btn viewWithTag:IMAGEVIEW_TAG];
		
		head.image = [person.userImage stretchableImageWithLeftCapWidth:person.userImage.size.width/2 topCapHeight:person.userImage.size.height/2];
	}
}

-(void) setNameForFriend:(WeiJuParticipant *)person
{
	int index = [self.friendsObjects indexOfObject:person];
	
	if(index!=-1 && person.displayName!=nil)
	{
		UIView *btn = (UIView *)[self.friendsViews objectAtIndex:index];
		
		UILabel *name = (UILabel *)[btn viewWithTag:NAME_TAG];
		
		name.text = person.displayName;
	}
}
@end
