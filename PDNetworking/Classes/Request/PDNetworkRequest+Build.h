//
//  PDNetworkRequest+Build.h
//  PDNetworking
//
//  Created by liang on 2019/7/6.
//  Copyright © 2019 liang. All rights reserved.
//

#import "PDNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDNetworkRequestBuilder <NSObject>

@property (nonatomic, weak, nullable) id owner;
@property (nonatomic, assign) PDNetworkRequestMethod requestMethod; // Default is 'POST'.
@property (nonatomic, copy, nullable) NSString *baseUrl;
@property (nonatomic, copy, nullable) NSString *urlPath;
@property (nonatomic, assign) PDNetworkRequestCachePolicy cachePolicy; // Default is PDNetworkRequestReloadIgnoringCacheData.
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *requestHeaders;
@property (nonatomic, assign) PDNetworkRequestSerializerType serializerType; // Default is 'HTTP'.
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // Default is 30s.
@property (nonatomic, assign) NSUInteger autoRetryTimes; // Default is 3.
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue; // Default is main queue.

@end

@interface PDNetworkRequest (Build)

+ (instancetype)requestWithBuilder:(void (^)(id<PDNetworkRequestBuilder> builder))block;

- (instancetype)appendParameters:(NSDictionary *(^)(void))block;

@end

NS_ASSUME_NONNULL_END
