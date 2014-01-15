//
//  SGSViewController.m
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 12/29/13.
//  Copyright (c) 2013 Say Goodnight Software. All rights reserved.
//

#import "SGSViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SGSImageViewCell.h"
#import "SGSVideoPeer.h"

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface SGSViewController () <MCNearbyServiceBrowserDelegate, MCSessionDelegate, UICollectionViewDataSource, UICollectionViewDelegate, SGSVideoPeerDelegate> {
    MCPeerID *_myDevicePeerId;
    MCSession *_session;
    MCNearbyServiceBrowser *_browser;
    
    NSMutableDictionary* _peers;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger cellCount;

@end

@implementation SGSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _peers = @{}.mutableCopy;
    
    self.cellCount = 0;
    [self.collectionView reloadData];
    
    _myDevicePeerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    _session = [[MCSession alloc] initWithPeer:_myDevicePeerId securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;
    
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myDevicePeerId serviceType:@"multipeer-video"];
    _browser.delegate = self;
    [_browser startBrowsingForPeers];
}

- (void)viewDidAppear:(BOOL)animated {
//    [self showAssistant];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return self.cellCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    SGSImageViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ImageViewCell" forIndexPath:indexPath];
    
    return cell;
}


#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
	switch (state) {
		case MCSessionStateConnected: {
            NSLog(@"PEER CONNECTED: %@", peerID.displayName);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.cellCount inSection:0];

                SGSVideoPeer* newVideoPeer = [[SGSVideoPeer alloc] initWithPeer:peerID atIndexPath:indexPath];
                newVideoPeer.delegate = self;
                
                _peers[peerID.displayName] = newVideoPeer;
                
                self.cellCount = self.cellCount + 1;
                [self.collectionView reloadData];
            });
            
			break;
        }
		case MCSessionStateConnecting:
            NSLog(@"PEER CONNECTING: %@", peerID.displayName);
			break;
		case MCSessionStateNotConnected: {
            NSLog(@"PEER NOT CONNECTED: %@", peerID.displayName);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                SGSVideoPeer* peer = _peers[peerID.displayName];
                [peer stopPlaying];
                peer = nil;
                
                [_peers removeObjectForKey:peerID.displayName];
                
                self.cellCount = self.cellCount - 1;
                [self.collectionView reloadData];
            });
			break;
        }
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
//    NSLog(@"(%@) Read %d bytes", peerID.displayName, data.length);
    
    NSDictionary* dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    UIImage* image = [UIImage imageWithData:dict[@"image"] scale:2.0];
    NSNumber* framesPerSecond = dict[@"framesPerSecond"];
    
    SGSVideoPeer* thisVideoPeer = _peers[peerID.displayName];
    [thisVideoPeer addImageFrame:image withFPS:framesPerSecond];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void) browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    
}

- (void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    [browser invitePeer:peerID toSession:_session withContext:nil timeout:0];
}

- (void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    
}

#pragma mark - SGSVideoPeerDelegate

- (void) showImage:(UIImage *)image atIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        SGSImageViewCell* cell = (SGSImageViewCell*) [self.collectionView cellForItemAtIndexPath:indexPath];
        cell.imageView.image = image;
    });
}

- (void) raiseFramerateForPeer:(MCPeerID *)peerID {
    NSLog(@"(%@) raise framerate", peerID.displayName);
    NSData* data = [@"raiseFramerate" dataUsingEncoding:NSUTF8StringEncoding];
    [_session sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}

- (void) lowerFramerateForPeer:(MCPeerID *)peerID {
    NSLog(@"(%@) lower framerate", peerID.displayName);
    NSData* data = [@"lowerFramerate" dataUsingEncoding:NSUTF8StringEncoding];
    [_session sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}

@end
