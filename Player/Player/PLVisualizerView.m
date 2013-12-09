//
//  PLVisualizerView.m
//  Player
//
//  Created by Can Bülbül on 08/12/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "PLVisualizerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PLVisualizerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        emitterLayer = (CAEmitterLayer *)self.layer;
        
        /* bunch of random particles */
        CGFloat height = MAX(frame.size.width, frame.size.height);
        emitterLayer.emitterPosition = CGPointMake(-10,height/2);
        emitterLayer.emitterSize = CGSizeMake(10, height);
        emitterLayer.emitterShape = kCAEmitterLayerRectangle;
        emitterLayer.renderMode = kCAEmitterLayerAdditive;
        
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.emissionLongitude = 0;
        cell.name = @"cell";
        cell.contents = (id)[[UIImage imageNamed:@"particleTexture.png"] CGImage];
        cell.color = [[UIColor colorWithWhite:1.0 alpha:0.2] CGColor];
        cell.redRange = 0.1f;
        cell.greenRange = 0.1f;
        cell.blueRange = 0.0f;
        cell.alphaRange = 0.2f;
        cell.redSpeed = 0.01f;
        cell.greenSpeed = 0.03f;
        cell.blueSpeed = 0.02f;
        cell.alphaSpeed = -0.01f;
        cell.scale = 0.3f;
        cell.scaleRange = 3.8f;
        cell.lifetime = 50.0f;
        cell.lifetimeRange = 1.0f;
        cell.birthRate = 30;
        cell.velocity = 20.0f;
        cell.velocityRange = 10.0f;
        cell.emissionRange = M_PI/4;
        emitterLayer.emitterCells = @[cell];

    }
    return self;
}

+ (Class)layerClass
{
    return [CAEmitterLayer class];
}

- (void) stop {
    emitterLayer.birthRate = 0.1;
}

- (void) start {
    emitterLayer.birthRate = 1;
}

@end
