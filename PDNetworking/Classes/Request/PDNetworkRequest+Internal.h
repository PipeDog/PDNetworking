//
//  PDNetworkRequest+Internal.h
//  PDNetworking
//
//  Created by liang on 2020/3/27.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PDNetworkRequestType) {
    PDNetworkRequestTypeData        = 0,
    PDNetworkRequestTypeDownload    = 1,
    PDNetworkRequestTypeUpload      = 2,
};

@interface PDNetworkRequest ()

@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;
@property (nonatomic, assign) PDNetworkRequestType requestType;
@property (nonatomic, strong, nullable) PDNetworkResponser *responser;

- (void)unbindResponser;

@end

NS_ASSUME_NONNULL_END
