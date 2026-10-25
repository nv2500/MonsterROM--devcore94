source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MODPATH="$SRC_DIR/unica/mods/blocklist"

SKIPUNZIP=1

ADD_TO_WORK_DIR "$MODPATH" "system" "system/etc/unica_blocklist.xml" 0 0 644 "u:object_r:system_file:s0"

DELETE_FROM_WORK_DIR "system" "system/etc/ldu_blocklist.xml"

APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/services.jar/0001-Allow-custom-PackageBlockListPolicy.patch"
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali_classes2/com/samsung/android/server/pm/install/PackageBlockListPolicy\$1.smali" 'remove'
