#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/meizu/m95

# Soong namespaces
# Soong parses every Android.bp in the workspace with no TARGET_DEVICE guard;
# namespaced modules reach Make only for products that list the namespace here.
PRODUCT_SOONG_NAMESPACES += \
    device/meizu/m95 \
    vendor/meizu/m95

# VNDK
# Ship the v30 VNDK apex next to the current one, so a vendor image built
# with ro.vndk.version=30 still boots (as the Android 13 GSI does).
PRODUCT_EXTRA_VNDK_VERSIONS := 30

# Audio effects: without a vendor audio_effects.xml the effects factory falls
# back to /system/etc/audio_effects.conf, which a vendor HAL may not read.
PRODUCT_COPY_FILES += \
    frameworks/av/media/libeffects/data/audio_effects.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.conf

# Vendor blobs
$(call inherit-product, vendor/meizu/m95/m95-vendor.mk)
$(call inherit-product, vendor/meizu/m95/m95-vendor-extra.mk)

# Vendor prebuilt modules
PRODUCT_PACKAGES += \
    vulkan.mt6797_symlinks \
    librilimp

# Flyme system libraries are not shipped; re-add together with the camera apps.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/public.libraries-meizu.txt:$(TARGET_COPY_OUT_SYSTEM)/etc/public.libraries-meizu.txt

PRODUCT_DEVICE := m95

# Overridden by product_launched_with_n_mr1.mk, inherited later from
# lineage_m95.mk; the effective value is 25.
PRODUCT_SHIPPING_API_LEVEL := 30

# Ramdisk
# The ueventd graphics/input subsystem blocks are required for display and touch.
PRODUCT_PACKAGES += \
    fstab.mt6797 \
    fstab.mt6797.ramdisk \
    ueventd.mt6797.rc \
    ueventd.mt6797.ramdisk.rc \
    init.mt6797.rc \
    init.mt6797.usb.rc \
    init.m95.modem.rc \
    init.m95.connectivity.rc \
    init.m95.tee.rc \
    init.m95.thermal.rc \
    init.m95.cpuset.rc \
    init.m95.powertrap.rc \
    init.m95.mem.rc \
    init.m95.power.rc \
    init.m95.sensors.rc \
    init.m95.volte.rc \
    goodixfpd.rc \
    m95-cpuset.sh \
    m95-perfprofile.sh \
    m95-powertrap.sh \
    m95-bdaddr.sh

# HIDL HALs
# Each passthrough *-service needs its *-impl.so in /vendor/lib{,64}/hw,
# otherwise it exits and restarts in a loop.
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl-2.1 \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    android.hardware.renderscript@1.0-impl \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service \
    android.hardware.light@2.0-impl \
    android.hardware.light@2.0-service \
    lights.mt6797 \
    android.hardware.vibrator@1.0-impl \
    android.hardware.vibrator@1.0-service \
    android.hardware.thermal@2.0-service.m95 \
    android.hardware.ir@1.0-impl \
    android.hardware.ir@1.0-service \
    libtinycompress \
    android.hardware.audio@2.0-impl \
    android.hardware.audio@2.0-service \
    android.hardware.audio.effect@2.0-impl \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    audio.r_submix.default \
    audio.usb.default \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \
    android.hardware.drm@1.4-service.clearkey \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    android.hardware.sensors@1.0-impl \
    android.hardware.sensors@1.0-service \
    android.hardware.wifi@1.0-service \
    android.hardware.bluetooth@1.0-impl \
    android.hardware.bluetooth@1.0-service

# Gatekeeper: AOSP software implementation; the vendor blob needs the N-era
# libgatekeeper ABI. Existing lock credentials will not verify after switching.
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software

# TFA98xx speaker DSP firmware; sensors multi-HAL list (hals.conf).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/tfa98xx.cnt:$(TARGET_COPY_OUT_VENDOR)/firmware/tfa98xx.cnt \
    $(LOCAL_PATH)/prebuilt/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/hals.conf

# Hotspot: ap0 as a tetherable interface, no randomized AP BSSID.
PRODUCT_PACKAGES += \
    M95TetheringConfigOverlay \
    M95WifiOverlay

PRODUCT_COPY_FILES += \
    external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant_template.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf

# Keylayouts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/ACCDET.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/ACCDET.kl \
    $(LOCAL_PATH)/keylayout/fp-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/fp-keys.kl \
    $(LOCAL_PATH)/keylayout/mtk-kpd.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/mtk-kpd.kl

# Permissions
# android.hardware.telephony.ims is required for the ImsResolver to start.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.consumerir.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.consumerir.xml

# Media
# media_profiles.xml is installed as media_profiles_V1_0.xml, the default
# ro.media.xml_variant.profiles name.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    $(LOCAL_PATH)/media/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/media_codecs_mediatek_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_mediatek_audio.xml \
    $(LOCAL_PATH)/media/media_codecs_mediatek_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_mediatek_video.xml \
    $(LOCAL_PATH)/media/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    $(LOCAL_PATH)/media/media_codecs_google_video_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video_le.xml \
    $(LOCAL_PATH)/media/media_codecs_performance.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance.xml

# Audio
# Audio policy configuration converted from the stock audio_policy.conf.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml

# xi:include targets: copied rather than packaged, next to the including file.
AUDIO_POLICY_CFG_DIR := frameworks/av/services/audiopolicy/config
PRODUCT_COPY_FILES += \
    $(AUDIO_POLICY_CFG_DIR)/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml \
    $(AUDIO_POLICY_CFG_DIR)/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    $(AUDIO_POLICY_CFG_DIR)/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    $(AUDIO_POLICY_CFG_DIR)/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    $(AUDIO_POLICY_CFG_DIR)/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    $(AUDIO_POLICY_CFG_DIR)/surround_sound_configuration_5_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/surround_sound_configuration_5_0.xml

# ADB
# M95_ADB_KEYS: optional file of adb public keys installed as /adb_keys
# (eng/userdebug only); empty by default.
M95_ADB_KEYS ?=
ifneq ($(M95_ADB_KEYS),)
ifeq ($(wildcard $(M95_ADB_KEYS)),)
$(warning m95: M95_ADB_KEYS=$(M95_ADB_KEYS) does not exist -- no /adb_keys, every computer will be asked for on the screen)
else
PRODUCT_ADB_KEYS := $(M95_ADB_KEYS)
endif
endif

# M95_INSECURE_ADB=true: no adb authorization and a root shell.
# Development only; off by default.
M95_INSECURE_ADB ?= false
ifeq ($(M95_INSECURE_ADB),true)
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0
endif

