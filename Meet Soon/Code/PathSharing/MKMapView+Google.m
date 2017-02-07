//
//  MKMapView+Google.m
//  WeiJu
//
//  Created by Michael Luo on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MKMapView+Google.h"

@implementation MKMapView (Google)

- (UIImageView*)googleLogo 
{	
	UIImageView *imgView = nil;	
	for (UIView *subview in self.subviews) 
	{		
		if ([subview isMemberOfClass:[UIImageView class]]) 
		{			
			imgView = (UIImageView*)subview;			
			break;		
		}	
	}	
	return imgView;
}

@end
