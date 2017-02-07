//
//  CalEventVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalEventVCtrl.h"
#import "MapVCtrl.h"
#import "WeiJuAppPrefs.h"
#import "Utils.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuPathShareVCtrl.h"

@interface CalEventVCtrl ()

@end

@implementation CalEventVCtrl

#define CAL_MAPVIEW_LEFT_MARGIN 70

#define CAL_EVENT_NORMVIEWCONTAINER_TAG 11
#define CAL_EVENT_STARTTIME_TAG 14
#define CAL_EVENT_STARTTIME_AMPM_TAG 15
#define CAL_EVENT_STARTTIME_NO_AMPM_TAG 16
#define CAL_EVENT_SUBJ_TAG 12
#define CAL_EVENT_PLACE_TAG 13
#define CAL_EVENT_STRIKE_TAG 17

const int CAL_EVENT_MODE_STATIC = 0;
const int CAL_EVENT_MODE_MAP = 1;

#define CURRENT_VIEW_EVENT 0
#define CURRENT_VIEW_MAP 1

const int ANIMATION_MODE_SHIFTUP = 0;
const int ANIMATION_MODE_FLIP = 1;

@synthesize containerSize=_containerSize, calEventMode=_calEventMode,calEventMapAnimationMode=_calEventMapAnimationMode, calEventCurrentView=_calEventCurrentView, runAnimation=_runAnimation, animationTimerForMap=_animationTimerForMap, mapVCtrl=_mapVCtrl;

@synthesize eventStartTime=_eventStartTime, eventPlace=_eventPlace, eventSubject=_eventSubject;

@synthesize centerCoordinate=_centerCoordinate, latitudinalMeters=_latitudinalMeters, longitudinalMeters=_longitudinalMeters, initialAnnotation=_initialAnnotation; // initialCrumbs=_initialCrumbs, initialAnnotations=_initialAnnotations;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect displayMode:(int) mode
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.containerSize = rect;
		self.calEventMode=mode;
		self.calEventCurrentView=0; //default is normal eventview
		//self.calEventMapAnimationMode=ANIMATION_MODE_SHIFTUP;
		self.calEventMapAnimationMode=ANIMATION_MODE_FLIP;
		self.runAnimation=NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	self.view.frame = self.containerSize; 
	self.view.userInteractionEnabled=NO; //disable the touch on map!
	
	[self.view viewWithTag:CAL_EVENT_STRIKE_TAG].hidden=YES;
	
	//self.view.layer.masksToBounds=YES;
//	self.view.layer.borderWidth=1;
//	self.view.layer.borderColor=[[UIColor greenColor] CGColor];
	
	/* //no need to set here, since the setSub method will access self.view, whch will calls this method
	((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_TAG]).text = [Utils getHourMinutes:self.eventStartTime];
	((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_AMPM_TAG]).text = [Utils getAMPM:self.eventStartTime];
	//((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_AMPM_TAG]).textColor = [UIColor lightTextColor];
	((UILabel *)[self.view viewWithTag:CAL_EVENT_SUBJ_TAG]).text = self.eventSubject;
	((UILabel *)[self.view viewWithTag:CAL_EVENT_PLACE_TAG]).text = self.eventPlace;
	 */
	
	if(self.calEventMode==CAL_EVENT_MODE_MAP)
	{
		[self setUpMapDisplay];
	}	

	//UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	//[self.view addGestureRecognizer:recognizer];

}

- (void) setUpMapDisplay
{
	self.calEventMode=CAL_EVENT_MODE_MAP;
	
	if(self.mapVCtrl==nil)
		self.mapVCtrl = [[MapVCtrl alloc] initWithNibName:@"MapVCtrl" bundle:nil rect:CGRectMake(CAL_MAPVIEW_LEFT_MARGIN, 0,self.containerSize.size.width, self.containerSize.size.height) center:CLLocationCoordinate2DMake(self.centerCoordinate.latitude, self.centerCoordinate.longitude) 
											  latDistance:self.latitudinalMeters 
											 longDistance:self.longitudinalMeters 
											   annotation:self.initialAnnotation ];
//												   crumbs:self.initialCrumbs 
//											  annotations:self.initialAnnotations];
	//NSLog(@"self.view %@ %@", self.view, self.mapVCtrl.view);
	[self.view addSubview:self.mapVCtrl.view];
	
	//self.calEventCurrentView=CURRENT_VIEW_MAP; //map
	self.calEventCurrentView=CURRENT_VIEW_EVENT;
	
	if(self.calEventMapAnimationMode==ANIMATION_MODE_SHIFTUP) //move the msg downward to be shifted up
		//[Utils shiftView:[self.view viewWithTag:CAL_EVENT_NORMVIEWCONTAINER_TAG] changeInX:0 changeInY:[self.view viewWithTag:CAL_EVENT_NORMVIEWCONTAINER_TAG].frame.size.height changeInWidth:0 changeInHeight:0];
		[Utils shiftView:self.mapVCtrl.view changeInX:0 changeInY:self.mapVCtrl.view.frame.size.height changeInWidth:0 changeInHeight:0];
	else if (self.calEventMapAnimationMode==ANIMATION_MODE_FLIP)
		self.mapVCtrl.view.hidden=YES; //hide one view: bug? should it be the message view to be hid first?
	
	self.runAnimation=YES;
	[self mapAnimation];

}

-(void) removeMapDisplay
{
	self.runAnimation=NO;
	self.calEventCurrentView=CURRENT_VIEW_EVENT; 
	self.calEventMode=CAL_EVENT_MODE_STATIC;
	[self.mapVCtrl.view removeFromSuperview];
	self.mapVCtrl=nil; //recycle to save memory
	//what if the event view is off position: below the map to be shifted up
	[self.view viewWithTag:CAL_EVENT_NORMVIEWCONTAINER_TAG].hidden=NO;
}

- (void) ensureToShowEventContent //called to ensure the content view is dispayed/not hidden due to map animation stopped in the middle
{
	[self.view viewWithTag:CAL_EVENT_NORMVIEWCONTAINER_TAG].hidden=NO;	
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.eventPlace = nil;
	self.eventStartTime = nil;
	self.eventSubject = nil;
	
	self.initialAnnotation = nil;
	//self.initialCrumbs = nil;
	//self.initialAnnotations = nil;
	
	self.mapVCtrl = nil;
	self.animationTimerForMap=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) setSubject:(NSString *)subj place:(NSString *)place startTime:(NSDate *)time
{
	//NSLog(@"setSubject: %@ %@", subj, place);
	/*
	if(subj==nil || [subj isEqualToString:@""])
		self.eventSubject = @"New Event";
	else
		self.eventSubject = [NSString stringWithString:subj];
	 if(place==nil|| [place isEqualToString:@""])
	 self.eventPlace = @"Place unspecified";
	 else
	 self.eventPlace = [NSString stringWithString:place];
	 */
	self.eventSubject = [[[Utils alloc] init] getEventProperty:subj nilReplaceMent:@"New Event"];
	self.eventPlace = [[[Utils alloc] init] getEventProperty:place nilReplaceMent:@"Place unspecified"];
	
	[self setEventStartTime:[NSDate dateWithTimeInterval:0 sinceDate:time]]; //make a copy, rather than hold the reference
	
	NSString *ampm = [Utils getAMPM:self.eventStartTime];
	if(ampm!=nil && [ampm isEqualToString:@""]==NO)
	{
		((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_TAG]).text = [Utils getHourMinutes:self.eventStartTime];
		((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_AMPM_TAG]).text = ampm;
		((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_NO_AMPM_TAG]).text = @"";		
	}
	else {
		((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_TAG]).text = @"";
		((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_AMPM_TAG]).text = @"";
		((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_NO_AMPM_TAG]).text = [Utils getHourMinutes:self.eventStartTime];		
	}
	//((UILabel *)[self.view viewWithTag:CAL_EVENT_STARTTIME_AMPM_TAG]).textColor = [UIColor lightTextColor];
	((UILabel *)[self.view viewWithTag:CAL_EVENT_SUBJ_TAG]).text = self.eventSubject;
	((UILabel *)[self.view viewWithTag:CAL_EVENT_PLACE_TAG]).text = self.eventPlace;

}

- (void) toggleMapMode:(BOOL)yesOrNo center:(CLLocationCoordinate2D)centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters annotation:(id < MKAnnotation >)initialAnnotation//  crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations
{
	if(yesOrNo)
	{
		[self setMapViewCenter:centerCoordinate latDistance:latitudinalMeters longDistance:longitudinalMeters annotation:initialAnnotation]; //crumbs:initialCrumbs annotations:initialAnnotations];
		[self setUpMapDisplay];
	}
	else {
		[self removeMapDisplay];
	}
}


- (void) setMapViewCenter:(CLLocationCoordinate2D)centerCoord latDistance:(CLLocationDistance) latitudinalM longDistance:(CLLocationDistance) longitudinalM annotation:(id < MKAnnotation >)annotation// crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations
{
	//self.centerCoordinate = CLLocationCoordinate2DMake(centerCoord.latitude, centerCoord.longitude);
	self.centerCoordinate = centerCoord;
	self.latitudinalMeters = latitudinalM;
	self.longitudinalMeters = longitudinalM;

	self.initialAnnotation = annotation;
	//self.initialCrumbs = initialCrumbs;
	//self.initialAnnotations = initialAnnotations;
	//NSLog(@"2: %f %f %@", self.centerCoordinate.latitude, self.centerCoordinate.longitude, self);
	
	if(self.mapVCtrl!=nil)
		[self.mapVCtrl setMapViewRegionCenter:CLLocationCoordinate2DMake(self.centerCoordinate.latitude, self.centerCoordinate.longitude) 
								  latDistance:self.latitudinalMeters 
								 longDistance:self.longitudinalMeters];

}

-(void) mapAnimation //transitionWithView - transition is always for the containerview, not for subview inside the containerview
{
	@synchronized(self)
	{	
		UIView *eventContainerView = [self.view viewWithTag:CAL_EVENT_NORMVIEWCONTAINER_TAG];
		if(self.runAnimation==YES)
		{
			UIViewAnimationOptions opt;
			if(self.calEventMapAnimationMode==ANIMATION_MODE_SHIFTUP)
				opt = UIViewAnimationOptionCurveEaseOut;
			else if(self.calEventMapAnimationMode==ANIMATION_MODE_FLIP)
				opt = UIViewAnimationOptionTransitionFlipFromBottom;
			
			[UIView transitionWithView:self.view duration:0.5 options:opt 
							animations:^{
								if(self.calEventMapAnimationMode==ANIMATION_MODE_SHIFTUP)
								{
									[Utils shiftView:eventContainerView changeInX:0 changeInY:-eventContainerView.frame.size.height changeInWidth:0 changeInHeight:0];
									[Utils shiftView:self.mapVCtrl.view changeInX:0 changeInY:-self.mapVCtrl.view.frame.size.height changeInWidth:0 changeInHeight:0];
								}
								else if(self.calEventMapAnimationMode==ANIMATION_MODE_FLIP)
								{
									if(eventContainerView.hidden==YES)
									{
										self.mapVCtrl.view.hidden=YES;
										eventContainerView.hidden=NO;
										
									}
									else {
										eventContainerView.hidden=YES;
										self.mapVCtrl.view.hidden=NO;
									}
								}
							} 
							completion:^(BOOL finished) {
								if(self.calEventMapAnimationMode==ANIMATION_MODE_SHIFTUP)
								{
									if(self.calEventCurrentView==CURRENT_VIEW_MAP) //map already shifted up 
									{
										[Utils shiftView:self.mapVCtrl.view changeInX:0 changeInY:2*self.mapVCtrl.view.frame.size.height changeInWidth:0 changeInHeight:0]; //can potentially get messed up due to multiple threads calling this method
										self.calEventCurrentView=CURRENT_VIEW_EVENT;
									}
									else {
										[Utils shiftView:eventContainerView changeInX:0 changeInY:2*eventContainerView.frame.size.height changeInWidth:0 changeInHeight:0];
										self.calEventCurrentView=CURRENT_VIEW_MAP;
									}
								}
								else if(self.calEventMapAnimationMode==ANIMATION_MODE_FLIP)
								{
									//the following update may not be necessary for the animation, may be useful for other methods
									if(eventContainerView.hidden)
										self.calEventCurrentView=CURRENT_VIEW_MAP;
									else 
										self.calEventCurrentView=CURRENT_VIEW_EVENT;
								}
								
								if(self.runAnimation==YES) //should pause for a few seconds here
									self.animationTimerForMap = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(mapAnimationTimesup:) userInfo:nil repeats:NO];
								
								//[Utils printSubViews:@"ecvc-a" For:self.view];
								
								
							} ];
		}
		else{
			//reset container view position
			if(self.calEventMapAnimationMode==ANIMATION_MODE_SHIFTUP)
				eventContainerView.frame=CGRectMake(eventContainerView.frame.origin.x, 0, eventContainerView.frame.size.width, eventContainerView.frame.size.height);
			else 
				eventContainerView.hidden = NO;
		}
	}
}

-(void) mapAnimationTimesup:(NSTimer *)timer
{
	if(timer == self.animationTimerForMap && self.calEventMode==CAL_EVENT_MODE_MAP) //if they are not equal, it means we fire many timer quickly (pintapped), only the last one will be executed: e.g., tap pin twice to stop (but the first timer has been fired) and then start quickly, animation==YES, fire the 2nd timer, they both come to call this method -> animation become fast
		[self mapAnimation];
}

- (void) tapped:(UIGestureRecognizer *)gesture
{
  	//NSLog(@"tap- %@, %@\n", gesture, self);
	if([[WeiJuAppPrefs getSharedInstance] demo])
	{
		if(self.calEventMode==CAL_EVENT_MODE_MAP) //always go to chatv with map displayed
		{
			//[[WeiJuListVCtrl getSharedInstance].navigationController pushViewController:[[WeiJuPathShareVCtrl alloc] initWithNibName:@"WeiJuPathShareVCtrl" bundle:nil center:self.centerCoordinate latDistance:self.latitudinalMeters longDistance:self.longitudinalMeters crumbs:self.initialCrumbs annotations:self.initialAnnotations locSharing:NO locSharingDuration:30] animated:YES];
			
		}
		else //go to chatv without map displayed
		{
			//[[WeiJuListVCtrl getSharedInstance].navigationController pushViewController:[[WeiJuPathShareVCtrl alloc] initWithNibName:@"WeiJuPathShareVCtrl" bundle:nil center:CLLocationCoordinate2DMake(0, 0) latDistance:0 longDistance:0 crumbs:nil annotations:nil locSharing:NO locSharingDuration:30] animated:YES];
		}
	}
	else
	{
		
	}
}

- (void) mapTapped:(MapVCtrl *)mapVCtrl
{
  	//NSLog(@"tap- %@\n", mapVCtrl);
	if([[WeiJuAppPrefs getSharedInstance] demo])
	{
		//[[WeiJuListVCtrl getSharedInstance].navigationController pushViewController:[[WeiJuPathShareVCtrl alloc] initWithNibName:@"WeiJuPathShareVCtrl" bundle:nil center:self.centerCoordinate latDistance:self.latitudinalMeters longDistance:self.longitudinalMeters crumbs:self.initialCrumbs annotations:self.initialAnnotations locSharing:NO locSharingDuration:30] animated:YES];

	}
	else
	{
		
	}
	
	
}

-(void) toggleEventAnimation:(BOOL)yesOrNo
{
	@synchronized(self)
	{	
	if (yesOrNo==YES) 
	{
		if(self.runAnimation==NO)
		{
			self.runAnimation=YES;
			if(self.calEventMode==CAL_EVENT_MODE_MAP)
			{
				//[self.calEventMapVCtrl.mapViewPin setImage:[UIImage imageNamed:@"pin-black.png"] forState:UIControlStateNormal];
				
				[self mapAnimation];
			}
		}
	}
	else {
		if(self.runAnimation==YES)
		{
			self.runAnimation=NO;
			if(self.calEventMode==CAL_EVENT_MODE_MAP)
			{
				//[self.calEventMapVCtrl.mapViewPin setImage:[UIImage imageNamed:@"cancel-icon.png"] forState:UIControlStateNormal];
			}
		}
	}
	}
}

- (void) setStrike:(BOOL)strike
{
	UIButton * strikeBtn = (UIButton *)[self.view viewWithTag:CAL_EVENT_STRIKE_TAG];
	if(strike==NO)
		strikeBtn.hidden=YES;
	else 
	{
		UILabel *subj = (UILabel *)[self.view viewWithTag:CAL_EVENT_SUBJ_TAG];
		if([subj.text hasPrefix:@"Canceled"]==NO)
			subj.text = [@"Canceled: " stringByAppendingString:subj.text];
		CGSize textSize= [subj.text sizeWithFont:[UIFont boldSystemFontOfSize:17.0] forWidth:210 lineBreakMode:UILineBreakModeTailTruncation];
		strikeBtn.frame = CGRectMake(strikeBtn.frame.origin.x, strikeBtn.frame.origin.y, textSize.width, strikeBtn.frame.size.height);
		strikeBtn.hidden=NO;
	}
}
@end
