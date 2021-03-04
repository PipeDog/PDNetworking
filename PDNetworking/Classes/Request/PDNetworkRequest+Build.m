//
//  PDNetworkRequest+Build.m
//  PDNetworking
//
//  Created by liang on 2019/7/6.
//  Copyright © 2019 liang. All rights reserved.
//

#import "PDNetworkRequest+Build.h"

@interface PDNetworkRequestBuilder : NSObject <PDNetworkRequestBuilder>

@end

@implementation PDNetworkRequestBuilder

@synthesize owner = _owner;
@synthesize requestMethod = _requestMethod;
@synthesize baseUrl = _baseUrl;
@synthesize urlPath = _urlPath;
@synthesize cachePolicy = _cachePolicy;
@synthesize requestHeaders = _requestHeaders;
@synthesize serializerType = _serializerType;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize autoRetryTimes = _autoRetryTimes;
@synthesize completionQueue = _completionQueue;

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeoutInterval = PDNetworkRequestDefaultTimeoutInterval;
        _requestMethod = PDNetworkRequestMethodPOST;
        _serializerType = PDNetworkRequestSerializerTypeHTTP;
        _cachePolicy = PDNetworkRequestReloadIgnoringCacheData;
        _autoRetryTimes = PDNetworkRequestDefaultAutoRetryTimes;
    }
    return self;
}

@end

@implementation PDNetworkRequest (Build)

+ (instancetype)requestWithBuilder:(void (^)(id<PDNetworkRequestBuilder> _Nonnull))block {
    PDNetworkRequest *request = [[self alloc] init];
    id<PDNetworkRequestBuilder> builder = [[PDNetworkRequestBuilder alloc] init];
    
    !block ?: block(builder);
    
    request.owner = builder.owner;
    request.requestMethod = builder.requestMethod;
    request.baseUrl = builder.baseUrl;
    request.urlPath = builder.urlPath;
    request.cachePolicy = builder.cachePolicy;
    request.requestHeaders = builder.requestHeaders;
    request.serializerType = builder.serializerType;
    request.timeoutInterval = builder.timeoutInterval;
    request.autoRetryTimes = builder.autoRetryTimes;
    request.completionQueue = builder.completionQueue;
    return request;
}

- (instancetype)appendParameters:(NSDictionary * _Nonnull (^)(void))block {
    NSDictionary *parameters;
    if (block) {
        parameters = block();
    }
    self.parameters = parameters;
    return self;
}

@end
