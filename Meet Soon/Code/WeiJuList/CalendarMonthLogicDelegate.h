//
//  CalendarLogicDelegate.h
//  Calendar
//
//  Created by Lloyd Bottomley on 29/04/10.
//  Copyright 2010 Savage Media Pty Ltd. All rights reserved.
//

@class CalendarMonthLogic;

@protocol CalendarMonthLogicDelegate

- (void)calendarLogic:(CalendarMonthLogic *)aLogic dateSelected:(NSDate *)aDate;
- (void)calendarLogic:(CalendarMonthLogic *)aLogic monthChangeDirection:(NSInteger)aDirection;

@end
