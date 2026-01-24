TARGET = ios
ARCHS = arm64
SDK = iphoneos
CC = clang
CFLAGS = -fobjc-arc -framework UIKit -isysroot $(shell xcrun --sdk $(SDK) --show-sdk-path) -arch $(ARCHS) -dynamiclib

# Source files
SRCS = main.m $(wildcard Managers/*.m) $(wildcard UI/*.m) $(wildcard Utils/*.m)

all: libinject.dylib

libinject.dylib: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f libalert.dylib
	rm -f libinject.dylib
