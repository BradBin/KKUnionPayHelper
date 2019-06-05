//
//  KKUnionPayManager.m
//  KKUnionPayHelper
//
//  Created by 尤彬 on 2019/6/4.
//  Copyright © 2019 youbin. All rights reserved.
//

#import "KKUnionPayManager.h"

#import "UPPaymentControl.h"

/**
 银联回调标识
 */
NSString *const KKUppayResult  = @"uppayresult";
NSString *const KKUppaySuccess = @"success";
NSString *const KKUppayFailure = @"fail";
NSString *const KKUppayCancel  = @"cancel";

/**
 正式环境
 */
NSString *const KKUppayRelease  = @"00";
/**
 开发环境
 */
NSString *const KKUppayDevelop  = @"01";



@interface KKUnionPayManager ()

/**
 默认:fasle正式环境
 */
@property (nonatomic,assign) BOOL isDebug;
/**
 支付成功回调block
 */
@property (nonatomic, copy) KKUnionPayBlock successBlock;
/**
 支付失败回调block
 */
@property (nonatomic, copy) KKUnionPayBlock failureBlock;

@end

@implementation KKUnionPayManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isDebug = false;
    }
    return self;
}

+(instancetype)shared{
    static KKUnionPayManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class] alloc] init];
    });
    return _instance;
}

-(void)setDebugEnabled:(BOOL)enable{
    _isDebug = enable;
}

-(BOOL)isPaymentAppInstalled{
    return UPPaymentControl.defaultControl.isPaymentAppInstalled;
}

-(BOOL)startUnionPay:(NSString *)tradeNum scheme:(NSString *)scheme viewController:(UIViewController *)vc success:(KKUnionPayBlock)success failure:(KKUnionPayBlock)failure{
    NSString *mode = _isDebug ? KKUppayDevelop : KKUppayRelease;
    self.successBlock = success;
    self.failureBlock = failure;
    return [[UPPaymentControl defaultControl] startPay:tradeNum fromScheme:scheme mode:mode viewController:vc];
}

-(BOOL)handleOpenURL:(NSURL *)url{
    __weak typeof(self) weakSelf = self;
    if ([url.host isEqualToString:KKUppayResult]) {
        [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
            if ([code isEqualToString:KKUppaySuccess]) {
                if (weakSelf.successBlock) {
                    weakSelf.successBlock(KKUnionPayResultStatusSuccess, data);
                }
            }else if ([code isEqualToString:KKUppayFailure]){
                if (weakSelf.failureBlock) {
                    weakSelf.failureBlock(KKUnionPayResultStatusFailure, data);
                }
            }else if ([code isEqualToString:KKUppayCancel]){
                if (weakSelf.failureBlock) {
                    weakSelf.failureBlock(KKUnionPayResultStatusCancel, data);
                }
            }else{
                if (weakSelf.failureBlock) {
                    weakSelf.failureBlock(KKUnionPayResultStatusUnknownCancel, data);
                }
            }
        }];
    }
    return true;
}

-(BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication{
    __weak typeof(self) weakSelf = self;
    if ([url.host isEqualToString:KKUppayResult]) {
        [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
            if ([code isEqualToString:KKUppaySuccess]) {
                if (weakSelf.successBlock) {
                    weakSelf.successBlock(KKUnionPayResultStatusSuccess, data);
                }
            }else if ([code isEqualToString:KKUppayFailure]){
                if (weakSelf.failureBlock) {
                    weakSelf.failureBlock(KKUnionPayResultStatusFailure, data);
                }
            }else if ([code isEqualToString:KKUppayCancel]){
                if (weakSelf.failureBlock) {
                    weakSelf.failureBlock(KKUnionPayResultStatusCancel, data);
                }
            }else{
                if (weakSelf.failureBlock) {
                    weakSelf.failureBlock(KKUnionPayResultStatusUnknownCancel, data);
                }
            }
        }];
    }
    return true;
}



#pragma mark -
#pragma mark - 验证签名证书
- (BOOL)kk_verifySignString:(NSString *)signString{
    //验签证书同后台验签证书
    //此处的verify，商户需送去商户后台做验签
    return false;
}

@end
