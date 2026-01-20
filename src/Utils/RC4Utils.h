#import <Foundation/Foundation.h>

@interface RC4Utils : NSObject

+ (NSString *)encryptData:(NSString *)data withKey:(NSString *)key;
+ (NSString *)decryptData:(NSString *)hexData withKey:(NSString *)key;

@end
