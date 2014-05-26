//
//  CWAppDelegate.m
//  Rickface
//
//  Created by Charlie Williams on 26/05/2014.
//  Copyright (c) 2014 Charlie Williams. All rights reserved.
//

#import "CWAppDelegate.h"
#import <Parse/Parse.h>

@implementation CWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"dcpXwcx2N0XAHthxRllbAPGKAaYpgxu6KJ41HCv4" clientKey:@"INZwaPE1B0jJITP8MV0HUD0sKsRsY7gIScuqhR7X"];
    
    return YES;
}

@end
