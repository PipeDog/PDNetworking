//
//  PDNetworkDefinition.m
//  Pods
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkDefinition.h"

NSTimeInterval const PDNetworkRequestDefaultTimeoutInterval = 30.f;
NSUInteger const PDNetworkRequestDefaultAutoRetryTimes = 0;
NSUInteger const PDNetworkDefaultMaxConcurrentRequestCount = 3;

NSString *PDNetworkRequestGetMethodName(PDNetworkRequestMethod method) {
    switch (method) {
        case PDNetworkRequestMethodGET:     return @"GET";
        case PDNetworkRequestMethodPOST:    return @"POST";
        case PDNetworkRequestMethodHEAD:    return @"HEAD";
        case PDNetworkRequestMethodPUT:     return @"PUT";
        case PDNetworkRequestMethodDELETE:  return @"DELETE";
        case PDNetworkRequestMethodPATCH:   return @"PATCH";
        default: {
            NSCAssert(NO, @"Unsupport request method!");
            return @"GET";
        }
    }
}
