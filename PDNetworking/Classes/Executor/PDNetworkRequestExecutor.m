//
//  PDNetworkRequestExecutor.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkRequestExecutor.h"
#import "PDNetworkRequest.h"
#import "NSString+PDNetworking.h"
#import "PDNetworkRequest+Internal.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

@implementation PDNetworkRequestExecutor {
    NSThread *_executeThread;
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
        
        // Append full url
        NSString *url = _request.baseUrl;
        if (_request.urlPath.length > 0) {
            url = [url stringByAppendingString:_request.urlPath];
        }
        if (![NSURL URLWithString:url]) {
            url = [url encodeWithURLQueryAllowedCharacterSet];
        }
        _fullRequestURL = url;
              
        // Create request cache id
        NSString *requestCacheID = [_fullRequestURL copy];
        requestCacheID = [requestCacheID urlStringWithParameters:_request.parameters];
        _requestCacheID = [requestCacheID encodeWithURLQueryAllowedCharacterSet];
        
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
        
        switch (_request.actionType) {
            case PDNetworkRequestActionRegular: {
                _URLRequest = [requestSerializer requestWithMethod:method URLString:url parameters:parameters error:&outError];
            } break;
            case PDNetworkRequestActionDownload: {
                _URLRequest = [requestSerializer requestWithMethod:method URLString:url parameters:parameters error:&outError];
            } break;
            case PDNetworkRequestActionUpload: {
                void (^constructingBody)(id<AFMultipartFormData>) = (void (^)(id<AFMultipartFormData>))request.constructingBody;
                _URLRequest = [requestSerializer multipartFormRequestWithMethod:method URLString:url parameters:parameters constructingBodyWithBlock:constructingBody error:&outError];
            } break;
            default: break;
        }

        NSAssert(_URLRequest || !outError, @"Build `URLRequest` failed!");
        
        // Bind request with sessionTask
        _request.sessionTask = [self sessionTask];
        NSAssert(_request.sessionTask, @"Create `sessionTask` failed!");
    }
    return self;
}

- (void)executeWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    _executeThread = [NSThread currentThread];
    
    self.doneHandler = [doneHandler copy];
    self.currentRetryTimes = 0;
    [self.request.sessionTask resume];
}

- (void)cancel {
    /* Notify request then unbind
     * -cancel returns immediately, but marks a task as being canceled.
     * The task will signal -URLSession:task:didCompleteWithError: with an
     * error value of { NSURLErrorDomain, NSURLErrorCancelled }.  In some
     * cases, the task may signal other work before it acknowledges the
     * cancelation.  -cancel may be sent to a task that has been suspended.
     */
    [self.request.sessionTask cancel];
    self.request.sessionTask = nil;
    self->_request = nil;
    
    // Notify request manager
    NSError *outError = [NSError errorWithDomain:@"PDNetworkDomain" code:-1000 userInfo:nil];
    !self.doneHandler ?: self.doneHandler(NO, outError);
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

@end
