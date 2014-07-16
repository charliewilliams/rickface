//
//  CWAppDelegate.m
//  Rickface
//
//  Created by Charlie Williams on 26/05/2014.
//  Copyright (c) 2014 Charlie Williams. All rights reserved.
//

#import "CWAppDelegate.h"
#import <Parse/Parse.h>

#define kTrackingId @"UA-33416008-6"

@implementation CWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [GAI sharedInstance].dispatchInterval = 120;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    self.tracker = [[GAI sharedInstance] trackerWithName:@"Rickface" trackingId:kTrackingId];
    
    [Parse setApplicationId:@"dcpXwcx2N0XAHthxRllbAPGKAaYpgxu6KJ41HCv4" clientKey:@"INZwaPE1B0jJITP8MV0HUD0sKsRsY7gIScuqhR7X"];
    
    return YES;
}

@end
