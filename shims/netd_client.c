/* libnetd_client.so (vendor, 32-bit): setNetworkForSocket for the VoLTE SIP
 * stack. volte_stack cannot link without it; the platform library is
 * system-only.
 *
 * volte_stack and wfca import only setNetworkForSocket. It is forwarded to the
 * LLNDK android_setsocknetwork(), packing the netId into a net_handle_t like
 * gethandlefromnetid() and converting the -errno return back to -1/errno.
 *
 * libcharon's protectFromVpn is intentionally not provided: libandroid_net
 * has no equivalent.
 */
#include <android/multinetwork.h>
#include <errno.h>
#include <stdint.h>

#define NETID_UNSET 0u /* system/netd/include/netid_client.h */

/* Must match kHandleMagic in frameworks/base/native/android/net.c. */
static const uint32_t kHandleMagic = 0xcafed00d;

int setNetworkForSocket(unsigned netId, int socketFd) {
    net_handle_t handle = netId == NETID_UNSET
            ? NETWORK_UNSPECIFIED
            : ((net_handle_t)netId << 32) | kHandleMagic;

    if (android_setsocknetwork(handle, socketFd) == 0)
        return 0;
    return -errno;
}
