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
        
        // 2
        CGFloat height = MAX(frame.size.width, frame.size.height);
        emitterLayer.emitterPosition = CGPointMake(-60,height/2);
        emitterLayer.emitterSize = CGSizeMake(40, height);
        emitterLayer.emitterShape = kCAEmitterLayerRectangle;
        emitterLayer.renderMode = kCAEmitterLayerAdditive;
        
        // 3
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.emissionLongitude = 0;
        cell.name = @"cell";
        cell.contents = (id)[[UIImage imageNamed:@"particleTexture.png"] CGImage];
        
        // 4
        cell.color = [[UIColor colorWithWhite:1.0 alpha:0.2] CGColor];
        cell.redRange = 0.1f;
        cell.greenRange = 0.1f;
        cell.blueRange = 0.0f;
        cell.alphaRange = 0.2f;
        
        // 5
        cell.redSpeed = 0.01f;
        cell.greenSpeed = 0.03f;
        cell.blueSpeed = 0.02f;
        cell.alphaSpeed = -0.01f;
        
        // 6
        cell.scale = 0.3f;
        cell.scaleRange = 3.8f;
        
        // 7
        cell.lifetime = 50.0f;
        cell.lifetimeRange = 1.0f;
        cell.birthRate = 30;
        
        // 8
        cell.velocity = 20.0f;
        cell.velocityRange = 10.0f;
        cell.emissionRange = M_PI/4;
        
        // 9
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
