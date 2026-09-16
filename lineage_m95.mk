#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit 64-bit configs (zygote64_32: some blobs are 32-bit only)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common LineageOS stuff
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from m95 device
$(call inherit-product, device/meizu/m95/device.mk)

# IMS service (com.mediatek.ims) from vendor/forge/ims. It must be a real
# directory: Soong's finder skips symlinks, and a missing package would be
# dropped silently.
ifeq ($(wildcard vendor/forge/ims/forge-ims.mk),)
  $(error m95: vendor/forge/ims is missing; check out ForgeImsService (vendor/forge/ims, branch lineage-20) there)
endif
ifneq ($(shell readlink -f vendor/forge/ims),$(shell readlink -f .)/vendor/forge/ims)
  $(error m95: vendor/forge/ims is or sits under a symlink; soong's finder skips symlinked directories, so ForgeImsService would silently vanish. Use a real clone)
endif
$(call inherit-product, vendor/forge/ims/forge-ims.mk)

# Overlays
DEVICE_PACKAGE_OVERLAYS += device/meizu/m95/overlay

# Shipping API level 25 (Nougat MR1). Must come after device.mk: the last
# inherit wins.
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_n_mr1.mk)

# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := m95
PRODUCT_NAME := lineage_m95
BOARD_VENDOR := meizu
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := Meizu MX6
PRODUCT_MANUFACTURER := Meizu
TARGET_VENDOR := meizu

PRODUCT_GMS_CLIENTID_BASE := android-meizu

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="m95-user 7.1.1 NMF26O 1623837408 release-keys"

# Set BUILD_FINGERPRINT variable to be picked up by both system and vendor build.prop
BUILD_FINGERPRINT := "Meizu/meizu_MX6/MX6:7.1.1/NMF26O/1623837408:user/release-keys"
