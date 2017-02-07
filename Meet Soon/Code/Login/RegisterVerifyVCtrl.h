//
//  RegisterVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterVerifyVCtrl : UIViewController

@property (retain, nonatomic) NSString * verificationCode, * userId;
@property (retain, nonatomic) UIAlertView * verificationAlert;

- (IBAction)registerVerifyBtnPushed:(id)sender;

@end
