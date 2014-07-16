//
//  CWViewController.m
//  Rickface
//
//  Created by Charlie Williams on 26/05/2014.
//  Copyright (c) 2014 Charlie Williams. All rights reserved.
//

#import "CWViewController.h"
#import <Parse/Parse.h>
#import "NSObject+Helper.h"
#import "TakePhotoViewController.h"
#import "TakePhotoViewController+SocialShare.h"
#import "GAI/GAI.h"
#import "GAI/GAIDictionaryBuilder.h"
@import Social;

#define kHasShownFirstUX @"kHasShownFirstUX"

@interface CWViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *launchAnimationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *introRickPortraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceAboutLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomBlackView;

@property (weak, nonatomic) IBOutlet UILabel *rickFeelsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UILabel *moodLine1Label;
@property (weak, nonatomic) IBOutlet UIView *sharingContainerView;

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

    [self downloadFaces];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
//#warning Debug only!
//    [self showNewFace];
}

- (void)downloadFaces {
    
    NSError *error = nil;
    NSMutableArray *facePaths = [[self.fileManager contentsOfDirectoryAtPath:self.documentsDirectory error:&error] mutableCopy];
    if (error) {
        DLog(@"%@", error);
    }
    
    PFQuery *downloadQuery = [PFQuery queryWithClassName:@"Face"];
    [downloadQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        for (PFObject *face in objects) {
            
            NSString *moodString = face[@"emotion"];
            [facePaths removeObject:moodString];
            NSString *path = [self.documentsDirectory stringByAppendingPathComponent:moodString];
            if ([self.fileManager fileExistsAtPath:path]) {
                continue;
            }
            
            PFFile *file = face[@"image_640_1137"];
            [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                if (error) {
                    DLog(@"%@", error);
                }
                
                [data writeToFile:path atomically:NO];
            }];
        }
        
        for (NSString *face in facePaths) {

            error = nil;
            NSString *path = [self.documentsDirectory stringByAppendingPathComponent:face];
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error) {
                DLog(@"%@", error);
            }
        }
    }];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake) {
            
        [self showNewFace];
    }
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
    
    NSError *error = nil;
    NSArray *facePaths = [self.fileManager contentsOfDirectoryAtPath:self.documentsDirectory error:&error];
    if (error) {
        DLog(@"%@", error);
    }
    NSUInteger numberOfFaces = [facePaths count];
    
    if (!numberOfFaces) {
        return;
    }
    
    NSUInteger faceNumber = arc4random() % numberOfFaces;
//    NSUInteger facesToAnimate = 10;
//    
//    NSMutableArray *images = [NSMutableArray array];
//    NSMutableArray *moods = [NSMutableArray array];
    
    NSString *mood;
    UIImage *image;
    
//    for (NSInteger i=0; i<facesToAnimate; i++) {
    
    mood = facePaths[faceNumber % numberOfFaces];
    NSString *path = [self.documentsDirectory stringByAppendingPathComponent:mood];
    NSData *data = [NSData dataWithContentsOfFile:path];
    image = [UIImage imageWithData:data scale:2.0];
    
//        [moods addObject:mood];
//        [images addObject:image];
//    }
//    
//    self.faceImageView.animationImages = images;
//    self.faceImageView.animationDuration = 0.4;
//    [self.faceImageView startAnimating];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.faceImageView.image = image;
        self.moodLine1Label.text = mood;
    
    NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Face" action:@"Shown" label:mood value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
//    });
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not logged in" message:@"Please log in on this device in order to share Rickface." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
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
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *image = [UIImage imageWithData:data scale:2.0];
        [images addObject:image];
    }
    return images;
}

#pragma mark - Transition to photo

- (void)showPhotoScreenForService:(NSString *)service {
    
    NSMutableDictionary *event = [[GAIDictionaryBuilder createEventWithCategory:@"Share" action:@"Photo-screen" label:service value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
    
    NSString *userName = nil;
    
    if ([service isEqualToString:SLServiceTypeFacebook]) {
        userName = [PFTwitterUtils twitter].screenName;
    } else if ([service isEqualToString:SLServiceTypeTwitter]) {
        userName = [[PFUser currentUser] username];
    }
    
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
