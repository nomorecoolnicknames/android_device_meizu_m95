#!/vendor/bin/sh
# CPU placement, thermal trip table and LMK tiers for the MT6797, re-asserted
# every five seconds (init.m95.cpuset.rc):
#  1. hps hotplug off and all ten cores online, unless persist.vendor.m95.hps=1
#     on a kernel with the hotplug fixes.
#  2. cpuset masks: background/restricted on the LITTLE cluster (0-3).
#  3. mtktscpu trip table (thermal ladder below).
#  4. LMK minfree tiers of init.m95.mem.rc, which lmkd rewrites.
#  5. A72 cores (cpu8-9) back online after suspend while the screen is on.
# With persist.vendor.m95.perfprofile=1, m95-perfprofile.sh replaces 3 and 5.

set -u

# Performance profile, read once at start. `.` on a missing file would exit
# the shell, so check for it first.
PERFPROFILE=$(/vendor/bin/getprop persist.vendor.m95.perfprofile 2>/dev/null)
if [ "$PERFPROFILE" = 1 ] && [ -r /vendor/bin/m95-perfprofile.sh ]; then
    . /vendor/bin/m95-perfprofile.sh
else
    PERFPROFILE=
fi

# Hotplug: with hps on, kernels without the stop_machine hotplug fixes panic
# in list_del, so hps is left on only for kernels that report the fix
# (forge_hotplug_fixed) or are known by their uname. Otherwise all cores stay
# online with hps off. Not with the perf profile, which manages the cores.
HPS=
if [ -z "$PERFPROFILE" ] && [ "$(/vendor/bin/getprop persist.vendor.m95.hps 2>/dev/null)" = 1 ]; then
    _fix=$(cat /sys/module/stop_machine/parameters/forge_hotplug_fixed 2>/dev/null)
    read -r _ver < /proc/version
    # Kernels that carry the marker, in case the read fails.
    case "$_fix:$_ver" in
        Y:*) HPS=1 ;;
        *3.18.22-eng-g1c4ce619*|*3.18.22-eng-g3243163a*|*3.18.22-eng-gf3c39e3e*|*3.18.22-eng-g9ab6e192*) HPS=1 ;;
        *3.18.22-eng-g61fd3e0e*|*3.18.22-eng-g6039b9bd*) HPS=1 ;;
    esac
fi
if [ "$HPS" = 1 ]; then
    echo 1 > /proc/hps/enabled 2>/dev/null || true
else
    echo 0 > /proc/hps/enabled 2>/dev/null || true
    for _cpu in ${PP_BOOT_CPUS:-1 2 3 4 5 6 7 8 9}; do
        echo 1 > "/sys/devices/system/cpu/cpu$_cpu/online" 2>/dev/null || true
    done
fi

# Thermal ladder, from persist.vendor.m95.thermal or ro.vendor.m95.thermal:
#   0 - ATM enters at 85 C (cpu_adaptive_0/1 85/80)
#   A - stock entry 58/57 C (thermal.conf)
#   B - A + ATM GPU floor of 800 mW
#   C - B + PHPB cpu step 4x smaller
#   D - C + clctm mode 1 with the stock board-temperature curve
# thermal_manager loads thermal.conf after this service starts; each knob is
# written only when its readback differs (a tzcpu write resets ATM).
TD=/proc/driver/thermal
TZCPU=$TD/tzcpu
THERMAL_ARM=$(/vendor/bin/getprop persist.vendor.m95.thermal 2>/dev/null)
[ -n "$THERMAL_ARM" ] || THERMAL_ARM=$(/vendor/bin/getprop ro.vendor.m95.thermal 2>/dev/null)
case "$THERMAL_ARM" in A|B|C|D) ;; *) THERMAL_ARM=0 ;; esac
TH_TZCPU_0="10 110000 0 mtktscpu-sysrst 85000 0 cpu_adaptive_0 80000 0 cpu_adaptive_1 65000 0 no-cooler 63000 0 no-cooler 60000 0 no-cooler 55000 0 no-cooler 50000 0 no-cooler 45000 0 no-cooler 40000 0 no-cooler 40"
TH_TZCPU_STOCK="3 110000 0 mtktscpu-sysrst 58000 0 cpu_adaptive_0 57000 0 cpu_adaptive_1 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 40"
TH_ATM0_B="0 3000 10 15 1 560 0 800 0"
TH_CTM_D="1 85000 58000 48000 50000 75000 52000 733000 13500 627000 11500 500 500 13500"

# Shell builtins only: a vendor domain may not exec /system/bin/grep.
# th_has <file> <case-pattern>: some line of <file> matches.
th_has() {
    [ -r "$1" ] || return 1
    while IFS= read -r _l; do
        case "$_l" in $2) return 0 ;; esac
    done < "$1"
    return 1
}

# Cooler 0 of clatm_setting (cpu_adaptive_00) prints " m gpu = N".
th_atm0_gpu_is() {
    [ -r "$TD/clatm_setting" ] || return 1
    _in=0
    while IFS= read -r _l; do
        case "$_l" in
            cpu_adaptive_00) _in=1 ;;
            cpu_adaptive_*) _in=0 ;;
            " m gpu = $1") [ $_in = 1 ] && return 0 ;;
        esac
    done < "$TD/clatm_setting"
    return 1
}

thermal_once() {
    [ -w "$TZCPU" ] || return 0
    if [ "$THERMAL_ARM" = 0 ]; then
        th_has "$TZCPU" '*trip_1=85000 0 cpu_adaptive_0*' ||
            echo "$TH_TZCPU_0" > "$TZCPU" 2>/dev/null || true
        return 0
    fi
    th_has "$TZCPU" '*trip_1=58000 0 cpu_adaptive_0*' ||
        echo "$TH_TZCPU_STOCK" > "$TZCPU" 2>/dev/null || true
    [ "$THERMAL_ARM" = A ] && return 0
    th_atm0_gpu_is 800 || echo "$TH_ATM0_B" > "$TD/clatm_setting" 2>/dev/null || true
    [ "$THERMAL_ARM" = B ] && return 0
    th_has "$TD/clphpb" '\[cpu\] 40 40' || echo "cpu 40 40" > "$TD/clphpb" 2>/dev/null || true
    [ "$THERMAL_ARM" = C ] && return 0
    th_has "$TD/clctm" 'ctm 1' || echo "$TH_CTM_D" > "$TD/clctm" 2>/dev/null || true
}

# Per-set masks. 3.18 has no uclamp or schedtune, so the cpuset is the only
# way to keep background apps off the big cores. system-background stays wide:
# SurfaceFlinger runs GPU composition from it.
LITTLE=0-3

sync_once() {
    # Prefer the present set; fall back to the online mask on kernels that
    # refuse offline cpus.
    present=$(cat /sys/devices/system/cpu/present 2>/dev/null)
    online=$(cat /sys/devices/system/cpu/online 2>/dev/null)
    [ -n "$present$online" ] || return 0

    for set in foreground background top-app system-background restricted \
               foreground/boost camera-daemon; do
        [ -d "/dev/cpuset/$set" ] || continue
        case "$set" in
            background|restricted) want=$LITTLE ;;
            foreground) want=${PP_FOREGROUND:-$present} ;;
            *) want=$present ;;
        esac
        if [ -n "$want" ] && echo "$want" > "/dev/cpuset/$set/cpus" 2>/dev/null; then
            continue
        fi
        [ -n "$online" ] && echo "$online" > "/dev/cpuset/$set/cpus" 2>/dev/null || true
    done
}

# LMK tiers: lmkd rewrites the kernel parameters on every LMK_TARGET.
LMK_MINFREE=18432,23040,27648,32256,102400,122880
LMK_PARAM=/sys/module/lowmemorykiller/parameters/minfree
lmk_once() {
    [ -w "$LMK_PARAM" ] || return 0
    [ "$(cat "$LMK_PARAM" 2>/dev/null)" = "$LMK_MINFREE" ] && return 0
    echo "$LMK_MINFREE" > "$LMK_PARAM" 2>/dev/null || true
}

# hps_suspend() takes cpu8-9 down on every suspend without bringing them back.
# Bring them online while the screen is on.
big_back_once() {
    _b=1
    read -r _b < /sys/class/leds/lcd-backlight/brightness 2>/dev/null
    [ "$_b" = 0 ] && return 0
    for _c in 8 9; do
        _o=
        read -r _o < "/sys/devices/system/cpu/cpu$_c/online" 2>/dev/null
        [ "$_o" = 0 ] && echo 1 > "/sys/devices/system/cpu/cpu$_c/online" 2>/dev/null
    done
    return 0
}

# Five seconds: without the kernel cpuset fix cores were dropped from a set
# within seconds.
while true; do
    if [ "$PERFPROFILE" = 1 ]; then
        pp_cores_once
        # Parked (screen off): poll the backlight every second so the cores
        # are back right after unlock.
        if [ "$PP_PARKED" = 1 ]; then
            sleep 1
            continue
        fi
        sync_once
        pp_once
    else
        # With hps on, it owns the cores.
        [ "$HPS" = 1 ] || big_back_once
        sync_once
        thermal_once
    fi
    lmk_once
    sleep 5
done
