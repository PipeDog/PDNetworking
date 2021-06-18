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
#import "PDNetworkUUID.h"

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
    }
    return self;
}

#pragma mark - Public Methods
- (instancetype)sendWithResponser:(__kindof PDNetworkResponser *)responser {

    if ([responser isKindOfClass:[PDNetworkDataResponser class]]) {
        self.requestType = PDNetworkRequestTypeData;
    } else if ([responser isKindOfClass:[PDNetworkUploadResponser class]]) {
        self.requestType = PDNetworkRequestTypeUpload;
    } else if ([responser isKindOfClass:[PDNetworkDownloadResponser class]]) {
        self.requestType = PDNetworkRequestTypeDownload;
    } else {
        NSAssert(NO, @"Invalid responser class `%@`", NSStringFromClass([responser class]));
    }
    
    self.responser = responser;
    [[PDNetworkManager defaultManager] addRequest:self];
    return self;
}

- (void)cancel {
    [[PDNetworkManager defaultManager] cancelRequest:self];
}

- (PDNetworkRequestID)requestID {
    if (!_requestID) {
        _requestID = [PDNetworkUUID UUID].UUIDString;
    }
    return _requestID;
}

#pragma mark - Private Methods
- (void)unbindResponser {
    self.responser = nil;
}

#pragma mark - Getter Methods
- (BOOL)isExecuting {
    return (self.sessionTask.state == NSURLSessionTaskStateRunning);
}

@end
