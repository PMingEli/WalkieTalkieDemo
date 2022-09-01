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

static id _instance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    @synchronized (self) {
        if(_instance == nil){
            _instance = [super allocWithZone: zone];
        }
    }
    return _instance;
}

+ (instancetype)sharedInstance{
    @synchronized(self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _instance;
}

@end
