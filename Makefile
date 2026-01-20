TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = SpringBoard

# 包含 theos 框架
include $(THEOS)/makefiles/common.mk

# Tweak 配置
TWEAK_NAME = AlertTweak

# 源文件
AlertTweak_FILES = Tweak.x

# 链接的框架
AlertTweak_FRAMEWORKS = UIKit Foundation

# 安装路径
AlertTweak_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

# 架构支持
ARCHS = arm64 arm64e

# 包含 tweak 的 makefile
include $(THEOS_MAKE_PATH)/tweak.mk
