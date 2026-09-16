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

# Kernel
# Prebuilt kernel (Linux 3.18); the tree is never built from source here.
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

# SELinux is permissive on the kernel command line.
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

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

# VNDK
# BOARD_VNDK_VERSION := 30 does not work: vendor APEXes and vendor snapshot
# requirements break soong_build, so the vendor is built against the platform VNDK.
BOARD_VNDK_VERSION := current

# VNDK-lite no longer exists: libraries a vendor process needs from /system
# must be copied to /vendor, but never a VNDK library the vendor also uses.

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# Graphics
# The MTK vendor usage bit 26 must be accepted by the gralloc0 adapter.
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS ?= 0
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS += | (1 << 26)

TARGET_OTA_ASSERT_DEVICE := m95,M95,m685,MX6,mx6

# Vendor
include vendor/meizu/m95/BoardConfigVendor.mk

