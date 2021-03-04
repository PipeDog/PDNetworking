//
//  PDNetworkRequestDefines.h
//  PDNetworking
//
//  Created by liang on 2019/6/26.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef PDNetworkRequestDefines_h
#define PDNetworkRequestDefines_h

FOUNDATION_EXPORT NSTimeInterval const PDNetworkRequestTimeoutInterval;
FOUNDATION_EXPORT NSUInteger const PDNetworkRequestAutoRetryTimes;

typedef NS_ENUM(NSUInteger, PDNetworkRequestMethod) {
    PDNetworkRequestMethodGET     = 0,
    PDNetworkRequestMethodPOST    = 1,
    PDNetworkRequestMethodHEAD    = 2,
    PDNetworkRequestMethodPUT     = 3,
    PDNetworkRequestMethodDELETE  = 4,
    PDNetworkRequestMethodPATCH   = 5,
};

static inline NSString *PDNetworkRequestGetMethodName(PDNetworkRequestMethod method) {
    switch (method) {
        case PDNetworkRequestMethodGET:     return @"GET";
        case PDNetworkRequestMethodPOST:    return @"POST";
        case PDNetworkRequestMethodHEAD:    return @"HEAD";
        case PDNetworkRequestMethodPUT:     return @"PUT";
        case PDNetworkRequestMethodDELETE:  return @"DELETE";
        case PDNetworkRequestMethodPATCH:   return @"PATCH";
        default: return nil;
    }
}

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

#endif /* PDNetworkRequestDefines_h */
