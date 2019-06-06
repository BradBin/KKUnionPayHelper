//
//  KKCryptoHelper.h
//  KKUnionPayHelper_Example
//
//  Created by 尤彬 on 2019/6/6.
//  Copyright © 2019 BradBin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKCryptoHelper : NSObject

/**
 获取3DESKey 默认24个0
 */
@property (nonatomic,copy,readonly) NSString *threeDesKey;

/**
 单例管理对象

 @return 对象实例
 */
+ (instancetype)shared;


/***************3DES加密/解密相关部分*****************/

/**
 设置默认3DESKey秘钥

 @param key key
 */
- (void)kk_setDefault3DESKey:(nonnull NSString *)key;

/**
 对字符串进行3DES加密

 @param string 待加密字符串
 @return 3DES加密后的字符串
 */
- (nonnull NSString *)kk_encrypt3DESWithString:(nonnull NSString *)string;

/**
 对字符串进行3DES解密

 @param string 3DES加密字符串
 @return 解密后字符串
 */
- (nonnull NSString *)kk_decrypt3DESWithCryptoString:(nonnull NSString *)string ;

/**
 对字符串进行3DES加密
 
 @param string 待加密字符串
 @param key key秘钥
 @return 3DES加密后的字符串
 */
- (nonnull NSString *)kk_encrypt3DESWithString:(nonnull NSString *)string key:(nonnull NSString *)key;

/**
 对字符串进行3DES解密
 
 @param string 3DES加密字符串
 @param key key秘钥
 @return 解密后字符串
 */
- (nonnull NSString *)kk_decrypt3DESWithCryptoString:(nonnull NSString *)string key:(nonnull NSString *)key;




/***************RSA加密/解密相关部分*****************/

/**
 对字符串进行公钥加密码,生成Base64字符串

 @param string 字符串
 @param key 公钥
 @return base64字符串
 */
- (nonnull NSString *)kk_encryptRSAWithString:(nonnull NSString *)string publicKey:(nonnull NSString *)key;

/**
 对字符串进行共公钥解密

 @param string 待解密的字符串
 @param key 公钥
 @return 解密后字符串
 */
- (nonnull NSString *)kk_decryptRSAWithCryptoString:(nonnull NSString *)string publicKey:(nonnull NSString *)key;

/**
 对NSData进行公钥加密

 @param data data
 @param key 公钥
 @return 加密的data
 */
- (nonnull NSData *)kk_encryptRSAWithData:(nonnull NSData *)data publicKey:(nonnull NSString *)key;

/**
 对加密后data进行公钥解密

 @param data 待解密的data
 @param key 公钥
 @return 解密后的data
 */
- (nonnull NSData *)kk_decryptRSAWithCryptoData:(nonnull NSData *)data publicKey:(nonnull NSString *)key;

/**
 对字符串进行私钥加密

 @param string 待加密的字符串
 @param key 私钥
 @return 加密后字符串
 */
- (nonnull NSString *)kk_decryptRSAWithCryptoString:(NSString *)string privateKey:(NSString *)key;

/**
 对NSData进行私钥解密

 @param data 待解密的data
 @param key 私钥
 @return 解密后的data
 */
- (nonnull NSData *)kk_decryptRSAWithCryptoData:(NSData *)data privateKey:(NSString *)key;

/**
 验签并返回结果

 @param originData originData
 @param signData signData
 @param key 公钥
 @return 验签结果
 */
- (OSStatus)kk_verifyWithOriginData:(NSData *)originData signData:(NSData *)signData publicKey:(NSString *)key;


@end

NS_ASSUME_NONNULL_END
