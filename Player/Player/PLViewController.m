//
//  PLViewController.m
//  Main view for the app PLY
//
//  Created by Can Bülbül on 8/21/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "GPUImage.h"
#import "PLViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"

#define itemChange MPMusicPlayerControllerNowPlayingItemDidChangeNotification
#define stateChange MPMusicPlayerControllerPlaybackStateDidChangeNotification
#define normal UIControlStateNormal
#define blur 1.1
#define height self.view.frame.size.height

@interface PLViewController ()

@end

@implementation PLViewController
@synthesize playButton;
@synthesize nextButton;
@synthesize artworkView;
@synthesize infoLabel;
@synthesize playbackIndicator;

#pragma mark -
#pragma mark View Controller Methods

- (void) viewDidLoad {
    [super viewDidLoad];
    
    /* Setting up the music player */
	player = [MPMusicPlayerController iPodMusicPlayer];
    MPMediaQuery* query = [MPMediaQuery songsQuery];
    songs = [query items]; //Select from all songs in the library
    MPMediaItem *randomTrack = [songs objectAtIndex:arc4random_uniform([songs count])];
    [player setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:songs]];
    [player setNowPlayingItem:randomTrack];
    [player beginGeneratingPlaybackNotifications];
    
    /* Subscribe to music player notifications */
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(itemChangeCallback) name:itemChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(stateChangeCallback) name:stateChange object:nil];
    
    /* Pause the player just in case */
    [player pause];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:itemChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(stateChangeCallback) name:stateChange object:nil];
    [playbackTimer invalidate];
    playbackTimer = nil;
    player = nil;
}

#pragma mark -
#pragma mark Music Player Methods

- (IBAction)playPause:(id)sender {
    /* Play/Pause button method is only for controlling music player
     * In-app events are in callback function below 
     */
    if ([player playbackState] == MPMusicPlaybackStatePlaying) 
        [player pause];
    else
        [player play];
}

- (IBAction) nextSong:(id)sender {
    /* Just go to next song */
    [player skipToNextItem];
}

- (void) stateChangeCallback{
    /* Play/Pause callback
     * change the button image and reset the indicator counter.
     */
    if ([player playbackState] == MPMusicPlaybackStatePlaying) {
        [playButton setImage:[UIImage imageNamed:@"pause.png"] forState:normal];
        playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateIndicator) userInfo:nil repeats:YES];
    } else {
        [playButton setImage:[UIImage imageNamed:@"play.png"] forState:normal];
        [playbackTimer invalidate];
    }
}

- (void) itemChangeCallback {
    /* Next item callback
     * Update the song label, background and start playing.
     */
    nowPlaying = [player nowPlayingItem];
    npDuration = [[nowPlaying valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    NSString *titleString = [nowPlaying valueForProperty:MPMediaItemPropertyTitle];
    NSString *artistString = [nowPlaying valueForProperty:MPMediaItemPropertyArtist];
    if (!artistString) {
        artistString = @"";
    }
    
    // Fetch the artwork from library
    UIImage *artworkImage = nil;
    MPMediaItemArtwork *artwork = [nowPlaying valueForProperty:MPMediaItemPropertyArtwork];
    artworkImage = [artwork imageWithSize: CGSizeMake (300, 300)];
        
    if (artworkImage) {
        /* If found, apply blur filter and insert */
        blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
        blurFilter.blurSize = blur;
        [blurFilter forceProcessingAtSize:CGSizeMake(300, 300)];
        [artworkView setImage:[blurFilter imageByFilteringImage:artworkImage]];
        
        /* Fade animation */
        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [artworkView.layer addAnimation:transition forKey:nil];
        
    } else {
        /* If not, fetch from the web 
         * It downloads the album artwork from a web service I made,
         * which finds the artwork from last.fm API
         */
        NSError* error;
        NSString* urlStr = [NSString stringWithFormat:@"http://nightbla.de:8431/?artwork=%@+%@",[artistString stringByReplacingOccurrencesOfString:@" " withString:@"+"], [titleString stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
        NSURL* URL = [NSURL URLWithString:urlStr];
        NSString *imageURL = [NSString stringWithContentsOfURL:URL encoding:NSASCIIStringEncoding error:&error];
        //NSLog(@"%@",imageURL);
        /* If fetching fails SDWebImage ensures that our placeholder is used */
        [artworkView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"placeholder.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            /* Fade animation */
            CATransition *transition = [CATransition animation];
            transition.duration = 0.2f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [artworkView.layer addAnimation:transition forKey:nil];
        }];
    }
    //Change artist name to Unknown Artist if not shown
    if ([artistString isEqualToString:@""]) {
        artistString = @"Unknown Artist";
    }
    
    /* Fade animation for label update */
    [UIView animateWithDuration:0.2 animations:^{
        infoLabel.alpha = 0.3;
    } completion:^(BOOL finished) {
        infoLabel.text = [NSString stringWithFormat:@"%@ - %@",artistString, titleString];
        [UIView animateWithDuration:0.2 animations:^{
            infoLabel.alpha = 1;
        }];
    }];
    /* Reset the indicator */
    [self updateIndicator];
        
}

- (void) updateIndicator {
    /* update function for indicator at the bottom */
    [UIView animateWithDuration:0.5 animations:^{
        @try {
            playbackIndicator.frame = CGRectMake(0,318,[player currentPlaybackTime]*1.0*height/npDuration,2);
        }
        @catch (NSException *exception) {
            playbackIndicator.frame = CGRectMake(0,318,0,2);
        }
    }];
}

@end
