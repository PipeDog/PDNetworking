//
//  PDNetworkDataUtil.m
//  PDNetworking
//
//  Created by liang on 2021/3/4.
//

#import "PDNetworkDataUtil.h"

id PDNKValueToJSONObject(id value) {
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
    
    NSString *fmt = [NSString stringWithFormat:@"Invalid `value` type : %@", [value class]];
    NSCAssert(NO, fmt);
    return nil;
}

NSData *PDNKValueToData(id value) {
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
    
    NSString *fmt = [NSString stringWithFormat:@"Invalid `value` type : %@", [value class]];
    NSCAssert(NO, fmt);
    return nil;
}

NSString *PDNKValueToJSONText(id value) {
    NSData *JSONData = PDNKValueToData(value);
    NSString *JSONText = JSONData ? [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] : nil;
    return JSONText;
}
