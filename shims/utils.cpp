// libm95shim_utils: libutils/libcutils/libbinder symbols removed since Nougat.
//
// strndup16to8/strdup8to16/strnlen16to8/strncpy16to8 (RIL stack,
// nvram_agent_binder): local implementations following AOSP libutils.
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
// char16_t is a C++11 builtin; do NOT typedef it.

extern "C" {

size_t strnlen16to8(const char16_t* s, size_t n) {
    size_t r = 0;
    while (n-- > 0 && *s++) r++;
    return r;
}

char* strncpy16to8(char* dest, const char16_t* src, size_t n) {
    char* d = dest;
    while (n-- > 0) {
        char16_t c = *src++;
        *d++ = (c < 0x80) ? (char)c : '?';
    }
    return dest;
}

char* strndup16to8(const char16_t* s, size_t n) {
    n = strnlen16to8(s, n);
    char* r = (char*)malloc(n + 1);
    if (!r) return NULL;
    strncpy16to8(r, s, n);
    r[n] = '\0';
    return r;
}

char16_t* strdup8to16(const char* s, size_t* out_len) {
    size_t n = strlen(s);
    char16_t* r = (char16_t*)malloc((n + 1) * sizeof(char16_t));
    if (!r) return NULL;
    for (size_t i = 0; i < n; i++) r[i] = (char16_t)(unsigned char)s[i];
    r[n] = 0;
    if (out_len) *out_len = n;
    return r;
}

}  // extern "C"

// android_memset16/android_memset32, removed from libcutils; imported by
// gralloc.mt6797.so. count is in bytes, a multiple of the element size, dst
// aligned to the element size.
extern "C" void android_memset16(uint16_t* dst, uint16_t value, size_t count) {
    count /= sizeof(uint16_t);
    while (count-- > 0) *dst++ = value;
}

extern "C" void android_memset32(uint32_t* dst, uint32_t value, size_t count) {
    count /= sizeof(uint32_t);
    while (count-- > 0) *dst++ = value;
}

// android::PermissionCache::checkCallingPermission, imported by libpqservice.so
// (in the libGLES_mali closure). The VNDK libbinder has no PermissionCache;
// always grant. N-era mangled name, no libbinder dependency.
namespace android {
class String16;
class PermissionCache {
  public:
    static bool checkCallingPermission(const String16& permission);
    static bool checkPermission(const String16& permission, int32_t pid, uint32_t uid);
};
bool PermissionCache::checkCallingPermission(const String16&) {
    return true;
}
// Also imported by goodixfingerprintd / libgoodixfingerprintd_binder.so.
bool PermissionCache::checkPermission(const String16&, int32_t, uint32_t) {
    return true;
}
}  // namespace android

// ---- android::MemoryHeapBase(int fd, size_t size, uint32_t flags, off_t offset)
// N mangled the offset as uint32_t (C1Eijjj on both ABIs); current libbinder
// uses C1Eijjl (32-bit) / C1Eimjl (64-bit). Imported by libmtkcam_cct.so.
// Manual declarations, resolved from libbinder at runtime.
extern "C" {
#ifdef __LP64__
void _ZN7android14MemoryHeapBaseC1Eimjl(void* self, int fd, unsigned long size,
                                        uint32_t flags, long offset);
void _ZN7android14MemoryHeapBaseC1Eijjj(void* self, int fd, uint32_t size,
                                        uint32_t flags, uint32_t offset) {
    _ZN7android14MemoryHeapBaseC1Eimjl(self, fd, size, flags, (long)offset);
}
#else
void _ZN7android14MemoryHeapBaseC1Eijjl(void* self, int fd, uint32_t size,
                                        uint32_t flags, long offset);
void _ZN7android14MemoryHeapBaseC1Eijjj(void* self, int fd, uint32_t size,
                                        uint32_t flags, uint32_t offset) {
    _ZN7android14MemoryHeapBaseC1Eijjl(self, fd, size, flags, (long)offset);
}
#endif
}  // extern "C"
