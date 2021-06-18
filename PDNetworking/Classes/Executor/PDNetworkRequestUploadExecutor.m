//
//  PDNetworkRequestUploadExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestUploadExecutor.h"
#import "PDNetworkResponser+Internal.h"

@implementation PDNetworkRequestUploadExecutor

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask {
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager dataTaskWithRequest:self.URLRequest
                                     uploadProgress:self.responser.progress
                                   downloadProgress:nil
                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        [strongSelf lock];
        id parsedData = [strongSelf parseResponseData:responseObject outError:nil];
        [strongSelf _handleResponse:parsedData error:error];
        [strongSelf unlock];
    }];
}

#pragma mark - Private Methods
- (void)_handleResponse:(id)responseObject error:(NSError *)error {
    if (!error || [self isCancelled]) {
        [self _notifyRequestWithResponse:responseObject error:error];
        return;
    }
    
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
        response.data = PDNTValueToJSONObject(responseObject);
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishUpload:self.request withResponse:response];
        
        !self.responser.responseHandler ?: self.responser.responseHandler(response);
        [self.request unbindResponser];
        !self.doneHandler ?: self.doneHandler(!!(responseObject && !error), error);
    });
}

- (PDNetworkUploadResponser *)responser {
    return (PDNetworkUploadResponser *)self.request.responser;
}

@end
