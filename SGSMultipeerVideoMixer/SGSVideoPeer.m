//
//  SGSVideoPeer.m
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 1/1/14.
//  Copyright (c) 2014 Say Goodnight Software. All rights reserved.
//

#import "SGSVideoPeer.h"

@implementation SGSVideoPeer

- (instancetype) init {
    self = [super init];
    if (self) {
        self.frames = @[].mutableCopy;
        self.isPlaying = NO;
    }
    
    return self;
}

@end
