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

# Vendor public libraries: the stock list plus libwfo_jni.so for the IMS service.
# Keep above the vendor inherit: the first PRODUCT_COPY_FILES entry for a path wins.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/public.libraries-vendor.txt:$(TARGET_COPY_OUT_VENDOR)/etc/public.libraries.txt

# A-GPS: stock profile list with the default SUPL server switched to
# supl.google.com; same first-entry-wins rule.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/agps_profiles_conf2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/agps_profiles_conf2.xml

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

# RIL: our libril is also built as librilmtk.so, the soname mtk-ril.so needs,
# so vendor responses bind to our request list. librilimp is the stock MTK
# libril, renamed. Requires BOARD_USES_MTK_LEGACY_RIL (see BoardConfig.mk).
PRODUCT_PACKAGES += \
    librilmtk

# libstdc++ as a vendor copy: the 32-bit Mali closure needs it and it is
# neither LLNDK nor VNDK.
PRODUCT_PACKAGES += \
    libstdc++.vendor

# Vendor variants of non-VNDK framework libraries used by the N blobs.
# libgui_m95/libsensor_m95 are forwarders with DT_NEEDED on the real library.
PRODUCT_PACKAGES += \
    libgui_vendor \
    libsensor_vendor \
    libgui_m95 \
    libsensor_m95

# Vendor libcamera_client: the camera HAL1 blobs need it and A13 builds it
# only for /system.
PRODUCT_PACKAGES += \
    libcamera_client_vendor

# Shims
PRODUCT_PACKAGES += \
    libm95shim_gui \
    libm95shim_power \
    libm95shim_audioutils \
    libm95shim_ui \
    libm95shim_utils \
    libm95shim_sf \
    libm95shim_nparcel \
    libm95shim_net \
    libm95shim_netd_client \
    libm95shim_region \
    libm95shim_fs_mgr \
    libm95shim_skia \
    libm95shim_camera_client \
    libm95shim_media \
    libm95shim_mediautils \
    libm95shim_android_runtime \
    libm95shim_icuuc \
    libm95shim_icui18n \
    libm95shim_android \
    libm95shim_drmframework \
    libm95shim_stagefright \
    libm95shim_jnigraphics \
    libm95shim_btvendor \
    libm95shim_ssl \
    libm95shim_mnld \
    libm95shim_perfservice \
    libm95probe

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

# Camera: RAW16 for the rear sensor and 4:3 viewfinder sizes. The 32-bit
# provider loads it via TARGET_LD_SHIM_LIBS and cannot link without it.
# Runtime toggles: persist.camera.raw / persist.camera.preview_43.
PRODUCT_PACKAGES += \
    libm95_camera_metadata_raw

# VoLTE log filter, opt-in: M95_VOLTE_LOGFILTER=true.
ifeq ($(M95_VOLTE_LOGFILTER),true)
PRODUCT_PACKAGES += \
    libm95volte_logfilter
endif

# Google Camera as the default camera. The APKs are not in git: run
# gcam/fetch-gcam.sh once, or build with M95_WITHOUT_GCAM=true.
ifneq ($(M95_WITHOUT_GCAM),true)
  ifneq ($(words $(wildcard \
          $(LOCAL_PATH)/gcam/MGC_8.9.097_A11_V25_MGC.apk \
          $(LOCAL_PATH)/gcam/GcamServicesProvider-1.6.1-photos.apk \
          $(LOCAL_PATH)/gcam/.fetched)),3)
    $(error m95: Google Camera is not in $(LOCAL_PATH)/gcam; run $(LOCAL_PATH)/gcam/fetch-gcam.sh, or build with M95_WITHOUT_GCAM=true)
  endif
  PRODUCT_PACKAGES += \
      MGC_8_9_097 \
      GcamServicesProvider
  DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay-gcam
endif

# Gatekeeper: AOSP software implementation; the vendor blob needs the N-era
# libgatekeeper ABI. Existing lock credentials will not verify after switching.
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software

# Fingerprint: device copy of the LineageOS @2.0 service, adapted to the
# vendor blob's larger device struct and missing enumerate.
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.0-service.m95

# TFA98xx speaker DSP firmware; sensors multi-HAL list (hals.conf).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/tfa98xx.cnt:$(TARGET_COPY_OUT_VENDOR)/firmware/tfa98xx.cnt \
    $(LOCAL_PATH)/prebuilt/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/hals.conf

# Wi-Fi
PRODUCT_PACKAGES += \
    lib_driver_cmd_mt66xx \
    libwifi-hal-mt66xx \
    hostapd \
    wificond \
    wpa_supplicant \
    libwpa_client

# Hotspot: ap0 as a tetherable interface, no randomized AP BSSID.
PRODUCT_PACKAGES += \
    M95TetheringConfigOverlay \
    M95WifiOverlay

PRODUCT_COPY_FILES += \
    external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant_template.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf

# FM radio
# The kernel opens the mt6631 DSP patch by absolute path under /system/etc/firmware.
PRODUCT_PACKAGES += \
    FMRadio

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

# Privapp permissions for the IMS service: required with
# ro.control_privapp_permissions=enforce.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/permissions/privapp-permissions-com.mediatek.ims.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-com.mediatek.ims.xml

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

# Seccomp: additional mediacodec policy for the MTK video encoders.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/seccomp/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy

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

# Vendor copies of VNDK-core libraries for the sphal namespace
# (needed by the Mali blob chain).
PRODUCT_COPY_FILES += \
    vendor/meizu/m95/proprietary/vendor/lib64/libnetutils.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libnetutils.so \
    vendor/meizu/m95/proprietary/vendor/lib/libnetutils.so:$(TARGET_COPY_OUT_VENDOR)/lib/libnetutils.so

# Power
# AIDL Power HAL; power-fleet/ is a vendored copy, do not edit it here.
PRODUCT_PACKAGES += \
    android.hardware.power-service.meizu
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/power/fleet_power.json:$(TARGET_COPY_OUT_VENDOR)/etc/power/fleet_power.json
