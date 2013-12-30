//
//  SGSViewController.m
//  SGSMultipeerVideoMixer
//
//  Created by PJ Gray on 12/29/13.
//  Copyright (c) 2013 Say Goodnight Software. All rights reserved.
//

#import "SGSViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface SGSViewController () <MCBrowserViewControllerDelegate, MCSessionDelegate, NSStreamDelegate> {
    MCPeerID *_myDevicePeerId;
    MCSession *_session;
}

@property (weak, nonatomic) IBOutlet UIImageView *imagePreview;

@end

@implementation SGSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

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

#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
	switch (state) {
		case MCSessionStateConnected:
            NSLog(@"PEER CONNECTED: %@", peerID.displayName);
            [self dismissViewControllerAnimated:YES completion:nil];
			break;
		case MCSessionStateConnecting:
            NSLog(@"PEER CONNECTING: %@", peerID.displayName);
			break;
		case MCSessionStateNotConnected:
            NSLog(@"PEER NOT CONNECTED: %@", peerID.displayName);
            [self showAssistant];
			break;
	}
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    UIImage* image = [UIImage imageWithData:data scale:2.0];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imagePreview.image = image;
    });
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
