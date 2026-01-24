#import "HashUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation HashUtils

+ (NSString *)md5:(NSString *)string {
    if (!string) return nil;
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return [output lowercaseString];
}

+ (NSData *)md5ToData:(NSString *)string {
    if (!string) return nil;
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    return [NSData dataWithBytes:digest length:CC_MD5_DIGEST_LENGTH];
}

+ (NSString *)sha256:(NSString *)string {
    if (!string) return nil;
    const char *s = [string UTF8String];
    NSData *keyData = [NSData dataWithBytes:s length:strlen(s)];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(keyData.bytes, (CC_LONG)keyData.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return [output lowercaseString];
}

@end
