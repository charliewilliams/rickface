//
//  SHTwitterRequestFollow.m
//  Shazam
//
//  Created by Duncan Fleming on 05/11/2012.
//  Copyright (c) 2012 Shazam Entertainment Ltd. All rights reserved.
//

#import "SHTwitterRequestFollow.h"

#define kTwitterFollowURL @"https://api.twitter.com/1.1/friendships/create.json"

@implementation SHTwitterRequestFollow

- (void)followUserWithScreenName:(NSString *)screenName completion:(SHTwtterFollowCompletionBlock)completion {
    
    NSError *error = nil;
    
    NSDictionary *requestParams = @{kTwitterScreenNameKey: screenName};
    SLRequest *request = [self buildAuthorizedTwitterRequestWithURL:kTwitterFollowURL requestMethod:SLRequestMethodPOST parameters:requestParams error:&error];
    
    if (request == nil){
        completion(nil, screenName, NO, error);
    }
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        [self parseFollowUserWithScreenName:screenName responseData:responseData urlResponse:urlResponse error:error completion:completion];
        
    }];
}

#pragma mark parsingCode

- (void)parseFollowUserWithScreenName:(NSString *)screenName responseData:(NSData *)responseData urlResponse:(NSHTTPURLResponse *)urlResponse error:(NSError *)error completion:(SHTwtterLookupCompletionBlock)completion {
    
    if ([responseData length] == 0) {
        
        completion(nil, screenName, NO, error);
    } else {
        
        NSError *jsonError = nil;
        id newFollower = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
        
        if ([newFollower isKindOfClass:[NSDictionary class]]) {
            
            if (newFollower[kTwitterFollowingKey] == nil) {
                completion(nil, screenName, NO, [NSError errorWithDomain:@"shakers" code:0 userInfo:@{@"error":@"no user or unexpected response"}]);
                return;
            }
            
            BOOL following = ((NSNumber *)newFollower[kTwitterFollowingKey]).boolValue;
            NSString *userId = newFollower[kTwitterUserIdStringKey];
            completion(userId, screenName, following, nil);
        } else {
            
            if(jsonError == nil){
                jsonError = [NSError errorWithDomain:@"shakers" code:0 userInfo:@{@"error":@"no user or unexpected response"}];
            }
            completion(nil, screenName, NO, jsonError);
        }
    }
    
}

@end
