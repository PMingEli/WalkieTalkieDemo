//
//  DeviceIPAddress.h
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/9/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceIPAddress : NSObject

@property (nonatomic, strong) NSString* ipAdderss;
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
