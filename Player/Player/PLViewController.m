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
#import "UIButton+Glow.h"
#import <math.h>

#define itemChange MPMusicPlayerControllerNowPlayingItemDidChangeNotification
#define stateChange MPMusicPlayerControllerPlaybackStateDidChangeNotification
#define normal UIControlStateNormal
#define blur 1.1

#define up    point(120,24)
#define right point(216,120)
#define down  point(120,216)
#define left  point(24,120)

@interface PLViewController ()

@end

@implementation PLViewController
@synthesize statusImage;
@synthesize overlay;
@synthesize menu;
@synthesize artworkView;
@synthesize artistLabel;
@synthesize songLabel;
@synthesize volumeIndicator;
@synthesize playbackIndicator;
@synthesize timeIndicator;
@synthesize currentLabel;
@synthesize totaltime;

#pragma mark -
#pragma mark View Controller Methods

-(BOOL) shouldAutorotate {
    return !touched;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        width = self.view.frame.size.height;
        height = self.view.frame.size.width;
    }else {
        width = self.view.frame.size.width;
        height = self.view.frame.size.height;
    }
    [self updateIndicator];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    width = self.view.frame.size.width;
    height = self.view.frame.size.height;
    
    /* add dummy volume indicator */
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame: rect(-1000, -1000, 0, 0)];
    [volumeView setUserInteractionEnabled:NO];
    volumeView.showsRouteButton = NO;
    [self.view addSubview: volumeView];
    
    /* Setting up the music player */
	player = [MPMusicPlayerController iPodMusicPlayer];
    MPMediaQuery* query = [MPMediaQuery songsQuery];
    songs = [query items]; //Select from all songs in the library
    if([songs count]>0) {
        MPMediaItem *randomTrack = [songs objectAtIndex:arc4random_uniform([songs count])];
        [player setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:songs]];
        [player setNowPlayingItem:randomTrack];
        [player beginGeneratingPlaybackNotifications];
    }
    
    /* Subscribe to music player notifications */
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(itemChangeCallback) name:itemChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(stateChangeCallback) name:stateChange object:nil];
    
    /* Pause the player just in case */
    [player pause];
    
    /* Hide the overlay view*/
    overlay.alpha = 0;
    
    /* reset the flags */
    gu = false;
    gr = false;
    gd = false;
    gl = false;
    touched = false;
    seeking = false;
    longTouch = false;
    
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
    if ([player playbackState] == MPMusicPlaybackStatePlaying){
        statusImage.image = [UIImage imageNamed:@"pause.png"];
        [UIView animateWithDuration:0.1 animations:^{
            statusImage.alpha = 0.6;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4 animations:^{
                statusImage.alpha = 0;
            }];
        }];
        [player pause];
    }else{
        statusImage.image = [UIImage imageNamed:@"play.png"];
        [UIView animateWithDuration:0.1 animations:^{
            statusImage.alpha = 0.6;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4 animations:^{
                statusImage.alpha = 0;
            }];
        }];
        [player play];
    }
}

- (IBAction) nextSong:(id)sender {
    /* Just go to next song */
    [player endSeeking];
    [player skipToNextItem];
}

- (IBAction) prevSong:(id)sender {
    /* Just go to next song */
    [player endSeeking];
    [player skipToPreviousItem];
}

- (void) seekForward: (NSTimer *)timer {
    seeking = true;
    [player beginSeekingForward];
}

- (void) seekBackwards: (NSTimer *)timer  {
    seeking = true;
    [player beginSeekingBackward];
}


- (void) stateChangeCallback{
    /* Play/Pause callback
     * change the button image and reset the indicator counter.
     */
    if ([player playbackState] == MPMusicPlaybackStatePlaying || [player playbackState] == MPMusicPlaybackStateSeekingForward || [player playbackState] == MPMusicPlaybackStateSeekingBackward) {
        playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateIndicator) userInfo:nil repeats:YES];
    } else {
        [playbackTimer invalidate];
    }
}

- (void) itemChangeCallback {
    /* Next item callback
     * Update the song label, background and start playing.
     */
    nowPlaying = [player nowPlayingItem];
    npDuration = [[nowPlaying valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    NSString *titleString = [[nowPlaying valueForProperty:MPMediaItemPropertyTitle] uppercaseString];
    NSString *artistString = [[nowPlaying valueForProperty:MPMediaItemPropertyArtist] uppercaseString];
    if (!artistString) {
        artistString = @"";
    }
    totaltime.text = format(@"%.2d:%.2d",(int)(npDuration/60),((int)npDuration%60));
    
    // Fetch the artwork from library
    UIImage *artworkImage = nil;
    MPMediaItemArtwork *artwork = [nowPlaying valueForProperty:MPMediaItemPropertyArtwork];
    artworkImage = [artwork imageWithSize: CGSizeMake (300, 300)];
        
    if (artworkImage) {
        /* If found, apply blur filter and insert */
        blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
        blurFilter.blurSize = blur;
        [blurFilter forceProcessingAtSize:CGSizeMake(300, 300)];
        artworkView.contentMode = UIViewContentModeScaleAspectFill;
        [artworkView setImage:[blurFilter imageByFilteringImage:artworkImage]];
        artworkView.tintColor = rgba(35,149,155,128);
        
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
        NSString* urlStr = format(@"http://hgeg.io/lastrk/?artwork=%@",
          [self urlencode:
           [NSString stringWithFormat:@"%@ %@",artistString, titleString]
          ]
        );
        NSLog(@"req: %@",urlStr);
        NSURL* URL = [NSURL URLWithString:urlStr];
        NSString *imageURL = [NSString stringWithContentsOfURL:URL encoding:NSASCIIStringEncoding error:&error];
        NSLog(@"res: %@",imageURL);
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
        artistString = @"UNKNOWN ARTIST";
    }
    
    currentLabel.text = @"00:00";
    
    /* Fade animation for label update */
    [UIView animateWithDuration:0.2 animations:^{
        artistLabel.alpha = 0.3;
        songLabel.alpha   = 0.3;
        totaltime.alpha   = 0.3;
    } completion:^(BOOL finished) {
        artistLabel.text = artistString;
        songLabel.text   = titleString;
        [UIView animateWithDuration:0.2 animations:^{
            artistLabel.alpha = 1;
            songLabel.alpha   = 1;
            totaltime.alpha   = 1;
        }];
    }];
    
    
    [player play];
    
    /* Reset the indicator */
    [self updateIndicator];
        
}

- (void) updateIndicator {
    /* update function for indicator at the bottom */
    float d = 0.5;
    if([player playbackState] == MPMusicPlaybackStatePlaying) {
        d = 0.5;
    }else d = 1;
    [UIView animateWithDuration:d animations:^{
        @try {
            playbackIndicator.frame = rect(0,height-8,[player currentPlaybackTime]*1.0*width/npDuration,8);
            currentLabel.text = format(@"%.2d:%.2d",(int)([player currentPlaybackTime]/60),((int)[player currentPlaybackTime]%60));
            
            if(playbackIndicator.frame.size.width<32)
                timeIndicator.center = point(32, height-40);
            else if(playbackIndicator.frame.size.width>width-32)
                timeIndicator.center = point(width-32, height-40);
            else
                timeIndicator.center = point(playbackIndicator.frame.size.width, height-40);
        }
        @catch (NSException *exception) {
            playbackIndicator.frame = rect(0,318,0,2);
        }
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!touched) {
        volumeIndicator.text = format(@"%d",(int)(player.volume*100));
        longTouch = false;
        touched = true;
        lastTouch = [((UITouch *)[[touches allObjects] lastObject]) locationInView:self.view];
        touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(showMenu) userInfo:nil repeats:NO];
    }
}

- (void) showMenu {
    longTouch = true;
    menu.center = lastTouch;
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 1;
    }];
    UIView *volup   = [menu viewWithTag:1],
    *next    = [menu viewWithTag:2],
    *voldown = [menu viewWithTag:3],
    *prev    = [menu viewWithTag:4];
    CGPoint center = point(120,120);
    volup.center   = center;
    next.center    = center;
    voldown.center = center;
    prev.center    = center;
    [UIView animateWithDuration:0.4 animations:^{
        volup.center   = up;
        next.center    = right;
        voldown.center = down;
        prev.center    = left;
    }];
}

- (void) incVolume: (NSTimer *)timer {
    if (player.volume>=1) [timer invalidate];
    player.volume += 0.01;
    volumeIndicator.text = format(@"%d",(int)(player.volume*100));
}

- (void) decVolume: (NSTimer *)timer  {
    if (player.volume<=0) [timer invalidate];
    player.volume -= 0.01;
    volumeIndicator.text = format(@"%d",(int)(player.volume*100));
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!longTouch) return;
    CGPoint p = [((UITouch *)[touches allObjects][0]) locationInView:self.view];
    UIButton *volup   = (UIButton *)[menu viewWithTag:1],
             *next    = (UIButton *)[menu viewWithTag:2],
             *voldown = (UIButton *)[menu viewWithTag:3],
             *prev    = (UIButton *)[menu viewWithTag:4];
    
    float dist = (p.x-lastTouch.x)*(p.x-lastTouch.x)+(p.y-lastTouch.y)*(p.y-lastTouch.y);
    if(dist<520000 && dist>4000) {
        float angle = r2d(-atan2f((p.y-lastTouch.y), (p.x-lastTouch.x)));
        if((angle<20.0 && angle>-20.0) && !gr) {
            gu = false;
            gr = true;
            gd = false;
            gl = false;
            [volup dim];
            [next glow];
            [voldown dim];
            [prev dim];
            [volumeTimer invalidate];
            seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(seekForward:) userInfo:nil repeats:NO];
        }
        if((angle<110 && angle>70) && !gu) {
            gu = true;
            gr = false;
            gd = false;
            gl = false;
            [volup glow];
            [next dim];
            [voldown dim];
            [prev dim];
            if(!seeking)
                volumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(incVolume:) userInfo:nil repeats:YES];
        }
        if((angle<-160 || angle>160) && !gl) {
            gu = false;
            gr = false;
            gd = false;
            gl = true;
            [volup dim];
            [next dim];
            [voldown dim];
            [prev glow];
            [volumeTimer invalidate];
            seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(seekBackwards:) userInfo:nil repeats:NO];
        }
        if((angle<-70 && angle>-110) && !gd) {
            gu = false;
            gr = false;
            gd = true;
            gl = false;
            [volup dim];
            [next dim];
            [voldown glow];
            [prev dim];
            volumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(decVolume:) userInfo:nil repeats:YES];
        }
    }else {
        [volup dim];
        [next dim];
        [voldown dim];
        [prev dim];
        [volumeTimer invalidate];
        gu = false;
        gr = false;
        gd = false;
        gl = false;
        seeking = false;
        [player endSeeking];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!longTouch){
        CGPoint p = [((UITouch *)[touches allObjects][0]) locationInView:self.view];
        float dist = (p.x-lastTouch.x)*(p.x-lastTouch.x)+(p.y-lastTouch.y)*(p.y-lastTouch.y);
        if (dist<1024) {
            [self playPause:nil];
        }
        [touchTimer invalidate];
    }
    [player endSeeking];
    if (gr && !seeking) {
        [self nextSong:nil];
    }else if(gl && !seeking){
        [self prevSong:nil];
    }
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha=0;
    }];
    UIButton *volup   = (UIButton *)[menu viewWithTag:1],
             *next    = (UIButton *)[menu viewWithTag:2],
             *voldown = (UIButton *)[menu viewWithTag:3],
             *prev    = (UIButton *)[menu viewWithTag:4];
    
    [volup dim];
    [next dim];
    [voldown dim];
    [prev dim];
    
    gu = false;
    gr = false;
    gd = false;
    gl = false;
    touched = false;
    seeking = false;
    longTouch = false;
    
    [volumeTimer invalidate];
    [seekTimer invalidate];
    
    CGPoint center = point(120,120);
    [UIView animateWithDuration:0.3 animations:^{
        volup.center   = center;
        next.center    = center;
        voldown.center = center;
        prev.center    = center;
    }];
    
    [player endSeeking];
}

- (NSString *)urlencode:(NSString *)str {
    NSString *urlString = [[str componentsSeparatedByCharactersInSet:
                            [NSCharacterSet decimalDigitCharacterSet]]
                           componentsJoinedByString:@""];
    CFStringRef newString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8);
    return (NSString *)CFBridgingRelease(newString);
}


@end
