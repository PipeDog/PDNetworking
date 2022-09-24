//
//  PDNetworkRequestExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestExecutor.h"
#import "NSString+PDNetworking.h"
#import "PDNetworkRequestGenericExecutor.h"
#import "PDNetworkRequestUploadExecutor.h"
#import "PDNetworkRequestDownloadExecutor.h"
#import "PDNetworkRequestUtil.h"

@implementation PDNetworkRequestExecutor {
    NSRecursiveLock *_lock;
    BOOL _isCancelled;
}

+ (Class)executorClassWithRequestType:(PDNetworkRequestType)requestType {
    switch (requestType) {
        case PDNetworkRequestTypeGeneric: return [PDNetworkRequestGenericExecutor class];
        case PDNetworkRequestTypeUpload: return [PDNetworkRequestUploadExecutor class];
        case PDNetworkRequestTypeDownload: return [PDNetworkRequestDownloadExecutor class];
        default: return nil;
    }
}

- (instancetype)initWithRequest:(PDNetworkRequest *)request
                 sessionManager:(AFHTTPSessionManager *)sessionManager {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return nil;
    }
    
    self = [super init];
    if (self) {
        _request = request;
        _sessionManager = sessionManager;
        _lock = [[NSRecursiveLock alloc] init];
        _isCancelled = NO;
        
        // Append full url
        NSString *fullUrl = _request.baseUrl;
        if (_request.urlPath.length > 0) {
            fullUrl = [fullUrl stringByAppendingString:_request.urlPath];
        }
        if (![NSURL URLWithString:fullUrl]) {
            fullUrl = [fullUrl pdnt_encodeWithURLQueryAllowedCharacterSet];
        }
              
        // Create request cache id
        _requestCacheID = [PDNetworkRequestUtil getCacheIDForRequest:request];
        
        // Request serializer
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        if (_request.serializerType == PDNetworkRequestSerializerTypeJSON) {
            requestSerializer = [AFJSONRequestSerializer serializer];
        }
        requestSerializer.timeoutInterval = _request.timeoutInterval;

        NSDictionary<NSString *, NSString *> *requestHeaders = [_request.requestHeaders copy];
        for (NSString *httpHeaderField in requestHeaders.allKeys) {
            NSString *value = requestHeaders[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
        
        _requestSerializer = requestSerializer;
        
        // Response serializer
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        if (_request.serializerType == PDNetworkRequestSerializerTypeJSON) {
            responseSerializer = [AFJSONResponseSerializer serializer];
        }

        _responseSerializer = responseSerializer;
        
        // Build URLRequest
        NSError *outError = nil;
        NSString *method = PDNetworkRequestGetMethodName(request.requestMethod);
        NSDictionary *parameters = _request.parameters;
        
        switch (_request.requestType) {
            case PDNetworkRequestTypeGeneric: {
                _URLRequest = [requestSerializer requestWithMethod:method URLString:fullUrl parameters:parameters error:&outError];
            } break;
            case PDNetworkRequestTypeDownload: {
                _URLRequest = [requestSerializer requestWithMethod:method URLString:fullUrl parameters:parameters error:&outError];
            } break;
            case PDNetworkRequestTypeUpload: {
                void (^constructingBody)(id<AFMultipartFormData>) = (void (^)(id<AFMultipartFormData>))request.constructingBody;
                _URLRequest = [requestSerializer multipartFormRequestWithMethod:method URLString:fullUrl parameters:parameters constructingBodyWithBlock:constructingBody error:&outError];
            } break;
            default: break;
        }

        if (!_URLRequest || outError) {
            NSAssert(_URLRequest || !outError, @"Build `URLRequest` failed!");
            return nil;
        }
        
        // Bind request with sessionTask
        _request.sessionTask = [self sessionTask];
        
        if (!_request.sessionTask) {
            NSAssert(_request.sessionTask, @"Create `sessionTask` failed!");
            return nil;
        }
    }
    return self;
}

- (void)executeWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    [self lock];
    _doneHandler = [doneHandler copy];
    self.currentRetryTimes = 0;
    [self unlock];

    [self.request.sessionTask resume];
}

- (void)cancel {
    [self lock];
    _isCancelled = YES;
    [self unlock];
    
    /* Notify request then unbind
     * -cancel returns immediately, but marks a task as being canceled.
     * The task will signal -URLSession:task:didCompleteWithError: with an
     * error value of { NSURLErrorDomain, NSURLErrorCancelled }.  In some
     * cases, the task may signal other work before it acknowledges the
     * cancelation.  -cancel may be sent to a task that has been suspended.
     */
    [self.request.sessionTask cancel];
    
    // Notify request manager
    NSError *outError = [NSError errorWithDomain:@"PDNetworkDomain" code:-1000 userInfo:nil];
    !self.doneHandler ?: self.doneHandler(NO, outError);
}

- (BOOL)isCancelled {
    [self lock];
    BOOL isCancelled = _isCancelled;
    [self unlock];
    return isCancelled;
}

#pragma mark - Internal Methods
- (NSURLSessionTask *)sessionTask {
    NSAssert(NO, @"This method must be override!");
    return nil;
}

- (id)parseResponseData:(id)responseData outError:(NSError **)outError {
    if (self.request.serializerType == PDNetworkRequestSerializerTypeHTTP) {
        return responseData;
    }
    
    NSURLResponse *response = self.request.sessionTask.response;
    id data = [self.responseSerializer responseObjectForResponse:response data:responseData error:outError];
    NSAssert(data || !(*outError), @"Parse data failed!");
    return data;
}

- (void)lock {
    [self->_lock lock];
}

- (void)unlock {
    [self->_lock unlock];
}

@end
