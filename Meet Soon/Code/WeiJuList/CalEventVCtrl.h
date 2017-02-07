//
//  CalEventVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class  MapVCtrl;

@interface CalEventVCtrl : UIViewController

extern const int CAL_EVENT_MODE_STATIC;
extern const int CAL_EVENT_MODE_DYNAMIC;
extern const int CAL_EVENT_MODE_MAP;

@property (nonatomic, assign) CGRect containerSize;
@property (nonatomic, assign) int calEventMode; //0:static, 1:mapview/normview animation
@property (nonatomic, assign) int calEventMapAnimationMode; //0:shift from bottom up, 1:flip
@property (nonatomic, assign) int calEventCurrentView; //0:normal eventview, 1:mapview
@property (nonatomic, assign) BOOL runAnimation;
@property (nonatomic, retain) NSTimer *animationTimerForMap;

@property (retain, nonatomic) MapVCtrl *mapVCtrl;

///////event static/normal view properties
@property (retain, nonatomic) NSDate *eventStartTime;
@property (retain, nonatomic) NSString *eventSubject;
@property (retain, nonatomic) NSString *eventPlace;

///////event map view properties
@property (assign, nonatomic) CLLocationCoordinate2D centerCoordinate;
@property (assign, nonatomic) CLLocationDistance latitudinalMeters;
@property (assign, nonatomic) CLLocationDistance longitudinalMeters;
//@property (retain, nonatomic) NSArray *initialCrumbs;
//@property (retain, nonatomic) NSArray *initialAnnotations;
@property (retain, nonatomic) id < MKAnnotation > initialAnnotation;

- (void) setSubject:(NSString *)subj place:(NSString *)place startTime:(NSDate *)time; //called by weijulistv to setup view's value
- (void) toggleMapMode:(BOOL)yesOrNo center:(CLLocationCoordinate2D)centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters annotation:(id < MKAnnotation >)initialAnnotation;// crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations;
- (void) ensureToShowEventContent; //called to ensure the content view is dispayed/not hidden due to map animation stopped in the middle

- (void) setStrike:(BOOL)strike; //called by weijucell to set the strikethorugh for cancelled event

- (void) setMapViewCenter:(CLLocationCoordinate2D)centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect displayMode:(int) mode;
- (void) toggleEventAnimation:(BOOL)yesOrNo;

- (void) mapTapped:(MapVCtrl *)mapVCtrl; //called by CalEventMapVCtrl
@end
