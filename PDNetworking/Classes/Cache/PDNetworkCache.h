//
//  PDNetworkCache.h
//  PDNetworking
//
//  Created by liang on 2020/4/24.
//  Copyright © 2020 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDNetworkCache <NSObject>

- (BOOL)containsObjectForKey:(NSString *)key;
- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

- (id _Nullable)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key withBlock:(void (^)(NSString *key, id _Nullable object))block;

- (void)setObject:(id _Nullable)object forKey:(NSString *)key;
- (void)setObject:(id _Nullable)object forKey:(NSString *)key withBlock:(void (^ _Nullable)(void))block;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key withBlock:(void (^ _Nullable)(NSString *key))block;

- (void)removeAllObjects;
- (void)removeAllObjectsWithBlock:(void (^ _Nullable)(void))block;

@end

NS_ASSUME_NONNULL_END
