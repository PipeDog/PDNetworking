//
//  PDNetworkRequestExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestExecutor.h"
#import "PDNetworkRequest.h"
#import "NSString+PDNetworking.h"

@implementation PDNetworkRequestExecutor

- (instancetype)initWithRequest:(PDNetworkRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return nil;
    }
    
    self = [super init];
    if (self) {
        _request = request;
        
        // Append full url
        NSString *url = _request.baseUrl;
        if (_request.urlPath.length > 0) {
            url = [url stringByAppendingString:_request.urlPath];
        }
        if (![NSURL URLWithString:url]) {
            url = [url encodeWithURLQueryAllowedCharacterSet];
        }
        _fullRequestURL = url;
              
        // Create request cache id
        NSString *requestCacheID = [_fullRequestURL copy];
        requestCacheID = [requestCacheID urlStringWithParameters:_request.parameters];
        _requestCacheID = [requestCacheID encodeWithURLQueryAllowedCharacterSet];
        
        // Request serializer
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        if (_request.serializerType == PDNetworkRequestSerializerTypeJSON) {
            requestSerializer = [AFJSONRequestSerializer serializer];
        }
        requestSerializer.timeoutInterval = _request.timeoutInterval;

        NSDictionary<NSString *, NSString *> *requestHeaders = [_request.requestHeaders copy];
        for (NSString *httpHeaderField in requestHeaders.allKeys) {
            NSString *value = requestHeaders[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
        
        _requestSerializer = requestSerializer;
        
        // Response serializer
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        if (_request.serializerType == PDNetworkRequestSerializerTypeJSON) {
            responseSerializer = [AFJSONResponseSerializer serializer];
        }

        _responseSerializer = responseSerializer;
    }
    return self;
}

- (void)executeWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    NSAssert(NO, @"This method must be override!");
}

- (void)cancel {
    NSAssert(NO, @"This method must be override!");
}

@end
