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
@import CoreMotion;

#define kHasShownFirstUX @"kHasShownFirstUX"

@interface CWViewController () {
    BOOL histeresisExcited;
}

@property (weak, nonatomic) IBOutlet UIImageView *launchAnimationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *introRickPortraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceAboutLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomBlackView;

@property (weak, nonatomic) IBOutlet UILabel *rickFeelsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UILabel *moodLine1Label;
@property (weak, nonatomic) IBOutlet UIView *sharingContainerView;

@property (nonatomic, assign) CMAcceleration *lastAcceleration;

@end

@implementation CWViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.introRickPortraitImageView.layer.cornerRadius = self.introRickPortraitImageView.bounds.size.width/2;
    self.introRickPortraitImageView.layer.masksToBounds = YES;
    self.introRickPortraitImageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.introRickPortraitImageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.bottomBlackView.alpha = 0.0;
    
    if (![self.store boolForKey:kHasShownFirstUX]) {
    
        self.launchAnimationImageView.image = [self animationImages][0];
        self.launchAnimationImageView.animationImages = [self animationImages];
        CGFloat duration = 2.5;
        self.launchAnimationImageView.animationDuration = duration;
        
        [self.launchAnimationImageView startAnimating];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.launchAnimationImageView stopAnimating];
            
            [UIView animateWithDuration:0.6 delay:0.1 options:0 animations:^{
                
                self.launchAnimationImageView.alpha = 0.0f;
                
            } completion:^(BOOL finished) {
                
            }];
        });
        
        [self.store setBool:YES forKey:kHasShownFirstUX];
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.rickFeelsLabel.alpha = 0.0;
    self.moodLine1Label.text = nil;
    self.moodLine1Label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.rickFaceAboutLabel.alpha = 1.0;
    self.rickFaceTitleLabel.alpha = 1.0;
    self.faceImageView.alpha = 0.0;
    self.moodLine1Label.alpha = 0.0;
    self.sharingContainerView.alpha = 0.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foregrounded) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)foregrounded {
    
    if (!self.launchAnimationImageView.image) {
        [self showNewFace];
    }
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
    
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[URL path]], @"Only add attribute to existing file");
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!success) {
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake) {
            
        [self showNewFace];
    }
}

// Ensures the shake is strong enough on at least two axes before declaring it a shake.
// "Strong enough" means "greater than a client-supplied threshold" in G's.
static BOOL accelerationIsShaking(CMAcceleration *last, CMAcceleration *current, double threshold) {
	double
    deltaX = fabs(last->x - current->x),
    deltaY = fabs(last->y - current->y),
    deltaZ = fabs(last->z - current->z);
    
	return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

- (void)accelerometer:(CMAcceleration *)accelerometer didAccelerate:(CMAcceleration *)acceleration {
    
	if (self.lastAcceleration) {
		if (!histeresisExcited && accelerationIsShaking(self.lastAcceleration, acceleration, 0.7)) {
			histeresisExcited = YES;
            
            [self showNewFace];
            
		} else if (histeresisExcited && !accelerationIsShaking(self.lastAcceleration, acceleration, 0.2)) {
			histeresisExcited = NO;
		}
	}
    
	self.lastAcceleration = acceleration;
}

- (void)showNewFace {
    
     [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        self.view.backgroundColor = [UIColor blackColor];
        self.rickFeelsLabel.alpha = 0.0;
        self.rickFaceTitleLabel.alpha = 0.0;
        self.rickFaceAboutLabel.alpha = 0.0;
        self.faceImageView.alpha = 0.0;
        self.moodLine1Label.alpha = 0.0;
        self.sharingContainerView.alpha = 0.0;
        self.bottomBlackView.alpha = 0.0;
        self.introRickPortraitImageView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        self.launchAnimationImageView.image = nil;
        
        [self showNewFaceImpl];
        
        [UIView animateWithDuration:3.0 animations:^{
            
            self.bottomBlackView.alpha = 1.0;
            self.rickFeelsLabel.alpha = 1.0;
            self.faceImageView.alpha = 1.0;
            self.moodLine1Label.alpha = 1.0;
            self.sharingContainerView.alpha = 1.0;
        }];
    }];
}

- (void)showNewFaceImpl {
    
    Face *face = [Face random];

    self.faceImageView.image = face.image;
    self.moodLine1Label.text = face.emotion;
    
    NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Face" action:@"Shown" label:face.emotion value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
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

#pragma mark - Intro

- (NSArray *)animationImages {
    
    NSArray *imageNames = @[@"001.jpg", @"001.jpg", @"001.jpg", @"001.jpg",
                            @"011.jpg", @"011.jpg", @"011.jpg", @"011.jpg",
                            @"025.jpg", @"025.jpg", @"025.jpg",
                            @"035.jpg", @"035.jpg", @"035.jpg",
                            @"041.jpg", @"041.jpg", @"041.jpg",
//                            @"042.jpg", @"042.jpg",
//                            @"049.jpg", @"049.jpg",
//                            @"051.jpg", @"051.jpg",
//                            @"058.jpg", @"058.jpg",
                            @"065.jpg",
                            @"068.jpg",
                            @"074.jpg",
                            @"081.jpg",
                            @"082.jpg",
                            @"097.jpg",
//                            @"001.jpg", @"011.jpg", @"025.jpg", @"035.jpg", @"041.jpg", @"042.jpg", @"049.jpg", @"051.jpg", @"058.jpg", @"065.jpg",
                            @"068.jpg", @"074.jpg", @"081.jpg", @"082.jpg", @"097.jpg"];
    
    NSMutableArray *images = [NSMutableArray array];
    for (NSString *name in imageNames) {

        UIImage *image = [UIImage imageNamed:name];

        if (image) {
            [images addObject:image];
        }
    }
    return images;
}

#pragma mark - Transition to photo

- (void)showPhotoScreenForService:(NSString *)service {
    
    NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Share" action:@"Photo-screen" label:service value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
    
    NSString *userName = nil;
    
//    if ([service isEqualToString:SLServiceTypeFacebook]) {
//        userName = [ twitter].screenName;
//    } else if ([service isEqualToString:SLServiceTypeTwitter]) {
//        userName = [[PFUser currentUser] username];
//    }
    
    TakePhotoViewController *tpvc = [self.storyboard instantiateViewControllerWithIdentifier:@"TakePhotoViewController"];
    [tpvc view];
    tpvc.activeSLServiceType = service;
    tpvc.rickFaceImageView.image = [self imageForSocialShare];
    tpvc.moodLabel.text = self.moodLine1Label.text;
    
    if (userName) {
        tpvc.userFeelsLabel.text = [NSString stringWithFormat:@"%@ feels:", userName];
    } else {
        tpvc.userFeelsLabel.hidden = YES;
    }
    [self presentViewController:tpvc animated:YES completion:nil];
}

@end
