#import "NetworkManager.h"
#import <UIKit/UIKit.h>
#import "../Config.h"
#import "../Utils/RC4Utils.h"

// Configuration
static NSTimeInterval kHeartbeatInterval = 300.0;

@interface NetworkManager ()
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, strong) NSString *currentCard;
@property (nonatomic, strong) NSString *currentDeviceID;
@property (nonatomic, strong) NSString *currentToken;
@property (nonatomic, assign) BOOL isDebugMode; // Dynamic Debug Flag
@end

@implementation NetworkManager

+ (instancetype)sharedManager {
    static NetworkManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        shared.isDebugMode = NO; // Default to NO, wait for Cloud Config
    });
    return shared;
}

- (void)postRequestToURL:(NSString *)urlString params:(NSDictionary *)params completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // Encrypt Data Field
    NSMutableDictionary *finalParams = [params mutableCopy];
    NSString *debugEncryptionInfo = @"Mode: Plain (0)";
    
    if (params[@"data"]) {
        id internalData = params[@"data"];
        
        // Prepare JSON String
        NSString *jsonString = nil;
        if ([internalData isKindOfClass:[NSDictionary class]] || [internalData isKindOfClass:[NSArray class]]) {
             NSData *jsonData = [NSJSONSerialization dataWithJSONObject:internalData options:0 error:nil];
             jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else if ([internalData isKindOfClass:[NSString class]]) {
             jsonString = internalData;
        }
        
        if (jsonString) {
            #if ENCRYPTION_METHOD == 1
                // RC4 Encryption
                debugEncryptionInfo = @"Mode: RC4 (1)";
                NSString *encryptedData = [RC4Utils encryptData:jsonString withKey:APP_SECRET];
                finalParams[@"data"] = encryptedData;
                
            #elif ENCRYPTION_METHOD == 2
                // RSA Encryption (Placeholder)
                debugEncryptionInfo = @"Mode: RSA (2)";
                // TODO: Implement RSA
                finalParams[@"data"] = jsonString; // Fallback to plain for now if not impl
                
            #else
                // Plaintext (Method 0)
                debugEncryptionInfo = @"Mode: Plain (0)";
            #endif
        }
    }
    
    // DEBUG ALERT: Request
    if (self.isDebugMode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *originalData = [NSString stringWithFormat:@"%@", params];
            NSString *finalData = [NSString stringWithFormat:@"%@", finalParams];
            NSString *msg = [NSString stringWithFormat:@"URL: %@\n\n%@\n\n[Original Params]:\n%@\n\n[Final Params]:\n%@", urlString, debugEncryptionInfo, originalData, finalData];
            [self showDebugAlert:@"Request Debug" content:msg];
        });
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:finalParams options:0 error:&error];
    if (error) {
        if (completion) completion(NO, @"Data processing error", nil);
        return;
    }
    req.HTTPBody = jsonData;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !responseData) {
                if (completion) completion(NO, @"Network Request Failed", nil);
                return;
            }
            
            NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
            
            // DEBUG ALERT: Response
            if (self.isDebugMode) {
                NSString *respStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                [self showDebugAlert:@"Response Debug" content:respStr ?: @"Invalid Data"];
            }
            
            if (!resp) {
                if (completion) completion(NO, @"Invalid Server Response", nil);
                return;
            }
            
            NSString *code = [NSString stringWithFormat:@"%@", resp[@"code"]];
            NSString *message = resp[@"message"] ?: @"Unknown Error";
            
            if ([code isEqualToString:@"200"]) {
                id data = resp[@"data"];
                
                // Response Decryption
                #if ENCRYPTION_METHOD == 1
                if ([data isKindOfClass:[NSString class]]) {
                    // Try to decrypt
                    NSString *decryptedJson = [RC4Utils decryptData:data withKey:APP_SECRET];
                    if (decryptedJson && decryptedJson.length > 0) {
                        NSError *jsonErr;
                        NSData *jsonData = [decryptedJson dataUsingEncoding:NSUTF8StringEncoding];
                        id decryptedObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonErr];
                        
                        if (!jsonErr && decryptedObj) {
                            
                            // DEBUG ALERT: Decrypted Response
                            if (self.isDebugMode) {
                                [self showDebugAlert:@"Decrypted Response" content:[NSString stringWithFormat:@"%@", decryptedObj]];
                            }
                            
                            if (completion) completion(YES, message, decryptedObj);
                            return;
                        } else {
                            // Decryption produced invalid JSON? Or maybe it wasn't encrypted?
                            NSLog(@"[NetworkManager] Failed to parse decrypted JSON: %@", jsonErr);
                        }
                    } else {
                        NSLog(@"[NetworkManager] Decryption returned empty/nil.");
                    }
                }
                #endif
                
                // Fallback: Return raw data (if plaintext mode or decryption failed/not needed)
                if (completion) completion(YES, message, data);
            } else {
                if (completion) completion(NO, message, nil);
            }
        });
    }];
    [task resume];
}

- (void)startHeartbeatWithCard:(NSString *)card deviceID:(NSString *)deviceID token:(NSString *)token {
    [self stopHeartbeat]; // Stop existing if any
    
    self.currentCard = card;
    self.currentDeviceID = deviceID;
    self.currentToken = token;
    
    // Start Timer
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:kHeartbeatInterval target:self selector:@selector(sendHeartbeat) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
    
    NSLog(@"[NetworkManager] Heartbeat started. Interval: %.0f", kHeartbeatInterval);
}

- (void)stopHeartbeat {
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    self.currentCard = nil;
    self.currentDeviceID = nil;
    self.currentToken = nil;
    NSLog(@"[NetworkManager] Heartbeat stopped.");
}

- (void)sendHeartbeat {
    if (!self.currentCard || !self.currentToken) {
        [self stopHeartbeat];
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/api/cardHeartbeat", API_BASE_URL];
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *params = @{
        @"app_id": APP_ID,
        @"data": @{
            @"card": self.currentCard,
            @"markcode": self.currentDeviceID ?: @"",
            @"token": self.currentToken
        },
        @"time": timestamp,
        @"sign": @""
    };
    
    [self postRequestToURL:url params:params completion:^(BOOL success, NSString *msg, NSDictionary *data) {
        NSLog(@"[NetworkManager] Heartbeat sent. Success: %d, Msg: %@", success, msg);
        
        if (!success) {
            // Heartbeat failed - Force Exit
            dispatch_async(dispatch_get_main_queue(), ^{
                // Use keyWindow safely (though deprecated) or windows.firstObject for dylib context where specific scene is unknown
                UIWindow *keyWindow = nil;
                if (@available(iOS 13.0, *)) {
                     // Try to find a window from connected scenes
                     for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                         if (scene.activationState == UISceneActivationStateForegroundActive) {
                             // Use first matching window
                             for (UIWindow *win in scene.windows) {
                                 if (win.isKeyWindow) {
                                     keyWindow = win;
                                     break;
                                 }
                             }
                         }
                         if (keyWindow) break;
                     }
                }
                
                // Fallback for older iOS or if scene logic fails
                if (!keyWindow) {
                    keyWindow = [UIApplication sharedApplication].keyWindow;
                }
                
                UIViewController *rootVC = keyWindow.rootViewController;
                if (rootVC) {
                    // Start from rootVC and find top presented VC to present alert
                    while (rootVC.presentedViewController) {
                        rootVC = rootVC.presentedViewController;
                    }
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"验证失败" message:@"心跳验证失败，请重新登录" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        exit(0);
                    }]];
                    [rootVC presentViewController:alert animated:YES completion:nil];
                } else {
                    exit(0);
                }
            });
        }
    }];
}

- (void)trialLoginWithDeviceID:(NSString *)deviceID completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/trialLogin", API_BASE_URL]; 
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *params = @{
        @"app_id": APP_ID,
        @"data": @{
            @"markcode": deviceID
        },
        @"time": timestamp,
        @"sign": @""
    };
    
    [self postRequestToURL:url params:params completion:completion];
}

- (void)cardLoginWithCard:(NSString *)card deviceID:(NSString *)deviceID completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/cardLogin", API_BASE_URL];
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *params = @{
        @"app_id": APP_ID,
        @"data": @{
            @"card": card ?: @"",
            @"markcode": deviceID
        },
        @"time": timestamp,
        @"sign": @""
    };
    
    [self postRequestToURL:url params:params completion:completion];
}

- (void)queryCard:(NSString *)card completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/chk", API_BASE_URL]; 
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *params = @{
        @"app_id": APP_ID,
        @"data": @{
            @"card": card ?: @""
        },
        @"time": timestamp,
        @"sign": @""
    };
    [self postRequestToURL:url params:params completion:completion];
}

- (void)unbindCard:(NSString *)card deviceID:(NSString *)deviceID token:(NSString *)token completion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/cardUnbind", API_BASE_URL];
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *params = @{
        @"app_id": APP_ID,
        @"data": @{
            @"card": card ?: @"",
            @"markcode": deviceID,
            @"token": token ?: @""
        },
        @"time": timestamp,
        @"sign": @""
    };
    [self postRequestToURL:url params:params completion:completion];
}

- (void)getAppConfigWithCompletion:(void(^)(BOOL success, NSString *msg, NSDictionary *data))completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/getAppConfig", API_BASE_URL];
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *params = @{
        @"app_id": APP_ID,
        @"data": @{},
        @"time": timestamp,
        @"sign": @""
    };
    [self postRequestToURL:url params:params completion:completion];
}

#pragma mark - Debug Helper

- (void)showDebugAlert:(NSString *)title content:(NSString *)content {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
         for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
             if (scene.activationState == UISceneActivationStateForegroundActive) {
                 for (UIWindow *win in scene.windows) {
                     if (win.isKeyWindow) {
                         keyWindow = win;
                         break;
                     }
                 }
             }
             if (keyWindow) break;
         }
    }
    if (!keyWindow) keyWindow = [UIApplication sharedApplication].keyWindow;
    
    UIViewController *rootVC = keyWindow.rootViewController;
    if (rootVC) {
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
             [UIPasteboard generalPasteboard].string = content;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [rootVC presentViewController:alert animated:YES completion:nil];
    }
}

@end


