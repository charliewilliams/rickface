//
//  SNGViewController.h
//  Camera Handler
//
//  Created by Eddy Gammon on 08/05/2014.
//  Copyright (c) 2014 Kudan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TakePhotoViewController : UIViewController

@property (nonatomic, strong) NSString *activeSLServiceType;
@property (nonatomic, weak) IBOutlet UIImageView *rickFaceImageView;
@property (weak, nonatomic) IBOutlet UILabel *moodLabel;
@property (weak, nonatomic) IBOutlet UILabel *userFeelsLabel;

@end
