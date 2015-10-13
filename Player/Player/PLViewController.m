//
//  PLViewController.m
//  Main view for the app PLY
//
//  Created by Can Bülbül on 8/21/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "PLViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "PLVisualizerView.h"
#import "PLPlaylistSelectionController.h"
#import "PLSpotifyController.h"
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
@synthesize albumTitle;
@synthesize volumeIndicator;
@synthesize playbackIndicator;
@synthesize timeIndicator;
@synthesize playbackWidth;
@synthesize currentLabel;
@synthesize totaltime;
@synthesize timeView;
@synthesize timeViewBottom;

@synthesize ind1;
@synthesize ind2;
@synthesize ind3;

#pragma mark -
#pragma mark View Controller Methods

// don't let autorotate if either control menu or
// tutorial menu is active
-(BOOL) shouldAutorotate {
    return false && !touched && UD_getBool(@"tutorial");
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // reassign height and width according to orientation
    if(toInterfaceOrientation ==   UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        width = self.view.frame.size.height;
        height = self.view.frame.size.width;
    }else {
        width = self.view.frame.size.height;
        height = self.view.frame.size.width;
    }
    // call for itemChangeCallback repositions song elements
    [self itemChangeCallback];
    [self updateIndicator];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.playbackIndicator = [[UIView alloc] initWithFrame:rect(0,0,0,0)];
    self.playbackIndicator.backgroundColor = hex(0x1c9ba0);
    [self.view addSubview:playbackIndicator];
    [self.view sendSubviewToBack:playbackIndicator];
    
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
    
    /* Show tutorial view at first open*/
    if (!UD_getBool(@"tutorial")) {
        UIImageView *tutorial = [[UIImageView alloc] initWithFrame:self.view.frame];
        tutorial.image = [UIImage imageNamed:@"tutorial"];
        tutorial.contentMode = UIViewContentModeScaleAspectFill;
        tutorial.userInteractionEnabled = YES;
        UITapGestureRecognizer *tgw = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeTutorial:)];
        [tutorial addGestureRecognizer:tgw];
        tutorial.alpha = 1;
        [self.view addSubview:tutorial];
        [self.view bringSubviewToFront:tutorial];
        UD_setBool(@"tutorial", true);
    }
    
    /* add dummy volume indicator */
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame: rect(-1000, -1000, 0, 0)];
    [volumeView setUserInteractionEnabled:NO];
    volumeView.showsRouteButton = NO;
    [self.view addSubview: volumeView];
    dummyPlayer = [MPMusicPlayerController iPodMusicPlayer];
    
    NC_addObserver(@"AUTH_OK", @selector(preparePlayerView:));
    NC_addObserver(@"AUTH_ERROR", @selector(preparePlayerView:));
    NC_addObserver(@"selected_playlist", @selector(changePlaylist:));
    
    /* Initialize Visualizer */
    self.visualizer = [[PLVisualizerView alloc] initWithFrame:self.view.frame];
    /*[_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];*/
    [self.backgroundView addSubview:_visualizer];
    [self.visualizer stop];
    
    artworkView.alpha = 1;
    artworkView.clipsToBounds = true;
    artworkView.image = [self maskImage:[UIImage imageNamed:@"artwork_mask"] withMask:artworkView.image];
    
    SPTSession *pSession = [NSKeyedUnarchiver unarchiveObjectWithData:UD_getObj(@"PLSessionPersistKey")];
    NSLog(@"persisted Session: %@", pSession);
    if (pSession) {
        NSNotification *n = [[NSNotification alloc] initWithName:@"AUTH_D" object:nil userInfo:@{@"session":@"RESTORE"}];
        [self preparePlayerView:n];
    }else {
        [[SPTAuth defaultInstance] setClientID:@"a780ee73f16647c1850bfdfc5f627eb4"];
        [[SPTAuth defaultInstance] setRedirectURL:[NSURL URLWithString:@"ply://auth"]];
        //[[SPTAuth defaultInstance] setTokenSwapURL:[NSURL URLWithString:@"https://csgn.us/ply/swap/"]];
        //[[SPTAuth defaultInstance] setTokenRefreshURL:[NSURL URLWithString:@"https://csgn.us/ply/refresh/"]];
        [[SPTAuth defaultInstance] setRequestedScopes:@[SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthUserLibraryReadScope]];
        self.loginLoader.alpha = 0;
    }
}

- (IBAction)spotifySignIn:(id)sender {
    self.spotifyButton.enabled = false;
    
    // Construct a login URL and open it
    NSURL *loginURL = [[SPTAuth defaultInstance] loginURL];
    self.loginLoader.alpha = 1;
    [self.loginLoader startAnimating];
    
    // Opening a URL in Safari close to application launch may trigger
    // an iOS bug, so we wait a bit before doing so.
    [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                            withObject:loginURL afterDelay:0.1];
}

- (BOOL) nextSongsFrom:(SPTListPage *)list {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    [[SPTRequest sharedHandler] performRequest:[list createRequestForNextPageWithAccessToken:controller.session.accessToken error:nil] callback:^(NSError *error, NSURLResponse *response, NSData *data) {
        SPTListPage *newlist = [SPTListPage listPageFromData:data withResponse:response expectingPartialChildren:true rootObjectKey:nil error:nil];
        for (SPTSavedTrack *i in newlist.items) {
            [controller.myMusic addObject:i.uri];
        }
        if (newlist.hasNextPage) {
            [self nextSongsFrom:newlist];
        }
    }];
    return false;
}

- (void) changePlaylist:(NSNotification *) notification {
    
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    NSDictionary *ui = notification.userInfo;
    controller.player.shuffle = true;
    
    if ([ui[@"selected"] integerValue] == -1) {
        
        [controller.player playURIs:controller.myMusic fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"*** Starting playback got error2: %@", error);
                return;
            }
            [self itemChangeCallback];
        }];
        
    } else {
        NSInteger playlist = [ui[@"selected"] integerValue];
        [controller.player playURIs:@[((SPTPartialPlaylist *)(controller.playlists.items[playlist])).playableUri] fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"*** Starting playback got error: %@", error);
                return;
            }
            self.loginView.alpha = 0;
            self.playlistLabel.text = [((SPTPartialPlaylist *)(controller.playlists.items[playlist])).name uppercaseString];
            [self itemChangeCallback];
        }];
    }
}

- (void) preparePlayerView:(NSNotification*) notification {
    
    
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    
    if([notification.userInfo[@"session"] isEqual:@"ERROR"]) {
        //[[SPTAuth defaultInstance] setTokenSwapURL:nil];
        //[[SPTAuth defaultInstance] setTokenRefreshURL:nil];
        self.loginLoader.alpha = 0;
        self.spotifyButton.enabled = true;
        return;
    }
    
    if([notification.userInfo[@"session"] isEqual:@"RESTORE"]) {
        
        SPTSession *restored = [NSKeyedUnarchiver unarchiveObjectWithData:UD_getObj(@"PLSessionPersistKey")];
        NSLog(@"restored Session: %@", restored);
        controller.session = restored;
        
        [SPTPlaylistList playlistsForUserWithSession:controller.session callback:^(NSError *error, id object) {
            controller.playlists = object;
        }];
        
        [SPTRequest savedTracksForUserInSession:controller.session callback:^(NSError *error, id object) {
            SPTListPage *mlist = (SPTListPage *)object;
            if (error != nil) {
                NSLog(@"*** Starting playback got error: %@", error);
                return;
            }
            
            NSLog(@"my music: %@",mlist);
            for (SPTSavedTrack *i in mlist.items) {
                [controller.myMusic addObject:i.uri];
            }
            if (mlist.hasNextPage) [self nextSongsFrom:mlist];
            [controller.player playURIs:controller.myMusic fromIndex:0 callback:^(NSError *error) {
                if (error != nil) {
                    NSLog(@"*** Starting playback got error: %@", error);
                    return;
                }
                
                self.loginView.alpha = 0;
                self.loginLoader.alpha = 0;
                [self.loginLoader stopAnimating];
                self.playlistLabel.text = @"SAVED TRACKS";
                [self itemChangeCallback];
                
            }];
            
        }];
        return;
    }
    
    [controller.player loginWithSession:controller.session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Logging in got error: %@", error);
            self.spotifyButton.enabled = true;
            return;
        }
        
        UD_setObj(@"PLSessionPersistKey", [NSKeyedArchiver archivedDataWithRootObject:controller.session]);
        NSLog(@"saved Session: %@", controller.session);
        
        controller.player.playbackDelegate = self;
        controller.player.shuffle = true;
        
        [SPTPlaylistList playlistsForUserWithSession:controller.session callback:^(NSError *error, id object) {
            controller.playlists = object;
        }];
        
        [SPTRequest savedTracksForUserInSession:controller.session callback:^(NSError *error, id object) {
            SPTListPage *mlist = (SPTListPage *)object;
            if (error != nil) {
                NSLog(@"*** Starting playback got error: %@", error);
                return;
            }
            
            NSLog(@"my music: %@",mlist);
            for (SPTSavedTrack *i in mlist.items) {
                [controller.myMusic addObject:i.uri];
            }
            if (mlist.hasNextPage) [self nextSongsFrom:mlist];
            [controller.player playURIs:controller.myMusic fromIndex:0 callback:^(NSError *error) {
                if (error != nil) {
                    NSLog(@"*** Starting playback got error: %@", error);
                    return;
                }
                
                self.loginView.alpha = 0;
                self.loginLoader.alpha = 0;
                [self.loginLoader stopAnimating];
                self.playlistLabel.text = @"SAVED TRACKS";
                [self itemChangeCallback];
                
            }];
            
        }];
        
    }];
    
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
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:itemChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(stateChangeCallback) name:stateChange object:nil];
    [playbackTimer invalidate];
    playbackTimer = nil;
    controller.player = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *stringURL = @"http://ply.orkestra.co/";
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
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    /* Play/Pause button method is only for controlling music player
     * In-app events are in callback function below
     */
    if (controller.player.isPlaying){
        [statusImage setImage:[UIImage imageNamed:@"pause"]];
        [UIView animateWithDuration:0.2 animations:^{
            statusImage.alpha = 0.6;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                statusImage.alpha = 0;
            } completion:nil];
        }];
    }else{
        [statusImage setImage:[UIImage imageNamed:@"play"]];
        [UIView animateWithDuration:0.2 animations:^{
            statusImage.alpha = 0.6;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                statusImage.alpha = 0;
            } completion:nil];
        }];
    }
    [controller.player setIsPlaying:!controller.player.isPlaying callback:nil];
    
}

- (IBAction) nextSong:(id)sender {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    /* Just go to next song */
    [controller.player skipNext:^(NSError *error) {
        [self itemChangeCallback];
    }];
}

- (IBAction) prevSong:(id)sender {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    /* Just go to previous song */
    [controller.player skipPrevious:^(NSError *error) {
        [self itemChangeCallback];
    }];
}


- (void) stateChangeCallback{
    /* Play/Pause callback
     * change the button image and reset the indicator counter.
     */
}

- (void) itemChangeCallback {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    /* Next item callback
     * Update the song label, background and start playing.
     */
    [SPTTrack trackWithURI:controller.player.currentTrackURI session:controller.session callback:^(NSError *error, id object) {
        SPTTrack *t = object;
        // Fetch the artwork from library
        [artworkView sd_setImageWithURL:t.album.largestCover.imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            artworkView.clipsToBounds = true;
            artworkView.image = [self maskImage:[UIImage imageNamed:@"artwork_mask"] withMask:artworkView.image];
        }];
        
        npDuration = controller.player.currentTrackDuration;
        totaltime.text = format(@"%.2d:%.2d",(int)(npDuration/60),((int)npDuration%60));
        
        /* Fade animation */
        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [artworkView.layer addAnimation:transition forKey:nil];
        
        /* Fade animation for label update */
        [UIView animateWithDuration:0.2 animations:^{
            artistLabel.alpha = 0.3;
            albumTitle.alpha  = 0.3;
            songTitle.alpha   = 0.3;
            timeView.alpha    = 0.3;
        } completion:^(BOOL finished) {
            NSString *titleString = [controller.player.currentTrackMetadata[SPTAudioStreamingMetadataTrackName] uppercaseString];
            NSString *artistString = [controller.player.currentTrackMetadata[SPTAudioStreamingMetadataArtistName] uppercaseString];
            artistLabel.text = artistString;
            songTitle.text = titleString;
            albumTitle.text = [controller.player.currentTrackMetadata[SPTAudioStreamingMetadataAlbumName] uppercaseString];
            
            float hoff = songTitle.frame.size.height - [songTitle sizeThatFits:CGSizeMake(songTitle.frame.size.width,songTitle.frame.size.height)].height;
            //timeView.center = point(timeView.center.x, songTitle.frame.origin.y+songTitle.frame.size.height-hoff+16);
            timeViewBottom.constant = hoff;
            
            currentLabel.text = @"00:00";
            [UIView animateWithDuration:0.2 animations:^{
                artistLabel.alpha = 1;
                albumTitle.alpha  = 1;
                songTitle.alpha   = 1;
                timeView.alpha    = 1;
            }];
            [self.visualizer start];
        }];
    }];
    
    /* Reset the indicator */
    [self updateIndicator];
    
}

- (void) updateIndicator {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    /* update function for indicator at the bottom */
    float d = 0.2;
    double pwidth = playbackWidth.constant;
    [UIView animateWithDuration:d animations:^{
        @try {
            playbackWidth.constant = controller.player.currentPlaybackPosition*1.0*width/(controller.player.currentTrackDuration)+1;
            currentLabel.text = format(@"%.2d:%.2d",(int)(controller.player.currentPlaybackPosition/60),((int)controller.player.currentPlaybackPosition%60));
            if(pwidth<32) {
                self.timerLeftSpace.constant = 0;
                //timeIndicator.center = point(32, height-40);
                timeIndicator.alpha = (pwidth)/40.0;
            } else if(pwidth>width-32) {
                //timeIndicator.center = point(width-32, height-40);
                timeIndicator.alpha = (width-pwidth)/40.0;
            } else {
                self.timerLeftSpace.constant = pwidth-32;
                //timeIndicator.center = point(playbackIndicator.frame.size.width, height-40);
            }
        }
        @catch (NSException *exception) {
            playbackIndicator.frame = rect(0,318,0,2);
        }
    }];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    if (!touched && UD_getBool(@"tutorial")) {
        volumeIndicator.text = format(@"%d",(int)(dummyPlayer.volume));
        tapTouch = true;
        touched = true;
        lastTouch = [((UITouch *)[[touches allObjects] lastObject]) locationInView:self.view];
        touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(showMenu) userInfo:nil repeats:NO];
        volumeIndicator.text = format(@"%d",(int)(dummyPlayer.volume*100));
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
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    if (dummyPlayer.volume>=1) [timer invalidate];
    dummyPlayer.volume += 0.01;
    volumeIndicator.text = format(@"%d",(int)(dummyPlayer.volume*100));
}

- (void) decVolume: (NSTimer *)timer  {
    PLSpotifyController *controller = [PLSpotifyController defaultController];
    if (dummyPlayer.volume<=0) [timer invalidate];
    dummyPlayer.volume -= 0.01;
    volumeIndicator.text = format(@"%d",(int)(dummyPlayer.volume*100));
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
    if(dist<500000 && dist>4000) {
        float angle = r2d(-atan2f((p.y-lastTouch.y), (p.x-lastTouch.x)));
        if((angle<20.0 && angle>-20.0) && !gr) {
            gu = false;
            gr = true;
            gd = false;
            gl = false;
            [volup setSelected:false];
            [next setSelected:true];
            [voldown setSelected:false];
            [prev setSelected:false];
            [volumeTimer invalidate];
        }
        if((angle<110 && angle>70) && !gu) {
            gu = true;
            gr = false;
            gd = false;
            gl = false;
            [volup setSelected:true];
            [next setSelected:false];
            [voldown setSelected:false];
            [prev setSelected:false];
            seeking = false;
            volumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(incVolume:) userInfo:nil repeats:YES];
        }
        if((angle<-160 || angle>160) && !gl) {
            gu = false;
            gr = false;
            gd = false;
            gl = true;
            [volup setSelected:false];
            [next setSelected:false];
            [voldown setSelected:false];
            [prev setSelected:true];
            [volumeTimer invalidate];
        }
        if((angle<-70 && angle>-110) && !gd) {
            gu = false;
            gr = false;
            gd = true;
            gl = false;
            [volup setSelected:false];
            [next setSelected:false];
            [voldown setSelected:true];
            [prev setSelected:false];
            seeking = false;
            volumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(decVolume:) userInfo:nil repeats:YES];
        }
    }else {
        [volup setSelected:false];
        [next setSelected:false];
        [voldown setSelected:false];
        [prev setSelected:false];
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
    
    [volup setSelected:false];
    [next setSelected:false];
    [voldown setSelected:false];
    [prev setSelected:false];
    
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
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"select_playlist"]) {
        PLPlaylistSelectionController *d = (PLPlaylistSelectionController *)segue.destinationViewController;
        d.modalPresentationStyle = UIModalPresentationCurrentContext;
        PLSpotifyController *controller = [PLSpotifyController defaultController];
        d.playlists = controller.playlists.items;
        d.selected = @0;
    }
}

- (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
    CGImageRef maskRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    return [UIImage imageWithCGImage:masked];
    
}



- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    [self itemChangeCallback];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    if(isPlaying) {
        [self resumeIndicatorProgress];
    }else {
        [self pauseIndicatorProgress];
    }
}

- (void) resumeIndicatorProgress {
    playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateIndicator) userInfo:nil repeats:YES];
}

- (void) pauseIndicatorProgress {
    [playbackTimer invalidate];
}

@end
