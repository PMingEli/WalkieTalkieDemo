//
//  IPSetting.h
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPSetting : NSObject

@property (nonatomic, strong)NSString* targetIP;
@property (nonatomic, strong)NSString* localPort;
@property (nonatomic, strong)NSString* remotePort;

+ (instancetype)sharedInstance;


@end

NS_ASSUME_NONNULL_END
