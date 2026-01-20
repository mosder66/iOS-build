#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Hook UIApplication 的启动方法
%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    %orig;
    
    // 延迟显示弹窗，确保应用完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showAlertDialog];
    });
    
    return YES;
}

%new
- (void)showAlertDialog {
    // 获取当前的根视图控制器
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    // 如果根视图控制器正在呈现其他控制器，获取最顶层的控制器
    while (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    }
    
    // 创建 Alert 控制器
    UIAlertController *alertController = [UIAlertController 
        alertControllerWithTitle:@"欢迎"
        message:@"应用已启动！这是一个由 dylib 注入的弹窗。"
        preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加"确定"按钮
    UIAlertAction *okAction = [UIAlertAction 
        actionWithTitle:@"确定" 
        style:UIAlertActionStyleDefault 
        handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"[Alert] 用户点击了确定按钮");
        }];
    
    // 添加"取消"按钮
    UIAlertAction *cancelAction = [UIAlertAction 
        actionWithTitle:@"取消" 
        style:UIAlertActionStyleCancel 
        handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"[Alert] 用户点击了取消按钮");
        }];
    
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    // 显示弹窗
    if (rootViewController) {
        [rootViewController presentViewController:alertController animated:YES completion:^{
            NSLog(@"[Alert] 弹窗已显示");
        }];
    } else {
        NSLog(@"[Alert] 警告：无法获取根视图控制器");
    }
}

%end

// 构造函数 - dylib 加载时自动执行
%ctor {
    NSLog(@"[Alert] Alert dylib 已加载");
}
