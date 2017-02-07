//
//  FirstLoginVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstLoginVCtrl : UIViewController


- (IBAction)pageControl:(id)sender;
- (IBAction)loginBtnPushed:(id)sender;
- (IBAction)registerBtnPushed:(id)sender;
- (IBAction)demoBtnPushed:(id)sender;


+ (FirstLoginVCtrl *)getCurrentInstance;
@end
