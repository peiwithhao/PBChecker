TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
export THEOS_DEVICE_IP=localhost
export THEOS_DEVICE_PORT=2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = testTweak

testTweak_FILES = Tweak.x
testTweak_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

