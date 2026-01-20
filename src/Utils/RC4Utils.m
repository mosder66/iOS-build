#import "RC4Utils.h"
#import "HashUtils.h"

@implementation RC4Utils

+ (NSString *)encryptData:(NSString *)data withKey:(NSString *)key {
    if (!data || !key) return nil;
    
    // Key Processing: MD5(key) -> 16 bytes
    NSData *keyBytes = [self processKey:key];
    NSData *dataBytes = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *encrypted = [self rc4:dataBytes key:keyBytes];
    return [self bytesToHex:encrypted];
}

+ (NSString *)decryptData:(NSString *)hexData withKey:(NSString *)key {
    if (!hexData || !key) return nil;
    
    // Key Processing
    NSData *keyBytes = [self processKey:key];
    NSData *dataBytes = [self hexToBytes:hexData];
    
    NSData *decrypted = [self rc4:dataBytes key:keyBytes];
    return [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
}

// MD5 process key as per java implementation: MD5(key) -> bytes -> copyOf(16)
+ (NSData *)processKey:(NSString *)key {
    NSData *md5Key = [HashUtils md5ToData:key];
    if (md5Key.length >= 16) {
        return [md5Key subdataWithRange:NSMakeRange(0, 16)];
    } else {
        NSMutableData *padded = [NSMutableData dataWithData:md5Key];
        [padded increaseLengthBy:16 - md5Key.length]; // Padding with zeros if needed (though MD5 is usually 16 bytes)
        return padded;
    }
}

+ (NSData *)rc4:(NSData *)data key:(NSData *)key {
    if (!data || !key) return nil;
    
    const uint8_t *k = key.bytes;
    NSUInteger keyLen = key.length;
    
    // Init S-Box
    int S[256];
    for (int i = 0; i < 256; i++) {
        S[i] = i;
    }
    
    int j = 0;
    for (int i = 0; i < 256; i++) {
        j = (j + S[i] + k[i % keyLen]) % 256;
        int temp = S[i];
        S[i] = S[j];
        S[j] = temp;
    }
    
    // Transform
    uint8_t *result = malloc(data.length);
    const uint8_t *d = data.bytes;
    int i = 0;
    int j2 = 0;
    for (int k = 0; k < data.length; k++) {
        i = (i + 1) % 256;
        j2 = (j2 + S[i]) % 256;
        int temp = S[i];
        S[i] = S[j2];
        S[j2] = temp;
        
        int t = (S[i] + S[j2]) % 256;
        result[k] = d[k] ^ S[t];
    }
    
    NSData *output = [NSData dataWithBytes:result length:data.length];
    free(result);
    return output;
}

+ (NSString *)bytesToHex:(NSData *)data {
    const unsigned char *buffer = (const unsigned char *)[data bytes];
    if (!buffer) return @"";
    NSMutableString *hexString = [NSMutableString stringWithCapacity:[data length] * 2];
    for (int i = 0; i < [data length]; ++i)
        [hexString appendFormat:@"%02x", buffer[i]];
    return hexString;
}

+ (NSData *)hexToBytes:(NSString *)hexString {
    NSMutableData *data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= hexString.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

@end
