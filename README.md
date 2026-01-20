# ios-alert-dylib

这是一个用 C/C++ (Objective-C) 编写的 iOS 动态库 (dylib) 示例，启动后弹出一个原生弹窗。

## 目录结构

```
ios-alert-dylib/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions 自动编译
├── src/
│   ├── main.m                 # 弹窗实现代码
│   └── Makefile               # 编译配置
├── inject_sign.sh             # 注入+签名脚本
├── Info.plist                 # dylib 信息（可选）
└── README.md
```

## 编译

建议在 macOS 或 WSL 下，需安装 Xcode 命令行工具或 iOS 交叉编译工具链。

```bash
cd src
make clean
make
```

## 注入与签名

使用 inject_sign.sh 脚本将 dylib 注入到 app 并签名。

```bash
./inject_sign.sh <app_path> <dylib_path>
```

## 自动化编译

可参考 .github/workflows/build.yml 配置 GitHub Actions 自动编译。

## 说明
- main.m 采用 C/Objective-C 编写，兼容 C++
- 仅供学习研究，勿用于非法用途

- 弹窗的标题和内容
- 按钮文本
- 显示延迟时间
- Hook 的目标应用

## 指定特定应用

如果你只想在特定应用中显示弹窗，可以创建一个 `AlertTweak.plist` 文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Filter</key>
    <dict>
        <key>Bundles</key>
        <array>
            <string>com.apple.mobilesafari</string>
        </array>
    </dict>
</dict>
</plist>
```

将此文件放在 `/Library/MobileSubstrate/DynamicLibraries/` 目录下。

## 日志

使用以下命令查看日志输出：

```bash
# 在 iOS 设备上
tail -f /var/log/syslog | grep Alert
```

或使用 Console.app 在 Mac 上查看连接设备的日志。

## 许可证

MIT License

## 注意事项

- 此项目仅用于学习和研究目的
- 需要越狱的 iOS 设备才能运行
- 请遵守相关法律法规
