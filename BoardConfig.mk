#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/meizu/m95

# Build
# Duplicate install rules (N blobs vs AOSP default HAL modules at the same
# /vendor path) warn instead of failing the build.
BUILD_BROKEN_DUP_RULES := true

# Prebuilt modules of the N-era blobs have unresolvable DT_NEEDED entries.
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true

# The N-era ELF blobs are still installed via PRODUCT_COPY_FILES rather than
# as Soong prebuilt modules.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Architecture
# MT6797: 2x Cortex-A72 + 8x Cortex-A53, ARMv8.0-A without LSE atomics.
# Do not use ARMv8.1+ flags or newer CPU variants.
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53
TARGET_USES_64_BIT_BINDER := true

# Platform
TARGET_BOARD_PLATFORM := mt6797
TARGET_NO_BOOTLOADER := true
BOARD_VENDOR := meizu

# ---------------------------------------------------------------------------
# Kernel — PREBUILT, never rebuilt from this tree.
# ---------------------------------------------------------------------------
# prebuilt/Image.gz-dtb (since 2026-10-17, build 41) is the kernel that is on
# the phone: "Linux version 3.18.22-eng-g8a1c65d4 ... Fri Oct 16 23:36:58 MSK
# 2026", sha256 6a4581a760d8c205..., from ~/meizu-local-builds/
# mx6-kernel-restored-20261009 branch mx6-k41 @ 8a1c65d4 = charger-mx6
# f3649519 + b628fe26 (p2p wiphy glue, softAP panic) + 8a1c65d4 (RSN policy on
# the BSSID search path, H-W1). Config 7a748beb (= softap-rpfct: f14a9250 +
# IP{,6}_NF_MATCH_RPFILTER + NETFILTER_XT_TARGET_CT for tethering), DTB
# 31b6230f. Same tree as nomorecoolnicknames/android_kernel_meizu_m95
# lineage-20.0 (m95_defconfig = this config). Verified on the phone
# 2026-10-16/17 (the bring-up notes): boot f6416975 = this kernel over
# the ramdisk of boot 56e9001f; Wi-Fi 5/5 first-attempt joins.
# Before (2026-10-06 .. build 40): 1c4ce619 c3d605a9, config f14a9250 -- no
# RPFILTER/CT (softAP tethering failed), no b628fe26 (softAP panic).
# History: until 2026-10-06 this was kernel/m685 @ 78e751a9 an earlier build (sha256
# b84b732d...24da7e, copied from the LOS 18.1 build tree), which carried the
# eBPF, FFS-AIO and dm-bufio/mnt backports Android 13 needs; all of them are in
# the export line above.
# УСТАРЕЛО (2026-09-16): раньше здесь стояло «kernel/meizu/m95 намеренно
# отсутствует, поэтому kernel.mk берёт ветку прибилта». Это больше не так —
# исходник пришлось подключить ради generated_kernel_includes (см. ниже),
# а ветка прибилта теперь удерживается флагом TARGET_FORCE_PREBUILT_KERNEL.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_VERSION := 3.18
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb

# The kernel source is still needed for generated_kernel_includes
# (headers_install).
TARGET_KERNEL_SOURCE := kernel/meizu/m95
TARGET_KERNEL_CONFIG := m95_defconfig

# Do not add TARGET_KERNEL_ADDITIONAL_FLAGS for headers_install: it is read
# after the kernel make flags are exported to Soong and has no effect there.

# Use the prebuilt even though TARGET_KERNEL_SOURCE is set.
TARGET_FORCE_PREBUILT_KERNEL := true

# Boot image (header v0, no MTK header)
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_KERNEL_TAGS_OFFSET := 0x03f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_BOOT_HEADER_VERSION := 0
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.hardware=mt6797
BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --second_offset $(BOARD_SECOND_OFFSET) \
    --tags_offset $(BOARD_KERNEL_TAGS_OFFSET) \
    --header_version $(BOARD_BOOT_HEADER_VERSION)

# SELinux: ENFORCING since build 41 (no androidboot.selinux on the cmdline).
# Bring-up was permissive (16.0, 18.1, A13 builds 1..40) until the census was
# closed: census #7 (sepolicy 06a45b0) on build 40, then the same kernel and
# ramdisk booted enforcing on the phone (boot bd2ad754, 2026-10-17) and passed
# boot, Wi-Fi, BT, both cameras, video, audio, sensors, IMS, SMS in/out, USSD,
# VoLTE out and incoming ringing, softAP start (the bring-up notes).
# Back to permissive for a bring-up: add androidboot.selinux=permissive here.

# Turn off costly kernel debug features at boot (the prebuilt is built from a
# debug defconfig, and LK prepends slub_debug=O). Diagnostics only.
BOARD_KERNEL_CMDLINE += slub_debug=- lockdep.prove_locking=0 dma_debug=off trace_buf_size=1M

# Partitions
# A-only, no dynamic partitions. system was resized to 4 GiB.
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 31457280
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4294967296
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_VENDORIMAGE_PARTITION_SIZE := 536870912
BOARD_FLASH_BLOCK_SIZE := 131072
AB_OTA_UPDATER := false

# /vendor is a real partition: custom (mmcblk0p3, 512 MiB).
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

# A-only legacy layout with a real recovery partition.
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
BOARD_USES_RECOVERY_AS_BOOT := false
TARGET_NO_RECOVERY := false

# File systems
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/fstab.mt6797
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
BOARD_HAS_NO_SELECT_BUTTON := true

# Display
# 1080x1920. The kernel rotates the panel by 180 degrees in hardware; do not
# add a userspace rotation.
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_DENSITY := 480

# Treble
# Shipping API level is 25, below the level that enables Treble by itself.
PRODUCT_FULL_TREBLE_OVERRIDE := true

# VNDK
# BOARD_VNDK_VERSION := 30 does not work: vendor APEXes and vendor snapshot
# requirements break soong_build, so the vendor is built against the platform VNDK.
BOARD_VNDK_VERSION := current

# VNDK-lite no longer exists: libraries a vendor process needs from /system
# must be copied to /vendor, but never a VNDK library the vendor also uses.

# VINTF
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# Wi-Fi
BOARD_WLAN_DEVICE := MediaTek
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_STATE_CTRL_PARAM := /dev/wmtWifi
WIFI_DRIVER_STATE_ON := 1
WIFI_DRIVER_STATE_OFF := 0
# Hotspot: the Wi-Fi HAL switches firmware mode by writing these strings to
# /dev/wmtWifi ('A' = AP mode with ap0, 'S'/'P' = STA mode with p2p0).
WIFI_DRIVER_FW_PATH_PARAM := /dev/wmtWifi
WIFI_DRIVER_FW_PATH_STA := STA
WIFI_DRIVER_FW_PATH_AP := AP
WIFI_DRIVER_FW_PATH_P2P := P2P
# The driver rejects SIOCSIFHWADDR; a failed MAC change would leave wlan0 down.
WIFI_AVOID_IFACE_RESET_MAC_CHANGE := true

# Bluetooth
BOARD_HAVE_BLUETOOTH := true

# RIL
SIM_COUNT := 2

# N-era MTK RIL blob hosted by the AOSP rild; BOARD_USES_MTK_LEGACY_RIL makes
# hardware/ril build librilmtk and the MTK-specific code paths.
BOARD_USES_MTK_HARDWARE := true
BOARD_USES_MTK_LEGACY_RIL := true
# Upstream hardware/ril would build a rild that cannot load mtk-ril.so.
ifeq ($(wildcard hardware/ril/libril/librilmtk_force_needed.c),)
$(error m95: hardware/ril is not on branch meizu-legacy-vendor (no libril/librilmtk_force_needed.c); rild would be built without librilmtk)
endif

# Graphics
# The MTK vendor usage bit 26 must be accepted by the gralloc0 adapter.
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS ?= 0
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS += | (1 << 26)

TARGET_OTA_ASSERT_DEVICE := m95,M95,m685,MX6,mx6

# Vendor
include vendor/meizu/m95/BoardConfigVendor.mk

# Shims
# Camera RAW16: the metadata library must be loaded RTLD_GLOBAL into the camera
# provider before its DT_NEEDED; LD_PRELOAD is dropped under AT_SECURE.
TARGET_LD_SHIM_LIBS += \
    /vendor/bin/hw/android.hardware.camera.provider@2.4-service|/vendor/lib/libm95_camera_metadata_raw.so

# spm_loader uses __android_log_print without liblog in DT_NEEDED.
TARGET_LD_SHIM_LIBS += \
    /vendor/bin/spm_loader|liblog.so

# VoLTE log filter: drop VoLTE daemon INFO-and-below logs, which contain full
# SIP messages. Opt-in: M95_VOLTE_LOGFILTER=true.
ifeq ($(M95_VOLTE_LOGFILTER),true)
TARGET_LD_SHIM_LIBS += \
    /vendor/bin/volte_stack|/vendor/lib/libm95volte_logfilter.so \
    /vendor/bin/volte_ua|/vendor/lib/libm95volte_logfilter.so \
    /vendor/bin/volte_imcb|/vendor/lib/libm95volte_logfilter.so
endif
