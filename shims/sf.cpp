// libm95shim_sf: legacy SurfaceComposerClient/SurfaceControl entry points.
//
// The N-era global-transaction Surface API is gone; libgui_ext, libaal,
// libshowlogo, thermalindicator and libperfservice need these symbols to load.
// They do not drive real transactions, so the stubs return inert values.
// sp<>-returning entries return a null pointer.
#include <stdint.h>

namespace android {
class String8;
class Rect;
class IBinder;
template <typename T>
class sp;
class Surface;
}  // namespace android

namespace {
struct NullSp {
    void* p;
};
}  // namespace

extern "C" {

// SurfaceComposerClient::openGlobalTransaction() -> void.
void _ZN7android21SurfaceComposerClient21openGlobalTransactionEv(void* /*self*/) {
}

// SurfaceComposerClient::closeGlobalTransaction(bool) -> void.
void _ZN7android21SurfaceComposerClient22closeGlobalTransactionEb(void* /*self*/,
                                                                  bool /*synchronous*/) {
}

// SurfaceComposerClient::createSurface(String8,w,h,format,flags) -> null sp<Surface>.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"
NullSp _ZN7android21SurfaceComposerClient13createSurfaceERKNS_7String8Ejjij(
        void* /*self*/, const android::String8& /*name*/, uint32_t /*w*/,
        uint32_t /*h*/, int32_t /*format*/, uint32_t /*flags*/) {
    NullSp r;
    r.p = 0;
    return r;
}
#pragma clang diagnostic pop

// SurfaceComposerClient::setDisplayProjection(sp<IBinder>,orient,layerStack,disp)
// -> NO_ERROR.
int _ZN7android21SurfaceComposerClient20setDisplayProjectionERKNS_2spINS_7IBinderEEEjRKNS_4RectES8_(
        void* /*self*/, const void* /*token*/, uint32_t /*orient*/,
        const android::Rect& /*layerStack*/, const android::Rect& /*display*/) {
    return 0;
}

// SurfaceControl methods -> NO_ERROR.
int _ZN7android14SurfaceControl8setLayerEj(void* /*self*/, uint32_t /*layer*/) {
    return 0;
}
int _ZN7android14SurfaceControl4showEv(void* /*self*/) { return 0; }
int _ZN7android14SurfaceControl4hideEv(void* /*self*/) { return 0; }
int _ZN7android14SurfaceControl5clearEv(void* /*self*/) { return 0; }
int _ZN7android14SurfaceControl7setSizeEjj(void* /*self*/, uint32_t /*w*/,
                                           uint32_t /*h*/) {
    return 0;
}

}  // extern "C"

// android::IDumpTunnel::asInterface(const sp<IBinder>&): MediaTek's N-era
// libgui extension, imported by libgui_ext.so. Returns a null sp<>.
//
// android::sp<T> is not trivially destructible, so on arm64 it is returned
// through the hidden sret pointer (x8). SpRet has a user-provided destructor
// to get the same return convention. (The NullSp entries above are only
// needed for symbol resolution.)
namespace {
struct SpRet {
    void* p;
    SpRet() : p(nullptr) {}
    ~SpRet() {}
};
}  // namespace

// clang's -Wreturn-type-c-linkage is exactly the point here: the C-named
// symbol must return a C++-ABI (memory-class) value.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"
extern "C" SpRet _ZN7android11IDumpTunnel11asInterfaceERKNS_2spINS_7IBinderEEE(void* /*binder*/) {
    return SpRet();
}

// static sp<IBinder> SurfaceComposerClient::getBuiltInDisplay(int32_t id),
// removed in Q. Returns a null sp<> through the sret slot, which
// libperfservice.so dereferences when non-null.
extern "C" SpRet _ZN7android21SurfaceComposerClient17getBuiltInDisplayEi(int32_t /*id*/) {
    return SpRet();
}
#pragma clang diagnostic pop

// static status_t SurfaceComposerClient::getDisplayInfo(const sp<IBinder>&,
// DisplayInfo*), removed in S. Imported by libgui_ext.so and libperfservice.so.
// Both callers ignore the status and read the struct, so it is filled with the
// panel's fixed values (1080x1920, 60 Hz, 480 dpi). SurfaceFlinger cannot be
// asked from a vendor process: it is not registered on /dev/vndbinder.
namespace {
// N/O/P layout (frameworks/native/include/ui/DisplayInfo.h); callers reserve
// exactly these 48 bytes.
struct M95DisplayInfoN {
    uint32_t w;
    uint32_t h;
    float xdpi;
    float ydpi;
    float fps;
    float density;
    uint8_t orientation;
    bool secure;
    int64_t appVsyncOffset;
    int64_t presentationDeadline;
};
static_assert(sizeof(M95DisplayInfoN) == 48, "N DisplayInfo is 48 bytes");
}  // namespace

extern "C" int32_t _ZN7android21SurfaceComposerClient14getDisplayInfoERKNS_2spINS_7IBinderEEEPNS_11DisplayInfoE(
        const void* /*display*/, M95DisplayInfoN* info) {
    if (info == nullptr) return -22;  // BAD_VALUE
    info->w = 1080;
    info->h = 1920;
    info->xdpi = 480.0f;
    info->ydpi = 480.0f;
    info->fps = 60.36f;
    info->density = 3.0f;
    info->orientation = 0;
    info->secure = true;
    info->appVsyncOffset = 1000000;
    info->presentationDeadline = 16567262;
    return 0;  // NO_ERROR
}
