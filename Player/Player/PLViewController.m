//
//  PLViewController.m
//  Main view for the app PLY
//
//  Created by Can Bülbül on 8/21/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "PLViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "UIButton+Glow.h"
#import "PLVisualizerView.h"
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
@synthesize songTitle;
@synthesize volumeIndicator;
@synthesize playbackIndicator;
@synthesize timeIndicator;
@synthesize currentLabel;
@synthesize totaltime;
@synthesize timeView;

#pragma mark -
#pragma mark View Controller Methods

// don't let autorotate if either control menu or
// tutorial menu is active
-(BOOL) shouldAutorotate {
    return !touched && UD_getBool(@"tutorial");
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // reassign heaght and width according to orientation
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        width = self.view.frame.size.height;
        height = self.view.frame.size.width;
    }else {
        width = self.view.frame.size.width;
        height = self.view.frame.size.height;
    }
    // call for itemChangeCallback repositions song elements
    [self itemChangeCallback];
    [self updateIndicator];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    /* Rating alert */
    int opens = UD_getInt(@"opens") ? UD_getInt(@"opens") : 0;
    bool rated = UD_getBool(@"rated") ? UD_getBool(@"rated") : false;
    opens++;
    UD_setInt(@"opens", opens);
    UD_setBool(@"rated", rated);
    
    UIAlertView *alert;
    if (opens%10==0 && !rated) {
        alert = [[UIAlertView alloc] initWithTitle:@"Rate PLY" message:@"Enjoying PLY? Please rate this app on AppStore." delegate:self cancelButtonTitle:@"Don't bother me with this" otherButtonTitles:@"Rate now", @"Maybe later", nil];
        [alert show];
    }
    /* End of raiting alert */
    
    /* Initialize dimensions */
    width = self.view.frame.size.width;
    height = self.view.frame.size.height;
    
    /* Show tutorial view at first open */
    if (!UD_getBool(@"tutorial")) {
        UIImageView *tutorial = [[UIImageView alloc] initWithFrame:rect(0, 0, 320, 568)];
        tutorial.image = [UIImage imageNamed:@"tutorial.png"];
        tutorial.userInteractionEnabled = YES;
        UITapGestureRecognizer *tgw = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeTutorial:)];
        [tutorial addGestureRecognizer:tgw];
        tutorial.alpha = 1;
        [self.view addSubview:tutorial];
        [self.view bringSubviewToFront:tutorial];
    }
    
    
    /* A pseudo LaunchImage that fades out */
    launcher = [[UIImageView alloc] initWithFrame:rect(0, 0, 320, 568)];
    launcher.image = [UIImage imageNamed:@"s_l_i5.png"];
    launcher.center = point(160, height/2);
    launcher.alpha = 1;
    [self.view addSubview:launcher];
    
    /* add dummy volume indicator */
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame: rect(-1000, -1000, 0, 0)];
    [volumeView setUserInteractionEnabled:NO];
    volumeView.showsRouteButton = NO;
    [self.view addSubview: volumeView];
    
    /* Setting up the music player */
	player = [MPMusicPlayerController iPodMusicPlayer];
    MPMediaQuery* query = [MPMediaQuery songsQuery];
    songs = [query items]; //Select from all songs in the library
    /* check for applicable music library */
    if([songs count]>0) {
        MPMediaItem *randomTrack = [songs objectAtIndex:arc4random_uniform([songs count])];
        [player setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:songs]];
        [player setNowPlayingItem:randomTrack];
        [player beginGeneratingPlaybackNotifications];
    } else {
        artworkView.alpha = 0;
        artistLabel.alpha = 0;
        timeView.alpha = 0;
        
        [songTitle setText:@"It seems you don't have any music in your library. Add some songs via itunes to use PLY."];
        [songTitle setTextColor:rgba(255, 255, 255, 200)];
        [songTitle setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20]];
        songTitle.clipsToBounds = NO;
        [songTitle setTextAlignment:NSTextAlignmentCenter];
        songTitle.alpha = 1;
    }
    
    /* Subscribe to music player notifications */
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(itemChangeCallback) name:itemChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(stateChangeCallback) name:stateChange object:nil];
    
    /* Initialize Visualizer */
    self.visualizer = [[PLVisualizerView alloc] initWithFrame:self.view.frame];
    /*[_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];*/
    [self.backgroundView addSubview:_visualizer];
    
    /* Circular artwork */
    artworkView.layer.masksToBounds = YES;
    artworkView.layer.cornerRadius  = 50.0f;
    artworkView.layer.borderWidth   = 2.0f;
    artworkView.layer.borderColor   = [rgba(210, 250, 255, 200) CGColor];
    
    
    /* Start the player */
    [player play];
    
    /* Hide the overlay view*/
    overlay.alpha = 0;
    
    /* reset the flags */
    gu = false;
    gr = false;
    gd = false;
    gl = false;
    touched = false;
    seeking = false;
    tapTouch = false;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:itemChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(stateChangeCallback) name:stateChange object:nil];
    [playbackTimer invalidate];
    playbackTimer = nil;
    player = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *stringURL = @"http://orkestra.co/PLY/";
    NSURL *url = [NSURL URLWithString:stringURL];
    switch (buttonIndex) {
        case 1:
            [[UIApplication sharedApplication] openURL:url];
            UD_setBool(@"rated", true);
            break;
        case 0:
            UD_setBool(@"rated", true);
            break;
        default:
            break;
    }
}

- (void) removeTutorial:(UITapGestureRecognizer *)recognizer {
    [UIView animateWithDuration:0.3 animations:^{
        recognizer.view.alpha = 0;
    } completion:^(BOOL finished) {
        [recognizer.view removeFromSuperview];
        MPMediaQuery* query = [MPMediaQuery songsQuery];
        songs = [query items]; //Select from all songs in the library
        if([songs count]>0) {
            UD_setBool(@"tutorial", true);
        }
    }];
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


- (void) stateChangeCallback{
    /* Play/Pause callback
     * change the button image and reset the indicator counter.
     */
    if ([player playbackState] == MPMusicPlaybackStatePlaying || [player playbackState] == MPMusicPlaybackStateSeekingForward || [player playbackState] == MPMusicPlaybackStateSeekingBackward) {
        playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateIndicator) userInfo:nil repeats:YES];
        [self.visualizer start];
    } else {
        [playbackTimer invalidate];
        [self.visualizer stop];
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
        [artworkView setImage:artworkImage];
        
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
        NSURL* URL = [NSURL URLWithString:urlStr];
        NSString *imageURL = [NSString stringWithContentsOfURL:URL encoding:NSASCIIStringEncoding error:&error];
        /* If fetching fails SDWebImage ensures that our placeholder is used */
        [artworkView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"default.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
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
    
    /* Fade animation for label update */
    [UIView animateWithDuration:0.2 animations:^{
        
        artistLabel.alpha = 0.3;
        songTitle.alpha   = 0.3;
        timeView.alpha   = 0.3;
    } completion:^(BOOL finished) {
        artistLabel.text = artistString;
        [songTitle setText:titleString];
        [songTitle setTextColor:rgba(255, 255, 255, 200)];
        [songTitle setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20]];
        [songTitle setTextAlignment:NSTextAlignmentCenter];
        
        float hoff = songTitle.frame.size.height - [songTitle sizeThatFits:CGSizeMake(songTitle.frame.size.width,songTitle.frame.size.height)].height;
        timeView.center = point(timeView.center.x, songTitle.frame.origin.y+songTitle.frame.size.height-hoff+16);
        
        currentLabel.text = @"00:00";
        [UIView animateWithDuration:0.2 animations:^{
            artistLabel.alpha = 1;
            songTitle.alpha   = 1;
            timeView.alpha    = 1;
        }];
        if(launcher.alpha>0)
            [UIView animateWithDuration:0.3 animations:^{
                launcher.alpha = 0;
            } completion:^(BOOL finished) {
                [launcher removeFromSuperview];
            }];
    }];
    
    //[player play];
    
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
            
            if(playbackIndicator.frame.size.width<32) {
                timeIndicator.center = point(32, height-40);
                timeIndicator.alpha = (playbackIndicator.frame.size.width)/40.0;
            } else if(playbackIndicator.frame.size.width>width-32) {
                timeIndicator.center = point(width-32, height-40);
                timeIndicator.alpha = (width-playbackIndicator.frame.size.width)/40.0;
            } else {
                timeIndicator.center = point(playbackIndicator.frame.size.width, height-40);
            }
        }
        @catch (NSException *exception) {
            playbackIndicator.frame = rect(0,318,0,2);
        }
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!touched && UD_getBool(@"tutorial")) {
        volumeIndicator.text = format(@"%d",(int)(player.volume*100));
        tapTouch = true;
        touched = true;
        lastTouch = [((UITouch *)[[touches allObjects] lastObject]) locationInView:self.view];
        touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(showMenu) userInfo:nil repeats:NO];

    }
}

- (void) showMenu {
    tapTouch = false;
    menu.center = lastTouch;
    [UIView animateWithDuration:0.1 animations:^{
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
    [UIView animateWithDuration:0.1 animations:^{
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
    CGPoint p = [((UITouch *)[touches allObjects][0]) locationInView:self.view];
    UIButton *volup   = (UIButton *)[menu viewWithTag:1],
             *next    = (UIButton *)[menu viewWithTag:2],
             *voldown = (UIButton *)[menu viewWithTag:3],
             *prev    = (UIButton *)[menu viewWithTag:4];
    
    float dist = (p.x-lastTouch.x)*(p.x-lastTouch.x)+(p.y-lastTouch.y)*(p.y-lastTouch.y);
    if (tapTouch && dist>2000) {
        [self showMenu];
        tapTouch = false;
        [touchTimer invalidate];
    }
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
            seeking = false;
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
            seeking = false;
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
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [touchTimer invalidate];
    if(tapTouch) [self playPause:nil];
    if (gr) {
        [self nextSong:nil];
    }else if(gl){
        [self prevSong:nil];
    }
    /*if(!(gr||gl||gu||gd)){
        [self playPause:nil];
    }*/
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
