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
    
    NSNumber* _fps;
    
    NSInteger _numberOfFramesAtLastTick;
    NSInteger _numberOfTicksWithFullBuffer;
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
        _numberOfTicksWithFullBuffer = 0;
        
    }
    
    return self;
}

// If using auto-framerate (self.useAutoFramerate == YES)
// AUTO LOWER FRAMERATE BASED ON CONNECTION SPEED TO MATCH SENDER
// Every clock tick, if playing: if the number of buffered frames goes down
//      then send a msg saying to lower the framerate
// else every 5th clocktick if it has stayed the same
//      then send a msg saying to raise the framerate
- (void) playerClockTick {
    
    NSInteger delta = _frames.count - _numberOfFramesAtLastTick;
    NSLog(@"(%@) fps: %f frames total: %d  frames@last: %d delta: %d", _peerID.displayName, _fps.floatValue, _frames.count, _numberOfFramesAtLastTick, delta);
    _numberOfFramesAtLastTick = _frames.count;
    if (_isPlaying) {
        
        if (_frames.count > 1) {
            
            
            if (self.useAutoFramerate) {
                if (_frames.count >= 10) {
                    if (_numberOfTicksWithFullBuffer >= 30) {
                        // higher framerate
                        if (self.delegate) {
                            [self.delegate raiseFramerateForPeer:_peerID];
                        }
                        _numberOfTicksWithFullBuffer = 0;
                    }
                    
                    _numberOfTicksWithFullBuffer++;
                } else {
                    _numberOfTicksWithFullBuffer = 0;
                    if (delta <= -1) {
                        // lower framerate
                        if (self.delegate && _fps.floatValue > 5) {
                            [self.delegate lowerFramerateForPeer:_peerID];
                        }
                    }
                }
            }
            
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

- (void) addImageFrame:(UIImage*) image withFPS:(NSNumber*) fps {
    _fps = fps;
    if (!_playerClock || (_playerClock.timeInterval != (1.0/fps.floatValue))) {
        NSLog(@"(%@) changing framerate: %f", _peerID.displayName, fps.floatValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_playerClock) {
                [_playerClock invalidate];
            }

            NSTimeInterval timeInterval = 1.0 / [fps floatValue];
            _playerClock = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(playerClockTick)
                                                          userInfo:nil
                                                           repeats:YES];
        });
    }
    [_frames addObject:image];
}

- (void) stopPlaying {
    if (_playerClock) {
        [_playerClock invalidate];        
    }
}

@end
