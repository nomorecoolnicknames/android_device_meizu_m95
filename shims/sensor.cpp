// SensorEventQueue::getFd() const for the N camera stack (libmtkcam_sysutils).
// libsensor_vendor wraps an opaque NDK ASensorEventQueue and has no descriptor
// of its own, and the camera hands the fd to its Looper unchecked. Return a
// valid descriptor that never becomes readable: the listener receives no
// sensor events, but nothing crashes.
#include <log/log.h>
#include <sys/eventfd.h>

extern "C" int _ZNK7android16SensorEventQueue5getFdEv(const void* /*self*/) {
    static const int fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
    ALOGW("m95: SensorEventQueue::getFd() has no real descriptor on the compat libsensor, "
          "returning a silent eventfd (%d)", fd);
    return fd;
}
