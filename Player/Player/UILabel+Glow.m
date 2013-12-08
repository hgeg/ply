//
//  UILabel+Glow.m
//  Player
//
//  Created by Can Bülbül on 08/12/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "UILabel+Glow.h"

@implementation UILabel (Glow)

- (void) glow {
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowRadius = 20;
    self.layer.shadowOpacity = 1.0;
    [self.layer setShadowPath:[[UIBezierPath
                                bezierPathWithRect:self.bounds] CGPath]];
    
}

- (void) dim {
    self.layer.shadowRadius = 0;
    self.layer.shadowOpacity = 0.0;
}


@end
