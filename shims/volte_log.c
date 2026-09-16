// libm95volte_logfilter: keeps SIP traffic of the VoLTE daemons out of logcat.
//
// volte_stack, volte_ua and volte_imcb (32-bit) log whole SIP messages at INFO
// under tags such as "VoLTE REG" (IMSI, IMEI, phone numbers). The tags contain
// a space, so no log.tag.* property can name them.
//
// The daemons import only __android_log_print (and __android_log_assert). A
// TARGET_LD_SHIM_LIBS library is loaded before the executable's DT_NEEDED, so
// this definition wins over liblog's. VoLTE* lines below WARN are dropped;
// everything else goes to liblog unchanged.
//
// Built and wired only with M95_VOLTE_LOGFILTER=true.

#include <android/log.h>
#include <errno.h>
#include <stdarg.h>
#include <string.h>

__attribute__((visibility("default")))
int __android_log_print(int prio, const char* tag, const char* fmt, ...) {
    if (prio < ANDROID_LOG_WARN && tag != NULL && strncmp(tag, "VoLTE", 5) == 0)
        return -EPERM;

    va_list ap;
    va_start(ap, fmt);
    int ret = __android_log_vprint(prio, tag, fmt, ap);
    va_end(ap);
    return ret;
}
