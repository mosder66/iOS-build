#import "ActivationViewController.h"
#import "../Utils/DeviceUtils.h"
#import "../Managers/NetworkManager.h"

@interface ActivationViewController ()
@property (nonatomic, strong) UITextField *cardField;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subDescLabel;
@property (nonatomic, strong) UIButton *trialBtn;
@property (nonatomic, strong) UIButton *loginBtn;
@property (nonatomic, strong) UIButton *queryBtn;
@property (nonatomic, strong) UIButton *unbindBtn;
@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, strong) UIImageView *iconImg;
@end

@implementation ActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Background (Dark overlay)
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    
    // Main Panel (White, Rounded)
    CGFloat panelWidth = 300;
    CGFloat panelHeight = 280; // 调整高度以适应紧凑布局
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelWidth, panelHeight)];
    panel.center = self.view.center;
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 16;
    panel.layer.masksToBounds = NO; // Allow icon to overflow
    [self.view addSubview:panel];
    
    // Top Icon (Blue Circle with Icon)
    CGFloat iconSize = 60;
    UIView *iconBg = [[UIView alloc] initWithFrame:CGRectMake((panelWidth - iconSize)/2, -iconSize/2, iconSize, iconSize)];
    iconBg.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0]; // Light Blue
    iconBg.layer.cornerRadius = iconSize/2;
    iconBg.layer.borderWidth = 3;
    iconBg.layer.borderColor = [UIColor whiteColor].CGColor;
    iconBg.layer.masksToBounds = YES;
    
    // Icon Image (Touch/Hand icon)
    self.iconImg = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
    // Using system image if available (iOS 13+), or simple placeholder
    if (@available(iOS 13.0, *)) {
        self.iconImg.image = [UIImage systemImageNamed:@"hand.tap.fill"];
        self.iconImg.tintColor = [UIColor whiteColor];
    } else {
        // Fallback for older iOS or if system icon not found
        self.iconImg.backgroundColor = [UIColor whiteColor]; 
    }
    [iconBg addSubview:self.iconImg];
    [panel addSubview:iconBg];
    
    CGFloat yOffset = iconSize/2 + 20; // Start below icon
    
    // Title "激活验证"
    // Title "激活验证"
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, panelWidth, 24)];
    self.titleLabel.text = @"激活验证";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = [UIColor blackColor];
    [panel addSubview:self.titleLabel];
    yOffset += 30;
    
    // Subtitle "请输入您的激活码..."
    // Subtitle "请输入您的激活码..."
    self.subDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, panelWidth-40, 40)];
    self.subDescLabel.text = @"请输入您的激活码以继续使用完整功能";
    self.subDescLabel.textAlignment = NSTextAlignmentCenter;
    self.subDescLabel.textColor = [UIColor grayColor];
    self.subDescLabel.font = [UIFont systemFontOfSize:13];
    self.subDescLabel.numberOfLines = 0;
    [panel addSubview:self.subDescLabel];
    yOffset += 50;
    
    // Input Field
    self.cardField = [[UITextField alloc] initWithFrame:CGRectMake(20, yOffset, panelWidth-40, 40)];
    self.cardField.borderStyle = UITextBorderStyleNone;
    self.cardField.layer.borderWidth = 1;
    self.cardField.layer.borderColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor; // Blue border
    self.cardField.layer.cornerRadius = 8;
    self.cardField.placeholder = @"请输入激活码";
    self.cardField.textAlignment = NSTextAlignmentCenter;
    self.cardField.font = [UIFont systemFontOfSize:14];
    
    // Load saved card
    NSString *savedCard = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedCardCode"];
    if (savedCard) {
        self.cardField.text = savedCard;
    }
    
    [panel addSubview:self.cardField];
    yOffset += 50;
    
    // Buttons Grid
    // Rule: "One row two buttons, Trial, Login, Query, Unbind"
    
    self.panelView = panel; // Store reference
    
    // Create Buttons (Frames will be set in updateButtonLayout)
    self.trialBtn = [self createButtonWithTitle:@"试用" color:[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0] action:@selector(onTrial)];
    [panel addSubview:self.trialBtn];
    
    self.loginBtn = [self createButtonWithTitle:@"登录" color:[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0] action:@selector(onCardLogin)];
    [panel addSubview:self.loginBtn];
    
    self.queryBtn = [self createButtonWithTitle:@"查询" color:[UIColor darkGrayColor] action:@selector(onQuery)];
    [panel addSubview:self.queryBtn];
    
    self.unbindBtn = [self createButtonWithTitle:@"解绑" color:[UIColor redColor] action:@selector(onUnbind)];
    [panel addSubview:self.unbindBtn];
    
    // Initial Layout
    [self updateButtonLayout];
    
    // Tap to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // Status Label
    // Position will be updated in updateButtonLayout, here just add it
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:10];
    [panel addSubview:self.statusLabel];
    
    // Fetch App Config
    [self loadAppConfig];
}

- (void)updateButtonLayout {
    CGFloat panelWidth = self.panelView.bounds.size.width;
    // Base Y offset for buttons (Title + Subtitle + InputField + Spacing)
    // Icon(60/2) + 20 + Title(24) + 30 + SubTitle(40) + 50 + Input(40) + 50 = Approx 30 + 20 + 24 + 30 + 40 + 50 + 40 + 50 = 284?
    // Let's recalculate based on viewDidLoad
    // iconSize=60. iconBg y = -30.
    // yOffset starts at 30 + 20 = 50.
    // Title y = 50. Height 24.
    // yOffset += 30 -> 80.
    // SubTitle y = 80. Height 40.
    // yOffset += 50 -> 130.
    // Input y = 130. Height 40.
    // yOffset += 50 -> 180.
    CGFloat startY = 180;
    
    NSMutableArray *visibleBtns = [NSMutableArray array];
    if (!self.trialBtn.hidden) [visibleBtns addObject:self.trialBtn];
    [visibleBtns addObject:self.loginBtn];
    [visibleBtns addObject:self.queryBtn];
    [visibleBtns addObject:self.unbindBtn];
    
    NSInteger count = visibleBtns.count;
    CGFloat btnSpacing = 10;
    CGFloat margin = 20;
    CGFloat btnHeight = 35;
    CGFloat currentY = startY;
    
    for (NSInteger i = 0; i < count; i++) {
        UIButton *btn = visibleBtns[i];
        
        // Single column (full width) if it's the last one and total count is odd
        if (i == count - 1 && count % 2 != 0) {
            btn.frame = CGRectMake(margin, currentY, panelWidth - 2 * margin, btnHeight);
            currentY += btnHeight + btnSpacing;
        } else {
            // Two column layout
            // Determine if left or right
            // If we are in "pair" mode
            // We need to know if this is the start of a pair or end
            // Since we might have mixed rows, let's look at index
            
            // Logic:
            // If remaining items >= 2, place 2 items in this row
            // If remaining items == 1, place 1 item (handled by 'last one' logic above effectively?)
            // Actually, the simple logic "if even, 2 per row" works.
            // But if total is odd, the last one is alone. The preceding ones are in pairs.
            
            // Wait, if i is even, it's the left button
            // If i is odd, it's the right button
            // But we must respect the "last one is alone" rule
            
            // Correct Logic:
            // Iterate in steps of 2? No, iteration is linear.
            
            BOOL isLast = (i == count - 1);
            if (isLast && count % 2 != 0) {
                 // Should be caught by first if
                 btn.frame = CGRectMake(margin, currentY, panelWidth - 2 * margin, btnHeight);
                 currentY += btnHeight + btnSpacing;
            } else {
                 // It's part of a pair
                 CGFloat btnWidth = (panelWidth - 2 * margin - btnSpacing) / 2;
                 if (i % 2 == 0) {
                     // Left
                     btn.frame = CGRectMake(margin, currentY, btnWidth, btnHeight);
                     // Don't increase Y yet
                 } else {
                     // Right
                     btn.frame = CGRectMake(margin + btnWidth + btnSpacing, currentY, btnWidth, btnHeight);
                     currentY += btnHeight + btnSpacing;
                 }
            }
        }
    }
    
    // Adjust Panel Height
    // Add extra padding
    currentY += 10; 
    
    // Status Label
    self.statusLabel.frame = CGRectMake(0, currentY, panelWidth, 12);
    currentY += 20;
    
    CGRect frame = self.panelView.frame;
    frame.size.height = currentY;
    self.panelView.frame = frame;
    self.panelView.center = self.view.center;
}

- (UIButton *)createButtonWithTitle:(NSString *)title color:(UIColor *)color action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 6;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Actions

- (void)onTrial {
    NSString *uuid = [DeviceUtils getDeviceUUID];
    [self showStatus:@"正在请求试用..." color:[UIColor blueColor]]; // Keep status for progress
    
    [[NetworkManager sharedManager] trialLoginWithDeviceID:uuid completion:^(BOOL success, NSString *msg, NSDictionary *data) {
        if (success) {
            [self handleSuccess:data msg:msg];
        } else {
            [self showAlert:@"试用失败" msg:msg];
            [self showStatus:@"" color:[UIColor clearColor]];
        }
    }];
}

- (void)onCardLogin {
    NSString *card = self.cardField.text;
    if (!card || card.length == 0) {
        [self showAlert:@"错误" msg:@"请输入卡密"];
        return;
    }
    NSString *uuid = [DeviceUtils getDeviceUUID];
    [self showStatus:@"正在登录..." color:[UIColor blueColor]]; // Keep status for progress
    
    [[NetworkManager sharedManager] cardLoginWithCard:card deviceID:uuid completion:^(BOOL success, NSString *msg, NSDictionary *data) {
        if (success) {
            [self handleSuccess:data msg:msg];
        } else {
            [self showAlert:@"登录失败" msg:msg];
            [self showStatus:@"" color:[UIColor clearColor]];
        }
    }];
}

- (void)onQuery {
    NSString *card = self.cardField.text;
    if (!card || card.length == 0) {
         [self showAlert:@"错误" msg:@"请输入卡密以查询"];
        return;
    }
    [self showStatus:@"正在查询..." color:[UIColor grayColor]];
    
    [[NetworkManager sharedManager] queryCard:card completion:^(BOOL success, NSString *msg, NSDictionary *data) {
        [self showAlert:success ? @"查询成功" : @"查询失败" msg:msg];
        [self showStatus:@"" color:[UIColor whiteColor]];
    }];
}

- (void)onUnbind {
    NSString *card = self.cardField.text;
    if (!card || card.length == 0) {
        [self showAlert:@"错误" msg:@"请输入卡密以解绑"];
        return;
    }
    NSString *uuid = [DeviceUtils getDeviceUUID];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedToken"];
    
    if (!token || token.length == 0) {
       // Optional: Prompt user to login first, or just proceed with empty token if expected
       // [self showAlert:@"提示" msg:@"请先登录以获取授权"];
       // return;
    }

    [self showStatus:@"正在解绑..." color:[UIColor redColor]];
    
    [[NetworkManager sharedManager] unbindCard:card deviceID:uuid token:token completion:^(BOOL success, NSString *msg, NSDictionary *data) {
        [self showAlert:success ? @"解绑成功" : @"解绑失败" msg:msg];
        [self showStatus:@"" color:[UIColor whiteColor]];
        if (success) {
            // Clear token on Unbind? Maybe.
            // [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SavedToken"];
        }
    }];
}



- (void)loadAppConfig {
    [[NetworkManager sharedManager] getAppConfigWithCompletion:^(BOOL success, NSString *msg, NSDictionary *data) {
        if (success && data) {
            // Check App Status
            NSString *appStatus = [NSString stringWithFormat:@"%@", data[@"status"]];
            if ([appStatus isEqualToString:@"0"]) {
                // App is disabled
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"软件已关闭，请联系管理员" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    exit(0);
                }]];
                [self presentViewController:alert animated:YES completion:nil];
                return; // Stop processing
            }

            // Update UI
            NSString *appName = data[@"name"];
            NSString *desc = data[@"description"];
            NSString *iconUrl = data[@"icon"];
            NSString *trialStatus = [NSString stringWithFormat:@"%@", data[@"trialStatus"]];
            
            if (appName && [appName isKindOfClass:[NSString class]] && appName.length > 0) {
                self.titleLabel.text = appName;
            }
            
            if (desc && [desc isKindOfClass:[NSString class]] && desc.length > 0) {
                self.subDescLabel.text = desc;
            }
            
            // Load Icon asynchronously if URL exists
            if (iconUrl && [iconUrl isKindOfClass:[NSString class]] && iconUrl.length > 0) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:iconUrl]];
                    if (imgData) {
                        UIImage *image = [UIImage imageWithData:imgData];
                        if (image) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.iconImg.image = image;
                                // Reset tint color if it was set for template image
                                self.iconImg.tintColor = nil; 
                            });
                        }
                    }
                });
            }
            
            // Trial Status: "1" = Open, "0" = Closed
            if ([trialStatus isEqualToString:@"0"]) {
                self.trialBtn.hidden = YES;
            } else {
                self.trialBtn.hidden = NO;
            }
            
            // Update Layout
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateButtonLayout];
            });
        }
    }];
}

#pragma mark - Helpers

- (void)handleSuccess:(NSDictionary *)data msg:(NSString *)msg {
    @try {
        // Safe check for data type
        if (!data || ![data isKindOfClass:[NSDictionary class]]) {
            [self showAlert:@"错误" msg:@"服务器返回数据格式异常"];
            [self showStatus:@"" color:[UIColor clearColor]];
            return;
        }
    
        // Update Status immediately
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showStatus:@"验证成功，即将进入..." color:[UIColor greenColor]];
        });
        
        // Save Card
        if (self.cardField.text.length > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:self.cardField.text forKey:@"SavedCardCode"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        // Save Token
        id tokenObj = data[@"token"];
        if (tokenObj && [tokenObj isKindOfClass:[NSString class]] && ((NSString *)tokenObj).length > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:tokenObj forKey:@"SavedToken"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        // Start Heartbeat
        NSString *card = self.cardField.text ?: @"";
        NSString *uuid = [DeviceUtils getDeviceUUID];
        NSString *token = [tokenObj isKindOfClass:[NSString class]] ? tokenObj : @"";
        [[NetworkManager sharedManager] startHeartbeatWithCard:card deviceID:uuid token:token];
        
        // Dismiss Self with Delay
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            // Dismiss Logic: Try presentingViewController first (to dismiss self + children)
            UIViewController *target = self.presentingViewController ? self.presentingViewController : self;
            [target dismissViewControllerAnimated:YES completion:nil];
        });
        
    } @catch (NSException *exception) {
        NSLog(@"[ActivationVC] HandleSuccess Exception: %@", exception);
        [self showAlert:@"异常" msg:@"处理登录响应时发生错误"];
    }
}

- (void)showStatus:(NSString *)text color:(UIColor *)color {
    self.statusLabel.text = text;
    self.statusLabel.textColor = color;
}

- (void)showAlert:(NSString *)title msg:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
