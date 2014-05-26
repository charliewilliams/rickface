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
@property (weak, nonatomic) IBOutlet UILabel *moodLine2Label;

@end

@implementation CWViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
//    [downloadQuery includeKey:@"faceImage"];
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
        
        self.rickFaceTitleLabel.alpha = 0;
        self.rickFaceAboutLabel.alpha = 0;
    }];
    
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
}

@end
