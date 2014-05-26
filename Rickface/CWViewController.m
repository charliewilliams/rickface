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

#define kHasShownFirstUX @"kHasShownFirstUX"

@interface CWViewController ()

@property (weak, nonatomic) IBOutlet UILabel *rickFaceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rickFaceAboutLabel;

@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UILabel *moodLine1Label;
@property (weak, nonatomic) IBOutlet UIView *sharingContainerView;

@end

@implementation CWViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
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
    
    if (![self.store boolForKey:kHasShownFirstUX]) {
        
        UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstUX"];
        [self presentViewController:viewController animated:YES completion:nil];
        [self.store setBool:YES forKey:kHasShownFirstUX];
    }
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
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.view.backgroundColor = [UIColor blackColor];
        self.rickFaceTitleLabel.alpha = 0.0;
        self.rickFaceAboutLabel.alpha = 0.0;
        self.faceImageView.alpha = 0.0;
        self.moodLine1Label.alpha = 0.0;
        self.sharingContainerView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        [self showNewFaceImpl];
        
        [UIView animateWithDuration:0.3 animations:^{
            
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

@end
