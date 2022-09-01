//
//  IPSettingVC.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/31.
//

#import "IPSettingVC.h"
#import "../UIScreen.h"
@import SYAlertController;

@interface IPSettingVC ()

@property (nonatomic, strong)UITextField* inputTargetIP;
@property (nonatomic, strong)UITextField* inputLocalPort;
@property (nonatomic, strong)UITextField* inputRemotePort;
@property (nonatomic, strong)UIButton* confirmBtn;


@end

@implementation IPSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self createUI];
    [self.view addSubview:self.inputTargetIP];
    [self.view addSubview:self.inputLocalPort];
    [self.view addSubview:self.inputRemotePort];
    [self.view addSubview:self.confirmBtn];
}

- (void)createUI{
    self.inputTargetIP = [[UITextField alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/5, SCREEN_HEIGHT/5, SCREEN_WIDTH*3/5, 50)];
    self.inputTargetIP.text = [IPSetting sharedInstance].targetIP;
    self.inputTargetIP.font = [UIFont fontWithName:@"wawati sc" size:45];
    self.inputTargetIP.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTargetIP.placeholder = @"请输入目标IP";
    self.inputTargetIP.clearsOnBeginEditing = YES;
    
    self.inputLocalPort = [[UITextField alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/5, SCREEN_HEIGHT/5+100, SCREEN_WIDTH*3/5, 50)];
    self.inputLocalPort.text = [IPSetting sharedInstance].localPort;
    self.inputLocalPort.font = [UIFont fontWithName:@"wawati sc" size:45];
    self.inputLocalPort.borderStyle = UITextBorderStyleRoundedRect;
    self.inputLocalPort.placeholder = @"请输入本地端口";
    self.inputLocalPort.clearsOnBeginEditing = YES;
    
    self.inputRemotePort = [[UITextField alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/5, SCREEN_HEIGHT/5+200, SCREEN_WIDTH*3/5, 50)];
    self.inputRemotePort.text = [IPSetting sharedInstance].remotePort;
    self.inputRemotePort.font = [UIFont fontWithName:@"wawati sc" size:45];
    self.inputRemotePort.borderStyle = UITextBorderStyleRoundedRect;
    self.inputRemotePort.placeholder = @"请输入远程端口";
    self.inputRemotePort.clearsOnBeginEditing = YES;
    
    self.confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*2/5, SCREEN_HEIGHT*4/5, SCREEN_WIDTH/5, 40)];
    [self.confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    self.confirmBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.confirmBtn addTarget:self action:@selector(sender:) forControlEvents:UIControlEventTouchDown];
    [self.confirmBtn.layer setCornerRadius:10.0];
    [self.confirmBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.confirmBtn.layer setBorderWidth:2];
}

- (void) sender:(UIButton*)btn{
    IPSetting* ip = [IPSetting sharedInstance];
    if([self isIPV4Validate:self.inputTargetIP.text]){
        NSLog(@"输入正确，IP地址为:%@",self.inputTargetIP.text);
        ip.targetIP = self.inputTargetIP.text;
        ip.localPort = self.inputLocalPort.text;
        ip.remotePort = self.inputRemotePort.text;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"IPSettingChanged" object:nil];
    }else{
        SYAlertController *alert = [SYAlertController alertControllerWithTitle:@"" message:@"目标IP地址有误，请重新输入" image:@"warning"];
        [self presentViewController:alert animated:YES completion:^{
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
        }];
    }
}

-(BOOL)isIPV4Validate:(NSString *)str
{
    NSString *regex = @"^(?:(?:1[0-9][0-9]\.)|(?:2[0-4][0-9]\.)|(?:25[0-5]\.)|(?:[1-9][0-9]\.)|(?:[0-9]\.)){3}(?:(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])|(?:[1-9][0-9])|(?:[0-9]))$";
    NSPredicate *ipv4Regx = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [ipv4Regx evaluateWithObject:str];
}

- (void)dismissAlertController {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
