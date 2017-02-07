//
//  PathDCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//@class CrumbPath;
/*
@protocol PathUpdate //<NSObject>
-(void) locationUpdated:(CLLocationCoordinate2D)currentCoord rect:(MKMapRect)rect metersApart:(CLLocationDistance)distance;
@end
*/
@interface PathDCtrl : NSObject  <CLLocationManagerDelegate>

//@property (strong, nonatomic) id <PathUpdate> delegate;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL locationManagerOn;
@property (nonatomic, assign) NSUInteger registeredListners;

//location manger's location may be diff from mapview's, in china, hence need to make adjustment
@property (nonatomic, assign) CLLocationDistance adjustLatitudinalMeters;
@property (nonatomic, assign) CLLocationDistance adjustLongitudinalMeters;

//@property (nonatomic, assign) CLLocationCoordinate2D currentCoordinate;

+ (PathDCtrl *) getSharedInstance;
//- (id) initWithTarget:(id)delegate;
-(void) registerLocationUpdate;
-(void) deRegisterLocationUpdate;

- (void) adjustCoordinates:(CLLocationCoordinate2D) userCoord;
-(CLLocationCoordinate2D) getUserCurrentCoord;

@end
