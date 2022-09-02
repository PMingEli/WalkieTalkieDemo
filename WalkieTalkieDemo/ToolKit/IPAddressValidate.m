//
//  IPAddressValidate.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/9/2.
//

#import "IPAddressValidate.h"

@implementation IPAddressValidate

+ (instancetype)sharedInstance{
    static IPAddressValidate *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        if(instance == nil){
            instance = [[IPAddressValidate alloc] init];
        }
    });
    return instance;
}

-(BOOL)isIPV4Validate:(NSString *)str
{
    NSString *regex = @"^(?:(?:1[0-9][0-9]\.)|(?:2[0-4][0-9]\.)|(?:25[0-5]\.)|(?:[1-9][0-9]\.)|(?:[0-9]\.)){3}(?:(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])|(?:[1-9][0-9])|(?:[0-9]))$";
    NSPredicate *ipv4Regx = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [ipv4Regx evaluateWithObject:str];
}

@end
