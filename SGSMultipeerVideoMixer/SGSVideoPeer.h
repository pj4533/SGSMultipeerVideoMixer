//
//  SGSVideoPeer.h
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 1/1/14.
//  Copyright (c) 2014 Say Goodnight Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGSVideoPeer : NSObject

@property (strong, nonatomic) NSMutableArray* frames;
@property BOOL isPlaying;
@property (strong, nonatomic) NSIndexPath* indexPath;

@end
