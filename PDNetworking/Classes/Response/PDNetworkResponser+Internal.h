//
//  PDNetworkResponser+Internal.h
//  PDNetworking
//
//  Created by liang on 2021/6/18.
//

#import "PDNetworkResponserInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkDataResponser ()

@property (nonatomic, copy) void (^responseHandler)(id<PDNetworkResponse>);

@end

@interface PDNetworkUploadResponser ()

@property (nonatomic, copy) void (^constructingBody)(id<PDMultipartFormData>);
@property (nonatomic, copy) void (^progress)(NSProgress *);
@property (nonatomic, copy) void (^responseHandler)(id<PDNetworkUploadResponse>);

@end

@interface PDNetworkDownloadResponser ()

@property (nonatomic, copy) void (^progress)(NSProgress *);
@property (nonatomic, copy) NSURL *(^destination)(NSURL *, NSURLResponse *);
@property (nonatomic, copy) void (^responseHandler)(id<PDNetworkDownloadResponse>);

@end

NS_ASSUME_NONNULL_END
