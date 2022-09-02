//
//  ViewController.h
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/15.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIFeedbackGenerator.h>
#import <AVFoundation/AVFoundation.h>
#import "ToolKit/UIScreen.h"
#import "MoreSetting/IPSettingVC.h"
#import "MoreSetting/IPSetting.h"

@import SYAlertController;
@import CocoaAsyncSocket;

@interface ViewController : UIViewController <AVAudioPlayerDelegate, GCDAsyncUdpSocketDelegate>

@end

