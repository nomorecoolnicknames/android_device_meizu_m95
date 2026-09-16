// AndroidBitmap_* for the Meizu camera libraries in the camera HAL closure
// (libcam.common.meizu.so, libphoto_timestamp.so); libjnigraphics is
// system-only. The native HAL process has no JavaVM, so returning an error is
// safe. Unique soname, so the system libjnigraphics stays visible elsewhere.
int AndroidBitmap_getInfo(void* env, void* jbitmap, void* info) {
    (void)env;
    (void)jbitmap;
    (void)info;
    return -1;
}

int AndroidBitmap_lockPixels(void* env, void* jbitmap, void** addrPtr) {
    (void)env;
    (void)jbitmap;
    (void)addrPtr;
    return -1;
}

int AndroidBitmap_unlockPixels(void* env, void* jbitmap) {
    (void)env;
    (void)jbitmap;
    return -1;
}
