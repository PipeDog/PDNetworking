//
//  PDNetworkPluginManager.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "PDNetworkPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDNetworkPluginNotify <PDNetworkPlugin>

@end

@interface PDNetworkPluginManager : NSObject <PDNetworkPluginNotify>

@property (class, strong, readonly) PDNetworkPluginManager *defaultManager;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id<PDNetworkPlugin>> *pluginMap;
@property (nonatomic, copy, readonly) NSArray<id<PDNetworkPlugin>> *plugins;

@end

NS_ASSUME_NONNULL_END
