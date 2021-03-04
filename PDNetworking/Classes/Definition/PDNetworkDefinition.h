//
//  PDNetworkDefinition.h
//  Pods
//
//  Created by 雷亮 on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSTimeInterval const PDNetworkRequestDefaultTimeoutInterval;
FOUNDATION_EXPORT NSUInteger const PDNetworkRequestDefaultAutoRetryTimes;

typedef NS_ENUM(NSUInteger, PDNetworkRequestMethod) {
    PDNetworkRequestMethodGET     = 0,
    PDNetworkRequestMethodPOST    = 1,
    PDNetworkRequestMethodHEAD    = 2,
    PDNetworkRequestMethodPUT     = 3,
    PDNetworkRequestMethodDELETE  = 4,
    PDNetworkRequestMethodPATCH   = 5,
};

typedef NS_ENUM(NSUInteger, PDNetworkRequestSerializerType) {
    PDNetworkRequestSerializerTypeHTTP = 0,
    PDNetworkRequestSerializerTypeJSON = 1,
};

typedef NS_ENUM(NSUInteger, PDNetworkRequestCachePolicy) {
    PDNetworkRequestReloadIgnoringCacheData = 0,
    PDNetworkRequestReturnCacheDataThenLoad = 1,
    PDNetworkRequestReturnCacheDataElseLoad = 2,
    PDNetworkRequestReturnCacheDataDontLoad = 3,
};

FOUNDATION_EXPORT NSString *PDNetworkRequestGetMethodName(PDNetworkRequestMethod method);

NS_ASSUME_NONNULL_END
