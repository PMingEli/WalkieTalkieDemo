//
//  ViewController.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/15.
//

#import "ViewController.h"
#import "UIColor+Hex/UIColor+Hex.h"


#define SCREEN_HEIGHT self.view.frame.size.height
#define SCREEN_WIDTH self.view.frame.size.width

@interface ViewController ()

@property(nonatomic,assign)CFAbsoluteTime touchTime;
@property(nonatomic,assign)CFAbsoluteTime startTime;

@property (nonatomic, strong)UIImageView* playImageV;
@property (nonatomic, strong)UIButton* button;
@property (nonatomic, strong)UIView* tabView;
@property (nonatomic, strong)UIButton* switchBtn;
@property (nonatomic, strong)UIButton* mojiBtn;
@property BOOL isTalk;
@property (nonatomic, strong)UITextField* inputMsg;
@property (nonatomic, strong)UIButton* inputVoice;
@property (nonatomic, strong)UIButton* playBtn;

//播放器
@property (nonatomic, strong) AVAudioPlayer *player;
//
@property (nonatomic, strong) AVAudioSession *session;
//录音
@property (nonatomic, strong) AVAudioRecorder *recorder;
//进度条
@property (nonatomic, strong) UIProgressView *progress;
//时间
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSMutableArray *meterTable;

@property (nonatomic) float mScaleFactor;

@property (nonatomic, strong) UIImpactFeedbackGenerator* impactHeavy;

@end

@implementation ViewController

@synthesize player = _player;
@synthesize session = _session;
@synthesize recorder = _recorder;
@synthesize progress = _progress;
@synthesize timer = _timer;
@synthesize meterTable = _meterTable;
@synthesize mScaleFactor = _mScaleFactor;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithHexString:@"#ededed"]];
    // Do any additional setup after loading the view.
    [self setUpAudioObjects];
    
    [self createUI];
    
}

- (void)setUpAudioObjects
{
    [self setUpMeterTable];
    [self setUpAudioSession];
    [self setUpRecorder];
    [self setUpProgress];
    
}

- (void)setUpMeterTable
{
    float inMinDecibels = -80.;
    float inRoot = 2.;
    double minAmp = pow(10., 0.05 * inMinDecibels);
    double ampRange = 1. - minAmp;
    double invAmpRange = 1. / ampRange;
    double rroot = 1. / inRoot;
    self.meterTable = [[NSMutableArray alloc] initWithCapacity:400];
    float mDecibelResolution = inMinDecibels/399;
    self.mScaleFactor = 1./mDecibelResolution;
    
    for (size_t i = 0; i < 400; ++i) {
        double decibels = i * mDecibelResolution;
        double amp = pow(10., 0.05 * decibels);
        double adjAmp = (amp - minAmp) * invAmpRange;
        [self.meterTable setObject:@(pow(adjAmp, rroot)) atIndexedSubscript:i];
    }
}

- (void)setUpAudioSession
{
    self.session = [AVAudioSession sharedInstance];
    
    [self.session setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    UInt32 doChangeDefaultRoute = 1;
    //设置扬声器播放，不然默认是听筒
    [self.session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    //    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
    //                             sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
    NSError* error;
    [self.session setPreferredIOBufferDuration:doChangeDefaultRoute error: &error];
}

- (void)setUpRecorder
{
    NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"]];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:fileURL
                                                settings:[self getRecordSettingsDictionary]
                                                   error:nil];
    self.recorder.meteringEnabled = YES;
}

- (void)setUpProgress
{
    self.progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.progress setFrame:CGRectMake(SCREEN_WIDTH/5, SCREEN_HEIGHT*2/5, SCREEN_WIDTH*0.6, 3)];
    self.progress.progressTintColor = [UIColor blueColor];
    [self.view addSubview:self.progress];
    self.progress.progress = 0;
    self.progress.hidden = YES;
}

- (NSDictionary *)getRecordSettingsDictionary
{
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    return @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
             AVSampleRateKey: @44100,
             AVNumberOfChannelsKey: @2,
             AVLinearPCMBitDepthKey:@32,
             AVEncoderAudioQualityKey:@(AVAudioQualityMax),
             AVEncoderBitRateKey: @128000,
             AVChannelLayoutKey: [NSData dataWithBytes:&channelLayout
                                                length:sizeof(AudioChannelLayout)]};
}

- (void)createUI {
    _isTalk = YES;
    
    _tabView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-60-44, SCREEN_WIDTH, 60)];
    [_tabView setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6"]];
    
    _button = [[UIButton alloc] init];
    //    UIEdgeInsets insets = self.view.safeAreaInsets;
    //    [_button setFrame:CGRectMake(insets.left+50, SCREEN_HEIGHT-insets.bottom-50-44, SCREEN_WIDTH-insets.left-insets.right-50, 50)];
    [_button setFrame:CGRectMake(50, 10, SCREEN_WIDTH-100, 40)];
    [_button setTitle:@"按住 说话" forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //    [_button setBackgroundColor:[UIColor grayColor]];
    [_button addTarget:self action:@selector(btnTouchDownClick:) forControlEvents:UIControlEventTouchDown];
    [_button addTarget:self action:@selector(btnTouchUpClick:) forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchUpOutside)];
    [_button.layer setCornerRadius:10.0];
    [_button.layer setMasksToBounds:YES];
    [_button setBackgroundColor:[UIColor whiteColor]];
    //    [_button.layer setBorderWidth:2];
    //    [self.view addSubview:_button];
    [_tabView addSubview:_button];
    
    _playImageV = [[UIImageView alloc] init];
    _playImageV.frame = CGRectMake(SCREEN_WIDTH/2-50, SCREEN_HEIGHT-350, 100, 100);
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
    
    _switchBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, 50, 50)];
    [_switchBtn setImage:[UIImage imageNamed:@"keyboard"] forState:UIControlStateNormal];
    [_switchBtn addTarget:self action:@selector(btnSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [_tabView addSubview:_switchBtn];
    
    _mojiBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-50, 5, 50, 50)];
    [_mojiBtn setImage:[UIImage imageNamed:@"moji"] forState:UIControlStateNormal];
    
    [_tabView addSubview:_mojiBtn];
    
    _inputMsg = [[UITextField alloc] initWithFrame:CGRectMake(50, 10, SCREEN_WIDTH-100, 40)];
    [_inputMsg.layer setCornerRadius:10.0];
    [_inputMsg setBackgroundColor:[UIColor whiteColor]];
    _inputMsg.hidden = YES;
    
    [_tabView addSubview:_inputMsg];
    
    //    [self.view addSubview:_tabView];
    
    self.inputVoice = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-50, SCREEN_HEIGHT*3/4, 100, 100)];
    [self.inputVoice setImage:[UIImage imageNamed:@"voiceInput"] forState:UIControlStateNormal];
    [self.inputVoice setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6"]];
    [self.inputVoice addTarget:self action:@selector(btnTouchDownClick:) forControlEvents:UIControlEventTouchDown];
    [self.inputVoice addTarget:self action:@selector(btnTouchUpClick:) forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchUpOutside)];
    //    self.inputVoice = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"voiceInput"] highlightedImage:[UIImage imageNamed:@"voiceInput_s"]];
    //    [self.inputVoice setFrame:CGRectMake(SCREEN_WIDTH/2-50, SCREEN_HEIGHT*3/4, 100, 100)];
    //    [self.inputVoice setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6"]];
    //    self.inputVoice.userInteractionEnabled = YES;
    //    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    //    [longPress setMinimumPressDuration:0];
    //    [self.inputVoice addGestureRecognizer:longPress];
    [self.inputVoice.layer setCornerRadius:50.0];
    [self.inputVoice.layer setBorderWidth:2];
    [self.inputVoice.layer setShadowOffset:CGSizeMake(1, 1)];
    [self.inputVoice.layer setShadowOpacity:0.8];
    [self.inputVoice.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.view addSubview:self.inputVoice];
    
    self.playBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-50, SCREEN_HEIGHT/4, 100, 50)];
    [self.playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [self.playBtn addTarget:self action:@selector(playButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.playBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.playBtn.layer setCornerRadius:10.0];
    [self.playBtn.layer setBorderWidth:2];
    [self.view addSubview:self.playBtn];
    
    self.impactHeavy = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    
    
}


#pragma mark- longPress(长按手势)
- (void)longPressAction:(UILongPressGestureRecognizer *)longPress{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        NSLog(@"检测到长按手势开始的时候执行");
        [self.inputVoice setHighlighted:YES];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_sync(queue, ^{
            //            [self.impactHeavy impactOccurredWithIntensity:1.0];
            //            [_impactHeavy prepare];
            [_impactHeavy impactOccurred];
            [self startRecording];
        });
    }
    else if (longPress.state == UIGestureRecognizerStateEnded) {
        [self.inputVoice setHighlighted:NO];
        NSLog(@"长按手势结束的时候执行");
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_sync(queue, ^{
            [self stopRecording];
            
            if(self.player.duration<1){
                [self showToast:@"说话时间太短"];
                self.player = nil;
                return;
            }
        });
    }
    //    NSLog(@"检测到了长按手势");
}


#pragma mark - 按钮事件
// 按钮按下事件
- (void)btnTouchDownClick:(UIButton *)sender
{
    [_impactHeavy prepare];
    [_impactHeavy impactOccurred];
    [self.inputVoice setImage:[UIImage imageNamed:@"voiceInput_s"] forState:UIControlStateHighlighted];
    [self.inputVoice setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6" alpha:0.6]];
    NSLog(@"按钮按下事件");
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_sync(queue, ^{
        [self startRecording];
    });
}

// 按钮抬起事件
- (void)btnTouchUpClick:(UIButton *)sender
{
    // 停止播放动画
    [self.inputVoice setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6"]];
    self.progress.progress=0;
    NSLog(@"按钮抬起事件");
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_sync(queue, ^{
        [self stopRecording];
        if(self.player.duration<1){
            [self showToast:@"说话时间太短"];
            self.player = nil;
            return;
        }
    });
    //TODO:发送音频
    
    
}

- (void)updateProgress:(NSTimer *)timer{
    NSTimeInterval duration = self.player.duration;
    NSTimeInterval currentTime = self.player.currentTime;
    [self.progress setProgress:(float)(currentTime/duration) animated:YES];
    NSLog(@"%f",(float)(currentTime/duration));
}

//播放完成时调用的方法  (代理里的方法),需要设置代理才可以调用
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.timer invalidate]; //NSTimer暂停   invalidate  使...无效;
    if(self.progress.progress<1){
        [self.progress setProgress:1.0 animated:YES];
    }
}

//播放按钮
- (void)playButtonPressed {
    NSLog(@"点击了播放按钮");
    self.progress.hidden = NO;
    self.progress.progress = 0;
    @try {
        if (!self.player.isPlaying && !self.recorder.isRecording) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(queue, ^{
                [self.session setActive:YES error:nil];
                [self.player prepareToPlay];
                [self.player setVolume:1.0f];
                [self.player play];
            });
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
        }
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    } @finally {
        [self.recorder deleteRecording];
        NSLog(@"录音删除成功");
    }
}

//开始录音
- (void)startRecording{
    self.progress.hidden = NO;
    if (self.player.isPlaying) {
        [self.player stop];
    }
    self.player = nil;
    [self.session setActive:YES error:nil];
    //准备录音，必须与record一对配合，不然会录不上
    [self.recorder prepareToRecord];
    //开启分贝监听
    self.recorder.meteringEnabled = YES;
    //定时获取分贝
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector: @selector(levelTimerCallback:) userInfo:nil repeats:YES];
    @try {
        if([self.recorder record]){
            NSLog(@"开始录制成功");
        }
    } @catch (NSException *exception) {
        NSLog(@"开始录制失败");
        NSLog(@"%@",exception);
    } @finally {
        
    }
}

//结束录音
- (void)stopRecording{
    [self.timer invalidate];
    [self.recorder stop];
    [self.session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"]];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    self.player.delegate = self;
    self.player.meteringEnabled = YES;
}

- (void)levelTimerCallback:(NSTimer *)timer{
    [self.recorder updateMeters];//刷新音量数据
    //获取分贝  基本在0-1之间 可能超过1
    CGFloat lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
    //分成10个等级
    self.progress.progress = lowPassResults;
}

// 切换按钮按下事件
- (void)btnSwitchClick:(UIButton *)sender
{
    // 切换键盘输入
    _isTalk = !_isTalk;
    if(_isTalk){
        [self textFieldDidBeginEditing:self.inputMsg];
        [_switchBtn setImage:[UIImage imageNamed:@"talk"]  forState:UIControlStateNormal];
        _button.hidden = YES;
        _inputMsg.hidden = NO;
    }
    else{
        [self textFieldDidEndEditing:self.inputMsg];
        [_switchBtn setImage:[UIImage imageNamed:@"keyboard"]  forState:UIControlStateNormal];
        _inputMsg.hidden = YES;
        _button.hidden = NO;
    }
    //TODO:
}

- (void)showToast:(NSString *) msg {
    //初始化弹窗
    SYAlertController *alert = [SYAlertController alertControllerWithTitle:@"" message:msg image:@"warning"];
    //    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    //    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:^{
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
    }];
}

- (void)dismissAlertController {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

//点击输入框界面跟随键盘上移
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    CGRect frame = _tabView.frame;
    int offSet = frame.origin.y+50 - (self.view.frame.size.height - 375.0);
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:0.5f];
    //将视图的Y坐标向上移动offset个单位，以使线面腾出开的地方用于软键盘的显示
    if (offSet > 0) {
        self.view.frame = CGRectMake(0.0f, -offSet, self.view.frame.size.width, self.view.frame.size.height);
        [UIView commitAnimations];
    }
}

//输入框编辑完成以后，将视图恢复到原始状态

-(void)textFieldDidEndEditing:(UITextField *)textField {
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}



@end
