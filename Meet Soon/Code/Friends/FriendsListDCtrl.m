//
//  FriendsListDCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendsListDCtrl.h"
#import "WeiJuListDCtrl.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuPathShareVCtrl.h"
#import "WeiJuData.h"
#import "WeiJuMessage.h"
#import "FriendData.h"
#import "WeiJuManagedObjectContext.h"
#import "OperationQueue.h"
#import "DataFetchUtil.h"
#import "WeiJuNetWorkClient.h"
#import "ConvertUtil.h"
#import "Character.h"
#import "DataFetchUtil.h"
#import "FriendsListVCtrl.h"
#import "OperationTask.h"
#import "Utils.h"
#import "ConvertData.h"
#import "FileOperationUtils.h"
#import "FriendDetailVCtrl.h"

@implementation FriendsListDCtrl

@synthesize friendDataAllList;

@synthesize friendDataAllSectionList;

@synthesize friendDataSearchList;

@synthesize friendDataSearchSectionList;

@synthesize friendEmailsDictionary;

@synthesize addressBookDictionary;

@synthesize addressBookSearchAllArr;

@synthesize addressBookCurrentSearchArr;

@synthesize addressBookCurrentSearchStr;

@synthesize addressBookSectionsArr;

@synthesize fetcher=_fetcher;

@synthesize eventChangeBuf=_eventChangeBuf, eventChangeQ=_eventChangeQ, addrMutex=_addrMutex;

@synthesize hasAcceessToAddr=_hasAcceessToAddr, hasLoadedAddr=_hasLoadedAddr;

ABAddressBookRef addressBook;

static FriendsListDCtrl *sharedInstance;

static bool isInit = true;
//初始化
- (id)init 
{
    if (self = [super init]) 
    {
        addressBookCurrentSearchStr = @"";
		addressBook=NULL;
		
		self.hasAcceessToAddr=NO;
		self.hasLoadedAddr=NO;
		
		self.eventChangeBuf = [[NSMutableArray alloc] init];
		self.eventChangeQ=[[NSOperationQueue alloc] init];
		[self.eventChangeQ setName:@"AddrChangeQ"];
		[self.eventChangeQ setMaxConcurrentOperationCount:1]; //only one update can run, no concurrency
		self.addrMutex = [NSNull null];
		
        [self startFetcher];
        if (ABAddressBookRequestAccessWithCompletion == NULL || ABAddressBookGetAuthorizationStatus()==kABAuthorizationStatusAuthorized)
		{
			self.hasAcceessToAddr=YES;
			[self setUpData];
		}
        return self;
    }
    return nil;
}

+(FriendsListDCtrl *)getSharedInstance{
    if (sharedInstance == nil) {
        sharedInstance = [[FriendsListDCtrl alloc] init];
    }
    return sharedInstance;
}

- (void) reset{
    [self closeAddrBook];
    friendDataAllList = nil;
    friendDataAllSectionList = nil;
    friendDataSearchList = nil;
    friendDataSearchSectionList = nil;
    friendEmailsDictionary = nil;
    addressBookDictionary = nil;
    addressBookSearchAllArr = nil;
    addressBookCurrentSearchArr = nil;
    addressBookCurrentSearchStr = @"";
    addressBookSectionsArr = nil;
    sharedInstance = nil;

	self.hasAcceessToAddr=NO;
	self.hasLoadedAddr=NO;
}

#pragma mark - addressbook methods
- (void) getAccessToAddr
{
	FriendsListDCtrl * __weak weakSelf = self;
	
	CFErrorRef myError = NULL;
	addressBook = ABAddressBookCreateWithOptions(NULL, &myError);
	
	ABAddressBookRequestAccessWithCompletion(addressBook,^(bool granted, CFErrorRef error){
												 if (granted)
												 {
													 [DataFetchUtil saveButtonsEventRecord:@"1q"];
													 weakSelf.hasAcceessToAddr=YES;
													 [weakSelf performSelectorOnMainThread:@selector(setUpData) withObject:nil waitUntilDone:YES];
													 
													 //notify flistvctrl or pvc, whoever needs to access addrbook
													 [[NSNotificationCenter defaultCenter] postNotificationName:@"AddrBookNotif" object:self userInfo:nil];
												 }
												 else
												 {
													 [DataFetchUtil saveButtonsEventRecord:@"1r"];
													 [Utils displaySmartAlertWithTitle:NSLocalizedString(@"NO_ADDR_ACCESS_TITLE", nil) message:NSLocalizedString(@"NO_ADDR_ACCESS_MSG", nil) noLocalNotif:YES];
												 }
											 });
}

- (void) setUpData //:(BOOL)refreshFData
{
    if (ABAddressBookRequestAccessWithCompletion == NULL)
	{
		if(addressBook==NULL)
			addressBook = ABAddressBookCreate();
	}
	else //ios6: should already been openned in getAccessToAddr; maybe not, if called by pvc calling getAddressBook
	{
		if(addressBook==NULL)
		{
			CFErrorRef myError = NULL;
			addressBook = ABAddressBookCreateWithOptions(NULL, &myError);
		}
	}
	
	//if(refreshFData)
	//{
		NSMutableDictionary *withObject = [NSMutableDictionary dictionary];
		NSNumber *reopenFlag = [NSNumber numberWithInt:0]; //dont reopenn addressbook
		[withObject setObject:reopenFlag forKey:@"reopenFlag"];
		[self refreshFriendDataAndAddrBook:withObject];
	//}
	
	self.hasLoadedAddr=YES;
	
	ABAddressBookRegisterExternalChangeCallback(addressBook, MyABExternalChangeCallback,nil);
    
}

- (void) closeAddrBook
{
	if(addressBook!=NULL)
	{
        ABAddressBookUnregisterExternalChangeCallback(addressBook, MyABExternalChangeCallback, nil);

		[self.eventChangeQ cancelAllOperations];
		[self.eventChangeBuf removeAllObjects];

		@synchronized(self.addrMutex) //otherwise the change operation may still access the addressbook
		{
			CFRelease(addressBook);
			addressBook=NULL;
		}
	}
}

- (ABAddressBookRef) getAddressBook //for pvc to get
{
	@synchronized(self.addrMutex)
	{
		return addressBook;
	}
}

- (NSData *)getImageByRecordID:(int32_t) abRecordID
{
	ABRecordRef abr;
	@synchronized(self.addrMutex)
	{
	if(addressBook==NULL)
		return nil;
	//NSLog(@"%d", abRecordID);
	abr = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);
	}
	//NSLog(@"%@", abr);
	
	if (abr && ABPersonHasImageData(abr))
	{
        CFDataRef imageC = ABPersonCopyImageDataWithFormat(abr, kABPersonImageFormatThumbnail);
		if(imageC)
		{
			UIImage *addressVookImage = [UIImage imageWithData:(__bridge NSData*)imageC];
			addressVookImage = [[[Utils alloc] init] rotateImage:addressVookImage orient:addressVookImage.imageOrientation];
			CFRelease(imageC);
			//CFRelease(abr);
			return UIImagePNGRepresentation(addressVookImage);
		}
	}
	
	//CFRelease(abr);	//don't release, will cause crash when switching to contacts view
	return nil;

}

void MyABExternalChangeCallback(ABAddressBookRef ab, CFDictionaryRef info, void *context)
{
	[Utils log:@"MyABChange:%@", [NSDate date]];
    [[FriendsListDCtrl getSharedInstance] processAddrChange:YES];
}

- (void) processAddrChange:(BOOL)reopenADDR //for the first launch refresh, there is no need to close and open the addressbook again
{
	//when this line is executed: there can be three possibilities: 1) the previous timer has not fired yet -> good, it will be invalidated, won't fire; 2) the timer has fired, but the thread hasn't started exec yet -> in refreshFriendData, check if timer is valid, exec only when it is invalid as it means there is no next timer fired, 3) refreshFriendData is being exec, hence this block will be executed only when refreshFriendData is done
	@synchronized(self.eventChangeBuf)
	{
		if([self.eventChangeBuf count]>1)
		{
			NSLog(@"skip addr update, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
			return;
		}
		
		NSLog(@"continue to addr update, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
		
		[self.eventChangeBuf addObject:[NSNull null]];

		NSMutableDictionary *withObject = [NSMutableDictionary dictionary];
		NSNumber *reopenFlag;
		if(reopenADDR)
			reopenFlag = [NSNumber numberWithInt:1];
		else
			reopenFlag = [NSNumber numberWithInt:0];
		[withObject setObject:reopenFlag forKey:@"reopenFlag"];
		NSInvocationOperation *eventChangeTask = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processAddrChangeInThread:) object:withObject];
		[eventChangeTask setQueuePriority:NSOperationQueuePriorityLow];
		[eventChangeTask setThreadPriority:1.0];
		[self.eventChangeQ addOperation:eventChangeTask];

	}
}

//run on main (flag==1) and non main thread
- (void) processAddrChangeInThread:(NSDictionary *)dic
{
	BOOL redisplay = [self refreshFriendDataAndAddrBook:dic];
	
	@synchronized(self.eventChangeBuf)
	{
		[self.eventChangeBuf removeLastObject];
		NSLog(@"done with processAddrChangeInThread, with ops=%d, buf=%d", self.eventChangeQ.operationCount, [self.eventChangeBuf count]);
	}
	
	if( ([FriendsListVCtrl getSharedInstance] != nil && [FriendsListVCtrl getSharedInstance].isBeingDisplayed) || ([FriendsListVCtrl getSharedInstance] != nil && [FriendsListVCtrl getSharedInstance].fDetailVCtrl != nil && [FriendsListVCtrl getSharedInstance].fDetailVCtrl.isBeingDisplayed))
	{
		if(redisplay)
			[[FriendsListVCtrl getSharedInstance].tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
		
		if([FriendsListVCtrl getSharedInstance] != nil && [FriendsListVCtrl getSharedInstance].fDetailVCtrl != nil && [FriendsListVCtrl getSharedInstance].fDetailVCtrl.isBeingDisplayed)
			[[FriendsListVCtrl getSharedInstance].fDetailVCtrl performSelectorOnMainThread:@selector(updateImageView) withObject:nil waitUntilDone:YES];
    }
		
}

- (BOOL) refreshFriendDataAndAddrBook:(NSDictionary *)dic
{
	NSArray *friendDataResult;
    NSNumber *reopenABRFlag = (NSNumber *)[dic objectForKey:@"reopenFlag"];
	
	ABAddressBookRef addressBookTmp = addressBook; //used for the first time, called on main thread, hence using the addrBook on main thread
    if([reopenABRFlag intValue]==1)
    {
		if (ABAddressBookRequestAccessWithCompletion == NULL)
		{
			addressBookTmp = ABAddressBookCreate();
		}
		else //ios6: should already been openned in getAccessToAddr; maybe not, if called by pvc calling getAddressBook
		{
			CFErrorRef myError = NULL;
			addressBookTmp = ABAddressBookCreateWithOptions(NULL, &myError);
		}
		
		friendDataResult = [[[DataFetchUtil alloc] init] searchObjectArray:@"addressBookFriendData" managedObjectName:@"FriendData" filterString:nil]; //open on non-main thread
    }
	else 
		friendDataResult = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:nil];
	
    if(addressBookTmp==NULL) return NO; //fail to open, do nothing
    
    NSMutableArray *modifyArray = [NSMutableArray array];
	
	if(friendDataResult!=nil&&[friendDataResult count]>0)
	{
		for(FriendData *friendData in friendDataResult)
		{
			NSArray *abRecordNameNoCaseArr = friendData.abRecordNameNoCase == nil?nil:[friendData.abRecordNameNoCase componentsSeparatedByString:@"|"];
			NSString *abRecordIDStr = [abRecordNameNoCaseArr count] > 1?[abRecordNameNoCaseArr objectAtIndex:1]:nil;
			if (abRecordIDStr != nil)
			{
				int32_t abRecordID = [abRecordIDStr intValue];
				
				ABRecordRef abr;
				abr = ABAddressBookGetPersonWithRecordID(addressBookTmp, abRecordID);
				
				NSMutableDictionary *modifyDic = [NSMutableDictionary dictionary];
				[modifyDic setObject:friendData.userId forKey:@"userId"];
				//bool changed = false;
				if (abr)
				{
					//update frist name
					CFStringRef cfn = ABRecordCopyValue(abr, kABPersonFirstNameProperty);
					NSString * firstName = nil;
					if(cfn)
					{
						firstName = [NSString stringWithFormat:@"%@", cfn];
						if(![firstName isEqualToString:friendData.abRecordFirstName]){
							[modifyDic setObject:firstName forKey:@"abRecordFirstName"];
						}
						CFRelease(cfn); //copy from abr, can be released
					}
					//update last name
					CFStringRef cln = ABRecordCopyValue(abr, kABPersonLastNameProperty);
					NSString * lastName = nil;
					if(cln)
					{
						lastName = [NSString stringWithFormat:@"%@", cln];
						if(![lastName isEqualToString:friendData.abRecordLastName]){
							[modifyDic setObject:lastName forKey:@"abRecordLastName"];
						}
						CFRelease(cln);
					}
					
					NSString *fullName = nil;
					NSString *fullNameNoCase = nil;
					if(lastName != nil && firstName != nil)
					{
						fullName = [firstName stringByAppendingFormat:@" %@", lastName];
						fullNameNoCase = [[lastName stringByAppendingFormat:@" %@", firstName] lowercaseString];
						
					}else if(lastName == nil && firstName != nil){
						fullName = firstName;
						fullNameNoCase = [firstName lowercaseString];
					}else if(lastName != nil && firstName == nil){
						fullName = lastName;
						fullNameNoCase = [lastName lowercaseString];
					}
					fullNameNoCase = fullNameNoCase == nil?nil:[fullNameNoCase stringByAppendingFormat:@"|%@",abRecordIDStr];
					
					if(fullName != nil && ![fullName isEqualToString:friendData.abRecordName]){
						[modifyDic setObject:fullName forKey:@"abRecordName"];
					}
					if(fullNameNoCase != nil && ![fullNameNoCase isEqualToString:friendData.abRecordNameNoCase]){
						[modifyDic setObject:fullNameNoCase forKey:@"abRecordNameNoCase"];
					}
					
					//获取email多值
					ABMultiValueRef emailRef = ABRecordCopyValue(abr, kABPersonEmailProperty);
					int emailcount = ABMultiValueGetCount(emailRef);
					bool uploadEmail = false;
					for (int x = 0; x < emailcount; x++)
					{
						CFStringRef emailC = ABMultiValueCopyValueAtIndex(emailRef, x);
						if (!emailC) {
							continue;
						}
						NSString *email = [@"" stringByAppendingFormat:@"(%@)", emailC];
						if ([friendData.abRecordEmails rangeOfString:email].location == NSNotFound) {
							uploadEmail = true;
							friendData.abRecordEmails = [friendData.abRecordEmails stringByAppendingFormat:@"%@",email];
						}
						CFRelease(emailC);
					}
					if (uploadEmail) {
						[modifyDic setObject:friendData.abRecordEmails forKey:@"abRecordEmails"];
					}
					
					//读取照片
					if (ABPersonHasImageData(abr)){
						CFDataRef imageC = ABPersonCopyImageDataWithFormat(abr,kABPersonImageFormatThumbnail);
						if(imageC)
						{
							UIImage *addressVookImage = [UIImage imageWithData:(__bridge NSData*)imageC];
							
							UIImage *fixedAddressVookImage = [[[Utils alloc] init] rotateImage:addressVookImage orient:addressVookImage.imageOrientation];
							
							//fixedAddressVookImage = fixedAddressVookImage;
							//FileOperationUtils *fileOperationUtils = [[FileOperationUtils alloc] init];
							//NSString *disFileName = [fileOperationUtils getDisName];
							//[fileOperationUtils saveFileWithDisFileName:abRecordIDStr image:addressVookImage];
							//[modifyDic setObject:addressVookImage forKey:@"userImageTest"];
							[modifyDic setObject:UIImagePNGRepresentation(fixedAddressVookImage)  forKey:@"userImageFileData"];
							CFRelease(imageC);
						}
					}
				}//abr
				else {
					[modifyDic setObject:@" " forKey:@"userImageFileData"];
					[modifyDic setObject:@" " forKey:@"abRecordName"];
					[modifyDic setObject:@" " forKey:@"abRecordNameNoCase"];
					[modifyDic setObject:@" " forKey:@"abRecordFirstName"];
					[modifyDic setObject:@" " forKey:@"abRecordLastName"];
					[modifyDic setObject:@" " forKey:@"abRecordEmails"];
					[modifyDic setObject:@"1" forKey:@"hide"];
				}
				
				if ([[modifyDic allKeys] count] > 2 )
				{
					[Utils log:@"%s [line:%d] AddressBook Changed,upload data to server",__FUNCTION__,__LINE__];
					[[Utils getSharedInstance] updateMyFriend:modifyDic];
				}
				
				[modifyArray addObject:modifyDic];
			}//abRecordIDStr != nil
			
		}//for
	}//friendataResult not nil
    
    //self.saveTimer=nil; //no need
    isInit = false;
	
	BOOL redisplay=NO;
	if (modifyArray!=nil && [modifyArray count]>0)
	{
		[self performSelectorOnMainThread:@selector(updateLocalFriendData:) withObject:modifyArray waitUntilDone:YES];
		redisplay=YES;
	}
	
	if ([FriendsListVCtrl getSharedInstance] != nil) //during wjlvctrl init's first call to this method, flvctrl is nil, hence won't load the full addrbook
	{
        if (addressBookSectionsArr != nil && addressBookSearchAllArr != nil) //we have loaded the addrbook already, hence need to reload
		{
            [self buildAddrBook:addressBookTmp];
			redisplay=YES;
        }
    }
	
	if(addressBookTmp!=addressBook)
		CFRelease(addressBookTmp);
	return redisplay;
}

-(void) updateLocalFriendData:(NSArray *)arr{
    
    for (NSDictionary *dic in arr)
	{
        NSString *userId = (NSString *)[dic objectForKey:@"userId"];
        NSArray *friendDataResult = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:[@"userId ==" stringByAppendingFormat:@"'%@'",userId]];
        if (friendDataResult != nil && [friendDataResult count] > 0)
		{
            FriendData *friendData = [friendDataResult objectAtIndex:0];
			NSArray * allKeys = [dic allKeys];
            for (NSString *key in allKeys)
			{
                if ([@"userId" isEqualToString:key]) continue;
                NSString *value = [dic objectForKey:key];
                if ([@"" isEqualToString:[dic objectForKey:key]] || [@" " isEqualToString:[dic objectForKey:key]]) {
                    value = nil;
                }
                [friendData setValue:value forKey:key];
            }
            
        }
    }

    [Utils log:@"Update local friendData:%i",[arr count]];
    [WeiJuManagedObjectContext quickSave];
}

//can be called on any thread
- (void) buildAddrBook:(ABAddressBookRef) addrBook
{
    Character *character = [[Character alloc] init];
    [self initFriendMailsDictionary];

	//this works for all contacts
    CFMutableArrayRef results = (CFMutableArrayRef)ABAddressBookCopyArrayOfAllPeople(addrBook);
	if(results==NULL)
		return;
	
	//copy from stanford material
	CFRange fullRange = CFRangeMake(0, CFArrayGetCount(results));
	ABPersonSortOrdering sortOrdering = ABPersonGetSortOrdering();
	CFArraySortValues(results, fullRange, ABPersonComparePeopleByName, (void*)sortOrdering);
	// Objective-C alternative:勿删
    //NSArray *results = (__bridge NSArray *)results1;
    //CFRelease(results1);
	//[results_nsarray sortUsingFunction:ABPersonComparePeopleByName context:(void*)sortOrdering];
	
	/* //this works for only ONE contact source, not multiple
    ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
    CFArrayRef results = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook,source,kABPersonSortByLastName);
    CFRelease(source);
	 */
    
	self.addressBookDictionary = [NSMutableDictionary dictionary];
    self.addressBookSectionsArr = [NSMutableArray array];
    self.addressBookSearchAllArr = [NSMutableArray array];
    /*
	//this works for all contacts: luo is infront of Luo, not right
	results = [results sortedArrayUsingComparator: ^(id obj1, id obj2) { 
        CFStringRef lnameCa  = ABRecordCopyValue(((__bridge ABRecordRef)obj1), kABPersonLastNameProperty);
        CFStringRef lnameCb  = ABRecordCopyValue(((__bridge ABRecordRef)obj2), kABPersonLastNameProperty);
        CFStringRef fnameCa  = ABRecordCopyValue(((__bridge ABRecordRef)obj1), kABPersonFirstNameProperty);
        CFStringRef fnameCb  = ABRecordCopyValue(((__bridge ABRecordRef)obj2), kABPersonFirstNameProperty);
        NSString *la = @"";
        NSString *lb = @"";
        NSString *fa = @"";
        NSString *fb = @"";
        if(lnameCa){
            la = [NSString stringWithFormat:@"%@",lnameCa];
            CFRelease(lnameCa);
        }
        if(fnameCa){
            fa = [NSString stringWithFormat:@"%@",fnameCa];
            CFRelease(fnameCa);
        }
        if(lnameCb){
            lb = [NSString stringWithFormat:@"%@",lnameCb];
            CFRelease(lnameCb);
        }
        if(fnameCb){
            fb = [NSString stringWithFormat:@"%@",fnameCb];
            CFRelease(fnameCb);
        }
        NSString *a = [la stringByAppendingFormat:@"%@",fa];
        NSString *b = [lb stringByAppendingFormat:@"%@",fb];
        if ([a compare: b] == NSOrderedDescending) { 
            return (NSComparisonResult)NSOrderedDescending; 
        } else {
            return (NSComparisonResult)NSOrderedAscending; 
        }
        
        return (NSComparisonResult)NSOrderedSame; 
    }];
    */
		
    for(int i = 0; i < CFArrayGetCount(results); i++)
    //for(int i = 0; i < [results count]; i++)
    {
        ABRecordRef person = CFArrayGetValueAtIndex(results, i);
        //ABRecordRef person = (__bridge ABRecordRef)[results objectAtIndex:i];
        NSMutableDictionary *personDic = [NSMutableDictionary dictionary];
        //读取lastname
        CFStringRef lastnameC = ABRecordCopyValue(person, kABPersonLastNameProperty);
        CFStringRef fristnameC = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        CFStringRef companynameC = ABRecordCopyValue(person, kABPersonOrganizationProperty);
        NSString *username;
        if(lastnameC && fristnameC){
            username = [NSString stringWithFormat:@"%@ %@",lastnameC,fristnameC];
        }else if(lastnameC){
            username = [NSString stringWithFormat:@"%@",lastnameC];
        }else if(fristnameC){
            username = [NSString stringWithFormat:@"%@",fristnameC];
        }else if(companynameC){
            username = [NSString stringWithFormat:@"%@",companynameC];
        }else{
            //username = @"No Name";//try email/phone as name
			ABMutableMultiValueRef multi = ABRecordCopyValue(person, kABPersonEmailProperty);
			if (multi) 
			{
				for(CFIndex x=0;x<ABMultiValueGetCount(multi);x++)
				{
					CFStringRef email = ABMultiValueCopyValueAtIndex(multi, x);
					//NSLog(@"%d: %@ %@", x, [@"Lable is " stringByAppendingFormat:@"%@",phoneLabel], phoneNumber);
					if(email)
					{
						username = [NSString stringWithFormat:@"%@",email];
						CFRelease(email);
						break;
					}
				}
				CFRelease(multi); //a copy from abr, can be released
			}
			
			if(username==nil) //not found email
			{
				ABMutableMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
				if (multi) 
				{
					for(CFIndex x=0;x<ABMultiValueGetCount(multi);x++)
					{
						CFStringRef phone = ABMultiValueCopyValueAtIndex(multi, x);
						//NSLog(@"%d: %@ %@", x, [@"Lable is " stringByAppendingFormat:@"%@",phoneLabel], phoneNumber);
						if(phone)
						{
							username = [NSString stringWithFormat:@"%@",phone];
							CFRelease(phone);
							break;
						}
					}
					CFRelease(multi); //a copy from abr, can be released
				}
				
				if(username==nil) {
					username = @"No Name";
				}
			}
			
        }
        
        if (lastnameC) CFRelease(lastnameC);
        if (fristnameC) CFRelease(fristnameC);
        if (companynameC) CFRelease(companynameC);
		
        NSString *fristc = [character getFirstCharacter:[NSString stringWithFormat:@"%@", username]].uppercaseString;
        
        if ([self.addressBookDictionary objectForKey:fristc] == nil){
            [self.addressBookDictionary setValue:[NSMutableArray array] forKey:fristc];
            [self.addressBookSectionsArr addObject:fristc];
        }
            
        [((NSMutableArray *)[self.addressBookDictionary objectForKey:fristc]) addObject:personDic];
        [personDic setValue:username forKey:@"username"];
        
        
        //读取照片
        if (ABPersonHasImageData(person)){
            CFDataRef imageC = ABPersonCopyImageDataWithFormat(person,kABPersonImageFormatThumbnail); //ABPersonCopyImageData(person);
			if(imageC)
			{
				UIImage *addressVookImage = [UIImage imageWithData:(__bridge NSData*)imageC];
				addressVookImage = [[[Utils alloc] init] rotateImage:addressVookImage orient:addressVookImage.imageOrientation];
				[personDic setValue:addressVookImage forKey:@"image"];
				CFRelease(imageC);
			}
        }
   
        
        //获取email多值
        ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
		if(email)
		{
			int emailcount = ABMultiValueGetCount(email);
			for (int x = 0; x < emailcount; x++)
			{
				//获取email值
				CFStringRef emailContent = ABMultiValueCopyValueAtIndex(email, x);
				NSString *email = [NSString stringWithFormat:@"%@", emailContent];
				if (x == 0) {
					[personDic setValue:email forKey:@"email"];
				}else {
					[personDic setValue:[[personDic objectForKey:@"email"] stringByAppendingFormat:@",%@",email] forKey:@"email"];
				}
				if([self.friendEmailsDictionary objectForKey:email] != nil){
					[personDic setValue:[self.friendEmailsDictionary objectForKey:email] forKey:@"FriendData"];
					break;
				}
				if (emailContent) {
					CFRelease(emailContent);
				}
			}
			CFRelease(email);
		}
		
        //获取phone number多值
        ABMultiValueRef phone = ABRecordCopyValue(person, kABPersonPhoneProperty);
		if(phone)
		{
			for (int k = 0; k<ABMultiValueGetCount(phone); k++)
			{
				//获取电话Label
				CFStringRef personPhoneLabelC = ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phone, k));
				CFStringRef personPhoneC = ABMultiValueCopyValueAtIndex(phone, k);
				
				NSString *personPhoneLabel = [NSString stringWithFormat:@"%@", personPhoneLabelC];
				NSString *personPhone = [NSString stringWithFormat:@"%@", personPhoneC];
				
				if (k == 0) {
					[personDic setValue:[NSMutableArray array] forKey:@"personPhoneLabelArr"];
					[personDic setValue:[NSMutableArray array] forKey:@"personPhoneArr"];
				}
				[((NSMutableArray *)[personDic objectForKey:@"personPhoneLabelArr"]) addObject:personPhoneLabel];
				[((NSMutableArray *)[personDic objectForKey:@"personPhoneArr"]) addObject:personPhone];
				
				if (personPhoneLabelC) CFRelease(personPhoneLabelC);
				if (personPhoneC) CFRelease(personPhoneC);
			}
			CFRelease(phone);
		}
        
        [self.addressBookSearchAllArr addObject:personDic];
		
		//CFRelease(person); //don't release, will cause crash when switching back to registered view
    }
    
	CFRelease(results);
    //CFRelease(addressBook); //close elsewhere

    self.addressBookSectionsArr = [self.addressBookSectionsArr sortedArrayUsingComparator: ^(id obj1, id obj2) {
        NSString *a = (NSString *)obj1;
        NSString *b = (NSString *)obj2;
        if ([a compare: b] == NSOrderedDescending) { 
            return (NSComparisonResult)NSOrderedDescending; 
        } else {
            return (NSComparisonResult)NSOrderedAscending; 
        }
        return (NSComparisonResult)NSOrderedSame; 
    }]; 
}

- (void) startSearchAddressBookWithSearchStr:(NSString *)searchStr{
    self.addressBookCurrentSearchArr = [NSMutableArray array];
	for (NSDictionary *dict in self.addressBookSearchAllArr) {
    //for (int i=0; i<[self.addressBookSearchAllArr count]; i++) {
        if ([((NSString *)[dict objectForKey:@"username"]).lowercaseString rangeOfString:searchStr.lowercaseString].location != NSNotFound) {
            [self.addressBookCurrentSearchArr addObject:dict];
        }
    }
    
}

- (void) initFriendMailsDictionary
{
    self.friendEmailsDictionary = [NSMutableDictionary dictionary];
    NSArray *friendDataResult = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:nil];
    for (int i=0; i<[friendDataResult count]; i++) {
        
        FriendData *friendData = (FriendData *)[friendDataResult objectAtIndex:i];
        if (friendData.userEmails != nil && ![friendData.userEmails isEqualToString:@""]){        
            NSArray *emails = [friendData.userEmails componentsSeparatedByString:@")("];
           
            for (int j=0; j<[emails count]; j++) {
                if ([emails objectAtIndex:j] != nil) {
                    
                    NSString *email = [[(NSString *)[emails objectAtIndex:j] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
                    [self.friendEmailsDictionary setValue:friendData forKey:email];
                }
            }
        }
    }
}


#pragma mark - coredata methods

#pragma mark - coredata methods
- (void) startFetcher //search all from coredata
{ 
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userId" ascending:YES] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FriendData" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];   
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:nil] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
        [Utils log:@"%s [line:%d] error:%@, %@",__FUNCTION__,__LINE__, error, [error userInfo]];
    }   
}

- (void) startSearch //search all from coredata
{    
    if ([@"" isEqualToString:self.addressBookCurrentSearchStr]) {
        //NSArray *a = [[NSArray alloc] initWithObjects:@"userNameSectionTitle",nil];
        NSArray *a = [[NSArray alloc] initWithObjects:@"abRecordNameNoCase",nil];
        NSArray *searchList = [[[DataFetchUtil alloc] init] searchObjectArrayOrderby:@"FriendData" filterString:@"hide = '0'" orderbyStrArray:a];
		//NSArray *searchList = [[[DataFetchUtil alloc] init] searchObjectArrayOrderby:@"FriendData" filterString:@"(NOT (userId in {'1','2','3','4','5','6','7','8','9','10'})) and hide = '0'" orderbyStrArray:a];
//        if (searchList != nil) {
//            searchList = [searchList sortedArrayUsingComparator: ^(id obj1, id obj2) { 
//                NSString *a = ((FriendData *)obj1).abRecordLastName;
//                NSString *b = ((FriendData *)obj2).abRecordLastName;
//                if ([a compare: b] == NSOrderedDescending) { 
//                    return (NSComparisonResult)NSOrderedDescending; 
//                } else {
//                    return (NSComparisonResult)NSOrderedAscending; 
//                }
//                return (NSComparisonResult)NSOrderedSame; 
//            }]; 
//        }
        NSString *stepSectionStr = @"";
        NSMutableArray *sectionArr = nil;
        self.friendDataAllList = [NSMutableArray array];
        self.friendDataAllSectionList = [NSMutableArray array];
		Character *character = [[Character alloc] init];
        for (int i=0; i < [searchList count]; i++) {
            FriendData *friendData = (FriendData *)[searchList objectAtIndex:i];
            NSString *fristc =  [character getFirstCharacter:friendData.abRecordNameNoCase].uppercaseString;
            //NSString *fristc = friendData.userNameSectionTitle.uppercaseString;
            //[Utils log:@"%s [line:%d] info:%@:%@:%@",__FUNCTION__,__LINE__,friendData.userId,friendData.userName,friendData.userNameSectionTitle];
            if (fristc == nil || friendData.abRecordNameNoCase == nil || [@"" isEqualToString:friendData.abRecordNameNoCase])
            {
                continue;
            }
            if (![fristc isEqualToString:stepSectionStr]) {
                stepSectionStr = fristc;
                sectionArr = [NSMutableArray array];
                [self.friendDataAllList addObject:sectionArr];
                [self.friendDataAllSectionList addObject:fristc];
            }
            [sectionArr addObject:friendData];
            
        }
        
//        self.friendDataAllSectionList = [self.friendDataAllSectionList sortedArrayUsingComparator: ^(id obj1, id obj2) { 
//            NSString *a = (NSString *)obj1;
//            NSString *b = (NSString *)obj2;
//            if ([a compare: b] == NSOrderedDescending) { 
//                return (NSComparisonResult)NSOrderedDescending; 
//            } else {
//                return (NSComparisonResult)NSOrderedAscending; 
//            }
//            return (NSComparisonResult)NSOrderedSame; 
//        }]; 
    }else {
        NSArray *searchList = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:[@"" stringByAppendingFormat:@" hide = '0' and abRecordNameNoCase like '*%@*'",[self.addressBookCurrentSearchStr lowercaseString]]];
		//NSArray *searchList = [[[DataFetchUtil alloc] init] searchObjectArray:@"FriendData" filterString:[@"(NOT (userId in " stringByAppendingFormat:@"{%@})) and  hide = '0' and abRecordNameNoCase like '*%@*'",@"'1','2','3','4','5','6','7','8','9','10'",[self.addressBookCurrentSearchStr lowercaseString] ]];
        NSString *stepSectionStr = @"";
        NSMutableArray *sectionArr;
        self.friendDataSearchList = [NSMutableArray array];
        self.friendDataSearchSectionList = [NSMutableArray array];
        for (int i=0; i < [searchList count]; i++) {
            FriendData *friendData = (FriendData *)[searchList objectAtIndex:i];
            NSString *fristc = [[[Character alloc] init] getFirstCharacter:[NSString stringWithFormat:@"%@", friendData.userName]].uppercaseString;
            if (![fristc isEqualToString:stepSectionStr]) {
                stepSectionStr = fristc;
                sectionArr = [NSMutableArray array];
                [self.friendDataSearchList addObject:sectionArr];
                [self.friendDataSearchSectionList addObject:fristc];
            }
            [sectionArr addObject:friendData];
        }
        
    }
}

#pragma mark - Fetched results controller callbacks
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
// A delegate callback called by the fetched results controller when its content 
// changes.  If anything interesting happens (that is, an insert, delete or move), we 
// respond by reloading the entire table.  This is rather a heavy-handed approach, but 
// I found it difficult to correctly handle the updates.  Also, the insert, delete and 
// move aren't on the critical performance path (which is scrolling through the list 
// loading thumbnails), so I can afford to keep it simple.
{
	//@synchronized(self) //no need to sync, because it is called by the main thread one by one
	//{
		if ([WeiJuListVCtrl getSharedInstance] == nil) {
			return;
		}
		if([[[anObject class] description] isEqualToString:@"FriendData"]){
			switch (type) {
				case NSFetchedResultsChangeInsert:
				{
					FriendData *friendData = (FriendData *)anObject;
					//NSLog(@"flistdCtrl: friendData=%@",friendData);
					if ([WeiJuListVCtrl getSharedInstance] != nil && [WeiJuListVCtrl getSharedInstance].weiJuPathShareVCtrls != nil)
					{
						NSArray *allValues = [[WeiJuListVCtrl getSharedInstance].weiJuPathShareVCtrls allValues];
						
						for (WeiJuPathShareVCtrl *pvc in allValues)
						{
							if(pvc.hasBeenShutdown==NO)
								[pvc refreshParticipantColorStatus:friendData setColor:YES];
							//NSLog(@"%d: %@",i, weiJuPathShareVCtrl.selfEvent.title);
							
							//                        SEL s = NSSelectorFromString(@"refreshParticipantColorStatus:");
							//                        NSMethodSignature *sig = [self methodSignatureForSelector:s];
							//                        NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
							//                        [invo setTarget:weiJuPathShareVCtrl];
							//                        [invo setSelector:s];
							//                        [invo setArgument:&friendData atIndex:2];
							//                        [invo setArgument:YES atIndex:3];
							//                        [invo retainArguments];
							//                        [invo performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
						}
						
					}
                    
					break;
				}
				case NSFetchedResultsChangeDelete: {
				} break;
				case NSFetchedResultsChangeMove: {
				} break;
				case NSFetchedResultsChangeUpdate: {
				} break;
				default: {
				} break;
			}
		}
    //}
}


- (void) startAddressBookSearch //only called by listvctrl, search all from coredata
{
//	if(addressBook==NULL) //refreshFriendData could happen to set it to be NULL then reopen again
//	{
//		NSTimer *waitTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(startAddressBookSearch) userInfo:nil repeats:NO];
//	}
//	else
//	{
		if(addressBookDictionary == nil) //haven't loaded addrbook yet
		{
			ABAddressBookRef addressBookTmp=NULL;
			if (ABAddressBookRequestAccessWithCompletion == NULL)
			{
				addressBookTmp = ABAddressBookCreate();
			}
			else //ios6
			{
				CFErrorRef myError = NULL;
				addressBookTmp = ABAddressBookCreateWithOptions(NULL, &myError);
			}
				
			if(addressBookTmp!=NULL)
			{
				[self buildAddrBook:addressBookTmp]; //don't use main thread's addressBook
				CFRelease(addressBookTmp);
			}
		}
//	}
}

- (int)numberOfSections
{
    NSString *searchStr = [FriendsListVCtrl getSharedInstance].searchBar.text;
    if ([@"" isEqualToString:searchStr]) {
        //没有使用搜索
        self.addressBookCurrentSearchStr = searchStr;
        return [self.friendDataAllSectionList count];
    }else{
       if (![self.addressBookCurrentSearchStr isEqualToString:searchStr]) {
          //使用搜索,并且搜索栏改变了搜索内容
           self.addressBookCurrentSearchStr = searchStr;
           [self startSearch];
       }
        return [self.friendDataSearchSectionList count];;
 
    }
    
}

- (int)numberOfRowsInSection:(NSInteger)section
{
    if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
        //没有使用搜索
        return [[self.friendDataAllList objectAtIndex:section] count];
    }else{
        return [[self.friendDataSearchList objectAtIndex:section] count];
    }
    
}


- (FriendData *)objectInListAtIndex:(NSIndexPath *)theIndex {
    if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
        //没有使用搜索
         return [[self.friendDataAllList objectAtIndex:theIndex.section] objectAtIndex:theIndex.row];
    }else{
         return [[self.friendDataSearchList objectAtIndex:theIndex.section] objectAtIndex:theIndex.row];
        
    }
}
- (NSArray *)sectionIndexTitles {
    
    if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
        //没有使用搜索
        return self.friendDataAllSectionList;
    }else{
        return self.friendDataSearchSectionList;
        
    }
    
}



//address book
- (NSArray *)adbSectionIndexTitles  {
    
    if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
        //没有使用搜索
        return self.addressBookSectionsArr;
    }else{
        //正在搜索
        return [[NSArray alloc] init];
    }

}

- (int)adbNumberOfSections
{
	NSString *searchStr = [FriendsListVCtrl getSharedInstance].searchBar.text;
	if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
		//没有使用搜索
        self.addressBookCurrentSearchStr = searchStr.lowercaseString;
		return [self.addressBookSectionsArr count];
	}else{
		if (![self.addressBookCurrentSearchStr.lowercaseString isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text.lowercaseString]) {
            self.addressBookCurrentSearchStr = searchStr.lowercaseString;
			[self startSearchAddressBookWithSearchStr:[FriendsListVCtrl getSharedInstance].searchBar.text.lowercaseString];
		}
		if ([self.addressBookCurrentSearchArr count] != 0) {
			return 1;
		}else {
			return 0;
		}
	}
}

- (int)adbNumberOfRowsInSection:(NSInteger)section
{
    
    
    if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
        
        //没有搜索,搜索所有
        return [[self.addressBookDictionary objectForKey:[self.addressBookSectionsArr objectAtIndex:section]] count];
      
    }else{
        //正在使用搜索
        return [self.addressBookCurrentSearchArr count];
    }

}


- (NSDictionary *)adbObjectInListAtIndex:(NSIndexPath *)theIndex{    
    
    if ([@"" isEqualToString:[FriendsListVCtrl getSharedInstance].searchBar.text]) {
        return [[self.addressBookDictionary objectForKey:[self.addressBookSectionsArr objectAtIndex:theIndex.section]] objectAtIndex:theIndex.row];
    }else {
        if ([self.addressBookCurrentSearchArr count] == 0) {
            return nil;
        }
        return [self.addressBookCurrentSearchArr objectAtIndex:theIndex.row];
    }
    
}


@end
