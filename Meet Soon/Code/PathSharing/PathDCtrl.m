//
//  PathDCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PathDCtrl.h"
#import "CrumbPath.h"
#import "Utils.h"

@implementation PathDCtrl

@synthesize locationManager, locationManagerOn, adjustLatitudinalMeters, adjustLongitudinalMeters, registeredListners;

static PathDCtrl *sharedInstance;

+ (PathDCtrl *) getSharedInstance
{
    return sharedInstance;
}

- (id) init
{
	self = [super init];
	
	if(self)
	{
		//self.delegate = callbackTarget;
		//We could normally use MKMapView's user location update delegation but this does not work in the background
				
		if([CLLocationManager locationServicesEnabled] != YES)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Your iPhone's location service is off. This feature of the app needs to use location service. \n\nPlease go to iPhone's Settings->Location Services, and turn on the location service for your iPhone."
														   delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[alert show];
			[Utils log:@"[CLLocationManager locationServicesEnabled]==NO"];
			return nil;
			
		}
		/* //don't alert here, use the purpose property below to tell user
		if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This app is not authorized to use location service. \n\nPlease go to iPhone's Settings->Location Services, and turn on the location service for this app."
														   delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[alert show];
			return nil;
			
		}
		*/
		
		self.locationManager = [[CLLocationManager alloc] init];

		if(self.locationManager==nil)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Your app can't start location service. \n\nPlease make sure the phone can receive GPS signal, or go to iPhone's Settings->Location Services, and check if this app is authorized to use location service."
														   delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[alert show];
			[Utils log:@"[[CLLocationManager alloc] init]==nil"];
			return nil;
		}
		
		self.locationManager.delegate = self; 
		
		self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters; //kCLLocationAccuracyBest;
		self.locationManager.distanceFilter = 10;
		self.locationManager.purpose=@"Your location is shared with others ONLY from when you turn on till auto-time off. \n\nYou can also turn the sharing on/off anytime by tapping the switch at the bottom of the map screen";
				
		self.adjustLatitudinalMeters = 0;
		self.adjustLongitudinalMeters = 0;
		
		self.registeredListners=0;

		if([self.locationManager respondsToSelector:@selector(pausesLocationUpdatesAutomatically)])
		{
			//NSLog(@"pausesLocationUpdatesAutomatically1:%d", self.locationManager.pausesLocationUpdatesAutomatically);
			self.locationManager.pausesLocationUpdatesAutomatically=NO;
			//NSLog(@"pausesLocationUpdatesAutomatically2:%d", self.locationManager.pausesLocationUpdatesAutomatically);
		}

		[self.locationManager startUpdatingLocation];
		self.locationManagerOn = YES;
	}
	
	sharedInstance=self;
	return self;
}

-(void) registerLocationUpdate
{
	@synchronized(self)
	{
		self.registeredListners++;
		//if(self.registeredListners>0)
			[self toggleLocationService:YES];
	}
}
-(void) deRegisterLocationUpdate
{
	@synchronized(self)
	{
		self.registeredListners = MAX(0, self.registeredListners-1);
		if(self.registeredListners==0)
			[self toggleLocationService:NO];
		
	}	
}

-(void) toggleLocationService:(BOOL) onOrOff
{
	@synchronized(self) //adjustCoordinates
	{
		if(onOrOff)
		{
			[self.locationManager startUpdatingLocation];
			self.locationManagerOn = YES;
		}
		else {
			[self.locationManager stopUpdatingLocation];
			self.locationManagerOn = NO;
		}
	}
}

//adjust the accuracy for tracking in China
- (void) adjustCoordinates:(CLLocationCoordinate2D) userCoord
{
	@synchronized(self)
	{
		if(self.locationManagerOn)
		{
			self.adjustLatitudinalMeters = userCoord.latitude - self.locationManager.location.coordinate.latitude;
			self.adjustLongitudinalMeters = userCoord.longitude - self.locationManager.location.coordinate.longitude;			
		}
	}
}

-(CLLocationCoordinate2D) getUserCurrentCoord
{
	//return CLLocationCoordinate2DMake(self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude);
	return CLLocationCoordinate2DMake(self.locationManager.location.coordinate.latitude+self.adjustLatitudinalMeters, self.locationManager.location.coordinate.longitude+self.adjustLongitudinalMeters);
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	//printf("oldLocation:%f %f -> newLocation:%f %f\n", oldLocation.coordinate.longitude, oldLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.coordinate.latitude);
	
	//if(oldLocation.coordinate.latitude==0 && oldLocation.coordinate.longitude==0) //the first update, may not be accurate, ignore it - but it can also be accurate - the gps may not update afterwards, hence need to notification for the first update
	//	return;

    if (newLocation && CLLocationCoordinate2DIsValid(newLocation.coordinate))
    {
		// make sure the old and new coordinates are different: do it in PVC, because for the first update, if old and new coord are the same, pvc will not get the first update for a long time 
        //if ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) ||
        //    (oldLocation.coordinate.longitude != newLocation.coordinate.longitude))
        //{    
			
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MyLocUpdateNotif" object:self userInfo:nil];
		//}
    }
	
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [Utils log:@"locationManager didFailWithError:%@",[error userInfo]];
	
	//self.locationManagerOn = NO;
	[self toggleLocationService:NO];
	self.registeredListners = 0; //reset the counter, because those sessions will need to re-turn on the shareinswtich again, which will access this counter
	
	 [[NSNotificationCenter defaultCenter] postNotificationName:@"gpsInitFailed" object:self userInfo:nil];
	
	/*
	 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This app can't start the iPhone location service.\n\nPlease make sure the phone can receive GPS signal and restart sharing, or go to iPhone's Settings->Location Services, and check if this app is authorized to use location service."
	 delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
	 [alert show];
	 */
	[Utils displaySmartAlertWithTitle:@"Warning" message:@"This app received an error notice from iPhone's location service.\n\nPlease make sure the phone can receive GPS signal and has Internet access, and restart your sharing, or go to iPhone's Settings->Location Services, and check if this app is authorized to use location service." noLocalNotif:NO];
}

@end
