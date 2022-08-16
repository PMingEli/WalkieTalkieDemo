//
//  ViewController.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/15.
//

#import "ViewController.h"
#import <SpeechRecognizerButton/SpeechRecognizerButton.h>
@import SpeechRecognizerButton;

@interface ViewController ()

@property(nonatomic,assign)CFAbsoluteTime touchTime;
@property(nonatomic,assign)CFAbsoluteTime startTime;

@property UIImageView* playImageV;
@property (nonatomic, strong) UIButton* button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self createUI];
}

- (void)createUI {
    
    _button = [[UIButton alloc] init];
    [_button setFrame:CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height-200, 100, 50)];
    [_button setTitle:@"按住说话" forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //    [_button setBackgroundColor:[UIColor grayColor]];
    [_button addTarget:self action:@selector(btnTouchDownClick:) forControlEvents:UIControlEventTouchDown];
    [_button addTarget:self action:@selector(btnTouchUpClick:) forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchUpOutside)];
    [_button.layer setCornerRadius:10.0];
    [_button.layer setMasksToBounds:YES];
    [_button.layer setBorderWidth:2];
    [self.view addSubview:_button];
    
    _playImageV = [[UIImageView alloc] init];
    _playImageV.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height-350, 100, 100);
    [self.view addSubview:_playImageV];
    
    // 创建图片集
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:0];
    
    for (NSInteger index = 0; index < 5; index++) {
        NSString *image_name = [NSString stringWithFormat:@"yuyin_%ld.jpg", (long)index];
        UIImage *tempImage = [UIImage imageNamed:image_name];
        // 添加图片
        [imageArray addObject:tempImage];
    }
    
    // 播放图片集
    // 设置播放的图片集（需将图片添加到数组 imageArray 中）
    _playImageV.animationImages = imageArray;
    // 设置播放整个图片集的时间
    _playImageV.animationDuration = 0.8;
    // 设置循环播放次数，默认为 0 一直循环
    _playImageV.animationRepeatCount = 0;
    
}

#pragma mark - 按钮事件

// 按钮按下事件
- (void)btnTouchDownClick:(UIButton *)sender
{
    // 开始播放
    [_playImageV startAnimating];
    NSLog(@"按钮按下事件");
    _startTime = CFAbsoluteTimeGetCurrent();
    //TODO:收集音频
}

// 按钮抬起事件
- (void)btnTouchUpClick:(UIButton *)sender
{
    // 停止播放动画
    [_playImageV stopAnimating];
    NSLog(@"按钮抬起事件");
    _touchTime = CFAbsoluteTimeGetCurrent()-_startTime;
    if(_touchTime<0.5){
        [self showToast:@"说话时间太短"];
        return;
    }
    //TODO:发送音频
}

- (void)showToast:(NSString *) msg {
    //初始化弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    NSLog(@"subviews:%@",alert.view.subviews);
//    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
//    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    //弹出提示框
    [self presentViewController:alert animated:true completion:^{
        [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
    }];
}

- (void)dismissAlertController {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}


@end
