//
//  PDNetworkRequest.h
//  PDNetworking
//
//  Created by liang on 2019/6/26.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDNetworkResponse.h"
#import "PDNetworkDefinition.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol PDMultipartFormData;

typedef NSString * PDNetworkRequestID;

@interface PDNetworkRequest : NSObject

@property (nonatomic, weak, nullable) id owner;
@property (nonatomic, assign) PDNetworkRequestMethod requestMethod; // Default is 'POST'.
@property (nonatomic, copy, nullable) NSString *baseUrl;
@property (nonatomic, copy, nullable) NSString *urlPath;
@property (nonatomic, copy, nullable) NSDictionary *parameters;
@property (nonatomic, assign) PDNetworkRequestCachePolicy cachePolicy; // Default is PDNetworkRequestReloadIgnoringCacheData.
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *requestHeaders;
@property (nonatomic, assign) PDNetworkRequestSerializerType serializerType; // Default is 'HTTP'.
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // Default is 30s.
@property (nonatomic, assign) NSUInteger autoRetryTimes; // Default is 3.
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue; // Default is main queue.
@property (nonatomic, copy, nullable) __kindof NSURLSessionTask *(^customSessionTask)(void); // All the other constructing properties are ignored if the `customSessionTask` is not nil, and need to manage PDNetworkRequest instance memory by yourself.
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;

- (instancetype)sendWithSuccess:(void (^ __nullable)(id<PDNetworkResponse> response))success
                        failure:(void (^ __nullable)(id<PDNetworkResponse> response))failure;

- (instancetype)downloadWithProgress:(void (^ __nullable)(NSProgress *downloadProgress))downloadProgressBlock
                         destination:(NSURL * (^ __nonnull)(NSURL *targetPath, NSURLResponse *response))destination
                             success:(void (^ __nullable)(id<PDNetworkDownloadResponse> response))success
                             failure:(void (^ __nullable)(id<PDNetworkDownloadResponse> response))failure;

- (instancetype)uploadWithConstructingBody:(void (^ __nullable)(id<PDMultipartFormData> formData))block
                                  progress:(void (^ __nullable)(NSProgress *uploadProgress))uploadProgress
                                   success:(void (^ __nullable)(id<PDNetworkUploadResponse> response))success
                                   failure:(void (^ __nullable)(id<PDNetworkUploadResponse> response))failure;

- (void)cancel;
- (PDNetworkRequestID)requestID;

@end

@protocol PDMultipartFormData <AFMultipartFormData>

@end

NS_ASSUME_NONNULL_END
