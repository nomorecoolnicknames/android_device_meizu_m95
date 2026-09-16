#!/system/bin/sh
# Publish the factory Bluetooth address from MTK NVRAM as
# persist.service.bdroid.bdaddr. The Bluetooth HAL needs ro.bt.bdaddr_path,
# ro.boot.btmacaddr or this property and aborts without one; the address is
# the first six bytes of /data/nvram/APCFG/APRDEB/BT_Addr.

set -u

NV=/data/nvram/APCFG/APRDEB/BT_Addr

[ -r "$NV" ] || exit 0

# Already published: keep a user- or framework-set address.
case "$(getprop persist.service.bdroid.bdaddr)" in
    ??:??:??:??:??:??) exit 0 ;;
esac

addr=$(od -An -tx1 -N6 "$NV" 2>/dev/null | tr -d ' \n' | tr 'a-f' 'A-F')

# Twelve hex digits, and not one of the unprovisioned NVRAM patterns.
case "$addr" in
    ????????????) ;;
    *) exit 0 ;;
esac
[ "$addr" = "000000000000" ] && exit 0
[ "$addr" = "FFFFFFFFFFFF" ] && exit 0

formatted=$(echo "$addr" | sed 's/../&:/g; s/:$//')
setprop persist.service.bdroid.bdaddr "$formatted"

exit 0
