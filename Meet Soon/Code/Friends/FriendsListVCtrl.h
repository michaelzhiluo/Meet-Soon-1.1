//
//  FriendsListVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsScrollVCtrl.h"

@class FriendsListDCtrl, FriendsScrollVCtrl, FriendDetailVCtrl;

@interface FriendsListVCtrl : UIViewController <UISearchBarDelegate,UISearchDisplayDelegate,UIScrollViewDelegate,UITableViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UITableViewDataSource, FriendSelected>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, retain) UISwipeGestureRecognizer *swipeGestureRecognizerRight;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeGestureRecognizerLeft;

@property (retain, nonatomic) UISegmentedControl *listOption;
@property (nonatomic, retain) NSArray *indexPaths;

@property (nonatomic, retain) FriendsListDCtrl* friendsListDCtrl; //指向friends列表数据控制类
@property (nonatomic, retain) FriendsScrollVCtrl* friendsScrollVCtrl;

@property (strong, nonatomic) IBOutlet UITableViewCell *friendsVCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *contactsVCell;


@property (nonatomic, retain)  NSString *viewType;
@property (nonatomic, retain)  NSMutableDictionary *dictionary;
@property (nonatomic, retain)  UILocalizedIndexedCollation *collation;

@property (nonatomic, retain) NSOperationQueue *loadAddrBookQ;
@property (nonatomic, retain) NSOperationQueue *loadImageQ;
@property (nonatomic, assign) BOOL isBeingDisplayed;

@property (nonatomic, retain) FriendDetailVCtrl *fDetailVCtrl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil type:(NSString *)type;
+ (FriendsListVCtrl *)getSharedInstance;

- (void) checkButtonTapped:(id)sender event:(id) event;

//- (void) startAddressBookSearch;

- (void)syncWithServerDone;

- (void) startSearch;

@end
