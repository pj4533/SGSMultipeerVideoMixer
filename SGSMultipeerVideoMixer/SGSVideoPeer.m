//
//  SGSVideoPeer.m
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 1/1/14.
//  Copyright (c) 2014 Say Goodnight Software. All rights reserved.
//

#import "SGSVideoPeer.h"

@interface SGSVideoPeer () {
    MCPeerID* _peerID;
    BOOL _isPlaying;
    NSMutableArray* _frames;
    NSTimer* _playerClock;
    NSIndexPath* _indexPath;
}

@end

@implementation SGSVideoPeer

- (instancetype) initWithPeer:(MCPeerID*) peerID atIndexPath:(NSIndexPath*) indexPath {
    self = [super init];
    if (self) {
        _frames = @[].mutableCopy;
        _isPlaying = NO;
        _peerID = peerID;
        _indexPath = indexPath;
        
        // make clocks individual when adjusting framerate
        _playerClock = [NSTimer scheduledTimerWithTimeInterval:(1.0/5.0)
                                                        target:self
                                                      selector:@selector(playerClockTick)
                                                      userInfo:nil
                                                       repeats:YES];

    }
    
    return self;
}

// AUTO LOWER FRAMERATE BASED ON CONNECTION SPEED TO MATCH SENDER
// Every clock tick, if playing: if the number of buffered frames goes down
//      then send a msg saying to lower the framerate
// else every 5th clocktick if it has stayed the same
//      then send a msg saying to raise the framerate
- (void) playerClockTick {
    NSLog(@"(%@) frames: %d", _peerID.displayName, _frames.count);
    if (_isPlaying) {
        if (_frames.count > 1) {
            
            
            if (self.delegate) {
                [self.delegate showImage:_frames[0] atIndexPath:_indexPath];
            }
            [_frames removeObjectAtIndex:0];
            
            
        } else {
            _isPlaying = NO;
        }
    } else {
        if (_frames.count > 10) {
            _isPlaying = YES;
        }
    }
}

- (void) addImageFrame:(UIImage*) image {
    [_frames addObject:image];
}

@end
