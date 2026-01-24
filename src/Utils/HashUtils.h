#import <Foundation/Foundation.h>

@interface HashUtils : NSObject

+ (NSString *)md5:(NSString *)string;
+ (NSData *)md5ToData:(NSString *)string;
+ (NSString *)sha256:(NSString *)string;

@end
