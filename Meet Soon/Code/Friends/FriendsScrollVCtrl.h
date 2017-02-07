//
//  FriendsScrollVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeiJuParticipant;

@protocol FriendSelected <NSObject>
-(void) friendSelected:(WeiJuParticipant *) person;
-(void) friendLongPressed:(WeiJuParticipant *) person;
@end

@interface FriendsScrollVCtrl : UIViewController

@property (nonatomic, assign) CGRect containerSize;

extern int const FRIEND_SCROLL_LIST_MODE_CONTACT;
extern int const FRIEND_SCROLL_LIST_MODE_MAP;

//extern int const FRIEND_SCROLL_LIST_STAUS_ACCEPT;
//extern int const FRIEND_SCROLL_LIST_STAUS_DECLINE;
//extern int const FRIEND_SCROLL_LIST_STAUS_UNDECIDED;


@property (strong, nonatomic) id <FriendSelected> delegate;

@property (nonatomic, assign) int mode; //0 - contact book, 1 - mapview
@property (nonatomic, assign) int numberOfFriends;
@property (nonatomic, assign) int selectedFriend;
@property (nonatomic, retain) NSMutableArray *friendsViews;
@property (nonatomic, retain) NSMutableArray *friendsObjects;

@property (nonatomic, retain) UIScrollView *scrollV;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil rect:(CGRect)rect mode:(int)displayMode friends:(NSArray *)friends callBack:(id) callBackTarget;
- (void) addFriendViewAndObject:(WeiJuParticipant *)person;
- (void) removeFriendViewAndObject:(WeiJuParticipant *)person;
- (void) updateFriendList:(NSArray *)friendsObjects;

- (void) setIconFor:(WeiJuParticipant *)person status:(int)mode;

- (void) setColorFor:(WeiJuParticipant *)person color:(UIColor *)frameColor exclusive:(BOOL) yesOrNo;

-(void) setBadgeForFriend:(WeiJuParticipant *)person;
-(void) setImageForFriend:(WeiJuParticipant *)person;
-(void) setNameForFriend:(WeiJuParticipant *)person;

@end
