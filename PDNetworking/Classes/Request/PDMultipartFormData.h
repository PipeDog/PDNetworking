//
//  PDMultipartFormData.h
//  PDNetworking
//
//  Created by liang on 2021/6/18.
//

#import <Foundation/Foundation.h>

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol PDMultipartFormData <AFMultipartFormData>

@end

NS_ASSUME_NONNULL_END
