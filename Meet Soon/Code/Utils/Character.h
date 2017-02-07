//
//  Chracter.h
//  PhoneBook
//
//  Created by apple on 11-12-19.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Character : NSObject
{
    NSArray *allCharacter;
}

@property(strong,nonatomic) NSArray *allCharacter;

-(NSString *)getFirstCharacter:(NSString *)strText;

@end
