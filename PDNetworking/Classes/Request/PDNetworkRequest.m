//
//  PDNetworkRequest.m
//  PDNetworking
//
//  Created by liang on 2019/6/26.
//  Copyright © 2019 liang. All rights reserved.
//

#import "PDNetworkRequest.h"
#import "PDNetworkRequest+Internal.h"
#import "PDNetworkManager.h"
#import "PDNetworkRequestVisitor.h"
#import "PDNKCodecUUID.h"

@implementation PDNetworkRequest {
    PDNetworkRequestID _requestID;
}

@dynamic executing;

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeoutInterval = PDNetworkRequestDefaultTimeoutInterval;
        _requestMethod = PDNetworkRequestMethodPOST;
        _serializerType = PDNetworkRequestSerializerTypeHTTP;
        _cachePolicy = PDNetworkRequestReloadIgnoringCacheData;
        _autoRetryTimes = PDNetworkRequestDefaultAutoRetryTimes;
        _currentRetryTimes = 0;
    }
    return self;
}

#pragma mark - Public Methods
- (instancetype)sendWithSuccess:(void (^)(id<PDNetworkResponse> _Nonnull))success
                        failure:(void (^)(id<PDNetworkResponse> _Nonnull))failure {
    self.action = PDNetworkRequestActionRegular;
    self.success = success;
    self.failure = failure;
    [[PDNetworkManager defaultManager] addRequest:self];
    return self;
}

- (instancetype)downloadWithProgress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                         destination:(NSURL * _Nonnull (^)(NSURL * _Nonnull, NSURLResponse * _Nonnull))destination
                             success:(void (^)(id<PDNetworkDownloadResponse> _Nonnull))success
                             failure:(void (^)(id<PDNetworkDownloadResponse> _Nonnull))failure {
    NSAssert(destination != nil, @"The block `destination` can not be nil!");
    
    self.action = PDNetworkRequestActionDownload;
    self.downloadProgress = downloadProgressBlock;
    self.destination = destination;
    self.downloadSuccess = success;
    self.downloadFailure = failure;
    [[PDNetworkManager defaultManager] addRequest:self];
    return self;
}

- (instancetype)uploadWithConstructingBody:(void (^)(id<PDMultipartFormData> _Nonnull))block
                                  progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                                   success:(void (^)(id<PDNetworkUploadResponse> _Nonnull))success
                                   failure:(void (^)(id<PDNetworkUploadResponse> _Nonnull))failure {
    self.action = PDNetworkRequestActionUpload;
    self.constructingBody = block;
    self.uploadProgress = uploadProgress;
    self.uploadSuccess = success;
    self.uploadFailure = failure;
    [[PDNetworkManager defaultManager] addRequest:self];
    return self;
}

- (void)cancel {
    [[PDNetworkManager defaultManager] cancelRequest:self];
}

- (PDNetworkRequestID)requestID {
    if (!_requestID) {
        _requestID = [PDNKCodecUUID UUID].UUIDString;
    }
    return _requestID;
}

#pragma mark - Private Methods
- (void)clearRequestBlocks {
    _success = nil;
    _failure = nil;
    _downloadProgress = nil;
    _destination = nil;
    _downloadSuccess = nil;
    _downloadFailure = nil;
    _uploadProgress = nil;
    _constructingBody = nil;
    _uploadSuccess = nil;
    _uploadFailure = nil;
}

- (void)setNeedsUpdate {
    _visitor = nil;
}

#pragma mark - Getter Methods
- (BOOL)isExecuting {
    return (self.sessionTask.state == NSURLSessionTaskStateRunning);
}

- (PDNetworkRequestVisitor *)visitor {
    if (!_visitor) {
        _visitor = [[PDNetworkRequestVisitor alloc] initWithRequest:self];
    }
    return _visitor;
}

@end
