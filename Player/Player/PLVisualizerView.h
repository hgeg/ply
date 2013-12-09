//
//  PLVisualizerView.h
//  Player
//
//  Created by Can Bülbül on 08/12/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PLVisualizerView : UIView {
    CAEmitterLayer *emitterLayer;
}

- (void) stop;

- (void) start;

@end
