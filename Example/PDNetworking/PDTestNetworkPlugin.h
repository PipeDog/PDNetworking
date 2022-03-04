//
//  PDTestNetworkPlugin.h
//  PDNetworking_Example
//
//  Created by liang on 2022/3/4.
//  Copyright © 2022 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PDNetworkPlugin.h>

NS_ASSUME_NONNULL_BEGIN

PD_EXPORT_NETWORK_PLUGIN(testPlugin, PDTestNetworkPlugin)

@interface PDTestNetworkPlugin : NSObject <PDNetworkPlugin>

@end

NS_ASSUME_NONNULL_END
