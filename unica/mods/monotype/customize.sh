source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes3/com/samsung/android/settings/display/SecDisplayUtils.smali" "return" \
    'isInvalidFont(Landroid/content/Context;Ljava/lang/String;)Z' \
    'false'
