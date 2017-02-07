//
//  WeiJuCell.m
//  WeiJu
//
//  Created by Michael Luo on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeiJuCell.h"
#import "CalEventVCtrl.h"
#import "Utils.h"

@implementation WeiJuCell

#define CELL_CONTENT_CONTAINER 10
#define CELL_BADGE_LABEL 62
#define CELL_SHARE_BTN 63
#define CELL_COLOR_BTN 64

const int CAL_DAYVIEW_EVENT_WIDTH = 278; //278+1+1=280, is the content container size
const int CAL_DAYVIEW_EVENT_HEIGHT = 50;//50+1+1=52, is the content container height
const int CAL_DAYVIEW_EVENT_LEFTMARGIN = 70;

//const int CELL_DISPLAY_MODE_EVENT = 0;
//const int CELL_DISPLAY_MODE_SHARE = 1;

@synthesize delegate=_delegate;
@synthesize calEventVCtrl=_calEventVCtrl;
@synthesize progressDescription, progressView, progressText;
@synthesize displayMode=_displayMode; //0-normal mode, will show event view and buttons; 1-will show the location control subview

@synthesize shapeLayer=_shapeLayer; //for dashed line drawing

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id) initWithDelegate:(id)target
{    
    NSArray*    topLevelObjs = nil;
    topLevelObjs = [[NSBundle mainBundle] loadNibNamed:@"WeiJuCell" owner:self options:nil];
    
    if (topLevelObjs == nil)
    {
        [Utils log:@"%s [line:%d] Error! Could not load WeiJuCell Nib file.\n",__FUNCTION__,__LINE__];
        return nil;
    }
    
    self = [topLevelObjs objectAtIndex:0];
    
    self.delegate=target;
	self.displayMode=CAL_EVENT_MODE_STATIC;
    
    //测试设置颜色和形状
	/*
	UILabel *badge = (UILabel *)[self viewWithTag:CELL_BADGE_LABEL];
	badge.layer.cornerRadius = badge.bounds.size.height/2;
	//badge.layer.masksToBounds = YES;
	badge.layer.borderWidth = 2.2;
	badge.layer.borderColor = [[UIColor whiteColor] CGColor];
	badge.textColor = [UIColor whiteColor];
	badge.font = [UIFont boldSystemFontOfSize:10];
	badge.backgroundColor = [UIColor redColor]; 
	badge.textAlignment = UITextAlignmentCenter;
	//badge.text = [NSString stringWithFormat: @"%d", 5];
	badge.hidden=YES;
    */
	UIButton *badge = (UIButton *)[self viewWithTag:CELL_BADGE_LABEL];
	[badge setBackgroundImage:[[UIImage imageNamed:@"UIButtonBarBadge.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:11] forState:UIControlStateNormal];
	[badge setTitle:@"1" forState:UIControlStateNormal];
	badge.hidden=YES;
	
    UIButton *btn;
    btn = (UIButton *)[self viewWithTag:CELL_SHARE_BTN];
	//[btn setBackgroundImage:[[UIImage imageNamed:@"gradient-grey.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateNormal];
	[btn setImage:[UIImage imageNamed:@"map-pin-blue.png"] forState:UIControlStateNormal];
	//[Utils initCustomGradientButton:btn title:nil image:@"map-pin-blue.png" gradientStart:[UIColor lightTextColor] gradientEnd:[UIColor grayColor] cornerRadius:4 borderWidth:0.5];
	//[Utils initCustomGradientButton:btn title:nil image:@"sharehand.png" gradientStart:[UIColor lightTextColor] gradientEnd:[UIColor grayColor] cornerRadius:4 borderWidth:0.5];
    //btn.layer.cornerRadius = 4;
    //btn.layer.borderWidth = 1.0;
	btn.hidden=YES;
    	
	self.calEventVCtrl = [[CalEventVCtrl alloc] initWithNibName:@"CalEventVCtrl" bundle:nil rect:CGRectMake(1, 1, CAL_DAYVIEW_EVENT_WIDTH, CAL_DAYVIEW_EVENT_HEIGHT) displayMode:CAL_EVENT_MODE_STATIC];
	
	[[self viewWithTag:CELL_CONTENT_CONTAINER] addSubview:self.calEventVCtrl.view];
	
    return self;
}

- (IBAction)notifBtnPushed:(id)sender {
	[self.delegate notifBtnPushed:self];
}

- (IBAction)shareBtnPushed:(id)sender {
	//if(self.progressView!=nil)
	[self.delegate shareBtnPushed:self];
}

- (void) setSubject:(NSString *)subj place:(NSString *)place startTime:(NSDate *)time //called by weijulistv to setup view's value
{
	[self.calEventVCtrl setSubject:subj place:place startTime:time];
}

- (void) toggleMapMode:(BOOL)yesOrNo center:(CLLocationCoordinate2D)centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters annotation:(id < MKAnnotation >)initialAnnotation //crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations
{
	if(yesOrNo)
		self.displayMode = CAL_EVENT_MODE_MAP;
	else 
		self.displayMode = CAL_EVENT_MODE_STATIC;
	
	[self.calEventVCtrl toggleMapMode:yesOrNo center:centerCoordinate latDistance:latitudinalMeters longDistance:longitudinalMeters annotation:initialAnnotation ]; // crumbs:initialCrumbs annotations:initialAnnotations];
}

- (void) ensureToShowEventContent //called to ensure the content view is dispayed/not hidden due to map animation stopped in the middle
{
	[self.calEventVCtrl ensureToShowEventContent];

}

- (void) setAcceptanceStatusBoundary:(BOOL) accepted
{
	UIView *eventContainer = [self contentView];//[self viewWithTag:CELL_CONTENT_CONTAINER];
//	if(accepted)
//	{
//		eventContainer.layer.cornerRadius=4.0;
//		eventContainer.layer.borderWidth=0.0;
//		eventContainer.layer.borderColor=[[UIColor clearColor] CGColor];
//	}
//	else {
//		eventContainer.layer.cornerRadius=4.0;
//		eventContainer.layer.borderWidth=3.0;
//		eventContainer.layer.borderColor=[[UIColor groupTableViewBackgroundColor] CGColor];
//	}
	
	if(accepted==NO)
	{
		if(self.shapeLayer==nil)
		{
			self.shapeLayer = [CAShapeLayer layer];
			CGRect shapeRect = CGRectMake(0.0f, 0.0f, eventContainer.frame.size.width-4, eventContainer.frame.size.height-4);
			[self.shapeLayer setBounds:shapeRect];
			[self.shapeLayer setPosition:CGPointMake(eventContainer.frame.size.width/2, eventContainer.frame.size.height/2)];
			[self.shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
			[self.shapeLayer setStrokeColor:[[UIColor lightGrayColor] CGColor]];
			[self.shapeLayer setLineWidth:2.0f];
			[self.shapeLayer setLineJoin:kCALineJoinRound];
			[self.shapeLayer setLineDashPattern:
			[NSArray arrayWithObjects:[NSNumber numberWithInt:8], 
			  [NSNumber numberWithInt:2], 
			  nil]];
			UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:shapeRect cornerRadius:6.0];
			[self.shapeLayer setPath:path.CGPath];
		}
		[[self layer] addSublayer:self.shapeLayer];

	}
	else {
		if(self.shapeLayer!=nil)
			[self.shapeLayer removeFromSuperlayer];
	}
}

- (void) prepareForReuse
{
	[super prepareForReuse];
	if(self.shapeLayer!=nil)
		[self.shapeLayer removeFromSuperlayer];
	[self setBadge:-1]; //remove the red dot
	[self setStrike:NO];
	
	//[self viewWithTag:CELL_COLOR_BTN].backgroundColor = [UIColor clearColor];
	
	//照说在weijucell里面的prepareforreuse就会把map和动画关闭;但是这样做的话,有些cell会是blank,tap之后才会显示标题
	[self toggleMapMode:NO center:CLLocationCoordinate2DMake(-300,-300) latDistance:0 longDistance:0 annotation:nil];// crumbs:nil annotations:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) showProgressView:(float)prog duration:(int)total
{
	if(self.progressView==nil)
	{
		self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(CAL_DAYVIEW_EVENT_LEFTMARGIN, CAL_DAYVIEW_EVENT_HEIGHT+(21-9)/2+1, CAL_DAYVIEW_EVENT_WIDTH-CAL_DAYVIEW_EVENT_LEFTMARGIN, 21)];
		
		self.progressText = [[UILabel alloc] initWithFrame:CGRectMake(CAL_DAYVIEW_EVENT_LEFTMARGIN+self.progressView.frame.size.width, CAL_DAYVIEW_EVENT_HEIGHT, self.frame.size.width- CAL_DAYVIEW_EVENT_WIDTH, 21)];
		self.progressText.textAlignment=UITextAlignmentRight;
		self.progressText.font=[UIFont systemFontOfSize:12];
		/*
		self.progressDescription = [[UILabel alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x-70-1, CAL_DAYVIEW_EVENT_HEIGHT, 70, 21)];
		self.progressDescription.textAlignment=UITextAlignmentRight;
		self.progressDescription.font=[UIFont systemFontOfSize:12];
		self.progressDescription.text=@"Auto Timer";
		*/
		[Utils shiftView:self changeInX:0 changeInY:0 changeInWidth:0 changeInHeight:21];
	}
	
	if([self.progressView superview]==nil)
	{
		[self.contentView addSubview:self.progressView];
		[self.contentView addSubview:self.progressText];
		//[self.contentView addSubview:self.progressDescription];
	}
	
	self.progressView.progress = prog/(float)total;
	
	self.progressText.text = [[NSString stringWithFormat:@"%d", (int)prog] stringByAppendingFormat:@"/%@m",[NSString stringWithFormat:@"%d", total] ];

}

-(void) removeProgreeView
{
	if(self.progressView!=nil)
	{
		[self.progressText removeFromSuperview];
		[self.progressView removeFromSuperview];
		//[self.progressDescription removeFromSuperview];
	}
}

-(void) displayShareBtn:(BOOL)yesOrNo
{
	if (yesOrNo) {
		[self viewWithTag:CELL_SHARE_BTN].hidden=NO;
	}
	else {
		[self viewWithTag:CELL_SHARE_BTN].hidden=YES;
	}
}

-(void) setBadge:(int)newMsg
{
	UIButton *badge = (UIButton *)[self viewWithTag:CELL_BADGE_LABEL];

	if(newMsg<=0)
	{
		badge.hidden=YES;
	}
	else if(newMsg<9)
	{
		//badge.text = @"";
		[badge setTitle:[NSString stringWithFormat:@"%d", newMsg] forState:UIControlStateNormal];
		badge.hidden=NO;
		[self viewWithTag:CELL_SHARE_BTN].hidden=NO;//even if the btn is hidden, show it, otherwise, a red dot alone is weird
	}
	else {
		//if(newMsg<10)
		//	badge.text = [NSString stringWithFormat: @"%d", newMsg];
		//else //if(newMsg>=10)
		//	badge.text = @"N";
		[badge setTitle:@"N" forState:UIControlStateNormal];
		badge.hidden=NO;
		[self viewWithTag:CELL_SHARE_BTN].hidden=NO; //even if the btn is hidden, show it
	}
}

- (void) setCellColor:(CGColorRef)cgColor
{
	[self viewWithTag:CELL_COLOR_BTN].backgroundColor = [UIColor colorWithCGColor:cgColor];
}

- (void) setStrike:(BOOL)strike
{
	[self.calEventVCtrl setStrike:strike];
}

-(CGRect) getShareBtnRect
{
	return [self viewWithTag:CELL_SHARE_BTN].frame;
}

@end
