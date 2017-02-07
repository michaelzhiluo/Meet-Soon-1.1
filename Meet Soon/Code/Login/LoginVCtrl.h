//
//  LoginVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginVCtrl : UIViewController <MFMailComposeViewControllerDelegate>

- (IBAction)signInBtnPushed:(id)sender;
- (IBAction)pwdBtnPushed:(id)sender;
+(LoginVCtrl *)getSharedInstance;
- (IBAction)reportIssue:(id)sender;
-(void) setUpMainUSUI;
-(void)loginFailed:(NSString *)message;
@end
