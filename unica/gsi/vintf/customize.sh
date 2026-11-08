source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

DEVICE_MATRIX="$SRC_DIR/target/$TARGET_CODENAME/vintf/compatibility_matrix.device.xml"
if [ ! -f "$DEVICE_MATRIX" ]; then
    ABORT "File not found: ${DEVICE_MATRIX//$SRC_DIR\//}"
    return 1
fi

LOG "- Installing r9s compatibility matrix"
EVAL "mkdir -p \"$WORK_DIR/system/system/etc/vintf\"" || return 1
EVAL "cp -a \"$DEVICE_MATRIX\" \"$WORK_DIR/system/system/etc/vintf/compatibility_matrix.device.xml\"" || return 1
SET_METADATA "system" "system/etc/vintf/compatibility_matrix.device.xml" \
    0 0 644 "u:object_r:system_file:s0" || return 1
unset DEVICE_MATRIX

# 30.0.cil
TARGET_FIRMWARE_DIR="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
# LOG "TARGET_FIRMWARE_DIR=$TARGET_FIRMWARE_DIR"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_DIR" "system" "system/system_ext/etc/selinux/mapping/30.0.cil" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_DIR" "system" "system/system_ext/etc/selinux/mapping/30.0.compat.cil" 0 0 644 "u:object_r:system_file:s0"
