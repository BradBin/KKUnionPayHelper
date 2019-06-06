//
//  KKCryptoHelper.m
//  KKUnionPayHelper_Example
//
//  Created by 尤彬 on 2019/6/6.
//  Copyright © 2019 BradBin. All rights reserved.
//

#import "KKCryptoHelper.h"
#import <CommonCrypto/CommonCrypto.h>
#import <sys/time.h>
#import <sys/stat.h>
#import "GTMBase64/GTMBase64.h"
#import "GTMBase64/GTMDefines.h"


//默认3DESKEY
NSString * const KKCustomKey = @"000000000000000000000000";

/**
 NSData转Base64字符串

 @param data data
 @return base64字符串
 */
static inline NSString * _Nonnull  KKEncodeBase64StringFromData(NSData * _Nonnull data){
    data = [data base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    return base64String;
}

/**
 base64字符串转NSData

 @param base64String base64字符串
 @return NSData
 */
static inline NSData * _Nonnull KKDecodeDataFromBase64String(NSString * _Nonnull base64String){
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return data;
}


@interface KKCryptoHelper ()
@property (nonatomic, copy) NSString *threeDesKey;

@end

@implementation KKCryptoHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _threeDesKey = KKCustomKey;
    }
    return self;
}

+(instancetype)shared{
    static KKCryptoHelper * _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class] alloc] init];
    });
    return _instance;
}

- (void)kk_setDefault3DESKey:(nonnull NSString *)key{
    _threeDesKey = key;
}

- (NSString *)kk_encrypt3DESWithString:(NSString *)string
{
    //kCCEncrypt 加密
    return [self kk_encrypt:string encryptOrDecrypt:kCCEncrypt key:_threeDesKey iv:nil];
}

- (NSString *)kk_decrypt3DESWithCryptoString:(NSString *)string
{
    //kCCDecrypt 解密
    return [self kk_encrypt:string encryptOrDecrypt:kCCDecrypt key:_threeDesKey iv:nil];
}

-(NSString *)kk_encrypt3DESWithString:(NSString *)string key:(NSString *)key
{
    //kCCEncrypt 加密 key
    return [self kk_encrypt:string encryptOrDecrypt:kCCEncrypt key:key iv:nil];
}

-(NSString *)kk_decrypt3DESWithCryptoString:(NSString *)string key:(NSString *)key
{
     //kCCDecrypt 解密 key
    return [self kk_encrypt:string encryptOrDecrypt:kCCDecrypt key:key iv:nil];
}

- (NSString *)kk_encrypt:(NSString *)string encryptOrDecrypt:(CCOperation)encryptOperation key:(NSString *)key iv:(NSString *)initIv
{
    const void *dataIn;
    size_t dataInLength;
    
    if (encryptOperation == kCCDecrypt)//传递过来的是decrypt 解码
        {
        //解码 base64
        NSData *decryptData = [GTMBase64 webSafeDecodeData:[string dataUsingEncoding:NSUTF8StringEncoding]];//转成utf-8并decode
        dataInLength = [decryptData length];
        dataIn = [decryptData bytes];
        }
    else  //encrypt
        {
        NSData* encryptData = [string dataUsingEncoding:NSUTF8StringEncoding];
        dataInLength = [encryptData length];
        dataIn = (const void *)[encryptData bytes];
        }
    /*
     DES加密 ：用CCCrypt函数加密一下，然后用base64编码下，传过去
     DES解密 ：把收到的数据根据base64，decode一下，然后再用CCCrypt函数解密，得到原本的数据
     */
    CCCryptorStatus ccStatus;
    uint8_t *dataOut = NULL; //可以理解位type/typedef 的缩写（有效的维护了代码，比如：一个人用int，一个人用long。最好用typedef来定义）
    size_t dataOutAvailable = 0; //size_t  是操作符sizeof返回的结果类型
    size_t dataOutMoved = 0;
    
    dataOutAvailable = (dataInLength + kCCBlockSizeDES) & ~(kCCBlockSizeDES - 1);
    dataOut = malloc( dataOutAvailable * sizeof(uint8_t));
    memset((void *)dataOut, 0x0, dataOutAvailable);//将已开辟内存空间buffer的首 1 个字节的值设为值 0
    
    const void *vkey = (const void *) [key UTF8String];
    const void *iv = [self kk_isNotBlank:initIv] ? (const void *) [initIv UTF8String] : nil;
    
    //CCCrypt函数 加密/解密
    ccStatus = CCCrypt(encryptOperation,//  加密/解密
                       kCCAlgorithm3DES,//  加密根据哪个标准（des，3des，aes。。。。）
                       kCCOptionPKCS7Padding | kCCOptionECBMode,//  选项分组密码算法(des:对每块分组加一次密  3DES：对每块分组加三个不同的密)
                       vkey,  //密钥    加密和解密的密钥必须一致
                       kCCKeySize3DES,//   DES 密钥的大小（kCCKeySizeDES=8）
                       iv, //  可选的初始矢量
                       dataIn, // 数据的存储单元
                       dataInLength,// 数据的大小
                       (void *)dataOut,// 用于返回数据
                       dataOutAvailable,
                       &dataOutMoved);
    
    NSString *result = nil;
    
    if (encryptOperation == kCCDecrypt)//encryptOperation==1  解码
        {
        //得到解密出来的data数据，改变为utf-8的字符串
        result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)dataOut length:(NSUInteger)dataOutMoved] encoding:NSUTF8StringEncoding] ;
        }
    else //encryptOperation==0  （加密过程中，把加好密的数据转成base64的）
        {
        //编码 base64
        NSData *data = [NSData dataWithBytes:(const void *)dataOut length:(NSUInteger)dataOutMoved];
        result = [GTMBase64 stringByWebSafeEncodingData:data padded:YES];
        
        }
    
    return result;
}


/***************RSA加密/解密相关部分*****************/

- (NSString *)kk_encryptRSAWithString:(NSString *)string publicKey:(NSString *)key{
    NSData *data = [self kk_encryptRSAWithData:[string dataUsingEncoding:NSASCIIStringEncoding] publicKey:key];
    NSString *base64String = KKEncodeBase64StringFromData(data);
    return base64String;
}

- (nonnull NSString *)kk_decryptRSAWithCryptoString:(nonnull NSString *)string publicKey:(nonnull NSString *)key{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self kk_decryptRSAWithCryptoData:data publicKey:key];
    NSString *resultString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    return resultString;
}

- (NSData *)kk_encryptRSAWithData:(NSData *)data publicKey:(NSString *)key{
    if (!data || !key) {
        return nil;
    }
    SecKeyRef keyRef = [self kk_RSAWithAddPublicKey:key];
    if (!keyRef) {
        return nil;
    }
    return [self kk_encryptData:data keyRef:keyRef];
}

-(NSData *)kk_decryptRSAWithCryptoData:(NSData *)data publicKey:(NSString *)key{
    if (!data || !key) {
        return nil;
    }
    SecKeyRef keyRef = [self kk_RSAWithAddPublicKey:key];
    if (!keyRef) {
        return nil;
    }
    return [self kk_decryptData:data keyRef:keyRef];
}

- (nonnull NSString *)kk_decryptRSAWithCryptoString:(NSString *)string privateKey:(NSString *)key{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self kk_decryptData:data privateKey:key];
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

- (nonnull NSData *)kk_decryptRSAWithCryptoData:(NSData *)data privateKey:(NSString *)key{
    if (!data || !key) {
        return nil;
    }
    SecKeyRef keyRef = [self kk_RSAWithAddPrivateKey:key];
    if (!keyRef) {
        return nil;
    }
    return [self kk_decryptData:data privateKey:key];
}

-(OSStatus)kk_verifyWithOriginData:(NSData *)originData signData:(NSData *)signData publicKey:(NSString *)key{
    if (originData == nil || [self kk_isNotBlank:key] == false || signData == nil) {
        return 0;
    }
    SecKeyRef keyRef = [self kk_RSAWithAddPublicKey:key];
    if (!keyRef) {
        return 0;
    }
    return [self kk_verifyWithOriginData:originData signData:signData keyRef:keyRef];
}

- (OSStatus)kk_verifyWithOriginData:(NSData *)originData signData:(NSData *)signData keyRef:(SecKeyRef)keyRef{
    
    OSStatus status = noErr;
    uint8_t hash[CC_SHA1_DIGEST_LENGTH];
    
    //先做SHA1后验证签名
    CC_SHA1((const void *)[originData bytes], (CC_LONG)[originData length], (unsigned char *)hash);
    
    status = SecKeyRawVerify(keyRef, kSecPaddingPKCS1SHA1, hash, CC_SHA1_DIGEST_LENGTH, (const uint8_t *)[signData bytes], [signData length]);
    
    if (status != 0) {
#ifdef DEBUG
        NSLog(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
#endif
    }
    return status;
}

- (NSData *)kk_decryptData:(NSData *)data privateKey:(NSString *)key{
    if (!data || !key) {
        return nil;
    }
    SecKeyRef keyRef = [self kk_RSAWithAddPublicKey:key];
    if (!keyRef) {
        return nil;
    }
    return [self kk_decryptData:data keyRef:keyRef];
}

- (NSData *)kk_encryptData:(NSData *)data keyRef:(SecKeyRef)keyRef{
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen         = (size_t)data.length;
    size_t block_size     = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf          = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *mData  = NSMutableData.alloc.init;
    for(int idx = 0; idx < srclen; idx += src_block_size){
        //NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
        size_t data_len = srclen - idx;
        if(data_len > src_block_size){
            data_len = src_block_size;
        }
        size_t outlen   = block_size;
        OSStatus status = noErr;
        status = SecKeyEncrypt(keyRef,
                               kSecPaddingNone,//kSecPaddingPKCS1,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            NSLog(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
            mData = nil;
            break;
        }else{
            [mData appendBytes:outbuf length:outlen];
        }
    }
    free(outbuf);
    CFRelease(keyRef);
    return mData;
}

- (NSData *)kk_decryptData:(NSData *)data keyRef:(SecKeyRef)keyRef{
    
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t block_size     = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    UInt8 *outbuf         = malloc(block_size);
    NSMutableData *mData  = NSMutableData.alloc.init;
    size_t outlen         = block_size;
    OSStatus status       = noErr;
    status = SecKeyDecrypt(keyRef,
                           kSecPaddingNone,
                           srcbuf ,
                           block_size,
                           outbuf,
                           &outlen
                           );
    [mData appendBytes:&outbuf[0] length:block_size];
    free(outbuf);
    CFRelease(keyRef);
    return mData;
}

- (SecKeyRef)kk_RSAWithAddPublicKey:(NSString *)key{
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if(spos.location != NSNotFound && epos.location != NSNotFound){
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = KKDecodeDataFromBase64String(key);
    data = [self kk_stripPublicKeyHeader:data];
    if(!data){
        return nil;
    }
    
    //a tag to read/write keychain storage
    NSString *tag = @"RSAUtil_PubKey";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }
    return keyRef;
}

- (SecKeyRef)kk_RSAWithAddPrivateKey:(NSString *)key{
    NSRange spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];
    if(spos.location != NSNotFound && epos.location != NSNotFound){
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = KKDecodeDataFromBase64String(key);
    data = [self kk_stripPrivateKeyHeader:data];
    if(!data){
        return nil;
    }
    
    //a tag to read/write keychain storage
    NSString *tag = @"RSAUtil_PrivKey";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
    [privateKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [privateKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)privateKey);
    
    // Add persistent version of the key to system keychain
    [privateKey setObject:data forKey:(__bridge id)kSecValueData];
    [privateKey setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)
     kSecAttrKeyClass];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)privateKey, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [privateKey removeObjectForKey:(__bridge id)kSecValueData];
    [privateKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)privateKey, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }
    return keyRef;
}

- (NSData *)kk_stripPublicKeyHeader:(NSData *)dataKey{
    // Skip ASN.1 public key header
    if (dataKey == nil) return(nil);
    
    unsigned long len = [dataKey length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[dataKey bytes];
    unsigned int  idx     = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

- (NSData *)kk_stripPrivateKeyHeader:(NSData *)dataKey{
    // Skip ASN.1 private key header
    if (dataKey == nil) return(nil);
    
    unsigned long len = [dataKey length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[dataKey bytes];
    unsigned int  idx     = 22; //magic byte at offset 22
    
    if (0x04 != c_key[idx++]) return nil;
    
    //calculate length of the key
    unsigned int c_len = c_key[idx++];
    int det = c_len & 0x80;
    if (!det) {
        c_len = c_len & 0x7f;
    } else {
        int byteCount = c_len & 0x7f;
        if (byteCount + idx > len) {
            //rsa length field longer than buffer
            return nil;
        }
        unsigned int accum = 0;
        unsigned char *ptr = &c_key[idx];
        idx += byteCount;
        while (byteCount) {
            accum = (accum << 8) + *ptr;
            ptr++;
            byteCount--;
        }
        c_len = accum;
    }
    
    // Now make a new NSData from this buffer
    return [dataKey subdataWithRange:NSMakeRange(idx, c_len)];
}


#pragma mark - private method
/**
 判断字符串是否为空,并返回结果
 
 @param string 字符串
 @return true:字符串不为空 otherwise:false则反之
 */
- (BOOL)kk_isNotBlank:(NSString *)string {
    NSCharacterSet *blank = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSInteger i = 0; i < string.length; ++i) {
        unichar c = [string characterAtIndex:i];
        if (![blank characterIsMember:c]) {
            return YES;
        }
    }
    return NO;
}

@end
