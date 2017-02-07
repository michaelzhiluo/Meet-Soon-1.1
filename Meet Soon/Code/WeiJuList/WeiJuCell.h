//
//  WeiJuCell.h
//  WeiJu
//
//  Created by Michael Luo on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeiJuData, CalEventVCtrl;

@protocol WeiJuCellDelegate;

@interface WeiJuCell : UITableViewCell
//they have to be extern to be used by weijuistvctrl
//extern const int CELL_MAP_BTN;
//extern const int CELL_SHARE_BTN;

extern const int CAL_DAYVIEW_EVENT_WIDTH;
extern const int CAL_DAYVIEW_EVENT_HEIGHT; 
extern const int CAL_DAYVIEW_EVENT_LEFTMARGIN; 

//extern const int CELL_DISPLAY_MODE_EVENT;
//extern const int CELL_DISPLAY_MODE_SHARE;

@property (retain, nonatomic) id <WeiJuCellDelegate> delegate;
@property (assign, nonatomic) int displayMode; //CAL_EVENT_MODE_STATIC, etc.

@property (retain, nonatomic) CAShapeLayer *shapeLayer; //for dashed line drawing

@property (retain, nonatomic) CalEventVCtrl *calEventVCtrl;
@property (retain, nonatomic) UILabel *progressDescription;
@property (retain, nonatomic) UIProgressView *progressView;
@property (retain, nonatomic) UILabel *progressText;

- (id) initWithDelegate:(id)delegate;

- (IBAction)shareBtnPushed:(id)sender;

- (void) setSubject:(NSString *)subj place:(NSString *)place startTime:(NSDate *)time; //called by weijulistv to setup view's value
- (void) toggleMapMode:(BOOL)yesOrNo center:(CLLocationCoordinate2D)centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters annotation:(id < MKAnnotation >)initialAnnotation;// crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations;
- (void) ensureToShowEventContent; //called to ensure the content view is dispayed/not hidden due to map animation stopped in the middle

- (void) setAcceptanceStatusBoundary:(BOOL) accepted;

- (void) showProgressView:(float)prog duration:(int)total;
-(void) removeProgreeView;
-(void) displayShareBtn:(BOOL)yesOrNo;
-(void) setBadge:(int)newMsg;
- (void) setCellColor:(CGColorRef)cgColor;
- (void) setStrike:(BOOL)strike;

-(CGRect) getShareBtnRect;

@end

@protocol WeiJuCellDelegate
- (void) notifBtnPushed:(WeiJuCell *)cell;
- (void) shareBtnPushed:(WeiJuCell *)cell;
@end
