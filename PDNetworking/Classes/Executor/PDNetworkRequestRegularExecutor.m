//
//  PDNetworkRequestRegularExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestRegularExecutor.h"
#import "PDNetworkManager.h"

@interface PDNetworkRequestRegularExecutor ()

@property (nonatomic, strong) id<PDNetworkCache> cache;

@end

@implementation PDNetworkRequestRegularExecutor

- (instancetype)initWithRequest:(PDNetworkRequest *)request sessionManager:(AFHTTPSessionManager *)sessionManager {
    self = [super initWithRequest:request sessionManager:sessionManager];
    if (self) {
        _cache = [PDNetworkManager defaultManager].networkCache;

        // Handle cache logic here
        id cachedData = nil;
        BOOL continueRequesting = YES;
        PDNetworkRequestCachePolicy cachePolicy = self.request.cachePolicy;
        
        if (cachePolicy == PDNetworkRequestReturnCacheDataThenLoad) {
            if ((cachedData = [self _cachedData])) {
                [self _notifyRequestWithCachedData:cachedData];
            }
        } else if (cachePolicy == PDNetworkRequestReturnCacheDataElseLoad) {
            if ((cachedData = [self _cachedData])) {
                [self _notifyRequestWithCachedData:cachedData];
                continueRequesting = NO;
            }
        } else if (cachePolicy == PDNetworkRequestReturnCacheDataDontLoad) {
            [self _notifyRequestWithCachedData:(cachedData = [self _cachedData])];
            continueRequesting = NO;
        } else {
            // Do nothing...
        }

        if (!continueRequesting) {
            return nil;
        }
    }
    return self;
}

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask {
    return [self.sessionManager dataTaskWithRequest:self.URLRequest
                                     uploadProgress:nil
                                   downloadProgress:nil
                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        id parsedData = [self parseResponseData:responseObject outError:nil];
        [self _handleResponse:parsedData error:error];
    }];
}

#pragma mark - Private Methods
- (id)_cachedData {
    __block id cachedData = nil;
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    
    [_cache objectForKey:self.requestCacheID withBlock:^(NSString * _Nonnull key, id  _Nullable object) {
        cachedData = object;
        dispatch_semaphore_signal(lock);
    }];
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    return cachedData;
}

- (void)_notifyRequestWithCachedData:(id)data {
    id<PDNetworkResponse> response = [[PDNetworkResponse alloc] init];
    response.data = data;
    
    dispatch_async(self.request.completionQueue ?: dispatch_get_main_queue(), ^{
        !self.request.success ?: self.request.success(response);
    });
}

- (void)_handleResponse:(id)responseObject error:(NSError *)error {
    if (!error || [self isCancelled]) {
        [self _notifyRequestWithResponse:responseObject error:error];
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
    
    [self _notifyRequestWithResponse:responseObject error:error];
}

- (void)_notifyRequestWithResponse:(id)responseObject error:(NSError *)error {
    dispatch_async(self.request.completionQueue ?: dispatch_get_main_queue(), ^{
        id<PDNetworkResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = self.request.sessionTask.response;
        response.data = PDNTValueToJSONObject(responseObject);
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishLoad:self.request withResponse:response];
        
        if (!error) {
            !self.request.success ?: self.request.success(response);
            // Save cache data after callback
            [self.cache setObject:responseObject forKey:self.requestCacheID withBlock:nil];
        } else {
            !self.request.failure ?: self.request.failure(response);
        }
        
        !self.doneHandler ?: self.doneHandler(!!(responseObject && !error), error);
    });
}

@end
