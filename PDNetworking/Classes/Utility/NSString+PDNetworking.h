//
//  NSString+PDNetworking.h
//  PDNetworking
//
//  Created by liang on 2020/3/30.
//  Copyright © 2020 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (PDNetworking)

- (NSString *)urlStringWithParameters:(NSDictionary *)parameters;
- (NSString *)encodeWithURLQueryAllowedCharacterSet;

@end

NS_ASSUME_NONNULL_END
