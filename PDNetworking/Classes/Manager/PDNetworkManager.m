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
#import "PDNetworkBuiltinCache.h"
#import "PDNetworkDataUtil.h"
#import "PDNetworkRequestExecutor.h"
#import <pthread/pthread.h>

@interface PDNetworkManager ()

@property (nonatomic, assign) pthread_rwlock_t lock;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
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

- (void)dealloc {
    pthread_rwlock_destroy(&_lock);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_lock, NULL);
        _operationQueue = [[NSOperationQueue alloc] init];
        _requestMap = [NSMutableDictionary dictionary];
        _executorMap = [NSMutableDictionary dictionary];
        _sessionManager = [AFHTTPSessionManager manager];
        _networkCache = [[PDNetworkBuiltinCache alloc] init];
        _maxConcurrentRequestCount = PDNetworkDefaultMaxConcurrentRequestCount;

        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.allowInvalidCertificates = NO;
        securityPolicy.validatesDomainName = NO;
        _sessionManager.securityPolicy = securityPolicy;
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _operationQueue.maxConcurrentOperationCount = _maxConcurrentRequestCount;
    }
    return self;
}

#pragma mark - Public Methods
- (void)addRequest:(PDNetworkRequest *)request {
    [self.operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [self _addRequest:request];
    }]];
}

- (void)cancelRequest:(PDNetworkRequest *)request {
    [self.operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [self _cancelRequest:request];
    }]];
}

- (void)cancelRequestsWithFilter:(BOOL (^)(PDNetworkRequest * _Nonnull))filter {
    [self.operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [self _cancelRequestsWithFilter:filter];
    }]];
}

- (void)cancelAllRequests {
    [self.operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [self _cancelAllRequests];
    }]];
}

#pragma mark - Private Methods
- (void)_addRequest:(PDNetworkRequest *)request {
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
    
    pthread_rwlock_rdlock(&_lock);
    PDNetworkRequestExecutor *executor = self.executorMap[request.requestID];
    pthread_rwlock_unlock(&_lock);
    
    if (executor) { [executor cancel]; }
    
    Class executorClass = [PDNetworkRequestExecutor executorClassWithRequestType:request.requestType];
    executor = [[executorClass alloc] initWithRequest:request sessionManager:self.sessionManager];
    if (!executor) { return; }
    
    pthread_rwlock_wrlock(&_lock);
    self.requestMap[request.requestID] = request;
    self.executorMap[request.requestID] = executor;
    pthread_rwlock_unlock(&_lock);
    
    [[PDNetworkPluginManager defaultManager] requestWillStartLoad:request];
    
    [executor executeWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
        pthread_rwlock_wrlock(&(self->_lock));
        [self.requestMap removeObjectForKey:request.requestID];
        [self.executorMap removeObjectForKey:request.requestID];
        pthread_rwlock_unlock(&(self->_lock));
    }];
}

- (void)_cancelRequest:(PDNetworkRequest *)request {
    pthread_rwlock_wrlock(&_lock);
    PDNetworkRequestExecutor *executor = self.executorMap[request.requestID];
    [self.requestMap removeObjectForKey:request.requestID];
    [self.executorMap removeObjectForKey:request.requestID];
    pthread_rwlock_unlock(&_lock);
    
    [executor cancel];
}

- (void)_cancelRequestsWithFilter:(BOOL (^)(PDNetworkRequest * _Nonnull))filter {
    NSAssert(filter, @"The argument `filter` can not be nil!");
    if (!filter) { return; }
    
    pthread_rwlock_rdlock(&_lock);
    NSDictionary<NSString *, PDNetworkRequest *> *requestMap = [_requestMap copy];
    pthread_rwlock_unlock(&_lock);
    
    [requestMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, PDNetworkRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        if (filter(obj)) {
            [obj cancel];
        }
    }];
}

- (void)_cancelAllRequests {
    pthread_rwlock_rdlock(&_lock);
    NSDictionary<NSString *, PDNetworkRequest *> *requests = [_requestMap copy];
    pthread_rwlock_unlock(&_lock);
    
    [requests enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, PDNetworkRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

#pragma mark - Setter Methods
- (void)setNetworkCache:(id<PDNetworkCache>)networkCache {
    @synchronized (self) {
        _networkCache = networkCache;
    }
}

- (void)setMaxConcurrentRequestCount:(NSUInteger)maxConcurrentRequestCount {
    NSAssert(maxConcurrentRequestCount > 0 &&
             maxConcurrentRequestCount < 20,
             @"Invalid argument maxConcurrentRequestCount");
    
    @synchronized (self) {
        _maxConcurrentRequestCount = maxConcurrentRequestCount;
        self.operationQueue.maxConcurrentOperationCount = _maxConcurrentRequestCount;
    }
}

@end
