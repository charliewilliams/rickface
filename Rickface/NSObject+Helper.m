//
//  NSObject+Helper.m
//  Untitled
//
//  Created by Charlie Williams on 20/01/2014.
//  Copyright (c) 2014 Kudan. All rights reserved.
//

#import "NSObject+Helper.h"
#import <UIKit/UIKit.h>

@implementation NSObject (Helper)

- (BOOL)isPad {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (BOOL)is4inch {
    return [UIScreen mainScreen].bounds.size.height == 568.0;
}

- (BOOL)isRetina {
    return [UIScreen mainScreen].scale == 2.;
}

- (NSUserDefaults *)store {
    return [NSUserDefaults standardUserDefaults];
}

- (NSURL *)applicationDocumentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]; //[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]; //
}

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

- (NSFileManager *)fileManager {
    return [NSFileManager defaultManager];
}

- (NSString *)localeString {
    return [[NSLocale currentLocale] localeIdentifier];
}

- (NSString *)deviceString {
    return self.isPad ? @"tablet" : @"phone";
}

// convenience method to auto-create missing directories
- (void)saveData:(NSData *)data atPath:(NSString *)filePathString {
    
    BOOL isDirectory = NO;
    BOOL fileOrDirectoryExists = [self.fileManager fileExistsAtPath:filePathString isDirectory:&isDirectory];
    
    if (!fileOrDirectoryExists) {
        
        NSError *error = nil;
        BOOL success = [self.fileManager createDirectoryAtPath:[filePathString stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (!success) {
            DLog(@"Failed to create directory with error: %@", error);
        }
    }
    
    NSError *error = nil;
    [data writeToFile:filePathString options:0 error:&error];
    
    if (error) {
        DLog(@"Failed to write file at %@ with error: %@", filePathString, error);
    } else {
//        DLog(@"Wrote file at %@", filePathString);
    }
}

#pragma mark - Time format strings
#define kSecondsString @"seconds"
#define kMinuteString @"minute"
#define kMinutesString @"minutes"

- (NSString *)timeFormatStringForSeconds:(NSInteger)seconds {
    
    return [self timeFormatStringForSeconds:seconds lineBreak:NO];
}

- (NSString *)timeFormatStringForSeconds:(NSInteger)seconds roundedTo:(NSUInteger)rounder {
    
    if (!rounder) return [self timeFormatStringForSeconds:seconds];
    
    NSInteger minutes = seconds / 60;
    seconds %= 60;
    seconds /= rounder;
    seconds *= rounder;
    
    if (!minutes) {
        
        return [NSString stringWithFormat:@":%02ld", (long)seconds];
    }
    else {
        
        return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
    }
}

- (NSString *)timeFormatStringForSeconds:(NSInteger)seconds lineBreak:(BOOL)lineBreak {
    
    NSString *lineBreakString = lineBreak ? @"\n" : @" ";
    
    NSInteger minutes = seconds / 60;
    seconds %= 60;
    
    if (!minutes) {
        
        return [NSString stringWithFormat:@"%ld %@", (long)seconds, kSecondsString];
    }
    else if (!seconds) {
        
        return [NSString stringWithFormat:@"%ld %@", (long)minutes, (minutes == 1) ? kMinuteString : kMinutesString];
    }
    else {
        
        return [NSString stringWithFormat:@"%ld %@%@%02ld %@", (long)minutes, (minutes == 1) ? kMinuteString : kMinutesString, lineBreakString, (long)seconds, kSecondsString];
    }
}

- (NSString *)timeFormatStringForSecondsRounded:(NSInteger)seconds {
    
    seconds /= 60;
    seconds *= 60;
    return [self timeFormatStringForSeconds:seconds];
}


@end
