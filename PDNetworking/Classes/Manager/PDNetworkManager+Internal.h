//
//  PDNetworkManager+Internal.h
//  PDNetworking
//
//  Created by liang on 2020/3/27.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDNetworkManager.h"
#import "PDNetworkCache.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkManager ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

NS_ASSUME_NONNULL_END
