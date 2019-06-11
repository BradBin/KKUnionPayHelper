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

/** 正式环境 */
NSString *const KKUppayRelease = @"00";
/** 开发环境 */
NSString *const KKUppayDevelop = @"01";

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

/**
 支付订单编号
 */
@property (nonatomic, copy) NSString *tradeNum;

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

-(BOOL)isUnionPayAppInstalled{
    return UPPaymentControl.defaultControl.isPaymentAppInstalled;
}

-(BOOL)startUnionPay:(NSString *)tradeNum scheme:(NSString *)scheme viewController:(UIViewController *)vc success:(KKUnionPayBlock)success failure:(KKUnionPayBlock)failure{
    NSString *mode    = _isDebug ? KKUppayDevelop : KKUppayRelease;
    self.successBlock = success;
    self.failureBlock = failure;
    self.tradeNum     = tradeNum;
    return [[UPPaymentControl defaultControl] startPay:tradeNum fromScheme:scheme mode:mode viewController:vc];
}

-(BOOL)handleOpenURL:(NSURL *)url{
     [self handlePaymentResultWithURL:url];
    return true;
}

-(BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication{
    [self handlePaymentResultWithURL:url];
    return true;
}

-(BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [self handlePaymentResultWithURL:url];
    return true;
}

- (void)handlePaymentResultWithURL:(NSURL *)url{
    if ([url.host isEqualToString:KKUppayResult]) {
        __weak __typeof(self)weakSelf = self;
        [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            NSMutableDictionary *dict             = NSMutableDictionary.dictionary;
            strongSelf.tradeNum                   = strongSelf.tradeNum.length ? strongSelf.tradeNum : @"";
            [dict addEntriesFromDictionary:data];
            [dict setObject:strongSelf.tradeNum forKey:@"tradeNum"];
            if (strongSelf.isDebug) {
                NSLog(@"\n*************❤️************\n银联支付结果状态:%@\n支付结果详情:%@\n*************************\n",code,dict);
            }
            if ([code isEqualToString:KKUppaySuccess]) {
                if (strongSelf.successBlock) {
                    strongSelf.successBlock(KKUnionPayResultStatusSuccess, dict);
                }
            }else if ([code isEqualToString:KKUppayFailure]){
                if (strongSelf.failureBlock) {
                    strongSelf.failureBlock(KKUnionPayResultStatusFailure, dict);
                }
            }else if ([code isEqualToString:KKUppayCancel]){
                if (strongSelf.failureBlock) {
                    strongSelf.failureBlock(KKUnionPayResultStatusCancel, dict);
                }
            }else{
                if (strongSelf.failureBlock) {
                    strongSelf.failureBlock(KKUnionPayResultStatusUnknownCancel, dict);
                }
            }
        }];
    }
}

@end
