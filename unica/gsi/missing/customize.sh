source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MOD_DIR="$SRC_DIR/unica/gsi/missing"

LOG "- adding ColorOS vendor blobs"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libexposuremonitor.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libAImode_wrapper.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/vendor.oplus.hardware.olc2-V2-ndk.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libAIphoto_core.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libExposureMonitor.uniplugin@1.0.so" 0 0 644 "u:object_r:vendor_configs_file:s0"

ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/libAImode_wrapper.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/vendor.oplus.hardware.olc2-V2-ndk.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/libAIphoto_core.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"


# below is not checking yet
if [[ "$TARGET_CODENAME" != "r9s" ]]; then
    LOG "- Skipping r9s GSI compatibility libraries on $TARGET_CODENAME"
    return 0
fi

SYSTEM_SDK="$(GET_PROP "system" "ro.build.version.sdk")"
SYSTEM_BRAND="$(GET_PROP "system" "ro.product.system.brand")"
if [[ "$SYSTEM_SDK" != "37" ]] || [[ "$SYSTEM_BRAND" != "oplus" ]]; then
    LOG "- Skipping legacy memtrack libraries for non-ColorOS 17 system"
    unset SYSTEM_SDK SYSTEM_BRAND
    return 0
fi
unset SYSTEM_SDK SYSTEM_BRAND

MOD_DIR="$SRC_DIR/unica/mods/gsi"
for LIB in \
        "lib/android.hardware.memtrack@1.0.so" \
        "lib64/android.hardware.memtrack@1.0.so" \
        "lib64/libwifi-system-iface.so" \
        "lib64/android.hardware.dumpstate@1.0.so" \
        "lib64/android.hardware.dumpstate@1.1.so"; do
    if [ ! -f "$MOD_DIR/system/$LIB" ]; then
        ABORT "Required GSI compatibility library not found: ${MOD_DIR//$SRC_DIR\//}/system/$LIB"
        return 1
    fi

    LOG "- Restoring legacy memtrack library /system/$LIB"
    ADD_TO_WORK_DIR "$MOD_DIR" "system" "$LIB" \
        0 0 644 "u:object_r:system_file:s0" || return 1
done

unset MOD_DIR LIB
