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

@interface SGSViewController () <MCBrowserViewControllerDelegate, MCSessionDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
    MCPeerID *_myDevicePeerId;
    MCSession *_session;
    
    NSMutableDictionary* _peers;
    
    NSTimer* _playerClock;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger cellCount;

@end

@implementation SGSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _peers = @{}.mutableCopy;
    
    // make clocks individual when adjusting framerate
    _playerClock = [NSTimer scheduledTimerWithTimeInterval:(1.0/5.0)
                                     target:self
                                   selector:@selector(playerClockTick)
                                   userInfo:nil
                                    repeats:YES];
    
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.collectionView addGestureRecognizer:tapRecognizer];

    self.cellCount = 0;
    [self.collectionView reloadData];
    
    _myDevicePeerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    _session = [[MCSession alloc] initWithPeer:_myDevicePeerId securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self showAssistant];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showAssistant {
    MCBrowserViewController* browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"multipeer-video" session:_session];
    browserVC.delegate = self;
    [self presentViewController:browserVC animated:YES completion:nil];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self showAssistant];
    }
}

// AUTO LOWER FRAMERATE BASED ON CONNECTION SPEED TO MATCH SENDER
// Every clock tick, if playing: if the number of buffered frames goes down
//      then send a msg saying to lower the framerate
// else every 5th clocktick if it has stayed the same
//      then send a msg saying to raise the framerate
- (void) playerClockTick {
    for (MCPeerID* peerID in _session.connectedPeers) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SGSVideoPeer* thisVideoPeer = _peers[peerID.displayName];
            NSLog(@"(%@) frames: %d", peerID.displayName, thisVideoPeer.frames.count);
            if (thisVideoPeer.isPlaying) {
                if (thisVideoPeer.frames.count > 1) {
                    
            
                    SGSImageViewCell* cell = (SGSImageViewCell*) [self.collectionView cellForItemAtIndexPath:thisVideoPeer.indexPath];
                    cell.imageView.image = thisVideoPeer.frames[0];
                    [thisVideoPeer.frames removeObjectAtIndex:0];
                    
                    
                } else {
                    thisVideoPeer.isPlaying = NO;
                }
            } else {
                if (thisVideoPeer.frames.count > 10) {
                    thisVideoPeer.isPlaying = YES;
                }
            }
        });
    }
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
                [self dismissViewControllerAnimated:YES completion:nil];
                
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.cellCount inSection:0];

                SGSVideoPeer* newVideoPeer = [[SGSVideoPeer alloc] init];
                newVideoPeer.indexPath = indexPath;
                
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
            [self showAssistant];
			break;
        }
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    NSDictionary* dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    UIImage* image = [UIImage imageWithData:dict[@"image"] scale:2.0];
    
    SGSVideoPeer* thisVideoPeer = _peers[peerID.displayName];
    [thisVideoPeer.frames addObject:image];

//    NSNumber* currentTimestamp = dict[@"timestamp"];
//    NSData *returnMsg = [NSKeyedArchiver archivedDataWithRootObject:currentTimestamp];
//    [_session sendData:returnMsg toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

#pragma mark - MCBroweserViewController

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
