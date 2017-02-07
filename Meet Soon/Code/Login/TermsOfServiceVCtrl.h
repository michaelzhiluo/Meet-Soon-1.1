//
//  LoginVCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TermsOfServiceVCtrl : UIViewController <MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accpectAble:(bool)accpectAbleTmp;
@end
