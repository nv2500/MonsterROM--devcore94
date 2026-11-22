source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MODPATH="$SRC_DIR/unica/mods/language-core"


LOG_STEP_IN "- Adding Language Core back"

ADD_TO_WORK_DIR "$MODPATH" "system" "system/etc/permissions/signature-permissions-com.samsung.android.offline.languagemodel.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MODPATH" "system" "system/priv-app/OfflineLanguageModel_stub/OfflineLanguageModel_stub.apk" 0 0 644 "u:object_r:system_file:s0"

ADD_TO_WORK_DIR "$MODPATH" "vendor" "lib64/libenn_user_lib.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$MODPATH" "system" "system/lib64/libenn_user_lib.so" 0 0 644 "u:object_r:system_file:s0"

LOG_STEP_OUT
