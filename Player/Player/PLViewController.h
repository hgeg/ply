//
//  PLViewController.h
//  Player
//
//  Created by Ali Can Bülbül on 8/21/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import <Spotify/Spotify.h>

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

@class PLVisualizerView;

@interface PLViewController : UIViewController <NSURLConnectionDelegate, UIAlertViewDelegate, SPTAudioStreamingPlaybackDelegate> {
    MPMusicPlayerController *dummyPlayer;
    NSTimer *playbackTimer;
    NSInteger npDuration;
    NSArray *songs;
    CGPoint lastTouch;
    NSTimer *touchTimer;
    NSTimer *volumeTimer;
    NSTimer *seekTimer;
    UIImageView *launcher;
    BOOL tapTouch, seeking,touched;
    BOOL gu,gr,gd,gl;
    int height,width;
}

@property (strong, nonatomic) PLVisualizerView *visualizer;

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerLeftSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *playbackWidth;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;
@property (strong, nonatomic) IBOutlet UIView *playbackIndicator;
@property (weak, nonatomic) IBOutlet UILabel *albumTitle;
@property (weak, nonatomic) IBOutlet UILabel *songTitle;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) IBOutlet UIView *menu;
@property (weak, nonatomic) IBOutlet UIView *playbackContainer;
@property (weak, nonatomic) IBOutlet UILabel *playlistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ind1;
@property (weak, nonatomic) IBOutlet UIImageView *ind2;
@property (weak, nonatomic) IBOutlet UIImageView *ind3;
@property (weak, nonatomic) IBOutlet UILabel *volumeIndicator;
@property (weak, nonatomic) IBOutlet UIView *timeIndicator;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *totaltime;
@property (weak, nonatomic) IBOutlet UIView *timeView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timeViewBottom;
@property (weak, nonatomic) IBOutlet UIView *loginView;
@property (weak, nonatomic) IBOutlet UIButton *spotifyButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginLoader;

- (IBAction) playPause:(id)sender;
- (IBAction) nextSong:(id)sender;
- (void) itemChangeCallback;
- (void) stateChangeCallback;
- (void) updateIndicator;

@end
