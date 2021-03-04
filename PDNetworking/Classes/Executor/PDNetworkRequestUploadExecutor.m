//
//  PDNetworkRequestUploadExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestUploadExecutor.h"
#import "PDNetworkRequest+Internal.h"
#import "PDNetworkPluginManager.h"
#import "PDNetworkResponse.h"
#import "PDNetworkDataUtil.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

@implementation PDNetworkRequestUploadExecutor

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask {
    return [self.sessionManager dataTaskWithRequest:self.URLRequest
                                     uploadProgress:self.request.uploadProgress
                                   downloadProgress:nil
                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        id parsedData = [self parseResponseData:responseObject outError:nil];
        [self _handleResponse:parsedData error:error];
    }];
}

#pragma mark - Private Methods
- (void)_handleResponse:(id)responseObject error:(NSError *)error {
    if (!error) {
        [self _notifyRequestWithResponse:responseObject error:error];
        return;
    }
    
    // Retry if needed
    if (self.currentRetryTimes < self.request.autoRetryTimes) {
        self.currentRetryTimes += 1;
        [self.request.sessionTask resume];
        return;
    }
    
    [self _notifyRequestWithResponse:responseObject error:error];
}

- (void)_notifyRequestWithResponse:(id)responseObject error:(NSError *)error {
    dispatch_async(self.request.completionQueue ?: dispatch_get_main_queue(), ^{
        id<PDNetworkUploadResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = self.request.sessionTask.response;
        response.data = PDNKValueToJSONObject(responseObject);
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishUpload:self.request withResponse:response];
        
        if (!error) {
            !self.request.uploadSuccess ?: self.request.uploadSuccess(response);
        } else {
            !self.request.uploadFailure ?: self.request.uploadFailure(response);
        }
        
        !self.doneHandler ?: self.doneHandler(!!(responseObject && !error), error);
    });
}

@end
