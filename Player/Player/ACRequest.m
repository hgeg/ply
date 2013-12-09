//
//  ACRequest.m
//  AppCounterLib
//
//  Created by Ali Can Bülbül on 9/12/13.
//  Copyright (c) 2013 Can Bülbül. All rights reserved.
//

#import "ACRequest.h"

@implementation ACRequest

+ (id) sharedRequest {
    static ACRequest *sharedRequest = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRequest = [[self alloc] init];
    });
    return sharedRequest;
}

- (id)init {
    if (self = [super init]) {
        //Register app
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        //Register client
        
    }
    return self;
}

- (void) sendAppOpen {
    // Construct url
    NSString *urlAsString = [NSString stringWithFormat:@"http://hgeg.io/appcounter/add/%@/%@/",uid,appName];
    NSURL *url = [NSURL URLWithString:urlAsString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    // Send the request asynchronously
    [NSURLConnection
     sendAsynchronousRequest:urlRequest
     queue:[[NSOperationQueue alloc] init]
     completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
         if(e){
             completed = false;
             error = e;
             response = r;
         }else {
             completed = true;
             error = nil;
             response = r;
         }
     }];
}

- (void) sendAction: (NSString *)action {
    // Construct url
    NSString *urlAsString = [[NSString stringWithFormat:@"http://hgeg.io/appcounter/action/%@/%@/%@/",uid,appName,action] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlAsString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    // Send the request asynchronously
    [NSURLConnection
     sendAsynchronousRequest:urlRequest
     queue:[[NSOperationQueue alloc] init]
     completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
         if(e){
             completed = false;
             error = e;
             response = r;
         }else {
             completed = true;
             error = nil;
             response = r;
         }
     }];
}

@end
