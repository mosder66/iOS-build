#ifndef Config_h
#define Config_h

// 默认配置 (可通过编译参数覆写)

// API 域名
#ifndef API_BASE_URL
#define API_BASE_URL @"https://shop.apiy.me"
#endif

// 统一 App ID (用于所有接口：登录、心跳、配置)
#ifndef APP_ID
#define APP_ID @"1"
#endif



// App Secret (用于数据加密)
#ifndef APP_SECRET
#define APP_SECRET @"123456"
#endif

// 加密方式: 0=明文, 1=RC4, 2=RSA
#ifndef ENCRYPTION_METHOD
#define ENCRYPTION_METHOD 1
#endif



#endif /* Config_h */
