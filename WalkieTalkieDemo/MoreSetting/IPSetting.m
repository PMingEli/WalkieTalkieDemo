//
//  IPSetting.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/31.
//

#import "IPSetting.h"
@interface IPSetting()

@end

@implementation IPSetting

+ (instancetype)sharedInstance{
    static IPSetting *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        if(instance == nil){
            instance = [[IPSetting alloc] init];
        }
    });
    return instance;
}

@end
