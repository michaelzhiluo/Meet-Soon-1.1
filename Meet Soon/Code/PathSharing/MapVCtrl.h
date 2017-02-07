//
//  MapVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CrumbPath;

@interface MapVCtrl : UIViewController

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, assign) CGRect containerSize;

@property (nonatomic, assign) CLLocationCoordinate2D mapCenterCoordinate;
@property (nonatomic, assign) CLLocationDistance mapLatitudinalMeters;//one degree of latitude is approximately 111 kilometers (69 miles) at all times
@property (nonatomic, assign) CLLocationDistance mapLongitudinalMeters;//one degree of longitude spans a distance of approximately 111 kilometers (69 miles) at the equator but shrinks to 0 kilometers at the poles
@property (nonatomic, assign) BOOL centerMapOnSelfLocation; //no update, self center, fit-all etc.


@property (nonatomic, retain) NSMutableArray *crumbsFromAll; //should be an array, to display the crumbpath from all people
@property (nonatomic, assign) int colorIndex;
@property (nonatomic, retain) NSArray *crumbViewsColor;
@property (nonatomic, retain) NSMutableArray *crumbViewsFromAll;
//@property (nonatomic, retain) NSMutableArray *annotationsFromAll; 
@property (nonatomic, retain) id < MKAnnotation > lastAnnotation; 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect center:(CLLocationCoordinate2D) centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters annotation:(id < MKAnnotation >)initialAnnotation; //crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations;

-(void) showsUserLocation:(BOOL)show;
-(BOOL) setMapViewRegionCenter:(CLLocationCoordinate2D) centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters;
-(BOOL) setMapViewRegionCenter:(CLLocationCoordinate2D) centerCoordinate;

-(CrumbPath *) addOverlay:(CLLocationCoordinate2D) center; //add a person's saved CrumbPath
-(void) removeOverlay:(id) overlay;
-(void) updateCrumbViewForOverlay:(id) overlay rect:(MKMapRect) updateRect;

-(void) selectAnnotation:(id < MKAnnotation >)annotation;
- (id < MKAnnotation >) addAnnotation:(CLLocationCoordinate2D)coord title:(NSString *)title subTitle:(NSString *)subTitle repositionMap:(BOOL)yesOrNot;
-(void) removeAnnotations:(NSArray *)annotationArray;

- (void)zoomMapViewToFitAnnotations;
- (void) centerSelfLocation;

//mainlly called by demo mode
- (void) addInitialOverLays:(NSArray *)initialCrumbs initialAnnotations:(NSArray *)initialAnnotations;

@end
