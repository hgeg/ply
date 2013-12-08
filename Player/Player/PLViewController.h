//
//  PLViewController.h
//  Player
//
//  Created by Ali Can Bülbül on 8/21/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

@interface PLViewController : UIViewController <NSURLConnectionDelegate> {
    MPMusicPlayerController *player;
    NSTimer *playbackTimer;
    MPMediaItem *nowPlaying;
    NSInteger npDuration;
    NSArray *songs;
    GPUImageGaussianBlurFilter *blurFilter;
    CGPoint lastTouch;
    NSTimer *touchTimer;
    NSTimer *volumeTimer;
    NSTimer *seekTimer;
    BOOL longTouch, seeking,touched;
    BOOL gu,gr,gd,gl;
    int height,width;
}

@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;
@property (weak, nonatomic) IBOutlet UIView *playbackIndicator;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) IBOutlet UIView *menu;
@property (weak, nonatomic) IBOutlet UILabel *volumeIndicator;
@property (weak, nonatomic) IBOutlet UIView *timeIndicator;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *totaltime;

- (IBAction) playPause:(id)sender;
- (IBAction) nextSong:(id)sender;
- (void) itemChangeCallback;
- (void) stateChangeCallback;
- (void) updateIndicator;

@end
