//
//  UILabel+Glow.m
//  Player
//
//  Created by Can Bülbül on 08/12/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "UIButton+Glow.h"

@implementation UIButton (Glow)

- (void) glow {
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowRadius = 25;
    self.layer.shadowOpacity = 1.0;
    CGRect b = self.bounds;
    [self.layer setShadowPath:[[UIBezierPath
                                bezierPathWithRect:rect(b.origin.x-25, b.origin.y-25, b.size.width+50,b.size.height+50)] CGPath]];
    
}

- (void) dim {
    self.layer.shadowRadius = 0;
    self.layer.shadowOpacity = 0.0;
}


@end
