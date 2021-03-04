//
//  PDNetworkRequestVisitor.m
//  PDNetworking
//
//  Created by liang on 2020/3/27.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDNetworkRequestVisitor.h"
#import "PDNetworkRequest+Internal.h"
#import "NSString+PDNetworking.h"
#import "PDNetworkManager+Internal.h"

static inline AFJSONResponseSerializer *_PDJSONResponseSerializer(void) {
    static AFJSONResponseSerializer *_JSONResponseSerializer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _JSONResponseSerializer = [AFJSONResponseSerializer serializer];
    });
    return _JSONResponseSerializer;
}

static inline AFHTTPResponseSerializer *_PDHTTPResponseSerializer(void) {
    static AFHTTPResponseSerializer *_HTTPResponseSerializer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _HTTPResponseSerializer = [AFHTTPResponseSerializer serializer];
    });
    return _HTTPResponseSerializer;
}

@interface PDNetworkRequestVisitor ()

@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, strong) NSString *cacheKey;

@end

@implementation PDNetworkRequestVisitor {
    __weak PDNetworkRequest *_request;
}

- (instancetype)init {
    NSAssert(NO, @"You should call method `initWithRequest:`!");
    PDNetworkRequest *request;
    return [self initWithRequest:request];
}

- (instancetype)initWithRequest:(PDNetworkRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}

- (BOOL)shouldContinueRequestingAfterHandleCache {
    if (_request.action != PDNetworkRequestActionRegular) {
        return YES;
    }

    PDNetworkRequest *request = _request;
    
    void (^cacheHandler)(id _Nullable) = ^ (id _Nullable data) {
        id<PDNetworkResponse> response = [[PDNetworkResponse alloc] init];
        response.data = data;
        
        dispatch_async(request.completionQueue ?: dispatch_get_main_queue(), ^{
            !request.success ?: request.success(response);
        });
    };
    
    BOOL shouldContinueRequesting = YES;

    switch (_request.cachePolicy) {
        case PDNetworkRequestReloadIgnoringCacheData: {
            // Do nothing about cache.
        } break;
        case PDNetworkRequestReturnCacheDataThenLoad: {
            id cachedData = [self cachedData];
            cacheHandler(cachedData);
        } break;
        case PDNetworkRequestReturnCacheDataElseLoad: {
            id cachedData = [self cachedData];
            if (cachedData) {
                cacheHandler(cachedData);
                shouldContinueRequesting = NO;
            }
        } break;
        case PDNetworkRequestReturnCacheDataDontLoad: {
            id cachedData = [self cachedData];
            cacheHandler(cachedData);
            shouldContinueRequesting = NO;
        } break;
        default: break;
    }
    
    return shouldContinueRequesting;
}

- (id)cachedData {
    if (_request.action != PDNetworkRequestActionRegular) { return nil; }
    if (_request.cachePolicy == PDNetworkRequestReloadIgnoringCacheData) { return nil; }

    id<PDNetworkCache> cache = [PDNetworkManager defaultManager].cache;
    
    // Get cached data in subthread, but sync execute
    __block id cachedData = nil;
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    
    [cache objectForKey:self.cacheKey withBlock:^(NSString * _Nonnull key, id  _Nullable object) {
        cachedData = object;
        dispatch_semaphore_signal(lock);
    }];

    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    return cachedData;
}

- (void)setCacheData:(id)cacheData {
    if (_request.action != PDNetworkRequestActionRegular) { return; }
    if (_request.cachePolicy == PDNetworkRequestReloadIgnoringCacheData) { return; }

    id<PDNetworkCache> cache = [PDNetworkManager defaultManager].cache;
    [cache setObject:cacheData forKey:self.cacheKey withBlock:^{
        // Sync cache finished...
    }];
}

#pragma mark - Getter Methods
- (AFHTTPRequestSerializer *)requestSerializer {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (_request.serializerType == PDNetworkRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    } else { // HTTP or default
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }

    requestSerializer.timeoutInterval = _request.timeoutInterval;

    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *requestHeaders = [_request.requestHeaders copy];
    if (requestHeaders != nil) {
        for (NSString *httpHeaderField in requestHeaders.allKeys) {
            NSString *value = requestHeaders[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    return requestSerializer;
}

- (AFHTTPResponseSerializer *)responseSerializer {
    switch (_request.serializerType) {
        case PDNetworkRequestSerializerTypeJSON: return _PDJSONResponseSerializer();
        default: return _PDHTTPResponseSerializer(); // HTTP or default
    }
}

- (NSString *)URLString {
    if (!_URLString) {
        NSString *URLString = _request.baseUrl;
        
        if (_request.urlPath.length > 0) {
            URLString = [URLString stringByAppendingString:_request.urlPath];
        }
        if (![NSURL URLWithString:URLString]) {
            URLString = [URLString encodeWithURLQueryAllowedCharacterSet];
        }
        
        _URLString = URLString;
    }
    return _URLString;
}

- (NSString *)cacheKey {
    if (!_cacheKey) {
        NSString *URLString = self.URLString;
        NSString *fullURLString = [URLString urlStringWithParameters:_request.parameters];
        _cacheKey = [fullURLString encodeWithURLQueryAllowedCharacterSet];
    }
    return _cacheKey;
}

@end
