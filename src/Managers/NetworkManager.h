#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

- (void)trialLoginWithDeviceID:(NSString *)deviceID completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion;
- (void)cardLoginWithCard:(NSString *)card deviceID:(NSString *)deviceID completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion;
- (void)queryCard:(NSString *)card completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion;
- (void)unbindCard:(NSString *)card deviceID:(NSString *)deviceID token:(NSString *)token completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion;
- (void)getAppConfigWithCompletion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion;
- (void)startHeartbeatWithCard:(NSString *)card deviceID:(NSString *)deviceID token:(NSString *)token;
- (void)stopHeartbeat;

@end
