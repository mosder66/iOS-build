#import "DeviceUtils.h"

@implementation DeviceUtils

+ (NSString *)getDeviceUUID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

@end
