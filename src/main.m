#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UI/ActivationViewController.h"

// 构造函数 - dylib 加载时自动执行
__attribute__((constructor)) static void customConstructor() {
    NSLog(@"[Alert] Dylib Injected");
    
    // 延迟执行以等待 UI 准备就绪
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        // 如果 deprecated warning 很烦，可以换用 windows.firstObject 等方式，但 keyWindow 在越狱开发常用的旧环境下通常没问题
        if (!keyWindow) {
            // 尝试遍历 windows
            for (UIWindow *win in [UIApplication sharedApplication].windows) {
                if (win.isKeyWindow) {
                    keyWindow = win;
                    break;
                }
            }
        }
        
        if (!keyWindow) return;
        
        UIViewController *rootVC = keyWindow.rootViewController;
        // 获取最顶层 VC
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        
        if (rootVC) {
            ActivationViewController *vc = [[ActivationViewController alloc] init];
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [rootVC presentViewController:vc animated:YES completion:nil];
        }
    });
}