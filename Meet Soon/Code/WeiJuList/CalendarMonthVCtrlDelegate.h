//
//  CalendarViewControllerDelegate.h
//  Sorted
//
//  Created by Lloyd Bottomley on 30/04/10.
//  Copyright 2010 Savage Media Pty Ltd. All rights reserved.
//

@class CalendarMonthVCtrl;

@protocol CalendarMonthVCtrlDelegate

- (void)selectedDayInMonthCalendar:(CalendarMonthVCtrl *)aCalendarViewController dateDidChange:(NSDate *)aDate;

@end
