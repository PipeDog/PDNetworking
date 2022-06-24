//
//  PDNetworkRequestUtil.h
//  PDNetworking
//
//  Created by liang on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDNetworkRequest;

@interface PDNetworkRequestUtil : NSObject

+ (NSString *)getCacheIDForRequest:(PDNetworkRequest *)request;

@end

NS_ASSUME_NONNULL_END
