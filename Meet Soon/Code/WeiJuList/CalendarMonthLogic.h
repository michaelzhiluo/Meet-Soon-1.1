//
//  CalendarLogic.h
//  Calendar
//
//  Created by Lloyd Bottomley on 29/04/10.
//  Copyright 2010 Savage Media Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CalendarMonthLogicDelegate.h"

@interface CalendarMonthLogic : NSObject {
	id <CalendarMonthLogicDelegate> calendarLogicDelegate;
	NSDate *referenceDate;
}

@property (nonatomic, retain) id <CalendarMonthLogicDelegate> calendarLogicDelegate;
@property (nonatomic, retain) NSDate *referenceDate;

- (id)initWithDelegate:(id <CalendarMonthLogicDelegate>)aDelegate referenceDate:(NSDate *)aDate;

+ (NSDate *)dateForToday;
+ (NSDate *)dateForWeekday:(NSInteger)aWeekday 
					onWeek:(NSInteger)aWeek 
				   ofMonth:(NSInteger)aMonth 
					ofYear:(NSInteger)aYear;
+ (NSDate *)dateForWeekday:(NSInteger)aWeekday onWeek:(NSInteger)aWeek referenceDate:(NSDate *)aReferenceDate;

- (NSInteger)indexOfCalendarDate:(NSDate *)aDate;
- (NSInteger)distanceOfDateFromCurrentMonth:(NSDate *)aDate;

- (void)selectPreviousMonth;
- (void)selectNextMonth;

@end
