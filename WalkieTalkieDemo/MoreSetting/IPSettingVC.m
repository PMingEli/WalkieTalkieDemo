//
//  IPSettingVC.m
//  WalkieTalkieDemo
//
//  Created by 彭明均 on 2022/8/31.
//

#import "IPSettingVC.h"
#import "../ToolKit/UIScreen.h"
#import "../ToolKit/IPAddressValidate.h"
#import "../ToolKit/ZWAlignLabel.h"
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
    ZWAlignLabel* ipLabel = [[ZWAlignLabel alloc] initWithFrame:CGRectMake(10, SCREEN_HEIGHT/5, SCREEN_WIDTH*2/5-30, 50)];
    ipLabel.text = @"目标IP地址:";
    [ipLabel textAlign:^(ZWMaker *maker) {
        maker.right().center();
    }];
    [self.view addSubview:ipLabel];
    
    self.inputTargetIP = [[UITextField alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*2/5, SCREEN_HEIGHT/5, SCREEN_WIDTH*3/5-10, 50)];
    self.inputTargetIP.text = [IPSetting sharedInstance].targetIP;
    self.inputTargetIP.font = [UIFont fontWithName:@"wawati sc" size:45];
    self.inputTargetIP.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTargetIP.placeholder = @"请输入目标IP";
//    self.inputTargetIP.clearsOnBeginEditing = YES;
    
    ZWAlignLabel* localPortLabel = [[ZWAlignLabel alloc] initWithFrame:CGRectMake(10, SCREEN_HEIGHT/5+100, SCREEN_WIDTH*2/5-30, 50)];
    localPortLabel.text = @"本地端口:";
    [localPortLabel textAlign:^(ZWMaker *maker) {
        maker.right().center();
    }];
    [self.view addSubview:localPortLabel];
    
    self.inputLocalPort = [[UITextField alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*2/5, SCREEN_HEIGHT/5+100, SCREEN_WIDTH*3/5-10, 50)];
    self.inputLocalPort.text = [IPSetting sharedInstance].localPort;
    self.inputLocalPort.font = [UIFont fontWithName:@"wawati sc" size:45];
    self.inputLocalPort.borderStyle = UITextBorderStyleRoundedRect;
    self.inputLocalPort.placeholder = @"请输入本地端口";
//    self.inputLocalPort.clearsOnBeginEditing = YES;
    
    ZWAlignLabel* remotePortLabel = [[ZWAlignLabel alloc] initWithFrame:CGRectMake(10, SCREEN_HEIGHT/5+200, SCREEN_WIDTH*2/5-30, 50)];
    remotePortLabel.text = @"远程端口:";
    [remotePortLabel textAlign:^(ZWMaker *maker) {
        maker.right().center();
    }];
    [self.view addSubview:remotePortLabel];
    
    self.inputRemotePort = [[UITextField alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*2/5, SCREEN_HEIGHT/5+200, SCREEN_WIDTH*3/5-10, 50)];
    self.inputRemotePort.text = [IPSetting sharedInstance].remotePort;
    self.inputRemotePort.font = [UIFont fontWithName:@"wawati sc" size:45];
    self.inputRemotePort.borderStyle = UITextBorderStyleRoundedRect;
    self.inputRemotePort.placeholder = @"请输入远程端口";
//    self.inputRemotePort.clearsOnBeginEditing = YES;
    
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
    if([[IPAddressValidate sharedInstance] isIPV4Validate:self.inputTargetIP.text]){
        NSLog(@"输入正确，IP地址为:%@",self.inputTargetIP.text);
        ip.targetIP = self.inputTargetIP.text;
        if(![self.inputLocalPort.text isEqual:@""]&&![self.inputRemotePort.text isEqual:@""]){
            ip.localPort = self.inputLocalPort.text;
            ip.remotePort = self.inputRemotePort.text;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"IPSettingChanged" object:nil];
            
            SYAlertController *alert = [SYAlertController alertControllerWithTitle:@"" message:@"设置成功" image:@"complete"];
            [self presentViewController:alert animated:YES completion:^{
                [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
            }];
        }else{
            SYAlertController *alert = [SYAlertController alertControllerWithTitle:@"" message:@"端口不能为空或输入错误，请重新输入" image:@"warning"];
            [self presentViewController:alert animated:YES completion:^{
                [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
            }];
        }
    }else{
        SYAlertController *alert = [SYAlertController alertControllerWithTitle:@"" message:@"目标IP地址有误，请重新输入" image:@"warning"];
        [self presentViewController:alert animated:YES completion:^{
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlertController) userInfo:nil repeats:NO];
        }];
    }
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
