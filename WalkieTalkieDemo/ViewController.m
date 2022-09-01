//
//  ViewController.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/15.
//

#import "ViewController.h"
#import "UIColor+Hex/UIColor+Hex.h"
#import "MoreSetting/IPSettingVC.h"

#import <SystemConfiguration/CaptiveNetwork.h>
@import SBWatcher;


#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/sockio.h>
#import <sys/ioctl.h>
//
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
#define maxData 9206




@interface ViewController ()

@property (nonatomic, strong)UIButton* inputVoice;
@property (nonatomic, strong)UIButton* playBtn;
@property (nonatomic, strong)UIButton* moreBtn;
//@property (nonatomic, strong)UITextField* deviceIP;
@property (nonatomic, strong)UILabel* deviceIP;
@property (nonatomic, strong)NSString* targetIP;
@property (nonatomic, strong)NSString* localPort;
@property (nonatomic, strong)NSString* remotePort;

//主页
//@property (nonatomic) MainView* mainView;
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

@property (nonatomic, strong) UIImpactFeedbackGenerator* impactHeavy;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

@property (nonatomic, strong) NSMutableDictionary* remoteData;

@end

@implementation ViewController

@synthesize player = _player;
@synthesize session = _session;
@synthesize recorder = _recorder;
@synthesize progress = _progress;
@synthesize timer = _timer;

- (void)viewDidLoad {
    [super viewDidLoad];
    //注册观察者
    [[SBWatcherManager shareManager] registWatcher];
    
    [self.view setBackgroundColor:[UIColor colorWithHexString:@"#ededed"]];
    // Do any additional setup after loading the view.
    [self setUpAudioObjects];
    
    [self createUI];
    
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(IPSettingChanged) name:@"IPSettingChanged" object:nil];
}

- (void)setUpAudioObjects
{
    [self setUpAudioSession];
    [self setUpRecorder];
    [self setUpProgress];
    
}

-(void) IPSettingChanged{
    IPSetting* ip = [IPSetting sharedInstance];
    self.targetIP = ip.targetIP;
    self.localPort = ip.localPort;
    self.remotePort = ip.remotePort;
    NSLog(@"targetIP:%@",self.targetIP);
    
    NSError * error = nil;
    [self.udpSocket bindToPort:[self.localPort integerValue] error:&error];
    if (error) {//监听错误打印错误信息
        NSLog(@"error:%@",error);
    }else {//监听成功则开始接收信息
        NSLog(@"接收数据");
        [self.udpSocket beginReceiving:&error];
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
    //    NSString *wavRecordFilePath = [NSTemporaryDirectory()stringByAppendingPathComponent:@"WAVtemporaryRadio.wav"];
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
    //    AudioChannelLayout channelLayout;
    //    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    //    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    return @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
             AVSampleRateKey: @44100,
             AVNumberOfChannelsKey: @1,
             AVLinearPCMBitDepthKey:@8,
             AVEncoderAudioQualityKey:@(AVAudioQualityLow),
             AVEncoderBitRateKey: @128000,
             //             AVChannelLayoutKey: [NSData dataWithBytes:&channelLayout
             //                                                length:sizeof(AudioChannelLayout)]
    };
    //    return @{ AVSampleRateKey        : @8000.0,                      // 采样率
    //              AVFormatIDKey          : @(kAudioFormatLinearPCM),     // 音频格式
    //              AVLinearPCMBitDepthKey : @16,                          // 采样位数 默认 16
    //              AVNumberOfChannelsKey  : @1                            // 通道的数目
    //    };
}

- (void)createUI {
    
    self.inputVoice = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-50, SCREEN_HEIGHT*3/4-50, 100, 100)];
    [self.inputVoice setImage:[UIImage imageNamed:@"voiceInput"] forState:UIControlStateNormal];
    [self.inputVoice setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6"]];
    [self.inputVoice addTarget:self action:@selector(btnTouchDownClick:) forControlEvents:UIControlEventTouchDown];
    [self.inputVoice addTarget:self action:@selector(btnTouchUpClick:) forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchUpOutside)];
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
    
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoSetting)];
    self.navigationItem.rightBarButtonItem = item;
    
    NSString* ip = [self getIPAddress:YES];
    
    self.deviceIP = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/5, SCREEN_HEIGHT-37-50, SCREEN_WIDTH*3/5, 50)];
    [self.view addSubview:self.deviceIP];
    self.deviceIP.font = [UIFont systemFontOfSize:20];
    self.deviceIP.textAlignment = NSTextAlignmentCenter;
    self.deviceIP.enabled = NO;
    self.deviceIP.text = [@"本机IP：" stringByAppendingString:ip];
    
    self.impactHeavy = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    
    
}


#pragma mark - 按钮事件
// 按钮按下事件
- (void)btnTouchDownClick:(UIButton *)sender
{
    NSArray* files = [self allFilesAtPath:NSTemporaryDirectory()];
    for(id file in files){
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    }
    [_impactHeavy prepare];
    [_impactHeavy impactOccurred];
    [self.inputVoice setImage:[UIImage imageNamed:@"voiceInput_s"] forState:UIControlStateHighlighted];
    [self.inputVoice setBackgroundColor:[UIColor colorWithHexString:@"#f6f6f6" alpha:0.6]];
    //    [self.mainView inputVoiceSelected];
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
    //    [self.mainView inputVoiceUnselected];
    //    self.mainView.progress.progress = 0;
    NSLog(@"按钮抬起事件");
    [self stopRecording];
    if(self.player.duration<1){
        [self showToast:@"说话时间太短"];
        self.player = nil;
        return;
    }
    //    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    //    dispatch_sync(queue, ^{
    //        [self stopRecording];
    //        if(self.player.duration<1){
    //            [self showToast:@"说话时间太短"];
    //            self.player = nil;
    //            return;
    //        }
    //    });
    //TODO:发送音频
    //暂存录音文件路径
    //    NSString *wavRecordFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WAVtemporaryRadio.wav"];
    //    NSString *amrRecordFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"AMRtemporaryRadio.amr"];
    
    //重点:把wav录音文件转换成amr文件,用于网络传输.amr文件大小是wav文件的十分之一左右
    //    [EMVoiceConverter wavToAmr:wavRecordFilePath amrSavePath:amrRecordFilePath];
    //wave_file_to_amr_file([wavRecordFilePath cStringUsingEncoding:NSUTF8StringEncoding],[amrRecordFilePath cStringUsingEncoding:NSUTF8StringEncoding], 1, 16);
    
    //返回amr音频文件Data,用于传输或存储
    //    NSData *cacheAudioData = [NSData dataWithContentsOfFile:amrRecordFilePath];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_sync(queue, ^{
        NSURL* fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"]];
        NSLog(@"fileURL:%@",fileURL);
        NSData* audioData = [NSData dataWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"]];
        NSData* testData = [@"testtest" dataUsingEncoding:NSUTF8StringEncoding];
        if([IPSetting sharedInstance].targetIP){
            if(audioData.length>maxData){
                [self sendAllData:audioData];
            }else{
                [self.udpSocket sendData:audioData toHost:self.targetIP port:[self.remotePort integerValue] withTimeout:-1 tag:0];
            }
        }else{
            NSLog(@"host为nil");
        }
    });
}

- (BOOL) sendAllData: (NSData *)data{
    unsigned long count = data.length / maxData;
    NSData *tmp = data;
    NSMutableData* startFlag;
    unsigned long len = 0;
    for(int i=0;i<=count;i++){
        len = i == count? data.length - i*maxData :maxData;
        tmp = [data subdataWithRange: NSMakeRange(i*maxData, len)];
        NSString* str = [self getMaxLength:[@"" stringByAppendingFormat:@"%d-%lu",i,count]];
        startFlag = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        [startFlag appendData:tmp];
        [self.udpSocket sendData:startFlag toHost:self.targetIP port:[self.remotePort integerValue] withTimeout:-1 tag:0];
    }
    return NO;
}

-(NSString *)getMaxLength:(NSString *)str{
    NSString *result = str;
    for(unsigned long i=str.length;i<10;i++){
        result = [result stringByAppendingString:@"a"];
    }
    NSLog(@"result: %@",result);
    return result;
}

- (void)updateProgress:(NSTimer *)timer{
    NSTimeInterval duration = self.player.duration;
    NSTimeInterval currentTime = self.player.currentTime;
    [self.progress setProgress:(float)(currentTime/duration) animated:YES];
    //    [self.mainView.progress setProgress:(float)(currentTime/duration) animated:YES];
    NSLog(@"%f",(float)(currentTime/duration));
}

//播放完成时调用的方法  (代理里的方法),需要设置代理才可以调用
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.timer invalidate]; //NSTimer暂停   invalidate  使...无效;
    if(self.progress.progress<1){
        [self.progress setProgress:1.0 animated:YES];
        //        [self.mainView.progress setProgress:1.0 animated:YES];
    }
}

//播放按钮
- (void)playButtonPressed {
    NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"]];
    //    NSString *wavRecordFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WAVtemporaryRadio.wav"];
    //    NSLog(@"文件大小: %@", [[[NSFileManager defaultManager] attributesOfItemAtPath:fileURL error:nil] objectForKey:NSFileSize]);
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (self.player == nil) {
        NSLog(@"AudioPlayer did not load properly: %@", [error description]);
    }
    self.player.delegate = self;
    self.player.meteringEnabled = YES;
    NSLog(@"点击了播放按钮");
    if(self.player!=nil){
        self.progress.hidden = NO;
        self.progress.progress = 0;
        //    self.mainView.progress.hidden = NO;
        //    [self.mainView.progress setProgress:0 animated:YES];
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
    }else{
        [self showToast:@"播放器初始化失败"];
    }
}

- (void) gotoSetting{
    IPSettingVC* ipsetting = [[IPSettingVC alloc] init];
    //    ipsetting.delegate = self;
    [self.navigationController pushViewController:ipsetting animated:NO];
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
    //    NSString *wavRecordFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WAVtemporaryRadio.wav"];
    //    NSLog(@"文件大小: %@", [[[NSFileManager defaultManager] attributesOfItemAtPath:fileURL error:nil] objectForKey:NSFileSize]);
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (self.player == nil) {
        NSLog(@"AudioPlayer did not load properly: %@", [error description]);
    }
    self.player.delegate = self;
    self.player.meteringEnabled = YES;
}

- (void)levelTimerCallback:(NSTimer *)timer{
    [self.recorder updateMeters];//刷新音量数据
    //获取分贝  基本在0-1之间 可能超过1
    CGFloat lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
    //分成10个等级
    [self.progress setProgress:lowPassResults animated:YES];
}

- (void)showToast:(NSString *) msg {
    //初始化弹窗
    SYAlertController *alert = [SYAlertController alertControllerWithTitle:@"" message:msg image:@"warning"];
    [self presentViewController:alert animated:YES completion:^{
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
    }];
}

- (void)dismissAlertController {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

//获取ip地址
//获取设备当前网络IP地址
- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
        address = addresses[key];
        if(address) *stop = YES;
    } ];
    return address ? address : @"0.0.0.0";
}

//获取所有相关IP信息
- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"发送失败");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error{
    NSLog(@"连接失败");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"发送成功");
//    NSError *error;
//    [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"] error:&error];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    //    NSLog(@"接收到%@的数据",address);
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    
    //    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 继续来等待接收下一次消息
//    NSLog(@"收到数据 [%@:%d]", ip, port);
    NSMutableData* msg;
    
//    if(data.length<maxData+10&&msg == nil){
//        msg = [NSMutableData dataWithData:data];
//        NSString *aacPlayerFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"];
//
//        [msg writeToFile:aacPlayerFilePath atomically:YES];
//        [msg setLength:0];
//
//        //    NSLog(@"收到数据 [%@:%d] %@", ip, port, s);
//
//        NSError *error;
//        self.player = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:aacPlayerFilePath] error:&error];
//        [self.player prepareToPlay];
//        [self.player play];
//    }else{
        NSData* ten = [data subdataWithRange:NSMakeRange(0, 10)];
        NSString* str = [[NSString alloc] initWithData:ten encoding:NSUTF8StringEncoding];
        NSLog(@"str: %@",str);
        str = [str stringByReplacingOccurrencesOfString:@"a" withString:@""];
        
        NSArray* array = [str componentsSeparatedByString:@"-"];
        int num = [array[1] integerValue];
        NSData *audioData = [data subdataWithRange:NSMakeRange(10, data.length-10)];
        
        NSString *aacPlayerFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[array[0] stringByAppendingString:@".m4a"]];
        
        [audioData writeToFile:aacPlayerFilePath atomically:YES];
        
        NSArray* files = [self allFilesAtPath:NSTemporaryDirectory()];

        if(files.count==num+2){
            NSLog(@"%@",files);
            NSMutableData* playData = [[NSMutableData alloc] initWithLength:0];
            NSArray *array = [files sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
                return [[obj1 lowercaseString] compare:[obj2 lowercaseString]];
            }];
            for(id file in array){
                if([file containsString:@"temp.m4a"]){
                    continue;
                }
                NSData* tmp = [NSData dataWithContentsOfFile:file];
//                [playData appendData:tmp];
                [playData appendBytes:tmp.bytes length:tmp.length];
                NSLog(@"playData的长度为 %lu Byte",playData.length);
            }
            [playData writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.m4a"] atomically:YES];
            
            
//            [msg writeToFile:aacPlayerFilePath atomically:YES];
//            [msg setLength:0];
//
//            //    NSLog(@"收到数据 [%@:%d] %@", ip, port, s);
//
            NSError *error;
            self.player = [[AVAudioPlayer alloc] initWithData:playData error:&error];
            [self.player prepareToPlay];
            [self.player play];
        }
//    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    NSLog(@"udpSocketDidClose:%@",error);
}

- (NSArray*)allFilesAtPath:(NSString*)dirString {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:10];
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSArray* tempArray = [fileMgr contentsOfDirectoryAtPath:dirString error:nil];
    for (NSString* fileName in tempArray) {
        BOOL flag = YES;
        NSString* fullPath = [dirString stringByAppendingPathComponent:fileName];
        if ([fileMgr fileExistsAtPath:fullPath isDirectory:&flag]) {
            if (!flag) {
                [array addObject:fullPath];
            }
        }
    }
    return array;
}

@end
