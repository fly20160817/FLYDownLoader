//
//  NSString+SZ.m
//  FLYDownLoader
//
//  Created by fly on 2020/3/20.
//  Copyright © 2020 fly. All rights reserved.
//

#import "NSString+SZ.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (SZ)

- (NSString *)md5
{
    const char * data = self.UTF8String;
    
    //接收转换结果的char数组
    unsigned char md[CC_MD5_DIGEST_LENGTH];
    
    //把C语言的字符串，转成 md5 C字符串
    CC_MD5(data, (CC_LONG)strlen(data), md);
    
    //32位  （CC_MD5_DIGEST_LENGTH等于16）
    NSMutableString * result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        //把字符串转成16进制，两位数，不足两位补0
        [result appendFormat:@"%02x", md[i]];
    }
    
    return result;
}

@end
