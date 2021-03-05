//
//  PDNetworkManager.h
//  PDNetworking
//
//  Created by liang on 2019/6/26.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDNetworkCache.h"

@class PDNetworkRequest;

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkManager : NSObject

@property (class, strong, readonly) PDNetworkManager *defaultManager;

@property (nonatomic, strong) id<PDNetworkCache> networkCache;

- (void)addRequest:(PDNetworkRequest *)request;
- (void)cancelRequest:(PDNetworkRequest *)request;

// If return YES, the request will be canceled
- (void)cancelRequestsWithFilter:(BOOL (^)(PDNetworkRequest *request))filter;
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
