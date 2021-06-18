//
//  PDNetworkResponser.h
//  PDNetworking
//
//  Created by liang on 2021/6/18.
//

#import <Foundation/Foundation.h>
#import "PDNetworkResponserInternal.h"
#import "PDNetworkResponse.h"
#import "PDMultipartFormData.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkDataResponser : PDNetworkResponser

+ (instancetype)responserWithResponseHandler:(void (^)(id<PDNetworkResponse> response))responseHandler;

@end

@interface PDNetworkUploadResponser : PDNetworkResponser

+ (instancetype)responserWithConstructingBody:(void (^)(id<PDMultipartFormData> formData))constructingBody
                                     progress:(void (^ _Nullable)(NSProgress *progress))progress
                              responseHandler:(void (^ _Nullable)(id<PDNetworkUploadResponse> _Nullable response))responseHandler;

@end

@interface PDNetworkDownloadResponser : PDNetworkResponser

+ (instancetype)responserWithProgress:(void (^ _Nullable)(NSProgress *progress))progress
                          destination:(NSURL *(^)(NSURL *targetPath, NSURLResponse *response))destination
                      responseHandler:(void (^ _Nullable)(id<PDNetworkDownloadResponse> response))responseHandler;

@end

NS_ASSUME_NONNULL_END
