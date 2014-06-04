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
@import Social;

#define kHasShownFirstUX @"kHasShownFirstUX"

@interface CWViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *launchAnimationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *introRickPortraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceAboutLabel;

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
    
    if (![self.store boolForKey:kHasShownFirstUX]) {
        
        self.launchAnimationImageView.image = [self animationImages][0];
        self.launchAnimationImageView.animationImages = [self animationImages];
        CGFloat duration = 3.;
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

- (void)downloadFaces {
    
    PFQuery *downloadQuery = [PFQuery queryWithClassName:@"Face"];
    [downloadQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        for (PFObject *face in objects) {
            
            NSString *moodString = face[@"emotion"];
            NSString *path = [self.documentsDirectory stringByAppendingPathComponent:moodString];
            if ([self.fileManager fileExistsAtPath:path]) {
                continue;
            }
            
            PFFile *file = face[@"image_640_853"];
            [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                if (error) {
                    DLog(@"%@", error);
                }
                
                [data writeToFile:path atomically:NO];
            }];
        }
    }];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake) {
            
        [self showNewFace];
    }
}

- (void)showNewFace {
    
    [UIView animateWithDuration:0.6 animations:^{
        
        self.view.backgroundColor = [UIColor blackColor];
        self.rickFeelsLabel.alpha = 0.0;
        self.rickFaceTitleLabel.alpha = 0.0;
        self.rickFaceAboutLabel.alpha = 0.0;
        self.faceImageView.alpha = 0.0;
        self.moodLine1Label.alpha = 0.0;
        self.sharingContainerView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        [self showNewFaceImpl];
        
        [UIView animateWithDuration:3.0 animations:^{
            
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
    
    NSUInteger faceNumber = arc4random() % numberOfFaces;
    
    NSString *mood = facePaths[faceNumber];
    NSString *path = [self.documentsDirectory stringByAppendingPathComponent:mood];
    self.moodLine1Label.text = mood;
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    self.faceImageView.image = image;
    
    [self.moodLine1Label sizeToFit];
}

#pragma mark - Social Share

- (IBAction)facebookPressed:(id)sender {
    
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        [self shareFailed];
        return;
    }
    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [self handleSocialViewController:vc];
}

- (IBAction)twitterPressed:(id)sender {
    
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        [self shareFailed];
        return;
    }
    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [self handleSocialViewController:vc];
}

- (void)handleSocialViewController:(SLComposeViewController *)vc {
    
    [self setTextForSocialShare:vc];
    [self setImageForSocialShare:vc];
    [self addURLForSocialShare:vc];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)emailPressed:(id)sender {
    
    if (![MFMailComposeViewController canSendMail]) {
        [self shareFailed];
        return;
    }
    
    MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
    [vc setMailComposeDelegate:self];
    
    NSString *body = [NSString stringWithFormat:@"I asked Rick how he felt and he made a face that seemed somehow... <i>%@</i>.\n\n%@", [self.moodLine1Label.text lowercaseString], self.appStoreURLString];
    [vc setMessageBody:body isHTML:YES];
    
    NSData *imageData = UIImageJPEGRepresentation([self imageForSocialShare], 0.6);
    [vc addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"Rickface.jpg"];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)setTextForSocialShare:(SLComposeViewController *)vc {
    NSString *text = [NSString stringWithFormat:@"I asked Rick how he felt & he made a face that seemed somehow... %@ #rickface", [self.moodLine1Label.text lowercaseString]];
    [vc setInitialText:text];
}

- (void)setImageForSocialShare:(SLComposeViewController *)vc {
    
    [vc addImage:self.imageForSocialShare];
}

- (void)addURLForSocialShare:(SLComposeViewController *)vc {
    
    [vc addURL:[NSURL URLWithString:self.appStoreURLString]];
}

- (UIImage *)imageForSocialShare {
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (NSString *)appStoreURLString {
    return @"http://itunes.apple.com/app/rickface/id882560160";
}

- (void)shareFailed {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not logged in" message:@"Please log in on this device in order to share Rickface." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

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

@end
