//
//  PDNetworkDataUtil.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN id _Nullable PDNKValueToJSONObject(id value);
FOUNDATION_EXTERN NSData * _Nullable PDNKValueToData(id value);
FOUNDATION_EXTERN NSString * _Nullable PDNKValueToJSONText(id value);

NS_ASSUME_NONNULL_END
