//
//  WeiJuPathShareOptionVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeiJuPathShareVCtrl;

@interface WeiJuPathShareOptionVCtrl : UIViewController <UIScrollViewDelegate>

@property (nonatomic, retain) WeiJuPathShareVCtrl *delegate;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeGestureRecognizerRight;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeGestureRecognizerLeft;
@property (strong, nonatomic) IBOutlet UISegmentedControl *timerSegCtrl;
- (IBAction)timerSegCtrlSelected:(id)sender;

@end
