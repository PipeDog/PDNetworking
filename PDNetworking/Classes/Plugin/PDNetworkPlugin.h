//
//  PDNetworkPlugin.h
//  PDNetworking
//
//  Created by liang on 2020/3/30.
//  Copyright © 2020 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDNetworkRequest.h"
#import "PDNetworkResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    const char *pluginname;
    const char *classname;
} PDNetworkPluginName;

#define __PD_EXPORT_NETWORK_PLUGIN_EX(pluginname, classname)    \
__attribute__((used, section("__DATA , _pd_netplugins")))       \
static const PDNetworkPluginName __PD_exp_networkplugin_##pluginname##__ = {#pluginname, #classname}

#define PD_EXPORT_NETWORK_PLUGIN(pluginname, classname) __PD_EXPORT_NETWORK_PLUGIN_EX(pluginname, classname))

typedef NSInteger PDNetworkPluginPriority NS_TYPED_EXTENSIBLE_ENUM;

@protocol PDNetworkPlugin <NSObject>

@optional
- (PDNetworkPluginPriority)priority;

- (void)requestWillStartLoad:(PDNetworkRequest *)request;
- (void)requestDidFinishLoad:(PDNetworkRequest *)request withResponse:(id<PDNetworkResponse>)response;
- (void)requestDidFinishUpload:(PDNetworkRequest *)request withResponse:(id<PDNetworkUploadResponse>)response;
- (void)requestDidFinishDownload:(PDNetworkRequest *)request withResponse:(id<PDNetworkDownloadResponse>)response;

@end

NS_ASSUME_NONNULL_END
