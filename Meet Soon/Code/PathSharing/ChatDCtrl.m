//
//  ChatDCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatDCtrl.h"
#import "Utils.h"
#import "WeiJuData.h"
#import "WeiJuMessage.h"
#import "FriendData.h"
#import "WeiJuManagedObjectContext.h"
#import "OperationQueue.h"
#import "DataFetchUtil.h"
#import "WeiJuNetWorkClient.h"
#import "ConvertUtil.h"
#import "MessageTemplate.h"
#import "ConvertData.h"
#import "WeiJuAppDelegate.h"
#import "WeiJuAppPrefs.h"
#import "WeiJuListVCtrl.h"
#import "WeiJuPathShareVCtrl.h"
#import "WeiJuParticipant.h"
#import "WeiJuListDCtrl.h"

@implementation ChatDCtrl

const int WEIJU_MSG_INVITE_TO_SHARE_PATH = 10;
const int WEIJU_MSG_PATH_SHARE_UPDATE = 11;
const int WEIJU_MSG_PATH_SHARE_TURNED_OFF = 12;
const int WEIJU_MSG_ICAL_EVENT_UPDATE = 13;

@synthesize fetcher=_fetcher;

static ChatDCtrl *sharedInstance;

+(ChatDCtrl *)getSharedInstance{
    if (sharedInstance == nil) {
        sharedInstance = [[ChatDCtrl alloc] init];
        [sharedInstance startFetcher];
    }
    return sharedInstance;
}
//初始化
- (id)initWithWeiJuData:(WeiJuData *)weiJuData
{
    if (self = [super init]) 
    {        
        if ([weiJuData.weiJuId isEqualToString:@"0"]) {
            [self startFetcherWithWeiJuClientId:weiJuData.weiJuClientId];
        }else{
            [self startFetcher:weiJuData.weiJuId];
        }
        return self;
    }
    return nil;
}

#pragma mark - coredata methods
- (void) startFetcher //search all from coredata
{    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageClientId" ascending:YES] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WeiJuMessage" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];  
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
	// [fetchRequest setPredicate:[NSPredicate predicateWithFormat:[@"sendTime > " stringByAppendingFormat:@"%@",],nil]];  
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:nil] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
        [Utils log:@"%s [line:%d] error:%@",__FUNCTION__,__LINE__,error.description];
    } 
    //NSLog(@"%i",[[[self.fetcher sections] objectAtIndex:0] numberOfObjects]);
}

- (void) startFetcher:(NSString *)weiJuId //search all from coredata
{    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageClientId" ascending:YES] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WeiJuMessage" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];  
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:[@"weiJuId in " stringByAppendingFormat:@"{'%@'}",weiJuId],nil]];  
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:nil] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
        [Utils log:@"%s [line:%d] error:%@",__FUNCTION__,__LINE__,[error localizedDescription]];
    } 
    //NSLog(@"%i",[[[self.fetcher sections] objectAtIndex:0] numberOfObjects]);
}

- (void) startFetcherWithWeiJuClientId:(NSString *)weiJuClientId //search all from coredata
{    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageClientId" ascending:YES] ;  
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WeiJuMessage" inManagedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]];  
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:[@"weiJuClientId in " stringByAppendingFormat:@"{'%@'}",weiJuClientId],nil]];  
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WeiJuManagedObjectContext getManagedObjectContext]  sectionNameKeyPath:nil cacheName:nil] ; 
    self.fetcher.delegate = self; //callback    
    NSError *error;
    if ( ! [self.fetcher performFetch:&error] ) {
        [Utils log:@"%s [line:%d] error:%@",__FUNCTION__,__LINE__,error.description];
    } 
    //NSLog(@"%i",[[[self.fetcher sections] objectAtIndex:0] numberOfObjects]);
}

- (int)numberOfSections
{
    //NSLog(@"%i",[[self.fetcher sections] count]);
    return [[self.fetcher sections] count];
}

- (int)numberOfRowsInSection:(NSInteger)section;
{
    //NSLog(@"%i",[[[self.fetcher sections] objectAtIndex:section] numberOfObjects]);
    return [[[self.fetcher sections] objectAtIndex:section] numberOfObjects];
}


- (Message *)objectInListAtIndex:(NSIndexPath *)theIndex {  
    //NSLog(@"%@", [self.fetcher objectAtIndexPath:theIndex]);
    return [self.fetcher objectAtIndexPath:theIndex];
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
@try {
    if ([WeiJuListVCtrl getSharedInstance] == nil) {
        return;
    }    
    if([[[anObject class] description] isEqualToString:@"WeiJuMessage"]){
        WeiJuMessage *message = (WeiJuMessage *)anObject;
        
        //NSLog(@"-----------------------------------------%@",[message managedObjectContext].description);
        switch (type) 
		{
            case NSFetchedResultsChangeInsert: 
			{
                if([message.isSendBySelf isEqualToString:@"1"])
				{
                    WeiJuNetWorkClient *weiJuNetWorkClient = [[WeiJuNetWorkClient alloc] init]; 
                    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                    [dic setObject:[[WeiJuAppPrefs getSharedInstance] userId] forKey:@"userId"];
                    [dic setObject:@"0" forKey:@"partyId"];
                    [dic setObject:message.messageRecipients forKey:@"partyPersonUserIds"];
					[dic setObject:message.messagePushAlert forKey:@"messagePushAlert"];
                    [dic setObject:message.isPushMessage forKey:@"isPushMessage"];
                    [dic setObject:message.messageType forKey:@"messageType"];
                    [dic setObject:message.messageContentType forKey:@"messageContentType"];
                    [dic setObject:message.messageContent forKey:@"messageContent"];
					//message.protocolVersion = [[NSString alloc] initWithString:curProtoVer]; //set this in weijunetworkclient
					//[dic setObject:message.protocolVersion forKey:@"protocolVersion"];
					[weiJuNetWorkClient sendData:@"userPartyMessageAction.sendMessage" parameters:dic withObject:message callbackInstance:self callbackMethod:@"sendMessageOperationDone:"];
                }
				else 
				{
					//判定是接受到的消息
					NSArray *messageArr = [message.messageContent componentsSeparatedByString:@"|"];
					//NSLog(@"received %@", message.protocolVersion);
					BOOL hasNewProtoVer=[[Utils getSharedInstance] hasNewVersonFrom:curProtoVer to:message.protocolVersion];
					switch ([message.messageType intValue])
					{
						case WEIJU_MSG_INVITE_TO_SHARE_PATH:
						{   //others send me request to share my path
							
							//find the PVC, then call its displaySharingRequestFrom method to display the request
							WeiJuPathShareVCtrl *pvc = [[WeiJuListVCtrl getSharedInstance] selectWeiJuPathShareVCtrl:nil eventID:[messageArr objectAtIndex:0]/*eventID*/ display:NO];
							
							if (pvc == nil|| pvc.hasBeenShutdown) { //i have deleted this event ([ekevent refresh]==NO in the above call) 
                                break;
                            }

							if(pvc.mySelf!=nil && pvc.mySelf.isSharing==NO &&[[NSDate date] timeIntervalSinceDate:pvc.selfEvent.endDate]<=3600) //event has not ended for an hour yet
							{
								WeiJuParticipant *sender = [pvc weiJuParticipantForUserId:message.sendUser.userId];
								if (sender==nil)
									break;
								
								NSString *eventTitle = [[[Utils alloc] init] getEventProperty:pvc.selfEvent.title nilReplaceMent:@"No title"];
								//AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert); //not for ios
								if ([[WeiJuAppPrefs getSharedInstance] inviteVibrate])
									AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
								
								//first check protocol version
								if (hasNewProtoVer)
								{
									[Utils displaySmartAlertWithTitle:[sender.fullName stringByAppendingFormat:@" invites you to share your path in calendar event \"%@\" scheduled @ %@ %@", eventTitle, [Utils getHourMinutes:pvc.selfEvent.startDate], [Utils getAMPM:pvc.selfEvent.startDate]] message:[@"However, your app version" stringByAppendingFormat:@" (%@) is lower than his/hers (%@), hence cannot display path updates from him/her. Please go to \"Settings\" from the app's main screen and then select \"Upgrade\".", curProtoVer, message.protocolVersion] noLocalNotif:YES];
									break;
								}
								
								if(pvc.isBeingDisplayed)
									[pvc displaySharingRequestFrom:message.sendUser.userId];
								else
								{
									//set the listvtrl row to display red dot
									pvc.numberOfNewMessage++;
									//if([WeiJuListVCtrl getSharedInstance].currentVCtrl!=nil) //listvctrl is being displayed - don't do this because if we are in contact book, when we go back to listvctrl, the table won't be refreshed
										[[WeiJuListVCtrl getSharedInstance].tableView reloadData];
									
									//sender.newMsg++; //no need to do this, otherwise user will tap on it and found no change on map
									[Utils displaySmartAlertWithTitle:[sender.fullName stringByAppendingFormat:@" invites you to share your path in calendar event \"%@\" scheduled @ %@ %@", eventTitle, [Utils getHourMinutes:pvc.selfEvent.startDate], [Utils getAMPM:pvc.selfEvent.startDate]] message:@"Go to the event screen to turn on path sharing" noLocalNotif:YES];
								}
								
							}
							
							break;
						}
						case WEIJU_MSG_PATH_SHARE_UPDATE:
						{
							//others send me his/her location update
							NSString *eventID = [messageArr objectAtIndex:0];
							WeiJuPathShareVCtrl *pvc = [[WeiJuListVCtrl getSharedInstance] selectWeiJuPathShareVCtrl:nil eventID:eventID display:NO]; //[[WeiJuListVCtrl getSharedInstance]searchWeiJuPathShareVCtrl:eventID];
							if (pvc == nil|| pvc.hasBeenShutdown) 
							{ //i have deleted this event, or i have not entered / created the pvc yet, no need to process the messag
								//but need to update wjlvctrl!
                                break;
                            }
														              
                            if([[NSDate date] timeIntervalSinceDate:pvc.selfEvent.endDate]<=3600) //event has not ended for an hour yet
							{
								WeiJuParticipant *sender = [pvc weiJuParticipantForUserId:message.sendUser.userId];
								if (sender==nil)
									break;
								
								NSString *eventTitle = [[[Utils alloc] init] getEventProperty:pvc.selfEvent.title nilReplaceMent:@"No title"];
								
								int firstTime = [(NSString *)[messageArr objectAtIndex:1] intValue];
								//int numberOfCoordinates = [(NSString *)[messageArr objectAtIndex:2] intValue];
								
								//first check protocol version
								if (hasNewProtoVer)
								{
									if(firstTime==1)
									{
										[Utils displaySmartAlertWithTitle:[sender.fullName stringByAppendingFormat:@" has started sharing path in calendar event \"%@\" scheduled @ %@ %@", eventTitle, [Utils getHourMinutes:pvc.selfEvent.startDate], [Utils getAMPM:pvc.selfEvent.startDate]] message:[@"However, your app version" stringByAppendingFormat:@" (%@) is lower than his/hers (%@), hence cannot display path updates from him/her. Please go to \"Settings\" from the app's main screen and then select \"Upgrade\".", curProtoVer, message.protocolVersion] noLocalNotif:YES];
									}
									break;
								}
								
								if ([[WeiJuAppPrefs getSharedInstance] pathUpdateVibrate])
									AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
								//NSLog(@"%@ %@", message.sendUser, message.sendUser.userId);
								
								//don't bother user with too many alerts popup: do it only for the first sharing (turn on sharing)
								if(firstTime==1)
								{
									[Utils displaySmartAlertWithTitle:[sender.fullName stringByAppendingFormat:@" has started sharing path in calendar event \"%@\" scheduled @ %@ %@", eventTitle, [Utils getHourMinutes:pvc.selfEvent.startDate], [Utils getAMPM:pvc.selfEvent.startDate]] message:@"Go to the event screen to view his/her path" noLocalNotif:YES];
								}

								if (pvc.hasBeenLoaded==NO) 
								{ //pvc was just created but view not loaded yet, no need to process the message
									pvc.numberOfNewMessage++;
									//sender.newMsg++; //regardless hasBeenLoaded, do this in pvc locationChanged (called by pvc's view didload)

									//if([WeiJuListVCtrl getSharedInstance].currentVCtrl!=nil) //listvctrl is being displayed - don't do this because if we are in contact book, when we go back to listvctrl, the table won't be refreshed
										[[WeiJuListVCtrl getSharedInstance].tableView reloadData];
									
									break;
								}
								
								//2985CE9E-EF80-47F5-B43C-D013DD35F79F:2FEC9B07-D96B-4725-976E-BE8BCC6FEECB|1|1|40.085768,116.552949|17:21
								NSString *locaitonStr = [messageArr objectAtIndex:3];
								NSArray *locationArr = [locaitonStr componentsSeparatedByString:@"#"];
								for (int i=0; i<[locationArr count]; i++) 
								{
									NSString *locationBoth = [locationArr objectAtIndex:i];
									NSArray *locationBothArr = [locationBoth componentsSeparatedByString:@","];
									if(i == ([locationArr count] -1)){
										[pvc participant:sender locationChanged:CLLocationCoordinate2DMake([(NSString *)[locationBothArr objectAtIndex:0] doubleValue],[(NSString *)[locationBothArr objectAtIndex:1] doubleValue]) annotationSubTitle:(NSString *)[messageArr objectAtIndex:4] updateSenderStatus:YES];
									}else {
										[pvc participant:sender locationChanged:CLLocationCoordinate2DMake([(NSString *)[locationBothArr objectAtIndex:0] doubleValue],[(NSString *)[locationBothArr objectAtIndex:1] doubleValue]) annotationSubTitle:nil updateSenderStatus:YES];
									}
								}
								
								if(pvc.isBeingDisplayed==NO)
								{
									pvc.numberOfNewMessage++;
									//sender.newMsg++; //regardless pvc.isBeingDisplayed==YES or NO, do this in pvc locationChanged

									//if([WeiJuListVCtrl getSharedInstance].currentVCtrl!=nil) //listvctrl is being displayed - don't do this because if we are in contact book, when we go back to listvctrl, the table won't be refreshed
										[[WeiJuListVCtrl getSharedInstance].tableView reloadData]; //display the reddot, plus the updated map center, in weijulistv's row
								}
								
							}
							break;
						}
						case WEIJU_MSG_PATH_SHARE_TURNED_OFF:
						{
							if (hasNewProtoVer)
								break;
							//userfriends location share switched off
							NSString *eventID = [messageArr objectAtIndex:0];
							
							WeiJuPathShareVCtrl *pvc = [[WeiJuListVCtrl getSharedInstance] selectWeiJuPathShareVCtrl:nil eventID:eventID display:NO]; //[[WeiJuListVCtrl getSharedInstance]selectWeiJuPathShareVCtrl:eventID];
							if (pvc == nil|| pvc.hasBeenShutdown) { //i have deleted this event, or i have not entered / created the pvc yet
                                break;
                            }
							if(pvc.hasBeenLoaded==NO)
								break;
							
							if([[NSDate date] timeIntervalSinceDate:pvc.selfEvent.endDate]<=3600) //event has not ended for an hour yet
							{
								WeiJuParticipant *sender = [pvc weiJuParticipantForUserId:message.sendUser.userId];
								if (sender==nil)
									break;
								
								[pvc changeSharingStatusToOffFor:sender];
								
								//we decided not to display alert for turning off sharing
								//NSString *senderName = [pvc weiJuParticipantForUserId:message.sendUser.userId].fullName;
								//NSString *eventTitle = pvc.selfEvent.title;
								//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[senderName stringByAppendingFormat:@"%@\"%@\"",@" is no longer sharing path in calendar event ", eventTitle] message:nil delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
								//[alert show];	
							}
							break;
						}
						case WEIJU_MSG_ICAL_EVENT_UPDATE:
						{
							if (hasNewProtoVer)
								break;
							[Utils log:@"%s [line:%d] checkIfCalendarHasChanged from %@", __FUNCTION__,__LINE__, message.sendUser.userLogin];
							[[WeiJuListDCtrl getSharedInstance] checkIfCalendarHasChanged];
							break;
						}
					}//switch
                    
                }
                
			} break;
				
            case NSFetchedResultsChangeDelete: {
                //[[ChatVCtrl getSharedInstance].tableView reloadData];
            } break;
				
            case NSFetchedResultsChangeMove: {
                //[[ChatVCtrl getSharedInstance].tableView reloadData];
            } break;
				
            case NSFetchedResultsChangeUpdate: {
                //[[ChatVCtrl getSharedInstance].tableView reloadData];
                
            } break;
				
            default: {
                //[[ChatVCtrl getSharedInstance].tableView reloadData];
            } break;
        }
    }
  }@catch (NSException *exception) {
      [Utils log:@"%s [line:%d] chatDctrl error:%@",__FUNCTION__,__LINE__,exception];
  }
  @finally {
        
  }  
}

#pragma mark - network callback
-(void) sendMessageOperationDone:(NSDictionary *) messageData
{    
    NSString *withObject = [ConvertData getWithOjbect:messageData];
    NSString *messageSendId = [ConvertData getValue:messageData key:@"messageSendId"];
    if (withObject == nil || messageSendId == nil) return;
    WeiJuMessage *message = ((WeiJuMessage *)withObject);
    message.messageSendId = messageSendId;
    message.messageReadStatus = @"1";
}

#pragma mark - message template
-(MessageTemplate *)getLastMessageTemplateWithMode:(int)mode
{
    NSMutableArray *orderbyArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *orderbyNameDic = [NSMutableDictionary dictionary];
    [orderbyNameDic setValue:@"createDate" forKey:@"name"];
    [orderbyNameDic setValue:@"YES" forKey:@"asscending"];
    NSArray *messageTemplateArr = [[[DataFetchUtil alloc] init] searchObjectArrayOrderby:@"MessageTemplate" filterString:[@"messageMode == " stringByAppendingFormat:@"'%i'",mode] orderbyStrArray:orderbyArray];
    if(messageTemplateArr == nil || [messageTemplateArr count] < 1)return nil;
    return [messageTemplateArr objectAtIndex:0];
}


@end

