// libm95shim_power: legacy acquire/release_wake_lock for N blobs.
//
// libhardware_legacy is system-only, so vendor processes (audio.primary,
// hwcomposer) cannot link it. Implemented against the kernel wakelock sysfs
// ABI: writing a name to /sys/power/wake_lock acquires a wakelock, writing it
// to /sys/power/wake_unlock releases it.
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

extern "C" {

static void write_wakelock(const char* file, const char* id) {
    if (!id || !*id) return;
    int fd = open(file, O_WRONLY | O_CLOEXEC);
    if (fd < 0) return;
    write(fd, id, strlen(id));
    close(fd);
}

int acquire_wake_lock(int /*lock*/, const char* id) {
    write_wakelock("/sys/power/wake_lock", id);
    return 0;
}

int release_wake_lock(const char* id) {
    write_wakelock("/sys/power/wake_unlock", id);
    return 0;
}

}  // extern "C"
