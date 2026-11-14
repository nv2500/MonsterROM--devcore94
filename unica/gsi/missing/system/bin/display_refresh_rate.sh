#!/system/bin/sh
# Display, System Settings, Vibration & Battery Charge Limit Persistence Service
# Enforces 120Hz refresh rate (prevents green tint), tactile vibration, battery charge pass-through, and power key instant response.
# Provides out-of-the-box defaults (Extra small display size, 30-min timeout) on first boot/factory reset without overriding user selections on subsequent reboots.

export PATH=/system/bin:/system/xbin:$PATH

LOG_TAG="display_settings_mgr"
LOG_FILE="/data/local/tmp/display_refresh_rate.log"
log_info() {
    log -p i -t "$LOG_TAG" "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

# Single instance lock (stored in devtmpfs in RAM so it never survives a reboot)
PIDFILE="/dev/.display_refresh_rate.pid"
rm -f /data/local/tmp/display_refresh_rate.pid 2>/dev/null

if [ -f "$PIDFILE" ]; then
    OLDPID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLDPID" ] && [ "$OLDPID" != "$$" ] && grep -q "display_refresh_rate" "/proc/$OLDPID/cmdline" 2>/dev/null; then
        log_info "Already running as PID $OLDPID. Exiting duplicate."
        exit 0
    fi
fi
echo $$ > "$PIDFILE"

# 1. Wait until boot completes and system services are responsive
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

log_info "Boot completed. Waiting for SettingsProvider and WindowManager..."

# Ensure SettingsProvider and WindowManager are actively accepting commands
while ! settings get system screen_off_timeout >/dev/null 2>&1; do
    sleep 1
done
while ! cmd window density >/dev/null 2>&1; do
    sleep 1
done

log_info "Services ready. Initializing settings..."

# Display Corner Radius Hardware Matching (Galaxy S21 FE 24px hardware corners)
if [ -x /data/adb/ksu/bin/resetprop ]; then
    /data/adb/ksu/bin/resetprop -n ro.oplus.display.rc.size 38,38,38,38
elif which resetprop >/dev/null 2>&1; then
    resetprop -n ro.oplus.display.rc.size 38,38,38,38
fi
log_info "Enforced display corner radius property ro.oplus.display.rc.size=30,30,30,30."


# Bluetooth Runtime Permissions Enforcement (Ensures SystemUI and companion apps never crash on toggle)
for pkg in com.android.systemui com.oplus.wirelesssettings com.coloros.oshare com.oplus.padconnect; do
    pm grant "$pkg" android.permission.BLUETOOTH_CONNECT 2>/dev/null
    pm grant "$pkg" android.permission.BLUETOOTH_SCAN 2>/dev/null
    pm grant "$pkg" android.permission.BLUETOOTH_ADVERTISE 2>/dev/null
done
log_info "Ensured Bluetooth runtime permissions for SystemUI and companion packages."

# Default Device Name Enforcement (Defaults to Galaxy S21 FE on factory reset / first boot)
CUR_DEV_NAME=$(settings get global revise_device_name 2>/dev/null)
if [ "$CUR_DEV_NAME" = "一加平板 Pro" ] || [ -z "$CUR_DEV_NAME" ] || [ "$CUR_DEV_NAME" = "null" ]; then
    settings put global device_name "Galaxy S21 FE"
    settings put global revise_device_name "Galaxy S21 FE"
    settings put system revise_device_name "Galaxy S21 FE"
    settings put secure bluetooth_name "Galaxy S21 FE"
    log_info "Initialized default device name to Galaxy S21 FE."
fi

# Default Swipe Animations Enforcement (Defaults to enabled on factory reset / first boot)
CUR_SWIPE_ANIM=$(settings get secure oplus_third_part_apps_predictive_back 2>/dev/null)
if [ -z "$CUR_SWIPE_ANIM" ] || [ "$CUR_SWIPE_ANIM" = "null" ]; then
    settings put secure oplus_third_part_apps_predictive_back 1
    settings put system double_wake_status 1 2>/dev/null
    settings put system double_tap_to_wake 1 2>/dev/null
    settings put system oplus_customize_gesture_double_touch 1 2>/dev/null
    log_info "Initialized default oplus_third_part_apps_predictive_back=1."
fi

# 2. Refresh Rate (120 Hz locked globally to prevent display green tint & ensure smoothness)
settings put system min_refresh_rate 120.0
settings put global min_refresh_rate 120.0
settings put system peak_refresh_rate 120.0
settings put global peak_refresh_rate 120.0
settings put secure oplus_customize_screen_refresh_rate 3
settings put system oplus_customize_screen_refresh_rate 3
cmd display set-user-preferred-display-mode 1848 2960 120.00001 0 true 2>/dev/null
cmd display set-match-content-frame-rate-pref 0 2>/dev/null
log_info "Applied 120Hz refresh rate settings."

# Enable OLED burn-in protection overlay
cmd overlay enable com.android.internal.display.burnin.overlay 2>/dev/null
log_info "Ensured burn-in protection overlay is active."

# Power Button Responsiveness (Eliminates 5-second Oplus Theia HAL wait in lib_inputflingerEx)
setprop persist.sys.saupwk_test 1
log_info "Ensured power button instant responsiveness (saupwk_test=1)."

# 3. Vibration & Haptics Persistence
apply_vibration_settings() {
    settings put secure gesture_side_back_vibrate_enable 1 2>/dev/null
    settings put system gesture_side_back_vibrate_enable 1 2>/dev/null
    settings put secure gesture_enable_back_vibrate 1 2>/dev/null
    settings put system gesture_enable_back_vibrate 1 2>/dev/null
    settings put system haptic_feedback_intensity 3 2>/dev/null
    settings put system keyboard_vibration_intensity 3 2>/dev/null
    settings put system haptic_feedback_enabled 1 2>/dev/null
    settings put system vibrate_on_touch 1 2>/dev/null
    settings put system input_method_key_vibration 1 2>/dev/null
    settings put system keyboard_vibration_enabled 1 2>/dev/null
    settings put system oplus_customize_key_vibrate 1 2>/dev/null
    settings put system vibrate_when_ringing 1 2>/dev/null
    settings put system vibrate_when_silent 1 2>/dev/null
    settings put system vibrate_in_silent 1 2>/dev/null
}
apply_vibration_settings
log_info "Applied vibration settings."

# 4. Battery Charge Limit Enforcement (Custom charging limit -> Hardware Pass-Through)
apply_battery_charge_limit() {
    CHG_SWITCH=$(settings get system regular_charge_protection_switch_state 2>/dev/null)
    CHG_LIMIT=$(settings get system regular_charge_protection_open_power_level 2>/dev/null)

    case "$CHG_LIMIT" in
        ''|*[!0-9]*) CHG_LIMIT=80 ;;
    esac

    # Ensure batt_slate_mode is ALWAYS 0 so USB VBUS is NEVER cut off (device remains externally powered)
    CUR_SLATE=$(cat /sys/class/power_supply/battery/batt_slate_mode 2>/dev/null)
    if [ "$CUR_SLATE" = "1" ]; then
        echo 0 > /sys/class/power_supply/battery/batt_slate_mode
        log_info "Cleared batt_slate_mode=0 to ensure USB external power remains active."
    fi

    CUR_FULL_CAP=$(cat /sys/class/power_supply/battery/batt_full_capacity 2>/dev/null)

    if [ "$CHG_SWITCH" = "1" ]; then
        if [ "$CUR_FULL_CAP" != "$CHG_LIMIT" ]; then
            echo "$CHG_LIMIT" > /sys/class/power_supply/battery/batt_full_capacity
            log_info "Battery charge limit enabled ($CHG_LIMIT%): set batt_full_capacity=$CHG_LIMIT (hardware pass-through, 0mA current at limit)."
        fi
    else
        if [ "$CUR_FULL_CAP" != "0" ] && [ "$CUR_FULL_CAP" != "100" ]; then
            echo 0 > /sys/class/power_supply/battery/batt_full_capacity
            log_info "Battery charge limit disabled: restored batt_full_capacity=0 (normal charging to 100%)."
        fi
    fi
}
apply_battery_charge_limit
log_info "Applied initial battery charge limit check."

# 5. First Boot / Factory Reset Out-of-the-Box Defaults
# On first boot after installation or factory reset (/data wipe), initialize defaults:
# - Display size: Extra small (480, index 0)
# - Auto screen off timeout: 30 minutes (1800000)
# On subsequent boots, the system preserves whatever option the user selects normally.
INIT_FLAG="/data/system/.default_preferences_applied"
if [ ! -f "$INIT_FLAG" ]; then
    log_info "First boot / factory reset detected. Setting out-of-the-box defaults (Extra small, 30m timeout)..."
    settings put secure display_density_forced 480
    settings put system display_density_index_manual 0
    cmd window density 480
    settings put system screen_off_timeout 1800000
    settings put system last_manual_screen_off_timeout 1800000
    # Set Gboard as default IME
    ime enable com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME 2>/dev/null
    ime set com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME 2>/dev/null
    settings put secure default_input_method com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME 2>/dev/null
    settings put secure enabled_input_methods com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME 2>/dev/null
    settings put secure oplus_third_part_apps_predictive_back 1
    settings put system double_wake_status 1 2>/dev/null
    settings put system double_tap_to_wake 1 2>/dev/null
    settings put system oplus_customize_gesture_double_touch 1 2>/dev/null
    # System Launcher Out-of-the-Box Defaults:
    # 1. App Startup Animation Speed (Fast: 0)
    settings put secure setting_app_startup_anim_speed 0
    # 2. Home Screen Layout (10x6 Grid)
    settings put secure launcher_layout_parameter '{"layout_cellcount_x":10,"layout_cellcount_y":6}'
    settings put system layout_cellcount_x 10
    settings put system layout_cellcount_y 6
    settings put system useTabletNewLayout 2
    # 3. Swipe Down on Home Screen (Notifications & Quick Settings)
    settings put secure launcher_slid_slip_enable_state 1
    # 4. Double Tap to Lock Screen on Launcher
    settings put secure oplus_customize_gesture_double_touch_off_launcher 1
    # 5. Speed / Quick Unlock
    settings put secure skip_speed_unlock 1
    # 6. Display RAM/Memory Info in Recent Tasks
    settings put secure allow_memory_info_display 1
    # 7. Launcher Taskbar Defaults
    settings put system enable_launcher_taskbar 1
    settings put system enable_launcher_tools_longpress_entry 1
    settings put system enable_launcher_tools_transient_entry 1

    # 8. Seed default launcher shared_prefs and databases from /system/etc/launcher_defaults if present
    if [ -d /system/etc/launcher_defaults ]; then
        LAUNCHER_DE_DIR="/data/user_de/0/com.android.launcher"
        mkdir -p "$LAUNCHER_DE_DIR/shared_prefs" "$LAUNCHER_DE_DIR/databases"
        cp -f /system/etc/launcher_defaults/shared_prefs/* "$LAUNCHER_DE_DIR/shared_prefs/" 2>/dev/null
        cp -f /system/etc/launcher_defaults/databases/* "$LAUNCHER_DE_DIR/databases/" 2>/dev/null
        LAUNCHER_UID=$(stat -c "%u" "$LAUNCHER_DE_DIR" 2>/dev/null || echo 10120)
        chown -R "$LAUNCHER_UID:$LAUNCHER_UID" "$LAUNCHER_DE_DIR/shared_prefs" "$LAUNCHER_DE_DIR/databases" 2>/dev/null
        chmod 0770 "$LAUNCHER_DE_DIR/shared_prefs" "$LAUNCHER_DE_DIR/databases" 2>/dev/null
        chmod 0660 "$LAUNCHER_DE_DIR/shared_prefs"/* "$LAUNCHER_DE_DIR/databases"/* 2>/dev/null
        restorecon -R "$LAUNCHER_DE_DIR" 2>/dev/null
        log_info "Seeded default launcher preferences and workspace database."
    fi

    touch "$INIT_FLAG"
    sync
    log_info "Out-of-the-box defaults written. Density: $(cmd window density 2>&1 | tr '\n' ' '), Timeout: $(settings get system screen_off_timeout)"
else
    log_info "User preferences already initialized; leaving user settings untouched."
fi

# 6. Double Tap to Wake Persistence (Samsung TSP Always On Touch)
LAST_DT2W_STATE=""
apply_dt2w_settings() {
    DT2W_ENABLE=$(settings get system double_wake_status 2>/dev/null)
    if [ -z "$DT2W_ENABLE" ] || [ "$DT2W_ENABLE" = "null" ]; then
        DT2W_ENABLE=1
        settings put system double_wake_status 1 2>/dev/null
        settings put system double_tap_to_wake 1 2>/dev/null
        settings put system oplus_customize_gesture_double_touch 1 2>/dev/null
    fi

    if [ "$DT2W_ENABLE" != "$LAST_DT2W_STATE" ]; then
        if [ -f /sys/class/sec/tsp/cmd ]; then
            chmod 666 /sys/class/sec/tsp/cmd 2>/dev/null
            echo -n "aot_enable,$DT2W_ENABLE" > /sys/class/sec/tsp/cmd 2>/dev/null
            LAST_DT2W_STATE="$DT2W_ENABLE"
            log_info "Applied Samsung TSP Always On Touch (aot_enable,$DT2W_ENABLE)."
        fi
    fi
}
apply_dt2w_settings
log_info "Applied initial double tap to wake setting."

# Synchronize Samsung TSP power state with screen on/off events for Double Tap to Wake
sync_tsp_screen_state() {
    log_info "Starting Samsung TSP screen state synchronizer..."
    # Initial state sync
    if dumpsys power 2>/dev/null | grep -q "mWakefulness=Asleep"; then
        DT2W_ENABLE=$(settings get system double_wake_status 2>/dev/null)
        if [ "$DT2W_ENABLE" != "0" ] && [ -f /sys/class/sec/tsp/enabled ]; then
            echo "1,0" > /sys/class/sec/tsp/enabled 2>/dev/null
            log_info "Initial state asleep: TSP set to low power gesture mode (1,0)."
        fi
    else
        if [ -f /sys/class/sec/tsp/enabled ]; then
            echo "2,1" > /sys/class/sec/tsp/enabled 2>/dev/null
            log_info "Initial state awake: TSP set to active mode (2,1)."
        fi
    fi

    while true; do
        logcat -T 1 -b events -s power_screen_state | while read -r line; do
            case "$line" in
                *"power_screen_state: [0,"*)
                    DT2W_ENABLE=$(settings get system double_wake_status 2>/dev/null)
                    if [ "$DT2W_ENABLE" != "0" ]; then
                        if [ -f /sys/class/sec/tsp/enabled ]; then
                            echo "1,0" > /sys/class/sec/tsp/enabled 2>/dev/null
                            log_info "Screen off: TSP entered low power gesture mode (1,0)."
                        fi
                    fi
                    ;;
                *"power_screen_state: [1,"*)
                    if [ -f /sys/class/sec/tsp/enabled ]; then
                        echo "2,1" > /sys/class/sec/tsp/enabled 2>/dev/null
                        log_info "Screen on: TSP returned to active mode (2,1)."
                    fi
                    ;;
            esac
        done
        sleep 2
    done
}
sync_tsp_screen_state &

# 7. Continuous Maintenance Loop
while true; do
    sleep 3

    # Enforce 120Hz globally (prevent apps from dropping to 60Hz and causing green tint)
    CUR_MIN_RATE=$(settings get system min_refresh_rate)
    if [ "$CUR_MIN_RATE" != "120.0" ]; then
        settings put system min_refresh_rate 120.0
        settings put global min_refresh_rate 120.0
        settings put system peak_refresh_rate 120.0
        settings put global peak_refresh_rate 120.0
        settings put secure oplus_customize_screen_refresh_rate 3
        settings put system oplus_customize_screen_refresh_rate 3
        cmd display set-user-preferred-display-mode 1848 2960 120.00001 0 true 2>/dev/null
    fi

    # Enforce battery charge limit dynamically (hardware pass-through)
    apply_battery_charge_limit

    # Enforce Double Tap to Wake state
    apply_dt2w_settings
done
