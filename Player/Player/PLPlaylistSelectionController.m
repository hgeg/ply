//
//  PLPlaylistSelectionController.m
//  Player
//
//  Created by Can Bülbül on 09/10/15.
//  Copyright © 2015 Can Bülbül. All rights reserved.
//

//TODO: Go Back Button

#import "PLPlaylistSelectionController.h"
#import "UIImageView+WebCache.h"

@implementation PLPlaylistSelectionController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playlists.count+2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlist"];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"playlist"];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    
    UIImageView *artwork = (UIImageView *)[cell viewWithTag:1];
    UILabel *title = (UILabel *)[cell viewWithTag:2];
    UIImageView *frame = (UIImageView *)[cell viewWithTag:3];
    UIImageView *close = (UIImageView *)[cell viewWithTag:4];
    SPTPartialPlaylist *playlist;
    
    switch (indexPath.row) {
        case 0:
            title.text = @"CANCEL";
            artwork.alpha = 0;
            frame.alpha = 0;
            close.alpha = 1;
            break;
            
        case 1:
            title.text = @"SAVED TRACKS";
            artwork.image = [self maskImage:[UIImage imageNamed:@"artwork_mask"] withMask:[UIImage imageNamed:@"default"]];
            
            artwork.alpha = 1;
            frame.alpha = 1;
            close.alpha = 0;
            break;
            
        default:
            playlist = (SPTPartialPlaylist *) self.playlists[indexPath.row-2];
            [artwork sd_setImageWithURL:playlist.smallestImage.imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                artwork.clipsToBounds = true;
                artwork.image = [self maskImage:[UIImage imageNamed:@"artwork_mask"] withMask:artwork.image];
            }];
            title.text = [playlist.name uppercaseString];
            
            artwork.alpha = 1;
            frame.alpha = 1;
            close.alpha = 0;
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *ui;
    switch (indexPath.row) {
        case 0:
            break;
            
        case 1:
            ui = @{ @"selected": @(-1)};
            NC_postNotification(@"selected_playlist", ui);
            break;
            
        default:
            ui = @{ @"selected": @(indexPath.row-2)};
            NC_postNotification(@"selected_playlist", ui);
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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


@end
