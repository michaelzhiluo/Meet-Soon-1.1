//
//  MyAccountVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 9/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingsVCtrl;

@interface MyAccountVCtrl : UIViewController

@property (retain, nonatomic)  SettingsVCtrl *delegate;

@property (strong, nonatomic) IBOutlet UITextField *userNameTF;
@property (strong, nonatomic) IBOutlet UITextField *oldPwdTF;
@property (strong, nonatomic) IBOutlet UITextField *pwdTF1;
@property (strong, nonatomic) IBOutlet UITextField *pwdTF2;

+(MyAccountVCtrl *)getSharedInstance;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil changeType:(NSString *)changeTypeTemp;
- (void) cancel:(BOOL)isSuccess;
@end
