//
//  SHTwitterRequestFollow.h
//  Shazam
//
//  Created by Duncan Fleming on 05/11/2012.
//  Copyright (c) 2012 Shazam Entertainment Ltd. All rights reserved.
//

#import "SHTwitterRequest.h"

typedef void (^SHTwtterFollowCompletionBlock) (NSString *userId, NSString *screenName, BOOL success, NSError *error);

@interface SHTwitterRequestFollow : SHTwitterRequest

- (void)followUserWithScreenName:(NSString *)screenName completion:(SHTwtterFollowCompletionBlock)completion;

@end
