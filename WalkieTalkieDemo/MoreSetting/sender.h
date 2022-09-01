//
//  sender.h
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/31.
//

#ifndef sender_h
#define sender_h
@protocol sender <NSObject>

-(void)send:(NSMutableDictionary*) data;

@end

#endif /* sender_h */
