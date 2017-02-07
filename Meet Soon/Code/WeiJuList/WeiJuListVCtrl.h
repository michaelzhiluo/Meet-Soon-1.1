//
//  WeiJuListVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeiJuCell.h"
#import "WEPopoverController.h"
#import "CalendarMonthVCtrlDelegate.h"

@class WeiJuListDCtrl, CrumbPath, PopOverTexiViewReminder;
@class CalEventVCtrl,WeiJuPathShareVCtrl,ChatDCtrl,CalendarMonthVCtrl,FriendsListDCtrl;

@interface WeiJuListVCtrl : UIViewController <UITableViewDataSource, UITableViewDelegate, WeiJuCellDelegate, WEPopoverControllerDelegate, EKEventViewDelegate, EKEventEditViewDelegate,CalendarMonthVCtrlDelegate>

@property (nonatomic, assign) BOOL demoMode; //for initial demo (take a look)
@property (nonatomic, assign) BOOL firstLaunch; //whether the view is launched for the first ttime -> scroll to today at viewdidappear

@property (nonatomic, retain) CalendarMonthVCtrl *calMouthVCtrl;
@property (nonatomic, retain) UISegmentedControl *dayMonth;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UIView *messageView;
@property (retain, nonatomic) UIViewController *currentVCtrl;

@property (nonatomic, retain) WEPopoverController* popoverCtrl;
@property (nonatomic, retain) PopOverTexiViewReminder* popoverReminder;

@property (retain, nonatomic) WeiJuCell *currentSelectedSharingCell;

@property (retain, nonatomic) NSMutableDictionary *weiJuPathShareVCtrls;
@property (nonatomic, retain) ChatDCtrl* chatDCtrl; //指向chatdctrl列表数据控制类

@property (nonatomic, retain) WeiJuPathShareVCtrl *currentWeiJuPathShareVCtrl;

@property (strong, nonatomic) UIButton * notifBtn;

@property (nonatomic, retain) WeiJuListDCtrl* weiJuListDCtrl; //指向weiju列表数据控制类
@property (nonatomic, retain) FriendsListDCtrl *friendsListDCtrl; //指向friend列表数据控制类

@property (nonatomic, retain) NSOperationQueue *checkEventQ;

+ (WeiJuListVCtrl *) getSharedInstance;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil demoOrNot:(BOOL)demo;
- (void) eventDataBaseChanged; //called by WeiJuListDCtrl when it receives event change notification
- (void) todayEventHasChanged:(EKEvent *)event; //event participants might have changed -> need to set up again
- (void) todayEventHasBeenDeleted:(EKEvent *)event;
- (void) gotoToday;

-(void) deletePVC:(WeiJuPathShareVCtrl *)pvc;
- (void) shutdownAllPVC;

- (WeiJuPathShareVCtrl *) selectWeiJuPathShareVCtrl:(EKEvent *)ekevent eventID:(NSString *)eventID display:(BOOL)
yesOrNot; //select a pVC and optionally display it (or simply update its data such as participants)

-(void) checkEventStatus:(NSMutableDictionary *)dict;

- (void) addBarButtonPressed;
- (void) settingBarButtonPressed;

//for weijuoptionvctrl to callback
- (void) curlUpBarButtonPressed;
- (void)calendarBtnPushed:(id)sender;
- (void)contactBtnPushed:(id)sender;
- (void)placeBtnPushed:(id)sender;
- (void)settingBtnPushed:(id)sender;

//to dislay or dismiss the "network unavailable view
- (void) displayNetworkMessageView;
- (void) dismissNetworkMessageView;

@end
