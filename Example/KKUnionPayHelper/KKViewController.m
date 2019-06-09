//
//  KKViewController.m
//  KKUnionPayHelper
//
//  Created by BradBin on 06/04/2019.
//  Copyright (c) 2019 BradBin. All rights reserved.
//

#import "KKViewController.h"
#import <YYKit/YYKit.h>
#import <Masonry/Masonry.h>
#import <AFNetworking/AFNetworking.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <KKUnionPayHelper/KKUnionPayHelper.h>


//商户需要换用自己的mertchantID
#define kAppleMerchantID        @"merchant.com.am.gu"
//生产环境:固定为一分钱订单         mode=00
#define kURL_TN_Product         @"http://101.231.114.216:1725/sim/getacptn"

//测试环境:不会产生真实交易         mode=01
#define kURL_TN_ATest           @"http://101.231.204.84:8091/sim/getacptn"
#define kURL_TN_UTest           @"http://101.231.204.84:8091/sim/getacptn"

@interface KKViewController ()

@property (nonatomic,strong) UIButton *paymentBtn;

@end

@implementation KKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self kk_setupView];
    [self kk_bindModel];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)kk_setupView{
    
    self.paymentBtn = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.masksToBounds = true;
        button.layer.cornerRadius = CGFloatPixelRound(8);
        [button setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#207CB7"]] forState:UIControlStateNormal];
        [button setTitle:@"银联支付" forState:UIControlStateNormal];
        [self.view addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(button.superview.mas_safeAreaLayoutGuideBottom).offset(-CGFloatPixelRound(35));
            } else {
              make.bottom.equalTo(button.superview.mas_bottom).offset(-CGFloatPixelRound(35));
            }
            make.centerX.equalTo(button.superview.mas_centerX);
            make.width.equalTo(button.superview.mas_width).multipliedBy(0.75);
            make.height.mas_equalTo(@50);
        }];
        button;
    });
}

- (void)kk_bindModel{
    @weakify(self);
    [[[self.paymentBtn rac_signalForControlEvents:UIControlEventTouchUpInside] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        NSLog(@"银联支付");
        [self kk_getTradeNum];
    }];
}

- (void)kk_getTradeNum{
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer     = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 15.0;
    @weakify(self);
    [manager GET:kURL_TN_UTest parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self);
        NSString *tradeNum = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        [self kk_UnionPayWithTradeNum:tradeNum];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString *errMsg = [NSString stringWithFormat:@"%@(%ld)",error.localizedDescription,(long)error.code];
        [SVProgressHUD showErrorWithStatus:errMsg];
    }];
    
}



- (void)kk_UnionPayWithTradeNum:(nonnull NSString *)tradeNum{
    [KKUnionPayManager.shared startUnionPay:tradeNum scheme:@"controldemo" viewController:self success:^(KKUnionPayResultStatus status, NSDictionary * _Nonnull dict) {
          NSLog(@"UnionPay success: %ld  %@",(long)status,[dict modelDescription]);
    } failure:^(KKUnionPayResultStatus status, NSDictionary * _Nonnull dict) {
        switch (status) {
            case KKUnionPayResultStatusCancel:
                [SVProgressHUD showErrorWithStatus:@"用户取消支付"];
                break;
            case KKUnionPayResultStatusFailure:
                 [SVProgressHUD showErrorWithStatus:@"用户支付失败"];
                break;
                
                case KKUnionPayResultStatusUnknownCancel:
                    [SVProgressHUD showErrorWithStatus:@"支付发生未知错误"];
                break;
                
            default:
                break;
        }
        
        
        NSLog(@"UnionPay failure: %ld  %@",(long)status,[dict modelDescription]);
    }];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
