//
//  PDNetworkRequest+Internal.h
//  PDNetworking
//
//  Created by liang on 2020/3/27.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class PDNetworkRequestVisitor;

typedef NS_ENUM(NSUInteger, PDNetworkRequestAction) {
    PDNetworkRequestActionNormal = 0,
    PDNetworkRequestActionDownload,
    PDNetworkRequestActionUpload,
};

@interface PDNetworkRequest ()

@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;
@property (nonatomic, assign) NSUInteger currentRetryTimes; // Record the current number of retries.
@property (nonatomic, strong) PDNetworkRequestVisitor *visitor;
@property (nonatomic, assign) PDNetworkRequestAction action;

@property (nonatomic, copy, nullable) void (^success)(id<PDNetworkResponse>);
@property (nonatomic, copy, nullable) void (^failure)(id<PDNetworkResponse>);

@property (nonatomic, copy, nullable) void (^downloadProgress)(NSProgress *);
@property (nonatomic, copy, nullable) NSURL * (^destination)(NSURL *, NSURLResponse *);
@property (nonatomic, copy, nullable) void (^downloadSuccess)(id<PDNetworkDownloadResponse>);
@property (nonatomic, copy, nullable) void (^downloadFailure)(id<PDNetworkDownloadResponse>);

@property (nonatomic, copy, nullable) void (^uploadSuccess)(id<PDNetworkUploadResponse>);
@property (nonatomic, copy, nullable) void (^uploadFailure)(id<PDNetworkUploadResponse>);
@property (nonatomic, copy, nullable) void (^uploadProgress)(NSProgress *);
@property (nonatomic, copy, nullable) void (^constructingBody)(id<PDMultipartFormData>);

- (void)clearRequestBlocks;
- (void)setNeedsUpdate;

@end

NS_ASSUME_NONNULL_END
