#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# vendor/meizu/m95/m95-vendor.mk and Android.mk are maintained by hand (blob
# layout, the lights blob left out, symlink recreation, the librilimp
# prebuilt). This script overwrites them, so it refuses to run unless asked
# and keeps a copy; diff the result against the .handmaintained files.
#

set -e

DEVICE=m95
VENDOR=meizu

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

VENDOR_DIR="${ANDROID_ROOT}/vendor/${VENDOR}/${DEVICE}"

if [ "${M95_ALLOW_REGEN}" != "1" ]; then
    cat >&2 <<EOF
setup-makefiles.sh would regenerate

    ${VENDOR_DIR}/m95-vendor.mk
    ${VENDOR_DIR}/Android.mk
    ${VENDOR_DIR}/Android.bp
    ${VENDOR_DIR}/BoardConfigVendor.mk

and those files are hand-maintained for this device (see the header of this
script and device/meizu/m95/proprietary-files.txt).

Re-run with M95_ALLOW_REGEN=1 if that is really what you want.  The current
files will be saved next to them with a .handmaintained suffix.
EOF
    exit 1
fi

for f in m95-vendor.mk Android.mk Android.bp BoardConfigVendor.mk; do
    if [ -f "${VENDOR_DIR}/${f}" ]; then
        cp -f "${VENDOR_DIR}/${f}" "${VENDOR_DIR}/${f}.handmaintained"
        echo "saved ${VENDOR_DIR}/${f}.handmaintained"
    fi
done

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false true

# Warnings headers
write_headers

write_makefiles "${MY_DIR}/proprietary-files.txt" true

# Finish
write_footers

echo
echo "Generated. Now diff every file against its .handmaintained twin:"
for f in m95-vendor.mk Android.mk Android.bp BoardConfigVendor.mk; do
    echo "  diff -u ${VENDOR_DIR}/${f}.handmaintained ${VENDOR_DIR}/${f}"
done
