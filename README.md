# Meizu MX6 (m95)

Device tree for the Meizu MX6 for LineageOS 20.0.

## Specifications

| | |
| --- | --- |
| SoC | MediaTek MT6797 (Helio X20) |
| Architecture | arm64 |
| Display | 1080 x 1920, 480 dpi |
| Kernel | Linux 3.18, `m95_defconfig` |
| Codenames | m95, m685, MX6 |

## Status

- Display, touch and backlight: working
- Cameras: rear and front take photos
- Mobile network: LTE data, SMS, USSD and VoLTE calls (outgoing and incoming) working
- Wi-Fi: 2.4 and 5 GHz working; hotspot working
- Bluetooth: turns on; pairing and audio untested
- Sensors (accelerometer, gyroscope, magnetometer, light, proximity), Power HAL, thermal HAL: working
- Audio: call audio path active, listening untested; fingerprint and outdoor GPS fix: untested
- SELinux: enforcing; encryption and suspend current: untested

## Building

```sh
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
mkdir -p .repo/local_manifests
curl -L -o .repo/local_manifests/meizu_m95.xml \
  https://raw.githubusercontent.com/nomorecoolnicknames/android_local_manifests_meizu/lineage-20.0/meizu_m95.xml
repo sync -c
source build/envsetup.sh
breakfast m95
brunch m95
```

The local manifest adds this tree, `hardware/ril` ([android_hardware_ril](https://github.com/nomorecoolnicknames/android_hardware_ril), MediaTek legacy RIL support)
and the kernel ([android_kernel_meizu_m95](https://github.com/nomorecoolnicknames/android_kernel_meizu_m95), built with `m95_defconfig`). Also required:

- Vendor blobs: [android_vendor_meizu_m95](https://github.com/nomorecoolnicknames/android_vendor_meizu_m95) `lineage-20.0` at `vendor/meizu/m95`.
  Use the prepared vendor tree; a raw extraction is not interchangeable with it.
- Platform patches: `device/meizu/common` (android_device_meizu_common) applies them on `source build/envsetup.sh`.
- The IMS service (MtkImsService) will be provided by device/meizu/common/ims; until it is published the build stops with an error.
- Stock-derived init, fstab, keylayout, media and carrier profile files are supplied separately.

A boot image built from the kernel source was tested on the phone.
Google Camera is optional: run `gcam/fetch-gcam.sh` and build with `M95_WITH_GCAM=true`.
No ADB keys are preinstalled; set `M95_ADB_KEYS` only for your own test setup.

## License

Based on work by LineageOS and CyanogenMod contributors, the original device-tree authors and ReMeizu
contributors. Copyright and license notices remain with their source files.
