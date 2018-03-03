//
//  CWAppDelegate.m
//  Rickface
//
//  Created by Charlie Williams on 26/05/2014.
//  Copyright (c) 2014 Charlie Williams. All rights reserved.
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "CWAppDelegate.h"

#define kTrackingId @"UA-33416008-6"

@implementation CWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [GAI sharedInstance].dispatchInterval = 120;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    self.tracker = [[GAI sharedInstance] trackerWithName:@"Rickface" trackingId:kTrackingId];

    [Fabric with:@[[Crashlytics class]]];
    
    return YES;
}

@end
