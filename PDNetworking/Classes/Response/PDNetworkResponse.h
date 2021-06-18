//
//  PDNetworkResponse.h
//  PDNetworking
//
//  Created by liang on 2020/3/27.
//  Copyright © 2020 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDNetworkResponse <NSObject>

@property (nonatomic, strong, nullable) NSURLResponse *URLResponse;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSError *error;

@end

@protocol PDNetworkUploadResponse <NSObject>

@property (nonatomic, strong, nullable) NSURLResponse *URLResponse;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSError *error;

@end

@protocol PDNetworkDownloadResponse <NSObject>

@property (nonatomic, strong, nullable) NSURLResponse *URLResponse;
@property (nonatomic, strong, nullable) NSURL *filePath;
@property (nonatomic, strong, nullable) NSError *error;

@end

@interface PDNetworkResponse : NSObject <PDNetworkResponse, PDNetworkUploadResponse, PDNetworkDownloadResponse>

@end

NS_ASSUME_NONNULL_END
