//
//  CWViewController.m
//  Rickface
//
//  Created by Charlie Williams on 26/05/2014.
//  Copyright (c) 2014 Charlie Williams. All rights reserved.
//

#import "Rickface-Swift.h"

#import "CWViewController.h"
#import "NSObject+Helper.h"
#import "TakePhotoViewController.h"
#import "TakePhotoViewController+SocialShare.h"
#import "GAI/GAI.h"
#import "GAI/GAIDictionaryBuilder.h"
@import Social;

#define kHasShownFirstUX @"kHasShownFirstUX"

@interface CWViewController () {
    BOOL histeresisExcited;
}

@property (weak, nonatomic) IBOutlet UIImageView *introRickPortraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceAboutLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomBlackView;

@property (weak, nonatomic) IBOutlet UILabel *rickFeelsLabel;
@property (weak, nonatomic) IBOutlet UILabel *translucentPlaceholderLabel;

@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UILabel *moodLine1Label;
@property (weak, nonatomic) IBOutlet UIView *sharingContainerView;

@end

@implementation CWViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setUpLaunchUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpLaunchUI) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)setUpLaunchUI {

    self.introRickPortraitImageView.layer.cornerRadius = self.introRickPortraitImageView.bounds.size.width/2;
    self.introRickPortraitImageView.layer.masksToBounds = YES;
    self.introRickPortraitImageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.introRickPortraitImageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    self.introRickPortraitImageView.alpha = 1;
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.bottomBlackView.alpha = 0.0;

    self.view.backgroundColor = [UIColor whiteColor];
    self.rickFeelsLabel.alpha = 0.0;
    self.translucentPlaceholderLabel.alpha = 0.0;
    self.moodLine1Label.text = nil;
    self.moodLine1Label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.rickFaceAboutLabel.alpha = 1.0;
    self.rickFaceTitleLabel.alpha = 1.0;
    self.faceImageView.alpha = 0.0;
    self.moodLine1Label.alpha = 0.0;
    self.sharingContainerView.alpha = 0.0;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake) {
            
        [self showNewFace];
    }
}

- (void)showNewFace {

    Face *face = [Face random];

    self.faceImageView.image = face.image;


    NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Face" action:@"Shown" label:face.emotion value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];

    CGFloat duration = 1.0;
    UIViewAnimationOptions options = UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent;

    [UIView transitionWithView:self.faceImageView duration:duration options:options animations:^{
        self.faceImageView.image = face.image;
    } completion:nil];

    [UIView transitionWithView:self.moodLine1Label duration:duration options:options animations:^{
        self.moodLine1Label.text = face.emotion;
    } completion:nil];

    
    [UIView animateWithDuration:duration animations:^{

        self.rickFaceTitleLabel.alpha = 0.0;
        self.rickFaceAboutLabel.alpha = 0.0;

        self.rickFeelsLabel.alpha = 1.0;
        self.translucentPlaceholderLabel.alpha = 1.0;
        self.introRickPortraitImageView.alpha = 0.0;
        self.rickFeelsLabel.alpha = 1.0;
        self.translucentPlaceholderLabel.alpha = 1.0;
        self.faceImageView.alpha = 1.0;
        self.moodLine1Label.alpha = 1.0;
        self.sharingContainerView.alpha = 1.0;
    }];
}

#pragma mark - Social Share

- (IBAction)facebookPressed:(id)sender {
    
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Social" action:@"Share-facebook" label:@"failed" value:nil] build];
        [[GAI sharedInstance].defaultTracker send:event];
        [[GAI sharedInstance] dispatch];
        [self shareFailed];
        return;
    }
    [self showPhotoScreenForService:SLServiceTypeFacebook];
}

- (IBAction)twitterPressed:(id)sender {
    
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Social" action:@"Share-twitter" label:@"failed" value:nil] build];
        [[GAI sharedInstance].defaultTracker send:event];
        [[GAI sharedInstance] dispatch];
        [self shareFailed];
        return;
    }
    [self showPhotoScreenForService:SLServiceTypeTwitter];
}

- (UIImage *)imageForSocialShare {
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)shareFailed {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Not logged in" message:@"Please log in on this device in order to share Rickface." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Transition to photo

- (void)showPhotoScreenForService:(NSString *)service {
    
    NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Share" action:@"Photo-screen" label:service value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
    
    NSString *userName = nil;

    TakePhotoViewController *tpvc = [self.storyboard instantiateViewControllerWithIdentifier:@"TakePhotoViewController"];
    [tpvc view];
    tpvc.activeSLServiceType = service;
    tpvc.rickFaceImageView.image = [self imageForSocialShare];
    tpvc.moodLabel.text = self.moodLine1Label.text;
    
    if (userName) {
        tpvc.userFeelsLabel.text = [NSString stringWithFormat:@"%@ feels:", userName];
    } else {
        tpvc.userFeelsLabel.text = @"I feel:";
    }
    [self presentViewController:tpvc animated:YES completion:nil];
}

@end
