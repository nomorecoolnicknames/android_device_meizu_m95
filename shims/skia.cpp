// libskia (stub): DT_NEEDED placeholder for Nougat blobs.
//
// Skia is part of libhwui, so there is no libskia.so. The blobs that list it
// (libcam.camadapter, libem_wifi_jni, libimsma_socketwrapper, libimsma_rtp,
// libjni_lomoeffect) import no Sk* symbols, so an empty library satisfies them.
// It exports nothing: N-era Sk* symbols cannot be mapped onto current skia.
extern "C" void __m95_libskia_stub_marker(void) {}
