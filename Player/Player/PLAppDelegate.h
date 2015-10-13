//
//  PLAppDelegate.h
//  Player
//
//  Created by Ali Can Bülbül on 8/21/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import <Spotify/Spotify.h>

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;

@end
