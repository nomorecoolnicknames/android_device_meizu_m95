// libm95shim_ui: N-to-A13 libui forwarders and android::Fence for the N blobs.
//
// Missing in A13 libui:
//   GraphicBuffer::lock(uint32_t,void**)                       N: lockEjPPv
//     A13: lockEjPPvPiS3_ (extra out-params, forwarded as null)
//   GraphicBufferMapper::lock(handle,usage,rect,vaddr)          N: 5 args
//     A13: ...PPvPiS9_ (7 args, extras nulled)
//
// libui is not linked (see gui.cpp); the A13 Fence pieces are looked up in the
// already-loaded libui with dlsym.
#include <dlfcn.h>
#include <errno.h>
#include <link.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <atomic>

namespace android {
class Rect;
class GraphicBuffer;
class GraphicBufferMapper;
struct native_handle;
}  // namespace android

extern "C" {

// ---- A13 targets (system libui, resolved at runtime) ----
int _ZN7android13GraphicBuffer4lockEjPPvPiS3_(
        android::GraphicBuffer*, uint32_t, void**, int32_t*, int32_t*);
int _ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPvPiS9_(
        android::GraphicBufferMapper*, const android::native_handle*,
        uint32_t, const android::Rect&, void**, int32_t*, int32_t*);
int _ZN7android13GraphicBuffer9lockAsyncEjPPviPiS3_(
        android::GraphicBuffer*, uint32_t, void**, int, int32_t*, int32_t*);

// ---- N-ABI entries ----
int _ZN7android13GraphicBuffer4lockEjPPv(
        android::GraphicBuffer* self, uint32_t inUsage, void** vaddr) {
    return _ZN7android13GraphicBuffer4lockEjPPvPiS3_(
            self, inUsage, vaddr, NULL, NULL);
}

int _ZN7android13GraphicBuffer9lockAsyncEjPPvi(
        android::GraphicBuffer* self, uint32_t inUsage, void** vaddr,
        int fenceFd) {
    return _ZN7android13GraphicBuffer9lockAsyncEjPPviPiS3_(
            self, inUsage, vaddr, fenceFd, NULL, NULL);
}

int _ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPv(
        android::GraphicBufferMapper* self, const android::native_handle* handle,
        uint32_t inUsage, const android::Rect& bounds, void** vaddr) {
    return _ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPvPiS9_(
            self, handle, inUsage, bounds, vaddr, NULL, NULL);
}

}  // extern "C"

// ---- Fence -----------------------------------------------------------------
// N (7.1) Fence: LightRefBase mCount@0, int mFenceFd@4, 8 bytes on both ABIs.
// A13 Fence is polymorphic: vptr@0, mCount, unique_fd mFenceFd last, i.e.
// 16 bytes with fd@12 on arm64 and 12 bytes with fd@8 on arm.
//
// N callers (hwcomposer.mt6797, libMtkOmxVenc, libMtkOmxVdecEx, libshowlogo)
// do new(8) + Fence(int) or Fence(), then wait()/waitForever()/dup(), then
// ~Fence. A13 libui does not export Fence() or ~Fence.
//
// This library is loaded before libui.so by every N consumer, so these names
// bind here for the whole load group, A13 libraries included. Hence:
//   - wait/waitForever/dup/~Fence detect the layout of the object (A13 objects
//     carry the libui vtable);
//   - Fence(int) builds the N layout only for callers that need this library
//     (the N blobs), and runs libui's own constructor for everyone else.
extern "C" int sync_wait(int fd, int timeout);                            // libsync (LLNDK)
extern "C" int __android_log_print(int prio, const char* tag, const char* fmt, ...);  // liblog

namespace {

struct NFence {
    int32_t mCount;
    int mFenceFd;
};

constexpr size_t kA13FdOffset = sizeof(void*) == 8 ? 12 : 8;
constexpr uintptr_t kVtableAddressPoint = 2 * sizeof(void*);

struct A13Fence {
    uintptr_t vptr;                   // _ZTVN7android5FenceE + address point
    void (*ctor)(void*, int);         // Fence::Fence(int), libui's own
};

// libui is loaded before any Fence exists; only success is cached.
const A13Fence* a13() {
    static std::atomic<const A13Fence*> cached{nullptr};
    static A13Fence storage;
    const A13Fence* p = cached.load(std::memory_order_acquire);
    if (p) return p;
    void* ui = dlopen("libui.so", RTLD_NOW | RTLD_NOLOAD);
    if (!ui) return nullptr;
    void* vt = dlsym(ui, "_ZTVN7android5FenceE");
    void* ct = dlsym(ui, "_ZN7android5FenceC2Ei");
    if (!vt || !ct) return nullptr;
    storage.vptr = reinterpret_cast<uintptr_t>(vt) + kVtableAddressPoint;
    storage.ctor = reinterpret_cast<void (*)(void*, int)>(ct);
    cached.store(&storage, std::memory_order_release);
    return &storage;
}

bool isA13(const void* self) {
    const A13Fence* a = a13();
    if (!a) return false;
    uintptr_t word = *static_cast<const uintptr_t*>(self);
    // N blobs run their inline sp<Fence> refcount at offset 0 even on A13
    // objects (32-bit atomic add/sub, libgui_ext and hwcomposer), which moves
    // only the low word of the vptr by a few units; accept that drift. An N
    // object's first word is a small mCount (arm) or fd:mCount (arm64).
    int32_t drift = static_cast<int32_t>(static_cast<uint32_t>(word) -
                                         static_cast<uint32_t>(a->vptr));
    return static_cast<uint64_t>(word) >> 32 == static_cast<uint64_t>(a->vptr) >> 32 &&
           drift > -256 && drift < 256;
}

int* fdOf(void* self) {
    if (isA13(self)) return reinterpret_cast<int*>(static_cast<char*>(self) + kA13FdOffset);
    return &static_cast<NFence*>(self)->mFenceFd;
}

// Does the module containing `ra` have DT_NEEDED libm95shim_ui.so?
struct CallerProbe {
    uintptr_t ra;
    bool needsShim;
};

int probeModule(dl_phdr_info* info, size_t, void* data) {
    CallerProbe* p = static_cast<CallerProbe*>(data);
    const ElfW(Dyn)* dyn = nullptr;
    bool inside = false;
    for (int i = 0; i < info->dlpi_phnum; ++i) {
        const ElfW(Phdr)& ph = info->dlpi_phdr[i];
        uintptr_t start = info->dlpi_addr + ph.p_vaddr;
        if (ph.p_type == PT_LOAD && p->ra >= start && p->ra < start + ph.p_memsz) inside = true;
        if (ph.p_type == PT_DYNAMIC) dyn = reinterpret_cast<const ElfW(Dyn)*>(start);
    }
    if (!inside) return 0;
    if (!dyn) return 1;
    // bionic leaves d_ptr unrelocated; glibc (host test) rewrites it in place.
    const char* strtab = nullptr;
    for (const ElfW(Dyn)* d = dyn; d->d_tag != DT_NULL; ++d) {
        if (d->d_tag != DT_STRTAB) continue;
        uintptr_t v = d->d_un.d_ptr;
        strtab = reinterpret_cast<const char*>(v < info->dlpi_addr ? v + info->dlpi_addr : v);
    }
    if (!strtab) return 1;
    for (const ElfW(Dyn)* d = dyn; d->d_tag != DT_NULL; ++d) {
        if (d->d_tag == DT_NEEDED && strcmp(strtab + d->d_un.d_val, "libm95shim_ui.so") == 0) {
            p->needsShim = true;
            break;
        }
    }
    return 1;
}

// Verdicts per call site: ((ra << 1) | isN), 0 = empty. Few call sites exist.
// An OMX blob may be dlclose'd; a reused address could only mislead us if an
// A13 importer of Fence(int) were loaded there later, and those (libgui_vendor,
// libstagefright_*) are loaded once and never unloaded.
std::atomic<uint64_t> gCallSites[32];

bool callerIsNBlob(uintptr_t ra) {
    for (auto& slot : gCallSites) {
        uint64_t v = slot.load(std::memory_order_acquire);
        if (v == 0) break;
        if ((v >> 1) == ra) return v & 1;
    }
    CallerProbe probe{ra, false};
    dl_iterate_phdr(probeModule, &probe);
    uint64_t v = (static_cast<uint64_t>(ra) << 1) | (probe.needsShim ? 1 : 0);
    for (auto& slot : gCallSites) {
        uint64_t expected = 0;
        if (slot.compare_exchange_strong(expected, v, std::memory_order_acq_rel)) break;
        if ((expected >> 1) == ra) break;
    }
    return probe.needsShim;
}

void constructWithFd(void* self, int fenceFd, uintptr_t ra) {
    if (!callerIsNBlob(ra)) {
        const A13Fence* a = a13();
        if (a) {
            a->ctor(self, fenceFd);
            return;
        }
        // A13 caller with no libui in the process cannot happen: the caller
        // links against libui. Refuse to guess a layout.
        __android_log_print(7 /* ANDROID_LOG_FATAL */, "m95shim_ui",
                            "Fence(int) from %p: A13 caller but libui Fence not found",
                            reinterpret_cast<void*>(ra));
        abort();
    }
    NFence* f = static_cast<NFence*>(self);
    f->mCount = 0;
    f->mFenceFd = fenceFd;
}

int waitOn(int fd, int timeout) {
    if (fd == -1) return 0;
    int err = sync_wait(fd, timeout);
    return err < 0 ? -errno : 0;
}

}  // namespace

extern "C" {

void _ZN7android5FenceC2Ev(void* self) {
    NFence* f = static_cast<NFence*>(self);
    f->mCount = 0;
    f->mFenceFd = -1;
}
void _ZN7android5FenceC1Ev(void* self) { _ZN7android5FenceC2Ev(self); }

void _ZN7android5FenceC2Ei(void* self, int fenceFd) {
    constructWithFd(self, fenceFd, reinterpret_cast<uintptr_t>(__builtin_return_address(0)));
}
void _ZN7android5FenceC1Ei(void* self, int fenceFd) {
    constructWithFd(self, fenceFd, reinterpret_cast<uintptr_t>(__builtin_return_address(0)));
}

void _ZN7android5FenceD2Ev(void* self) {
    int* fd = fdOf(self);
    if (*fd != -1) close(*fd);
}
void _ZN7android5FenceD1Ev(void* self) { _ZN7android5FenceD2Ev(self); }

// Same bodies as N and A13 frameworks/native/libs/ui/Fence.cpp (A13 also dumps
// sync_file_info on the 3 s timeout; the plain error line is kept).
int _ZN7android5Fence4waitEi(void* self, int timeout) { return waitOn(*fdOf(self), timeout); }

int _ZN7android5Fence11waitForeverEPKc(void* self, const char* logname) {
    int fd = *fdOf(self);
    if (fd == -1) return 0;
    const int warningTimeout = 3000;
    int err = sync_wait(fd, warningTimeout);
    if (err < 0 && errno == ETIME) {
        __android_log_print(6 /* ANDROID_LOG_ERROR */, "Fence",
                            "waitForever: %s: fence %d didn't signal in %d ms", logname, fd,
                            warningTimeout);
        err = sync_wait(fd, -1);
    }
    return err < 0 ? -errno : 0;
}

int _ZNK7android5Fence3dupEv(void* self) { return dup(*fdOf(self)); }

}  // extern "C"

// ---- String8::setPathName(const char*), gone from A13 libutils ------------
// Imported by libui_ext.so and libcam.client.so. N body: copy the name, drop
// one trailing '/'. setTo(const char*, size_t) is still exported.
namespace android {
class String8;
}  // namespace android

extern "C" {

#ifdef __LP64__
int _ZN7android7String85setToEPKcm(android::String8*, const char*, size_t);
#define M95_STRING8_SETTO _ZN7android7String85setToEPKcm
#else
int _ZN7android7String85setToEPKcj(android::String8*, const char*, size_t);
#define M95_STRING8_SETTO _ZN7android7String85setToEPKcj
#endif

void _ZN7android7String811setPathNameEPKc(android::String8* self, const char* name) {
    size_t len = strlen(name);
    if (len > 0 && name[len - 1] == '/') len--;
    M95_STRING8_SETTO(self, name, len);
}

}  // extern "C"
