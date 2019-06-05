//
//  KKUnionPayManager.h
//  KKUnionPayHelper
//
//  Created by 尤彬 on 2019/6/4.
//  Copyright © 2019 youbin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,KKUnionPayResultStatus) {
    KKUnionPayResultStatusSuccess,        //支付成功
    KKUnionPayResultStatusFailure,        //支付失败
    KKUnionPayResultStatusCancel,         //支付取消
    KKUnionPayResultStatusUnknownCancel   //支付取消，交易已发起，状态不确定，商户需查询商户后台确认支付状态
};

/**
 支付回调block
 
 @param status 支付结果状态
 @param dict dict
 */
typedef void(^ _Nullable KKUnionPayBlock)(KKUnionPayResultStatus status,NSDictionary *dict);


@interface KKUnionPayManager : NSObject

/**
 单例对象
 
 @return 单例对象
 */
+ (instancetype)shared;

/**
 是否是开发环境,默认:false正式环境,反之开发环境
 
 @param enable 运行环境标识
 */
- (void)setDebugEnabled:(BOOL)enable;

/**
 用户是否安装银联支付的APP
 
 @return 安装银联支付APP结果
 */
- (BOOL) isPaymentAppInstalled;

/**
 调用银联支付
 备注:支付成功时,
 
 @param tradeNum 订单信息/流水账单号
 @param scheme  调用支付的app注册在info.plist中的scheme
 @param vc 启动支付控件的viewController
 @param success 支付成功回调
 @param failure 支付失败回调
 @return 调用银联支付结果
 */
- (BOOL)startUnionPay:(NSString *)tradeNum scheme:(NSString *)scheme viewController:(UIViewController *)vc success:(KKUnionPayBlock)success failure:(KKUnionPayBlock)failure;

/**
 处理客户端回调
 - (BOOL)application(UIApplication *)application openURL:(NSURL *)url
 @param url url
 @return 回调结果
 */
- (BOOL)handleOpenURL:(NSURL *)url;


/**
 处理客户端回调
 - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
 @param url url
 @return 回调结果
 */
- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;



@end

NS_ASSUME_NONNULL_END
