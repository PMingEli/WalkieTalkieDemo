//
//  IPAddressValidate.h
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/9/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPAddressValidate : NSObject

+ (instancetype)sharedInstance;
- (BOOL)isIPV4Validate:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
