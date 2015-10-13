//
//  PLSpotifyController.h
//  Player
//
//  Created by Can Bülbül on 09/10/15.
//  Copyright © 2015 Can Bülbül. All rights reserved.
//

#import <Spotify/Spotify.h>
#import <Foundation/Foundation.h>

@interface PLSpotifyController : NSObject <SPTAudioStreamingPlaybackDelegate>

@property(strong, nonatomic) SPTAudioStreamingController *player;
@property(strong, nonatomic) SPTSession *session;
@property(strong, nonatomic) SPTPlaylistList *playlists;
@property(strong, nonatomic) NSMutableArray *myMusic;

+ (PLSpotifyController *)defaultController;

@end
