//
//  PDNetworkPluginManager.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkPluginManager.h"
#import <dlfcn.h>
#import <mach-o/getsect.h>

@implementation PDNetworkPluginManager

static PDNetworkPluginManager *__defaultManager;

+ (PDNetworkPluginManager *)defaultManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__defaultManager == nil) {
            __defaultManager = [[self alloc] init];
        }
    });
    return __defaultManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    @synchronized (self) {
        if (__defaultManager == nil) {
            __defaultManager = [super allocWithZone:zone];
        }
    }
    return __defaultManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadPlugins];
    }
    return self;
}

- (void)loadPlugins {
    NSMutableArray<id<PDNetworkPlugin>> *plugins = [NSMutableArray array];
    NSMutableDictionary<NSString *, id<PDNetworkPlugin>> *pluginMap = [NSMutableDictionary dictionary];

    Dl_info info; dladdr(&__defaultManager, &info);
    
#ifdef __LP64__
    uint64_t addr = 0; const uint64_t mach_header = (uint64_t)info.dli_fbase;
    const struct section_64 *section = getsectbynamefromheader_64((void *)mach_header, "__DATA", "_pd_netplugins");
#else
    uint32_t addr = 0; const uint32_t mach_header = (uint32_t)info.dli_fbase;
    const struct section *section = getsectbynamefromheader((void *)mach_header, "__DATA", "_pd_netplugins");
#endif
    
    if (section == NULL) { return; }
    
    for (addr = section->offset; addr < section->offset + section->size; addr += sizeof(PDNetworkPluginName)) {
        PDNetworkPluginName *name = (PDNetworkPluginName *)(mach_header + addr);
        if (!name) { continue; }
                
        NSString *pluginname = [NSString stringWithUTF8String:name->pluginname];
        NSString *classname = [NSString stringWithUTF8String:name->classname];
        
        if (pluginMap[pluginname]) {
            continue;
        }
        
        Class pluginClass = NSClassFromString(classname);
        id<PDNetworkPlugin> plugin = [[pluginClass alloc] init];
        pluginMap[pluginname] = plugin;
        [plugins addObject:plugin];
    }
    
    // sort by priority
    [plugins sortUsingComparator:^NSComparisonResult(id<PDNetworkPlugin> obj1, id<PDNetworkPlugin> obj2) {
        return obj1.priority < obj2.priority ? NSOrderedDescending : NSOrderedAscending;
    }];
    
    _plugins = [plugins copy];
    _pluginMap = [pluginMap copy];
}

#pragma mark - PDNetworkPluginNotify
- (void)requestWillStartLoad:(PDNetworkRequest *)request {
    for (id<PDNetworkPlugin> plugin in _plugins) {
        if ([plugin respondsToSelector:@selector(requestWillStartLoad:)]) {
            [plugin requestWillStartLoad:request];
        }
    }
}

- (void)requestDidFinishLoad:(PDNetworkRequest *)request withResponse:(id<PDNetworkResponse>)response {
    for (id<PDNetworkPlugin> plugin in _plugins) {
        if ([plugin respondsToSelector:@selector(requestDidFinishLoad:withResponse:)]) {
            [plugin requestDidFinishLoad:request withResponse:response];
        }
    }
}

- (void)requestDidFinishUpload:(PDNetworkRequest *)request withResponse:(id<PDNetworkUploadResponse>)response {
    for (id<PDNetworkPlugin> plugin in _plugins) {
        if ([plugin respondsToSelector:@selector(requestDidFinishUpload:withResponse:)]) {
            [plugin requestDidFinishUpload:request withResponse:response];
        }
    }
}

- (void)requestDidFinishDownload:(PDNetworkRequest *)request withResponse:(id<PDNetworkDownloadResponse>)response {
    for (id<PDNetworkPlugin> plugin in _plugins) {
        if ([plugin respondsToSelector:@selector(requestDidFinishDownload:withResponse:)]) {
            [plugin requestDidFinishDownload:request withResponse:response];
        }
    }
}

@end
