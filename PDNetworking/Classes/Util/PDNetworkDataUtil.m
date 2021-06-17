//
//  PDNetworkDataUtil.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkDataUtil.h"

id PDNTValueToJSONObject(id value) {
    if (!value || [value isKindOfClass:[NSNull class]]) {
        return nil;
    }

    // NSString, NSNumber, NSArray, NSDictionary, or NSNull
    if ([NSJSONSerialization isValidJSONObject:value]) {
        return value;
    }
    
    if ([value isKindOfClass:[NSData class]]) {
        NSJSONReadingOptions options = (NSJSONReadingMutableContainers |
                                        NSJSONReadingMutableLeaves |
                                        NSJSONReadingAllowFragments);
        id JSONObject = [NSJSONSerialization JSONObjectWithData:value options:options  error:nil];
        return JSONObject;
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSJSONReadingOptions options = (NSJSONReadingMutableContainers |
                                        NSJSONReadingMutableLeaves |
                                        NSJSONReadingAllowFragments);
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
        return JSONObject;
    }
    
    NSCAssert(NO, @"Invalid `value` type : %@", [value class]);
    return nil;
}

NSData *PDNTValueToData(id value) {
    if (!value || [value isKindOfClass:[NSNull class]]) {
        return nil;
    }

    if ([value isKindOfClass:[NSData class]]) {
        NSData *data = value;
        return data;
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        return data;
    }
        
    // NSString, NSNumber, NSArray, NSDictionary, or NSNull
    if ([NSJSONSerialization isValidJSONObject:value]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
        return data;
    }
    
    NSCAssert(NO, @"Invalid `value` type : %@", [value class]);
    return nil;
}

NSString *PDNTValueToJSONText(id value) {
    NSData *JSONData = PDNTValueToData(value);
    NSString *JSONText = JSONData ? [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] : nil;
    return JSONText;
}
