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
#import "PDNetworkDefaultCache.h"
#import "PDNetworkDataUtil.h"
#import "PDNetworkRequestExecutor.h"
#import "PDNetworkRequestDownloadExecutor.h"
#import "PDNetworkRequestUploadExecutor.h"
#import "PDNetworkRequestRegularExecutor.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface PDNetworkManager ()

@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) NSMutableDictionary<PDNetworkRequestID, PDNetworkRequest *> *requestMap;
@property (nonatomic, strong) NSMutableDictionary<PDNetworkRequestID, PDNetworkRequestExecutor *> *executorMap;

@end

@implementation PDNetworkManager

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
        _requestMap = [NSMutableDictionary dictionary];
        _executorMap = [NSMutableDictionary dictionary];
        _sessionManager = [AFHTTPSessionManager manager];
        
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:@"com.pd-network.cache"];
        _networkCache = [[PDNetworkDefaultCache alloc] initWithPath:path];

        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = NO;
        securityPolicy.validatesDomainName = NO;
        _sessionManager.securityPolicy = securityPolicy;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return self;
}

#pragma mark - Public Methods
- (void)addRequest:(PDNetworkRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return;
    }
    
    // Custom session task
    if (request.customSessionTask) {
        NSURLSessionTask *sessionTask = request.customSessionTask();
        request.sessionTask = sessionTask;
        [sessionTask resume];
        return;
    }
    
    Lock();
    PDNetworkRequestExecutor *executor = self.executorMap[request.requestID];
    Unlock();
    
    if (executor) { [executor cancel]; }
    
    executor = [self executorForRequest:request];
    if (!executor) { return; }
    
    Lock();
    self.requestMap[request.requestID] = request;
    self.executorMap[request.requestID] = executor;
    Unlock();
    
    [[PDNetworkPluginManager defaultManager] requestWillStartLoad:request];
    
    __weak typeof(self) weakSelf = self;
    [executor executeWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
        Lock();
        [weakSelf.requestMap removeObjectForKey:request.requestID];
        [weakSelf.executorMap removeObjectForKey:request.requestID];
        Unlock();
    }];
}

- (void)cancelRequestsWithFilter:(BOOL (^)(PDNetworkRequest * _Nonnull))filter {
    NSAssert(filter, @"The argument `filter` can not be nil!");
    if (!filter) { return; }
    
    NSDictionary<NSString *, PDNetworkRequest *> *requestMap = [_requestMap copy];
    [requestMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, PDNetworkRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        if (filter(obj)) {
            [obj cancel];
        }
    }];
}

- (void)cancelRequest:(PDNetworkRequest *)request {
    Lock();
    PDNetworkRequestExecutor *executor = self.executorMap[request.requestID];
    [self.requestMap removeObjectForKey:request.requestID];
    [self.executorMap removeObjectForKey:request.requestID];
    Unlock();
    
    [executor cancel];
}

- (void)cancelAllRequests {
    NSDictionary<NSString *, PDNetworkRequest *> *requests = [_requestMap copy];
    [requests enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, PDNetworkRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

#pragma mark - Private Methods
- (PDNetworkRequestExecutor *)executorForRequest:(PDNetworkRequest *)request {
    Class executorClass = nil;
    
    switch (request.actionType) {
        case PDNetworkRequestActionRegular: executorClass = [PDNetworkRequestRegularExecutor class]; break;
        case PDNetworkRequestActionUpload: executorClass = [PDNetworkRequestUploadExecutor class]; break;
        case PDNetworkRequestActionDownload: executorClass = [PDNetworkRequestDownloadExecutor class]; break;
    }
    
    return [[executorClass alloc] initWithRequest:request sessionManager:self.sessionManager];
}

#pragma mark - Setter Methods
- (void)setNetworkCache:(id<PDNetworkCache>)networkCache {
    Lock();
    _networkCache = networkCache;
    Unlock();
}

@end
