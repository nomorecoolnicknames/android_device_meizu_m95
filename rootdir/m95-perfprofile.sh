# Performance / thermal profile for the MT6797, sourced by m95-cpuset.sh when
# persist.vendor.m95.perfprofile=1 (read once at service start).
#
# Under sustained load the stock policy lets the A72 cores run uncapped at
# their least efficient OPP while the GPU is cut to its lowest one. This
# profile raises the ATM GPU floor, makes PPM account for the A72 cluster and
# lets the interactive governor honour hispeed_freq on every cluster.

# Sub-switches, read once like the main one:
#   persist.vendor.m95.perfprofile.big  = 0: keep the A72 pair (cpu8-9) offline.
#   persist.vendor.m95.perfprofile.park = 1: experimental, see pp_cores_once.
PP_BIG=$(/vendor/bin/getprop persist.vendor.m95.perfprofile.big 2>/dev/null)
PP_PARK=$(/vendor/bin/getprop persist.vendor.m95.perfprofile.park 2>/dev/null)

# Cores m95-cpuset.sh brings online at start
if [ "$PP_BIG" = 0 ]; then
    PP_BOOT_CPUS="1 2 3 4 5 6 7"
else
    PP_BOOT_CPUS="1 2 3 4 5 6 7 8 9"
fi

# Cpuset: foreground uses the eight A53 cores; the A72 stay with top-app and
# system-background (SurfaceFlinger).
PP_FOREGROUND=0-7

# Readbacks use shell builtins only: a vendor domain may not exec /system/bin
# grep/sed. pp_has <file> <case-pattern>: some line of <file> matches.
pp_has() {
    [ -r "$1" ] || return 1
    while IFS= read -r _l; do
        case "$_l" in $2) return 0 ;; esac
    done < "$1"
    return 1
}

# write $2 to $1 unless $1 already reads back as $2
pp_set() {
    [ -w "$1" ] || return 0
    _v=
    read -r _v < "$1" 2>/dev/null
    [ "$_v" = "$2" ] || echo "$2" > "$1" 2>/dev/null
}

# Thermal
TD=/proc/driver/thermal
# Continuous TM mode 0 (the ATM target is the cpu_adaptive_0 trip), Meizu's
# line from thermal.off.conf.
PP_CTM="0 85000 67000 45000 48000 75000 61000 355000 6000 285016 4667 25 25 10000"
# ATM cooler 0 (id first_step theta_rise theta_fall min_change min_cpu max_cpu
# min_gpu max_gpu): GPU floor 1000 mW; CPU floor derived from the chip's
# calibrated max power (max - 5200, at least 1300).
PP_MIN_CPU=1300
_mx=
if [ -r /proc/ppm/policy/thermal_cur_power ]; then
    while IFS= read -r _l; do
        case "$_l" in "max power = "*) _mx=${_l#max power = } ;; esac
    done < /proc/ppm/policy/thermal_cur_power
fi
case "$_mx" in
    ''|*[!0-9]*) ;;
    *) [ $((_mx - 5200)) -gt $PP_MIN_CPU ] && PP_MIN_CPU=$((_mx - 5200)) ;;
esac
PP_ATM0="0 3000 10 15 1 $PP_MIN_CPU 0 1000 0"
# Trip table: ATM holds 80 C; static CPU-only caps of 4.0 W from 72 C and
# 3.4 W from 76 C (DTM cooler cpuNN = 700 + 100*NN mW). sysrst at 110 C.
# Format: 10 triplets "temp type cooler" + polling ms.
PP_TZCPU="4 110000 0 mtktscpu-sysrst 80000 0 cpu_adaptive_0 76000 0 cpu27 72000 0 cpu33 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 40"
PP_DTM="cpu27 cpu33"

pp_thermal_once() {
    [ -w "$TD/tzcpu" ] || return 0
    # thermal_manager loads thermal.conf after this service starts.
    pp_has "$TD/clctm" 'ctm 0' || echo "$PP_CTM" > "$TD/clctm" 2>/dev/null
    pp_atm0_ok || echo "$PP_ATM0" > "$TD/clatm_setting" 2>/dev/null
    # Rewritten only when it differs: a tzcpu write resets ATM.
    if ! pp_has "$TD/tzcpu" 'trip_1=80000 0 cpu_adaptive_0' ||
       ! pp_has "$TD/tzcpu" 'trip_3=72000 0 cpu33'; then
        echo "$PP_TZCPU" > "$TD/tzcpu" 2>/dev/null
    fi
    # 2 C hysteresis on the static caps
    for _c in $PP_DTM; do
        pp_has "/proc/mtkcooler/$_c" 'EXIT val=* threshold=2000 *' ||
            echo "EXIT 2000" > "/proc/mtkcooler/$_c" 2>/dev/null
    done
}

# Cooler 0 of clatm_setting carries both floors.
pp_atm0_ok() {
    [ -r "$TD/clatm_setting" ] || return 1
    _in=0; _okc=0; _okg=0
    while IFS= read -r _l; do
        case "$_l" in
            cpu_adaptive_00) _in=1 ;;
            cpu_adaptive_*) _in=0 ;;
            " m cpu = $PP_MIN_CPU") [ $_in = 1 ] && _okc=1 ;;
            " m gpu = 1000") [ $_in = 1 ] && _okg=1 ;;
        esac
    done < "$TD/clatm_setting"
    [ $_okc = 1 ] && [ $_okg = 1 ]
}

# PPM: pin the power state to 4LL_L so every cluster is in the thermal budget.
# The readback shows HICA's own state when nothing is pinned, so the first
# pass writes unconditionally.
PP_HICA=/proc/ppm/policy/hica_power_state
PP_HICA_SET=0
pp_ppm_once() {
    [ -w "$PP_HICA" ] || return 0
    if [ "$PP_HICA_SET" = 0 ] || ! pp_has "$PP_HICA" 'hica_state = 2 (*'; then
        echo 2 > "$PP_HICA" 2>/dev/null && PP_HICA_SET=1
    fi
}

# Governor: cpufreq_power_mode 2 makes the interactive governor honour
# hispeed_freq on every cluster. target_loads/above_hispeed_delay are global
# and keyed by frequency (above 2 GHz only the A72 exist).
IA=/sys/devices/system/cpu/cpufreq/interactive
PP_TARGET_LOADS="85 1391000:90 1781000:95 2000000:99"
PP_ABOVE_HISPEED="20000 1781000:60000"
pp_gov_once() {
    pp_has /proc/cpufreq/cpufreq_power_mode 'Just_Make_Mode' ||
        echo 2 > /proc/cpufreq/cpufreq_power_mode 2>/dev/null
    pp_set "$IA/target_loads" "$PP_TARGET_LOADS"
    pp_set "$IA/above_hispeed_delay" "$PP_ABOVE_HISPEED"
    # Touch boost floor for LL/L
    pp_set /proc/perfmgr/touch/tb_freq 1391000
}

pp_once() {
    pp_thermal_once
    pp_ppm_once
    pp_gov_once
}

# Cores: hps_suspend() offlines cpu8-9 on every suspend and nothing brings
# them back.
#
# park=1 (experimental): with the screen off, offline every core but cpu0;
# deep idle and SODI need a single online core.
BL=/sys/class/leds/lcd-backlight/brightness
PP_DARK=0
PP_PARKED=0
# The backlight reads 0 until the lights HAL first writes it, so darkness only
# counts once the screen has been seen on.
PP_SEEN_ON=0

pp_screen_on() {
    _b=1
    read -r _b < "$BL" 2>/dev/null
    [ "$_b" != 0 ]
}

# pp_cpu <n> <0|1>: set cpu<n> online state unless it is already there
pp_cpu() {
    _o=
    read -r _o < "/sys/devices/system/cpu/cpu$1/online" 2>/dev/null
    [ -n "$_o" ] && [ "$_o" != "$2" ] &&
        echo "$2" > "/sys/devices/system/cpu/cpu$1/online" 2>/dev/null
    return 0
}

pp_cores_once() {
    if pp_screen_on; then
        PP_SEEN_ON=1
        PP_DARK=0
        # Every pass, so a failed cpu_up is retried.
        if [ "$PP_PARK" = 1 ]; then
            for _c in 1 2 3 4 5 6 7; do pp_cpu $_c 1; done
            PP_PARKED=0
        fi
        if [ "$PP_BIG" = 0 ]; then
            pp_cpu 9 0; pp_cpu 8 0
        else
            pp_cpu 8 1; pp_cpu 9 1
        fi
        return 0
    fi
    [ "$PP_SEEN_ON" = 1 ] || return 0
    PP_DARK=$((PP_DARK + 1))
    if [ "$PP_BIG" = 0 ]; then
        pp_cpu 9 0; pp_cpu 8 0
    fi
    if [ "$PP_PARK" = 1 ] && [ "$PP_DARK" -ge 2 ]; then
        for _c in 9 8 7 6 5 4 3 2 1; do pp_cpu $_c 0; done
        PP_PARKED=1
    fi
    return 0
}
