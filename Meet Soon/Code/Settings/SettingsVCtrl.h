//
//  SettingsVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsVCtrl : UIViewController <MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (retain, nonatomic) UIAlertView *logOffAlert;
@property (retain, nonatomic) UIAlertView * upgradeAlert;
@property (retain, nonatomic) UIAlertView * rateUsAlert;

- (void) changeUserName:(NSString *)name password:(NSString *)pwd newPassword:(NSString *)newPwd;

@end
