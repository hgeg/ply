//
//  PLSpotifyController.m
//  Player
//
//  Created by Can Bülbül on 09/10/15.
//  Copyright © 2015 Can Bülbül. All rights reserved.
//

#import "PLSpotifyController.h"

@implementation PLSpotifyController

static PLSpotifyController *defaultSpotifyController = nil;

+ (PLSpotifyController *)defaultController {
    if (defaultSpotifyController == nil) {
        defaultSpotifyController = [[super allocWithZone:NULL] init];
    }
    return defaultSpotifyController;
}

- (id)init {
    if ( (self = [super init]) ) {
        self.myMusic = [[NSMutableArray alloc] initWithCapacity:32];
    }
    return self;
}


@end
