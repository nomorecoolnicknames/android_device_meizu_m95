// libm95shim_audioutils: shims for audio.primary.mt6797.
//
// create/release_echo_reference were removed from libaudioutils. N signature:
//   int create_echo_reference(audio_format_t, uint32_t, uint32_t,
//                             audio_format_t, uint32_t, uint32_t,
//                             echo_reference_itfe**);
//   void release_echo_reference(echo_reference_itfe*);
// They serve voice-call echo cancellation only. Returning -ENOSYS makes the
// HAL take its no-EC path.
#include <errno.h>
#include <stdint.h>

extern "C" {

struct echo_reference_itfe;

int create_echo_reference(int /*rdFormat*/, uint32_t /*rdChannelCount*/,
                          uint32_t /*rdSamplingRate*/, int /*wrFormat*/,
                          uint32_t /*wrChannelCount*/,
                          uint32_t /*wrSamplingRate*/,
                          struct echo_reference_itfe** reference) {
    if (reference) *reference = 0;
    return -ENOSYS;
}

void release_echo_reference(struct echo_reference_itfe* /*reference*/) {
}

}  // extern "C"

// ---- android::AudioSystem::getDeviceConnectionState(audio_devices_t, const char*)
// Called from adev_open(). From the HAL service this would wait for
// media.audio_policy on /dev/vndbinder, where it is never published, and
// deadlock with audioserver. Report "unavailable": the policy manager pushes
// the real state via set_parameters after the module is loaded. This library
// precedes libaudioclient in the blob's DT_NEEDED, so this definition wins.
extern "C" int _ZN7android11AudioSystem24getDeviceConnectionStateEjPKc(
        unsigned int /*device*/, const char* /*device_address*/) {
    return 0;  // AUDIO_POLICY_DEVICE_STATE_UNAVAILABLE
}

// ---- AudioSystem::getParameters / setParameters (audio_io_handle_t, String8)
// Same deadlock, via libaudio_param_parser during adev_open. getParameters
// returns an empty String8 (the parser then uses the NVRAM parameters),
// setParameters reports success. String8 is returned by value (sret); the
// empty string is built by the real String8::String8().
namespace { struct M95String8Ret { void* p; ~M95String8Ret() {} }; }
extern "C" void _ZN7android7String8C1Ev(void* self);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"
extern "C" M95String8Ret _ZN7android11AudioSystem13getParametersEiRKNS_7String8E(
        int /*ioHandle*/, const void* /*keys*/) {
    M95String8Ret r;
    _ZN7android7String8C1Ev(&r);
    return r;
}
#pragma clang diagnostic pop
extern "C" int _ZN7android11AudioSystem13setParametersEiRKNS_7String8E(
        int /*ioHandle*/, const void* /*keyValuePairs*/) {
    return 0;  // NO_ERROR
}
