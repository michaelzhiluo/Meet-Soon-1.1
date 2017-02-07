//
//  Utils.h
//  WeiJu
//
//  Created by Michael Luo on 2/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  WeiJuParticipant, FriendData;

@interface Utils : NSObject <UIAlertViewDelegate>

extern int launchCountry; //0: US, 1: China

+(Utils *)getSharedInstance;

- (void)alertNewVerson:(BOOL)alertProtocolVersion alertProtocolVersion:(BOOL)alertProtocolVersion;
- (BOOL) hasNewVersonFrom:(NSString *)curVer to:(NSString *)newVer;

+(void) displaySmartAlertWithTitle:(NSString *)title message:(NSString *)message noLocalNotif:(BOOL) noLocal;

+(BOOL) isOSLowerThan5;

+ (void)log:(NSString *)format, ...;
+(void) sendEmailToSupport:(id)delegate;

+(void) sendReferral:(id)delegate to:(NSArray *)recipients viaMedium:(int)smsOrEmail;

+ (BOOL) validateEmail:(NSString *)candidate;

+ (void) printClass:(id) object;
+ (void) printCoordinatesFor:(NSString *)prefix View:(UIView *) view;
+ (void) printSubViews:(NSString *)title For:(UIView *)topView;

+ (void) hideTabBar:(BOOL)hide For:(UITabBarController *)tCtrl;
+ (void) hideNavToolBar:(BOOL)hide For:(UINavigationController *)nCtrl;
+ (void) repositionView:(UIView *)targetView fromTop:(CGFloat)topOffset withinParent:(UIView *)superView;
+ (void) repositionView:(UIView *)targetView fromBottom:(CGFloat)bottomOffset withinParent:(UIView *)superView;
+ (void) repositionTableView:(UITableView *)targetView fromTop:(CGFloat)topOffset Height:(CGFloat)h;
+ (void) removeSubViews:(UIView *)parentView;

//动画之前\之中和之后的位置调整
+(void) shiftView:(UIView *)view changeInX:(float)x changeInY:(float)y  changeInWidth:(float)w changeInHeight:(float)h;
+(void) presetBeforeAnimationMoveFor:(UIView *)view changeInX:(float)x changeInY:(float)y  changeInWidth:(float)w changeInHeight:(float)h;
+(void) executeOnAnimationMoveFor:(UIView *)view changeInX:(float)x changeInY:(float)y changeInWidth:(float)w changeInHeight:(float)h;
+(void) resetXAfterAnimationMoveFor:(UIView *)view;

//create rounded rect button with border
+ (void) initCustomButton:(UIButton *)button title:(NSString *)text backgroundImage:(NSString *)imageName leftCapWidth:(float)left topCapHeight:(float)height cornerRadius:(float) radius borderWidth:(float)width;
+ (void) initCustomGradientButton:(UIButton *)button title:(NSString *)text image:(NSString *)imageName gradientStart:(UIColor *)startColor gradientEnd:(UIColor *)endColor cornerRadius:(float) radius borderWidth:(float)width;

+ (void) registerForKeyboardNotif:(id) obj;
+ (void) deRegisterForKeyboardNotif:(id) obj;

+ (NSString *) convertFutureDateToReadableFormat:(NSDate *)date;
+ (NSString *) convertPastDateToReadableFormat:(NSDate *)date;
+ (NSString *) getHourMinutes:(NSDate *)targetDate;
+ (NSString *) getAMPM:(NSDate *)targetDate;
+ (NSDate *) buildDateFromHour:(int)hour minutes:(int)min;

+ (CGSize) labelHeight:(NSString *) text forFontType:(UIFont *)font maxWidth:(int)width maxHeight:(int) height;

+ (NSDictionary *) getMyEmailFromEvent:(EKEvent *)event;
+ (BOOL) isUnprocessedEvent:(EKEvent *) event;
+ (NSString *) retrieveParticipantEmails:(EKEvent *)event notIn:(NSString *)list;

- (void) requestServerToAddEmail:(NSString *)emails callBack:(id)callback alertForFailure:(BOOL)alert;
+ (void) inviteFriend:(WeiJuParticipant *)person toSharePathForEvent:(EKEvent *)event from:(WeiJuParticipant *)myself;
+ (void) requestServerToValidateEmail:(NSString *)email withCode:(NSString *)validationCode callBack:(id)callback;
- (void) updateFriend:(NSString *)allUserEmailString firstTime:(int)firstTime /*withMyName:(NSString *)mySelfFullName*/ subtitle:(NSString *)subTitle locations:(NSArray *)cachedLocations forEvent:(EKEvent *)event;
+ (void) informSharingOffToFriend:(NSString *)allUserEmailString forEventID:(NSString *)eventIdentifier from:(WeiJuParticipant *)myself;

- (void) updateMyFriend:(NSString *)friendUserId friendHidden:(NSString *)friendHidden abRecordName:(NSString *)abRecordName abRecordFirstName:(NSString *)abRecordFirstName abRecordLastName:(NSString *)abRecordLastName abRecordNameNoCase:(NSString *)abRecordNameNoCase abRecordEmails:(NSString *)abRecordEmails;
- (void) updateMyFriend:(NSDictionary *)dicPara;

+ (FriendData *) addEmailOrURNToSelf:(WeiJuParticipant *)person;

-(UIImage *)rotateImage:(UIImage *)aImage orient:(int)orient;

- (NSString *) getEventProperty:(NSString *)input nilReplaceMent:(NSString *)replaceString;

@end
