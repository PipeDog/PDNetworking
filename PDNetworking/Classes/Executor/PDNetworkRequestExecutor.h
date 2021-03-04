//
//  PDNetworkRequestExecutor.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDNetworkRequest;
@class AFHTTPRequestSerializer, AFHTTPResponseSerializer;

@interface PDNetworkRequestExecutor : NSObject

@property (nonatomic, weak, readonly) PDNetworkRequest *request;
@property (nonatomic, copy, readonly) NSString *fullRequestURL;
@property (nonatomic, copy, readonly) NSString *requestCacheID;
@property (nonatomic, strong, readonly) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong, readonly) AFHTTPResponseSerializer *responseSerializer;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRequest:(PDNetworkRequest *)request NS_DESIGNATED_INITIALIZER;

- (void)executeWithDoneHandler:(void (^)(BOOL success, NSError * _Nullable error))doneHandler;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
