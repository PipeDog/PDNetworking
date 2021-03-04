//
//  PDNetworkDefaultCache.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "PDNetworkCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkDefaultCache : NSObject <PDNetworkCache>

@property (nonatomic, copy, readonly) NSString *path;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
