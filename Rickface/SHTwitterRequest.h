//
//  SHTwitterAccount.h
//  Shazam
//
//  Created by Duncan Fleming on 23/07/2012.
//  Copyright (c) 2012 Shazam Entertainment Ltd. All rights reserved.
//

#import <Social/Social.h>

#define kTwitterAccessKey @"twitterAccessKey"

#define kTwitterScreenNameKey @"screen_name"
#define kTwitterFollowingKey @"following"
#define kTwitterLookupConnectionsKey @"connections"
#define kTwitterUserIdStringKey @"id_str"

typedef void (^SHTwtterLookupCompletionBlock) (NSString *userId, NSString *screenName, BOOL isFollowing, NSError *error);

@interface SHTwitterRequest : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, strong) ACAccount *authorizedAccount;

- (id)initWithAccount:(ACAccount *)account;
- (SLRequest *)buildAuthorizedTwitterRequestWithURL:(NSString *)inURL requestMethod:(SLRequestMethod)method parameters:(NSDictionary *)params error:(NSError **)error;

@end
