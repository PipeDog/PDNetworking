//
//  PDNetworkDefaultCache.m
//  PDNetworking
//
//  Created by 雷亮 on 2021/3/4.
//

#import "PDNetworkDefaultCache.h"
#import "YYDiskCache.h"
#import "PDNetworkDataUtil.h"

@implementation PDNetworkDefaultCache {
    YYDiskCache *_diskCache;
}

@synthesize path = _path;

- (instancetype)initWithPath:(NSString *)path {
    NSAssert(path.length > 0, @"The argument `path` can not be nil!");
    if (!path.length) { return nil; }
    
    self = [super init];
    if (self) {
        _path = [path copy];

        [self setupInitializeConfiguration];
    }
    return self;
}

- (void)setupInitializeConfiguration {
    [self _createPathIfNecessary:_path error:NULL];

    _diskCache = [[YYDiskCache alloc] initWithPath:_path];
    
    _diskCache.customArchiveBlock = ^NSData * _Nonnull(id  _Nonnull object) {
        return PDNKValueToData(object);
    };
    
    _diskCache.customUnarchiveBlock = ^id _Nonnull(NSData * _Nonnull data) {
        return PDNKValueToJSONObject(data);
    };
}

#pragma mark - Private Methods
- (BOOL)_createPathIfNecessary:(NSString *)path error:(NSError * __autoreleasing *)error {
    BOOL result = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:path]) {
        result = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
    }
    return result;
}

#pragma mark - NENetworkCache
- (BOOL)containsObjectForKey:(NSString *)key {
    return [_diskCache containsObjectForKey:key];
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, BOOL))block {
    [_diskCache containsObjectForKey:key withBlock:block];
}

- (id)objectForKey:(NSString *)key {
    return [_diskCache objectForKey:key];
}

- (void)objectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, id _Nullable))block {
    [_diskCache objectForKey:key withBlock:block];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    [_diskCache setObject:object forKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key withBlock:(void (^)(void))block {
    [_diskCache setObject:object forKey:key withBlock:block];
}

- (void)removeObjectForKey:(NSString *)key {
    [_diskCache removeObjectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull))block {
    [_diskCache removeObjectForKey:key withBlock:block];
}

- (void)removeAllObjects {
    [_diskCache removeAllObjects];
}

- (void)removeAllObjectsWithBlock:(void (^)(void))block {
    [_diskCache removeAllObjectsWithBlock:block];
}

@end
