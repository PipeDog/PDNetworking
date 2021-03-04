//
//  PDNetworkRequestExecutor.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDNetworkRequest;
@class AFHTTPRequestSerializer, AFHTTPResponseSerializer, AFHTTPSessionManager;

@interface PDNetworkRequestExecutor : NSObject

@property (nonatomic, weak, readonly) PDNetworkRequest *request;
@property (nonatomic, weak, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic, copy, readonly) NSString *fullRequestURL;
@property (nonatomic, copy, readonly) NSString *requestCacheID;
@property (nonatomic, strong, readonly) NSURLRequest *URLRequest;
@property (nonatomic, strong, readonly) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong, readonly) AFHTTPResponseSerializer *responseSerializer;
@property (nonatomic, copy) void (^doneHandler)(BOOL, NSError *);
@property (nonatomic, assign) NSUInteger currentRetryTimes;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - External Methods
- (instancetype _Nullable)initWithRequest:(PDNetworkRequest *)request
                           sessionManager:(AFHTTPSessionManager *)sessionManager NS_DESIGNATED_INITIALIZER;

- (void)executeWithDoneHandler:(void (^)(BOOL success, NSError * _Nullable error))doneHandler;
- (void)cancel;

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask;
- (id)parseResponseData:(id _Nullable)responseData outError:(NSError ** _Nullable)outError;

@end

NS_ASSUME_NONNULL_END
