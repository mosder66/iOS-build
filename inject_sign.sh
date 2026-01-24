#!/bin/bash
# 用于注入和签名 dylib 的脚本
# 用法: ./inject_sign.sh <app_path> <dylib_path>

APP_PATH="$1"
DYLIB_PATH="$2"

if [ -z "$APP_PATH" ] || [ -z "$DYLIB_PATH" ]; then
  echo "Usage: $0 <app_path> <dylib_path>"
  exit 1
fi

# 注入 dylib
optool install -c load -p "@executable_path/$(basename $DYLIB_PATH)" -t "$APP_PATH/$(basename $APP_PATH)"

# 拷贝 dylib 到 app 目录
cp "$DYLIB_PATH" "$APP_PATH/"

# 重新签名
codesign -fs "SignCert" --entitlements "$APP_PATH/archived-expanded-entitlements.xcent" "$APP_PATH/$(basename $DYLIB_PATH)"
codesign -fs "SignCert" --entitlements "$APP_PATH/archived-expanded-entitlements.xcent" "$APP_PATH/$(basename $APP_PATH)"
