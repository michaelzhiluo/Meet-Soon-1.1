//
//  PopOverTexiViewReminder.h
//  WeiJu
//
//  Created by Michael Luo on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopOverTexiViewReminder : UIViewController

@property (assign, nonatomic) CGRect containerSize;
@property (strong, nonatomic) IBOutlet UITextView *textView;

- (void) setTextContent:(NSString *)textContent;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil size:(CGRect)rect;

@end
