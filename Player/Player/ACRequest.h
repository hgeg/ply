//
//  ACRequest.h
//  AppCounterLib
//
//  Created by Ali Can Bülbül on 9/12/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACRequest : NSObject
{
    NSString *appName;
    //Response ata of the last request
    BOOL completed;
    NSError *error;
    NSURLResponse *response;
}

+ (id) sharedRequest;

- (void) sendAppOpen;
- (void) sendAction: (NSString *)action;

@end
