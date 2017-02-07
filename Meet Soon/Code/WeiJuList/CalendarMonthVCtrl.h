//
//  CalendarViewController.h
//  Calendar
//
//  Created by Lloyd Bottomley on 29/04/10.
//  Copyright Savage Media Pty Ltd 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CalendarMonthLogicDelegate.h"
#import "CalendarMonthVCtrlDelegate.h"

@class CalendarMonthLogic;
@class CalendarMonth;

@interface CalendarMonthVCtrl : UIViewController <CalendarMonthLogicDelegate> {
	id <CalendarMonthVCtrlDelegate> calendarViewControllerDelegate;
	
	CalendarMonthLogic *calendarLogic;
	CalendarMonth *calendarView;
	CalendarMonth *calendarViewNew;
	NSDate *selectedDate;

	UIButton *leftButton;
	UIButton *rightButton;
}

@property (nonatomic, retain) id <CalendarMonthVCtrlDelegate> calendarViewControllerDelegate;

@property (nonatomic, retain) CalendarMonthLogic *calendarLogic;
@property (nonatomic, retain) CalendarMonth *calendarView;
@property (nonatomic, retain) CalendarMonth *calendarViewNew;
@property (nonatomic, retain) NSDate *selectedDate;
@property (nonatomic, assign) CGRect containerSize;
@property (nonatomic, retain) UIButton *leftButton;
@property (nonatomic, retain) UIButton *rightButton;

- (void)animationMonthSlideComplete;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect;
@end

