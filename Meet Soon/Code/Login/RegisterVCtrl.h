//
//  ;
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterVCtrl : UIViewController <MFMailComposeViewControllerDelegate>

@property (retain, nonatomic) NSString * verificationCode, * userId;
@property (retain, nonatomic) UIAlertView * verificationAlert;
//@property (retain, nonatomic) UIAlertView * termOfServiceAlert;

- (IBAction)registerBtnPushed:(id)sender;

- (IBAction)reportIssue:(id)sender;

+ (RegisterVCtrl *)getSharedInstance;

- (void) verificationUserCode;
@end
