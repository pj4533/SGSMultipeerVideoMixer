//
//  SGSVideoPeer.h
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 1/1/14.
//  Copyright (c) 2014 Say Goodnight Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol SGSVideoPeerDelegate <NSObject>
- (void) showImage:(UIImage*) image atIndexPath:(NSIndexPath*) indexPath;
@end

@interface SGSVideoPeer : NSObject

@property (strong, nonatomic) id delegate;

- (instancetype) initWithPeer:(MCPeerID*) peerID atIndexPath:(NSIndexPath*) indexPath;
- (void) addImageFrame:(UIImage*) image;

@end
