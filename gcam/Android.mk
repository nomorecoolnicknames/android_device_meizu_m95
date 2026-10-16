#
# Google Camera as the MX6's default camera: BSG's MGC 8.9.097 V25 and the
# GServices shim it cannot start without on a phone with no GMS, preinstalled
# on /product. Neither APK is in git; fetch-gcam.sh puts them here, checked
# against pinned sha256, together with the camera's unpacked JNI libraries.
# device.mk includes them only with M95_WITH_GCAM=true.
#
# Both APKs are installed unmodified: the camera is signed with the v3 scheme
# only, and the prebuilt path would otherwise store its JNI libraries
# uncompressed without re-signing. The libraries are installed separately to
# <app>/lib/arm64, as the package manager does not extract them for
# preinstalled apps. No dexpreopt; the <uses-library> check is off because the
# manifest lists optional libraries that do not exist here.
#

LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard $(LOCAL_PATH)/MGC_8.9.097_A11_V25_MGC.apk),)

include $(CLEAR_VARS)
LOCAL_MODULE := MGC_8_9_097
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_SRC_FILES := MGC_8.9.097_A11_V25_MGC.apk
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/$(LOCAL_SRC_FILES)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRODUCT_MODULE := true
LOCAL_MULTILIB := 64
LOCAL_PREBUILT_JNI_LIBS := \
    $(patsubst $(LOCAL_PATH)/%,%,$(wildcard $(LOCAL_PATH)/lib/arm64/*.so))
LOCAL_DEX_PREOPT := false
LOCAL_ENFORCE_USES_LIBRARIES := false
include $(BUILD_PREBUILT)

endif

# Gcam Services Provider, Google Photos flavour: answers the GServices lookup
# and handles the review intent the camera sends to Google Photos by package
# name. As a system package under that name it cannot be removed, and the real
# Google Photos will not install over it; use the basic flavour
# (de.lukaspieper.gcam.services) if that matters.
ifneq ($(wildcard $(LOCAL_PATH)/GcamServicesProvider-1.6.1-photos.apk),)

include $(CLEAR_VARS)
LOCAL_MODULE := GcamServicesProvider
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_SRC_FILES := GcamServicesProvider-1.6.1-photos.apk
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/$(LOCAL_SRC_FILES)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRODUCT_MODULE := true
LOCAL_DEX_PREOPT := false
LOCAL_ENFORCE_USES_LIBRARIES := false
include $(BUILD_PREBUILT)

endif
