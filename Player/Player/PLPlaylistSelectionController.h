//
//  PLPlaylistSelectionController.h
//  Player
//
//  Created by Can Bülbül on 09/10/15.
//  Copyright © 2015 Can Bülbül. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PLPlaylistSelectionController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *playlists;
@property (strong, nonatomic) NSNumber *selected;

@end
