//
//  PDNetworkRequestVisitor.h
//  PDNetworking
//
//  Created by liang on 2020/3/27.
//  Copyright © 2020 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPRequestSerializer, AFHTTPResponseSerializer, PDNetworkRequest;

@interface PDNetworkRequestVisitor : NSObject

@property (nonatomic, strong, readonly) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong, readonly) AFHTTPResponseSerializer *responseSerializer;
@property (nonatomic, strong, readonly) NSString *URLString;

- (instancetype)initWithRequest:(PDNetworkRequest *)request;

- (BOOL)shouldContinueRequestingAfterHandleCache;
- (id _Nullable)cachedData;
- (void)setCacheData:(id _Nullable)cacheData;

@end

NS_ASSUME_NONNULL_END
