//
//  NSString+PDNetworking.m
//  PDNetworking
//
//  Created by liang on 2020/3/30.
//  Copyright © 2020 liang. All rights reserved.
//

#import "NSString+PDNetworking.h"

@implementation NSString (PDNetworking)

- (NSString *)pdnt_encodeWithURLQueryAllowedCharacterSet {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
