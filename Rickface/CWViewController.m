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
            
            NSString *moodString = face[@"moodString"];
            NSString *path = [self.documentsDirectory stringByAppendingPathComponent:moodString];
            if ([self.fileManager fileExistsAtPath:path]) {
                continue;
            }
            
            PFFile *file = face[@"faceImage"];
            
            NSError *error = nil;
            NSData *data = [file getData:&error];
            if (error) {
                DLog(@"%@", error);
            }
            
            [data writeToFile:path atomically:NO];
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
@end
