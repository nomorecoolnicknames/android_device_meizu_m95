/*
 * Add streams the sensors can produce but the vendor stream tables omit:
 * RAW16 at the rear pixel array and 4:3 preview sizes above 640x480.
 *
 * The MediaTek metadata store looks the per-sensor table up with
 * dlsym(RTLD_DEFAULT, "constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_<driver>").
 * This library exports the same symbols, calls the store's own implementation
 * and then appends rows to the scaler tags. It never replaces vendor data: if a
 * table is not in the expected shape, nothing is added.
 *
 * The library must be RTLD_GLOBAL in the camera provider to be found first; it
 * is loaded as a TARGET_LD_SHIM_LIBS shim of the provider (see BoardConfig.mk).
 * Each addition has its own switch (persist.camera.raw, persist.camera.preview_43,
 * persist.camera.raw_front); with all off the library is a pass-through.
 */

#include <dlfcn.h>
#include <stddef.h>

#include <cutils/properties.h>
#include <log/log.h>

#include "m95_nscam_metadata.h"

#undef LOG_TAG
#define LOG_TAG "m95ScalerRaw"

using NSCam::IMetadata;
using NSCam::MINT32;
using NSCam::MINT64;
using NSCam::MUINT;
using NSCam::MUINT32;
using NSCam::Type2Type;

namespace {

typedef int (*ConstructFn)(IMetadata*, void const*);

const char* const kMetastore = "libmtkcam_metastore.so";
const char* const kRearSymbol =
        "constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_IMX386_SUNNY_MIPI_RAW";
const char* const kFrontSymbol =
        "constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_OV5695_MIPI_RAW";

// One output row as the three tags want it: the configuration (format, width,
// height, OUTPUT), its minimum frame duration and its stall duration.
struct Row {
    MINT32 format;
    MINT32 width;
    MINT32 height;
    MINT64 minFrameDuration;
    MINT64 stallDuration;
};

// The raw frame is the sensor's active array. 30 fps durations keep it in
// getOutputSizes(); slower sizes are only listed in getHighResolutionOutputSizes().
const Row kRearRaw = {0x20 /* HAL_PIXEL_FORMAT_RAW16 */, 4032, 3016, 33333333LL, 33333333LL};

// The front OV5695 at its active array. Must match the framework-side claim
// (persist.camera.raw_front), or checkStream rejects the stream.
const Row kFrontRaw = {0x20 /* HAL_PIXEL_FORMAT_RAW16 */, 2592, 1944, 33333333LL, 33333333LL};

// 4:3 viewfinder sizes, YCbCr_420_888 at 30 fps and no stall, like the vendor's
// own YUV rows.
const Row kPreview43[] = {
        {0x23 /* YCbCr_420_888 */, 1440, 1080, 33333333LL, 0LL},
        {0x23 /* YCbCr_420_888 */, 1280, 960, 33333333LL, 0LL},
};

const MUINT kValuesPerRow = 4;

// A table the vendor left empty or ragged is one this library does not
// understand, and editEntryFor on a missing tag is an abort, not a create.
bool tableIsWhole(const IMetadata* metadata, MUINT32 tag) {
    const MUINT count = metadata->entryFor(tag).count();
    if (count == 0 || (count % kValuesPerRow) != 0) {
        ALOGE("tag 0x%x holds %u values; not appending", tag, count);
        return false;
    }
    return true;
}

template <typename T>
void appendValues(IMetadata* metadata, MUINT32 tag, T format, T width, T height, T last) {
    IMetadata::IEntry& entry = metadata->editEntryFor(tag);
    entry.push_back(format, Type2Type<T>());
    entry.push_back(width, Type2Type<T>());
    entry.push_back(height, Type2Type<T>());
    entry.push_back(last, Type2Type<T>());
}

void appendRow(IMetadata* metadata, const Row& row) {
    appendValues<MINT32>(metadata, MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS, row.format,
                         row.width, row.height,
                         MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS_OUTPUT);
    appendValues<MINT64>(metadata, MTK_SCALER_AVAILABLE_MIN_FRAME_DURATIONS, row.format,
                         row.width, row.height, row.minFrameDuration);
    appendValues<MINT64>(metadata, MTK_SCALER_AVAILABLE_STALL_DURATIONS, row.format,
                         row.width, row.height, row.stallDuration);
    ALOGI("appended format 0x%x %dx%d to the vendor table", row.format, row.width, row.height);
}

// Answer for one sensor section: run the store's own implementation, then append
// what the switches ask for. `self` is the exported answer calling this, so the
// lookup can tell the store's function from ours.
int extendSection(IMetadata* metadata, void const* info, const char* symbol, ConstructFn self,
                  const Row& rawRow, const char* rawProp) {
    if (metadata == NULL) {
        return -1;
    }

    // RTLD_NOLOAD: the store is the one asking, so it is already here. Looking
    // the symbol up through its handle rather than the default scope is what
    // reaches its implementation instead of this one.
    void* handle = ::dlopen(kMetastore, RTLD_NOW | RTLD_NOLOAD);
    if (handle == NULL) {
        ALOGE("%s is not loaded; leaving the table to whoever else answers", kMetastore);
        return -1;
    }

    ConstructFn vendor = reinterpret_cast<ConstructFn>(::dlsym(handle, symbol));
    ::dlclose(handle);
    if (vendor == NULL || vendor == self) {
        ALOGE("the store's own %s did not resolve; not touching the table", symbol);
        return -1;
    }

    // Log which library answered and whether the metadata changed.
    Dl_info where;
    if (::dladdr(reinterpret_cast<void*>(vendor), &where) != 0 && where.dli_fname != NULL) {
        ALOGI("%s: delegating to %p in %s", symbol, reinterpret_cast<void*>(vendor),
              where.dli_fname);
    } else {
        ALOGI("%s: delegating to %p, origin unknown", symbol, reinterpret_cast<void*>(vendor));
    }

    const int status = vendor(metadata, info);
    ALOGI("vendor returned %d; tag 0x%x now holds %u values", status,
          MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS,
          metadata->entryFor(MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS).count());

    // Off switches: read when the provider builds its static metadata, so they
    // take a provider restart, not a reflash. With both off the camera gets
    // exactly what the vendor built.
    const bool raw = property_get_bool(rawProp, false);
    const bool preview43 = property_get_bool("persist.camera.preview_43", false);
    if (!raw && !preview43) {
        ALOGI("%s / preview_43 off; vendor table passed through", rawProp);
        return status;
    }

    if (status == 0 &&
        tableIsWhole(metadata, MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS) &&
        tableIsWhole(metadata, MTK_SCALER_AVAILABLE_MIN_FRAME_DURATIONS) &&
        tableIsWhole(metadata, MTK_SCALER_AVAILABLE_STALL_DURATIONS)) {
        if (raw) {
            appendRow(metadata, rawRow);
        }
        if (preview43) {
            for (size_t i = 0; i < sizeof(kPreview43) / sizeof(kPreview43[0]); ++i) {
                appendRow(metadata, kPreview43[i]);
            }
        }
    }
    return status;
}

}  // namespace

extern "C" __attribute__((visibility("default"))) int
constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_IMX386_SUNNY_MIPI_RAW(
        IMetadata* metadata, void const* info) {
    return extendSection(metadata, info, kRearSymbol,
                         &constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_IMX386_SUNNY_MIPI_RAW,
                         kRearRaw, "persist.camera.raw");
}

extern "C" __attribute__((visibility("default"))) int
constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_OV5695_MIPI_RAW(
        IMetadata* metadata, void const* info) {
    return extendSection(metadata, info, kFrontSymbol,
                         &constructCustStaticMetadata_DEVICE_SCALER_SENSOR_DRVNAME_OV5695_MIPI_RAW,
                         kFrontRaw, "persist.camera.raw_front");
}
