//
//  MapVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapVCtrl.h"
#import "BridgeAnnotation.h"
#import "PathDCtrl.h"
#import "CrumbPath.h"
#import "CrumbPathView.h"
#import "Utils.h"

@interface MapVCtrl ()

@end

@implementation MapVCtrl

//#define SELF_UPDATE_MAP_NO 0
//#define SELF_UPDATE_MAP_SELFCENTER 1
//#define SELF_UPDATE_MAP_FITALL 2


@synthesize mapView, containerSize, mapCenterCoordinate, mapLatitudinalMeters, mapLongitudinalMeters, centerMapOnSelfLocation;
@synthesize colorIndex, crumbViewsColor, lastAnnotation;
@synthesize crumbsFromAll, crumbViewsFromAll;//, annotationsFromAll;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect center:(CLLocationCoordinate2D) centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters annotation:(id < MKAnnotation >)initialAnnotation //crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.containerSize = rect;
		self.mapCenterCoordinate = centerCoordinate;
		self.mapLatitudinalMeters = latitudinalMeters;
		self.mapLongitudinalMeters = longitudinalMeters;
		
		//self.mapView.showsUserLocation=YES; //it has no effect here since mapview not loaded yet - has to set it to be YES in the viewdidload
		self.centerMapOnSelfLocation=NO;
				
		self.crumbViewsColor = [NSArray arrayWithObjects:[UIColor blueColor],[UIColor cyanColor], /*[UIColor brownColor],*/[UIColor purpleColor],[UIColor magentaColor],nil];
		self.colorIndex=0;
		
		self.lastAnnotation = initialAnnotation;
		/*
		if(initialCrumbs!=nil && [initialCrumbs count]>0)
		{
			self.crumbsFromAll = [NSMutableArray arrayWithArray:initialCrumbs];
			self.crumbViewsFromAll = [[NSMutableArray alloc] init];
			for(int i=0;i<[self.crumbsFromAll count];i++)
			{
				[self.crumbViewsFromAll addObject:[[CrumbPathView alloc] initWithOverlay:[self.crumbsFromAll objectAtIndex:i] color:[self.crumbViewsColor objectAtIndex:self.colorIndex] ]];
				self.colorIndex++;
				if(self.colorIndex==[self.crumbViewsColor count])
					self.colorIndex = 0;
			}
		}

		if(initialAnnotations!=nil && [initialAnnotations count]>0)
			self.annotationsFromAll = [NSMutableArray arrayWithArray:initialAnnotations];
		 */
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	self.view.frame = self.containerSize;
	
	if(CLLocationCoordinate2DIsValid(self.mapCenterCoordinate)==NO) //not valid center point, use the user's current location
	{		
		self.mapLatitudinalMeters = 2000; //set the default zoom level
		self.mapLongitudinalMeters = 2000;
		
		[self setMapViewRegionCenter:CLLocationCoordinate2DMake(0, 0) latDistance:self.mapLatitudinalMeters longDistance:self.mapLongitudinalMeters];
		//NSLog(@"load/self - LAT: %f LON: %f", self.mapCenterCoordinate.latitude, self.mapCenterCoordinate.longitude);
		//NSLog(@"load/user - LAT: %f LON: %f", self.mapView.userLocation.coordinate.latitude, self.mapView.userLocation.coordinate.longitude);
		
		self.centerMapOnSelfLocation=YES;
		self.mapView.showsUserLocation=YES; //do this after the setMapViewRegionCenter, to ensure the map is not centered at 0,0 (right after the loc update call that centers the map around self)

	}
	else //already has a coord specificed, such as from other users' update, or recover from a crash (read from coredata) 
		[self setMapViewRegionCenter:self.mapCenterCoordinate latDistance:self.mapLatitudinalMeters longDistance:self.mapLongitudinalMeters];
	
	if(self.lastAnnotation!=nil)
	{
		[self.mapView addAnnotation:self.lastAnnotation];
		[self.mapView selectAnnotation:self.lastAnnotation animated:NO]; //useless here
	}
	
	/*
	if(self.crumbsFromAll!=nil && [self.crumbsFromAll count]>0)
		[self.mapView addOverlays:self.crumbsFromAll];
	
	if(self.annotationsFromAll!=nil && [self.annotationsFromAll count]>0)
	{
		[self.mapView addAnnotations:self.annotationsFromAll];
		//the last annotation is the one to display details
		[self.mapView selectAnnotation:[self.annotationsFromAll lastObject] animated:NO];
	}
	*/
}

- (void)viewDidUnload
{
	self.mapView.showsUserLocation=NO;
    [self setMapView:nil];
	self.lastAnnotation=nil;
	if(self.crumbsFromAll!=nil)
		[self.crumbsFromAll removeAllObjects];
	self.crumbsFromAll = nil;
	self.crumbViewsColor = nil;
	if(self.crumbViewsFromAll!=nil)
		[self.crumbViewsFromAll removeAllObjects];
	self.crumbViewsFromAll =nil;
	//self.annotationsFromAll = nil;
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

//this will not be called by PVC!!!! because of the view we use the vctrl. but it is called by weijulistvctrl for map in cell!!!
-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if(self.lastAnnotation!=nil)
	{
		//[self.mapView addAnnotation:self.lastAnnotation];
		[self.mapView selectAnnotation:self.lastAnnotation animated:NO];
	}

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) showsUserLocation:(BOOL)show
{
	self.mapView.showsUserLocation = show;
}

//mainlly called by demo mode
- (void) addInitialOverLays:(NSArray *)initialCrumbs initialAnnotations:(NSArray *)initialAnnotations
{
	if(initialCrumbs!=nil && [initialCrumbs count]>0)
	{
		if(self.crumbsFromAll==nil)
		{	
			self.crumbsFromAll = [NSMutableArray arrayWithArray:initialCrumbs];
			self.crumbViewsFromAll = [[NSMutableArray alloc] init];
		}
		
		for(int i=0;i<[self.crumbsFromAll count];i++)
		{
			[self.crumbViewsFromAll addObject:[[CrumbPathView alloc] initWithOverlay:[self.crumbsFromAll objectAtIndex:i] color:[self.crumbViewsColor objectAtIndex:self.colorIndex] ]];
			self.colorIndex++;
			if(self.colorIndex==[self.crumbViewsColor count])
				self.colorIndex = 0;
		}
	}
	
	if(self.crumbsFromAll!=nil && [self.crumbsFromAll count]>0)
		[self.mapView addOverlays:self.crumbsFromAll];
	
	if(initialAnnotations!=nil && [initialAnnotations count]>0)
	{
		[self.mapView addAnnotations:initialAnnotations];
		//the last annotation is the one to display details
		[self.mapView selectAnnotation:[initialAnnotations lastObject] animated:NO];
	}
}

- (BOOL) setMapViewRegionCenter:(CLLocationCoordinate2D) centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters
{
	self.mapCenterCoordinate = centerCoordinate;
	self.mapLatitudinalMeters = latitudinalMeters;
	self.mapLongitudinalMeters = longitudinalMeters;
	
	//In some situations (when app becomes active from background) didUpdateUserLocation method is fired, but without updated location. In this cases there is no valid region, and setRegion: method can throw exception - must catch it to prevent crashing
	@try{
		[self.mapView setRegion:MKCoordinateRegionMakeWithDistance(centerCoordinate, latitudinalMeters, longitudinalMeters) animated:YES];	
	}
	@catch(NSException *exception)
	{
		[Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, exception, [exception reason]];
		return NO;
	}
	
	return YES;
}

-(BOOL) setMapViewRegionCenter:(CLLocationCoordinate2D) centerCoordinate
{
	self.mapCenterCoordinate = centerCoordinate;
	//[self setMapViewRegionCenter:centerCoordinate latDistance:self.mapLatitudinalMeters longDistance:self.mapLongitudinalMeters];
	@try{
		[self.mapView setCenterCoordinate:centerCoordinate animated:YES];	
	}
	@catch(NSException *exception)
	{
		[Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, exception, [exception reason]];
		return NO;
	}

	return YES;
}

-(CrumbPath *) addOverlay:(CLLocationCoordinate2D) center //:(id) overlay
{
	CrumbPath * overlay = [[CrumbPath alloc] initWithCenterCoordinate:center];
	CrumbPathView *overlayView = [[CrumbPathView alloc] initWithOverlay:overlay color:[self.crumbViewsColor objectAtIndex:self.colorIndex]];
	
	if(self.crumbsFromAll==nil||[self.crumbsFromAll count]==0)
	{
		self.crumbsFromAll=[NSMutableArray arrayWithObject:overlay];
		self.crumbViewsFromAll=[NSMutableArray arrayWithObject:overlayView];
	}
	else 
	{
		[self.crumbsFromAll addObject:overlay];
		[self.crumbViewsFromAll addObject:overlayView];
	}
	
	self.colorIndex++;
	if(self.colorIndex==[self.crumbViewsColor count])
		self.colorIndex = 0;
	
	[self.mapView addOverlay:overlay];
	
	return overlay;
}

-(void) removeOverlay:(id) overlay
{
	[self.mapView removeOverlay:overlay];
/*
	int index = [self.crumbsFromAll indexOfObject:overlay];
	
	if(index!=NSNotFound)
	{
		[self.mapView removeOverlay:overlay];
		[self.crumbsFromAll removeObjectAtIndex:index];
		[self.crumbViewsFromAll removeObjectAtIndex:index];
		//remove annotation?
		
	}
*/	
}

-(void) updateCrumbViewForOverlay:(id) overlay rect:(MKMapRect) updateRect
{
	int index = [self.crumbsFromAll indexOfObject:overlay];
	
	if(index!=NSNotFound)
	{
		// Compute the currently visible map zoom scale
		MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
		
		// Find out the line width at this zoom scale and outset the updateRect by that amount
		CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
		updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
		// Ask the overlay view to update just the changed area.
		[(CrumbPathView *)[self.crumbViewsFromAll objectAtIndex:index ] setNeedsDisplayInMapRect:updateRect];
	}
}

-(void) selectAnnotation:(id < MKAnnotation >)annotation
{
	//if([self.annotationsFromAll indexOfObject:annotation]!=NSNotFound)
		[self.mapView selectAnnotation:annotation animated:YES];
}

- (id < MKAnnotation >) addAnnotation:(CLLocationCoordinate2D) coord title:(NSString *)title subTitle:(NSString *)subTitle repositionMap:(BOOL)yesOrNot
{
	BridgeAnnotation *ba=[[BridgeAnnotation alloc] init];
	ba.theTitle=title;
	ba.theSubtitle=subTitle;
	[ba setCoordinate:coord];

	/*
	if(self.annotationsFromAll==nil||[self.annotationsFromAll count]==0)
		self.annotationsFromAll=[NSMutableArray arrayWithObject:ba];
	else 
		[self.annotationsFromAll addObject:ba];
	*/
	
	[self.mapView addAnnotation:ba];
	
	[self.mapView selectAnnotation:ba animated:YES];	
	
	if(yesOrNot)
		[self setMapViewRegionCenter:coord];//] latDistance:self.mapLatitudinalMeters longDistance:self.mapLongitudinalMeters];
	
	self.lastAnnotation = ba;
	
	return ba;
}

-(void) removeAnnotations:(NSArray *)annotationArray
{
	[self.mapView removeAnnotations:annotationArray];
	/*
	for (int i=0; i<[annotationArray count]; i++) {
		[self.annotationsFromAll removeObject:[annotationArray objectAtIndex:i]];
	}
	*/
}

#pragma mark - MKMapViewDelegate Protocol
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	//NSLog(@"didUpdate: %@-> LAT: %f LON: %f\n", userLocation, userLocation.coordinate.latitude, userLocation.coordinate.longitude);
	//NSLog(@"didUpdate/mapview: -> LAT: %f LON: %f\n", mapView.userLocation.coordinate.latitude, mapView.userLocation.coordinate.longitude);
	BOOL updateResult=YES;
	if (self.centerMapOnSelfLocation)
	{
		if([self setMapViewRegionCenter:userLocation.coordinate])//] latDistance:self.mapLatitudinalMeters longDistance:self.mapLongitudinalMeters];
		{
			self.centerMapOnSelfLocation = NO; //self center only once!
		}
		else {
			updateResult = NO;
		}
	}
	
	if(updateResult)
	{
	//adjust the locmgr accuracy in china
	PathDCtrl *path = [PathDCtrl getSharedInstance];
	if (path!=nil) //help location manager to tune its accuracy in china
		[path adjustCoordinates:userLocation.coordinate];
//	else {
//		[[PathDCtrl alloc] init]; //如果这样做,好处是可以提前矫正locmanager的误差,坏处是会启动背景的gps,切换软件到后台,仍然跑gps,耗电
//	}
	}
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
	[Utils log:@"mapView didFailToLocateUserWithError %@ %@",[error localizedDescription], [error localizedRecoverySuggestion]];
	
	/*
	if([[error localizedDescription] rangeOfString:@"Location"].location!=NSNotFound) //skip the second warning - "The operation could not be completed. (kCLErrorDomain error 0.)"
		[Utils displaySmartAlertWithTitle:[error localizedDescription] message:[error localizedRecoverySuggestion] noLocalNotif:YES];
	*/
	//[self centerSelfLocation]; //re-do it again: bad recursion in loop
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
	[Utils log:@"mapViewDidFailLoadingMap %@",[error localizedDescription], [error localizedRecoverySuggestion]];
	
	//[Utils displaySmartAlertWithTitle:@"Map Loading Failed" message:[error localizedDescription] /*stringByAppendingFormat:@"\n\n%@", [error localizedRecoverySuggestion] ]*/ noLocalNotif:YES];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay //[mapView addOverlay:overlay]调用之后就会调用这个
{
    return [self.crumbViewsFromAll objectAtIndex:[self.crumbsFromAll indexOfObject:overlay]];
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	//[Utils printClass:annotation];
	
	if ([annotation isKindOfClass:[BridgeAnnotation class]]) 
    {
		// try to dequeue an existing pin view first
        static NSString* BridgeAnnotationIdentifier = @"bridgeAnnotationIdentifier";
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:BridgeAnnotationIdentifier];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[MKPinAnnotationView alloc]
												  initWithAnnotation:annotation 
												  reuseIdentifier:BridgeAnnotationIdentifier];
            customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: you can assign a specific call out accessory view, or as MKMapViewDelegate you can implement:
            //  - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
            /*
			UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			[rightButton addTarget:self
			action:@selector(showAnnotationDetails:)
			forControlEvents:UIControlEventTouchUpInside];
			customPinView.rightCalloutAccessoryView = rightButton;
			 
			UIImageView *leftPicture = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"person_none_image.png"]];
			leftPicture.bounds=CGRectMake(0, 0, 32, 32);
			customPinView.leftCalloutAccessoryView = leftPicture;
			 */
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
		
	}
	
	return nil;
}

#pragma mark - various manipulation

#define MINIMUM_ZOOM_ARC 0.014 //approximately 1 miles (1 degree of arc ~= 69 miles)
#define ANNOTATION_REGION_PAD_FACTOR 1.1 //1.15
#define MAX_DEGREES_ARC 360
//size the mapView region to fit its annotations
- (void)zoomMapViewToFitAnnotations
{ 
	//self.mapView.showsUserLocation=NO; //user current locatio is also an annotation, turn off since i am in china
	
	int count = [self.mapView.annotations count];
	
	if(self.mapView.showsUserLocation==NO)
		if ( count == 0) { return; } //bail if no or just 1 annotations
	else 
		if ( count <= 1) { return; } //2 means self plus another annotation
	
	//convert NSArray of id <MKAnnotation> into an MKCoordinateRegion that can be used to set the map size

	//can't use NSArray with MKMapPoint because MKMapPoint is not an id
	
	MKMapPoint points[count]; //C array of MKMapPoint struct
	for( int i=0; i<count; i++ ) //load points C array by converting coordinates to points
	{
		CLLocationCoordinate2D coordinate = [(id <MKAnnotation>)[self.mapView.annotations objectAtIndex:i] coordinate];
		points[i] = MKMapPointForCoordinate(coordinate);
	}
	
	//create MKMapRect from array of MKMapPoint
	MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:count] boundingMapRect];
	
	//convert MKCoordinateRegion from MKMapRect
	MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
	
	//add padding so pins aren't scrunched on the edges
	region.span.latitudeDelta  *= ANNOTATION_REGION_PAD_FACTOR;
	region.span.longitudeDelta *= ANNOTATION_REGION_PAD_FACTOR;
	//but padding can't be bigger than the world
	if( region.span.latitudeDelta > MAX_DEGREES_ARC ) { region.span.latitudeDelta  = MAX_DEGREES_ARC; }
	
	if( region.span.longitudeDelta > MAX_DEGREES_ARC ){ region.span.longitudeDelta = MAX_DEGREES_ARC; }
	
	//and don't zoom in stupid-close on small samples
	if( region.span.latitudeDelta  < MINIMUM_ZOOM_ARC ) { region.span.latitudeDelta  = MINIMUM_ZOOM_ARC; }
	
	if( region.span.longitudeDelta < MINIMUM_ZOOM_ARC ) { region.span.longitudeDelta = MINIMUM_ZOOM_ARC; }

	//and if there is a sample of 1 we want the max zoom-in instead of max zoom-out
	if( count == 1 )
	{ 
		region.span.latitudeDelta = MINIMUM_ZOOM_ARC;
		region.span.longitudeDelta = MINIMUM_ZOOM_ARC;
	}
	
	@try{
		[self.mapView setRegion:region animated:YES];		
	}
	@catch(NSException *exception)
	{
		[Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, [exception userInfo], [exception reason]];
	}
	
}

- (void) centerSelfLocation //called by pvc's - (void) friendSelected:(WeiJuParticipant *)friend
{
	self.centerMapOnSelfLocation=YES;
	//self.mapView.showsUserLocation=NO;
	[self showsUserLocation:NO]; //use func call to ensure it is executed right away
	self.mapView.showsUserLocation=YES; //first no then YES, to force refresh of lcoation RIGHT AWAY, hence calling setregion to reposition map
	//self.selfUpdateMapMode = SELF_UPDATE_MAP_SELFCENTER;
}

@end
