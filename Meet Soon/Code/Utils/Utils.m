//
//  Utils.m
//  WeiJu
//
//  Created by Michael Luo on 2/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Utils.h"
#import "QLog.h"
#import "WeiJuManagedObjectContext.h"
#import "DataFetchUtil.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuParticipant.h"
#import "WeiJuPathShareVCtrl.h"
#import "FriendData.h"
#import "WeiJuNetWorkClient.h"
#import "ChatDCtrl.h"
#import "WeiJuMessage.h"
#import "DESUtils.h"
#import "FileOperationUtils.h"
#import "WeiJuListDCtrl.h"

@implementation Utils

static Utils *sharedInstance;

int launchCountry=0;
BOOL _enabled;// main thread write, any thread read

+(Utils *)getSharedInstance
{
    if(sharedInstance == nil){
        sharedInstance = [[Utils alloc] init];
    }
    return sharedInstance;
}

+(BOOL) isOSLowerThan5
{
	NSString *reqSysVer = @"4.9"; 
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
		return NO;
	else 
		return YES;
}

+ (void) printClass:(id) object
{
    printf("Class name is %s\n\n", [NSStringFromClass([object class]) UTF8String]);  
}

+ (void) printCoordinatesFor:(NSString *)prefix View:(UIView *) view
{
    if(prefix!=nil)
        printf("%s: ", [prefix UTF8String]);
    else
        printf("%s: ", "-");
    
    printf("%s, tag=%d : %s\n", [NSStringFromCGRect(view.frame) UTF8String], view.tag,[NSStringFromClass([view class]) UTF8String]);
}

+ (void) printSubViews:(NSString *)title For:(UIView *)topView
{
    NSArray *subViews = topView.subviews;
    
    printf("Details for %s:\nTop view=", [title UTF8String]);
    
    [Utils printCoordinatesFor:NSStringFromClass([topView class]) View: topView];
    
    printf("sub views:\n");
    for(int i=0; i<[subViews count];i++)
    {
        UIView *sub = (UIView *)[subViews objectAtIndex:i];
        [Utils printCoordinatesFor:NSStringFromClass([sub class]) View: sub];
        //printf("tag=%d\n", sub.tag);
    }
    printf("\n");
}

+ (void) hideTabBar:(BOOL)hide For:(UITabBarController *)tCtrl
{
    NSArray *subViews = tCtrl.view.subviews;
    UIView * resizedView = [subViews objectAtIndex:0];
    
    if([resizedView isKindOfClass:[UITabBar class]])
        resizedView = [subViews objectAtIndex:1];
    
    if(hide){
        if(tCtrl.tabBar.hidden==YES)
            return;
        tCtrl.tabBar.hidden=YES;
        resizedView.frame = CGRectMake(resizedView.frame.origin.x, resizedView.frame.origin.y, resizedView.frame.size.width, resizedView.frame.size.height+tCtrl.tabBar.frame.size.height);
    }
    else{
        if(tCtrl.tabBar.hidden==NO)
            return;
        tCtrl.tabBar.hidden=NO;
        resizedView.frame = CGRectMake(resizedView.frame.origin.x, resizedView.frame.origin.y, resizedView.frame.size.width, resizedView.frame.size.height-tCtrl.tabBar.frame.size.height);
    }    
}

+ (void) hideNavToolBar:(BOOL)hide For:(UINavigationController *)nCtrl
{

    //[nCtrl setToolbarHidden:hide];
	if(hide)
    {
		if(nCtrl.toolbarHidden==NO)
			[nCtrl setToolbarHidden:YES];
    }
    else {
		if(nCtrl.toolbarHidden)
			[nCtrl setToolbarHidden:NO];
    }
}

+ (void) repositionView:(UIView *)targetView fromTop:(CGFloat)topOffset withinParent:(UIView *)superView
{
    //CGRect superFrame = superView.bounds;
    CGRect barFrame = targetView.frame;
    
    //[Utils printCoordinatesFor:@"old coord" View:targetView];
    
    targetView.frame = CGRectMake(barFrame.origin.x, topOffset, barFrame.size.width, barFrame.size.height);
    
    //[Utils printCoordinatesFor:@"new coord" View:targetView];
}

+ (void) repositionView:(UIView *)targetView fromBottom:(CGFloat)bottomOffset withinParent:(UIView *)superView
{
    CGRect superFrame = superView.bounds;
    CGRect barFrame = targetView.frame;
    
    //[Utils printCoordinatesFor:@"old coord" View:targetView];
    
    targetView.frame = CGRectMake(barFrame.origin.x,superFrame.size.height-bottomOffset-barFrame.size.height, barFrame.size.width, barFrame.size.height);
    
    //[Utils printCoordinatesFor:@"new coord" View:targetView];
}

+ (void) repositionTableView:(UITableView *)targetView fromTop:(CGFloat)topOffset Height:(CGFloat)h
{
    CGRect bound = targetView.bounds;
        
    //bound.size.height = h;
    targetView.bounds = CGRectMake(bound.origin.x, bound.origin.y, bound.size.width, h);
    targetView.frame = CGRectMake(bound.origin.x, topOffset, bound.size.width, bound.size.height);
}

+ (CGSize) labelHeight:(NSString *) text forFontType:(UIFont *)font maxWidth:(int)width maxHeight:(int) height
{
	CGSize maximumLabelSize = CGSizeMake(width,  height);
	CGSize expectedLabelSize = [text sizeWithFont:font constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap]; 
	return expectedLabelSize;
}


+ (void) removeSubViews:(UIView *)parentView
{
	NSArray *subViews = parentView.subviews;
	//[Utils printSubViews:@"to remove" For:parentView];
	if([subViews count]>0)
		for(int i=0;i<[subViews count];i++)
		{
			//printf("Remove:\n");
			//[Utils printClass:[subViews objectAtIndex:i] ];
			[[subViews objectAtIndex:i] removeFromSuperview];
		}
}

//create rounded rect button with border
+ (void) initCustomButton:(UIButton *)button title:(NSString *)text backgroundImage:(NSString *)imageName leftCapWidth:(float)left topCapHeight:(float)height cornerRadius:(float) radius borderWidth:(float)width
{
	if(button==nil)
		return;
	if(imageName!=nil && imageName.length>0)
		[button setBackgroundImage:[[UIImage imageNamed:imageName] stretchableImageWithLeftCapWidth:left topCapHeight:height] forState:UIControlStateNormal];
    button.layer.cornerRadius = radius;
    //button.layer.masksToBounds = YES;
    button.layer.borderWidth = width;
    //初始化按钮的文字
	if(text!=nil)
		[button setTitle:text forState:UIControlStateNormal];

}

+ (void) initCustomGradientButton:(UIButton *)button title:(NSString *)text image:(NSString *)imageName gradientStart:(UIColor *)startColor gradientEnd:(UIColor *)endColor cornerRadius:(float) radius borderWidth:(float)width
{
	if(button==nil)
		return;
	
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient = [CAGradientLayer layer];
    gradient.frame = button.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];
    [button.layer insertSublayer:gradient atIndex:0];
	//button的imageview不能是nil
	if(imageName!=nil)
	{
		[button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
		[button bringSubviewToFront:button.imageView];
	}
	
    button.layer.cornerRadius = radius;
    button.layer.masksToBounds = YES;
    button.layer.borderWidth = width;
    //初始化按钮的文字
	if(text!=nil)
		[button setTitle:text forState:UIControlStateNormal];

}

#pragma mark - 动画之前\之中和之后的位置调整
+(void) shiftView:(UIView *)view changeInX:(float)x changeInY:(float)y  changeInWidth:(float)w changeInHeight:(float)h
{
	view.frame = CGRectMake(view.frame.origin.x+x, view.frame.origin.y+y, view.frame.size.width+w, view.frame.size.height+h);
}

+(void) presetBeforeAnimationMoveFor:(UIView *)view changeInX:(float)x changeInY:(float)y  changeInWidth:(float)w changeInHeight:(float)h
{
	view.frame = CGRectMake(view.frame.origin.x+x, view.frame.origin.y+y, view.frame.size.width+w, view.frame.size.height+h);
}
+(void) executeOnAnimationMoveFor:(UIView *)view changeInX:(float)x changeInY:(float)y  changeInWidth:(float)w changeInHeight:(float)h
{
	view.frame = CGRectMake(view.frame.origin.x+x, view.frame.origin.y+y, view.frame.size.width+w, view.frame.size.height+h);
}
+(void) resetXAfterAnimationMoveFor:(UIView *)view
{
	view.frame = CGRectMake(0, view.frame.origin.y, view.frame.size.width, view.frame.size.height);	
}

#pragma keyboard management
+ (void) registerForKeyboardNotif:(id) obj 
{
	[Utils deRegisterForKeyboardNotif:obj]; //remove first, as sometimes, might have added the notif already, if not removed, two notif will be sent
	
    [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

+ (void) deRegisterForKeyboardNotif:(id) obj
{
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - 时间管理
+ (NSString *) convertFutureDateToReadableFormat:(NSDate *)targetDate
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm"];

	NSDate *now = [NSDate date];
	
	NSCalendar *usersCalendar = [NSCalendar autoupdatingCurrentCalendar];//[[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
	[usersCalendar setFirstWeekday:2];//一周从周一开始,2代表周一
	
	NSDateComponents *componentsTarget = [usersCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekOfYearCalendarUnit) fromDate:targetDate];
	NSDateComponents *componentsNow = [usersCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit| NSWeekOfYearCalendarUnit) fromDate:now];

	NSInteger yearTarget = [componentsTarget year];
	NSInteger monthTarget = [componentsTarget month];
	NSInteger dayTarget = [componentsTarget day];

	NSInteger yearNow = [componentsNow year];
	NSInteger monthNow = [componentsNow month];
	NSInteger dayNow = [componentsNow day];

	if(yearTarget==yearNow && monthNow==monthTarget && dayNow==dayTarget)
	{
		//今天
		return [[formatter stringFromDate:targetDate] stringByAppendingString:@" today"];
	}
	
	//建立明天的date
	NSDateComponents *component= [[NSDateComponents alloc] init];
	[component setDay:1];
	NSDate *next = [usersCalendar dateByAddingComponents:component toDate:now options:0];
	component= [usersCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:next];
	if(yearTarget==[component year] && [component month]==monthTarget && [component day]==dayTarget)
	{
		//明天
		return [[formatter stringFromDate:targetDate] stringByAppendingString:@" tomorrow"];
	}
	
	//后天
	component= [[NSDateComponents alloc] init];
	[component setDay:2];
	next = [usersCalendar dateByAddingComponents:component toDate:now options:0];
	component= [usersCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:next];
	if(yearTarget==[component year] && [component month]==monthTarget && [component day]==dayTarget)
	{
		//后天
		return [[formatter stringFromDate:targetDate] stringByAppendingString:@" the day after tomorrow"];
	}
	
	if([Utils isOSLowerThan5]==NO) //ios5.x
	{
		//同一周
		if(yearTarget==yearNow && [componentsNow weekOfYear]==[componentsTarget weekOfYear])
		{
			NSString*tmp= [[formatter stringFromDate:targetDate] stringByAppendingString:@" this "];
			[formatter setDateFormat:@"EEEE"];//返回星期几
			return [tmp stringByAppendingString:[formatter stringFromDate:targetDate]];
		}
		
		//下周
		if(yearTarget==yearNow && ([componentsNow weekOfYear]+1)==[componentsTarget weekOfYear])
		{
			NSString*tmp= [[formatter stringFromDate:targetDate] stringByAppendingString:@" next "];
			[formatter setDateFormat:@"EEEE"];//返回星期几
			return [tmp stringByAppendingString:[formatter stringFromDate:targetDate]];
		}
	
		[formatter setDateFormat:@"HH:mm 'on' MM'/'dd"];
		return [formatter stringFromDate:targetDate];
	}
	else { //ios4.x
		[formatter setDateFormat:@"HH:mm 'on' MM'/'dd '('"];
		NSString *result = [formatter stringFromDate:targetDate];
		[formatter setDateFormat:@"EEEE"];//返回星期几
		result = [result stringByAppendingString:[formatter stringFromDate:targetDate]];
		return [result stringByAppendingString:@")"];
	}
	//printf("%d %d\n", day, weekday);
}

+ (NSString *) convertPastDateToReadableFormat:(NSDate *)targetDate
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm"];
	
	NSDate *now = [NSDate date];
	
	NSCalendar *usersCalendar = [NSCalendar autoupdatingCurrentCalendar];//[[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
	[usersCalendar setFirstWeekday:2];//一周从周一开始,2代表周一
	
	NSDateComponents *componentsTarget = [usersCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekOfYearCalendarUnit) fromDate:targetDate];
	NSDateComponents *componentsNow = [usersCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit| NSWeekOfYearCalendarUnit) fromDate:now];
	
	NSInteger yearTarget = [componentsTarget year];
	NSInteger monthTarget = [componentsTarget month];
	NSInteger dayTarget = [componentsTarget day];
	
	NSInteger yearNow = [componentsNow year];
	NSInteger monthNow = [componentsNow month];
	NSInteger dayNow = [componentsNow day];
	
	if(yearTarget==yearNow && monthNow==monthTarget && dayNow==dayTarget)
	{
		//今天
		return [formatter stringFromDate:targetDate];
	}
	else {
		[formatter setDateFormat:@"MM/dd"];
		return [formatter stringFromDate:targetDate];
	}
}

+ (NSString *) getHourMinutes:(NSDate *)targetDate
{
	//NSCalendar *gregorian = [NSCalendar autoupdatingCurrentCalendar];//[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	//NSDateComponents *comps = [gregorian components:NSYearCalendarUnit |NSMonthCalendarUnit |NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit fromDate:targetDate];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"h:mm"];
	return [formatter stringFromDate:targetDate];
}

+ (NSString *) getAMPM:(NSDate *)targetDate
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"a"];
	return [formatter stringFromDate:targetDate];
}

+ (NSDate *) buildDateFromHour:(int)hour minutes:(int)min
{
	NSCalendar *gregorian = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *todayDate = [NSDate date];
	NSDateComponents *comps = [gregorian components:NSYearCalendarUnit |NSMonthCalendarUnit |NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit fromDate:todayDate];
	[comps setHour:hour];
	[comps setMinute:min];
	return [gregorian dateFromComponents:comps];
}

#pragma mark - event methods
+ (NSDictionary *) getMyEmailFromEvent:(EKEvent *)event
{
	NSString *organizerString;
	NSString *selfString;
	NSString *emailString;
	NSRange selfStringRange, emailStringRange;
	NSString *emailAddr, *URN;
	NSURL *url;
	BOOL isOrganizer = YES;
	
	if(event.organizer!=nil)
	{
		organizerString = [event.organizer description];
		/* EKOrganizer <0x2d3000> {UUID = D663503C-A2E4-453D-876B-BFF153665C24; name = Luo Michael; email = michael.luo@berkeley.edu; isSelf = 1} */
//		NSLog(@"%@ %@ %@",event.title, event.startDate, organizerString);
//		if([organizerString rangeOfString:@"francesnie@mshchina.com"].location!=NSNotFound)
//		{
//			NSLog(@"break: %@", event.attendees);
//		}
		organizerString = [organizerString substringFromIndex:[organizerString rangeOfString:@"{"].location];
		organizerString = [organizerString substringToIndex:[organizerString rangeOfString:@"}"].location];
		selfStringRange = [organizerString rangeOfString:@"isSelf"];
		if(selfStringRange.location!=NSNotFound)
		{
			selfString = [organizerString substringFromIndex:selfStringRange.location];
			
			if( [(NSString *)[[selfString componentsSeparatedByString:@";"] objectAtIndex:0] hasSuffix:@"1"] /*&& event.hasAttendees*/) //"isSelf = 1", and francesnie@mshchina.com type of event has no attendees; but reminder type of event on exchange also has attenddes as nil
			{
				url = event.organizer.URL;
				//until here: email addr is either email, or "urn:uuid:133596730"
				//NSLog(@"self url=%@", [url relativeString]);
				
				emailAddr = nil;
				URN = nil;
				if([[url scheme] isEqualToString:@"mailto"])
				{
					//found email!!
					emailAddr = [[[url relativeString] substringFromIndex:[@"mailto:" length]] lowercaseString];
					emailAddr = [@"(" stringByAppendingFormat:@"%@)",emailAddr];
				}
				else 
				{
					//URL doesnot contain email but UUID, hence need to find email from description
					URN = [[url relativeString] lowercaseString];
					URN = [@"(" stringByAppendingFormat:@"%@)",URN];
					
					emailStringRange = [organizerString rangeOfString:@"email"];
					if(emailStringRange.location!=NSNotFound)
					{
						emailString = [organizerString substringFromIndex:emailStringRange.location];
						emailString = (NSString *)[[emailString componentsSeparatedByString:@";"] objectAtIndex:0];
						emailAddr = [(NSString *)[[emailString componentsSeparatedByString:@" "] lastObject] lowercaseString];
						emailAddr = [@"(" stringByAppendingFormat:@"%@)",emailAddr];
						
						if(emailAddr!=nil && [emailAddr rangeOfString:@"@"].location==NSNotFound) //it is not a valid email address
							emailAddr=nil;
					}
					
				}
				
				/*//print to debug
				 if(emailAddr!=nil || URN!=nil) //found
				 {
				 //check and write to friendData here
				 if(emailAddr!=nil)
				 NSLog(@"email found: %@",emailAddr);
				 if(URN!=nil)
				 NSLog(@"URN found: %@",URN);
				 }
				 */
			}//found isself=1
			else 
				isOrganizer=NO;
		}//found isself
		else //must be error, play safe, set  isOrganizer to be NO
			isOrganizer=NO;
	}//organizer!=nil
	
	NSMutableDictionary *result;
	if (emailAddr!=nil || URN!=nil) 
	{
		result = [[NSMutableDictionary alloc] init];
		if(emailAddr!=nil)
			[result setValue:emailAddr forKey:@"email"];
		if(URN!=nil)
			[result setValue:URN forKey:@"urn"];
		if(isOrganizer)
			[result setValue:@"YES" forKey:@"isOrganizer"];
	}
	return result;
}

//whether this event is not initited by self, and has not responded yet
//organizer!=nil, && organizer' self!=1, && ekparticipant's me' status is not accept, decline or tentative
+ (BOOL) isUnprocessedEvent:(EKEvent *) event
{
	if (event.organizer==nil) {
		return NO;
	}
	
	NSString* organizerString = [event.organizer description];
	/* EKOrganizer <0x2d3000> {UUID = D663503C-A2E4-453D-876B-BFF153665C24; name = Luo Michael; email = michael.luo@berkeley.edu; isSelf = 1} */
	organizerString = [organizerString substringFromIndex:[organizerString rangeOfString:@"{"].location];
	organizerString = [organizerString substringToIndex:[organizerString rangeOfString:@"}"].location];
	NSRange selfStringRange = [organizerString rangeOfString:@"isSelf"];
	if(selfStringRange.location!=NSNotFound)
	{
		NSString *selfString = [organizerString substringFromIndex:selfStringRange.location];
		//NSLog(@"found self: %d %@", i, organizerString);
		if( [(NSString *)[[selfString componentsSeparatedByString:@";"] objectAtIndex:0] hasSuffix:@"1"] /*&& event.hasAttendees*/ ) //"isSelf = 1"
			return NO;
	}
	/*
	//NSDate *timeNow1 = [NSDate date];
	if([event.attendees count]>MAX_ATTENDEES) //loading .attendees can take 5 seconds for a 2000 users event
	{
		//if([event.title isEqualToString:@"GCR All hands "])
		//{
		//	NSLog(@"Organizer is %@", organizerString);
		//	NSLog(@"timelag %f", -[timeNow1 timeIntervalSinceNow]);
		//}
		return NO;
	}
	*/
	//now, walk thru the participants list, to find out if the participant's url matches my emails
	//EKParticipant *person;
	NSURL *url;
	NSString *email, *urn, *myEmails = [[WeiJuAppPrefs getSharedInstance] friendData].userEmails;
	
	//if([event.title rangeOfString:@"Vaccin"].location!=NSNotFound)
	//	NSLog(@"count is %@ %d %@",event.title, [event.attendees count], myEmails);
	
	//for (int i=0; i<MIN(MAX_ATTENDEES, [event.attendees count]);i++) 
	//for (int i=0; i<[event.attendees count];i++)
	for(EKParticipant * person in event.attendees)
	{
		//person = (EKParticipant *)[event.attendees objectAtIndex:i];
		url = person.URL;
	
		//if([event.title rangeOfString:@"Vaccin"].location!=NSNotFound)
		//	NSLog(@"person.participantStatus:%@ %d",[url relativeString], person.participantStatus);
		if([url relativeString]==nil)
			continue;
		
		if([[url scheme] isEqualToString:@"mailto"]) //it is email address
		{
			email = [[[url relativeString] substringFromIndex:[@"mailto:" length]] lowercaseString];
			if([myEmails rangeOfString:email].location!=NSNotFound) //found myself
			{
				if(person.participantStatus==EKParticipantStatusPending||person.participantStatus==EKParticipantStatusTentative/*||person.participantStatus==EKParticipantStatusUnknown*/)
					return YES;
				else 
					return NO;
			}
		}
		else //if([[url scheme] isEqualToString:@"urn"])
		{
			urn  = [[url relativeString] lowercaseString];
			if([myEmails rangeOfString:urn].location!=NSNotFound) //found myself
			{
				if(person.participantStatus==EKParticipantStatusPending||person.participantStatus==EKParticipantStatusTentative/*||person.participantStatus==EKParticipantStatusUnknown*/)
					return YES;
				else 
					return NO;
			}
			else 
			{
				//try URNemail
				NSString *ekdescription = [person description];
				ekdescription = [ekdescription substringFromIndex:[ekdescription rangeOfString:@"{"].location];
				ekdescription = [ekdescription substringToIndex:[ekdescription rangeOfString:@"}"].location];
				NSRange emailStringRange = [ekdescription rangeOfString:@"email"];
				if(emailStringRange.location!=NSNotFound)
				{
					NSString *URNEmail = [ekdescription substringFromIndex:emailStringRange.location];
					URNEmail = (NSString *)[[URNEmail componentsSeparatedByString:@";"] objectAtIndex:0];
					URNEmail = [(NSString *)[[URNEmail componentsSeparatedByString:@" "] lastObject] lowercaseString];
					if(URNEmail!=nil && [myEmails rangeOfString:URNEmail].location!=NSNotFound)
					{ 
						if(person.participantStatus==EKParticipantStatusPending||person.participantStatus==EKParticipantStatusTentative/*||person.participantStatus==EKParticipantStatusUnknown*/)
							return YES;
						else 
							return NO;
					}
				}
				
			}//end of urnemail
		}
	}
	
	//not found self
	return NO;
	
}

//called by wjldctrl, to get the participant emails for events that i am the organizer
+ (NSString *) retrieveParticipantEmails:(EKEvent *)event notIn:(NSString *)list //list contain the previously found participants
{
	if (event.organizer==nil) {
		return @"";
	}
	
	NSString* organizerString = [event.organizer description];
	/* EKOrganizer <0x2d3000> {UUID = D663503C-A2E4-453D-876B-BFF153665C24; name = Luo Michael; email = michael.luo@berkeley.edu; isSelf = 1} */
	organizerString = [organizerString substringFromIndex:[organizerString rangeOfString:@"{"].location];
	organizerString = [organizerString substringToIndex:[organizerString rangeOfString:@"}"].location];
	NSRange selfStringRange = [organizerString rangeOfString:@"isSelf"];
	if(selfStringRange.location!=NSNotFound)
	{
		NSString *selfString = [organizerString substringFromIndex:selfStringRange.location];
		//NSLog(@"found self: %d %@", i, organizerString);
		if( [(NSString *)[[selfString componentsSeparatedByString:@";"] objectAtIndex:0] hasSuffix:@"0"] ) //"isSelf = 0"
			return @""; //not organizer, no need to notify others since non-organizer can't really change the event
		
		//没必要,因为[event.attendees count]==0
		//if( [(NSString *)[[selfString componentsSeparatedByString:@";"] objectAtIndex:0] hasSuffix:@"1"] /*&& event.hasAttendees*/)
		//	return @""; //francesnie@mshchina.com type of event has no attendees
	}
	
	//now, walk thru the participants list, to find out if the participant's url matches my emails
	EKParticipant *person;
	NSURL *url;
	NSString *email, *urn, *myEmails = [[WeiJuAppPrefs getSharedInstance] friendData].userEmails;
	NSString *result=@"";
	for (int i=0; i<MIN(MAX_ATTENDEES,[event.attendees count]);i++) 
	{
		person = (EKParticipant *)[event.attendees objectAtIndex:i];
		url = person.URL;
		if([url relativeString]==nil)
			continue;
		
		if([[url scheme] isEqualToString:@"mailto"]) //it is email address
		{
			email = [[[url relativeString] substringFromIndex:[@"mailto:" length]] lowercaseString];
			if([myEmails rangeOfString:email].location==NSNotFound && [list rangeOfString:email].location==NSNotFound) //not myself
			{
				result = [result stringByAppendingFormat:@",%@",email];
			}
		}
		else //if([[url scheme] isEqualToString:@"urn"])
		{
			urn  = [[url relativeString] lowercaseString];
			if([myEmails rangeOfString:urn].location==NSNotFound && [list rangeOfString:urn].location==NSNotFound) //not myself
			{
				result = [result stringByAppendingFormat:@",%@",urn];
			}
			
			//now URNemail
			NSString *ekdescription = [person description];
			ekdescription = [ekdescription substringFromIndex:[ekdescription rangeOfString:@"{"].location];
			ekdescription = [ekdescription substringToIndex:[ekdescription rangeOfString:@"}"].location];
			NSRange emailStringRange = [ekdescription rangeOfString:@"email"];
			if(emailStringRange.location!=NSNotFound)
			{
				NSString *URNEmail = [ekdescription substringFromIndex:emailStringRange.location];
				URNEmail = (NSString *)[[URNEmail componentsSeparatedByString:@";"] objectAtIndex:0];
				URNEmail = [(NSString *)[[URNEmail componentsSeparatedByString:@" "] lastObject] lowercaseString];
				if(URNEmail!=nil && [myEmails rangeOfString:URNEmail].location==NSNotFound && [list rangeOfString:URNEmail].location==NSNotFound)
					result = [result stringByAppendingFormat:@",%@",URNEmail];
			}
		}
	}
	
	return result;
}

#pragma mark - message exchange
//tell server to add emails/URNs to my acct after scanning the event store
- (void) requestServerToAddEmail:(NSString *)emails callBack:(id)callback alertForFailure:(BOOL)alert
{	
	WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init]; 
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	[dic setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
	[dic setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"syncUserIds"];
	
	if(alert)
		[dic setObject:@"1" forKey:@"alertUploadEmailFail"];
	else 
		[dic setObject:@"0" forKey:@"alertUploadEmailFail"];
	
	[dic setObject:[DESUtils encryptUseDESDefaultKey:emails] forKey:@"ue"];
	[weiJuNetWorkClient requestData:@"userFriendsAction.uploadUserEmail" parameters:dic withObject:nil callbackInstance:callback callbackMethod:@"uploadSelfEmailsCallBack:"];
}

//ask a registered friend to start sharing (still use his url, not userID, as the server will query for the userID based on url)
+ (void) inviteFriend:(WeiJuParticipant *)person toSharePathForEvent:(EKEvent *)event from:(WeiJuParticipant *)myself
{
	NSString *friendURL;
	
	if(person.idType==0)
		friendURL = person.URN;
	else 
		friendURL = person.email;
	
	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
	/*
	NSArray *arrayFriendData = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",[[WeiJuAppPrefs getSharedInstance] userId]]];
	FriendData *me;
	if([arrayFriendData count] == 1){
		me = (FriendData *)[arrayFriendData objectAtIndex:0];
	}
	*/
	WeiJuMessage *message = (WeiJuMessage *)[dataFetchUtil createSavedObject:@"WeiJuMessage"];
	message.weiJuId = @"0"; //fixed
	message.sendUser = [[WeiJuAppPrefs getSharedInstance] friendData];
	message.sendTime = [NSDate date];
	message.isSendBySelf = @"1";
	message.messageRecipients = friendURL;
	message.messageType = [NSString stringWithFormat:@"%d", WEIJU_MSG_INVITE_TO_SHARE_PATH];
	
	NSString *title = [[[Utils alloc] init] getEventProperty:event.title nilReplaceMent:@"No title"];
	NSString *time = [[Utils getHourMinutes:event.startDate] stringByAppendingFormat:@" %@", [Utils getAMPM:event.startDate] ];
	
	message.messagePushAlert=[message.sendUser.userName stringByAppendingFormat:@" invites you to share your path for calendar event \"%@\" scheduled @ %@", title, time];
	message.isPushMessage=@"1";
	message.messageContentType = @"1"; //1 - text, 2 - picture
	//the following is key
	//message.messageContent = [NSString stringWithFormat:@"%@|%@",curProtoVer, eventID]; //[eventID stringByAppendingFormat:@"|%@", me.userId];//event id|sender userId is put here
	message.messageContent = [NSString stringWithFormat:@"%@", event.eventIdentifier];
	
	//[self saveCoreData]; //this will trigger chatDCtl to use WeiJuNetWorkClient to send
	[WeiJuManagedObjectContext save];

}

//ask server to initiate an email validation process
+ (void) requestServerToValidateEmail:(NSString *)email withCode:(NSString *)validationCode callBack:(id)callback
{
	WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init]; 
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	[dic setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
	[dic setObject:validationCode forKey:@"verificationCode"];
	[dic setObject:email forKey:@"relationEmail"];
	[dic setObject:[FileOperationUtils md5:[@"weijuCode#1" stringByAppendingFormat:@"%@%@",[[WeiJuAppPrefs getSharedInstance] userId],validationCode]]   forKey:@"token"];
	[weiJuNetWorkClient requestDataWithNoToken:@"loginAction.sendEmailToRelationEmail" parameters:dic withObject:nil callbackInstance:callback callbackMethod:@"createEmailBindingCallBack:"];
}

- (void) updateFriend:(NSString *)allUserEmailString firstTime:(int)firstTime /*withMyName:(NSString *)mySelfFullName*/ subtitle:(NSString *)subTitle locations:(NSArray *)cachedLocations forEvent:(EKEvent *)event
{
	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
	/*
	NSArray *arrayFriendData = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",[[WeiJuAppPrefs getSharedInstance] userId]]];
	FriendData *me;
	if([arrayFriendData count] == 1){
		me = (FriendData *)[arrayFriendData objectAtIndex:0];
	}
	*/
	WeiJuMessage *message = (WeiJuMessage *)[dataFetchUtil createSavedObject:@"WeiJuMessage"];
	message.weiJuId = @"0"; //fixed
	message.sendUser = [[WeiJuAppPrefs getSharedInstance] friendData];
	message.sendTime = [NSDate date];
	message.isSendBySelf = @"1";
	message.messageRecipients = allUserEmailString;
	message.messageType = [NSString stringWithFormat:@"%d", WEIJU_MSG_PATH_SHARE_UPDATE];
	if(firstTime==0) //not first time
	{
		message.messagePushAlert=[message.sendUser.userName stringByAppendingFormat:@"%@%@", @" has updated his/her path: ", subTitle];
		message.isPushMessage=@"0";
	}
	else 
	{
		NSString *title = [[[Utils alloc] init] getEventProperty:event.title nilReplaceMent:@"No title"];
		NSString *time = [[Utils getHourMinutes:event.startDate] stringByAppendingFormat:@" %@", [Utils getAMPM:event.startDate] ];
		message.messagePushAlert=[message.sendUser.userName stringByAppendingFormat:@" has started sharing path in calendar event \"%@\" scheduled @ %@", title, time];
		message.isPushMessage=@"1";
	}
	message.messageContentType = @"1"; //1 - text, 2 - picture
	//the following is key
	//message.messageContent = [NSString stringWithFormat:@"%@|%d", [[eventIdentifier componentsSeparatedByString:@":"] objectAtIndex:1], [cachedLocations count] ];
	//message.messageContent = [NSString stringWithFormat:@"%@|%@|%d|%d|",curProtoVer, event.eventIdentifier, firstTime, [cachedLocations count] ];
	message.messageContent = [NSString stringWithFormat:@"%@|%d|%d|", event.eventIdentifier, firstTime, [cachedLocations count] ];
	for (int i=0; i<[cachedLocations count]; i++) 
	{
		if(i == ([cachedLocations count]-1)){
			message.messageContent = [message.messageContent stringByAppendingFormat:@"%@,%@",[NSString stringWithFormat:@"%f", ((CLLocation *)[cachedLocations objectAtIndex:i]).coordinate.latitude], [NSString stringWithFormat:@"%f", ((CLLocation *)[cachedLocations objectAtIndex:i]).coordinate.longitude] ];//event id|sender userId is put here
		}else {
			message.messageContent = [message.messageContent stringByAppendingFormat:@"%@,%@#",[NSString stringWithFormat:@"%f", ((CLLocation *)[cachedLocations objectAtIndex:i]).coordinate.latitude], [NSString stringWithFormat:@"%f", ((CLLocation *)[cachedLocations objectAtIndex:i]).coordinate.longitude] ];//event id|sender userId is put here
		}
	}
	message.messageContent = [message.messageContent stringByAppendingFormat:@"|%@", subTitle];
	
    
	//[self saveCoreData]; //this will trigger WeiJuNetWorkClient
	[WeiJuManagedObjectContext save];
}

+ (void) informSharingOffToFriend:(NSString *)allUserEmailString forEventID:(NSString *)eventIdentifier from:(WeiJuParticipant *)myself
{
	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];
	NSArray *arrayFriendData = [dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userId == " stringByAppendingFormat:@"'%@'",[[WeiJuAppPrefs getSharedInstance] userId]]];
	FriendData *me;
	if([arrayFriendData count] == 1){
		me = (FriendData *)[arrayFriendData objectAtIndex:0];
	}
	
	WeiJuMessage *message = (WeiJuMessage *)[dataFetchUtil createSavedObject:@"WeiJuMessage"];
	message.weiJuId = @"0"; //fixed
	message.sendUser = me;
	message.sendTime = [NSDate date];
	message.isSendBySelf = @"1";
	message.messageRecipients = allUserEmailString;
	message.messageType = [NSString stringWithFormat:@"%d", WEIJU_MSG_PATH_SHARE_TURNED_OFF];
	message.messagePushAlert=[myself.fullName stringByAppendingFormat:@" %@",@"is no longer sharing path in calendar event "]; 
	message.isPushMessage=@"0"; //no need to push, because the color will tell the user - just like in MSN, no need to inform go-offline
	message.messageContentType = @"1"; //1 - text, 2 - picture
	//the following is key
	message.messageContent = eventIdentifier; //[eventID stringByAppendingFormat:@"|%@", me.userId];//event id|sender userId is put here
	
	//[self saveCoreData]; //this will trigger chatDCtl to use WeiJuNetWorkClient to send
	[WeiJuManagedObjectContext save];
}

- (void) updateMyFriend:(NSDictionary *)dicPara
{    
	WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init]; 
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	[dic setObject:[dicPara objectForKey:@"userId"] forKey:@"friendUserId"];
	[dic setObject:[dicPara objectForKey:@"hide"] == nil?@"":[dicPara objectForKey:@"hide"] forKey:@"friendHidden"];
	
    [dic setObject:[dicPara objectForKey:@"abRecordName"] == nil?@"":[dicPara objectForKey:@"abRecordName"] forKey:@"clientName"];
	[dic setObject:[dicPara objectForKey:@"abRecordFirstName"] == nil?@"":[dicPara objectForKey:@"abRecordFirstName"] forKey:@"clientFirstName"];
	[dic setObject:[dicPara objectForKey:@"abRecordLastName"] == nil?@"":[dicPara objectForKey:@"abRecordLastName"] forKey:@"clientLastName"];
	[dic setObject:[dicPara objectForKey:@"abRecordNameNoCase"] == nil?@"":[dicPara objectForKey:@"abRecordNameNoCase"] forKey:@"clientNoCaseName"];
	[dic setObject:[dicPara objectForKey:@"abRecordEmails"] == nil?@"":[dicPara objectForKey:@"abRecordEmails"] forKey:@"clientEmails"];
	
	[weiJuNetWorkClient requestData:@"userFriendsAction.updateUserFriend" parameters:dic withObject:nil callbackInstance:nil callbackMethod:nil];
}

- (void) updateMyFriend:(NSString *)friendUserId friendHidden:(NSString *)friendHidden abRecordName:(NSString *)abRecordName abRecordFirstName:(NSString *)abRecordFirstName abRecordLastName:(NSString *)abRecordLastName abRecordNameNoCase:(NSString *)abRecordNameNoCase abRecordEmails:(NSString *)abRecordEmails
{	
	WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init]; 
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:friendUserId forKey:@"friendUserId"];
	[dic setObject:friendHidden forKey:@"friendHidden"];
	
	if (abRecordName != nil) 
		[dic setObject:abRecordName forKey:@"clientName"];
	if (abRecordFirstName != nil) 
		[dic setObject:abRecordFirstName forKey:@"clientFirstName"];
	if (abRecordLastName != nil) 
		[dic setObject:abRecordLastName forKey:@"clientLastName"];
	if (abRecordNameNoCase != nil)
		[dic setObject:abRecordNameNoCase forKey:@"clientNoCaseName"];
	if (abRecordEmails != nil)
		[dic setObject:abRecordEmails forKey:@"clientEmails"];
	
	[weiJuNetWorkClient requestData:@"userFriendsAction.updateUserFriend" parameters:dic withObject:nil callbackInstance:nil callbackMethod:nil];
}

#pragma mark - core data related
//called when the server responds with positive msg that the user's submitted email addr has been validated: hence add to the core data
+ (FriendData *) addEmailOrURNToSelf:(WeiJuParticipant *)person
{
	DataFetchUtil *dataFetchUtil = [[DataFetchUtil alloc] init];

	FriendData *me = [[dataFetchUtil searchObjectArray:@"FriendData" filterString:[@"userID ==" stringByAppendingFormat:@"'%@'",[[WeiJuAppPrefs getSharedInstance] userId] ] ] objectAtIndex:0];
	
	if(person.idType==0)
	{
		if([me.userEmails rangeOfString:person.URN].location==NSNotFound)
			me.userEmails = [person.friendData.userEmails stringByAppendingFormat:@",%@",person.URN];
		if(person.URNEmail!=nil && [person.URNEmail rangeOfString:@"@"].location!=NSNotFound && [me.userEmails rangeOfString:person.URNEmail].location==NSNotFound)
			me.userEmails = [person.friendData.userEmails stringByAppendingFormat:@",%@",person.URNEmail];
	}
	else 
	{
		if([me.userEmails rangeOfString:person.email].location==NSNotFound)
			me.userEmails = [person.friendData.userEmails stringByAppendingFormat:@",%@",person.email];
	}
	
//	[Utils saveCoreData];
	[WeiJuManagedObjectContext save];
	
	return me;

}

- (NSString *) getEventProperty:(NSString *)input nilReplaceMent:(NSString *)replaceString
{
	if(input==nil||[input isEqualToString:@""])
		return replaceString;
	else
		return [NSString stringWithString:input];
}


#pragma mark - alerts
+(void) displaySmartAlertWithTitle:(NSString *)title message:(NSString *)message noLocalNotif:(BOOL) noLocal //if YES, don't do local notif in bg mode
{
	if((title==nil||[title isEqualToString:@""]) && (message==nil||[message isEqualToString:@""]))
	   return;
	
	UIApplicationState state = [UIApplication sharedApplication].applicationState;
	if(noLocal==NO && state == UIApplicationStateBackground)
	{
		UILocalNotification *notification=[[UILocalNotification alloc] init];
        if (notification!=nil) 
        {
            
            NSDate *now=[NSDate new];
			
            //notification.fireDate=[now addTimeInterval:period];
            //notification.fireDate = [now dateByAddingTimeInterval:10];
			notification.fireDate = now;
            notification.timeZone=[NSTimeZone defaultTimeZone];
            
			//notification.soundName = UILocalNotificationDefaultSoundName;//@"ping.caf";
            
			//notification.alertAction=@"Open"; //righ button value
            notification.alertBody = [NSString stringWithFormat:@"%@",[title stringByAppendingFormat:@": %@", message]];
            
            //NSDictionary* info = [NSDictionary dictionaryWithObject:uniqueCodeStr forKey:CODE];
            //notification.userInfo = info;
            
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];                  
        } 
	}
	else 
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title 
														message:message
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
	}
}

- (void)alertNewVerson:(BOOL)alertAppVersion alertProtocolVersion:(BOOL)alertProtocolVersion{
    if ([@"" isEqualToString:[[WeiJuAppPrefs getSharedInstance] newAppVer]]
        || [@"" isEqualToString:[[WeiJuAppPrefs getSharedInstance] newProtoVer]])
        return;
    
	if (alertAppVersion && [self hasNewVersonFrom:currentAppVersion to:[[WeiJuAppPrefs getSharedInstance] newAppVer] ] ) 
	{
        NSArray *nadArray = [[[WeiJuAppPrefs getSharedInstance] newAppVerData] componentsSeparatedByString:@"|"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Found New Version" message:[nadArray objectAtIndex:0] delegate:[Utils getSharedInstance] cancelButtonTitle:@"Remind Later" otherButtonTitles:@"Upgrade Now",nil];
        [alert show];
        return;
    }

    if (alertProtocolVersion && [self hasNewVersonFrom:curProtoVer to:[[WeiJuAppPrefs getSharedInstance] newProtoVer]])
	{
        NSArray *npdArray = [[[WeiJuAppPrefs getSharedInstance] newProtoVerData] componentsSeparatedByString:@"|"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Found New Version" message:[npdArray objectAtIndex:0] delegate:[Utils getSharedInstance] cancelButtonTitle:@"Remind Later" otherButtonTitles:@"Upgrade Now",nil];
        [alert show];
        return;
    }	    
}

- (BOOL) hasNewVersonFrom:(NSString *)curVer to:(NSString *)newVer
{
	if ([newVer isEqualToString:@""]) {
		return NO;
	}
	
	NSString *curMajor = [[curVer componentsSeparatedByString:@"."] objectAtIndex:0];
	NSString *newMajor = [[newVer componentsSeparatedByString:@"."] objectAtIndex:0];
	//NSLog(@"ver: %@ %@ %d %d", curMajor, newMajor, [curMajor compare:newMajor options:NSNumericSearch], NSOrderedAscending);
	if([curMajor compare:newMajor options:NSNumericSearch] == NSOrderedAscending)
		return YES;
	else if([curMajor compare:newMajor options:NSNumericSearch] == NSOrderedSame)
	{
		NSString *curMinor = [[curVer componentsSeparatedByString:@"."] objectAtIndex:1];
		NSString *newMinor = [[newVer componentsSeparatedByString:@"."] objectAtIndex:1];
		if([curMinor compare:newMinor options:NSNumericSearch] == NSOrderedAscending)
			return YES;
		else 
			return NO;
	}
	else //cur: 1.0, new: 0.2
		return NO;
	
	
}

//go to appstore to upgrade the software
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //@"itms://itunes.apple.com/gb/app/calendarium/id482136387?l=en&mt=8"
    if (buttonIndex == 1) {
        [DataFetchUtil saveButtonsEventRecord:@"1x"];
        NSArray *npdArray = [[[WeiJuAppPrefs getSharedInstance] newProtoVerData] componentsSeparatedByString:@"|"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[npdArray objectAtIndex:1]]];
    }
	else{
        [DataFetchUtil saveButtonsEventRecord:@"1w"];
    }
}

#pragma mark - alerts
+ (void)log:(NSString *)format, ...
{    
    @synchronized (self) 
	{ 
        va_list     argList;
        va_start(argList, format);
		
		if([[WeiJuAppPrefs getSharedInstance] logMode]==PRODUCTION_MODE)
		{
            [[QLog log] logWithFormat:format arguments:argList];
		}
		else if([[WeiJuAppPrefs getSharedInstance] logMode]==TEST_MODE)
		{
            [[QLog log] logWithFormat:format arguments:argList];
            NSLogv(format, argList);
		}
		else if([[WeiJuAppPrefs getSharedInstance] logMode]==DEVELOP_MODE)
		{
            NSLogv(format, argList);
		}
		
        va_end(argList);
    }
}

+(void) sendEmailToSupport:(id)delegate
{
	if([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		mailVC.mailComposeDelegate = delegate;
		[mailVC setToRecipients:[NSArray arrayWithObject:supportEmail]]; //customer support email
		
		if([[WeiJuAppPrefs getSharedInstance] friendData]!=nil && [[WeiJuAppPrefs getSharedInstance] friendData].userName!=nil)
			[mailVC setSubject:[@"Reporting issue from " stringByAppendingString:[[WeiJuAppPrefs getSharedInstance] friendData].userName]];
		else
			[mailVC setSubject:@"Reporting issue"];
		
		NSString *calAccess = @"YES";
		if([EKEventStore instancesRespondToSelector:@selector(requestAccessToEntityType:completion:)] && [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]!= EKAuthorizationStatusAuthorized)
			calAccess = @"NO";
		NSString *addrAccess = @"YES";
		if(ABAddressBookRequestAccessWithCompletion != NULL && ABAddressBookGetAuthorizationStatus()!=kABAuthorizationStatusAuthorized)
			addrAccess = @"NO";
		
		[mailVC setMessageBody:[NSString stringWithFormat:@"\n\n\nDevice Type: %@\niOS Version: %@ %@\nUser Login Email: %@ %@\nPush support: %d\nLocation enabled: %d\nCalendars: %@ %@\nContactBook:%@\nApp Version:%@/%@ %@/%@\n\nThe log below has no private location data, and is used only for identifying your issue. It is sent to us only when you choose to send out this email. You can also choose to delete the log before you send out the email but that will limit our ability to trace the issue for you.\n\nDebugging Logs:\n%@",[UIDevice currentDevice].localizedModel, [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, [[WeiJuAppPrefs getSharedInstance] friendData].userId, [[WeiJuAppPrefs getSharedInstance] friendData].userLogin, [[UIApplication sharedApplication] enabledRemoteNotificationTypes], [CLLocationManager locationServicesEnabled], [[WeiJuListDCtrl getSharedInstance] listOfAllCalendars], calAccess, addrAccess, currentAppVersion,[[WeiJuAppPrefs getSharedInstance] newAppVer], curProtoVer, [[WeiJuAppPrefs getSharedInstance] newProtoVer], [[QLog log].logEntries componentsJoinedByString:@"\n"] ] isHTML:NO];
		
		//[mailVC addAttachmentData:UIImagePNGRepresentation(screenShotImage) mimeType:@"image/png" fileName:@"iOS app screenshot"];
		
		[delegate presentViewController:mailVC animated:YES completion:nil];
	}
	else 
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your device can't send Email. Please go to iPhone's \"Settings\" to set up an Email account first."
														message:nil
													   delegate:nil 
											  cancelButtonTitle:@"Dismiss" 
											  otherButtonTitles:nil];
		[alert show];
	}
}

+(void) sendReferral:(id)delegate to:(NSArray *)recipients viaMedium:(int)smsOrEmail //0:SMS, 1: Email
{
	NSArray *npdArray = [[[WeiJuAppPrefs getSharedInstance] newAppVerData] componentsSeparatedByString:@"|"];
	NSString *content = [NSLocalizedString(@"REFER_MSG", nil) stringByAppendingFormat:@"%@",[npdArray objectAtIndex:1]];
	//NSString *content = @"Hi! I am using \"On My Way\", a simple but very useful iPhone utility that complements Calendar, enabling attendees of a Calendar event to continuously stream their paths to one another, with auto-off timer. No more frustrating guess on where is this guy:-) Download it at http://meetsoon.mobi/download";
	
	if(smsOrEmail==0)
	{
		if([MFMessageComposeViewController canSendText])
		{
			MFMessageComposeViewController *smsVC = [[MFMessageComposeViewController alloc] init];
			smsVC.messageComposeDelegate=delegate;
			smsVC.recipients = recipients;
			smsVC.body = content;
			[delegate presentViewController:smsVC animated:YES completion:nil];
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your device can't send SMS"
															message:nil
														   delegate:nil 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
			[alert show];
		}
	}
	else //email
	{
		if([MFMailComposeViewController canSendMail])
		{
			MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
			mailVC.mailComposeDelegate = delegate;
			[mailVC setToRecipients:recipients];
			[mailVC setSubject:NSLocalizedString(@"REFER_TITLE", nil)];
			[mailVC setMessageBody:content isHTML:YES];
			/*
			//now create the screen image to send with the email
			UIGraphicsBeginImageContext(self.view.bounds.size);
			//here, we can add more info to the view, such as turn on sharing, add title and location info in a subview etc.
			[self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
			UIImage *screenShotImage = UIGraphicsGetImageFromCurrentImageContext();
			//then, remove the added subview view
			UIGraphicsEndImageContext();
			
			[mailVC addAttachmentData:UIImagePNGRepresentation(screenShotImage) mimeType:@"image/png" fileName:@"iOS app screenshot"];
			*/
			[delegate presentViewController:mailVC animated:YES completion:nil];
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your device can't send Email. Please go to iPhone's \"Settings\" to set up Email first."
															message:nil
														   delegate:nil 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
			[alert show];
		}
	}

}

+ (BOOL) validateEmail:(NSString *)candidate 
{ 
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:candidate];
}

-(UIImage *)rotateImage:(UIImage *)aImage orient:(int)orient

{
    CGImageRef imgRef = aImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;
    CGFloat boundHeight;
    switch(orient)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
        
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
    
}

@end
