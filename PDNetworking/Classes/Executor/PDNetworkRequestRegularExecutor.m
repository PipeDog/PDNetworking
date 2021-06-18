//
//  PDNetworkRequestRegularExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestRegularExecutor.h"
#import "PDNetworkManager.h"
#import "PDNetworkResponser+Internal.h"

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
    __weak typeof(self) weakSelf = self;
    return [self.sessionManager dataTaskWithRequest:self.URLRequest
                                     uploadProgress:nil
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
    
    // `self` maybe dealloc when execute success callback, hold queue and success
    dispatch_queue_t queue = self.request.completionQueue ?: dispatch_get_main_queue();
    void (^success)(id<PDNetworkResponse>) = self.responser.responseHandler;
    
    dispatch_async(queue, ^{
        !success ?: success(response);
    });
}

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
        id<PDNetworkResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = self.request.sessionTask.response;
        response.data = PDNTValueToJSONObject(responseObject);
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishLoad:self.request withResponse:response];
        
        !self.responser.responseHandler ?: self.responser.responseHandler(response);
        [self.request unbindResponser];
        !self.doneHandler ?: self.doneHandler(!!(responseObject && !error), error);
    });
}

- (PDNetworkDataResponser *)responser {
    return (PDNetworkDataResponser *)self.request.responser;
}

@end
