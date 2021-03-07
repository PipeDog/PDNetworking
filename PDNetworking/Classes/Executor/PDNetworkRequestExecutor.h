//
//  PDNetworkRequestExecutor.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "PDNetworkResponse.h"
#import "PDNetworkDataUtil.h"
#import "PDNetworkRequest+Internal.h"
#import "PDNetworkPluginManager.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkRequestExecutor : NSObject

@property (nonatomic, strong, readonly) PDNetworkRequest *request;
@property (nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong, readonly) NSString *requestCacheID;
@property (nonatomic, strong, readonly) NSURLRequest *URLRequest;
@property (nonatomic, strong, readonly) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong, readonly) AFHTTPResponseSerializer *responseSerializer;
@property (nonatomic, copy, readonly) void (^doneHandler)(BOOL, NSError *);
@property (nonatomic, assign) NSUInteger currentRetryTimes;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - External Methods
+ (Class _Nullable)executorClassWithRequestType:(PDNetworkRequestType)requestType;

- (instancetype _Nullable)initWithRequest:(PDNetworkRequest *)request
                           sessionManager:(AFHTTPSessionManager *)sessionManager NS_DESIGNATED_INITIALIZER;

- (void)executeWithDoneHandler:(void (^)(BOOL success, NSError * _Nullable error))doneHandler;
- (void)cancel;
- (BOOL)isCancelled;

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask;
- (id)parseResponseData:(id _Nullable)responseData outError:(NSError ** _Nullable)outError;

- (void)lock;
- (void)unlock;

@end

NS_ASSUME_NONNULL_END
