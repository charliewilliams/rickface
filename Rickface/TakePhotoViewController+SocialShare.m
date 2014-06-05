//
//  TakePhotoViewController+SocialShare.m
//  Rickface
//
//  Created by Charlie Williams on 05/06/2014.
//  Copyright (c) 2014 Charlie Williams. All rights reserved.
//

#import "TakePhotoViewController+SocialShare.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
@import Social;

typedef void(^CompletionBlock)();

@implementation TakePhotoViewController (SocialShare)

- (void)showShareScreenWithImage:(UIImage *)image {
    
    NSAssert(self.activeSLServiceType, @"Need a social service type");
    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:self.activeSLServiceType];
    
    vc.completionHandler = ^(SLComposeViewControllerResult result){
        
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    };
    [self handleSocialViewController:vc image:image];
}

- (void)handleSocialViewController:(SLComposeViewController *)vc image:(UIImage *)image {
    
    [self setTextForSocialShare:vc];
    [vc addImage:image];
    [self addURLForSocialShare:vc];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)setTextForSocialShare:(SLComposeViewController *)vc {
    
    BOOL isFacebook = [self.activeSLServiceType isEqualToString:SLServiceTypeFacebook];
    NSString *text = [NSString stringWithFormat:@"Rick and I feel%@ %@ #rickface", (isFacebook ? @"" : @"ing"), [self.rickFaceMoodString lowercaseString]];
    [vc setInitialText:text];
}

- (void)addURLForSocialShare:(SLComposeViewController *)vc {
    
    [vc addURL:[NSURL URLWithString:self.appStoreURLString]];
}

- (NSString *)appStoreURLString {
    return @"http://itunes.apple.com/app/rickface/id882560160";
}

@end
