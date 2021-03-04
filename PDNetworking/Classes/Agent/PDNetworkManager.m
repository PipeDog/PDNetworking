//
//  PDNetworkManager.m
//  PDNetworking
//
//  Created by liang on 2019/6/26.
//  Copyright © 2019 liang. All rights reserved.
//

#import "PDNetworkManager.h"
#import "PDNetworkManager+Internal.h"
#import "NSString+PDNetworking.h"
#import "PDNetworkRequest.h"
#import "PDNetworkRequest+Internal.h"
#import "PDNetworkPluginManager.h"
#import "PDNetworkResponse.h"
#import "PDNetworkRequestVisitor.h"
#import "PDNetworkDefaultCache.h"
#import "PDNetworkDataUtil.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

static inline NSString *Hash(id<NSObject> object) {
    NSString *key;
    if ([object respondsToSelector:@selector(hash)]) {
        key = [NSString stringWithFormat:@"%lu", (unsigned long)[object hash]];
    }
    return key;
}

@implementation PDNetworkManager {
    dispatch_semaphore_t _lock;
    NSMutableDictionary<NSString *, __kindof PDNetworkRequest *> *_requests;
}

static PDNetworkManager *__defaultManager;

+ (PDNetworkManager *)defaultManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__defaultManager == nil) {
            __defaultManager = [[self alloc] init];
        }
    });
    return __defaultManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    @synchronized (self) {
        if (__defaultManager == nil) {
            __defaultManager = [super allocWithZone:zone];
        }
    }
    return __defaultManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _requests = [NSMutableDictionary dictionary];
        _sessionManager = [AFHTTPSessionManager manager];
        
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:@"com.pd-network.cache"];
        _cache = [[PDNetworkDefaultCache alloc] initWithPath:path];

        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = NO;
        securityPolicy.validatesDomainName = NO;
        _sessionManager.securityPolicy = securityPolicy;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return self;
}

#pragma mark - Public Methods
- (void)addRequest:(__kindof PDNetworkRequest *)request {
    [request setNeedsUpdate];
    
    // Custom session task
    if (request.customSessionTask) {
        NSURLSessionTask *sessionTask = request.customSessionTask();
        request.sessionTask = sessionTask;
        [sessionTask resume];
        return;
    }
    
    [[PDNetworkPluginManager defaultManager] requestWillStartLoad:request];
    
    // Handle cache if needed
    if (![request.visitor shouldContinueRequestingAfterHandleCache]) {
        return;
    }

    NSError *error;
    request.sessionTask = [self _sessionTaskForRequest:request error:&error];
    NSAssert(!error, @"Build session task error");
    
    [request.sessionTask resume];
    [self _addRequest:request];
}

- (void)cancelRequestsWithFilter:(BOOL (^)(__kindof PDNetworkRequest * _Nonnull))filter {
    NSAssert(filter, @"The argument `filter` can not be nil!");
    if (!filter) { return; }
    
    NSDictionary<NSString *, __kindof PDNetworkRequest *> *requests = [_requests copy];
    [requests enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof PDNetworkRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        if (filter(obj)) {
            [obj cancel];
        }
    }];
}

- (void)cancelRequest:(__kindof PDNetworkRequest *)request {
    [request.sessionTask cancel];
    [request clearRequestBlocks];
    
    [self _removeRequest:request];
}

- (void)cancelAllRequests {
    NSDictionary<NSString *, __kindof PDNetworkRequest *> *requests = [_requests copy];
    [requests enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof PDNetworkRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

#pragma mark - Hold Request
- (void)_addRequest:(__kindof PDNetworkRequest *)request {
    NSString *key = Hash(request.sessionTask);
    
    if (key.length) {
        Lock();
        _requests[key] = request;
        Unlock();
    }
}

- (void)_removeRequest:(__kindof PDNetworkRequest *)request {
    NSString *key = Hash(request.sessionTask);

    if (key.length) {
        Lock();
        [_requests removeObjectForKey:key];
        Unlock();
    }
}

#pragma mark - DataTask Creation Methods
- (NSURLSessionTask *)_sessionTaskForRequest:(PDNetworkRequest *)request error:(NSError * __autoreleasing *)outError {
    switch (request.action) {
        case PDNetworkRequestActionDownload: return [self _downloadTaskForRequest:request error:outError];
        case PDNetworkRequestActionUpload: return [self _uploadTaskForRequest:request error:outError];
        default: return [self _dataTaskForRequest:request error:outError];
    }
}

- (NSURLSessionDataTask *)_dataTaskForRequest:(PDNetworkRequest *)request error:(NSError * __autoreleasing *)outError {
    NSString *URLString = request.visitor.URLString;
    NSDictionary *parameters = request.parameters;
    AFHTTPRequestSerializer *requestSerializer = request.visitor.requestSerializer;
    NSString *method = PDNetworkRequestGetMethodName(request.requestMethod);
    NSMutableURLRequest *URLRequest = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:outError];

    NSURLSessionDataTask *dataTask = [_sessionManager dataTaskWithRequest:URLRequest
                                                             uploadProgress:nil
                                                           downloadProgress:nil
                                                        completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        id serializedData = [self _serializeResponseByMetaData:responseObject forRequest:request];
        [self _handleNormalRequestResult:request responseObject:serializedData error:error];
    }];
    return dataTask;
}

- (NSURLSessionDataTask *)_uploadTaskForRequest:(PDNetworkRequest *)request error:(NSError * __autoreleasing *)outError {
    NSString *URLString = request.visitor.URLString;
    NSDictionary *parameters = request.parameters;
    NSString *method = PDNetworkRequestGetMethodName(PDNetworkRequestMethodPOST);
    AFHTTPRequestSerializer *requestSerializer = request.visitor.requestSerializer;

    void (^constructingBody)(id<AFMultipartFormData>) = (void (^)(id<AFMultipartFormData>))request.constructingBody;
    NSMutableURLRequest *URLRequest = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:constructingBody error:outError];
    NSURLSessionDataTask *uploadTask = [_sessionManager dataTaskWithRequest:URLRequest
                                                             uploadProgress:request.uploadProgress
                                                           downloadProgress:nil
                                                          completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        id serializedData = [self _serializeResponseByMetaData:responseObject forRequest:request];
        [self _handleUploadRequestResult:request responseObject:serializedData error:error];
    }];
    return uploadTask;
}

- (NSURLSessionDownloadTask *)_downloadTaskForRequest:(PDNetworkRequest *)request error:(NSError * __autoreleasing *)outError {
    AFHTTPRequestSerializer *requestSerializer = request.visitor.requestSerializer;
    NSString *URLString = request.visitor.URLString;
    NSDictionary *parameters = request.parameters;
    NSString *method = PDNetworkRequestGetMethodName(PDNetworkRequestMethodGET);
    
    NSMutableURLRequest *URLRequest = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:outError];
    NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:URLRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            !request.downloadProgress ?: request.downloadProgress(downloadProgress);
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return request.destination(targetPath, response);
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [self _handleDownloadRequestResult:request filePath:filePath error:error];
    }];
    return downloadTask;
}

#pragma mark - Response Methods
- (void)_handleNormalRequestResult:(PDNetworkRequest *)request
                    responseObject:(id)responseObject
                             error:(NSError *)error {
    
    void (^finishedHandler)(void) = ^{
        request.currentRetryTimes = 0;

        id<PDNetworkResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = request.sessionTask.response;
        response.data = PDNKValueToJSONObject(responseObject);
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishLoad:request withResponse:response];

        dispatch_async(request.completionQueue ?: dispatch_get_main_queue(), ^{
            if (!error) {
                !request.success ?: request.success(response);
                
                // Sync cache data
                PDNetworkRequestVisitor *visitor = request.visitor;
                [visitor setCacheData:responseObject];
            } else {
                !request.failure ?: request.failure(response);
            }
            
            [self _removeRequest:request];
        });
    };
    
    // The request returns without retrying
    if (!error) {
        finishedHandler();
        return;
    }
    
    // Auto retry
    if (request.currentRetryTimes < request.autoRetryTimes) {
        request.currentRetryTimes += 1;
        [self _removeRequest:request];
        [self addRequest:request];
        return;
    }
    
    // Retry the end
    finishedHandler();
}

- (void)_handleDownloadRequestResult:(PDNetworkRequest *)request
                            filePath:(NSURL *)filePath
                               error:(NSError *)error {
    void (^finishedHandler)(void) = ^{
        request.currentRetryTimes = 0;

        id<PDNetworkDownloadResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = request.sessionTask.response;
        response.filePath = filePath;
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishDownload:request withResponse:response];
        
        dispatch_async(request.completionQueue ?: dispatch_get_main_queue(), ^{
            if (!error) {
                !request.downloadSuccess ?: request.downloadSuccess(response);
            } else {
                !request.downloadFailure ?: request.downloadFailure(response);
            }
            
            [self _removeRequest:request];
        });
    };
    
    // The request returns without retrying
    if (!error) {
        finishedHandler();
        return;
    }
    
    // Auto retry
    if (request.currentRetryTimes < request.autoRetryTimes) {
        request.currentRetryTimes += 1;
        [self _removeRequest:request];
        [self addRequest:request];
        return;
    }
    
    // Retry the end
    finishedHandler();
}

- (void)_handleUploadRequestResult:(PDNetworkRequest *)request
                    responseObject:(id)responseObject
                             error:(NSError *)error {
    void (^finishedHandler)(void) = ^{
        request.currentRetryTimes = 0;

        id<PDNetworkUploadResponse> response = [[PDNetworkResponse alloc] init];
        response.URLResponse = request.sessionTask.response;
        response.data = PDNKValueToJSONObject(responseObject);
        response.error = error;
        [[PDNetworkPluginManager defaultManager] requestDidFinishUpload:request withResponse:response];
        
        dispatch_async(request.completionQueue ?: dispatch_get_main_queue(), ^{
            if (!error) {
                !request.uploadSuccess ?: request.uploadSuccess(response);
            } else {
                !request.uploadFailure ?: request.uploadFailure(response);
            }
            
            [self _removeRequest:request];
        });
    };
    
    // The request returns without retrying
    if (!error) {
        finishedHandler();
        return;
    }
    
    // Auto retry
    if (request.currentRetryTimes < request.autoRetryTimes) {
        request.currentRetryTimes += 1;
        [self _removeRequest:request];
        [self addRequest:request];
        return;
    }
    
    // Retry the end
    finishedHandler();
}

#pragma mark - Serialize Response Method
- (id)_serializeResponseByMetaData:(id)metaData forRequest:(PDNetworkRequest *)request {
    // sessionManager's responseSerializer default is kind of class `AFHTTPResponseSerializer`, and do not need to repeat serialization
    if (request.serializerType == PDNetworkRequestSerializerTypeHTTP) {
        return metaData;
    }

    AFHTTPResponseSerializer *serializer = request.visitor.responseSerializer;
    NSURLResponse *response = request.sessionTask.response;
    
    NSError *error;
    id data = [serializer responseObjectForResponse:response data:metaData error:&error];
    NSAssert(!error, @"Parse data failed!");
    return data;
}

#pragma mark - Setter Methods
- (void)setCache:(id<PDNetworkCache>)cache {
    Lock();
    _cache = cache;
    Unlock();
}

@end
