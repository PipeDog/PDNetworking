//
//  PDNetworkPluginManager.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "PDNetworkPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDNetworkPluginNotify <NSObject>

- (void)requestWillStartLoad:(PDNetworkRequest *)request;
- (void)requestDidFinishLoad:(PDNetworkRequest *)request withResponse:(id<PDNetworkResponse>)response;
- (void)requestDidFinishUpload:(PDNetworkRequest *)request withResponse:(id<PDNetworkUploadResponse>)response;
- (void)requestDidFinishDownload:(PDNetworkRequest *)request withResponse:(id<PDNetworkDownloadResponse>)response;

@end

@interface PDNetworkPluginManager : NSObject <PDNetworkPluginNotify>

@property (class, strong, readonly) PDNetworkPluginManager *defaultManager;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id<PDNetworkPlugin>> *pluginMap;
@property (nonatomic, copy, readonly) NSArray<id<PDNetworkPlugin>> *plugins;

@end

NS_ASSUME_NONNULL_END
