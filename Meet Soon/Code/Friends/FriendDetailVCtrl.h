//
//  FriendDetailVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FriendData,EventHistoryListDCtrl;

@interface FriendDetailVCtrl : UIViewController <UITableViewDelegate, UITableViewDataSource,UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *personImageView;
@property (retain, nonatomic) FriendData *friend;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *eventHistoryVCtrlCell;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeGestureRecognizerRight;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeGestureRecognizerLeft;
@property (retain, nonatomic) EventHistoryListDCtrl *eventHistoryListDCtrl;

@property (nonatomic, assign) BOOL isBeingDisplayed;

- (IBAction)clearHistory:(id)sender;

- (void) updateImageView;

-(void) takeALooklBarButtonPressed;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil friendData:(FriendData *)friendData;
@end
