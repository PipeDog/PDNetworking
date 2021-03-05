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
    return [self.sessionManager downloadTaskWithRequest:self.URLRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            !self.request.downloadProgress ?: self.request.downloadProgress(downloadProgress);
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        // Get 'Content-Length' from response header
        long long contentLen = -1;
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *HTTPResp = (NSHTTPURLResponse *)response;
            if (HTTPResp.statusCode >= 300 && HTTPResp.statusCode < 600) {
                return nil;
            }

            NSString *contentLenText = HTTPResp.allHeaderFields[@"Content-Length"];
            contentLen = [contentLenText longLongValue];
        }

        if (contentLen <= 0) {
            // Maybe `expectedContentLength` value is `-1`, if the resource type is zip, should set "Accept-Encoding" to request header
            // https://stackoverflow.com/questions/11136020/response-expectedcontentlength-return-1
            contentLen = response.expectedContentLength;
        }
                
        if (contentLen <= 0) { return nil; }
        
        // 'fileSize' from local file info
        NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:targetPath.path error:NULL];
        long long fileSize = [fileInfo[NSFileSize] longLongValue];
        if (fileSize < contentLen) { return nil; }
        
        // Create intermediate dir path if needed
        NSURL *fileURL = self.request.destination(targetPath.path, response);
        BOOL isDir = NO; NSString *dirPath = [fileURL.path stringByDeletingLastPathComponent];
        BOOL dirExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
        
        if (!dirExist || !isDir) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]
        }
        
        return fileURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [self _handleResponse:filePath error:error];
    }];;
}

#pragma mark - Private Methods
- (void)_handleResponse:(id)responseObject error:(NSError *)error {
    if (!error || [self isCancelled]) {
        [self _notifyRequestWithFileURL:responseObject error:error];
        return;
    }
    
    [self lock];
    NSUInteger currentRetryTimes = self.currentRetryTimes;
    [self unlock];

    if (currentRetryTimes < self.request.autoRetryTimes) {
        [self lock];
        self.currentRetryTimes += 1;
        [self unlock];
        
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
        
        !self.doneHandler ?: self.doneHandler(!!(fileURL && !error), error);
    });
}

@end
