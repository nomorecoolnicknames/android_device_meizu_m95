// android::AndroidRuntime::{getJNIEnv, registerNativeMethods} for
// libmeizucamera.so, in the camera HAL closure. Both are JNI helpers and the
// native HAL process has no JavaVM, so null/-1 returns are safe. The
// signatures reproduce the real class so the mangled names match.
struct _JNIEnv;
struct JNINativeMethod;

namespace android {
class AndroidRuntime {
 public:
  static int registerNativeMethods(_JNIEnv* env, const char* className,
                                   const JNINativeMethod* methods, int numMethods);
  static _JNIEnv* getJNIEnv();
};

int AndroidRuntime::registerNativeMethods(_JNIEnv*, const char*, const JNINativeMethod*, int) {
  return -1;
}

_JNIEnv* AndroidRuntime::getJNIEnv() {
  return nullptr;
}
}  // namespace android
