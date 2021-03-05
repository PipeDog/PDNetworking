//
//  PDNetworkUUID.h
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDNetworkUUID : NSObject

@property (readonly, copy) NSString *UUIDString;

+ (instancetype)UUID;
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
