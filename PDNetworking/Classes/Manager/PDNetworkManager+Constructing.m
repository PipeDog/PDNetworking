//
//  PDNetworkManager+Constructing.m
//  PDNetworking
//
//  Created by liang on 2019/6/29.
//  Copyright © 2019 liang. All rights reserved.
//

#import "PDNetworkManager+Constructing.h"
#import "PDNetworkManager+Internal.h"

@implementation PDNetworkManager (Constructing)

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                               uploadProgress:(void (^)(NSProgress * _Nonnull))uploadProgressBlock
                             downloadProgress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                            completionHandler:(void (^)(NSURLResponse * _Nonnull, id _Nullable, NSError * _Nullable))completionHandler {
    return [self.sessionManager dataTaskWithRequest:request
                                     uploadProgress:uploadProgressBlock
                                   downloadProgress:downloadProgressBlock
                                  completionHandler:completionHandler];
}

#pragma mark - Upload Methods
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject, NSError  * _Nullable error))completionHandler {
    return [self.sessionManager uploadTaskWithRequest:request
                                             fromFile:fileURL
                                             progress:uploadProgressBlock
                                    completionHandler:completionHandler];
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                         progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject, NSError * _Nullable error))completionHandler {
    return [self.sessionManager uploadTaskWithRequest:request
                                             fromData:bodyData
                                             progress:uploadProgressBlock
                                    completionHandler:completionHandler];
}

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                        completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject, NSError * _Nullable error))completionHandler {
    return [self.sessionManager uploadTaskWithStreamedRequest:request
                                                     progress:uploadProgressBlock
                                            completionHandler:completionHandler];
}

#pragma mark - Download Methods
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                                          destination:(NSURL * _Nonnull (^)(NSURL * _Nonnull, NSURLResponse * _Nonnull))destination
                                    completionHandler:(void (^)(NSURLResponse * _Nonnull, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    return [self.sessionManager downloadTaskWithRequest:request
                                               progress:downloadProgressBlock
                                            destination:destination
                                      completionHandler:completionHandler];
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                                             destination:(NSURL * _Nonnull (^)(NSURL * _Nonnull, NSURLResponse * _Nonnull))destination
                                       completionHandler:(void (^)(NSURLResponse * _Nonnull, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    return [self.sessionManager downloadTaskWithResumeData:resumeData
                                                  progress:downloadProgressBlock
                                               destination:destination
                                         completionHandler:completionHandler];
}

@end
