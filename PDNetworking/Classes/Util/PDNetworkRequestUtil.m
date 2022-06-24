//
//  PDNetworkRequestUtil.m
//  PDNetworking
//
//  Created by liang on 2022/6/24.
//

#import "PDNetworkRequestUtil.h"
#import "PDNetworkRequest.h"
#import "NSString+PDNetworking.h"

@implementation PDNetworkRequestUtil

+ (NSString *)getCacheIDForRequest:(PDNetworkRequest *)request {
    if (request == nil) {
        return @"";
    }
    
    NSString *fullUrl = request.baseUrl;
    if (request.urlPath.length > 0) {
        fullUrl = [fullUrl stringByAppendingString:request.urlPath];
    }

    NSString *parametersString = [self convertMap2String:request.parameters];
    fullUrl = [fullUrl stringByAppendingFormat:@"&params=%@", parametersString];
    
    NSString *headersString = [self convertMap2String:request.requestHeaders];
    fullUrl = [fullUrl stringByAppendingFormat:@"&headers=%@", headersString];
    
    NSString *cacheID = [fullUrl pdnt_encodeWithURLQueryAllowedCharacterSet];
    return cacheID;
}

+ (NSString *)convertMap2String:(NSDictionary *)map {
    if (map == nil) {
        return @"";
    }
    
    // Sorted keys (increases the cache hit ratio)
    NSArray *allKeys = map.allKeys;
    NSArray *sortedKeys = [allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        NSString *key1 = [obj1 isKindOfClass:[NSString class]] ? obj1 : [obj1 description];
        NSString *key2 = [obj2 isKindOfClass:[NSString class]] ? obj2 : [obj2 description];
        return [key1 compare:key2];
    }];
    
    // Append query items
    NSMutableArray *stringPairs = [NSMutableArray array];
    [sortedKeys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = map[key];
        NSString *finalValue = [value isKindOfClass:[NSString class]] ? value : [value description];
        // Replace `?` and `=` with UTF-8
        finalValue = [finalValue stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
        finalValue = [finalValue stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
        NSString *pair = [NSString stringWithFormat:@"%@=%@",
                          [key isKindOfClass:[NSString class]] ? key : [key description],
                          finalValue];
        [stringPairs addObject:pair];
    }];
    
    // Query string joined by `&`
    NSString *stringParams = [stringPairs componentsJoinedByString:@"&"];
    return stringParams;
}

@end
