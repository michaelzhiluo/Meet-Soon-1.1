//
//  ChatDCtrl.h
//  WeiJu
//
//  Created by Michael Luo on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Message,WeiJuData,MessageTemplate;

@interface ChatDCtrl : NSObject <NSFetchedResultsControllerDelegate>

extern const int WEIJU_MSG_INVITE_TO_SHARE_PATH;
extern const int WEIJU_MSG_PATH_SHARE_UPDATE;
extern const int WEIJU_MSG_PATH_SHARE_TURNED_OFF;
extern const int WEIJU_MSG_ICAL_EVENT_UPDATE;

@property (nonatomic, strong) NSFetchedResultsController *fetcher;



#pragma mark - coredata methods
- (id)initWithWeiJuData:(WeiJuData *)weiJuData;

- (void) startFetcher;
- (void) startFetcher:(NSString *)weiJuId;

- (void) startFetcherWithWeiJuClientId:(NSString *)weiJuClientId;

- (int)numberOfSections;

- (int)numberOfRowsInSection:(NSInteger)section;

- (Message *)objectInListAtIndex:(NSIndexPath *)theIndex;

- (void)sendMessageOperationDone:(NSDictionary *) messageData;

- (MessageTemplate *)getLastMessageTemplateWithMode:(int)mode;

+(ChatDCtrl *)getSharedInstance;
@end
