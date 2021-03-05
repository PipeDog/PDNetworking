//
//  NSString+PDNetworking.m
//  PDNetworking
//
//  Created by liang on 2020/3/30.
//  Copyright © 2020 liang. All rights reserved.
//

#import "NSString+PDNetworking.h"

@implementation NSString (PDNetworking)

- (NSString *)pdnt_urlStringWithParameters:(NSDictionary *)parameters {
    if (!parameters.allKeys.count) {
        return self;
    }
    
    // Sorted keys (increases the cache hit ratio)
    NSArray *allKeys = parameters.allKeys;
    NSArray *sortedKeys = [allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        NSString *key1 = [obj1 isKindOfClass:[NSString class]] ? obj1 : [obj1 description];
        NSString *key2 = [obj2 isKindOfClass:[NSString class]] ? obj2 : [obj2 description];
        return [key1 compare:key2];
    }];
    
    // Append query items
    NSMutableArray *stringPairs = [NSMutableArray array];
    [sortedKeys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = parameters[key];
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
    
    // Join path with query
    if ([self rangeOfString:@"?"].location == NSNotFound) {
        return [self stringByAppendingFormat:@"?%@", stringParams];
    } else {
        return [self stringByAppendingFormat:@"&%@", stringParams];
    }
}

- (NSString *)pdnt_encodeWithURLQueryAllowedCharacterSet {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
