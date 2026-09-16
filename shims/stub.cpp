// Empty DT_NEEDED placeholder for vendor blobs that list a system-only library
// but import no symbols from it.
//
// An empty library under the real soname would shadow the system library for
// the blobs that do import from it, so these stubs keep unique names and only
// the zero-import consumers are redirected to them:
//   libcamera_client   -> camera.mt6797.so and four more
//   libmedia           -> 18 (32-bit) / 15 (64-bit) consumers
//   libmediautils      -> audio.primary.mt6797.so only
//   libandroid_runtime -> 3 (32-bit) / 2 (64-bit) consumers
extern "C" void __m95_stub_marker(void) {}
