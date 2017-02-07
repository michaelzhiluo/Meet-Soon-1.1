//
//  WeiJuPathShareVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsScrollVCtrl.h"
#import "WEPopoverController.h"

@class PathDCtrl, MapVCtrl, FriendsScrollVCtrl, WeiJuPathShareOptionVCtrl, PopOverTexiViewReminder, FriendData;

@interface WeiJuPathShareVCtrl : UIViewController <FriendSelected, WEPopoverControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, EKEventEditViewDelegate>

extern const int MAX_ATTENDEES;

@property (nonatomic, assign) BOOL demoMode;
//used for demo animation
@property (retain, nonatomic) NSTimer *demoPathTimer;
@property (nonatomic, assign) int demoPathCount;
@property (nonatomic, assign) int demoMinTime;
@property (retain, nonatomic) UIAlertView *demoReplayAlert;

@property (nonatomic, assign) BOOL hasSetUpP; //whether setupparticipants has finished
@property (nonatomic, assign) BOOL hasFailedAddr; //whether setupparticipants has failed to get addrbook
@property (nonatomic, assign) BOOL hasBeenLoaded; //whether the viewdidload has been called to set up map etc.
@property (nonatomic, assign) BOOL isBeingDisplayed; //whether it is the one being showed
@property (nonatomic, assign) BOOL hasBeenShutdown; 

@property (nonatomic, assign) int numberOfNewMessage; //whether the user has new msg from other used in the event
@property (nonatomic, assign) int numberOfSharings; //record how many people are sharing

@property (retain, nonatomic) EKEvent *selfEvent;
@property (assign, nonatomic) BOOL isOrganizer; //whether self is the organizer of this event (or there is no organizer)-: can hence edit the invitees

@property (retain, nonatomic) UIView *userActionCtrl;

@property (strong, nonatomic) IBOutlet UISwitch *locSwitch;
@property (retain, nonatomic) UIBarButtonItem *locSwitchBarBtn;
- (void)locSwitchChanged:(id)sender;
@property (nonatomic, assign) BOOL mySharingStatus;
@property (nonatomic, assign) float duration;
@property (retain, nonatomic) NSTimer *autoOffTimer;
@property (retain, nonatomic) NSTimer *progressTimer;

@property (retain, nonatomic) NSArray *currentToolbarItems;
@property (strong, nonatomic) IBOutlet UIView *progressViewContainer;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (assign, nonatomic) int progressLabel_Min;
@property (assign, nonatomic) int progressLabel_Sec;
@property (strong, nonatomic) IBOutlet UILabel *progressViewText;
@property (retain, nonatomic) UIBarButtonItem *pageCurlBarBtn;

@property (retain, nonatomic) MapVCtrl *mapVCtrl;
@property (retain, nonatomic) PathDCtrl *pathDCtrl;
@property (retain, nonatomic) FriendsScrollVCtrl *friendsScrollVCtrl;

@property (retain, nonatomic) NSMutableArray *weiJuParticipants;
@property (assign, nonatomic) BOOL foundMyself; //whether has foundmyself based on particiapnts' emails/urn
@property (retain, nonatomic) WeiJuParticipant *mySelf;

@property (retain, nonatomic) NSString *emailTobeValidated;
@property (retain, nonatomic) NSString *emailVerificationCode;

@property (assign, nonatomic) int countOfUnregisteredParticipants;
@property (assign, nonatomic) int currentSelectedParticipantIndex;
@property (assign, nonatomic) int addrDisplayMode;
@property (retain, nonatomic) NSString *allUserEmailString;


@property (retain, nonatomic) UIAlertView *addUserAlert;
@property (retain, nonatomic) UIAlertView *inviteUserAlert;
@property (retain, nonatomic) UIAlertView *selfIdentifyAlert;

@property (nonatomic, retain) WeiJuPathShareOptionVCtrl *optionVCtrl;

@property (nonatomic, retain) WEPopoverController* popoverCtrl;
@property (nonatomic, retain) PopOverTexiViewReminder* popoverReminder;

///////map view properties
@property (assign, nonatomic) CLLocationCoordinate2D centerCoordinate;
@property (assign, nonatomic) CLLocationDistance latitudinalMeters;
@property (assign, nonatomic) CLLocationDistance longitudinalMeters;
@property (retain, nonatomic) NSArray *initialCrumbs;
@property (retain, nonatomic) NSArray *initialAnnotations;

@property (assign, nonatomic) CLLocationCoordinate2D prevCoordinate; //my last updated coord
@property (assign, nonatomic) CLLocationDistance distanceTravelled; //track the distance travelled since last location update
@property (retain, nonatomic) NSDate *lastAnnotationUpdateTime; 
@property (retain, nonatomic) NSDate *lastLocationUpdateTime; 

@property (retain, nonatomic) NSMutableArray *cachedLocations;//each element is CLLocation 
//@property (retain, nonatomic) NSMutableArray *cachedLatitudes;//each element is a NSnumber object that contains the latitude of a coordinate, that has not sent out yet
//@property (retain, nonatomic) NSMutableArray *cachedLongitudes; //each element is a NSnumber object that contains the longitude of a coordinate

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil event:(EKEvent *)ekevent center:(CLLocationCoordinate2D) centerCoordinate latDistance:(CLLocationDistance) latitudinalMeters longDistance:(CLLocationDistance) longitudinalMeters crumbs:(NSArray *)initialCrumbs annotations:(NSArray *)initialAnnotations locSharing:(BOOL)onOrOff demoMode:(BOOL)demo;
-(void) setUpParticipants:(NSNumber*) updateOrNot; //0:NO, 1:YES
-(void) shutDown:(int)mode; //event is deleted, call this method to clean up


-(WeiJuParticipant *) weiJuParticipantForUserId:(NSString *)userId;

-(void) setUpDemoParticipants;
-(void) pageCurlUp;

-(void)participant:(WeiJuParticipant *)person/*ID:(NSString *)userID*/ locationChanged:(CLLocationCoordinate2D) coord annotationSubTitle:(NSString *)subTitle updateSenderStatus:(BOOL)updateStatus; //called by network thread
-(void) changeSharingStatusToOffFor:(WeiJuParticipant *)person; //(NSString *)invitorUserID;
-(void)displaySharingRequestFrom:(NSString *)invitorUserID;

-(void)updateUserFriendLocationInfo:(NSDictionary *)messageData;

-(void) refreshParticipantColorStatus:(FriendData *)friendData setColor:(BOOL)setColor; //called by FriendsListDCtrl

@end
