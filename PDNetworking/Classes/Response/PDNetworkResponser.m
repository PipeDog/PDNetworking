//
//  PDNetworkResponser.m
//  PDNetworking
//
//  Created by liang on 2021/6/18.
//

#import "PDNetworkResponser.h"
#import "PDNetworkResponser+Internal.h"

@implementation PDNetworkDataResponser

+ (instancetype)responserWithResponseHandler:(void (^)(id<PDNetworkResponse>))responseHandler {
    return [[PDNetworkDataResponser alloc] initWithResponseHandler:responseHandler];
}

- (instancetype)initWithResponseHandler:(void (^)(id<PDNetworkResponse>))responseHandler {
    self = [super init];
    if (self) {
        _responseHandler = [responseHandler copy];
    }
    return self;
}

@end

@implementation PDNetworkUploadResponser

+ (instancetype)responserWithConstructingBody:(void (^)(id<PDMultipartFormData> _Nonnull))constructingBody
                                     progress:(void (^)(NSProgress * _Nonnull))progress
                              responseHandler:(void (^)(id<PDNetworkUploadResponse> _Nullable))responseHandler {
    return [[PDNetworkUploadResponser alloc] initWithConstructingBody:constructingBody
                                                             progress:progress
                                                      responseHandler:responseHandler];
}

- (instancetype)initWithConstructingBody:(void (^)(id<PDMultipartFormData> _Nonnull))constructingBody
                                progress:(void (^)(NSProgress * _Nonnull))progress
                         responseHandler:(void (^)(id<PDNetworkUploadResponse> _Nullable))responseHandler {
    self = [super init];
    if (self) {
        _constructingBody = [constructingBody copy];
        _progress = [progress copy];
        _responseHandler = [responseHandler copy];
    }
    return self;
}

@end

@implementation PDNetworkDownloadResponser

+ (instancetype)responserWithProgress:(void (^)(NSProgress * _Nonnull))progress
                          destination:(NSURL * _Nonnull (^)(NSURL * _Nonnull, NSURLResponse * _Nonnull))destination
                      responseHandler:(void (^)(id<PDNetworkDownloadResponse> _Nonnull))responseHandler {
    return [[PDNetworkDownloadResponser alloc] initWithProgress:progress
                                                    destination:destination
                                                responseHandler:responseHandler];
}

- (instancetype)initWithProgress:(void (^)(NSProgress * _Nonnull))progress
                     destination:(NSURL * _Nonnull (^)(NSURL * _Nonnull, NSURLResponse * _Nonnull))destination
                 responseHandler:(void (^)(id<PDNetworkDownloadResponse> _Nonnull))responseHandler {
    self = [super init];
    if (self) {
        _progress = [progress copy];
        _destination = [destination copy];
        _responseHandler = [responseHandler copy];
    }
    return self;
}

@end
