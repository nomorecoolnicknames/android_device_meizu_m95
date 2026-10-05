/*
 * Copyright (C) 2018 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "android.hardware.thermal@2.0-service.m95"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <sstream>

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>
#include <hidl/HidlTransportSupport.h>

#include "Thermal.h"

namespace android {
namespace hardware {
namespace thermal {
namespace V2_0 {
namespace implementation {

using ::android::sp;
using ::android::hardware::interfacesEqual;
using ::android::hardware::thermal::V1_0::ThermalStatus;
using ::android::hardware::thermal::V1_0::ThermalStatusCode;

namespace {

// Thermal zones are matched by /sys/class/thermal/thermal_zoneN/type, as the
// zone numbers are not stable. Only zones reporting real millidegrees C:
//   mtktscpu  SoC junction
//   battery   bq27532 fuel gauge
//   mtktsAP   AP board NTC, reported as SKIN (there is no skin sensor)
// tsda9214, mtktsdram, mtktspa, mtktsbattery and mtktswmt report placeholder
// or non-temperature values; the remaining zones are of unknown placement.
struct Sensor {
    const char* zoneType;
    const char* name;
    TemperatureType type;
};

constexpr Sensor kSensors[] = {
        {"mtktscpu", "CPU", TemperatureType::CPU},
        {"battery", "battery", TemperatureType::BATTERY},
        {"mtktsAP", "AP_NTC", TemperatureType::SKIN},
};

constexpr char kThermalDir[] = "/sys/class/thermal/";
constexpr int kMaxZones = 32;

// Path of the temp file of the zone named |zoneType|, or "" if there is none.
std::string zoneTempPath(const char* zoneType) {
    for (int i = 0; i < kMaxZones; ++i) {
        std::string dir = std::string(kThermalDir) + "thermal_zone" + std::to_string(i);
        std::string type;
        if (!base::ReadFileToString(dir + "/type", &type)) continue;
        if (base::Trim(type) == zoneType) return dir + "/temp";
    }
    return "";
}

// Celsius, or NAN when the zone is missing or unreadable -- never a guess.
float readCelsius(const char* zoneType) {
    std::string path = zoneTempPath(zoneType);
    std::string value;
    if (path.empty() || !base::ReadFileToString(path, &value)) return NAN;
    char* end = nullptr;
    std::string trimmed = base::Trim(value);
    long milli = std::strtol(trimmed.c_str(), &end, 10);
    if (trimmed.empty() || *end != '\0') return NAN;
    return milli / 1000.0f;
}

bool wanted(bool filterType, TemperatureType want, TemperatureType type) {
    return !filterType || want == type;
}

}  // namespace

// Methods from ::android::hardware::thermal::V1_0::IThermal follow.
Return<void> Thermal::getTemperatures(getTemperatures_cb _hidl_cb) {
    ThermalStatus status;
    status.code = ThermalStatusCode::SUCCESS;
    std::vector<Temperature_1_0> temperatures;
    for (const Sensor& s : kSensors) {
        // V1_0::TemperatureType has CPU 0, GPU 1, BATTERY 2, SKIN 3 -- the
        // same values as V2_0, which only appends types.
        float c = readCelsius(s.zoneType);
        if (std::isnan(c)) continue;
        temperatures.push_back({
                .type = static_cast<::android::hardware::thermal::V1_0::TemperatureType>(s.type),
                .name = s.name,
                .currentValue = c,
                .throttlingThreshold = NAN,
                .shutdownThreshold = NAN,
                .vrThrottlingThreshold = NAN,
        });
    }
    _hidl_cb(status, temperatures);
    return Void();
}

Return<void> Thermal::getCpuUsages(getCpuUsages_cb _hidl_cb) {
    ThermalStatus status;
    status.code = ThermalStatusCode::SUCCESS;
    std::vector<CpuUsage> cpu_usages;
    std::ifstream stat("/proc/stat");
    std::string line;
    while (std::getline(stat, line)) {
        // "cpuN user nice system idle iowait irq softirq ..."; skip the
        // aggregate "cpu " line. Offline cores have no line at all.
        if (line.compare(0, 3, "cpu") != 0 || line.size() < 4 || line[3] == ' ') continue;
        std::istringstream in(line);
        std::string name;
        uint64_t user = 0, nice = 0, system = 0, idle = 0, iowait = 0, irq = 0, softirq = 0;
        in >> name >> user >> nice >> system >> idle >> iowait >> irq >> softirq;
        if (in.fail()) continue;
        uint64_t active = user + nice + system + irq + softirq;
        cpu_usages.push_back({
                .name = name,
                .active = active,
                .total = active + idle + iowait,
                .isOnline = true,
        });
    }
    if (cpu_usages.empty()) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "Failed to read /proc/stat";
    }
    _hidl_cb(status, cpu_usages);
    return Void();
}

Return<void> Thermal::getCoolingDevices(getCoolingDevices_cb _hidl_cb) {
    // The MTK cooling devices (cpu_adaptive_*, mtk-cl-*) are the legacy
    // daemons' business and have no V1/V2 CoolingType meaning; none reported.
    ThermalStatus status;
    status.code = ThermalStatusCode::SUCCESS;
    _hidl_cb(status, {});
    return Void();
}

// Methods from ::android::hardware::thermal::V2_0::IThermal follow.
Return<void> Thermal::getCurrentTemperatures(bool filterType, TemperatureType type,
                                             getCurrentTemperatures_cb _hidl_cb) {
    ThermalStatus status;
    status.code = ThermalStatusCode::SUCCESS;
    std::vector<Temperature_2_0> temperatures;
    for (const Sensor& s : kSensors) {
        if (!wanted(filterType, type, s.type)) continue;
        float c = readCelsius(s.zoneType);
        if (std::isnan(c)) continue;
        temperatures.push_back({
                .type = s.type,
                .name = s.name,
                .value = c,
                .throttlingStatus = ThrottlingSeverity::NONE,
        });
    }
    if (filterType && temperatures.empty()) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "No sensor of this type";
    }
    _hidl_cb(status, temperatures);
    return Void();
}

Return<void> Thermal::getTemperatureThresholds(bool filterType, TemperatureType type,
                                               getTemperatureThresholds_cb _hidl_cb) {
    // Thresholds are left undefined: throttling belongs to the MTK daemons,
    // whose trip table m95-cpuset.sh rewrites (85/80 C). Declaring numbers
    // here would let the framework act on a second, unsynchronised policy.
    ThermalStatus status;
    status.code = ThermalStatusCode::SUCCESS;
    std::vector<TemperatureThreshold> temperature_thresholds;
    for (const Sensor& s : kSensors) {
        if (!wanted(filterType, type, s.type)) continue;
        temperature_thresholds.push_back({
                .type = s.type,
                .name = s.name,
                .hotThrottlingThresholds = {{NAN, NAN, NAN, NAN, NAN, NAN, NAN}},
                .coldThrottlingThresholds = {{NAN, NAN, NAN, NAN, NAN, NAN, NAN}},
                .vrThrottlingThreshold = NAN,
        });
    }
    if (filterType && temperature_thresholds.empty()) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "No sensor of this type";
    }
    _hidl_cb(status, temperature_thresholds);
    return Void();
}

Return<void> Thermal::getCurrentCoolingDevices(bool filterType, CoolingType /* type */,
                                               getCurrentCoolingDevices_cb _hidl_cb) {
    ThermalStatus status;
    status.code = ThermalStatusCode::SUCCESS;
    if (filterType) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "No cooling devices reported";
    }
    _hidl_cb(status, {});
    return Void();
}

// Callbacks are kept as in the AOSP mock. With no thresholds the severity
// never changes, so there is nothing to notify them about.
Return<void> Thermal::registerThermalChangedCallback(const sp<IThermalChangedCallback>& callback,
                                                     bool filterType, TemperatureType type,
                                                     registerThermalChangedCallback_cb _hidl_cb) {
    ThermalStatus status;
    if (callback == nullptr) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "Invalid nullptr callback";
        LOG(ERROR) << status.debugMessage;
        _hidl_cb(status);
        return Void();
    } else {
        status.code = ThermalStatusCode::SUCCESS;
    }
    std::lock_guard<std::mutex> _lock(thermal_callback_mutex_);
    if (std::any_of(callbacks_.begin(), callbacks_.end(), [&](const CallbackSetting& c) {
            return interfacesEqual(c.callback, callback);
        })) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "Same callback interface registered already";
        LOG(ERROR) << status.debugMessage;
    } else {
        callbacks_.emplace_back(callback, filterType, type);
        LOG(INFO) << "A callback has been registered to ThermalHAL, isFilter: " << filterType
                  << " Type: " << android::hardware::thermal::V2_0::toString(type);
    }
    _hidl_cb(status);
    return Void();
}

Return<void> Thermal::unregisterThermalChangedCallback(
    const sp<IThermalChangedCallback>& callback, unregisterThermalChangedCallback_cb _hidl_cb) {
    ThermalStatus status;
    if (callback == nullptr) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "Invalid nullptr callback";
        LOG(ERROR) << status.debugMessage;
        _hidl_cb(status);
        return Void();
    } else {
        status.code = ThermalStatusCode::SUCCESS;
    }
    bool removed = false;
    std::lock_guard<std::mutex> _lock(thermal_callback_mutex_);
    callbacks_.erase(
        std::remove_if(callbacks_.begin(), callbacks_.end(),
                       [&](const CallbackSetting& c) {
                           if (interfacesEqual(c.callback, callback)) {
                               LOG(INFO)
                                   << "A callback has been unregistered from ThermalHAL, isFilter: "
                                   << c.is_filter_type << " Type: "
                                   << android::hardware::thermal::V2_0::toString(c.type);
                               removed = true;
                               return true;
                           }
                           return false;
                       }),
        callbacks_.end());
    if (!removed) {
        status.code = ThermalStatusCode::FAILURE;
        status.debugMessage = "The callback was not registered before";
        LOG(ERROR) << status.debugMessage;
    }
    _hidl_cb(status);
    return Void();
}

}  // namespace implementation
}  // namespace V2_0
}  // namespace thermal
}  // namespace hardware
}  // namespace android
