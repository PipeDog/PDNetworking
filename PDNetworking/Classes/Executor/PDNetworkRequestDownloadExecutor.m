//
//  PDNetworkRequestDownloadExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestDownloadExecutor.h"

@implementation PDNetworkRequestDownloadExecutor

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask {
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager downloadTaskWithRequest:self.URLRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            
            !strongSelf.request.downloadProgress ?: strongSelf.request.downloadProgress(downloadProgress);
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return nil; }

        // Create intermediate dir path if needed
        NSURL *fileURL = strongSelf.request.destination(targetPath, response);
        BOOL isDir = NO; NSString *dirPath = [fileURL.path stringByDeletingLastPathComponent];
        BOOL dirExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
        
        if (!dirExist || !isDir) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        return fileURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        [strongSelf lock];
        [strongSelf _handleResponse:filePath error:error];
        [strongSelf unlock];
    }];
}

#pragma mark - Private Methods
- (void)_handleResponse:(id)responseObject error:(NSError *)error {
    if (!error || [self isCancelled]) {
        [self _notifyRequestWithFileURL:responseObject error:error];
        return;
    }
    
    if (self.currentRetryTimes < self.request.autoRetryTimes) {
        self.currentRetryTimes += 1;
        self.request.sessionTask = self.sessionTask;
        [self.request.sessionTask resume];
        return;
    }
    
    [self _notifyRequestWithFileURL:responseObject error:error];
}

- (void)_notifyRequestWithFileURL:(NSURL *)fileURL error:(NSError *)error {
    dispatch_async(self.request.completionQueue ?: dispatch_get_main_queue(), ^{
        id<PDNetworkDownloadResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = self.request.sessionTask.response;
        response.filePath = fileURL;
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishDownload:self.request withResponse:response];
        
        if (!error) {
            !self.request.downloadSuccess ?: self.request.downloadSuccess(response);
        } else {
            !self.request.downloadFailure ?: self.request.downloadFailure(response);
        }
        
        [self.request removeRequestBlocks];
        !self.doneHandler ?: self.doneHandler(!!(fileURL && !error), error);
    });
}

@end
