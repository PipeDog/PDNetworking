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

typedef NS_ENUM(NSUInteger, PDNetworkRequestType) {
    PDNetworkRequestTypeRegular   = 0,
    PDNetworkRequestTypeDownload  = 1,
    PDNetworkRequestTypeUpload    = 2,
};

@interface PDNetworkRequest ()

@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;
@property (nonatomic, assign) PDNetworkRequestType requestType;

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

- (void)removeRequestBlocks;

@end

NS_ASSUME_NONNULL_END
